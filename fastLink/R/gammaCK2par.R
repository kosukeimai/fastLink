#' gammaCK2par
#'
#' Field comparisons for string variables. Two possible agreement patterns are considered:
#' 0 total disagreement, 2 agreement.
#' The distance between strings is calculated using a Jaro-Winkler distance as implemented
#' in the stringdist package.
#'
#' @param matAp vector storing the comparison field in data set 1
#' @param matBp vector storing the comparison field in data set 2
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com>, Ben Fifield, and Kosuke Imai
#'
#' @export

## ------------------------
## gammaCK2par: Now it takes values 0, 2
## This function applies gamma.k
## in parallel
## ------------------------

gammaCK2par <- function(matAp, matBp) {

  requireNamespace('parallel')
  requireNamespace('stringdist')
  requireNamespace('Matrix')
  requireNamespace('doParallel')
  requireNamespace('stats')

	matrix.1 <- as.matrix(as.character(matAp))
	matrix.2 <- as.matrix(as.character(matBp))

	matrix.1[is.na(matrix.1)] <- "9999"
	matrix.2[is.na(matrix.2)] <- "9998"

	u.values.1 <- unique(matrix.1)
	u.values.2 <- unique(matrix.2)

	n.slices1 <- max(round(length(u.values.1)/(4500), 0), 1) 
    	n.slices2 <- max(round(length(u.values.2)/(4500), 0), 1) 

	limit.1 <- round(quantile((0:nrow(u.values.2)), p = seq(0, 1, 1/n.slices2)), 0)
	limit.2 <- round(quantile((0:nrow(u.values.1)), p = seq(0, 1, 1/n.slices1)), 0)

  	temp.1 <- temp.2 <- list()
	  	
	for(i in 1:n.slices2) {
		temp.1[[i]] <- list(u.values.2[(limit.1[i]+1):limit.1[i+1]], limit.1[i])
	}

	for(i in 1:n.slices1) {
		temp.2[[i]] <- list(u.values.1[(limit.2[i]+1):limit.2[i+1]], limit.2[i])
	}

  stringvec <- function(m, y) {
    x <- as.matrix(m[[1]])
    e <- as.matrix(y[[1]])
    requireNamespace('stringdist')
    requireNamespace('Matrix')
    t <- 1 - stringdistmatrix(e, x, method = "jw")
    t[ t < 0.92 ] <- 0
    t <- Matrix(t, sparse = T)
    t@x[t@x >= 0.92] <- 2; gc()
    slice.1 <- m[[2]]
    slice.2 <- y[[2]]
    indexes.2 <- which(t == 2, arr.ind = T)
    indexes.2[, 1] <- indexes.2[, 1] + slice.2
    indexes.2[, 2] <- indexes.2[, 2] + slice.1
    list(indexes.2)
  }

	do <- expand.grid(1:n.slices2, 1:n.slices1)

	nc <- detectCores() - 1
  	cl <- makeCluster(nc)
  	registerDoParallel(cl)

  	temp.f <- foreach(i = 1:nrow(do), .packages = c("stringdist", "Matrix")) %dopar% {
  		r1 <- do[i, 1]
  		r2 <- do[i, 2]
  		stringvec(temp.1[[r1]], temp.2[[r2]])
  	}

  	stopCluster(cl)
  	gc()

	reshape2 <- function(s) { s[[1]] }
	temp.2 <- lapply(temp.f, reshape2)

	indexes.2 <- do.call('rbind', temp.2)

  	ht1 <- new.env(hash=TRUE)
  	ht2 <- new.env(hash=TRUE)

	n.values.2 <- as.matrix(cbind(u.values.1[indexes.2[, 1]], u.values.2[indexes.2[, 2]]))
	matches.2 <- lapply(seq_len(nrow(n.values.2)), function(i) n.values.2[i, ])

	no_cores <- detectCores() - 1
	final.list2 <- mclapply(matches.2, function(s) {
	  ht1 <- which(matrix.1 == s[1])
	  ht2 <- which(matrix.2 == s[2])
	  list(ht1, ht2)
	}, mc.cores = getOption("mc.cores", no_cores))

	na.list <- list()
	na.list[[1]] <- which(matrix.1 == "9999")
	na.list[[2]] <- which(matrix.2 == "9998")

	return(list(matches2 = final.list2, nas = na.list))
}


## ------------------------
## End of gammaCK2par
## ------------------------

