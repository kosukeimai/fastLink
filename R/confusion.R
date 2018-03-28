#' Get confusion table for fastLink objects
#'
#' Calculate confusion table after running fastLink().
#'
#' @usage confusion(object, threshold)
#'
#' @param object A 'fastLink' object. Can only be run if 'return.all = TRUE' in 'fastLink().'
#' @param threshold The matching threshold above which a pair is a true match. Default is .85
#'
#' @return 'confusion()' returns two tables - one calculating the confusion table, and another
#' calculating a series of additional summary statistics.
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com> and Ben Fifield <benfifield@gmail.com>
#'
#' @examples
#' \dontrun{
#'  out <- fastLink(
#'  dfA = dfA, dfB = dfB,
#'  varnames = c("firstname", "middlename", "lastname"),
#'  stringdist.match = c("firstname", "middlename", "lastname"),
#'  partial.match = c("firstname", "lastname", "streetname"),
#'  return.all = TRUE)
#'
#'  ct <- confusion(out)
#' }
#' 
#' @export
confusion <- function(object, threshold = .85) {

    if(!("confusionTable" %in% class(object))){
        stop("You can only run 'confusion()' if 'return.all = TRUE' in 'fastLink()'.")
    }

	## TM
    D <- sum(object$posterior * ifelse(object$posterior >= threshold, 1, 0))
	## FP
    B <- sum(ifelse(object$posterior >= threshold, 1, 0)) - D
	## TNM
	  A.1 <- sum((1 - object$posterior) * ifelse(object$posterior < threshold, 1, 0))
    A <- A.1 + (min(object$nobs.a, object$nobs.b) - D - B - A.1) * (1 - 0.001)
	## FN
    C <- (min(object$nobs.a, object$nobs.b) - D - B) - A
    
    t1 <- round(rbind(c(D, B), c(C, A)), 2)
    colnames(t1) <- c("'True' Matches", "'True' Non-Matches")
    rownames(t1) <- c("Declared Matches", "Declared Non-Matches")
    
    N    = A + B + C + D
    sens = 100 * D/(C + D)
    spec = 100 * A/(A + B)
    ppv  = 100 * D/(B + D)
    npv  = 100 * A/(A + C)
    fpr  = 100 * B/(A + B)
    fnr  = 100 * C/(C + D)
    acc  = 100 * (A + D)/N
    f1 = (2 * ppv * sens) / (ppv + sens)

    t2 <- round(as.matrix(c(N, sens, spec, ppv, npv, fpr, fnr, acc, f1)), digits = 4)

    rownames(t2) <- c("Max Number of Obs to be Matched", 
                      "Sensitivity (%)",
                      "Specificity (%)",
                      "Positive Predicted Value (%)",
                      "Negative Predicted Value (%)",
                      "False Positive Rate (%)",
                      "False Negative Rate (%)",
                      "Correctly Clasified (%)",
                      "F1 Score (%)")
    colnames(t2) <- "results"
    results <- list()				 
    results$confusion.table <- t1
    options(digits = 6)
    results$addition.info <- round(t2, digits = 2)
    return(results)
}