#' fastLink
#'
#' Run the fastLink algorithm to probabilistically match
#' two datasets.
#'
#' @usage fastLink(dfA, dfB, varnames, stringdist.match,
#' partial.match = NULL, cut.a, cut.p, n.cores = NULL, tol.em = 1e-04,
#' match = 0.85, verbose = FALSE)
#'
#' @param dfA Dataset A - to be matched to Dataset B
#' @param dfB Dataset B - to be matched to Dataset A
#' @param varnames A vector of variable names to use for matching.
#' Must be present in both dfA and dfB
#' @param stringdist.match A vector of booleans, indicating whether to use
#' string distance matching when determining matching patterns on
#' each variable. Must be same length as varnames.
#' @param partial.match A vector of booleans, indicating whether to include
#' a partial matching category for the string distances. Must be same length
#' as varnames. Default is FALSE for all variables.
#' @param cut.a Lower bound for full string-distance match, ranging between 0 and 1. Default is 0.92
#' @param cut.p Lower bound for partial string-distance match, ranging between 0 and 1. Default is 0.88
#' @param priors.obj A list containing priors for auxiliary movers information,
#' as output from calcMoversPriors(). Default is NULL
#' @param w.lambda How much weight to give the prior on lambda versus the data. Must range between 0 (no weight on prior) and 1 (weight fully on prior).
#' Default is NULL (no prior information provided).
#' @param w.pi How much weight to give the prior on pi versus the data. Must range between 0 (no weight on prior) and 1 (weight fully on prior).
#' Default is NULL (no prior information provided).
#' @param l.address The number of possible matching categories used for address fields. If a binary yes/no match, \code{l.address} = 2,
#' while if a partial match category is included, \code{l.address} = 3. Default is NULL (no prior information provided).
#' @param address.field A vector of booleans for whether a given field is an address field. To be used when 'pi.prior' is included in 'priors.obj'.
#' Default is FALSE for all fields. Address fields should be set to TRUE while non-address fields are set to FALSE.
#' @param n.cores Number of cores to parallelize over. Default is NULL.
#' @param tol.em Convergence tolerance for the EM Algorithm. Default is 1e-04.
#' @param match A number between 0 and 1. The closer to 1 the more centainty you have about a given pair being a match 
#' @param verbose Whether to print elapsed time for each step. Default is FALSE.
#'
#' @return \code{fastLink} returns a list of class 'fastLink' containing the following components:
#' \item{matches}{An nmatches X 2 matrix containing the indices of the successful matches in \code{dfA}
#' in the first column, and the indices of the corresponding successful matches in \code{dfB} in the
#' second column.}
#' \item{EM}{A matrix with the output of the EM algorithm, which contains the exact matching
#' patterns and the associated posterior probabilities of a match for each matching pattern.}
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com>, Ben Fifield <benfifield@gmail.com>, and Kosuke Imai
#'
#' @examples
#' \dontrun{
#' fastLink(dfA, dfB, varnames = c("firstname", "lastname", "streetname", "birthyear"),
#' stringdist.match = c(TRUE, TRUE, TRUE, FALSE), partial.match = c(TRUE, TRUE, FALSE, FALSE),
#' verbose = TRUE)
#' }
#' @export
fastLink <- function(dfA, dfB, varnames,
                     cut.a = 0.92, cut.p = 0.88,
                     stringdist.match, partial.match = NULL,
                     priors.obj = NULL,
                     w.lambda = NULL, w.pi = NULL, l.address = NULL, address.field = NULL,
                     n.cores = NULL, tol.em = 1e-04, match = 0.85, verbose = FALSE){

    cat("\n")
    cat(c(paste(rep("=", 20), sep = "", collapse = ""), "\n"))
    cat("fastLink(): Fast Probabilistic Record Linkage\n")
    cat(c(paste(rep("=", 20), sep = "", collapse = ""), "\n\n"))

    if(is.null(partial.match)){
        partial.match <- rep(FALSE, length(varnames))
    }
    if(length(varnames) != length(stringdist.match)){
        stop("There must be one entry in stringdist.match for each entry in varnames.")
    }
    if(length(varnames) != length(partial.match)){
        stop("There must be one entry in partial.match for each entry in varnames.")
    }
    if(any(class(dfA) %in% c("tbl_df", "data.table"))){
        dfA <- as.data.frame(dfA)
    }
    if(any(class(dfB) %in% c("tbl_df", "data.table"))){
        dfB <- as.data.frame(dfB)
    }
    if(any(!(varnames %in% names(dfA)))){
        stop("Some variables in varnames are not present in dfA.")
    }
    if(any(!(varnames %in% names(dfB)))){
        stop("Some variables in varnames are not present in dfB.")
    }

    ## Create gammas
    cat("Calculating matches for each variable.\n")
    start <- Sys.time()
    gammalist <- vector(mode = "list", length = length(varnames))
    for(i in 1:length(gammalist)){
        if(sum(is.na(dfA[,varnames[i]])) == nrow(dfA) | length(unique(dfA[,varnames[i]])) == 1){
            stop(paste("You have no variation in dataset A for", varnames[i], "or all observations are missing."))
        }
        if(sum(is.na(dfB[,varnames[i]])) == nrow(dfB) | length(unique(dfB[,varnames[i]])) == 1){
            stop(paste("You have no variation in dataset B for", varnames[i], "or all observations are missing."))
        }
        if(stringdist.match[i]){
            if(partial.match[i]){
                gammalist[[i]] <- gammaCKpar(dfA[,varnames[i]], dfB[,varnames[i]], cut.a = cut.a, cut.p = cut.p, n.cores = n.cores)
            }else{
                gammalist[[i]] <- gammaCK2par(dfA[,varnames[i]], dfB[,varnames[i]], cut.a = cut.a, n.cores = n.cores)
            }
        }else{
            gammalist[[i]] <- gammaKpar(dfA[,varnames[i]], dfB[,varnames[i]], n.cores = n.cores)
        }
    }
    end <- Sys.time()
    if(verbose){
        cat("Calculating matches for each variable took", round(difftime(end, start, units = "mins"), 2), "minutes.\n\n")
    }

    ## Get row numbers
    nr_a <- nrow(dfA)
    nr_b <- nrow(dfB)

    ## Get counts for zeta parameters
    cat("Getting counts for zeta parameters.\n")
    start <- Sys.time()
    counts <- tableCounts(gammalist, nobs.a = nr_a, nobs.b = nr_b, n.cores = n.cores)
    end <- Sys.time()
    if(verbose){
        cat("Getting counts for zeta parameters took", round(difftime(end, start, units = "mins"), 2), "minutes.\n\n")
    }

    ## Run EM algorithm
    cat("Running the EM algorithm.\n")
    start <- Sys.time()
    if(is.null(priors.obj)){
        lambda.prior <- NULL
        pi.prior <- NULL
    }else{
        if("lambda.prior" %in% names(priors.obj)){
            lambda.prior <- priors.obj$lambda.prior
        }
        if("pi.prior" %in% names(priors.obj)){
            if(!("lambda.prior" %in% names(priors.obj))){
                stop("Must specify a prior for lambda if providing a prior for pi.")
            }
            pi.prior <- priors.obj$pi.prior
        }else{
            pi.prior <- NULL
        }
    }
    resultsEM <- emlinkMARmov(patterns = counts, nobs.a = nr_a, nobs.b = nr_b,
                              tol = tol.em,
                              prior.lambda = lambda.prior, w.lambda = w.lambda,
                              prior.pi = pi.prior, w.pi = w.pi,
                              address.field = address.field, l.address = l.address)
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
    matches <- matchesLink(gammalist, nobs.a = nr_a, nobs.b = nr_b,
                           em = resultsEM, cut = match.ut,
                           n.cores = n.cores)
    end <- Sys.time()
    if(verbose){
        cat("Getting the indices of estimated matches took", round(difftime(end, start, units = "mins"), 2), "minutes.\n\n")
    }
    colnames(matches) <- c("inds.a", "inds.b")
    matches <- as.data.frame(matches)

    ## Return object
    out <- list()
    out[["matches"]] <- matches
    out[["EM"]] <- EM
    out[["nobs.a"]] <- nr_a
    out[["nobs.b"]] <- nr_b
    class(out) <- "fastLink"

    return(out)

}

