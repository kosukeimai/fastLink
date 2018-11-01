#' gammaKpar
#'
#' Field comparisons: 0 disagreement, 2 total agreement.
#'
#' @usage gammaKpar(matAp, matBp, gender, n.cores)
#' 
#' @param matAp vector storing the comparison field in data set 1
#' @param matBp vector storing the comparison field in data set 2
#' @param gender Whether the matching variable is gender. Will override
#' standard warnings of missingness/nonvariability. Default is FALSE.
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

gammaKpar <- function(matAp, matBp, gender = FALSE, n.cores = NULL) {

    ## For visible bindings
    i <- NULL

    if(any(class(matAp) %in% c("tbl_df", "data.table"))){
        matAp <- as.data.frame(matAp)[,1]
    }
    if(any(class(matBp) %in% c("tbl_df", "data.table"))){
        matBp <- as.data.frame(matBp)[,1]
    }

    if(is.null(n.cores)) {
        n.cores <- detectCores() - 1
    }

    matAp[matAp == ""] <- NA
    matBp[matBp == ""] <- NA

    if(!gender){
        if(sum(is.na(matAp)) == length(matAp) | length(unique(matAp)) == 1){
            cat("WARNING: You have no variation in this variable, or all observations are missing in dataset A.\n")
        }
        if(sum(is.na(matBp)) == length(matBp) | length(unique(matBp)) == 1){
            cat("WARNING: You have no variation in this variable, or all observations are missing in dataset B.\n")
        }
    }else{
        if(sum(is.na(matAp)) == length(matAp)){
            cat("WARNING: You have no variation in this variable, or all observations are missing in dataset A.\n")
        }
        if(sum(is.na(matBp)) == length(matBp)){
            cat("WARNING: You have no variation in this variable, or all observations are missing in dataset B.\n")
        }
    }

    matrix.1 <- as.matrix(as.character(matAp))
    matrix.2 <- as.matrix(as.character(matBp))

    matrix.1[is.na(matrix.1)] <- "9999"
    matrix.2[is.na(matrix.2)] <- "9998"

    u.values.1 <- unique(matrix.1)
    u.values.2 <- unique(matrix.2)

    matches <- u.values.1[u.values.1 %in% u.values.2]

    ht1 <- new.env(hash=TRUE)
    ht2 <- new.env(hash=TRUE)
    matches.l <- as.list(matches)
    
    if(Sys.info()[['sysname']] == "Windows") {
      if (n.cores == 1) '%oper%' <- foreach::'%do%'
      else { 
        '%oper%' <- foreach::'%dopar%'
        cl <- makeCluster(n.cores)
        registerDoParallel(cl)
        on.exit(stopCluster(cl))
      }
      
      final.list <- foreach(i = 1:length(matches.l)) %oper% {
        ht1 <- which(matrix.1 == matches.l[[i]]); ht2 <- which(matrix.2 == matches.l[[i]])
        list(ht1, ht2)
      }
      
    } else {
      final.list <- mclapply(matches.l, function(s){
        ht1[[s]] <- which(matrix.1 == s); ht2[[s]] <- which(matrix.2 == s);
        list(ht1[[s]], ht2[[s]]) }, mc.cores = getOption("mc.cores", n.cores))
    }
    
    na.list <- list()
    na.list[[1]] <- which(matrix.1 == "9999")
    na.list[[2]] <- which(matrix.2 == "9998")

    out <- list()
    out[["matches2"]] <- final.list
    out[["nas"]] <- na.list
    class(out) <- c("fastLink", "gammaKpar")

    return(out)
}

## ------------------------
## End of gamma.k.par
## ------------------------
