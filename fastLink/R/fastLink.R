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
#' @param tol.em Convergence tolerance for the EM Algorithm. Default is 1e-04.
#' @param tol.match Convergence tolerance for determining matches. Default is 1e-07.
#'
#' @export
fastLink <- function(df_a, df_b, varnames, partial_match, tol.em = 1e-04, tol.match = 1e-07){

    if(length(varnames) != length(partial_match)){
        stop("There must be one entry in partial_match for each entry in varnames.")
    }

    ## Create gammas
    cat("Calculating matches for each variable.")
    gammalist <- vector(mode = "list", length = length(varnames))
    for(i in 1:length(gammalist)){
        if(partial_match[i]){
            gammalist[[i]] <- gammaCKpar(df_a[,varnames[i]], df_b[,varnames[i]])
        }else{
            gammalist[[i]] <- gammaKpar(df_a[,varnames[i]], df_b[,varnames[i]])
        }
    }

    ## Get row numbers
    nr_a <- nrow(df_a)
    nr_b <- nrow(df_b)

    ## Get counts for zeta parameters
    cat("Getting counts for zeta parameters.")
    counts <- tableCounts(gammalist, nr1 = nr_a, nr2 = nr_b)

    ## Run EM algorithm
    cat("Running the EM algorithm.")
    resultsEM <- emlinkMAR(patterns = counts, tol = tol.em)

    ## Get output
    EM <- data.frame(cbind(resultsEM$patterns.w))
    EM <- EM[order(EM[, "weights"]),] 
    EM$cumsum.m <- cumsum(EM[, "p.gamma.j.m"])
    EM$cumsum.u <- 1 - cumsum(EM[, "p.gamma.j.u"])
    match.ut <- EM$weights[EM$cumsum.u <= tol.match][1]

    ## Get matches
    cat("Getting the indices of estimated matches.")
    matches <- matchesLink(gammalist, nr1 = nr_a, nr2 = nr_b,
                           em = resultsEM, cut = match.ut)
    colnames(matches) <- c("inds_a", "inds_b")

    return(matches)

}

