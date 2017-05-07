## #' dedupeMatches
## #'
## #' Dedupe matched dataframes using the linear sum assignment problem
## #' methodology.
## #'
## #' @usage dedupeMatches(matchesA, matchesB, EM,
## #' matchesLink, varnames, stringdist.match, partial.match,
## #' cut.a = 0.92, cut.p = 0.88)
## #' @param matchesA A dataframe of the matched observations in
## #' dataset A, with all variables used to inform the match.
## #' @param matchesB A dataframe of the matched observations in
## #' dataset B, with all variables used to inform the match.
## #' @param EM The EM object from \code{emlinkMARmov()}
## #' @param matchesLink The output from \code{matchesLink()}
## #' @param varnames A vector of variable names to use for matching.
## #' Must be present in both matchesA and matchesB.
## #' @param stringdist.match A vector of booleans, indicating whether to use
## #' string distance matching when determining matching patterns on
## #' each variable. Must be same length as varnames.
## #' @param partial.match A vector of booleans, indicating whether to include
## #' a partial matching category for the string distances. Must be same length
## #' as varnames. Default is FALSE for all variables.
## #' @param cut.a Lower bound for full string-distance match, ranging between 0 and 1. Default is 0.92
## #' @param cut.p Lower bound for partial string-distance match, ranging between 0 and 1. Default is 0.88
## #'
## #' @return \code{dedupeMatches()} returns a list containing the following elements:
## #' \item{matchesA}{A deduped version of matchesA}
## #' \item{matchesB}{A deduped version of matchesB}
## #' \item{EM}{A deduped version of the EM object}
## #' 
## #' @author Ted Enamorado <ted.enamorado@gmail.com> and Ben Fifield <benfifield@gmail.com>
## #' @export
## #' @importFrom adagio assignment
## dedupeMatches <- function(matchesA, matchesB, EM, matchesLink,
##                           varnames, stringdist.match, partial.match,
##                           cut.a = 0.92, cut.p = 0.88){

##     ## Convert to dataframe
##     if(any(class(matchesA) %in% c("tbl_df", "data.table"))){
##         matchesA <- as.data.frame(matchesA)
##     }
##     if(any(class(matchesB) %in% c("tbl_df", "data.table"))){
##         matchesB <- as.data.frame(matchesB)
##     }

##     ## ----------
##     ## Get gammas
##     ## ----------
##     gammalist <- vector(mode = "list", length = length(varnames))
##     namevec <- rep(NA, length(varnames))
##     for(i in 1:length(gammalist)){

##         if(stringdist.match[i]){
##             tmp <- 1 - stringdist(matchesA[,varnames[i]], matchesB[,varnames[i]])
##             if(partial.match[i]){
##                 gammalist[[i]] <- ifelse(
##                     tmp >= cut.a, 2, ifelse(tmp >= cut.p, 1, 0)
##                 )
##             }else{
##                 gammalist[[i]] <- ifelse(tmp >= cut.a, 2, 0)
##             }
##         }else{
##             tmp <- matchesA[,varnames[i]] == matchesB[,varnames[i]]
##             gammalist[[i]] <- ifelse(tmp == TRUE, 2, 0)
##         }

##         namevec[i] <- paste0("gamma.", i)
        
##     }
##     gammalist <- data.frame(do.call(cbind, gammalist))
##     names(gammalist) <- namevec

##     ## ---------------------
##     ## Merge EM to gammalist
##     ## ---------------------
##     matchesA <- merge(matchesA, EM, by = namevec, all.x = TRUE)
##     matchesB <- merge(matchesB, EM, by = namevec, all.x = TRUE)

##     ## ------------
##     ## Start dedupe
##     ## ------------
##     ## Ids 
##     matchesA$idA <- matchesLink[,1]
##     matchesB$idB <- matchesLink[,2]
##     matchesB$idA <- matchesA$idA
##     matchesA$idB <- matchesB$idB

##     ## Find duplicates
##     dupA <- duplicated(matchesA$idA)
##     dupB <- duplicated(matchesA$idA, fromLast = T)
##     matchesA$dupA <- ifelse(dupA == 1 | dupB == 1, 1, 0)

##     dupA <- duplicated(matchesB$idB)
##     dupB <- duplicated(matchesB$idB, fromLast = T)
##     matchesA$dupB <- ifelse(dupA == 1 | dupB == 1, 1, 0)

##     ## Split into dupes, not dups
##     dups <- subset(dataA, dupA == 1 | dupB == 1)
##     nodups <- subset(dataA, dup1 == 0 & dupB == 0)

##     dups$idA.t <- as.numeric(as.factor(dups$idA))
##     dups$idB.t <- as.numeric(as.factor(dups$idB))

##     nr <- max(dups$idA.t)
##     nc <- max(dups$idB.t)
##     dim <- max(nr, nc)

##     ## Create adjacency matrix to id duplicates
##     mat.adj <- sparseMatrix(i = dups$idA.t, j = dups$idB.t, x = dups$zeta.j,
##                             dims = c(dim, dim))
##     mat.adj <- as.matrix(mat.adj)

##     ## Solve linear sum assignment problem
##     T1 <- assignment(-matrix)
##     temp.0 <- cbind(1:dim, T1$perm)
##     n1 <- which(rowSums(matrix) == 0)
##     n2 <- which(colSums(matrix) == 0)

##     if(length(n1) > 0) {
##         temp.0 <- temp.0[-n1, ]
##     }

##     if(length(n2) > 0) {
##         temp.0 <- temp.0[, -n2]
##     }
    
##     temp.0 <- data.frame(temp.0)
##     names(temp.0) <- c("idA.t", "idB.t")

##     ## Merge in dedupe information
##     dedup <- merge(temp.0, dups, by = c("idA.t", "idB.t"))
##     dedup$idA.t <- dedup$idB.t <- NULL

##     ## Combine dupes, dedupes
##     matchesA <- rbind(dedup, nodups)
##     matchesA$dupA <- matchesA$dupB <- NULL	
##     listA <- paste(matchesA$idA, matchesA$idB, sep = "-")
##     listB <- paste(matchesB$idA, matchesB$idB, sep = "-")
##     keep <- which(listB %in% listA)
##     matchesB <- matchesB[keep, ]

##     ## Subset down and order
##     matchesA <- matchesA[order(matchesA$idA, matchesA$idB), ]
##     matchesB <- matchesB[order(matchesB$idA, matchesB$idB), ]

##     ## Return deduped object
##     out <- list(matchesA = matchesA, matchesB = matchesB, EM = EM)
##     return(out)

## }



