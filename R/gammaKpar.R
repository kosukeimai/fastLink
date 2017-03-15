#' gammaKpar
#'
#' Field comparisons: 0 disagreement, 2 total agreement.
#'
#' @usage gammaKpar(matAp, matBp, n.cores = NULL)
#' 
#' @param matAp vector storing the comparison field in data set 1
#' @param matBp vector storing the comparison field in data set 2
#' @param n.cores Number of cores to parallelize over. Default is NULL.
#'
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

gammaKpar <- function(matAp, matBp, n.cores = NULL, calc.prior = FALSE, var = NULL) {

    if(any(class(matAp) %in% c("tbl_df", "data.table"))){
        matAp <- as.data.frame(matAp)[,1]
    }
    if(any(class(matBp) %in% c("tbl_df", "data.table"))){
        matBp <- as.data.frame(matBp)[,1]
    }

    requireNamespace('parallel')

    if(is.null(n.cores)) {
        n.cores <- detectCores() - 1
    }

    matAp[matAp == ""] <- NA
    matBp[matBp == ""] <- NA

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
        nc <- n.cores
        cl <- makeCluster(nc)
        registerDoParallel(cl)
        final.list <- foreach(i = 1:length(matches.l)) %dopar% {
            ht1 <- which(matrix.1 == matches.l[[i]]); ht2 <- which(matrix.2 == matches.l[[i]])
            list(ht1, ht2)
        }
        stopCluster(cl)
    } else {
    	no_cores <- n.cores
    	final.list <- mclapply(matches.l, function(s){
            ht1[[s]] <- which(matrix.1 == s); ht2[[s]] <- which(matrix.2 == s);
            list(ht1[[s]], ht2[[s]]) }, mc.cores = getOption("mc.cores", no_cores))
    }

    ## Calculate optimal dirichlet
    if(calc.prior & !is.null(var)){
        ## Get counts of agreement for prior on delta_{k, agree}
        numerator <- 0
        for(i in 1:length(final.list)){
            numerator <- numerator +
                (length(final.list[[i]][[1]]) * length(final.list[[i]][[2]]))
        }
        denominator <- as.double(nrow(matrix.1)) * as.double(nrow(matrix.2)) -
            nrow(matrix.1)
        dir_mean <- numerator / denominator
        alpha_1 <- (dir_mean * (1 - dir_mean)^2 + var * dir_mean - var) /
            (var * 2 - var)
        alpha_0 <- ((2 - 1) * alpha_1 * dir_mean) / (1 - dir_mean)
    }
    
    na.list <- list()
    na.list[[1]] <- which(matrix.1 == "9999")
    na.list[[2]] <- which(matrix.2 == "9998")

    out <- list()
    out[["matches2"]] <- final.list
    out[["nas"]] <- na.list
    if(calc.prior & !is.null(var)){
        out[["priors"]] <- list(alpha_0 = alpha_0, alpha_1 = alpha_1)
    }

    return(out)
}

## ------------------------
## End of gamma.k.par
## ------------------------
