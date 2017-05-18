summarize.em <- function(x, thresholds){

    if("fastLink.EM" %in% class(x)){
        em.out <- x
        EM <- data.frame(em.out$patterns.w)
        EM$zeta.j <- em.out$zeta.j
        EM <- EM[order(EM[, "weights"]), ]
        n1 <- em.out$nobs.a; n2 <- em.out$nobs.b
    }else{
        em.out <- x$EM
        EM <- data.frame(em.out$patterns.w)
        EM$zeta.j <- em.out$zeta.j
        EM <- EM[order(EM[, "weights"]), ]
        n1 <- x$nobs.a; n2 <- x$nobs.b
    }

    count <- min(n1, n2)
    
    ## Containers for thresholds
    mc <- rep(NA, length(thresholds))
    fp <- rep(NA, length(thresholds))
    fn <- rep(NA, length(thresholds))
    for(i in 1:length(thresholds)){
        mc[i] <- min(sum(EM$counts[EM$zeta.j >= thresholds[i]]), min(n1, n2))
        fp[i] <- sum(EM$counts[EM$zeta.j >= thresholds[i]] * 
                     (1 - EM$zeta.j[EM$zeta.j >= thresholds[i]]))
        fn[i] <- sum(EM$counts[EM$zeta.j < thresholds[i]] * (EM$zeta.j[EM$zeta.j < thresholds[i]]))
    }

    ## Expected match rate
    exp.match <- sum(EM$counts * EM$zeta.j)

    ## Expected number of exact matches
    gamma.ind <- grep("gamma.[[:digit:]]", names(EM))
    exact.match.ind <- which(rowSums(EM[,gamma.ind]) == length(gamma.ind)*2)
    if(length(exact.match.ind) == 0){
        exact.matches <- 0
    }else{
        exact.matches <- EM$counts[exact.match.ind]
    }
    
    out <- data.frame(t(c(count, mc, fp, fn, exp.match, exact.matches)))
    names(out) <- c("count", paste0("mc.", thresholds*100), paste0("fp.", thresholds*100),  
                    paste0("fn.", thresholds*100),  "exp.match", "exact.matches")

    return(out)
    
}

summarize.agg <- function(x, weighted){
    
    s.calc <- function(y){
        ## Match rate
        matches <- 100 * (y[,grep("mc.", names(y))]) * (1/y$count)
        ## Exact match rate
        matches.E <- 100 * (y$exact.matches) * (1/y$count) 
        matches <- cbind(matches, matches.E)
        colnames(matches) <- c(names(y)[grep("mc.", names(y))], "matches.E")
        ## FDR
        fdr <- 100 * (y[,grep("fp.", names(y))]) * 1 / (y[,grep("mc.", names(y))])
        names(fdr) <- names(y)[grep("fp.", names(y))]
        ## FNR
        tp <- y[, grep("mc.", names(y))] - y[, grep("fp.", names(y))]
        fn <- y[, grep("fn.", names(y))]
        fnr <- 100 * fn/(tp + fn)
        names(fnr) <- names(y)[grep("fn.", names(y))]
        return(list(fdr = fdr, fnr = fnr, matches = matches))
    }
    
    if(class(x) == "data.frame"){
        out <- s.calc(x)
    }else{
        out <- list()
        out[["within"]] <- s.calc(x[["within"]])
        out[["across"]] <- s.calc(x[["across"]])
        ## -------
        ## Pooling
        ## -------
        ## Matches
        matches <- 100 * (x$within[,grep("mc.", names(x$within))] + x$across[,grep("mc.", names(x$across))]) /
            x$within$count
        matches.E <- 100 * (x$within$exact.matches + x$across$exact.matches) / x$within$count
        matches <- cbind(matches, matches.E)
        colnames(matches) <- c(names(x$within)[grep("mc.", names(x$within))], "matches.E")
        ## FDR
        fdr <- 100 * (x$within[,grep("fp.", names(x$across))] + x$across[,grep("fp.", names(x$across))]) /
            (x$within[,grep("mc.", names(x$within))] + x$across[,grep("mc.", names(x$across))])
        names(fdr) <- names(x$within)[grep("fp.", names(x$within))]
        ## FNR
        tp <- x$within[, grep("mc.", names(x$within))] + x$across[,grep("mc.", names(x$across))] - 
            x$within[, grep("fp.", names(x$within))] - x$across[,grep("fp.", names(x$across))]
        fn <- x$within[, grep("fn.", names(x$within))] + x$across[,grep("fn.", names(x$across))]
        fnr <- 100 * fn/(tp + fn)
        names(fnr) <- names(x$within)[grep("fn.", names(x$within))]
        ## Return object
        out[["pooled"]] <- list(fdr = fdr, fnr = fnr, matches = matches)
        ## ------
        ## Weight 
        ## ------
        if(weighted){
            ## Across-unit matches
            out$across$matches <- out$pooled$matches - out$within$matches
            ## Across and within-unit FDR
            fdr.a <- 100 * (x$across[, grep("fp.", names(x$across))]) / 
                (x$across[,grep("mc.", names(x$across))] + x$within[, grep("mc.", names(x$within))])
            names(fdr.a) <- names(x$across)[grep("fd.", names(x$across))]
            out$across$fdr <- fdr.a
            fdr.w <- 100 * (x$within[, grep("fp.", names(x$within))]) / 
                (x$across[,grep("mc.", names(x$across))] + x$within[, grep("mc.", names(x$within))])
            names(fdr.w) <- names(x$within)[grep("fd.", names(x$within))]
            out$within$fdr <- fdr.w
            ## Across and within-unit FNR
            w.a <- x$across[,grep("mc.", names(x$across))] - x$across[,grep("fp.", names(x$across))] + 
                x$across[,grep("fn.", names(x$across))]
            w.w <- x$within[,grep("mc.", names(x$within))] - x$within[,grep("fp.", names(x$within))] + 
                x$within[,grep("fn.", names(x$within))]
            fnr.a <- w.a * (1/(tp + fn)) * (fnr)
            names(fnr.a) <- names(x$across)[grep("fn.", names(x$across))]
            out$across$fnr <- fnr.a
            fnr.w <- w.w * (1/(tp + fn)) * (fnr)
            names(fnr.w) <- names(x$within)[grep("fn.", names(x$within))]
            out$within$fnr <- fnr.w
        }
    }

    return(out)

}

#' Get summaries of fastLink() objects
#'
#' \code{summary.fastLink()} calculates and outputs FDR, FNR, and match rates for
#' estimates matches from a fastLink() object.
#'
#' @usage \method{summary}{fastLink}(object, thresholds = c(.95, .85, .75), weighted = TRUE, digits = 3, ...)
#' @param object Either a single `fastLink` or `fastLink.EM` object, or a list of `fastLink` or `fastLink.EM` objects
#' to be aggregated together produced  by `aggregateEM`. 
#' @param thresholds A vector of posterior probabilities to calculate the summary statistics.
#' @param weighted Whether to weight the cross-geography matches on FDR and FNR.
#' @param digits How many digits to include in summary object. Default is 3.
#' @param ... Further arguments to be passed to \code{summary.fastLink()}.
#'
#' @S3method summary fastLink
summary.fastLink <- function(object, thresholds = c(.95, .85, .75), weighted = TRUE, digits = 3, ...){
    
    round.pct <- function(x){
      a <- unlist(x)
      b <- round(a, digits)
      c <- paste0(b, "%")
      return(c)
    }

    if("fastLink.agg" %in% class(object) & !("across.geo" %in% names(object))){
        ## Extract and calculate counts
        out <- as.data.frame(do.call(rbind, lapply(object, function(x){summarize.em(x, thresholds = thresholds)})))
        out <- data.frame(t(colSums(out)))
        out.agg <- summarize.agg(out, weighted = weighted)
    }else if("fastLink.agg" %in% class(object) & "across.geo" %in% names(object)){
        ## Extract and calculate counts
        out.w <- as.data.frame(do.call(rbind, lapply(object[["within.geo"]], function(x){summarize.em(x, thresholds = thresholds)})))
        out.a <- as.data.frame(do.call(rbind, lapply(object[["across.geo"]], function(x){summarize.em(x, thresholds = thresholds)})))
        out <- list(within = data.frame(t(colSums(out.w))), across = data.frame(t(colSums(out.a))))
        out.agg <- summarize.agg(out, weighted = weighted)
    }else if("fastLink" %in% class(object) | "fastLink.EM" %in% class(object)){
        out <- summarize.em(object, thresholds = thresholds)
        out.agg <- summarize.agg(out, weighted = weighted)
    } 

    if("fastLink.agg" %in% class(object) & "across.geo" %in% names(object)){
        tab <- as.data.frame(
          rbind(round.pct(out.agg$pooled$matches), round.pct(out.agg$within$matches),
                round.pct(out.agg$across$matches),
                c(round.pct(out.agg$pooled$fdr), ""), c(round.pct(out.agg$within$fdr), ""),
                c(round.pct(out.agg$across$fdr), ""),
                c(round.pct(out.agg$pooled$fnr), ""), c(round.pct(out.agg$within$fnr), ""),
                c(round.pct(out.agg$across$fnr), ""))
        )
        tab <- cbind(rep(c("All", "Within-State", "Across-State"), 3), tab)
        tab <- cbind(c("Match Rate", "", "", "FDR", "", "", "FNR", "", ""), tab)
        colnames(tab) <- c("", "", paste0(thresholds * 100, "%"),  "Exact")
    }else{
      tab <- as.data.frame(
        rbind(round.pct(out.agg$matches), c(round.pct(out.agg$fdr), ""), c(round.pct(out.agg$fnr), ""))
      )
      tab <- cbind(c("Match Rate", "FDR", "FNR"), tab)
      colnames(tab) <- c("", paste0(thresholds * 100, "%"), "Exact")
    }
    #class(tab) <- "summary.fastLink"
    
    return(tab)
}

#' Aggregate EM objects for use in `summary.fastLink()`
#'
#' \code{aggregateEM} aggregates EM objects for easy processing by `summary.fastLink()`
#'
#' @usage aggregateEM(em.list, within.geo)
#' @param em.list A list of `fastLink` or `fastLink.EM` objects that should be aggregate
#' in `summary.fastLink()`
#' @param within.geo A vector of booleans corresponding to whether each object in `em.list`
#' is a within-geography match or an across-geography match. Should be of equal length to
#' `em.list`. Default is NULL (assumes all are within-geography matches).
#' 
#' @export
aggregateEM <- function(em.list, within.geo = NULL){

    if(is.null(within.geo)){
        out <- em.list
    }else{
        if(length(within.geo) != length(em.list)){
            stop("If provided, within.geo should be the same length as em.list.")
        }

        wg <- vector(mode = "list", length = sum(within.geo))
        ag <- vector(mode = "list", length = length(within.geo) - sum(within.geo))
        ind.within <- which(within.geo == TRUE)
        ind.across <- which(within.geo == FALSE)
        for(i in 1:length(ind.within)){
            wg[[i]] <- em.list[[ind.within[i]]]
        }
        for(i in 1:length(ind.across)){
            ag[[i]] <- em.list[[ind.across[i]]]
        }
        
        out <- list(within.geo = wg, across.geo = ag)
        
    }
    class(out) <- c("fastLink", "fastLink.agg")
    
    return(out)

}


