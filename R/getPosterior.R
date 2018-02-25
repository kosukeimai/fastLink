#' getPosterior
#'
#' Get the posterior probability of a match for each matched pair of observations
#'
#' @usage getPosterior(matchesA, matchesB, EM, patterns)
#' @param matchesA A dataframe of the matched observations in
#' dataset A, with all variables used to inform the match.
#' @param matchesB A dataframe of the matched observations in
#' dataset B, with all variables used to inform the match.
#' @param EM The EM object from \code{emlinkMARmov()}
#' @param patterns The output from \code{getPatterns()}.
#'
#' @return \code{getPosterior} returns the posterior probability of a match for each matched pair of observations
#' in matchesA and matchesB
#' @author Ben Fifield <benfifield@gmail.com>
#' @export
getPosterior <- function(matchesA, matchesB, EM, patterns){

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

    ## Get original column names
    colnames.df.a <- colnames(matchesA)
    colnames.df.b <- colnames(matchesB)

    ## Gammalist
    gammalist <- patterns

    ## -------------------------------
    ## Convert EM object to data frame
    ## -------------------------------
    emdf <- as.data.frame(EM$patterns.w)
    emdf$zeta.j <- c(EM$zeta.j)

    ## ---------------------
    ## Merge EM to gammalist
    ## ---------------------
    namevec <- names(patterns)
    matchesA <- cbind(matchesA, gammalist)
    matchesA$roworder <- 1:nrow(matchesA)
    matchesA <- merge(matchesA, emdf, by = namevec, all.x = TRUE)
    matchesA <- matchesA[order(matchesA$roworder),]

    ## -------------
    ## Get max zetas
    ## -------------
    return(matchesA$zeta.j)
    
}

