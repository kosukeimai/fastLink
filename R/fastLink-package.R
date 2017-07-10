#' Fast Probabilistic Record Linkage with Missing Data
#'
#' \code{fastLink} implements methods developed by Enamorado, Fifield, and Imai (2017)
#' ''Using a Probabilistic Model to Assist Merging of Large-scale Administrative Records'',
#' to probabilistically merge large datasets using the Fellegi-Sunter model
#' while allowing for missing data and the inclusion of auxiliary information.
#' The current version of this package conducts a merge of two datasets under
#' the Fellegi-Sunter model, using the Expectation-Maximization Algorithm. In addition,
#' tools for conducting and summarizing data merges are included. 
#' 
#' \tabular{ll}{ Package: \tab fastLink\cr Type: \tab Package\cr Version: \tab 0.1.1-\cr
#' Date: \tab 2017-07-10\cr License: \tab GPL (>= 3)\cr }
#'
#' @name fastLink-package
#' @useDynLib fastLink, .registration = TRUE
#' @aliases fastLink-package 
#' @docType package
#' @author Ted Enamorado \email{fastlinkr@@gmail.com}, Ben Fifield \email{fastlinkr@@gmail.com}, and Kosuke Imai \email{kimai@@princeton.edu}
#' 
#' Maintainer: Ted Enamorado \email{fastlinkr@@gmail.com}
#' @references Enamorado, Ted, Ben Fifield and Kosuke Imai. (2017) "Using a Probabilistic Model to Assist Merging of
#' Large-scale Administrative Records." Working Paper. Available at \url{http://imai.princeton.edu/research/linkage.html}.
#' @keywords package
#' @import Matrix data.table
#' @importFrom Rcpp evalCpp
#' @importFrom stats kmeans na.omit prcomp predict quantile var
#' @importFrom utils data
NULL
