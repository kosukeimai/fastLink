#' matchesLink
#'
#' matchesLink produces two dataframes that store
#' all the pairs that share a pattern that conforms
#' to the an interval of the Fellegi-Sunter
#' weights
#'
#' @usage matchesLink(gammalist, nobs.a, nobs.b, em, thresh, n.cores = NULL)
#'
#' @param gammalist A list of objects produced by either gammaKpar or
#' gammaCKpar. 
#' @param nobs.a number of observations in dataset 1
#' @param nobs.b number of observations in dataset 2
#' @param em parameters obtained from the Expectation-Maximization algorithm under the MAR assumption. These estimates are
#' produced by emlinkMARmov
#' @param thresh is the interval of posterior zeta values for the agreements that we want to examine closer. Ranges between 0 and 1.
#' Can be a vector of length 1 (from specified value to 1) or 2 (from first specified value to second specified value).
#' @param n.cores Number of cores to parallelize over. Default is NULL.
#'
#' @return \code{matchesLink} returns an nmatches X 2 matrix with the indices of the
#' matches rows in dataset A and dataset B.
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com>, Ben Fifield <benfifield@gmail.com>, and Kosuke Imai
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
#'
#' ## Run EM
#' em <- emlinkMAR(tc)
#'
#' ## Get matches
#' ml <- matchesLink(list(g1, g2, g3, g4), nobs.a = nrow(dfA), nobs.b = nrow(dfB),
#' em = em, thresh = .95)
#' }
#'
#' @export

## ------------------------
## To recover the matches (their indices)
## we use matchesLink
## ------------------------

matchesLink <- function(gammalist, nobs.a, nobs.b, em, thresh, n.cores = NULL) {

    if(is.null(n.cores)) {
        n.cores <- detectCores() - 1
    }

    if(min(thresh) < 0 | max(thresh) > 1){
        stop("The specified threshold values are not valid posterior probabilities. These must range between 0 and 1.")
    }

    ## Slicing the data:
    n.slices1 <- max(round(as.numeric(nobs.a)/(10000), 0), 1) 
    n.slices2 <- max(round(as.numeric(nobs.b)/(10000), 0), 1) 
    nc <- min(n.cores, n.slices1 * n.slices2)

    limit.1 <- round(quantile((0:nobs.a), p = seq(0, 1, 1/n.slices1)), 0)
    limit.2 <- round(quantile((0:nobs.b), p = seq(0, 1, 1/n.slices2)), 0)

    last1 <- length(limit.1)
    last2 <- length(limit.2)

    n.lim.1 <- limit.1[-1] - limit.1[-last1]
    n.lim.2 <- limit.2[-1] - limit.2[-last2]

    ## Get the correct cuts
    em.obj <- data.frame(em$patterns.w)
    em.obj$zeta.j <- em$zeta.j
    em.obj <- em.obj[order(em.obj[, "weights"]), ]
    l.t <- thresh[1]
    u.t <- thresh[2]
    
    l.b <- suppressWarnings(min(em.obj$weights[em.obj$zeta.j >= l.t]))
    if(is.na(u.t)){
        u.b <- 1e10
    }else{
        u.b <- max(em.obj$weights[em.obj$zeta.j < u.t])
    }

    tablem <- em$patterns.w[em$patterns.w[, "weights"] >= l.b & em$patterns.w[, "weights"] < u.b, ]
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
    power <- rep(NA, length(gammalist))
    for(i in 1:length(gammalist)){
        power[i] <- 1 + (i-1)*3
    }
    power.s <- power[1:ncol]
    base <- 2^(power.s)
    list <- t(base * t(list))
    list.id <- rowSums(list)

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
                       ind = as.matrix(t(ind[i, ])), listid = list.id,
                       matchesLink = TRUE, threads = 1)
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
                             ind = ind, listid = list.id,
                             matchesLink = TRUE, threads = nc)

        gammas_mat <- lapply(gammas, function(x){
            as.matrix(data.frame(x[[1]], x[[2]]))
        })
        
        temp <- do.call('rbind', gammas_mat)
    }
    
    temp <- temp + 1
    rm(gammas, gammas_mat); gc()

    temp <- data.frame(inds.a = temp[,1], inds.b = temp[,2])
    
    class(temp) <- c("fastLink", "matchesLink")
    
    return(temp)
}

## ------------------------
## End of matcheLink
## ------------------------

