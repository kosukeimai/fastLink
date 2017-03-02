#' gammaCK3par
#'
#' Field comparisons for string variables. Three possible agreement patterns are considered:
#' 0 total disagreement, 1 somehow agree, 2 agreement. Made for Tukey!
#' The distance between strings is calculated using a Jaro-Winkler distance as implemented
#' in the stringdist package.
#'
#' @param matAp vector storing the comparison field in data set 1
#' @param matBp vector storing the comparison field in data set 2
#' @n.cores
#' @cut.a
#' @cut.p
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com>, Ben Fifield <benfifield@gmail.com>, and Kosuke Imai
#'
#' @export

## ------------------------
## gammaCKpar: Now it takes values 0, 1, 2
## This function applies gamma.k
## in parallel
## ------------------------

gammaCK3par <- function(matAp, matBp, n.cores = NULL, cut.a = NULL, cut.p = NULL) {

  	requireNamespace('parallel')
  	requireNamespace('stringdist')
  	requireNamespace('Matrix')
  	requireNamespace('doParallel')
  	requireNamespace('stats')

	if(is.null(n.cores)) {
		n.cores <- detectCores() - 1
	}

	if(is.null(cut.a)) {
		cut.a <- 0.92
	}

	if(is.null(cut.p)) {
		cut.p <- 0.88
	}

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

	n.cores <- min(n.cores, n.slices1 * n.slices2)
	  	
	for(i in 1:n.slices2) {
		temp.1[[i]] <- list(u.values.2[(limit.1[i]+1):limit.1[i+1]], limit.1[i])
	}

	for(i in 1:n.slices1) {
		temp.2[[i]] <- list(u.values.1[(limit.2[i]+1):limit.2[i+1]], limit.2[i])
	}


  stringvec <- function(m, y, cut) {
    x <- as.matrix(m[[1]])
    e <- as.matrix(y[[1]])
    require('stringdist')
    require('Matrix')
    t <- 1 - stringdistmatrix(e, x, method = "jw", nthread = 1)
    t[ t < cut[2] ] <- 0
    t <- Matrix(t, sparse = T)
    t@x[t@x >= cut[1]] <- 2
    t@x[t@x >= cut[2] & t@x < cut[1]] <- 1; gc()
    slice.1 <- m[[2]]
    slice.2 <- y[[2]]
    indexes.2 <- which(t == 2, arr.ind = T)
    indexes.2[, 1] <- indexes.2[, 1] + slice.2
    indexes.2[, 2] <- indexes.2[, 2] + slice.1
    indexes.1 <- which(t == 1, arr.ind = T)
    indexes.1[, 1] <- indexes.1[, 1] + slice.2
    indexes.1[, 2] <- indexes.1[, 2] + slice.1
    list(indexes.2, indexes.1)
  }

	do <- expand.grid(1:n.slices2, 1:n.slices1)
	
	nc <- n.cores
  	cl <- makeCluster(nc)
  	registerDoParallel(cl)

  	temp.f <- foreach(i = 1:nrow(do)) %dopar% { 
  		r1 <- do[i, 1]
  		r2 <- do[i, 2]
  		stringvec(temp.1[[r1]], temp.2[[r2]], cut = c(cut.a, cut.p))
  	}

  	stopCluster(cl)
  	gc()

	reshape2 <- function(s) { s[[1]] }
	reshape1 <- function(s) { s[[2]] }
	temp.2 <- lapply(temp.f, reshape2)
	temp.1 <- lapply(temp.f, reshape1)

	indexes.2 <- do.call('rbind', temp.2)
	indexes.1 <- do.call('rbind', temp.1)

  	ht1 <- new.env(hash=TRUE)
  	ht2 <- new.env(hash=TRUE)

	n.values.2 <- as.matrix(cbind(u.values.1[indexes.2[, 1]], u.values.2[indexes.2[, 2]]))
	n.values.1 <- as.matrix(cbind(u.values.1[indexes.1[, 1]], u.values.2[indexes.1[, 2]]))

	matches.2 <- lapply(seq_len(nrow(n.values.2)), function(i) n.values.2[i, ])
	matches.1 <- lapply(seq_len(nrow(n.values.1)), function(i) n.values.1[i, ])

	no_cores <- n.cores
	final.list2 <- mclapply(matches.2, function(s) {
	  ht1 <- which(matrix.1 == s[1])
	  ht2 <- which(matrix.2 == s[2])
	  list(ht1, ht2)
	}, mc.cores = getOption("mc.cores", no_cores))

	final.list1 <- mclapply(matches.1, function(s) {
	  ht1 <- which(matrix.1 == s[1])
	  ht2 <- which(matrix.2 == s[2])
	  list(ht1, ht2)
	}, mc.cores = getOption("mc.cores", no_cores))

		## Calculate optimal dirichlet
    if(calc.prior & !is.null(var)){
        ## Get counts of agreement for prior on delta_{k, agree}
        numerator <- 0
        for(i in 1:length(final.list2)){
            numerator <- numerator +
                (length(final.list2[[i]][[1]]) * length(final.list2[[i]][[2]]))
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
    out[["matches2"]] <- final.list2
    out[["matches1"]] <- final.list1
    out[["nas"]] <- na.list
    if(calc.prior & !is.null(var)){
        out[["priors"]] <- list(alpha_0 = alpha_0, alpha_1 = alpha_1)
    }

    return(out)
}

## ------------------------
## End of gammaCK3par
## ------------------------

