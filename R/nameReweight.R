#' nameReweight
#'
#' Reweights posterior probabilities to account for observed frequency
#' of names. Downweights posterior probability of match if first name is common,
#' upweights if first name is uncommon.
#'
#' @usage nameReweight(dfA, dfB, EM, gammalist, matchesLink,
#' varnames, firstname.field, patterns, threshold.match, n.cores)
#' @param dfA The full version of dataset A that is being matched.
#' @param dfB The full version of dataset B that is being matched.
#' @param EM The EM object from \code{emlinkMARmov()}
#' @param gammalist The list of gamma objects calculated on the full
#' dataset that indicate matching patterns, which is fed into \code{tableCounts()}
#' and \code{matchesLink()}.
#' @param matchesLink The output from \code{matchesLink()}.
#' @param varnames A vector of variable names to use for matching.
#' Must be present in both matchesA and matchesB.
#' @param firstname.field A vector of booleans, indicating whether each field indicates
#' first name. TRUE if so, otherwise FALSE.
#' @param patterns The output from \code{getPatterns()}.
#' @param threshold.match A number between 0 and 1 indicating either the lower bound (if only one number provided) or the range of certainty that the
#' user wants to declare a match. For instance, threshold.match = .85 will return all pairs with posterior probability greater than .85 as matches,
#' while threshold.match = c(.85, .95) will return all pairs with posterior probability between .85 and .95 as matches.
#' @param n.cores Number of cores to parallelize over. Default is NULL.
#'
#' @return \code{nameReweight()} returns a list containing the following elements:
#' \item{zetaA}{The reweighted zeta estimates for each matched element in dataset A.}
#' \item{zetaB}{The reweighted zeta estimates for each matched element in dataset B.}
#' @author Ted Enamorado <ted.enamorado@gmail.com> and Ben Fifield <benfifield@gmail.com>
#' @export
nameReweight <- function(dfA, dfB, EM, gammalist, matchesLink,
                         varnames, firstname.field, patterns,
                         threshold.match, n.cores = NULL){

    if(sum(firstname.field) == 0){
        stop("You have not indicated which field represents first name.")
    }
    
    ## Get cores
    if(is.null(n.cores)) {
        n.cores <- detectCores() - 1
    }
    
    ## Clean up EM object
    resultsEM <- EM
    EM <- data.frame(cbind(resultsEM$patterns.w))
    EM$zeta.j <- resultsEM$zeta.j			
    EM <- EM[order(EM[, "weights"]), ] 
    EM$cumsum.m <- cumsum(EM[, "p.gamma.j.m"])
    EM$cumsum.u <- 1 - cumsum(EM[, "p.gamma.j.u"])

    ## Subset down to perfect matches on first name
    firstname.field <- which(firstname.field == TRUE)
    EM.names <- as.matrix(EM[EM$zeta.j >= 1e-9 & EM[,firstname.field] == 2,])
    EM.names2 <- EM.names[, c(1:ncol(resultsEM$patterns.w))]
    resultsEM2 <- resultsEM
    resultsEM2$patterns.w <- EM.names2
    resultsEM2$zeta.j <- as.matrix(EM$zeta.j[EM$zeta.j > 1e-9 & EM[,firstname.field] == 2,])
    match.ut <- min(resultsEM2$patterns.w[, "weights"]) - 0.01

    ## We recover all the pairs that match on name:
    list.m <- matchesLink(gammalist, nobs.a = nrow(dfA), nobs.b = nrow(dfB), em = resultsEM2, thresh = threshold.match, n.cores = n.cores)

    ## Datasets with such matches
    dfA$ind.orig <- 1:nrow(dfA)
    dfB$ind.orig <- 1:nrow(dfB)
    matchesA.f <- dfA[ matchesLink$inds.a, ]
    matchesB.f <- dfB[ matchesLink$inds.b, ]

    fn.field <- varnames[firstname.field]

    ## Gammalist
    gammalist <- patterns

    ## Merge gammalist
    namevec <- names(patterns)
    matchesA.f <- cbind(matchesA.f, gammalist)
    matchesA.f <- merge(matchesA.f, EM, by = namevec, all.x = T)
    matchesB.f <- cbind(matchesB.f, gammalist)
    matchesB.f <- merge(matchesB.f, EM, by = namevec, all.x = T)

    matchesA <- matchesA.f[ matchesA.f$ind.orig %in%
                            intersect(matchesLink$inds.a, list.m$inds.a), ]
    matchesB <- matchesB.f[ matchesB.f$ind.orig %in%
                            intersect(matchesLink$inds.b, list.m$inds.b), ]

    ## ---------------------
    ## Start name adjustment
    ## ---------------------
    ## Factors to adjust names:
    fn.1 <- tapply(matchesA$zeta.j, matchesA[,fn.field], sum)
    fn.2 <- tapply(1 - matchesA$zeta.j, matchesA[,fn.field], sum)

    fcto <- data.frame(cbind(fn.1, fn.2))
    fcto$first.name <- rownames(fcto)
    names(fcto)[3] <- fn.field

    matchesA.f$id.o <- 1:nrow(matchesA.f)
    matchesB.f$id.o <- 1:nrow(matchesB.f)
    matches.names.A <- merge(matchesA.f, fcto, by = fn.field, all.x = T)
    matches.names.B <- merge(matchesB.f, fcto, by = fn.field, all.x = T)
    matches.names.A <- matches.names.A[order(matches.names.A$id.o), ]
    matches.names.B <- matches.names.B[order(matches.names.B$id.o), ]

    matches.names.A$zeta.j.names <- (matches.names.A$fn.1 * matches.names.A$p.gamma.j.m) /
        (matches.names.A$fn.1 * matches.names.A$p.gamma.j.m + matches.names.A$fn.2 * matches.names.A$p.gamma.j.u)
    matches.names.B$zeta.j.names <- (matches.names.B$fn.1 * matches.names.B$p.gamma.j.m) /
        (matches.names.B$fn.1 * matches.names.B$p.gamma.j.m + matches.names.B$fn.2 * matches.names.B$p.gamma.j.u)

    ind <- paste0("gamma.", firstname.field)
    matches.names.A$zeta.j.names[matches.names.A[,ind] != 2] <- NA
    matches.names.B$zeta.j.names[matches.names.B[,ind] != 2] <- NA

    ## ----------------------------------
    ## Output reweighted matched data set
    ## ----------------------------------
    return(matches.names.A$zeta.j.names)

}

