#' emlinklog
#'
#' Expectation-Maximization algorithm for Record Linkage 
#' allowing for dependencies across linkage fields
#'
#' @usage emlinklog(patterns, nobs.a, nobs.b, p.m, p.gamma.j.m, p.gamma.j.u,
#' iter.max, tol, varnames)
#'
#' @param patterns table that holds the counts for each unique agreement
#' pattern. This object is produced by the function: tableCounts.
#' @param nobs.a Number of observations in dataset A
#' @param nobs.b Number of observations in dataset B
#' @param p.m probability of finding a match. Default is 0.1
#' @param p.gamma.j.m probability that conditional of being in the matched set we observed a specific agreement pattern.
#' @param p.gamma.j.u probability that conditional of being in the non-matched set we observed a specific agreement pattern.
#' @param iter.max Max number of iterations. Default is 5000
#' @param tol Convergence tolerance. Default is 1e-05
#' @param varnames The vector of variable names used for matching. Automatically provided if using \code{fastLink()} wrapper. Used for
#' clean visualization of EM results in summary functions.
#'
#' @return \code{emlinklog} returns a list with the following components:
#' \item{zeta.j}{The posterior match probabilities for each unique pattern.}
#' \item{p.m}{The probability of finding a match.}
#' \item{p.u}{The probability of finding a non-match.}
#' \item{p.gamma.j.m}{The probability of observing a particular agreement pattern conditional on being in the set of matches.}
#' \item{p.gamma.j.u}{The probability of observing a particular agreement pattern conditional on being in the set of non-matches.}
#' \item{patterns.w}{Counts of the agreement patterns observed, along with the Felligi-Sunter Weights.}
#' \item{iter.converge}{The number of iterations it took the EM algorithm to converge.}
#' \item{nobs.a}{The number of observations in dataset A.}
#' \item{nobs.b}{The number of observations in dataset B.}
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com> and Benjamin Fifield
#'
#' @examples
#' \dontrun{
#' ## Calculate gammas
#' g1 <- gammaCKpar(dfA$firstname, dfB$firstname)
#' g2 <- gammaCKpar(dfA$middlename, dfB$middlename)
#' g3 <- gammaCKpar(dfA$lastname, dfB$lastname)
#' g4 <- gammaKpar(dfA$birthyear, dfB$birthyear)
#'
#' ## Run tableCounts
#' tc <- tableCounts(list(g1, g2, g3, g4), nobs.a = nrow(dfA), nobs.b = nrow(dfB))
#'
#' ## Run EM
#' em.log <- emlinklog(tc, nobs.a = nrow(dfA), nobs.b = nrow(dfB))
#' }
#'
#' @export
#' @importFrom gtools rdirichlet
#' @importFrom stats glm model.matrix
emlinklog <- function(patterns, nobs.a, nobs.b,
                      p.m = 0.1, p.gamma.j.m = NULL, p.gamma.j.u = NULL, iter.max = 5000, tol = 1e-5, varnames = NULL) {

    ## OPTIONS  
    ## patterns <- tc; nobs.a <- nrow(dfA); nobs.a <- nrow(dfB); p.m <- 0.1; iter.max = 5000; 
    ## tol = 1e-5; p.gamma.k.m = NULL; p.gamma.k.u = NULL

    options(digits=16)
    
    ## EM Algorithm for a Fellegi-Sunter model that accounts for missing data (under MAR)
    ##
    ## Args:
    ##   patterns:
    ##   p.m:
    ##   p.gamma.k.m:
    ##   p.gamma.k.u:
    ##   tol:
    ##
    ## Returns:
    ##   The p.m, p.gamma.k.m, p.gamma.k.u, p.gamma.k.m, p.gamma.k.m, p.gamma.k.m, that
    ##   maximize the observed data log-likelihood of the agreement patterns

    ## Edge case
    if(is.null(nrow(patterns))){
        patterns <- as.data.frame(t(as.matrix(patterns)))
    }
    
    ## Number of fields
    nfeatures <- ncol(patterns) - 1
    
    ## Patterns:
    gamma.j.k <- as.matrix(patterns[, 1:nfeatures])

    ## Patterns counts:
    n.j <- as.matrix(patterns[, (nfeatures + 1)])  # Counts
    
    ## Number of unique patterns:
    N <- nrow(gamma.j.k)
    
    p.gamma.k.m <- p.gamma.k.u <- NULL
    
    ## Overall Prob of finding a Match
    p.u <- 1 - p.m
    
    ## Field specific probability of observing gamma.k conditional on M
    if (is.null(p.gamma.k.m)) {
        p.gamma.k.m <- list()
        for (i in 1:nfeatures) {
            l.m <- length(unique(na.omit(gamma.j.k[, i])))
            c.m <- seq(from = 1, to = 50 * l.m, by = 50)
            p.gamma.k.m[[i]] <- sort(rdirichlet(1, c.m), decreasing = FALSE)
        }
    }

    ## Field specific probability of observing gamma.k conditional on U
    if (is.null(p.gamma.k.u)) {
        p.gamma.k.u <- list()
        for (i in 1:nfeatures) {
            l.u <- length(unique(na.omit(gamma.j.k[, i])))
            c.u <- seq(from = 1, to = 50 * l.u, by = 50)
            p.gamma.k.u[[i]] <- sort(rdirichlet(1, c.u), decreasing = TRUE)
        }
    }
    
    p.gamma.k.j.m <- matrix(rep(NA, N * nfeatures), nrow = nfeatures, ncol = N)
    p.gamma.k.j.u <- matrix(rep(NA, N * nfeatures), nrow = nfeatures, ncol = N)
    
    p.gamma.j.m <- matrix(rep(NA, N), nrow = N, ncol = 1)
    p.gamma.j.u <- matrix(rep(NA, N), nrow = N, ncol = 1)
    
    for (i in 1:nfeatures) {
        temp.01 <- temp.02 <- gamma.j.k[, i]
        temp.1 <- unique(na.omit(temp.01))
        temp.2 <- p.gamma.k.m[[i]]
        temp.3 <- p.gamma.k.u[[i]]
        for (j in 1:length(temp.1)) {
            temp.01[temp.01 == temp.1[j]] <- temp.2[j]
            temp.02[temp.02 == temp.1[j]] <- temp.3[j]
        }
        p.gamma.k.j.m[i, ] <- temp.01
        p.gamma.k.j.u[i, ] <- temp.02
    }
    
    sumlog <- function(x) { sum(log(x), na.rm = T) }
    
    p.gamma.j.m <- as.matrix((apply(p.gamma.k.j.m, 2, sumlog)))
    p.gamma.j.m <- exp(p.gamma.j.m)
    
    p.gamma.j.u <- as.matrix((apply(p.gamma.k.j.u, 2, sumlog)))
    p.gamma.j.u <- exp(p.gamma.j.u)

    delta <- 1
    count <- 1
    warn.once <- 1
    
    ## The EM Algorithm presented in the paper starts here:
    while (abs(delta) >= tol) {
        
        if((count %% 100) == 0) {
            cat("Iteration number", count, "\n")
            cat("Maximum difference in log-likelihood =", round(delta, 4), "\n")
        }
        
        ## Old Paramters
        p.old <- c(p.m, p.u, unlist(p.gamma.j.m), unlist(p.gamma.j.u))

        ## ------
        ## E-Step:
        ## ------
        
        log.prod <- log(p.gamma.j.m) + log(p.m)
        max.log.prod <- max(log.prod)
        
        logxpy <- function(lx,ly) {
            temp <- cbind(lx, ly)
            apply(temp, 1, max) + log1p(exp(-abs(lx-ly)))
        }
        
        log.sum <- logxpy(log(p.gamma.j.m) + log(p.m), log(p.gamma.j.u) + log(p.u))
        zeta.j <- exp(log.prod - max.log.prod)/(exp(log.sum - max.log.prod))
        
        ## --------
        ## M-step :
        ## --------
        num.prod <- n.j * zeta.j
        p.m <- sum(num.prod)/sum(n.j)
        p.u <- 1 - p.m
        

        pat <- data.frame(gamma.j.k)
        pat[is.na(pat)] <- -1
        pat <- replace(pat, TRUE, lapply(pat, factor))
        factors <- model.matrix(~ ., pat)
        
        ## get theta.m and theta.u
        c <- 1e-06
        matches <- glm(count ~ ., data = data.frame(count = ((zeta.j * n.j) + c), factors),
                       family = "quasipoisson")

        non.matches <- glm(count ~ .*., data = data.frame(count = ((1 - zeta.j) * n.j + c), factors),
                           family = "quasipoisson")
        
        ## Predict & renormalization fn as in Murray 2017
        g <- function(fit) {
            logwt = predict( fit )
            logwt = logwt - max(logwt)
            wt = exp(logwt)
            wt/sum(wt)
        }

        p.gamma.j.m = as.matrix(g(matches))
        p.gamma.j.u = as.matrix(g(non.matches))

        ## Updated parameters:
        p.new <- c(p.m, p.u, unlist(p.gamma.j.m), unlist(p.gamma.j.u))
        
        if(p.m < 1e-13 & warn.once == 1) {
            warning("The overall probability of finding a match is too small. Increasing the amount of overlap between the datasets might help, see e.g., clusterMatch()")
            warn.once <- 0
        }
        
        ## Max difference between the updated and old parameters:
        delta <- max(abs(p.new - p.old))
        count <- count + 1
        
        if(count > iter.max) {
            warning("The EM algorithm has run for the specified number of iterations but has not converged yet.")
            break
        }
    }
    
    weights <- log(p.gamma.j.m) - log(p.gamma.j.u)
    
    data.w <- cbind(patterns, weights, p.gamma.j.m, p.gamma.j.u)
    nc <- ncol(data.w)
    colnames(data.w)[nc-2] <- "weights"
    colnames(data.w)[nc-1] <- "p.gamma.j.m"
    colnames(data.w)[nc] <- "p.gamma.j.u"
    
    inf <- which(data.w == Inf, arr.ind = T)
    ninf <- which(data.w == -Inf, arr.ind = T)
    
    data.w[inf[, 1], unique(inf[, 2])] <- 150
    data.w[ninf[, 1], unique(ninf[, 2])] <- -150

    if(!is.null(varnames)){
        output <- list("zeta.j"= zeta.j,"p.m"= p.m, "p.u" = p.u, 
                       "p.gamma.j.m" = p.gamma.j.m, "p.gamma.j.u" = p.gamma.j.u, "patterns.w" = data.w, "iter.converge" = count,
                       "nobs.a" = nobs.a, "nobs.b" = nobs.b, "varnames" = varnames)
    }else{
        output <- list("zeta.j"= zeta.j,"p.m"= p.m, "p.u" = p.u, 
                       "p.gamma.j.m" = p.gamma.j.m, "p.gamma.j.u" = p.gamma.j.u, "patterns.w" = data.w, "iter.converge" = count,
                       "nobs.a" = nobs.a, "nobs.b" = nobs.b, "varnames" = paste0("gamma.", 1:nfeatures))
    }

    
    class(output) <- c("fastLink", "fastLink.EM")
    
    return(output)
}
