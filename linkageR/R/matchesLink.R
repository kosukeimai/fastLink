#' matchesLink
#'
#' matchesLink produces two dataframes that store
#' all the pairs that share a pattern that conforms
#' to the an interval of the Fellegi-Sunter
#' weights
#'
#' @param g1p-g16p list of indices for the first linking field - these are produced by either gammaKpar or gammaCKpar
#' @param nr1 number of observations in dataset 1
#' @param nr2 number of observations in dataset 2
#' @param em parameters obtained from the Expectation-Maximization algorithm under the MAR assumption. These estimates are
#' produced by emlinkMAR
#' @param cut is the interval of weight values for the agreements that we want to examine closer.
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com> and Kosuke Imai
#'
#' @export

## ------------------------
## To recover the matches (their indices)
## we use matchesLink
## ------------------------

matchesLink <- function(g1p = x, g2p = NULL, g3p = NULL, g4p = NULL, g5p = NULL, g6p = NULL, nr1 = w, nr2 = p, em = y, cut = z) {

    requireNamespace('foreach')
    requireNamespace('doParallel')
    requireNamespace('parallel')
    requireNamespace('stats')

  	## Slicing the data:
	n.slices <- round(max(as.numeric(nr1), as.numeric(nr2))/(4900), 0)
	if(n.slices == 0){
		n.slices <- 1
	}

	nc <- min((detectCores() - 1), n.slices^2)

	limit.1 <- round(quantile((0:nr1), p = seq(0, 1, 1/n.slices)), 0)
	limit.2 <- round(quantile((0:nr2), p = seq(0, 1, 1/n.slices)), 0)
	last <- length(limit.1)
	n.lim.1 <- limit.1[-1] - limit.1[-last]
	n.lim.2 <- limit.2[-1] - limit.2[-last]

	l.b <- cut[1]
	u.b <- cut[2]

	if(is.na(u.b)) {
		u.b <- 1e10
	}

	tablem <- em$patterns.w[em$patterns.w[, "weights"] > l.b & em$patterns.w[, "weights"] <= u.b, ]
	list <- tablem
	list[is.na(list)] <- 4

	if(is.null(dim(list))) {
		list <- t(as.matrix(list))
	}

	list <- list[, !colnames(list) %in% c("counts", "weights", "p.gamma.j.m", "p.gamma.j.u")]

	if(is.null(dim(list))) {
		list <- t(as.matrix(list))
	}

	ncol <- ncol(list)
	power <- c(1, 4, 7, 10, 13, 16)
	power.s <- power[1:ncol]
	base <- 2^(power.s)
	list <- t(base * t(list))
	list.id <- rowSums(list)

	## Indices for exact (or nearly exact) Matches:
	temp.1 <- g1p$matches2
	temp.2 <- g2p$matches2
	temp.3 <- g3p$matches2
	temp.4 <- g4p$matches2
	temp.5 <- g5p$matches2
	temp.6 <- g6p$matches2

	## Indices for somehow close strings:
	temp.1.c <- g1p$matches1
	temp.2.c <- g2p$matches1
	temp.3.c <- g3p$matches1
	temp.4.c <- g4p$matches1
	temp.5.c <- g5p$matches1
	temp.6.c <- g6p$matches1

	## Indexes for NAs:
	temp.1na <- g1p$nas
	temp.2na <- g2p$nas
	temp.3na <- g3p$nas
	temp.4na <- g4p$nas
	temp.5na <- g5p$nas
	temp.6na <- g6p$nas

	indexing <- function(s, l.1, l.2, l.3, l.4) {
		if(sum(s[[1]] > l.1 & s[[1]] <= l.2) >= 1 &
		sum(s[[2]] > l.3 & s[[2]] <= l.4) >= 1) {
			temp1 <- subset(s[[1]], s[[1]] > l.1 & s[[1]] <= l.2) - l.1
			temp2 <- subset(s[[2]], s[[2]] > l.3 & s[[2]] <= l.4) - l.3
			as.matrix(expand.grid(temp1, temp2))
			}
		}

    indexing.na <- function(s, d, l.1, l.2, l.3, l.4) {
    	temp1 <- subset(s, s > l.1 & s <= l.2) - l.1
    	temp2 <- subset(d, d > l.3 & d <= l.4) - l.3
    	list(temp1, temp2)
    	}

    m.func <- function(x) {
    	name.0 <- x[[1]]
    	name.1 <- name.0[[1]]
    	name.2 <- name.0[[2]]
    	name.3 <- name.0[[3]]
    	name.4 <- name.0[[4]]
    	name.5 <- name.0[[5]]
    	name.6 <- name.0[[6]]

    	name.1 <- name.1[!sapply(name.1, is.null)]
    	name.2 <- name.2[!sapply(name.2, is.null)]
    	name.3 <- name.3[!sapply(name.3, is.null)]
    	name.4 <- name.4[!sapply(name.4, is.null)]
    	name.5 <- name.5[!sapply(name.5, is.null)]
    	name.6 <- name.6[!sapply(name.6, is.null)]

    	match.1 <- cbind(do.call('rbind', name.1), 2^2)
    	match.2 <- cbind(do.call('rbind', name.2), 2^5)
    	match.3 <- cbind(do.call('rbind', name.3), 2^8)
    	match.4 <- cbind(do.call('rbind', name.4), 2^11)
    	match.5 <- cbind(do.call('rbind', name.5), 2^14)
    	match.6 <- cbind(do.call('rbind', name.6), 2^17)
    	rm(name.0, name.1, name.2, name.3, name.4, name.5, name.6)

    	name.0 <- x[[2]]
    	name.1 <- name.0[[1]]
    	name.2 <- name.0[[2]]
    	name.3 <- name.0[[3]]
    	name.4 <- name.0[[4]]
    	name.5 <- name.0[[5]]
    	name.6 <- name.0[[6]]

    	name.1 <- name.1[!sapply(name.1, is.null)]
    	name.2 <- name.2[!sapply(name.2, is.null)]
    	name.3 <- name.3[!sapply(name.3, is.null)]
    	name.4 <- name.4[!sapply(name.4, is.null)]
    	name.5 <- name.5[!sapply(name.5, is.null)]
    	name.6 <- name.6[!sapply(name.6, is.null)]

    	match.1.c <- cbind(do.call('rbind', name.1), 2^1)
    	match.2.c <- cbind(do.call('rbind', name.2), 2^4)
    	match.3.c <- cbind(do.call('rbind', name.3), 2^7)
    	match.4.c <- cbind(do.call('rbind', name.4), 2^10)
    	match.5.c <- cbind(do.call('rbind', name.5), 2^13)
    	match.6.c <- cbind(do.call('rbind', name.6), 2^16)
    	rm(name.0, name.1, name.2, name.3, name.4, name.5, name.6)

    	## this fixes weird cases:
    	rotate <- function(x) {
    		if( ncol(x) != 3 ){
    			x <- t(x)
    		} else {
    			x
    		}
    	}

    	if(ncol(match.1)==1){ match.1 <- t(as.matrix(c(0,0,0))) }
    	if(ncol(match.1.c)==1){ match.1.c <- t(as.matrix(c(0,0,0))) }
    	match.1.f <- rbind(match.1, match.1.c)
    	match.1.f <- as.matrix(match.1.f[rowSums(match.1.f) != 0, ])
		  match.1.f <- rotate(match.1.f)
    	rm(match.1, match.1.c)

    	if(ncol(match.2)==1){ match.2 <- t(as.matrix(c(0,0,0))) }
    	if(ncol(match.2.c)==1){ match.2.c <- t(as.matrix(c(0,0,0))) }
    	match.2.f <- rbind(match.2, match.2.c)
    	match.2.f <- as.matrix(match.2.f[rowSums(match.2.f) != 0, ])
    	match.2.f <- rotate(match.2.f)
    	rm(match.2, match.2.c)

    	if(ncol(match.3)==1){ match.3 <- t(as.matrix(c(0,0,0))) }
    	if(ncol(match.3.c)==1){ match.3.c <- t(as.matrix(c(0,0,0))) }
    	match.3.f <- rbind(match.3, match.3.c)
    	match.3.f <- as.matrix(match.3.f[rowSums(match.3.f) != 0, ])
    	match.3.f <- rotate(match.3.f)
    	rm(match.3, match.3.c)

    	if(ncol(match.4)==1){ match.4 <- t(as.matrix(c(0,0,0))) }
    	if(ncol(match.4.c)==1){ match.4.c <- t(as.matrix(c(0,0,0))) }
    	match.4.f <- rbind(match.4, match.4.c)
    	match.4.f <- as.matrix(match.4.f[rowSums(match.4.f) != 0, ])
    	match.4.f <- rotate(match.4.f)
    	rm(match.4, match.4.c)

    	if(ncol(match.5)==1){ match.5 <- t(as.matrix(c(0,0,0))) }
    	if(ncol(match.5.c)==1){ match.5.c <- t(as.matrix(c(0,0,0))) }
    	match.5.f <- rbind(match.5, match.5.c)
    	match.5.f <- as.matrix(match.5.f[rowSums(match.5.f) != 0, ])
    	match.5.f <- rotate(match.5.f)
    	rm(match.5, match.5.c)

    	if(ncol(match.6)==1){ match.6 <- t(as.matrix(c(0,0,0))) }
    	if(ncol(match.6.c)==1){ match.6.c <- t(as.matrix(c(0,0,0))) }
    	match.6.f <- rbind(match.6, match.6.c)
    	match.6.f <- as.matrix(match.6.f[rowSums(match.6.f) != 0, ])
    	match.6.f <- rotate(match.6.f)
    	rm(match.6, match.6.c)

    	lims <- x[[4]]
    	requireNamespace('Matrix')
    	m.1 <- sparseMatrix(match.1.f[,1], match.1.f[,2], x = match.1.f[,3], dims = c(lims[1], lims[2]))
    	m.2 <- sparseMatrix(match.2.f[,1], match.2.f[,2], x = match.2.f[,3], dims = c(lims[1], lims[2]))
    	m.3 <- sparseMatrix(match.3.f[,1], match.3.f[,2], x = match.3.f[,3], dims = c(lims[1], lims[2]))
    	m.4 <- sparseMatrix(match.4.f[,1], match.4.f[,2], x = match.4.f[,3], dims = c(lims[1], lims[2]))
    	m.5 <- sparseMatrix(match.5.f[,1], match.5.f[,2], x = match.5.f[,3], dims = c(lims[1], lims[2]))
    	m.6 <- sparseMatrix(match.6.f[,1], match.6.f[,2], x = match.6.f[,3], dims = c(lims[1], lims[2]))
      rm(match.1.f, match.2.f, match.3.f, match.4.f, match.5.f, match.6.f)

    	add.nas <- function(s, index.1, index.2, power) {
			if((length(index.1) + length(index.2)) > 0) {
				s <- as.matrix(s)
				s[, c(index.2)] <- power
				s[c(index.1), ] <- power
    			s <- Matrix(s, sparse = TRUE)
			}
    		return(s)
		}

		name.na <- x[[3]]
		name.1 <- name.na[[1]]
		name.2 <- name.na[[2]]
		name.3 <- name.na[[3]]
		name.4 <- name.na[[4]]
		name.5 <- name.na[[5]]
		name.6 <- name.na[[6]]

		m.1 <- add.nas(m.1, name.1[[1]], name.1[[2]], 2^3)
	  m.2 <- add.nas(m.2, name.2[[1]], name.2[[2]], 2^6)
	  m.3 <- add.nas(m.3, name.3[[1]], name.3[[2]], 2^9)
	  m.4 <- add.nas(m.4, name.4[[1]], name.4[[2]], 2^12)
	  m.5 <- add.nas(m.5, name.5[[1]], name.5[[2]], 2^15)
		m.6 <- add.nas(m.6, name.6[[1]], name.6[[2]], 2^18)
   	rm(name.na, name.1, name.2, name.3, name.4, name.5, name.6)

		mmm1 <- list()
		mmm2 <- list()
		mmm3 <- list()
		mmm4 <- list()
		mmm5 <- list()
		mmm1[[1]] <- m.1
		mmm1[[2]] <- m.2
		mmm2[[1]] <- m.3
		mmm2[[2]] <- m.4
		mmm3[[1]] <- m.5
		mmm3[[2]] <- m.6

   	rm(m.1, m.2, m.3, m.4, m.5, m.6)

		ttt1 <- do.call('+', mmm1)
		ttt2 <- do.call('+', mmm2)
		ttt3 <- do.call('+', mmm3)
		mmm4[[1]] <- ttt1
		mmm4[[2]] <- ttt2
		ttt4 <- do.call('+', mmm4)
		mmm5[[1]] <- ttt4
		mmm5[[2]] <- ttt3
		m.f <- do.call('+', mmm5)
		rm(mmm1, mmm2, mmm3, mmm4, mmm5, ttt1, ttt2, ttt3, ttt4)

		limsP <- x[[5]]
		list.idt <- x[[6]]

   	m.f@x[ m.f@x %in% list.idt ] <- 9999
   	temp <- which(sparseMatrix(i = (m.f@i + 1), p = m.f@p, x = m.f@x) == 9999, arr.ind = T)
   	rm(m.f)
    temp[, 1] <- temp[, 1] + limsP[1]
    temp[, 2] <- temp[, 2] + limsP[2]
   	return(temp)
   	}

  	gammas <- list()

  	ind.i <- ind.j <- 1:n.slices
	  ind <- expand.grid(ind.i, ind.j)

  	cl <- makeCluster(nc)
  	registerDoParallel(cl)

  	gammas <- foreach(do = 1:(nrow(ind))) %dopar% {

			i <- ind[do, 1]; j <- ind[do, 2]

  			temp <- temp.c <- tempna <- list()
  			temp[[1]] <- lapply(temp.1, indexing, l.1 = limit.1[i], l.2 = limit.1[i+1], l.3 = limit.2[j], l.4 = limit.2[j+1])
  			temp[[2]] <- lapply(temp.2, indexing, l.1 = limit.1[i], l.2 = limit.1[i+1], l.3 = limit.2[j], l.4 = limit.2[j+1])
  			temp[[3]] <- lapply(temp.3, indexing, l.1 = limit.1[i], l.2 = limit.1[i+1], l.3 = limit.2[j], l.4 = limit.2[j+1])
  			temp[[4]] <- lapply(temp.4, indexing, l.1 = limit.1[i], l.2 = limit.1[i+1], l.3 = limit.2[j], l.4 = limit.2[j+1])
  			temp[[5]] <- lapply(temp.5, indexing, l.1 = limit.1[i], l.2 = limit.1[i+1], l.3 = limit.2[j], l.4 = limit.2[j+1])
  			temp[[6]] <- lapply(temp.6, indexing, l.1 = limit.1[i], l.2 = limit.1[i+1], l.3 = limit.2[j], l.4 = limit.2[j+1])

  			temp.c[[1]] <- lapply(temp.1.c, indexing, l.1 = limit.1[i], l.2 = limit.1[i+1], l.3 = limit.2[j], l.4 = limit.2[j+1])
  			temp.c[[2]] <- lapply(temp.2.c, indexing, l.1 = limit.1[i], l.2 = limit.1[i+1], l.3 = limit.2[j], l.4 = limit.2[j+1])
  			temp.c[[3]] <- lapply(temp.3.c, indexing, l.1 = limit.1[i], l.2 = limit.1[i+1], l.3 = limit.2[j], l.4 = limit.2[j+1])
  			temp.c[[4]] <- lapply(temp.4.c, indexing, l.1 = limit.1[i], l.2 = limit.1[i+1], l.3 = limit.2[j], l.4 = limit.2[j+1])
  			temp.c[[5]] <- lapply(temp.5.c, indexing, l.1 = limit.1[i], l.2 = limit.1[i+1], l.3 = limit.2[j], l.4 = limit.2[j+1])
  			temp.c[[6]] <- lapply(temp.6.c, indexing, l.1 = limit.1[i], l.2 = limit.1[i+1], l.3 = limit.2[j], l.4 = limit.2[j+1])

  			tempna[[1]] <- indexing.na(temp.1na[[1]], temp.1na[[2]], l.1 = limit.1[i], l.2 = limit.1[i+1], l.3 = limit.2[j], l.4 = limit.2[j+1])
  			tempna[[2]] <- indexing.na(temp.2na[[1]], temp.2na[[2]], l.1 = limit.1[i], l.2 = limit.1[i+1], l.3 = limit.2[j], l.4 = limit.2[j+1])
  			tempna[[3]] <- indexing.na(temp.3na[[1]], temp.3na[[2]], l.1 = limit.1[i], l.2 = limit.1[i+1], l.3 = limit.2[j], l.4 = limit.2[j+1])
  			tempna[[4]] <- indexing.na(temp.4na[[1]], temp.4na[[2]], l.1 = limit.1[i], l.2 = limit.1[i+1], l.3 = limit.2[j], l.4 = limit.2[j+1])
  			tempna[[5]] <- indexing.na(temp.5na[[1]], temp.5na[[2]], l.1 = limit.1[i], l.2 = limit.1[i+1], l.3 = limit.2[j], l.4 = limit.2[j+1])
  			tempna[[6]] <- indexing.na(temp.6na[[1]], temp.6na[[2]], l.1 = limit.1[i], l.2 = limit.1[i+1], l.3 = limit.2[j], l.4 = limit.2[j+1])

  			lims <- c(n.lim.1[i], n.lim.2[j])
  			lims.2 <- c(limit.1[i], limit.2[j])

  			step1 <- list(temp, temp.c, tempna, lims, lims.2, list.id)
  			rm(temp, temp.c, tempna)
  			gc()

  			step2 <- m.func(step1)
  			rm(step1)
  			gc()

  			step2
  		}

  	stopCluster(cl)

  	rm(temp.1, temp.2, temp.3, temp.4, temp.5, temp.6)
  	rm(temp.1.c, temp.2.c, temp.3.c, temp.4.c, temp.5.c, temp.6.c)
  	rm(temp.1na, temp.2na, temp.3na, temp.4na, temp.5na, temp.6na)

  	temp <- do.call('rbind', gammas)
	  rm(gammas); gc()
  	return(temp)
}

## ------------------------
## End of matcheLink
## ------------------------

