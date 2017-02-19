#' fastLink
#'
#' Run the fastLink algorithm to probabilistically match
#' two datasets.
#'
#' @param df_a Dataset A - to be matched to Dataset B
#' @param df_b Dataset B - to be matched to Dataset A
#' @param varnames A vector of variable names to use for matching.
#' Must be present in both df_a and df_b
#' @param partial_match A vector of booleans, indicating whether to use
#' partial matching or exact matching when determining matching patterns on
#' each variable.
#' @param n.cores Number of cores to parallelize over. Default is NULL.
#' @param tol.em Convergence tolerance for the EM Algorithm. Default is 1e-04.
#' @param tol.match Convergence tolerance for determining matches. Default is 1e-07.
#' @param verbose Whether to print elapsed time for each step. Default is FALSE.
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com>, Ben Fifield <benfifield@gmail.com>, and Kosuke Imai
#'
#' @export
fastLink <- function(df_a, df_b, varnames, partial_match, n.cores = NULL, tol.em = 1e-04, tol.match = 1e-07, verbose = FALSE){

    cat("\n")
    cat(c(paste(rep("=", 20), sep = "", collapse = ""), "\n"))
    cat("fastLink(): Fast Probabilistic Record Linkage\n")
    cat(c(paste(rep("=", 20), sep = "", collapse = ""), "\n\n"))

    if(length(varnames) != length(partial_match)){
        stop("There must be one entry in partial_match for each entry in varnames.")
    }

    ## Create gammas
    cat("Calculating matches for each variable.\n")
    start <- Sys.time()
    gammalist <- vector(mode = "list", length = length(varnames))
    for(i in 1:length(gammalist)){
        if(partial_match[i]){
            gammalist[[i]] <- gammaCKpar(df_a[,varnames[i]], df_b[,varnames[i]], n.cores = n.cores)
        }else{
            gammalist[[i]] <- gammaKpar(df_a[,varnames[i]], df_b[,varnames[i]], n.cores = n.cores)
        }
    }
    end <- Sys.time()
    if(verbose){
        cat("Calculating matches for each variable took ", difftime(end, start, units = "mins"), " minutes.\n\n")
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
        cat("Getting counts for zeta parameters took ", difftime(end, start, units = "mins"), " minutes.\n\n")
    }

    ## Run EM algorithm
    cat("Running the EM algorithm.\n")
    start <- Sys.time()
    resultsEM <- emlinkMAR(patterns = counts, tol = tol.em)
    end <- Sys.time()
    if(verbose){
        cat("Running the EM algorithm took ", difftime(end, start, units = "secs"), " seconds.\n\n")
    }

    ## Get output
    EM <- data.frame(cbind(resultsEM$patterns.w))
    EM <- EM[order(EM[, "weights"]),] 
    EM$cumsum.m <- cumsum(EM[, "p.gamma.j.m"])
    EM$cumsum.u <- 1 - cumsum(EM[, "p.gamma.j.u"])
    match.ut <- EM$weights[EM$cumsum.u <= tol.match][1]

    ## Get matches
    cat("Getting the indices of estimated matches.\n")
    start <- Sys.time()
    matches <- matchesLink(gammalist, nr1 = nr_a, nr2 = nr_b,
                           em = resultsEM, cut = match.ut,
                           n.cores = n.cores)
    end <- Sys.time()
    if(verbose){
        cat("Getting the indices of estimated matches took ", difftime(end, start, units = "mins"), " minutes.\n\n")
    }
    colnames(matches) <- c("inds_a", "inds_b")

    return(matches)

}

