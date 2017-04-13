summarize.em <- function(x, thresholds){

    n1 <- x$nobs.a; n2 <- x$nobs.b
    
    count <- min(n1, n2)
    
    ## Containers for thresholds
    mc <- rep(NA, length(thresholds))
    fp <- rep(NA, length(thresholds))
    fn <- rep(NA, length(thresholds))
    for(i in 1:length(thresholds)){
        mc[i] <- min(sum(x$EM$counts[x$EM$zeta.j >= thresholds[i]]), min(n1, n2))
        fp[i] <- sum(x$EM$counts[x$EM$zeta.j >= thresholds[i]] * 
                     (1 - x$EM$zeta.j[x$EM$zeta.j >= thresholds[i]]))
        fn[i] <- sum(x$EM$counts[x$EM$zeta.j < thresholds[i]] * (x$EM$zeta.j[x$EM$zeta.j < thresholds[i]]))
    }

    ## Expected match rate
    exp.match <- sum(x$EM$counts * x$EM$zeta.j)

    ## Expected number of exact matches
    gamma.ind <- grep("gamma.[[:digit:]]", names(x$EM))
    exact.match.ind <- which(rowSums(x$EM[,gamma.ind]) == length(gamma.ind)*2)
    if(length(exact.match.ind) == 0){
        exact.matches <- 0
    }else{
        exact.matches <- x$EM$counts[exact.match.ind]
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
#' @param object Either a single fastLink object, or a list of lists - where the first list is a
#' list of all fastLink objects from within-geography matches, and the second list is a list of all
#' fastLink objects from cross-geography matches.
#' @param thresholds A vector of posterior probabilities to calculate the summary statistics.
#' @param weighted Whether to weight the cross-geography matches on FDR and FNR.
#' @param digits How many digits to include in summary object. Default is 3.
#'
#' @export
summary.fastLink <- function(object, thresholds = c(.95, .85, .75), weighted = TRUE, digits = 3, ...){
    
    round.pct <- function(x){
      a <- unlist(x)
      b <- round(a, digits)
      c <- paste0(b, "%")
      return(c)
    }
    
    if(class(object) == "fastLink"){
        out <- summarize.em(object, thresholds = thresholds)
        out.agg <- summarize.agg(out, weighted = weighted)
    }else if(class(object) == "list"){
        ## Extract and calculate counts
        within <- object[["within"]]
        w.out <- as.data.frame(do.call(rbind, lapply(within, function(x){summarize.em(x, thresholds = thresholds)})))
        if("across" %in% names(object)){
            across <- object[["across"]]
            a.out <- as.data.frame(do.call(rbind, lapply(across, function(x){summarize.em(x, thresholds = thresholds)})))
            ## Combine
            out <- list(within = data.frame(t(colSums(w.out))), across = data.frame(t(colSums(a.out))))
        }else{
            out <- data.frame(t(colSums(w.out)))
        }
        out.agg <- summarize.agg(out, weighted = weighted)
    }

    if(class(object) == "list" & "across" %in% names(object)){
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
    
    return(tab)
}

#' Aggregate EM objects for a single summary
#'
#' \code{aggregateEM} aggregates EM objects to create a single statewide summary.
#'
#' @usage aggregateEM(object)
#' @param object A list of lists, where each sub-list contains three entries:
#' EM (the EM object), nobs_a (the number of observations in dataset A) and
#' nobs_b (the number of observations in dataset B)
#' 
#' @export
aggregateEM <- function(object){

    ## Set up containers
    gamma.ind <- grep("gamma.[[:digit:]]", names(object[[1]]$EM))
    em.agg <- object[[1]]$EM[,gamma.ind]
    em.agg$counts <- object[[1]]$EM$counts
    em.agg$weights <- object[[1]]$EM$weights
    em.agg$zeta.j <- object[[1]]$EM$zeta.j
    n <- rep(NA, length(object))
    n[1] <- min(object[[1]]$nobs_a, object[[1]]$nobs_b)

    ## Loop over remainders
    if(length(object) > 1){
      for(i in 2:length(object)){
          em.sub <- object[[i]]$EM[,gamma.ind]
          em.sub$counts <- object[[i]]$EM$counts
          em.sub$weights <- object[[i]]$EM$weights
          em.sub$zeta.j <- object[[i]]$EM$zeta.j
          em.agg <- merge(
              em.agg, em.sub, by = paste0("gamma.", gamma.ind), all = TRUE
          )
          n[i] <- min(object[[i]]$nobs_a, object[[i]]$nobs_b)
      }
    }

    ## Aggregate
    counts.agg <- rep(NA, nrow(em.agg))
    counts.inds <- grep("counts.", names(em.agg))
    weights.agg <- rep(NA, nrow(em.agg))
    weights.inds <- grep("weights.", names(em.agg))
    zeta.j.agg <- rep(NA, nrow(em.agg))
    zeta.inds <- grep("zeta.j", names(em.agg))
    for(i in 1:nrow(em.agg)){
        counts.agg[i] <- sum(em.agg[i, counts.inds], na.rm = TRUE)
        weights.agg[i] <- wtd.mean(em.agg[i, weights.inds], n, na.rm = TRUE)
        zeta.j.agg[i] <- wtd.mean(em.agg[i, zeta.inds], n, na.rm = TRUE)
    }
    em.agg.out <- em.agg[,gamma.ind]
    em.agg.out$counts <- counts.agg
    em.agg.out$weights <- weights.agg
    em.agg.out$zeta.j <- zeta.j.agg
    em.agg.out <- em.agg.out[order(em.agg.out$zeta.j),]
    return(em.agg.out)

}


