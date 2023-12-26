#' gammaKpar
#'
#' Field comparisons: 0 disagreement, 2 total agreement.
#'
#' @usage gammaKpar(vecA, vecB, n.cores)
#' 
#' @param vecA vector storing the comparison field in data set 1
#' @param vecB vector storing the comparison field in data set 2
#' @param n.cores Number of cores to parallelize over. Default is NULL.
#'
#' @return \code{gammaKpar} returns a list with the indices corresponding to each
#' matching pattern, which can be fed directly into \code{tableCounts} and \code{matchesLink}.
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com>, Ben Fifield <benfifield@gmail.com>, and Kosuke Imai
#'
#' @examples
#' \dontrun{
#' g1 <- gammaKpar(dfA$birthyear, dfB$birthyear)
#' }
#' @export

## ------------------------
## gamma.k.par
## This function applies gamma.k
## in parallel
## ------------------------
gammaKpar <- function(vecA, vecB, n.cores = NULL) {
  
  ## For visible bindings
  i <- NULL
  
  if (is.null(n.cores)) {
    n.cores <- parallel::detectCores() - 1
  }
  if (!is.factor(vecA)) {
    vecA=collapse::qF(vecA,na.exclude = T,sort=TRUE)
  } 
  if (!is.factor(vecB)) {
    vecB=collapse::qF(vecB,na.exclude = T,sort=TRUE)
  }
  
  levels(vecA)[levels(vecA)==""]=NA
  levels(vecB)[levels(vecB)==""]=NA
  u.values.1 <- levels(vecA)
  u.values.2 <- levels(vecB)
  
  ## WARNING/STOP block
  if (length(u.values.1) < 2) {
      warning("You have no variation in this variable, or all observations are missing in dataset A.\n")
  }
  if (length(u.values.2) < 2) {
      warning("You have no variation in this variable, or all observations are missing in dataset B.\n")
  }
  
  vecA=as.numeric(vecA)
  vecB=as.numeric(vecB)
  
  u1=which(u.values.1 %in% u.values.2)
  u2=which(u.values.2 %in% u.values.1)
  
  match_val <- function(val1, val2) {
    list(which(vecA == val1),
          which(vecB == val2))
  }
  
  res <- list(
      "matches2" =
          parallel::mcmapply(
                        match_val,
                        val1 = u1,
                        val2 = u2,
                        mc.cores = n.cores,
                        SIMPLIFY = F,
                        USE.NAMES = F),
      "nas" = list(which(is.na(vecA)), which(is.na(vecB))))
  

  class(res) = c("fastLink", "gammaKpar")
  
  return(res)
}

## ------------------------
## End of gamma.k.par
## ------------------------
