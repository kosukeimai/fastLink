#' gammaCK2par
#'
#' Field comparisons for string variables. Two possible agreement patterns are considered:
#' 0 total disagreement, 2 agreement.
#' The distance between strings is calculated using a Jaro-Winkler distance.
#'
#' @usage gammaCK2par(matAp, matBp, n.cores, cut.a, method, w)
#'
#' @param vecA vector storing the comparison field in data set 1
#' @param vecB vector storing the comparison field in data set 2
#' @param n.cores Number of cores to parallelize over. Default is NULL.
#' @param cut.a Lower bound for full match, ranging between 0 and 1. Default is 0.92
#' @param method String distance method, options are: "jw" Jaro-Winkler (Default), "dl" Damerau-Levenshtein, "jaro" Jaro, and "lv" Edit
#' @param w Parameter that describes the importance of the first characters of a string (only needed if method = "jw"). Default is .10
#'
#' @return \code{gammaCK2par} returns a list with the indices corresponding to each
#' matching pattern, which can be fed directly into \code{tableCounts} and \code{matchesLink}.
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com>, Ben Fifield <benfifield@gmail.com>, and Kosuke Imai
#'
#' @examples
#' \dontrun{
#' g1 <- gammaCK2par(dfA$firstname, dfB$lastname)
#' }
#' @export

## ------------------------
## gammaCK2par: Now it takes values 0, 2
## This function applies gamma.k
## in parallel
## ------------------------
gammaCK2par <- function(vecA,vecB, n.cores = NULL, cut.a = 0.92, method = "jw", w = 0.1) {

    if (is.null(n.cores)) {
        n.cores <- parallel::detectCores() - 1
    }
    if (!is.factor(vecA)) {
        vecA=collapse::qF(vecA,na.exclude = T)
    } 
    if (!is.factor(vecB)) {
        vecB=collapse::qF(vecB,na.exclude = T)
    }

    levels(vecA)[levels(vecA)==""]=NA
    levels(vecB)[levels(vecB)==""]=NA
    u.values.1 <- levels(vecA)
    u.values.2 <- levels(vecB)
    
    # WARNING/STOP block
    if (length(u.values.1) < 2) {
        warning("You have no variation in this variable, or all observations are missing in dataset A.\n")
    }
    if (length(u.values.2) < 2) {
        warning("You have no variation in this variable, or all observations are missing in dataset B.\n")
    }
    if (!(method %in% c("jw", "jaro", "lv", "dl"))) {
        stop("Invalid string distance method. Method should be one of 'jw', 'dl', 'jaro', or 'lv'.")
    }
    if (method == "jw" & !is.null(w)) {
        if (w < 0 | w > 0.25) {
            stop("Invalid value provided for w. Remember, w in [0, 0.25].")
        }
    }
    

    n.slices1 <- max(round(length(u.values.1)/(4000), 0), 1) 
    n.slices2 <- max(round(length(u.values.2)/(4000), 0), 1) 

    limit.1 <- round(quantile((0:length(u.values.2)), p = seq(0, 1, 1/n.slices2)), 0)
    limit.2 <- round(quantile((0:length(u.values.1)), p = seq(0, 1, 1/n.slices1)), 0)
    
    n.cores <- min(n.cores, n.slices1 * n.slices2)


    do <- expand.grid(1:n.slices2, 1:n.slices1)
    
    temp <- list()
    ListPointer <- setRefClass("ListPointer",
                               fields = list(data1 = "matrix",
                                             data2 = "matrix",
                                             lim1 = "numeric",
                                             lim2 = "numeric"))
    factorPointer <- setRefClass("FactorPointer",
                                 fields=list(f1="numeric",
                                             f2="numeric"))
    facs=factorPointer$new(f1=as.numeric(vecA),
                           f2=as.numeric(vecB))
    
    for (i in 1:nrow(do)) {
        i1=do[i,2]
        i2=do[i,1]
        temp[[i]] <- ListPointer$new(
          data1=as.matrix(u.values.2[(limit.1[i2] + 1):limit.1[i2+1]]),
          data2=as.matrix(u.values.1[(limit.2[i1] + 1):limit.2[i1 + 1]]),
          lim1=limit.1[i2],
          lim2=limit.2[i1])
    }

    stringvec <- function(m, fa, cut=cut.a, strdist = method, p1 = w,
                          stringdistmatrix=stringdist::stringdistmatrix) {
        library(Matrix)
        
        x <- m$data1
        e <- m$data2        
        
        if(strdist == "jw") {
            t <- 1 - stringdistmatrix(e, x, method = "jw", p = p1, nthread = 1)
            t[ t < cut ] <- 0
            t <- Matrix(t, sparse = T)
        }

        if(strdist == "jaro") {
            t <- 1 - stringdistmatrix(e, x, method = "jw", nthread = 1)
            t[ t < cut ] <- 0
            t <- Matrix(t, sparse = T)
        }

        if(strdist == "lv") {
            t <- stringdistmatrix(e, x, method = "lv", nthread = 1)
            t.1 <- nchar(as.matrix(e))
            t.2 <- nchar(as.matrix(x))
            o <- t(apply(t.1, 1, function(w){ ifelse(w >= t.2, w, t.2)}))
            t <- 1 - t * (1/o)
            t[ t < cut ] <- 0
            t <- Matrix(t, sparse = T)
        }
        
        if(strdist == "dl") {
          t <- stringdistmatrix(e, x, method = "dl", nthread = 1)
          t.1 <- nchar(as.matrix(e))
          t.2 <- nchar(as.matrix(x))
          o <- t(apply(t.1, 1, function(w){ ifelse(w >= t.2, w, t.2)}))
          t <- 1 - t * (1/o)
          t[ t < cut ] <- 0
          t <- Matrix(t, sparse = T)
        }
        
        if(is(t, "ddiMatrix")) {
          t <- t * 2
        } else {
          t@x[t@x >= cut] <- 2
        }
        gc()
        
        slice.1 <- m$lim1
        slice.2 <- m$lim2
        indexes.2 <- which(t == 2, arr.ind = T)
        indexes.2[, 1] <- indexes.2[, 1] + slice.2
        indexes.2[, 2] <- indexes.2[, 2] + slice.1

        get_inds<-function(vec,indc) {
            Map(function(x) base::which(vec==x, useNames = T), indc,USE.NAMES=F)
        }
        if (nrow(indexes.2) > 0) {
            list(lapply(1:nrow(indexes.2), function(x) {
                c(get_inds(fa$f1,indexes.2[x,1]),
                  get_inds(fa$f2,indexes.2[x,2]))
            }))
        } else {
            list(list())
        }
        
    }

    cl <- parallel::makeCluster(n.cores)
    on.exit(parallel::stopCluster(cl))
    temp.f <- parallel::parSapply(cl, temp, stringvec,
                                  cut = cut.a,
                                  strdist = method,
                                  p1 = w,
                                  fa = facs)

    

    names(temp.f) <- c("matches2")
    if (length(temp.f$matches2) == 0) {
        warning("There are no identical (or nearly identical) matches. We suggest changing the value of cut.a")
    }
    
    
    temp.f[["nas"]] =  list(
        which(is.na(vecA)),
        which(is.na(vecB))
    )
    
    class(temp.f) <- c("fastLink", "gammaCK2par")
    
    return(temp.f)
}



## ------------------------
## End of gammaCK2par
## ------------------------

