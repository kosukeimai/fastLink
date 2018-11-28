#' String-distance comparison parse for formula
#'
#' @usage strdist(x, partial.match)
#'
#' @param x A variable name to match on
#' @param partial.match Whether or not to include a partial matching category. Default is FALSE.
#'
#' @export
strdist <- function(x, partial.match = FALSE){
    return(list(var = as.character(x), partial.match = partial.match))
}

#' Numeric-distance comparison parse for formula
#'
#' @usage numdist(x, partial.match)
#'
#' @param x A variable name to match on
#' @param partial.match Whether or not to include a partial matching category. Default is FALSE.
#'
#' @export
numdist <- function(x, partial.match = FALSE){
    return(list(var = as.character(x), partial.match = partial.match))
}

parse.formula <- function(formula){
    
    ## Get variables
    terms.out <- terms.formula(formula, specials = c("strdist", "numdist"))
    terms <- attr(terms.out, "term.labels")
    if(attr(terms.out, "response") != 0){
        stop("Please do not specify variables on left-hand-side of formula.")
    }

    ## Get indices
    sd <- attr(terms.out, "specials")$strdist
    nd <- attr(terms.out, "specials")$numdist
    vtab <- attr(terms.out, "factors")
    nt <- length(terms)
    if(length(sd) > 0){
        for(i in 1:length(sd)) {
            ind <- (1:nt)[as.logical(vtab[sd[i],])]
            sd[i] <- ind
        }
    }
    if(length(nd) > 0){
        for(i in 1:length(nd)) {
            ind <- (1:nt)[as.logical(vtab[nd[i],])]
            nd[i] <- ind 
        }
    }

    ## Loop through terms and run functions
    varnames <- rep(NA, nt)
    stringdist.match <- c()
    numeric.match <- c()
    partial.match <- c()
    for(i in 1:nt){
        if(i %in% c(sd, nd)){
            terms[i] <- gsub("\\(", "\\('", terms[i])
            if(grepl("partial", terms[i])){
                terms[i] <- gsub(",", "',", terms[i])
            }else{
                terms[i] <- gsub("\\)", "'\\)", terms[i])
            }
            st <- eval(parse(text = terms[i]))
            varnames[i] <- st$var
            if(st$partial.match){
                partial.match <- c(partial.match, st$var)
            }
            if(i %in% sd){
                stringdist.match <- c(stringdist.match, st$var)
            }
            if(i %in% nd){
                numeric.match <- c(numeric.match, st$var)
            }
        }else{
            varnames[i] <- terms[i]
        }
    }
    if(length(stringdist.match) == 0){
        stringdist.match <- NULL
    }
    if(length(numeric.match) == 0){
        numeric.match <- NULL
    }
    if(length(partial.match) == 0){
        partial.match <- NULL
    }

    return(list(varnames = varnames, stringdist.match = stringdist.match,
                numeric.match = numeric.match, partial.match = partial.match))

}
