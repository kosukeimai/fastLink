#' getMatches
#'
#' Subset two data frames to the matches returned by \code{fastLink()}
#' or \code{matchesLink()}.
#'
#' @usage getMatches(dfA, dfB, fl.out)
#' @param dfA Dataset A - matched to Dataset B by \code{fastLink()}.
#' @param dfB Dataset B - matches to Dataset A by \code{fastLink()}.
#' @param fl.out Either the output from \code{fastLink()} or \code{matchesLink()}.
#'
#' @return \code{getMatches()} returns a list of two data frames:
#' \item{dfA.match}{A subset of \code{dfA} subsetted down to the successful matches.}
#' \item{dfB.match}{A subset of \code{dfB} subsetted down to the successful matches.}
#'
#' @author Ben Fifield  <benfifield@gmail.com>
#'
#' @examples
#' \dontrun{
#' fl.out <- fastLink(dfA, dfB,
#' varnames = c("firstname", "lastname", "streetname", "birthyear"),
#' n.cores = 1)
#' ret <- getMatches(dfA, dfB, fl.out)
#' }
#' @export
getMatches <- function(dfA, dfB, fl.out){

    ## Depending on class
    if("matchesLink" %in% class(fl.out)){
        dfA.match <- dfA[fl.out$inds.a,]
        dfB.match <- dfB[fl.out$inds.b,]
    }else{
        dfA.match <- dfA[fl.out$matches$inds.a,]
        dfB.match <- dfB[fl.out$matches$inds.b,]
        if("max.zeta" %in% names(fl.out)){
            dfA.match$max.zeta <- fl.out$max.zeta
            dfB.match$max.zeta <- fl.out$max.zeta
        }
    }

    return(list(dfA.match = dfA.match, dfB.match = dfB.match))
    
}

