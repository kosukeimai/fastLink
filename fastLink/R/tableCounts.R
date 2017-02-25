#' tableCounts
#'
#' Count pairs with the same pattern in the cross product between two datasets.
#'
#' @param gammalist A list of objects produced by either gammaKpar or
#' gammaCKpar. 
#' @param nr1 number of observations in dataset 1
#' @param nr2 number of observations in dataset 2
#' @n.cores number of cores
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com>, Ben Fifield <benfifield@gmail.com>, and Kosuke Imai
#'
#' @export

## ------------------------
## To count unique patterns:
## tableCounts is the
## functions that does the trick
## ------------------------

tableCounts <- function(gammalist, nr1 = y, nr2 = z, n.cores = NULL) {
    
    ## Lists of indices:
    ##     temp - exact
    ##     ptemp - partial
    ##     natemp - NAs
    temp <- vector(mode = "list", length = length(gammalist))
    ptemp <- vector(mode = "list", length = length(gammalist))
    natemp <- vector(mode = "list", length = length(gammalist))

    for(i in 1:length(gammalist)){
        temp[[i]] <- gammalist[[i]]$matches2
        if(!is.null(gammalist[[i]]$matches1)) {
            ptemp[[i]] <- gammalist[[i]]$matches1
        }
        natemp[[i]] <- gammalist[[i]]$nas
    }

    ## Slicing the data:
    n.slices1 <- max(round(as.numeric(nr1)/(4500), 0), 1) 
    n.slices2 <- max(round(as.numeric(nr2)/(4500), 0), 1) 
    
    if(is.null(n.cores)) {
        n.cores <- detectCores() - 1
    }
    
    nc <- min(n.cores, n.slices1 * n.slices2)

    ## Prep objects for m_func_par
    limit.1 <- round(quantile((0:nr1), p = seq(0, 1, 1/n.slices1)), 0)
    limit.2 <- round(quantile((0:nr2), p = seq(0, 1, 1/n.slices2)), 0)

    last1 <- length(limit.1)
    last2 <- length(limit.2)

    n.lim.1 <- limit.1[-1] - limit.1[-last1]
    n.lim.2 <- limit.2[-1] - limit.2[-last2]

    ind.i <- 1:n.slices1
    ind.j <- 1:n.slices2
    ind <- as.matrix(expand.grid(ind.i, ind.j))

    ## Run main function
    cat("Starting gamma calculation\n")
    if(Sys.info()[['sysname']] == 'Darwin') {
        cat("Parallelizing gamma calculation using", nc, "cores.\n")
    	cl <- makeCluster(nc)
    	registerDoParallel(cl)

        gammas <- foreach(i = 1:nrow(ind)) %dopar% {
            m_func_par(temp = temp, ptemp = ptemp, natemp = natemp,
                       limit1 = limit.1, limit2 = limit.2,
                       nlim1 = n.lim.1, nlim2 = n.lim.2,
                       ind = as.matrix(t(ind[i, ])), listid = rep(1, 2),
                       matchesLink = FALSE, threads = 1)
      	}

      	stopCluster(cl)
        
	gammas_mat <- list()
	for(i in 1:length(gammas)){
            temp0 <- gammas[[i]]	
            temp1 <- as.matrix(lapply(temp0, function(x){
                as.matrix(data.frame(x[[1]], x[[2]]))
            }))
            gammas_mat[[i]] <- temp1[[1]] 
        }
	rm(temp0, temp1)	

        temp <- do.call('rbind', gammas_mat)

    } else {

        gammas <- m_func_par(temp = temp, ptemp = ptemp, natemp = natemp,
                             limit1 = limit.1, limit2 = limit.2,
                             nlim1 = n.lim.1, nlim2 = n.lim.2,
                             ind = ind, listid = rep(1, 2),
                             matchesLink = FALSE, threads = nc)

        gammas_mat <- lapply(gammas, function(x){
            as.matrix(data.frame(x[[1]], x[[2]]))
        })
        
        temp <- do.call('rbind', gammas_mat)
    }
    cat("Ending gamma calculation\n")
    
    rm(gammas); rm(gammas_mat); gc()

    counts.f <- as.matrix(tapply(as.numeric(temp[, 2]), temp[, 1], sum))
    counts.d <- cbind( as.numeric(row.names(counts.f)), counts.f)
    cat("Dimensions of count.d are ", dim(counts.d), " and class of counts.d is ", class(counts.d), "\n")
    colnames(counts.d) <- c("pattern.id", "count")
    cat("Constructing counts matrices\n")

    ## Merge Counts
    seq <- 1:(length(gammalist)*3)
    b <- 2^(seq)
    patterns.vec <- matrix(NA, 4, length(gammalist))
    for(i in 1:length(gammalist)){
        patterns.vec[,i] <- c(b[1:3 + (i-1)*3], 0)
    }
    cat("Getting patterns vector\n")
    patterns <- expand.grid(as.data.frame(patterns.vec))
    cat("Expanding grid\n")
    pattern.id <- rowSums(patterns)
    patterns <- cbind(patterns, pattern.id)
    data.new.0 <- merge(patterns, counts.d, by = "pattern.id")
    data.new.0 <- data.new.0[,-1]
    cat("Merged counts\n")

    b<-2
    patterns.2vec <- c()
    for(i in 1:length(gammalist)){
        patterns.2vec <- c(patterns.2vec, 1/b^(1 + (i-1)*3))
    }
    patterns.2 <- t((patterns.2vec) * t(data.new.0[,1:length(gammalist)]))
    data.new.1 <- cbind(patterns.2, data.new.0[,length(gammalist)+1])
    names <- c(paste0("gamma.", 1:length(gammalist)), "counts")
    cat("Dimensions of data.new.1 are ", dim(data.new.1), " and class of data.new.1 is ", class(data.new.1), "\n")
    colnames(data.new.1) <- names
    data.new.1 <- data.new.1[, colSums(data.new.1) != 0]
    nc <- ncol(data.new.1)
    na.data.new <- data.new.1[, -c(nc)]
    na.data.new[na.data.new == 4] <- NA
    data.new <- cbind(na.data.new, data.new.1[, nc])
    colnames(data.new)[nc] <- "counts"
    cat("Constructed output object\n")
    return(data.new)
    
}

## ------------------------
## End of tableCounts
## ------------------------

