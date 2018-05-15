#' aggconfusion
#'
#' Aggregate confusion tables from separate runs of fastLink() (UNDER DEVELOPMENT)
#'
#' @usage aggconfusion(object)
#'
#' @param object A list of confusion tables. 
#'
#' @return 'aggconfusion()' returns two tables - one calculating the confusion table, and another
#' calculating a series of additional summary statistics.
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com> and Ben Fifield <benfifield@gmail.com>
#'
#' @export
aggconfusion <- function(object) {
  y <- unlist(object)
  
  D <- sum(y[grep("confusion.table1", names(y))])
  B <- sum(y[grep("confusion.table2", names(y))])
  C <- sum(y[grep("confusion.table3", names(y))])
  A <- sum(y[grep("confusion.table4", names(y))])
  
  t1 <- round(rbind(c(D, B), c(C, A)), 2)
  colnames(t1) <- c("'True' Matches", "'True' Non-Matches")
  rownames(t1) <- c("Declared Matches", "Declared Non-Matches")
  N = A + B + C + D
  sens = 100 * D/(C + D)
  spec = 100 * A/(A + B)
  ppv = 100 * D/(B + D)
  npv = 100 * A/(A + C)
  fpr = 100 * B/(A + B)
  fnr = 100 * C/(C + D)
  acc = 100 * (A + D)/N
  f1 = (2 * ppv * sens)/(ppv + sens)
  t2 <- round(as.matrix(c(N, sens, spec, ppv, npv, fpr, fnr, 
                          acc, f1)), digits = 4)
  rownames(t2) <- c("Max Number of Obs to be Matched", "Sensitivity (%)", 
                    "Specificity (%)", "Positive Predicted Value (%)", "Negative Predicted Value (%)", 
                    "False Positive Rate (%)", "False Negative Rate (%)", 
                    "Correctly Clasified (%)", "F1 Score (%)")
  colnames(t2) <- "results"
  results <- list()
  results$confusion.table <- t1
  options(digits = 6)
  results$addition.info <- round(t2, digits = 2)
  return(results)
}


