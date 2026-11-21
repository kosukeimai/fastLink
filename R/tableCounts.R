#' tableCounts
#'
#' Count pairs with the same pattern in the cross product between two datasets.
#'
#' @usage tableCounts(gammalist, nobs.a, nobs.b, n.cores)
#'
#' @param gammalist A list of objects produced by gammaKpar, gammaCK2par, or
#' gammaCKpar. Up to 17 fields can be encoded exactly.
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
    
    fields <- length(gammalist)
    if (fields > 17L) {
        stop("At most 17 comparison fields fit in a numeric pattern ID.")
    }

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

    ids <- sort(unique(temp[, 1]))
    counts <- as.numeric(rowsum(temp[, 2], match(temp[, 1], ids)))
    patterns <- matrix(0, nrow = length(ids), ncol = fields)
    valid <- rep(TRUE, length(ids))

    ## Each field occupies three bits starting at bit 1. The C++ encoder
    ## uses 0 for disagreement, 1 for partial, 2 for exact and 4 for missing.
    for (j in seq_len(fields)) {
        digit <- floor(ids / 2^(1 + 3 * (j - 1))) %% 8
        valid <- valid & digit %in% c(0, 1, 2, 4)
        digit[digit == 4] <- NA_real_
        patterns[, j] <- digit
    }
    data.new <- cbind(patterns, counts)
    colnames(data.new) <- c(paste0("gamma.", seq_len(fields)), "counts")
    data.new <- data.new[valid & counts > 0, ]
    class(data.new) <- c("fastLink", "tableCounts")
    return(data.new)
    
}

## ------------------------
## End of tableCounts
## ------------------------

