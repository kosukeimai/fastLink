## summarize.em <- function(x, thresholds = c(.95, .85, .75)){

##     n1 <- x$nr1; n2 <- x$nr2
    
##     count <- max(n1, n2)
    
##     ## Containers for thresholds
##     mc <- rep(NA, length(thresholds))
##     fp <- rep(NA, length(thresholds))
##     fn <- rep(NA, length(thresholds))
##     for(i in 1:length(thresholds)){
##         mc[i] <- min(sum(x$EM$counts[x$EM$zeta.j >= thresholds[i]]), min(n1, n2))
##         fp[i] <- sum(x$EM$counts[x$EM$zeta.j >= thresholds[i]] * 
##                      (1 - x$EM$zeta.j[x$EM$zeta.j >= thresholds[i]]))
##         fn[i] <- sum(x$EM$counts[x$EM$zeta.j < thresholds[i]] * (x$EM$zeta.j[x$EM$zeta.j < thresholds[i]]))
##     }

##     ## Expected match rate
##     exp.match <- sum(x$EM$counts * x$EM$zeta.j)

##     ## Expected number of exact matches
##     gamma.ind <- grep("gamma.[[:digit:]]", names(x$EM))
##     exact.match.ind <- which(rowSums(x$EM[,gamma.ind]) == length(gamma.ind)*2)
##     if(length(exact.match.ind) == 0){
##         exact.matches <- 0
##     }else{
##         exact.matches <- x$EM$counts[exact.match.ind]
##     }
    
##     out <- data.frame(t(c(count, mc, fp, fn, exp.match, exact.matches)))
##     names(out) <- c("count", paste0("mc.", thresholds*100), paste0("fp.", thresholds*100),  
##                     paste0("fn.", thresholds*100),  "exp.match", "exact.matches")

##     return(out)
    
## }

## summarize.agg <- function(x, weighted = TRUE){
    
##     s.calc <- function(y){
##         ## Match rate
##         matches <- 100 * (y[,grep("mc.", names(y))]) * (1/y$count)
##         ## Exact match rate
##         matches.E <- 100 * (y$exact.matches) * (1/y$count) 
##         matches <- cbind(matches, matches.E)
##         colnames(matches) <- c(names(y)[grep("mc.", names(y))], "matches.E")
##         ## FDR
##         fdr <- 100 * (y[,grep("fp.", names(y))]) * 1 / (y[,grep("mc.", names(y))])
##         names(fdr) <- names(y)[grep("fp.", names(y))]
##         ## FNR
##         tp <- y[, grep("mc.", names(y))] - y[, grep("fp.", names(y))]
##         fn <- y[, grep("fn.", names(y))]
##         fnr <- 100 * fn/(tp + fn)
##         names(fnr) <- names(y)[grep("fn.", names(y))]
##         return(list(fdr = fdr, fnr = fnr, matches = matches))
##     }
    
##     if(class(x) == "data.frame"){
##         out <- s.calc(x)
##     }else{
##         out <- list()
##         out[["within"]] <- s.calc(x[["within"]])
##         out[["across"]] <- s.calc(x[["across"]])
##         ## -------
##         ## Pooling
##         ## -------
##         ## Matches
##         matches <- 100 * (x$within[,grep("mc.", names(x$within))] + x$across[,grep("mc.", names(x$across))]) /
##             x$within$count
##         matches.E <- 100 * (x$within$exact.matches + x$across$exact.matches) / x$within$count
##         matches <- cbind(matches, matches.E)
##         colnames(matches) <- c(names(x$within)[grep("mc.", names(x$within))], "matches.E")
##         ## FDR
##         fdr <- 100 * (x$within[,grep("fp.", names(x$across))] + x$across[,grep("fp.", names(x$across))]) /
##             (x$within[,grep("mc.", names(x$within))] + x$across[,grep("mc.", names(x$across))])
##         names(fdr) <- names(x$within)[grep("fp.", names(x$within))]
##         ## FNR
##         tp <- x$within[, grep("mc.", names(x$within))] + x$across[,grep("mc.", names(x$across))] - 
##             x$within[, grep("fp.", names(x$within))] - x$across[,grep("fp.", names(x$across))]
##         fn <- x$within[, grep("fn.", names(x$within))] + x$across[,grep("fn.", names(x$across))]
##         fnr <- 100 * fn/(tp + fn)
##         names(fnr) <- names(x$within)[grep("fn.", names(x$within))]
##         ## Return object
##         out[["pooled"]] <- list(fdr = fdr, fnr = fnr, matches = matches)
##         ## ------
##         ## Weight 
##         ## ------
##         if(weighted){
##             ## Across-unit matches
##             out$across$matches <- out$pooled$matches - out$within$matches
##             ## Across and within-unit FDR
##             fdr.a <- 100 * (x$across[, grep("fp.", names(x$across))]) / 
##                 (x$across[,grep("mc.", names(x$across))] + x$within[, grep("mc.", names(x$within))])
##             names(fdr.a) <- names(x$across)[grep("fd.", names(x$across))]
##             out$across$fdr <- fdr.a
##             fdr.w <- 100 * (x$within[, grep("fp.", names(x$within))]) / 
##                 (x$across[,grep("mc.", names(x$across))] + x$within[, grep("mc.", names(x$within))])
##             names(fdr.w) <- names(x$within)[grep("fd.", names(x$within))]
##             out$within$fdr <- fdr.w
##             ## Across and within-unit FNR
##             w.a <- x$across[,grep("mc.", names(x$across))] - x$across[,grep("fp.", names(x$across))] + 
##                 x$across[,grep("fn.", names(x$across))]
##             w.w <- x$within[,grep("mc.", names(x$within))] - x$within[,grep("fp.", names(x$within))] + 
##                 x$within[,grep("fn.", names(x$within))]
##             fnr.a <- w.a * (1/(tp + fn)) * (fnr)
##             names(fnr.a) <- names(x$across)[grep("fn.", names(x$across))]
##             out$across$fnr <- fnr.a
##             fnr.w <- w.w * (1/(tp + fn)) * (fnr)
##             names(fnr.w) <- names(x$within)[grep("fn.", names(x$within))]
##             out$within$fnr <- fnr.w
##         }
##     }

##     return(out)

## }

## summary.fastLink <- function(){

## }
