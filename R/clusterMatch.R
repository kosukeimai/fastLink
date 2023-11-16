#' clusterMatch
#'
#' Creates properly sized clusters for matching, using either
#' alphabetical or word embedding clustering. If using word embedding,
#' the function first creates a word embedding out of the provided
#' vectors, and then runs PCA on the matrix. It then takes the first
#' \code{k} dimensions (where \code{k} is provided by the user) and
#' k-means is run on that matrix to get the clusters.
#'
#' @usage clusterMatch(vecA, vecB, nclusters, max.n, word.embed, min.var, iter.max)
#'
#' @param vecA The character vector from dataset A
#' @param vecB The character vector from dataset B
#' @param nclusters The number of clusters to create from the provided data. Either
#' nclusters = NULL or max.n = NULL.
#' @param max.n The maximum size of either dataset A or dataset B in
#' the largest cluster. Either nclusters = NULL or max.n = NULL
#' @param word.embed Whether to use word embedding clustering. Default is FALSE.
#' @param min.var The minimum amount of explained variance (maximum = 1) a
#' PCA dimension can provide in order to be included in k-means clustering when
#' using word embedding. Default is .20.
#' @param iter.max Maximum number of iterations for the k-means algorithm.
#'
#' @return \code{clusterMatch} returns a list of length 3:
#' \item{clusterA}{The cluster assignments for dataset A}
#' \item{clusterB}{The cluster assignments for dataset B}
#' \item{n.clusters}{The number of clusters created}
#' \item{kmeans}{The k-means object output.}
#' \item{pca}{The PCA object output.}
#' \item{dims.pca}{The number of dimensions from PCA used for the k-means clustering.}
#'
#' @author Ben Fifield <benfifield@gmail.com>
#'
#' @examples data(samplematch)
#' cl <- clusterMatch(dfA$firstname, dfB$firstname, nclusters = 3)
#' @export
#' @importFrom stringr str_count
clusterMatch <- function(vecA, vecB,
                         nclusters = NULL, max.n = NULL,
                         word.embed = FALSE,
                         min.var = .20,
                         iter.max = 5000){
  
  ## Warning
  if(is.null(nclusters) & is.null(max.n)){
    stop("Please provide either the number of clusters ('nclusters') to create or the maximum n of each cluster ('max.n') as an argument.")
  }
  
  ## Clean and combine
  if(is(vecA, "factor")){
    vecA <- as.character(vecA)
  }
  if(is(vecB, "factor")){
    vecB <- as.character(vecB)
  }
  
  setid <- c(rep(1, length(vecA)), rep(2, length(vecB)))
  vec <- c(vecA, vecB)
  
  ## ------------------------
  ## Which type of clustering
  ## ------------------------
  if(word.embed){   
    ## Create word embedding
    out <- sapply(letters, function(x){str_count(vec, x)})
    
    ## Do pca
    pca.out <- prcomp(out, scale = TRUE)
    pred <- predict(pca.out, out)
    
    ## Get difference in variances
    vars <- apply(pca.out$x, 2, var)  
    props <- vars / sum(vars)
    cs.var <- cumsum(props)
    diffs <- diff(cs.var)
    dims.include <- c(1, which(diffs > min.var) + 1)
    
    ## Get first K dimensions
    dims <- pred[,1:dims.include]
  }else{
    dims <- as.numeric(as.factor(vec))
    weighted.kmeans <- FALSE
  }
  
  ## ----------
  ## Run kmeans
  ## ----------
  if(!is.null(nclusters)){
    ncl <- nclusters
  }else{
    ncl <- max(round(max(length(vecA), length(vecB))/max.n, 0), 1)
  }
  km.out <- kmeans(dims, centers = ncl, iter.max = iter.max)
  cluster <- km.out$cluster
  
  ## --------------------
  ## Create output object
  ## --------------------
  if(word.embed){
    out <- list(clusterA = cluster[setid == 1], clusterB = cluster[setid == 2],
                n.clusters = ncl, kmeans = km.out,
                pca = pca.out, dims.pca = dims.include)
  }else{
    out <- list(clusterA = cluster[setid == 1], clusterB = cluster[setid == 2],
                n.clusters = ncl, kmeans = km.out)
  }
  
  return(out)
  
}

