#' nameReweight
#'
#' Reweights posterior probabilities to account for observed frequency
#' of names. Downweights posterior probability of match if first name is common,
#' upweights if first name is uncommon.
#'
#' @usage nameReweight(dfA, dfB, EM, gammalist, matchesLink,
#' varnames, stringdist.match, partial.match,
#' firstname.field, threshold.match, stringdist.method, cut.a, cut.p,
#' jw.weight, n.cores)
#' @param dfA The full version of dataset A that is being matched.
#' @param dfB The full version of dataset B that is being matched.
#' @param EM The EM object from \code{emlinkMARmov()}
#' @param gammalist The list of gamma objects calculated on the full
#' dataset that indicate matching patterns, which is fed into \code{tableCounts()}
#' and \code{matchesLink()}.
#' @param matchesLink The output from \code{matchesLink()}.
#' @param varnames A vector of variable names to use for matching.
#' Must be present in both matchesA and matchesB.
#' @param stringdist.match A vector of booleans, indicating whether to use
#' string distance matching when determining matching patterns on
#' each variable. Must be same length as varnames.
#' @param partial.match A vector of booleans, indicating whether to include
#' a partial matching category for the string distances. Must be same length
#' as varnames. Default is FALSE for all variables.
#' @param firstname.field The name of the field indicating first name.
#' @param threshold.match A number between 0 and 1 indicating either the lower bound (if only one number provided) or the range of certainty that the
#' user wants to declare a match. For instance, threshold.match = .85 will return all pairs with posterior probability greater than .85 as matches,
#' while threshold.match = c(.85, .95) will return all pairs with posterior probability between .85 and .95 as matches.
#' @param stringdist.method String distance method for calculating similarity, options are: "jw" Jaro-Winkler (Default), "jaro" Jaro, and "lv" Edit
#' @param cut.a Lower bound for full string-distance match, ranging between 0 and 1. Default is 0.92
#' @param cut.p Lower bound for partial string-distance match, ranging between 0 and 1. Default is 0.88
#' @param jw.weight Parameter that describes the importance of the first characters of a string (only needed if stringdist.method = "jw"). Default is .10
#' @param n.cores Number of cores to parallelize over. Default is NULL.
#'
#' @return \code{nameReweight()} returns a list containing the following elements:
#' \item{zetaA}{The reweighted zeta estimates for each matched element in dataset A.}
#' \item{zetaB}{The reweighted zeta estimates for each matched element in dataset B.}
#' @author Ted Enamorado <ted.enamorado@gmail.com> and Ben Fifield <benfifield@gmail.com>
#' @export
nameReweight <- function(dfA, dfB, EM, gammalist, matchesLink,
                         varnames, stringdist.match, partial.match, 
                         firstname.field, threshold.match,
                         stringdist.method = "jw", cut.a = .92, cut.p = .88,
                         jw.weight = .10, n.cores = NULL){

    if(!(stringdist.method %in% c("jw", "jaro", "lv"))){
        stop("Invalid string distance method. Method should be one of 'jw', 'jaro', or 'lv'.")
    }
    if(stringdist.method == "jw" & !is.null(jw.weight)){
        if(jw.weight < 0 | jw.weight > 0.25){
            stop("Invalid value provided for jw.weight. Remember, jw.weight in [0, 0.25].")
        }
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
    EM.names <- as.matrix(EM[EM$zeta.j >= 1e-9 & EM[,firstname.field] == TRUE,])
    EM.names2 <- EM.names[, c(1:ncol(resultsEM$patterns.w))]
    resultsEM2 <- resultsEM
    resultsEM2$patterns.w <- EM.names2
    match.ut <- min(resultsEM2$patterns.w[, "weights"]) - 0.01

    ## We recover all the pairs that match on name:
    list.m <- matchesLink(gammalist, nobs.a = nrow(dfA), nobs.b = nrow(dfB), em = resultsEM2, thresh = threshold.match, n.cores = n.cores)

    ## Datasets with such matches
    matchesA <- dfA[ list.m[, 1], ]
    matchesB <- dfB[ list.m[, 2], ]
    matchesA.f <- dfA[matchesLink$inds.a,]
    matchesB.f <- dfB[matchesLink$inds.b,]

    fn.field <- varnames[firstname.field]

    ## ----------
    ## Get gammas
    ## ----------
    gammalist <- vector(mode = "list", length = length(varnames))
    namevec <- rep(NA, length(varnames))
    for(i in 1:length(gammalist)){
        ## Convert to character
        if(is.factor(matchesA[,varnames[i]]) | is.factor(matchesB[,varnames[i]])){
            matchesA[,varnames[i]] <- as.character(matchesA[,varnames[i]])
            matchesB[,varnames[i]] <- as.character(matchesB[,varnames[i]])
        }
        ## Get matches
        if(stringdist.match[i]){
            if(stringdist.method %in% c("jw", "jaro")){
                if(stringdist.method == "jw"){
                    p1 <- jw.weight
                }else{
                    p1 <- NULL
                }
                tmp <- 1 - stringdist(matchesA[,varnames[i]], matchesB[,varnames[i]], "jw", p = p1)
            }else{
                t <- stringdist(matchesA[,varnames[i]], matchesB[,varnames[i]], method = stringdist.method)
                t.1 <- nchar(matchesA[,varnames[i]])
                t.2 <- nchar(matchesB[,varnames[i]])
                o <- ifelse(t.1 > t.2, t.1, t.2)
                tmp <- 1 - t * (1/o)
            }
            if(partial.match[i]){
                gammalist[[i]] <- ifelse(
                    tmp >= cut.a, 2, ifelse(tmp >= cut.p, 1, 0)
                )
            }else{
                gammalist[[i]] <- ifelse(tmp >= cut.a, 2, 0)
            }
        }else{
            tmp <- matchesA[,varnames[i]] == matchesB[,varnames[i]]
            gammalist[[i]] <- ifelse(tmp == TRUE, 2, 0)
        }

        namevec[i] <- paste0("gamma.", i)
        
    }
    gammalist <- data.frame(do.call(cbind, gammalist))
    matchesA <- cbind(matchesA, gammalist)
    matchesA <- merge(matchesA, EM.names, by = namevec, all.x = T)	

    ## ---------------------
    ## Start name adjustment
    ## ---------------------
    ## Factors to adjust names:
    fn.1 <- tapply(matchesA$zeta.j, matchesA$first.name, sum)
    fn.2 <- tapply(1 - matchesA$zeta.j, matchesA$first.name, sum)

    factor <- data.frame(cbind(fn.1, fn.2))
    factor$first.name <- rownames(factor)

    matchesA.f$id.o <- 1:nrow(matchesA.f)
    matchesB.f$id.o <- 1:nrow(matchesB.f)
    matches.names.A <- merge(matchesA.f, factor, by = fn.field, all.x = T)
    matches.names.B <- merge(matchesB.f, factor, by = fn.field, all.x = T)
    matches.names.A <- matches.names.A[order(matches.names.A$id.o), ]
    matches.names.B <- matches.names.B[order(matches.names.B$id.o), ]

    matches.names.A$zeta.j.names <- (matches.names.A$fn.1 * matches.names.A$p.gamma.j.m) /
        (matches.names.A$fn.1 * matches.names.A$p.gamma.j.m + matches.names.A$fn.2 * matches.names.A$p.gamma.j.u)
    matches.names.B$zeta.j.names <- (matches.names.B$fn.1 * matches.names.B$p.gamma.j.m) /
        (matches.names.B$fn.1 * matches.names.B$p.gamma.j.m + matches.names.B$fn.2 * matches.names.B$p.gamma.j.u)

    matches.names.A$zeta.j.names[matches.names.A[,firstname.field] != 2] <- NA
    matches.names.B$zeta.j.names[matches.names.B[,firstname.field] != 2] <- NA

    ## ----------------------------------
    ## Output reweighted matched data set
    ## ----------------------------------
    return(matches.names.A$zeta.j.names)

}

