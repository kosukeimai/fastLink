#' gammaKpar
#'
#' Field comparisons: 0 disagreement, 2 total agreement.
#'
#' @param matAp vector storing the comparison field in data set 1
#' @param matBp vector storing the comparison field in data set 2
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com>, Ben Fifield <benfifield@gmail.com>, and Kosuke Imai
#'
#' @export

## ------------------------
## gamma.k.par
## This function applies gamma.k
## in parallel
## ------------------------

gammaKpar <- function(matAp, matBp, n.cores = NULL) {
	requireNamespace('parallel')

	if(is.null(n.cores)) {
		n.cores <- detectCores() - 1
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

	na.list <- list()
	na.list[[1]] <- which(matrix.1 == "9999")
	na.list[[2]] <- which(matrix.2 == "9998")

	return(list(matches2 = final.list, nas = na.list))
}

## ------------------------
## End of gamma.k.par
## ------------------------
