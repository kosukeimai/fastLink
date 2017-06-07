#' dedupeMatches
#'
#' Dedupe matched dataframes.
#'
#' @usage dedupeMatches(matchesA, matchesB, EM,
#' matchesLink, varnames, stringdist.match, partial.match,
#' linprog, stringdist.method, cut.a = 0.92, cut.p = 0.88,
#' jw.weight)
#' @param matchesA A dataframe of the matched observations in
#' dataset A, with all variables used to inform the match.
#' @param matchesB A dataframe of the matched observations in
#' dataset B, with all variables used to inform the match.
#' @param EM The EM object from \code{emlinkMARmov()}
#' @param matchesLink The output from \code{matchesLink()}
#' @param varnames A vector of variable names to use for matching.
#' Must be present in both matchesA and matchesB.
#' @param stringdist.match A vector of booleans, indicating whether to use
#' string distance matching when determining matching patterns on
#' each variable. Must be same length as varnames.
#' @param partial.match A vector of booleans, indicating whether to include
#' a partial matching category for the string distances. Must be same length
#' as varnames. Default is FALSE for all variables.
#' @param linprog Whether to implement Winkler's linear programming solution to the deduplication
#' problem. Default is false.
#' @param stringdist.method String distance method for calculating similarity, options are: "jw" Jaro-Winkler (Default), "jaro" Jaro, and "lv" Edit
#' @param cut.a Lower bound for full string-distance match, ranging between 0 and 1. Default is 0.92
#' @param cut.p Lower bound for partial string-distance match, ranging between 0 and 1. Default is 0.88
#' @param jw.weight Parameter that describes the importance of the first characters of a string (only needed if stringdist.method = "jw"). Default is .10
#'
#' @return \code{dedupeMatches()} returns a list containing the following elements:
#' \item{matchesA}{A deduped version of matchesA}
#' \item{matchesB}{A deduped version of matchesB}
#' \item{EM}{A deduped version of the EM object}
#' 
#' @author Ted Enamorado <ted.enamorado@gmail.com> and Ben Fifield <benfifield@gmail.com>
#' @export
#' @importFrom adagio assignment
#' @importFrom dplyr group_by summarise n "%>%"
#' @importFrom stringdist stringdist
#' @importFrom stats runif
dedupeMatches <- function(matchesA, matchesB, EM, matchesLink,
                          varnames, stringdist.match, partial.match,
                          linprog = FALSE, stringdist.method = "jw",
                          cut.a = 0.92, cut.p = 0.88, jw.weight = .10){

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

    ## Get original column names
    colnames.df.a <- colnames(matchesA)
    colnames.df.b <- colnames(matchesB)

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
    names(gammalist) <- namevec

    ## -------------------------------
    ## Convert EM object to data frame
    ## -------------------------------
    emdf <- as.data.frame(EM$patterns.w)
    emdf$zeta.j <- c(EM$zeta.j)

    ## ---------------------
    ## Merge EM to gammalist
    ## ---------------------
    matchesA <- cbind(matchesA, gammalist)
    matchesB <- cbind(matchesB, gammalist)
    matchesA$roworder <- 1:nrow(matchesA)
    matchesB$roworder <- 1:nrow(matchesB)
    matchesA <- merge(matchesA, emdf, by = namevec, all.x = TRUE)
    matchesB <- merge(matchesB, emdf, by = namevec, all.x = TRUE)
    matchesA <- matchesA[order(matchesA$roworder),]
    matchesB <- matchesB[order(matchesB$roworder),]

    ## ------------
    ## Start dedupe
    ## ------------
    ## Ids 
    matchesA$idA <- matchesLink$inds.a
    matchesB$idB <- matchesLink$inds.b
    matchesB$idA <- matchesA$idA
    matchesA$idB <- matchesB$idB

    ## Remove observations with NA for zeta.j
    matchesA <- matchesA[!is.na(matchesA$zeta.j),]
    matchesB <- matchesB[!is.na(matchesB$zeta.j),]

    if(!linprog){

        ## Step 1: Find max zeta for each observation in dataset A:
        ## Merge in maximum zeta for each observation in dataset A
        temp <- as.matrix(tapply(matchesA$zeta.j, matchesA$idA, max, na.rm = T))			
        temp <- data.frame(cbind(as.numeric(rownames(temp)), as.numeric(temp)))
        names(temp) <- c("idA", "zeta.max")
        matchesA <- merge(matchesA, temp, by = "idA")

        ## Calculate difference
        matchesA <- matchesA[order(matchesA$roworder), ]			
        matchesB <- matchesB[order(matchesB$roworder), ]			
        matchesA$rm <- abs(matchesA$zeta.j - matchesA$zeta.max)
        rm <- which(matchesA$rm == 0)

        ## Subset down to max zetas
        matchesA <- matchesA[rm, ]
        matchesB <- matchesB[rm, ]

        ## Step 2: Find max zeta for each observation in dataset B, if in first subset:
        ## Merge in maximum zeta for each observation in dataset B
        temp <- as.matrix(tapply(matchesB$zeta.j, matchesB$idB, max, na.rm = T))			
        temp <- data.frame(cbind(as.numeric(rownames(temp)), as.numeric(temp)))
        names(temp) <- c("idB", "zeta.max")
        matchesB <- merge(matchesB, temp, by = "idB")

        ## Calculate difference
        matchesA <- matchesA[order(matchesA$roworder), ]			
        matchesB <- matchesB[order(matchesB$roworder), ]			
        matchesB$rm <- abs(matchesB$zeta.j - matchesB$zeta.max)
        rm <- which(matchesB$rm == 0)

        ## Subset down to max zetas
        matchesA <- matchesA[rm, ]
        matchesB <- matchesB[rm, ]

        ## Step 3: Break remaining ties
        ## Find remaining duplicates in A
        d1 <- duplicated(matchesA$idA)
        d2 <- duplicated(matchesA$idA, fromLast = T)
        matchesA$dA <- ifelse((d1 + d2) > 0, 1, 0)
        matchesB$dA <- ifelse((d1 + d2) > 0, 1, 0)

        ## Draw uniform to break tie, and merge in 
        matchesA$uni <- runif(nrow(matchesA))			
        temp <- as.matrix(tapply(matchesA$uni, matchesA$idA, max, na.rm = T))			
        temp <- data.frame(cbind(as.numeric(rownames(temp)), as.numeric(temp)))
        names(temp) <- c("idA", "uni.max")
        matchesA <- merge(matchesA, temp, by = "idA")
        matchesA <- matchesA[order(matchesA$roworder), ]			
        matchesB <- matchesB[order(matchesB$roworder), ]			
        matchesA$rm <- abs(matchesA$uni - matchesA$uni.max)
        rm <- which(matchesA$rm == 0)

        ## Subset down to broken tie
        matchesA <- matchesA[rm, ]
        matchesB <- matchesB[rm, ]
        
    }else{

        ## Find duplicates
        dupA <- duplicated(matchesA$idA)
        dupB <- duplicated(matchesA$idA, fromLast = T)
        matchesA$dupA <- ifelse(dupA == 1 | dupB == 1, 1, 0)

        dupA <- duplicated(matchesB$idB)
        dupB <- duplicated(matchesB$idB, fromLast = T)
        matchesA$dupB <- ifelse(dupA == 1 | dupB == 1, 1, 0)

        ## Split into dupes, not dups
        dups <- subset(matchesA, dupA == 1 | dupB == 1)
        nodups <- subset(matchesA, dupA == 0 & dupB == 0)

        dups$idA.t <- as.numeric(as.factor(dups$idA))
        dups$idB.t <- as.numeric(as.factor(dups$idB))

        nr <- max(dups$idA.t)
        nc <- max(dups$idB.t)
        dim <- max(nr, nc)

        ## Create adjacency matrix to id duplicates
        mat.adj <- sparseMatrix(i = dups$idA.t, j = dups$idB.t, x = dups$zeta.j,
                                dims = c(dim, dim))
        mat.adj <- as.matrix(mat.adj)

        ## Solve linear sum assignment problem
        T1 <- suppressWarnings(assignment(-mat.adj))
        temp.0 <- cbind(1:dim, T1$perm)
        n1 <- which(rowSums(mat.adj) == 0)
        n2 <- which(colSums(mat.adj) == 0)

        if(length(n1) > 0) {
            temp.0 <- temp.0[-n1, ]
        }

        if(length(n2) > 0) {
            temp.0 <- temp.0[, -n2]
        }

        temp.0 <- data.frame(temp.0)
        names(temp.0) <- c("idA.t", "idB.t")

        ## Merge in dedupe information
        dedup <- merge(temp.0, dups, by = c("idA.t", "idB.t"))
        dedup$idA.t <- dedup$idB.t <- NULL

        ## Combine dupes, dedupes
        matchesA <- rbind(dedup, nodups)
        matchesA$dupA <- matchesA$dupB <- NULL	
        listA <- paste(matchesA$idA, matchesA$idB, sep = "-")
        listB <- paste(matchesB$idA, matchesB$idB, sep = "-")
        keep <- which(listB %in% listA)
        matchesB <- matchesB[keep, ]

        ## Subset down and order
        matchesA <- matchesA[order(matchesA$idA, matchesA$idB), ]
        matchesB <- matchesB[order(matchesB$idA, matchesB$idB), ]

    }

    ## -----------------
    ## Correct EM object
    ## -----------------
    counts <- eval(parse(
        text = paste0("data.frame(matchesA %>% group_by(",
                      paste(namevec, collapse = ", "),
                      ") %>% summarise(counts = n()))"))
        )
    patterns <- as.data.frame(EM$patterns.w)
    patterns$rownum <- 1:nrow(patterns)
    patterns <- merge(patterns, counts, by = namevec, all.x = TRUE)
    patterns$counts.x <- ifelse(!is.na(patterns$counts.y), patterns$counts.y,
                                patterns$counts.x)
    patterns <- patterns[order(patterns$rownum),]
    patterns$counts.y <- NULL; patterns$rownum <- NULL
    names(patterns) <- c(namevec, "counts", "weights", "p.gamma.j.m", "p.gamma.j.u")
    EM$patterns.w <- as.matrix(patterns)

    ## --------------------------
    ## Correct matchesLink object
    ## --------------------------
    matchesLink <- data.frame(inds.a = matchesA$idA, inds.b = matchesB$idB)

    ## -------------------
    ## Get the zeta values
    ## -------------------
    max.zeta <- matchesA$zeta.j

    ## --------------------------
    ## Correct dataframes objects
    ## --------------------------
    matchesA <- subset(matchesA, select = colnames.df.a)
    matchesB <- subset(matchesB, select = colnames.df.b)

    ## Return deduped object
    out <- list(matchesA = matchesA, matchesB = matchesB,
                EM = EM, matchesLink = matchesLink,
                max.zeta = max.zeta)
    return(out)

}

