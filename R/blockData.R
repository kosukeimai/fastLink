#' stringSubset
#'
#' Removes as candidate matches any observations with no close matches on
#' string-distance measures.
#'
#' @usage stringSubset(vecA, vecB, similarity.threshold, stringdist.method,
#' jw.weight, n.cores)
#' @param vecA A character or factor vector from dataset A
#' @param vecB A character or factor vector from dataset B
#' @param similarity.threshold Lower bound on string-distance measure for being considered a possible match.
#' If an observation has no possible matches above this threshold, it is discarded from the match. Default is 0.8.
#' @param stringdist.method The method to use for calculating string-distance similarity. Possible values are
#' 'jaro' (Jaro Distance), 'jw' (Jaro-Winkler), and 'lv' (Levenshtein). Default is 'jw'.
#' @param jw.weight Parameter that describes the importance of the first characters of a string (only needed if stringdist.method = "jw"). Default is .10.
#' @param n.cores Number of cores to parallelize over. Default is NULL.
#'
#' @return A list of length two, where the both entries are a vector of dummies corresponding to dataset A (entry 1) and dataset B (entry 2). A value of 1 indicates that
#' the observation should be used in the match, while an entry of 0 should not be included.
#'
#' @examples
#' \dontrun{
#' subset_out <- stringSubset(dfA$firstname, dfB$lastname, n.cores = 1)
#' fl_out <- fastLink(dfA[subset_out$dfA.block == 1,], dfB[subset_out$dfB.block == 1,],
#' varnames = c("firstname", "lastname", "streetname", "birthyear"), n.cores = 1)
#' }
#' @export
stringSubset <- function(vecA, vecB,
                         similarity.threshold = .8, stringdist.method = "jw",
                         jw.weight = .10, n.cores = NULL){

    if(class(vecA) == "factor"){
        vecA <- as.character(vecA)
    }
    if(class(vecB) == "factor"){
        vecB <- as.character(vecB)
    }
    if(class(vecA) != "character" | class(vecB) != "character"){
        stop("vecA and vecB must be of class factor or character.")
    }
    if(!(stringdist.method %in% c("jw", "jaro", "lv"))){
        stop("Invalid string distance method. Method should be one of 'jw', 'jaro', or 'lv'.")
    }
    if(similarity.threshold < 0 | similarity.threshold > 1){
        stop("similarity.threshold must be between 0 and 1.")
    }
    if(stringdist.method == "jw" & !is.null(jw.weight)){
        if(jw.weight < 0 | jw.weight > 0.25){
            stop("Invalid value provided for jw.weight. Remember, jw.weight in [0, 0.25].")
        }
    }
    
    ## Remove any very unlikely matches by first name
    gamma.out <- gammaCK2par(vecA, vecB, cut.a = similarity.threshold, method = stringdist.method, n.cores = n.cores)
    gamma.sub <- do.call(Map, c(c, gamma.out[[1]]))

    ## Get the voter file ids
    ids.A <- rep(0, length(vecA))
    ids.B <- rep(0, length(vecB))
    ids.A[unique(gamma.sub[[1]])] <- 1
    ids.B[unique(gamma.sub[[2]])] <- 1
    out <- list(dfA.block = ids.A, dfB.block = ids.B)
    class(out) <- "fastLink.block"
    
    return(out)
    
}

#' blockData
#'
#' Contains functionalities for blocking two data sets on one or more variables prior to
#' conducting a merge.
#'
#' @usage blockData(dfA, dfB, varnames, window.block, window.size,
#' kmeans.block, nclusters, iter.max,
#' stringdist.subset, similarity.threshold, stringdist.method, jw.weight,
#' n.cores)
#' @param dfA Dataset A - to be matched to Dataset B
#' @param dfB Dataset B - to be matched to Dataset A
#' @param varnames A vector of variable names to use for blocking.
#' Must be present in both dfA and dfB
#' @param window.block A vector of variable names indicating that the variable should be
#' blocked using windowing blocking. Must be present in varnames.
#' @param window.size The size of the window for window blocking. Default is 1
#' (observations +/- 1 on the specified variable will be blocked together).
#' @param kmeans.block A vector of variable names indicating that the variable should be
#' blocked using k-means blocking. Must be present in varnames.
#' @param nclusters Number of clusters to create with k-means. Default value is the
#' number of clusters where the average cluster size is 100,000 observations.
#' @param iter.max Maximum number of iterations for the k-means algorithm to run. Default is 5000
#' @param stringdist.subset A single variable name present in dfA and dfB to run string-distance
#' subsetting on, so that any observations that is not close to any other observation on the metric
#' will be excluded from all blocks.
#' @param similarity.threshold Lower bound on string-distance measure for being considered a possible match.
#' If an observation has no possible matches above this threshold, it is discarded from the match. Default is 0.8.
#' @param stringdist.method The method to use for calculating string-distance similarity. Possible values are
#' 'jaro' (Jaro Distance), 'jw' (Jaro-Winkler), and 'lv' (Levenshtein). Default is 'jw'.
#' @param jw.weight Parameter that describes the importance of the first characters of a string (only needed if stringdist.method = "jw"). Default is .10.
#' @param n.cores Number of cores to parallelize over. Default is NULL.
#'
#' @return A list with an entry for each block. Each list entry contains two vectors --- one with the indices indicating the block members in dataset A,
#' and another containing the indices indicating the block members in dataset B.
#'
#' @usage
#' \dontrun{
#' block_out <- blockData(dfA, dfB, varnames = c("city", "birthyear"))
#' }
#'
#' @export
blockData <- function(dfA, dfB, varnames, window.block = NULL,
                      window.size = 1,
                      kmeans.block = NULL,
                      nclusters = max(round(min(nrow(dfA), nrow(dfB)) / 100000, 0), 1),                      
                      iter.max = 5000,
                      stringdist.subset = NULL,
                      similarity.threshold = .8, stringdist.method = "jw",
                      jw.weight = .10, n.cores = NULL){

    ## ---------------------------
    ## Clean data and check inputs
    ## ---------------------------
    if(any(class(dfA) %in% c("tbl_df", "data.table"))){
        dfA <- as.data.frame(dfA)
    }
    if(any(class(dfB) %in% c("tbl_df", "data.table"))){
        dfB <- as.data.frame(dfB)
    }
    if(any(!(varnames %in% names(dfA)))){
        stop("Some variables in varnames are not present in dfA.")
    }
    if(any(!(varnames %in% names(dfB)))){
        stop("Some variables in varnames are not present in dfB.")
    }
    if(any(!(window.block %in% varnames))){
        stop("You have provided a variable name for window.block that is not in 'varnames'.")
    }
    if(any(!(kmeans.block %in% varnames))){
        stop("You have provided a variable name for kmeans.block that is not in 'varnames'.")
    }
    if(!is.null(stringdist.subset)){
        if(length(stringdist.subset) > 1){
            stop("Please provide only a single variable name for string distance subsetting.")
        }
        if(!(stringdist.subset %in% names(dfA))){
            stop("The specified variable in stringdist.subset is not present in dfA.")
        }
        if(!(stringdist.subset %in% names(dfB))){
            stop("The specified variable in stringdist.subset is not present in dfB.")
        }
        if(!(stringdist.method %in% c("jw", "jaro", "lv"))){
            stop("Invalid string distance method. Method should be one of 'jw', 'jaro', or 'lv'.")
        }
        if(similarity.threshold < 0 | similarity.threshold > 1){
            stop("similarity.threshold must be between 0 and 1.")
        }
        if(stringdist.method == "jw" & !is.null(jw.weight)){
            if(jw.weight < 0 | jw.weight > 0.25){
                stop("Invalid value provided for jw.weight. Remember, jw.weight in [0, 0.25].")
            }
        }
    }
    classA <- lapply(dfA[,varnames], class)
    classB <- lapply(dfB[,varnames], class)
    if(any(unlist(classA)[names(classA) %in% window.block] != "numeric") |
       any(unlist(classB)[names(classB) %in% window.block] != "numeric")){
        stop("You have specified that a variable be blocked using window blocking, but that variable is not of class 'numeric'. Please check your variable classes.")
    }
    if(any(unlist(classA)[names(classA) %in% kmeans.block] == "numeric") |
       any(unlist(classB)[names(classB) %in% kmeans.block] == "numeric")){
        stop("You have specified that a variable be blocked using k-means blocking, but that variable is of class 'numeric'. Please check your variable classes.")
    }
    if(is.null(n.cores)){
        n.cores <- detectCores() - 1
    }

    ## ----------
    ## Block data
    ## ----------
    cl <- makeCluster(n.cores)
    registerDoParallel(cl)
    blocklist <- foreach(i = 1:length(varnames)) %dopar% {
        if(varnames[i] %in% window.block){
            bl_out <- windowBlock(dfA[,varnames[i]], dfB[,varnames[i]], window.size = window.size)
        }else if(varnames[i] %in% kmeans.block){
            bl_out <- kmeansBlock(dfA[,varnames[i]], dfB[,varnames[i]], nclusters = nclusters, iter.max = iter.max)
        }else{
            bl_out <- exactBlock(dfA[,varnames[i]], dfB[,varnames[i]])
        }
        return(bl_out)
    }
    stopCluster(cl)

    ## --------------
    ## Combine blocks
    ## --------------
    combineblocks_out <- combineBlocks(blocklist)
    indlist_a <- apply(combineblocks_out$dfA.block, 2, function(x){which(x == 1)})
    indlist_a <- indlist_a[lapply(indlist_a, length) > 0]
    indlist_b <- apply(combineblocks_out$dfB.block, 2, function(x){which(x == 1)})
    indlist_b <- indlist_b[lapply(indlist_b, length) > 0]

    ## --------------------------
    ## String-distance subsetting
    ## --------------------------
    if(!is.null(stringdist.subset)){
        for(i in 1:length(indlist_a)){
            stringdist_out <- stringSubset(dfA[indlist_a[[i]], stringdist.subset],
                                           dfB[indlist_b[[i]], stringdist.subset],
                                           similarity.threshold = similarity.threshold,
                                           stringdist.method = stringdist.method,
                                           jw.weight = jw.weight, n.cores = n.cores)
            indlist_a[[i]] <- indlist_a[[i]][which(stringdist_out$dfA.block == 1)]
            indlist_b[[i]] <- indlist_b[[i]][which(stringdist_out$dfB.block == 1)]
        }
    }

    ## Clean up
    blocklist_out <- vector(mode = "list", length = length(indlist_a))
    for(i in 1:length(blocklist_out)){
        blocklist_out[[i]] <- list(dfA.inds = indlist_a[[i]], dfB.inds = indlist_b[[i]])
    }
    names(blocklist_out) <- paste0("block.", 1:length(blocklist_out))
    class(blocklist_out) <- "fastLink.block"
    return(blocklist_out)

}

windowBlock <- function(vecA, vecB, window.size = 1){
    
    ## Clean and combine
    vec <- c(vecA, vecB)
    setid <- c(rep("A", length(vecA)), rep("B", length(vecB)))

    ## Run blocking
    min_num <- min(vec, na.rm = TRUE)
    max_num <- max(vec, na.rm = TRUE)
    num_seq <- (min_num + 1):(max_num - 1)
    indlist_out <- vector(mode = "list", length = length(num_seq))
    for(i in 1:length(num_seq)){
        inds <- which(vec >= (num_seq[i] - window.size) &
                      vec <= (num_seq[i] + window.size))
        indlist_out[[i]] <- cbind(inds, i)
    }
    indlist_out <- do.call(rbind, indlist_out)
    na_inds <- (1:length(vec))[!(1:length(vec) %in% unique(indlist_out[,1]))]
    if(length(na_inds) > 0){
        indlist_out <- rbind(indlist_out, cbind(na_inds, length(num_seq) + 1))
    }
    mat_out <- sparseMatrix(i = indlist_out[,1], j = indlist_out[,2])

    ## Return object
    out <- list(dfA.block = mat_out[setid == "A",],
                dfB.block = mat_out[setid == "B",])
    class(out) <- "fastLink.block"
    return(out)
    
}

exactBlock <- function(vecA, vecB){

    ## Clean and combine
    vec <- c(vecA, vecB)
    setid <- c(rep("A", length(vecA)), rep("B", length(vecB)))

    ## Unique values of vec
    unq_val <- unique(vec)

    ## Loop over and define blocks
    indlist_out <- vector(mode = "list", length = length(unq_val))
    for(i in 1:length(unq_val)){
        if(!is.na(unq_val[i])){
            inds <- which(vec == unq_val[i])
        }else{
            inds <- which(is.na(vec))
        }
        indlist_out[[i]] <- cbind(inds, i)
    }
    indlist_out <- do.call(rbind, indlist_out)
    mat_out <- sparseMatrix(i = indlist_out[,1], j = indlist_out[,2])

    ## Return object
    out <- list(dfA.block = mat_out[setid == "A",],
                dfB.block = mat_out[setid == "B",])
    class(out) <- "fastLink.block"
    return(out)
    
}

kmeansBlock <- function(vecA, vecB, nclusters, iter.max = 5000){

    if(class(vecA) == "factor"){
        vecA <- as.character(vecA)
    }
    if(class(vecB) == "factor"){
        vecB <- as.character(vecB)
    }

    ## Clean and combine
    vec <- c(vecA, vecB)
    setid <- c(rep("A", length(vecA)), rep("B", length(vecB)))
    dims <- as.numeric(as.factor(vec))

    ## Run kmeans
    km.out <- kmeans(na.omit(dims), centers = nclusters, iter.max = iter.max)
    cluster <- rep(NA, length(vec))
    cluster[which(!is.na(vec))] <- km.out$cluster

    ## Create output
    indlist_out <- vector(mode = "list", length = nclusters)
    for(i in 1:nclusters){
        inds <- which(cluster == i)
        indlist_out[[i]] <- cbind(inds, i)
    }
    indlist_out <- do.call(rbind, indlist_out)
    na_inds <- (1:length(vec))[!(1:length(vec) %in% unique(indlist_out[,1]))]
    if(length(na_inds) > 0){
        indlist_out <- rbind(indlist_out, cbind(na_inds, nclusters + 1))
    }
    mat_out <- sparseMatrix(i = indlist_out[,1], j = indlist_out[,2])

    ## Return object
    out <- list(dfA.block = mat_out[setid == "A",],
                dfB.block = mat_out[setid == "B",])
    class(out) <- "fastLink.block"
    return(out)
    
}

combineBlocks <- function(blocklist){

    blkgrps <- NULL
    
    ## Unpack
    blockA <- vector(mode = "list", length = length(blocklist))
    blockB <- vector(mode = "list", length = length(blocklist))
    str <- ""
    for(i in 1:length(blocklist)){
        blockA[[i]] <- blocklist[[i]]$dfA.block
        blockB[[i]] <- blocklist[[i]]$dfB.block
        str <- paste0(str, "block.", i, "=1:", ncol(blockA[[i]]), ",")
    }
    str <- paste0("blkgrps <- expand.grid(", str, "stringsAsFactors = FALSE)")
    eval(parse(text = str))

    ## Get indices for each block
    indsA_out <- vector(mode = "list", length = nrow(blkgrps))
    indsB_out <- vector(mode = "list", length = nrow(blkgrps))
    for(i in 1:nrow(blkgrps)){

        indsA <- vector(mode = "list", length = ncol(blkgrps))
        indsB <- vector(mode = "list", length = ncol(blkgrps))
        for(j in 1:ncol(blkgrps)){
            indsA[[j]] <- which(blockA[[j]][,blkgrps[i,j]] == 1)
            indsB[[j]] <- which(blockB[[j]][,blkgrps[i,j]] == 1)
        }
        if(length(Reduce(intersect, indsA)) > 0 &
           length(Reduce(intersect, indsB)) > 0){
            indsA_out[[i]] <- cbind(Reduce(intersect, indsA), i)
            indsB_out[[i]] <- cbind(Reduce(intersect, indsB), i)
        }
        
    }

    ## Combine indices and create sparse matrix outputs
    indsA_out <- do.call(rbind, indsA_out)
    indsB_out <- do.call(rbind, indsB_out)
    matA_out <- sparseMatrix(i = indsA_out[,1], j = indsA_out[,2])
    matB_out <- sparseMatrix(i = indsB_out[,1], j = indsB_out[,2])

    out <- list(dfA.block = matA_out, dfB.block = matB_out)
    class(out) <- "fastLink.block"
    return(out)

}

