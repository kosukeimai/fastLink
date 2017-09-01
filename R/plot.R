#' Plot matching patterns of the EM object by posterior probability of match
#'
#' \code{plot.fastLink()} plots the matching patterns of the EM object,
#' ordering the matching patterns by the posterior probability of the match.
#'
#' @usage \method{plot}{fastLink}(x, posterior.range, ...)
#' @param x Either a \code{fastLink} or \code{fastLink.EM} object to be plotted.
#' @param posterior.range The range of posterior probabilities to display.
#' Default is c(0.85, 1).
#' @param ... Further arguments to be passed to \code{plot.fastLink()}.
#'
#' @export
#' @method plot fastLink
#' @importFrom plotrix staxlab
#' @importFrom grDevices colorRampPalette
#' @importFrom graphics axis legend plot polygon
plot.fastLink <- function(x, posterior.range = c(.85, 1), ...){
    
    ## Extract EM object
    if("fastLink.EM" %in% class(x)){
        em <- x
    }else if(length(class(x)) == 1 & "fastLink" %in% class(x)){
        em <- x$EM
    }

    if(min(posterior.range) < 0 | max(posterior.range) > 1){
        stop("Please make sure that posterior.range is between 0 and 1.")
    }
    if(length(posterior.range) == 1){
        posterior.range <- c(posterior.range, 1)
    }

    em.ins <- em
    em.ins <- data.frame(em.ins$patterns.w)
    em.ins$zeta.j <- em$zeta.j
    em.ins <- em.ins[order(em.ins[, "zeta.j"]), ]
    inds.gamma <- grep("gamma.[[:digit:]]", colnames(em.ins))

    ## Subset to the neighborhood around threshold
    min <- which.min(abs(em.ins$zeta.j - posterior.range[1]))
    max <- which.min(abs(em.ins$zeta.j - posterior.range[2]))
    em.ins <- em.ins[min:max,]
    colfunc <- colorRampPalette(c("darkred", "white"))
    cols <- colfunc(3)
    if(is.null(em$varnames)){
        varnames <- paste0("gamma.", 1:max(inds.gamma))
    }else{
        varnames <- em$varnames
    }
    ylabs <- seq(min(posterior.range), max(posterior.range), by = .05)
    yinds <- sapply(ylabs, function(x){which.min(abs(em.ins$zeta.j - x))})

    ## Plot polygons
    extra.x <- ceiling(length(inds.gamma)/3)
    plot(1,
         type = "n",
         xlim = c(0, length(inds.gamma) + extra.x),
         ylim = c(0, nrow(em.ins)),
         xaxt = "n", xlab = "",
         yaxt = "n", ylab = "Posterior Probability of a Match",
         bty = "n",
         main = "Matching Patterns Ordered by Posterior Probability of Match"
         )
    staxlab(1, 1:length(inds.gamma)-.5, varnames,
            srt = 45, top.line = 0)
    axis(2, yinds-.5, ylabs)
    for(i in 1:nrow(em.ins)){

        for(j in 1:length(inds.gamma)){
            val <- em.ins[i,j]
            c.val <- ifelse(is.na(val), "grey",
                     ifelse(val == 0, cols[3],
                     ifelse(val == 1, cols[2],
                            cols[1])))
            polygon(c(j-1, j, j, j-1),
                    c(i-1, i-1, i, i),
                    col = c.val)
        }  
        
    }
    legend("topright",
           c("Match", "Partial Match", "Non-Match", "NA"),
           pch = rep(22, 4), col = rep("black", 4),
           pt.bg = c(cols[1], cols[2], cols[3], "grey"),
           bty = "n")

}

