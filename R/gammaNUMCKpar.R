#' gammaNUMCKpar
#'
#' Field comparisons for numeric variables. Three possible agreement patterns are considered:
#' 0 total disagreement, 1 partial agreement, 2 agreement.
#' The distance between numbers is calculated using their absolute distance.
#'
#' @usage gammaNUMCKpar(matAp, matBp, n.cores, cut.a, cut.p)
#'
#' @param matAp vector storing the comparison field in data set 1
#' @param matBp vector storing the comparison field in data set 2
#' @param n.cores Number of cores to parallelize over. Default is NULL.
#' @param cut.a Lower bound for full match. Default is 1
#' @param cut.p Lower bound for partial match. Default is 2
#'
#' @return \code{gammaNUMCKpar} returns a list with the indices corresponding to each
#' matching pattern, which can be fed directly into \code{tableCounts} and \code{matchesLink}.
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com>, Ben Fifield <benfifield@gmail.com>, and Kosuke Imai
#'
#' @examples
#' \dontrun{
#' g1 <- gammaNUMCKpar(dfA$birthyear, dfB$birthyear)
#' }
#' @export
gammaNUMCKpar <- function(matAp, matBp, n.cores = NULL, cut.a = 1, cut.p = 2) {

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
    end.points <- c((round((max), 0) + 1), (round(max + cut.p, 0) + 3))
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
        t[ t > cut[2] ] <- 0
        t <- Matrix(t, sparse = T)

        t@x[t@x <= cut[1]] <- cut[2] + 1; gc()       	                
        t@x[t@x > cut[1] & t@x <= cut[2]] <- 1; gc()       	

        slice.1 <- m[[2]]
        slice.2 <- y[[2]]
        indexes.2 <- which(t == cut[2] + 1, arr.ind = T)
        indexes.2[, 1] <- indexes.2[, 1] + slice.2
        indexes.2[, 2] <- indexes.2[, 2] + slice.1
        indexes.1 <- which(t == 1, arr.ind = T)
        indexes.1[, 1] <- indexes.1[, 1] + slice.2
        indexes.1[, 2] <- indexes.1[, 2] + slice.1
        list(indexes.2, indexes.1)
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
        difference(temp.1[[r1]], temp.2[[r2]], c(cut.a, cut.p))
    }

    gc()

    reshape2 <- function(s) { s[[1]] }
    reshape1 <- function(s) { s[[2]] }
    temp.2 <- lapply(temp.f, reshape2)
    temp.1 <- lapply(temp.f, reshape1)
    
    indexes.2 <- do.call('rbind', temp.2)
    indexes.1 <- do.call('rbind', temp.1)

    n.values.2 <- as.matrix(cbind(u.values.1[indexes.2[, 2]], u.values.2[indexes.2[, 1]]))
    n.values.1 <- as.matrix(cbind(u.values.1[indexes.1[, 2]], u.values.2[indexes.1[, 1]]))
    
    matches.2 <- lapply(seq_len(nrow(n.values.2)), function(i) n.values.2[i, ])
    matches.1 <- lapply(seq_len(nrow(n.values.1)), function(i) n.values.1[i, ])
    
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
        
        final.list1 <- foreach(i = 1:length(matches.1)) %oper% {
            ht1 <- which(matrix.1 == matches.1[[i]][[1]]); ht2 <- which(matrix.2 == matches.1[[i]][[2]])
            list(ht1, ht2)
        }
##        if(n.cores > 1){
##            stopCluster(cl)
##        }
    } else {
        no_cores <- n.cores
        final.list2 <- mclapply(matches.2, function(s){
            ht1 <- which(matrix.1 == s[1]); ht2 <- which(matrix.2 == s[2]);
            list(ht1, ht2) }, mc.cores = getOption("mc.cores", no_cores))
        
        final.list1 <- mclapply(matches.1, function(s){
            ht1 <- which(matrix.1 == s[1]); ht2 <- which(matrix.2 == s[2]);
            list(ht1, ht2) }, mc.cores = getOption("mc.cores", no_cores))
    }
    
    na.list <- list()
    na.list[[1]] <- which(matrix.1 == end.points[2])
    na.list[[2]] <- which(matrix.2 == end.points[1])
    
    out <- list()
    out[["matches2"]] <- final.list2
    out[["matches1"]] <- final.list1
    out[["nas"]] <- na.list
    class(out) <- c("fastLink", "gammaNUMCKpar")
    
    return(out)
}


## ------------------------
## End of gammaNUMCKpar
## ------------------------

