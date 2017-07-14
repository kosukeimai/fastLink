#' inspectEM
#'
#' Inspect EM objects to analyze successfully and
#' unsuccessfully matched patterns.
#'
#' @usage inspectEM(object, posterior.range, digits)
#' @param object The output from either \code{fastLink} or \code{emlinkMARmov}.
#' @param posterior.range The range of posterior probabilities to display.
#' Default is c(0.85, 1).
#' @param digits How many digits to include in inspectEM dataframe. Default is 3.
#'
#' @return \code{inspectEM} returns a data frame with information
#' about patterns around the provided threshold.
#'
#' @author Ben Fifield <bfifield@princeton.edu>
#' @export
inspectEM <- function(object, posterior.range = c(0.85, 1), digits = 3){

    ## Extract EM object
    if("fastLink.EM" %in% class(object)){
        em <- object
    }else if(length(class(object)) == 1 & "fastLink" %in% class(object)){
        em <- object$EM
    }else if(!("fastLink" %in% class(object))){
        stop("inspectEM() is not compatible with the input object.")
    }

    if(min(posterior.range) < 0 | max(posterior.range) > 1){
        stop("Please make sure that posterior.range is between 0 and 1.")
    }
    if(length(posterior.range) == 1){
        posterior.range <- c(posterior.range, 1)
    }

    ## ---------------
    ## Output patterns
    ## ---------------
    ## Clean up object
    em.ins <- data.frame(em$patterns.w)
    em.ins$zeta.j <- em$zeta.j
    em.ins <- em.ins[order(em.ins[, "zeta.j"]), ]
    
    ## Which pattern is closest to the threshold?
    min <- which.min(abs(em.ins$zeta.j - min(posterior.range)))
    max <- which.min(abs(em.ins$zeta.j - max(posterior.range)))
    em.ins <- em.ins[min:max,]

    ## Clean up outputted object
    inds.gamma <- grep("gamma.[[:digit:]]", colnames(em.ins))
    em.ins[,inds.gamma] <- ifelse(em.ins[,inds.gamma] == 2, "M",
                           ifelse(em.ins[,inds.gamma] == 1, "PM",
                           ifelse(em.ins[,inds.gamma] == 0, "NM", NA)))
    em.ins[,(max(inds.gamma)+1):ncol(em.ins)] <- round(em.ins[,(max(inds.gamma)+1):ncol(em.ins)], digits)
    if(is.null(em$varnames)){
        varnames <- paste0("gamma.", 1:max(inds.gamma))
    }else{
        varnames <- em$varnames
    }
    colnames(em.ins)[inds.gamma] <- varnames

    ## ------------------------
    ## Output other information
    ## ------------------------
    ## Number of matches
    num.matches <- sum(em.ins$counts * em.ins$zeta.j)

    ## Gammas
    gammaprob <- em$p.gamma.k.m
    names(gammaprob) <- varnames
    gammaprob <- lapply(gammaprob, function(x){round(x, digits)})
    out <- list(match.patterns = em.ins, matchprob.by.variable = gammaprob,
                num.matches = num.matches, posterior.range = posterior.range,
                nobs.a = em$nobs.a, nobs.b = em$nobs.b, iter.converge = em$iter.converge,
                lambda = em$p.m)
    class(out) <- c("fastLink", "inspectEM")
    
    return(out)
    
}
