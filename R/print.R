#' print.inspectEM
#' 
#' Print information from the EM algorithm to console.
#'
#' @usage \method{print}{inspectEM}(x, ...)
#' @param x An \code{inspectEM} object
#' @param ... Further arguments to be passed to \code{print.fastLink()}.
#'
#' @export
#' @method print inspectEM
print.inspectEM <- function(x, ...){

    ## ------
    ## Output
    ## ------
    ## Details of match
    cat("\nMatched", x$nobs.a, "observations in dataset A to", x$nobs.b, "observations in dataset B.\n")
    cat("EM algorithm converged in", x$iter.converge, "iterations.\n")
    
    ## Number of matches
    min <- min(x$posterior.range)
    max <- max(x$posterior.range)
    cat(paste0("\nNumber of matches found for posterior between ", min, " and ", max, ":\n"))
    cat(x$num.matches, "\n")

    ## Quality of each variable
    cat("\nProbability of observing pattern conditional on being in matched set\n(By Variable):\n")
    print(x$matchprob.by.variable)
    cat("\n")

    cat("\nProbability of a match across all pairwise comparisons:\n")
    print(x$lambda)
    cat("\n")
    
    ## Posteriors
    cat("\nPosterior probability of a match, by matching pattern:\n")
    print(x$match.patterns)
    cat("\n")
    
}
