#' Record Linkage under MAR
#'
#' Implements a Fellegi-Sunter probabilistic record linkage model
#' that allows for missing data.
#' 
#' \tabular{ll}{ Package: \tab fastLink\cr Type: \tab Package\cr Version: \tab 0.1.-\cr
#' Date: \tab 2017-01-27\cr License: \tab GPL (>= 3)\cr }
#'
#' @name fastLink-package
#' @useDynLib fastLink, .registration = TRUE
#' @aliases fastLink-package 
#' @docType package
#' @author Ted Enamorado \email{tede@@princeton.edu}, Ben Fifield \email{bfifield@@princeton.edu}, and Kosuke Imai \email{kimai@@princeton.edu}
#' 
#' Maintainer: Ted Enamorado \email{tede@@princeton.edu}
#' @keywords package
#' @import Matrix data.table
#' @importFrom Rcpp evalCpp
#' @importFrom stats kmeans na.omit prcomp predict quantile var
#' @importFrom utils data
NULL
