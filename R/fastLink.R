#' fastLink
#'
#' Run the fastLink algorithm to probabilistically match
#' two datasets.
#'
#' @usage fastLink(df_a, df_b, varnames, stringdist_match,
#' partial_match = NULL, n.cores = NULL, tol.em = 1e-04,
#' match = 0.85, verbose = FALSE)
#'
#' @param df_a Dataset A - to be matched to Dataset B
#' @param df_b Dataset B - to be matched to Dataset A
#' @param varnames A vector of variable names to use for matching.
#' Must be present in both df_a and df_b
#' @param stringdist_match A vector of booleans, indicating whether to use
#' string distance matching when determining matching patterns on
#' each variable. Must be same length as varnames.
#' @param partial_match A vector of booleans, indicating whether to include
#' a partial matching category for the string distances. Must be same length
#' as varnames. Default is FALSE for all variables.
#' @param priors_obj A list containing priors for auxiliary movers information,
#' as output from calcMoversPriors() or precalcPriors(). Default is NULL
#' @param address_field A vector of booleans for whether a given field is an address field. To be used when 'alpha0' and 'alpha1' are included in 'priors_obj'.
#' Default is FALSE for all fields. Address fields should be set to TRUE while non-address fields are set to FALSE.
#' @param n.cores Number of cores to parallelize over. Default is NULL.
#' @param tol.em Convergence tolerance for the EM Algorithm. Default is 1e-04.
#' @param match A number between 0 and 1. The closer to 1 the more centainty you have about a given pair being a match 
#' @param verbose Whether to print elapsed time for each step. Default is FALSE.
#'
#' @return \code{fastLink} returns a list of class 'fastLink' containing the following components:
#' \item{matches}{An nmatches X 2 matrix containing the indices of the successful matches in \code{df_a}
#' in the first column, and the indices of the corresponding successful matches in \code{df_b} in the
#' second column.}
#' \item{EM}{A matrix with the output of the EM algorithm, which contains the exact matching
#' patterns and the associated posterior probabilities of a match for each matching pattern.}
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com>, Ben Fifield <benfifield@gmail.com>, and Kosuke Imai
#'
#' @examples
#' \dontrun{
#' fastLink(dfA, dfB, varnames = c("firstname", "lastname", "streetname", "birthyear"),
#' stringdist_match = c(TRUE, TRUE, TRUE, FALSE), partial_match = c(TRUE, TRUE, FALSE, FALSE),
#' verbose = TRUE)
#' }
#' @export
fastLink <- function(df_a, df_b, varnames,
                     stringdist_match, partial_match = NULL,
                     priors_obj = NULL, address_field = NULL,
                     n.cores = NULL, tol.em = 1e-04, match = 0.85, verbose = FALSE){

    cat("\n")
    cat(c(paste(rep("=", 20), sep = "", collapse = ""), "\n"))
    cat("fastLink(): Fast Probabilistic Record Linkage\n")
    cat(c(paste(rep("=", 20), sep = "", collapse = ""), "\n\n"))

    if(is.null(partial_match)){
        partial_match <- rep(FALSE, length(varnames))
    }
    if(length(varnames) != length(stringdist_match)){
        stop("There must be one entry in stringdist_match for each entry in varnames.")
    }
    if(length(varnames) != length(partial_match)){
        stop("There must be one entry in partial_match for each entry in varnames.")
    }
    if(any(class(df_a) %in% c("tbl_df", "data.table"))){
        df_a <- as.data.frame(df_a)
    }
    if(any(class(df_b) %in% c("tbl_df", "data.table"))){
        df_b <- as.data.frame(df_b)
    }

    ## Create gammas
    cat("Calculating matches for each variable.\n")
    start <- Sys.time()
    gammalist <- vector(mode = "list", length = length(varnames))
    for(i in 1:length(gammalist)){
        if(sum(is.na(df_a[,varnames[i]])) == nrow(df_a) | length(unique(df_a[,varnames[i]])) == 1){
            stop(paste("You have no variation in dataset A for", varnames[i], "or all observations are missing."))
        }
        if(sum(is.na(df_b[,varnames[i]])) == nrow(df_b) | length(unique(df_b[,varnames[i]])) == 1){
            stop(paste("You have no variation in dataset B for", varnames[i], "or all observations are missing."))
        }
        if(stringdist_match[i]){
            if(partial_match[i]){
                gammalist[[i]] <- gammaCKpar(df_a[,varnames[i]], df_b[,varnames[i]], n.cores = n.cores)
            }else{
                gammalist[[i]] <- gammaCK2par(df_a[,varnames[i]], df_b[,varnames[i]], n.cores = n.cores)
            }
        }else{
            gammalist[[i]] <- gammaKpar(df_a[,varnames[i]], df_b[,varnames[i]], n.cores = n.cores)
        }
    }
    end <- Sys.time()
    if(verbose){
        cat("Calculating matches for each variable took", round(difftime(end, start, units = "mins"), 2), "minutes.\n\n")
    }

    ## Get row numbers
    nr_a <- nrow(df_a)
    nr_b <- nrow(df_b)

    ## Get counts for zeta parameters
    cat("Getting counts for zeta parameters.\n")
    start <- Sys.time()
    counts <- tableCounts(gammalist, nr1 = nr_a, nr2 = nr_b, n.cores = n.cores)
    end <- Sys.time()
    if(verbose){
        cat("Getting counts for zeta parameters took", round(difftime(end, start, units = "mins"), 2), "minutes.\n\n")
    }

    ## Run EM algorithm
    cat("Running the EM algorithm.\n")
    start <- Sys.time()
    if(is.null(priors_obj)){
        psi <- NULL; mu <- NULL
        alpha0 <- NULL; alpha1 <- NULL
        address_field <- rep(FALSE, length(varnames))
    }else{
        if("lambda_prior" %in% names(priors_obj)){
            mu <- priors_obj$lambda_priors$mu
            psi <- priors_obj$lambda_priors$psi
        }else{
            mu <- NULL; psi <- NULL
        }
        if("pi_prior" %in% names(priors_obj)){
            alpha0 <- priors_obj$pi_priors$alpha_0
            alpha1 <- priors_obj$pi_priors$alpha_1
        }else{
            alpha0 <- NULL; alpha1 <- NULL
            address_field <- rep(FALSE, length(varnames))
        }
    }
    resultsEM <- emlinkMARmov(patterns = counts, tol = tol.em,
                              mu = mu, psi = psi,
                              alpha0 = alpha0, alpha1 = alpha1,
                              address_field = address_field)
    end <- Sys.time()
    if(verbose){
        cat("Running the EM algorithm took", round(difftime(end, start, units = "secs"), 2), "seconds.\n\n")
    }

    ## Get output
    EM <- data.frame(resultsEM$patterns.w)
    EM$zeta.j <- resultsEM$zeta.j
    EM <- EM[order(EM[, "weights"]), ] 
    EM$cumsum.m <- cumsum(EM[, "p.gamma.j.m"])
    EM$cumsum.u <- 1 - cumsum(EM[, "p.gamma.j.u"])
    if(verbose){
        cat("EM output is:\n")
        print(EM)
        cat("\n\n")
    }

    match.ut <- EM$weights[ EM$zeta.j >= match ][1]

    ## Get matches
    cat("Getting the indices of estimated matches.\n")
    start <- Sys.time()
    matches <- matchesLink(gammalist, nr1 = nr_a, nr2 = nr_b,
                           em = resultsEM, cut = match.ut,
                           n.cores = n.cores)
    end <- Sys.time()
    if(verbose){
        cat("Getting the indices of estimated matches took", round(difftime(end, start, units = "mins"), 2), "minutes.\n\n")
    }
    colnames(matches) <- c("inds_a", "inds_b")

    ## Return object
    out <- list()
    out[["matches"]] <- matches
    out[["EM"]] <- EM
    class(out) <- "fastLink"

    return(out)

}

