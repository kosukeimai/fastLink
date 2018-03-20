#' getPatterns
#'
#' Get the full matching patterns for all matched pairs in dataset A and dataset B
#'
#' @param matchesA A dataframe of the matched observations in
#' dataset A, with all variables used to inform the match.
#' @param matchesB A dataframe of the matched observations in
#' dataset B, with all variables used to inform the match.
#' @param varnames A vector of variable names to use for matching.
#' Must be present in both matchesA and matchesB.
#' @param stringdist.match A vector of booleans, indicating whether to use
#' string distance matching when determining matching patterns on
#' each variable. Must be same length as varnames.
#' @param numeric.match A vector of booleans, indicating whether to use
#' numeric pairwise distance matching when determining matching patterns on
#' each variable. Must be same length as varnames.
#' @param partial.match A vector of booleans, indicating whether to include
#' a partial matching category for the string distances. Must be same length
#' as varnames. Default is FALSE for all variables.
#' @param stringdist.method String distance method for calculating similarity, options are: "jw" Jaro-Winkler (Default), "jaro" Jaro, and "lv" Edit
#' @param cut.a Lower bound for full string-distance match, ranging between 0 and 1. Default is 0.92
#' @param cut.p Lower bound for partial string-distance match, ranging between 0 and 1. Default is 0.88
#' @param jw.weight Parameter that describes the importance of the first characters of a string (only needed if stringdist.method = "jw"). Default is .10
#' @param cut.a.num Lower bound for full numeric match. Default is 1
#' @param cut.p.num Lower bound for partial numeric match. Default is 2.5
#'
#' @return \code{getPatterns()} returns a dataframe with a row for each matched pair,
#' where each column indicates the matching pattern for each matching variable.
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com> and Ben Fifield <benfifield@gmail.com>
#' @export
getPatterns <- function(matchesA, matchesB, varnames,
                        stringdist.match, numeric.match,
                        partial.match, stringdist.method = "jw",
                        cut.a = 0.92, cut.p = 0.88, jw.weight = .10,
                        cut.a.num = 1, cut.p.num = 2.5){

    ## --------------
    ## Start function
    ## --------------
    ## Convert to dataframe
    if(any(class(matchesA) %in% c("tbl_df", "data.table"))){
        matchesA <- as.data.frame(matchesA)
    }
    if(any(class(matchesB) %in% c("tbl_df", "data.table"))){
        matchesB <- as.data.frame(matchesB)
    }
    if(!(stringdist.method %in% c("jw", "jaro", "lv"))){
        stop("Invalid string distance method. Method should be one of 'jw', 'jaro', or 'lv'.")
    }
    if(stringdist.method == "jw" & !is.null(jw.weight)){
        if(jw.weight < 0 | jw.weight > 0.25){
            stop("Invalid value provided for jw.weight. Remember, jw.weight in [0, 0.25].")
        }
    }
    if(any(stringdist.match * numeric.match) == 1){
        stop("There is a variable present in both 'numeric.match' and 'stringdist.match'. Please select only one matching metric for each variable.")
    }

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
        }else if(numeric.match[i]){
            tmp <- abs(matchesA[,varnames[i]] - matchesB[,varnames[i]])
            if(partial.match[i]){
                gammalist[[i]] <- ifelse(
                    tmp <= cut.a.num, 2, ifelse(tmp <= cut.p.num, 1, 0)
                )
            }else{
                gammalist[[i]] <- ifelse(tmp <= cut.a.num, 2, 0)
            }
        }else{
            tmp <- matchesA[,varnames[i]] == matchesB[,varnames[i]]
            gammalist[[i]] <- ifelse(tmp == TRUE, 2, 0)
        }

        namevec[i] <- paste0("gamma.", i)
        
    }
    gammalist <- data.frame(do.call(cbind, gammalist))
    names(gammalist) <- namevec

    return(gammalist)

}

