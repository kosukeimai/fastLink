#' clusterWordEmbed
#'
#' Use word embedding to create properly sized clusters for matching.
#' The function first creates a word embedding out of the provided
#' vectors, and then runs PCA on the matrix. It then takes the first
#' \code{k} dimensions (where \code{k} is provided by the user) and
#' k-means is run on that matrix to get the clusters.
#'
#' @usage clusterWordEmbed(vecA, vecB, nclusters, max_n, k)
#'
#' @param vecA The character vector from dataset A
#' @param vecB The character vector from dataset B
#' @param nclusters The number of clusters to create from the provided data. Either
#' nclusters = NULL or max_n = NULL.
#' @param max_n The maximum size of either dataset A or dataset B in
#' the largest cluster. Either nclusters = NULL or max_n = NULL
#' @param k The number of dimensions to use from PCA for k-means.
#'
#' @return \code{clusterWordEmbed} returns a list of length 3:
#' \item{clusterA}{The cluster assignments for dataset A}
#' \item{clusterB}{The cluster assignments for dataset B}
#' \item{n.clusters}{The number of clusters created}
#'
#' @author Ben Fifield <benfifield@gmail.com>
#'
#' @examples data(samplematch)
#' cl <- clusterWordEmbed(dfA$firstname, dfB$firstname, nclusters = 3)
#' @export
clusterWordEmbed <- function(vecA, vecB, nclusters = NULL, max_n = NULL, k = 3){

    ## Warning
    if(is.null(nclusters) & is.null(max_n)){
        stop("Please provide either the number of clusters ('nclusters') to create or the maximum n of each cluster ('max_n') as an argument.")
    }

    ## Clean and combine
    if(class(vecA) == "factor"){
        vecA <- as.character(vecA)
    }
    if(class(vecB) == "factor"){
        vecB <- as.character(vecB)
    }
    setid <- c(rep(1, length(vecA)), rep(2, length(vecB)))
    vec <- c(vecA, vecB)
    
    ## Create word embedding
    out <- sapply(letters, function(x){str_count(vec$firstname, x)})

    ## Do pca
    pca.out <- prcomp(out, scale = TRUE)
    pred <- predict(pca.out, out)

    ## Get first K dimensions
    dims <- pred[,1:k]

    ## Run kmeans
    if(!is.null(nclusters)){
        ncl <- nclusters
    }else{
        ncl <- max(round(max(length(vecA), length(vecB))/max_n, 0), 1)
    }
    km.out <- kmeans(dims, centers = ncl, iter.max = 5000)
    cluster <- km.out$cluster

    return(list(clusterA = cluster[setid == 1], clusterB = cluster[setid == 2],
                n.clusters = ncl))
    
}

