#' tableCounts
#'
#' Count pairs with the same pattern in the cross product between two datasets.
#'
#' @param gammalist A list of objects produced by either gammaKpar or
#' gammaCKpar. 
#' @param nr1 number of observations in dataset 1
#' @param nr2 number of observations in dataset 2
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com> and Kosuke Imai
#'
#' @export

## ------------------------
## To count unique patterns:
## tableCounts is the
## functions that does the trick
## ------------------------

tableCounts <- function(gammalist = NULL, nr1 = y, nr2 = z) {

    ## Lists of indices:
    ##     temp - exact
    ##     ptemp - partial
    ##     natemp - NAs
    temp <- vector(mode = "list", length = length(gammalist))
    ptemp <- vector(mode = "list", length = length(gammalist))
    natemp <- vector(mode = "list", length = length(gammalist))
    for(i in 1:length(gammalist)){
        temp[[i]] <- gammalist[[i]]$matches2
        ptemp[[i]] <- gammalist[[i]]$matches1
        natemp[[i]] <- gammalist[[i]]$nas
    }

    ## Slicing the data:
    n.slices <- round(max(as.numeric(nr1), as.numeric(nr2))/(4900), 0)
    if(n.slices == 0){
        n.slices <- 1
    }

    nc <- min((detectCores() - 1), n.slices^2)

    ## Prep objects for m_func_par
    limit.1 <- round(quantile((0:nr1), p = seq(0,1,1/n.slices)),0)
    limit.2 <- round(quantile((0:nr2), p = seq(0,1,1/n.slices)),0)
    last <- length(limit.1)
    n.lim.1 <- limit.1[-1] - limit.1[-last]
    n.lim.2 <- limit.2[-1] - limit.2[-last]

    ind.i <- ind.j <- 1:n.slices
    ind <- expand.grid(ind.i, ind.j)

    ## Run main function
    gammas <- m_func_par(temp, ptemp, natemp,
                         limit.1, limit.2,
                         n.lim.1, n.lim.2,
                         ind, nc)

    temp <- do.call('rbind', gammas)
    rm(gammas); gc()

    counts.f <- as.matrix(tapply(as.numeric(temp[, 2]), temp[, 1], sum))
    counts.d <- cbind( as.numeric(row.names(counts.f)), counts.f)
    colnames(counts.d) <- c("pattern.id", "count")

    ## Merge Counts
    seq <- 1:18
    b <- 2^(seq)
    patterns <- expand.grid( c(b[1:3], 0), c(b[4:6], 0), c(b[7:9], 0), c(b[10:12], 0), c(b[13:15], 0), c(b[16:18], 0))
    pattern.id <- rowSums(patterns)
    patterns <- cbind(patterns, pattern.id)
    data.new.0 <- merge(patterns, counts.d, by = "pattern.id")
    data.new.0 <- data.new.0[,-1]

    b<-2
    patterns.2 <- t((c(1/b^1, 1/b^4, 1/b^7, 1/b^10, 1/b^13, 1/b^16)) * t(data.new.0[,1:6]))
    data.new.1 <- cbind(patterns.2, data.new.0[,7])
    names <- c("gamma.1", "gamma.2", "gamma.3", "gamma.4", "gamma.5", "gamma.6", "counts")
    colnames(data.new.1) <- names
    data.new.1 <- data.new.1[, colSums(data.new.1) != 0]
    nc <- ncol(data.new.1)
    na.data.new <- data.new.1[, -c(nc)]
    na.data.new[na.data.new == 4] <- NA
    data.new <- cbind(na.data.new, data.new.1[, nc])
    colnames(data.new)[nc] <- "counts"
    return(data.new)
    
}

## ------------------------
## End of tableCounts
## ------------------------

