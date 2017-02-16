#' matchesLink
#'
#' matchesLink produces two dataframes that store
#' all the pairs that share a pattern that conforms
#' to the an interval of the Fellegi-Sunter
#' weights
#'
#' @param gammalist A list of objects produced by either gammaKpar or
#' gammaCKpar. 
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

matchesLink <- function(gammalist, nr1 = w, nr2 = p, em = y, cut = z) {

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

    ind.i <- ind.j <- 1:n.slices
    ind <- as.matrix(expand.grid(ind.i, ind.j))

    ## Run the function
    gammas <- m_func_par(temp = temp, ptemp = ptemp, natemp = natemp,
                         limit1 = limit.1, limit2 = limit.2,
                         nlim1 = n.lim.1, nlim2 = n.lim.2,
                         ind = ind, listid = list.id,
                         matchesLink = TRUE, threads = nc)
    gammas_mat <- lapply(gammas, function(x){
        as.matrix(data.frame(x[[1]], x[[2]]))
    })
    rm(temp, ptemp, natemp)

    temp <- do.call('rbind', gammas_mat)
    temp <- temp + 1
    rm(gammas, gammas_mat); gc()
    return(temp)
}

## ------------------------
## End of matcheLink
## ------------------------

