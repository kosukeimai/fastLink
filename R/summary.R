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
    tmc <- rep(NA, length(thresholds))
    tpc <- rep(NA, length(thresholds))
    fpc <- rep(NA, length(thresholds))
    fnc <- rep(NA, length(thresholds))
    for(i in 1:length(thresholds)){
        tmc[i] <- sum(EM$counts[EM$zeta.j >= thresholds[i]] * EM$zeta.j[EM$zeta.j >= thresholds[i]])
        tpc[i] <- min(sum(EM$counts[EM$zeta.j >= thresholds[i]]), min(n1, n2))
        fpc[i] <- sum(EM$counts[EM$zeta.j >= thresholds[i]] * (1 - EM$zeta.j[EM$zeta.j >= thresholds[i]]))
        fnc[i] <- sum(EM$counts[EM$zeta.j < thresholds[i]] * (EM$zeta.j[EM$zeta.j < thresholds[i]]))
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
    
    out <- data.frame(t(c(count, tmc, tpc, fpc, fnc, exp.match, exact.matches, n1, n2)))
    names(out) <- c("count", paste0("tmc.", thresholds*100), paste0("tpc.", thresholds*100), paste0("fpc.", thresholds*100),  
                    paste0("fnc.", thresholds*100),  "exp.match", "exact.matches", "nobs.a", "nobs.b")

    return(out)
    
}

summarize.agg <- function(x, num.comparisons, weighted){
    
    s.calc <- function(y){
        ## Match rate
        matches <- 100 * (y[,grep("tmc.", names(y))]) / min(y$nobs.a, y$nobs.b)
        ## Exact match rate
        matches.E <- 100 * (y$exact.matches) / min(y$nobs.a, y$nobs.b)
        matches <- cbind(matches, matches.E)
        colnames(matches) <- c(names(y)[grep("tmc.", names(y))], "matches.E")
        ## Match count
        matchcount <- y[,grep("tpc.", names(y))]
        matchcount.E <- y$exact.matches
        matchcount <- cbind(matchcount, matchcount.E)
        colnames(matchcount) <- c(names(y)[grep("tpc.", names(y))], "matchcount.E")
        ## FDR
        fdr <- 100 * (y[,grep("fpc.", names(y))]) * 1 / (y[,grep("tpc.", names(y))])
        names(fdr) <- names(y)[grep("fpc.", names(y))]
        ## FNR
        fnr <- 100 * (y[,grep("fnc.", names(y))]) * (1 / y$exp.match)
        names(fnr) <- names(y)[grep("fnc.", names(y))]
        return(list(fdr = fdr, fnr = fnr, matches = matches, matchcount = matchcount))
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
        matches <- 100 * (x$within[,grep("tmc.", names(x$within))] + x$across[,grep("tmc.", names(x$across))]) /
            min(x$within$nobs.a, x$within$nobs.b)
        matches.E <- 100 * (x$within$exact.matches + x$across$exact.matches) / min(x$within$nobs.a, x$within$nobs.b)
        matches <- cbind(matches, matches.E)
        colnames(matches) <- c(names(x$within)[grep("tmc.", names(x$within))], "matches.E")
        ## Match count
        matchcount <- out$within$matchcount + out$across$matchcount
        ## FDR
        fdr <- 100 * (x$within[,grep("fpc.", names(x$across))] + x$across[,grep("fpc.", names(x$across))]) /
            (x$within[,grep("tpc.", names(x$within))] + x$across[,grep("tpc.", names(x$across))])
        names(fdr) <- names(x$within)[grep("fpc.", names(x$within))]
        ## FNR
        fnr <- 100 * (x$within[,grep("fnc.", names(x$across))] + (x$across[,grep("fnc.", names(x$across))] / num.comparisons)) /
            min(x$within$nobs.a, x$within$nobs.b)
        names(fnr) <- names(x$within)[grep("fnc.", names(x$within))]
        ## Return object
        out[["pooled"]] <- list(fdr = fdr, fnr = fnr, matches = matches, matchcount = matchcount)
        ## ------
        ## Weight 
        ## ------
        if(weighted){
            ## Across-unit matches
            wm <- 100 * (x$within[,grep("tmc.", names(x$within))]) /
                min(x$within$nobs.a, x$within$nobs.b)
            wm.E <- 100 * (x$within$exact.matches) / min(x$within$nobs.a, x$within$nobs.b)
            out$within$matches <- cbind(wm, wm.E)
            wm <- 100 * (x$across[,grep("tmc.", names(x$across))]) /
                min(x$within$nobs.a, x$within$nobs.b)
            wm.E <- 100 * (x$across$exact.matches) / min(x$within$nobs.a, x$within$nobs.b)
            out$across$matches <- cbind(wm, wm.E)
            ## Across and within-unit FDR
            fdr.a <- 100 * (x$across[, grep("fpc.", names(x$across))]) / 
                (x$across[,grep("tmc.", names(x$across))] + x$within[, grep("tmc.", names(x$within))])
            names(fdr.a) <- names(x$across)[grep("fd.", names(x$across))]
            out$across$fdr <- fdr.a
            fdr.w <- 100 * (x$within[, grep("fpc.", names(x$within))]) / 
                (x$across[,grep("tpc.", names(x$across))] + x$within[, grep("tpc.", names(x$within))])
            names(fdr.w) <- names(x$within)[grep("fd.", names(x$within))]
            out$within$fdr <- fdr.w
            ## Across and within-unit FNR
            fnr.a <- 100 * (x$across[,grep("fnc.", names(x$across))] / num.comparisons) /
                min(x$within$nobs.a, x$within$nobs.b)
            names(fnr.a) <- names(x$across)[grep("fnc.", names(x$across))]
            out$across$fnr <- fnr.a
            fnr.w <- 100 * (x$within[,grep("fnc.", names(x$across))]) /
                min(x$within$nobs.a, x$within$nobs.b)
            names(fnr.w) <- names(x$within)[grep("fnc.", names(x$within))]
            out$within$fnr <- fnr.w
        }
    }

    return(out)

}

#' Get summaries of fastLink() objects
#'
#' \code{summary.fastLink()} calculates and outputs FDR, FNR, match counts, and match rates for
#' estimated matches from a fastLink() object.
#'
#' @usage \method{summary}{fastLink}(object, num.comparisons = 1,
#' thresholds = c(.95, .85, .75), weighted = TRUE, digits = 3, ...)
#' @param object Either a single `fastLink` or `fastLink.EM` object, or a list of `fastLink` or `fastLink.EM` objects
#' to be aggregated together produced  by `aggregateEM`.
#' @param num.comparisons The number of comparisons attempted for each observation in the across-geography match step.
#' A correction factor to avoid multiple-counting. Default is NULL
#' @param thresholds A vector of posterior probabilities to calculate the summary statistics.
#' @param weighted Whether to weight the cross-geography matches on FDR and FNR.
#' @param digits How many digits to include in summary object. Default is 3.
#' @param ... Further arguments to be passed to \code{summary.fastLink()}.
#'
#' @export
#' @method summary fastLink
summary.fastLink <- function(object, num.comparisons = 1, thresholds = c(.95, .85, .75), weighted = TRUE, digits = 3, ...){
    
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
        out.agg <- summarize.agg(out, num.comparisons = num.comparisons, weighted = weighted)
    }else if("fastLink.agg" %in% class(object) & "across.geo" %in% names(object)){
        ## Extract and calculate counts
        out.w <- as.data.frame(do.call(rbind, lapply(object[["within.geo"]], function(x){summarize.em(x, thresholds = thresholds)})))
        out.a <- as.data.frame(do.call(rbind, lapply(object[["across.geo"]], function(x){summarize.em(x, thresholds = thresholds)})))
        out <- list(within = data.frame(t(colSums(out.w))), across = data.frame(t(colSums(out.a))))
        out.agg <- summarize.agg(out, num.comparisons = num.comparisons, weighted = weighted)
    }else if("fastLink" %in% class(object) | "fastLink.EM" %in% class(object)){
        out <- summarize.em(object, thresholds = thresholds)
        out.agg <- summarize.agg(out, num.comparisons = num.comparisons, weighted = weighted)
    } 

    if("fastLink.agg" %in% class(object) & "across.geo" %in% names(object)){
        tab <- as.data.frame(
            rbind(c(out.agg$pooled$matchcount), c(out.agg$within$matchcount),
                  c(out.agg$across$matchcount),
                  round.pct(out.agg$pooled$matches), round.pct(out.agg$within$matches),
                  round.pct(out.agg$across$matches),
                  c(round.pct(out.agg$pooled$fdr), ""), c(round.pct(out.agg$within$fdr), ""),
                  c(round.pct(out.agg$across$fdr), ""),
                  c(round.pct(out.agg$pooled$fnr), ""), c(round.pct(out.agg$within$fnr), ""),
                  c(round.pct(out.agg$across$fnr), ""))
        )
        tab <- cbind(rep(c("All", "Within-State", "Across-State"), 4), tab)
        tab <- cbind(c("Match Count", "", "", "Match Rate", "", "", "FDR", "", "", "FNR", "", ""), tab)
        colnames(tab) <- c("", "", paste0(thresholds * 100, "%"),  "Exact")
    }else{
      tab <- as.data.frame(
        rbind(out.agg$matchcount, round.pct(out.agg$matches), c(round.pct(out.agg$fdr), ""), c(round.pct(out.agg$fnr), ""))
      )
      tab <- cbind(c("Match Count", "Match Rate", "FDR", "FNR"), tab)
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


