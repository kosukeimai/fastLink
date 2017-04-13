#' Record Linkage under MAR
#'
#' This packages provides functions to perform link (merge
#' probabilistically) two datasets when a unique identifier is missing.
#' 
#' \tabular{ll}{ Package: \tab fastLink\cr Type: \tab Package\cr Version: \tab 0.1.-\cr
#' Date: \tab 2017-01-27\cr License: \tab GPL (>= 3)\cr }
#'
#' @name fastLink-package
#' @useDynLib fastLink, .registration = TRUE
#' @aliases fastLink-package fastLink
#' @docType package
#' @author Ted Enamorado \email{tede@@princeton.edu} and Kosuke Imai \email{kimai@@princeton.edu}
#' 
#' Maintainer: Ted Enamorado \email{tede@@princeton.edu}
#' @keywords package
#' @import Matrix parallel foreach doParallel gtools stringdist data.table RcppEigen stringr Hmisc
#' @importFrom Rcpp evalCpp
#' @importFrom FactoClass kmeansW
NULL
