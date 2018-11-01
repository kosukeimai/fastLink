#' gammaNUMCK2par
#'
#' Field comparisons for numeric variables. Two possible agreement patterns are considered:
#' 0 total disagreement, 2 agreement.
#' The distance between numbers is calculated using their absolute distance.
#'
#' @usage gammaNUMCK2par(matAp, matBp, n.cores, cut.a)
#'
#' @param matAp vector storing the comparison field in data set 1
#' @param matBp vector storing the comparison field in data set 2
#' @param n.cores Number of cores to parallelize over. Default is NULL.
#' @param cut.a Lower bound for full match. Default is 1
#'
#' @return \code{gammaNUMCK2par} returns a list with the indices corresponding to each
#' matching pattern, which can be fed directly into \code{tableCounts} and \code{matchesLink}.
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com>, Ben Fifield <benfifield@gmail.com>, and Kosuke Imai
#'
#' @examples
#' \dontrun{
#' g1 <- gammaNUMCK2par(dfA$birthyear, dfB$birthyear)
#' }
#' @export

## ------------------------
## gammaNUMCK2par: Now it takes values 0, 2
## This function applies gamma.k
## in parallel
## ------------------------
gammaNUMCK2par <- function(matAp, matBp, n.cores = NULL, cut.a = 1) {
    
    if(any(class(matAp) %in% c("tbl_df", "data.table"))){
        matAp <- as.data.frame(matAp)[,1]
    }
    if(any(class(matBp) %in% c("tbl_df", "data.table"))){
        matBp <- as.data.frame(matBp)[,1]
    }
    
    matAp[matAp == ""] <- NA
    matBp[matBp == ""] <- NA

    if(sum(is.na(matAp)) == length(matAp) | length(unique(matAp)) == 1){
        cat("WARNING: You have no variation in this variable, or all observations are missing in dataset A.\n")
    }
    if(sum(is.na(matBp)) == length(matBp) | length(unique(matBp)) == 1){
        cat("WARNING: You have no variation in this variable, or all observations are missing in dataset B.\n")
    }
    
    if(is.null(n.cores)) {
        n.cores <- detectCores() - 1
    }

    matrix.1 <- as.matrix(as.numeric(matAp))
    matrix.2 <- as.matrix(as.numeric(matBp))

    max <- max(max(matrix.1, na.rm = T), max(matrix.2, na.rm = T))   
    end.points <- c((round((max), 0) + 1), (round(max + cut.a, 0) + 3))
    matrix.1[is.na(matrix.1)] <- end.points[2]
    matrix.2[is.na(matrix.2)] <- end.points[1]

    u.values.1 <- unique(matrix.1)
    u.values.2 <- unique(matrix.2)

    n.slices1 <- max(round(length(u.values.1)/(4500), 0), 1) 
    n.slices2 <- max(round(length(u.values.2)/(4500), 0), 1) 

    limit.1 <- round(quantile((0:nrow(u.values.2)), p = seq(0, 1, 1/n.slices2)), 0)
    limit.2 <- round(quantile((0:nrow(u.values.1)), p = seq(0, 1, 1/n.slices1)), 0)

    temp.1 <- temp.2 <- list()

    n.cores2 <- min(n.cores, n.slices1 * n.slices2)
    
    for(i in 1:n.slices2) {
        temp.1[[i]] <- list(u.values.2[(limit.1[i]+1):limit.1[i+1]], limit.1[i])
    }

    for(i in 1:n.slices1) {
        temp.2[[i]] <- list(u.values.1[(limit.2[i]+1):limit.2[i+1]], limit.2[i])
    }

    difference <- function(m, y, cut) {

        x <- as.matrix(m[[1]])
        e <- as.matrix(y[[1]])        

        t <- calcPWDcpp(as.matrix(x), as.matrix(e))
        t[ t == 0 ] <- cut[1]
        t[ t > cut ] <- 0
        t <- Matrix(t, sparse = T)
        
        t@x[t@x <= cut] <- 2; gc()       	
        slice.1 <- m[[2]]
        slice.2 <- y[[2]]
        indexes.2 <- which(t == 2, arr.ind = T)
        indexes.2[, 1] <- indexes.2[, 1] + slice.2
        indexes.2[, 2] <- indexes.2[, 2] + slice.1
        list(indexes.2)
    }

    do <- expand.grid(1:n.slices2, 1:n.slices1)

    if (n.cores2 == 1) '%oper%' <- foreach::'%do%'
    else { 
        '%oper%' <- foreach::'%dopar%'
        cl <- makeCluster(n.cores2)
        registerDoParallel(cl)
        on.exit(stopCluster(cl))
    }

    temp.f <- foreach(i = 1:nrow(do), .packages = c("Rcpp", "Matrix")) %oper% {
        r1 <- do[i, 1]
        r2 <- do[i, 2]
        difference(temp.1[[r1]], temp.2[[r2]], cut.a)
    }

    gc()

    reshape2 <- function(s) { s[[1]] }
    temp.2 <- lapply(temp.f, reshape2)

    indexes.2 <- do.call('rbind', temp.2)

    ht1 <- new.env(hash=TRUE)
    ht2 <- new.env(hash=TRUE)

    n.values.2 <- as.matrix(cbind(u.values.1[indexes.2[, 2]], u.values.2[indexes.2[, 1]]))
    matches.2 <- lapply(seq_len(nrow(n.values.2)), function(i) n.values.2[i, ])

    if(Sys.info()[['sysname']] == 'Windows') {
        if (n.cores == 1) '%oper%' <- foreach::'%do%'
        else { 
            '%oper%' <- foreach::'%dopar%'
            cl <- makeCluster(n.cores)
            registerDoParallel(cl)
            on.exit(stopCluster(cl))
        }

        final.list2 <- foreach(i = 1:length(matches.2)) %oper% {
            ht1 <- which(matrix.1 == matches.2[[i]][[1]]); ht2 <- which(matrix.2 == matches.2[[i]][[2]])
            list(ht1, ht2)
      	}

    } else {
        no_cores <- n.cores
        final.list2 <- mclapply(matches.2, function(s){
            ht1 <- which(matrix.1 == s[1]); ht2 <- which(matrix.2 == s[2]);
            list(ht1, ht2) }, mc.cores = getOption("mc.cores", no_cores))
    }
    
    na.list <- list()
    na.list[[1]] <- which(matrix.1 == end.points[2])
    na.list[[2]] <- which(matrix.2 == end.points[1])

    out <- list()
    out[["matches2"]] <- final.list2
    out[["nas"]] <- na.list
    class(out) <- c("fastLink", "gammaNUMCK2par")
    
    return(out)
}


## ------------------------
## End of gammaNUMKpar
## ------------------------

