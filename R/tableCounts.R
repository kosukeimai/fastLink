#' tableCounts
#'
#' Count pairs with the same pattern in the cross product between two datasets.
#'
#' @usage tableCounts(gammalist, nobs.a, nobs.b, n.cores)
#'
#' @param gammalist A list of objects produced by gammaKpar, gammaCK2par, or
#' gammaCKpar. 
#' @param nobs.a number of observations in dataset 1
#' @param nobs.b number of observations in dataset 2
#' @param n.cores Number of cores to parallelize over. Default is NULL.
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com>, Ben Fifield <benfifield@gmail.com>, and Kosuke Imai
#'
#' @return \code{tableCounts} returns counts of all unique mathching patterns, which can be
#' fed directly into \code{emlinkMAR} to get posterior matching probabilities for each unique pattern.
#'
#' @examples
#' \dontrun{
#' ## Calculate gammas
#' g1 <- gammaCKpar(dfA$firstname, dfB$firstname)
#' g2 <- gammaCKpar(dfA$middlename, dfB$middlename)
#' g3 <- gammaCKpar(dfA$lastname, dfB$lastname)
#' g4 <- gammaKpar(dfA$birthyear, dfB$birthyear)
#'
#' ## Run tableCounts
#' tc <- tableCounts(list(g1, g2, g3, g4), nobs.a = nrow(dfA), nobs.b = nrow(dfB))
#' }
#' @export
#' @importFrom parallel detectCores makeCluster stopCluster mclapply
#' @importFrom doParallel registerDoParallel
#' @importFrom foreach "%dopar%" "%do%" foreach
## ------------------------
## To count unique patterns:
## tableCounts is the
## functions that does the trick
## ------------------------

tableCounts <- function(gammalist, nobs.a, nobs.b, n.cores = NULL) {
    
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
    n.slices1 <- max(round(as.numeric(nobs.a)/(10000), 0), 1) 
    n.slices2 <- max(round(as.numeric(nobs.b)/(10000), 0), 1) 
    
    if(is.null(n.cores)) {
        n.cores <- detectCores() - 1
    }
    
    nc <- min(n.cores, n.slices1 * n.slices2)

    ## Prep objects for m_func_par
    limit.1 <- round(quantile((0:nobs.a), p = seq(0, 1, 1/n.slices1)), 0)
    limit.2 <- round(quantile((0:nobs.b), p = seq(0, 1, 1/n.slices2)), 0)

    last1 <- length(limit.1)
    last2 <- length(limit.2)

    n.lim.1 <- limit.1[-1] - limit.1[-last1]
    n.lim.2 <- limit.2[-1] - limit.2[-last2]

    ind.i <- 1:n.slices1
    ind.j <- 1:n.slices2
    ind <- as.matrix(expand.grid(ind.i, ind.j))

    ## Run main function
    if(Sys.info()[['sysname']] == 'Darwin') {
        if (nc == 1) '%oper%' <- foreach::'%do%'
        else { 
            '%oper%' <- foreach::'%dopar%'
            cl <- makeCluster(nc)
            registerDoParallel(cl)
            on.exit(stopCluster(cl))
        }

        gammas <- foreach(i = 1:nrow(ind)) %oper% {
            m_func_par(temp = temp, ptemp = ptemp, natemp = natemp,
                       limit1 = limit.1, limit2 = limit.2,
                       nlim1 = n.lim.1, nlim2 = n.lim.2,
                       ind = as.matrix(t(ind[i, ])), listid = rep(1, 2),
                       matchesLink = FALSE, threads = 1)
      	}
        
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
    
    rm(gammas); rm(gammas_mat); gc()

    counts.f <- as.matrix(tapply(as.numeric(temp[, 2]), temp[, 1], sum))
    counts.d <- cbind( as.numeric(row.names(counts.f)), counts.f)
    colnames(counts.d) <- c("pattern.id", "count")

    ## Merge Counts
    seq <- 1:(length(gammalist)*3)
    b <- 2^(seq)
    patterns.vec <- matrix(NA, 4, length(gammalist))
    for(i in 1:length(gammalist)){
        patterns.vec[,i] <- c(b[1:3 + (i-1)*3], 0)
    }
    patterns <- expand.grid(as.data.frame(patterns.vec))
    pattern.id <- rowSums(patterns)
    patterns <- cbind(patterns, pattern.id)
    data.new.0 <- merge(patterns, counts.d, by = "pattern.id")
    data.new.0 <- data.new.0[,-1]

    b<-2
    patterns.2vec <- c()
    for(i in 1:length(gammalist)){
        patterns.2vec <- c(patterns.2vec, 1/b^(1 + (i-1)*3))
    }
    patterns.2 <- t((patterns.2vec) * t(data.new.0[,1:length(gammalist)]))
    data.new.1 <- cbind(patterns.2, data.new.0[,length(gammalist)+1])
    names <- c(paste0("gamma.", 1:length(gammalist)), "counts")
    colnames(data.new.1) <- names
    sub.nc <- which(colSums(data.new.1) == 0)
    sub.nc <- sub.nc[sub.nc > length(gammalist)]
    if(length(sub.nc) > 0){
        data.new.1 <- data.new.1[, -sub.nc]
    }
    nc <- ncol(data.new.1)
    na.data.new <- data.new.1[, -c(nc), drop = FALSE]
    na.data.new[na.data.new == 4] <- NA
    data.new <- cbind(na.data.new, data.new.1[, nc])
    colnames(data.new)[nc] <- "counts"
    data.new <- data.new[data.new[, nc] > 0, ]
    class(data.new) <- c("fastLink", "tableCounts")
    return(data.new)
    
}

## ------------------------
## End of tableCounts
## ------------------------

