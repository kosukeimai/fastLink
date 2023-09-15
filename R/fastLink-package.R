#' Fast Probabilistic Record Linkage with Missing Data
#'
#' \code{fastLink} implements methods developed by Enamorado, Fifield, and Imai (2018)
#' ''Using a Probabilistic Model to Assist Merging of Large-scale Administrative Records'',
#' to probabilistically merge large datasets using the Fellegi-Sunter model
#' while allowing for missing data and the inclusion of auxiliary information.
#' The current version of this package conducts a merge of two datasets under
#' the Fellegi-Sunter model, using the Expectation-Maximization Algorithm. In addition,
#' tools for conducting and summarizing data merges are included. 
#'
#' @name fastLink-package
#' @useDynLib fastLink, .registration = TRUE
#' @aliases fastLink-package 
#' @docType package
#' @author Ted Enamorado \email{ted.enamorado@@gmail.com}, Ben Fifield \email{benfifield@@gmail.com}, and Kosuke Imai \email{imai@@harvard.edu}
#' 
#' Maintainer: Ted Enamorado \email{ted.enamorado@@gmail.com}
#' @references Enamorado, Ted, Ben Fifield and Kosuke Imai. (2019) "Using a Probabilistic Model to Assist Merging of
#' Large-scale Administrative Records." American Political Science Review. Vol. 113, No. 2. Available at \url{https://imai.fas.harvard.edu/research/files/linkage.pdf}.
#' @keywords package
#' @import Matrix data.table
#' @importFrom Rcpp evalCpp
#' @importFrom stats kmeans na.omit prcomp predict quantile var
#' @importFrom utils data
NULL
