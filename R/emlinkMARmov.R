#' emlinkMARmov
#'
#' Expectation-Maximization algorithm for Record Linkage under the
#' Missing at Random (MAR) assumption.
#'
#' @param patterns table that holds the counts for each unique agreement
#' pattern. This object is produced by the function: tableCounts.
#' @param nobs.a Number of observations in dataset A
#' @param nobs.b Number of observations in dataset B
#' @param p.m probability of finding a match. Default is 0.1
#' @param iter.max Max number of iterations. Default is 5000
#' @param tol Convergence tolerance. Default is 1e-05
#' @param p.gamma.k.m probability that conditional of being in the matched set we observed a specific agreement value for field k.
#' @param p.gamma.k.u probability that conditional of being in the non-matched set we observed a specific agreement value for field k.
#' @param prior.lambda The prior probability of finding a match, derived from auxiliary data.
#' @param w.lambda How much weight to give the prior on lambda versus the data. Must range between 0 (no weight on prior) and 1 (weight fully on prior)
#' @param prior.pi The prior probability of the address field not matching, conditional on being in the matched set. To be used when the
#' share of movers in the population is known with some certainty.
#' @param w.pi How much weight to give the prior on pi versus the data. Must range between 0 (no weight on prior) and 1 (weight fully on prior)
#' @param address.field Boolean indicators for whether a given field is an address field. Default is FALSE for all fields.
#' Address fields should be set to TRUE while non-address fields are set to FALSE.
#' @param l.address The number of possible matching categories used for address fields. If a binary yes/no match, \code{l.address} = 2,
#' while if a partial match category is included, \code{l.address} = 3
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com> and Kosuke Imai
#'
#' @export
emlinkMARmov <- function(patterns, nobs.a, nobs.b,
                         p.m = 0.1, iter.max = 5000, tol = 1e-5, p.gamma.k.m = NULL, p.gamma.k.u = NULL,
                         prior.lambda = NULL, w.lambda = NULL, 
                         prior.pi = NULL, w.pi = NULL, address.field = NULL, l.address = NULL) {

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

    ## Number of fields
    nfeatures <- ncol(patterns) - 1

    ## Patterns:
    gamma.j.k <- as.matrix(patterns[, 1:nfeatures])

    ## Patterns counts:
    n.j <- as.matrix(patterns[, (nfeatures + 1)]) # Counts

    ## Number of unique patterns:
    N <- nrow(gamma.j.k)

    ## Starting values if not provided by the user
    ## mu, psi
    if(!is.null(prior.lambda)){
        if(is.null(w.lambda)){
            stop("If providing a prior for lambda, please specify the weight using `w.lambda`.")
        }
        if(w.lambda < 0 | w.lambda > 1){
            stop("w.lambda must be between 0 and 1.")
        }
        if(w.lambda == 1){
            w.lambda <- 1 - 1e-05
        }
        c.lambda <- w.lambda / (1 - w.lambda)

        ## THESE ARE ORIGINAL EXPRESSIONS
        mu <- prior.lambda * c.lambda * nobs.a * nobs.b + 1
        psi <- (1 - prior.lambda) * mu / prior.lambda
        ## THESE ARE ORIGINAL EXPRESSIONS

        ## THESE ARE DENOM-MATCHING EXPRESSIONS
        ## mu <- prior.lambda * c.lambda^2 * nobs.a * nobs.b / (1 - 2 * prior.lambda)
        ## psi <- mu * (1 - prior.lambda) / prior.lambda
        ## THESE ARE DENOM-MATCHING EXPRESSIONS

        ## d <- ((psi - mu) / (nobs.a * nobs.b) + 1)
        ## w1 <- 1 / d
        ## w2 <- (((mu - 1) * (mu + psi)) / (mu * nobs.a * nobs.b)) / d
        ## cat("Sum of the weights =", w1 + w2, "\n")
        ## cat("mu =", mu, "\n")
        ## cat("psi =", psi, "\n")
        
        if(w.lambda == 0){
            psi <- 1
            mu <- 1
        }
    }else{
        psi <- 1
        mu <- 1
    }

    ## alpha0, alpha1
    if(!is.null(prior.pi)){
        if(is.null(prior.lambda)){
            stop("If providing a prior on pi, you must specify a prior for lambda as well.") 
        }
        if(is.null(w.pi)){
            stop("If providing a prior for pi, please specify the weight using `w.pi`.")
        }
        if(w.pi < 0 | w.pi > 1){
            stop("w.pi must be between 0 and 1.")
        }
        if(w.pi == 1){
            w.pi <- 1 - 1e-05
        }
        c.pi <- w.pi / (1 - w.pi)
        exp.match <- prior.lambda * nobs.a * nobs.b

        ## THESE ARE THE ORIGINAL EXPRESSIONS
        alpha0 <- c.pi * prior.pi * exp.match
        alpha1 <- alpha0 * (1 - prior.pi) / (prior.pi * (l.address - 1))
        ## THESE ARE THE ORIGINAL EXPRESSIONS

        ## THESE ARE THE DENOMINATOR-MATCHING EXPRESSIONS
        ## alpha1 <- (c.pi^2 * S + l.address) / (l.address - 1)
        ## alpha0 <- prior.pi * (l.address - 1) * alpha1 / (1 - prior.pi)
        ## THESE ARE THE DENOMINATOR-MATCHING EXPRESSIONS

        ## d <- 1 + ((alpha0 - 1) + (l.address - 1) * (alpha1 - 1)) / exp.match
        
        ## w1 <- 1 / d
        ## w2 <- (((alpha0 - 1) * ((alpha0 - 1) + (l.address - 1) * (alpha1 - 1))) / (alpha0 * exp.match)) / d
        ## cat("Sum of the weights =", w1 + w2, "\n")
        ## cat("Expected number of matches =", prior.lambda * nobs.a * nobs.b, "\n")
        
        ## cat("c =", c.pi, "\n")
        ## cat("specified prior =", prior.pi, "\n")
        ## cat("estimated prior =", alpha0 / (alpha0 + (l.address - 1) * alpha1), "\n")
        ## cat("alpha0 =", alpha0, "\n")
        ## cat("alpha1 =", alpha1, "\n")
        if(w.pi == 0){
            alpha0 <- 1
            alpha1 <- 1
        }
    }else{
        alpha0 <- 1
        alpha1 <- 1
        address.field <- rep(FALSE, nfeatures)
    }

    ## Overall Prob of finding a Match
    p.u <- 1 - p.m

    ## Field specific probability of observing gamma.k conditional on M
    suppressMessages(require('gtools'))

    if (is.null(p.gamma.k.m)) {
        p.gamma.k.m <- list()
        for (i in 1:nfeatures) {
            if(length(unique(na.omit(gamma.j.k[, i]))) == 3){
                p.gamma.k.m[[i]] <-  sort(rdirichlet(1, c(1, 50, 100)), decreasing = FALSE)
            }

            if(length(unique(na.omit(gamma.j.k[, i]))) == 2){
                p.gamma.k.m[[i]] <-  sort(rdirichlet(1, c(1, 10000)), decreasing = FALSE)
            }

            if(length(unique(na.omit(gamma.j.k[, i]))) == 1){
                p.gamma.k.m[[i]] <-  sort(rdirichlet(1, c(1)), decreasing = FALSE)
            }
        }
    }

    ## Field specific probability of observing gamma.k conditional on U
    if (is.null(p.gamma.k.u)) {
        p.gamma.k.u <- list()
        for (i in 1:nfeatures) {
            if(length(unique(na.omit(gamma.j.k[, i]))) == 3){
                p.gamma.k.u[[i]] <-  sort(rdirichlet(1, c(1, 50, 100)), decreasing = TRUE)
            }

            if(length(unique(na.omit(gamma.j.k[, i]))) == 2){
                p.gamma.k.u[[i]] <-  sort(rdirichlet(1, c(1, 10000)), decreasing = TRUE)
            }

            if(length(unique(na.omit(gamma.j.k[, i]))) == 1){
                p.gamma.k.u[[i]] <-  sort(rdirichlet(1, c(1)), decreasing = TRUE)
            }
        }
    }

    p.gamma.k.j.m <- matrix(rep(NA, N * nfeatures), nrow = nfeatures, ncol = N)
    p.gamma.k.j.u <- matrix(rep(NA, N * nfeatures), nrow = nfeatures, ncol = N)

    p.gamma.j.m <- matrix(rep(NA, N), nrow = N, ncol = 1)
    p.gamma.j.u <- matrix(rep(NA, N), nrow = N, ncol = 1)

    delta <- 1
    count <- 1

    ## The EM Algorithm presented in the paper starts here:
    while (abs(delta) >= tol) {

        if((count %% 10) == 0) {
            cat("Iteration number", count, "\n")
            cat("Maximum difference in log-likelihood =", delta, "\n")
        }

        ## Old Paramters
        p.old <- c(p.m, p.u, unlist(p.gamma.k.m), unlist(p.gamma.k.u))

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

        ## ------
        ## E-Step:
        ## ------
        log.prod <- log(p.gamma.j.m) + log(p.m)

        logxpy <- function(lx,ly) {
            temp <- cbind(lx, ly)
            apply(temp, 1, max) + log1p(exp(-abs(lx-ly)))
        }

        log.sum <- logxpy(log(p.gamma.j.m) + log(p.m), log(p.gamma.j.u) + log(p.u))
        zeta.j <- exp(log.prod - log.sum)
        
        ## --------
        ## M-step :
        ## --------
        num.prod <- exp(log(n.j) + log(zeta.j))
        l.p.m <- log(sum(num.prod) + mu - 1) - log(psi - mu + sum(n.j))
        p.m <- exp(l.p.m)
        p.u <- 1 - p.m

        for (i in 1:nfeatures) {
            temp.01 <- temp.02 <- gamma.j.k[, i]
            temp.1 <- unique(na.omit(temp.01))
            temp.2 <- rep(alpha1, (length(temp.1) - 1))
            temp.3 <- c(alpha0, temp.2)
            for (l in 1:length(temp.1)) {
                p.gamma.k.m[[i]][l] <- (sum(num.prod * ifelse(is.na(gamma.j.k[, i]), 0, 1) * ifelse(is.na(gamma.j.k[, i]), 0, ifelse(gamma.j.k[, i] == temp.1[l], 1, 0))) + address.field[i] * (temp.3[l] - 1))/ (sum(num.prod * ifelse(is.na(gamma.j.k[, i]), 0, 1)) + (address.field[i]  * sum(temp.3 - 1)))
                p.gamma.k.u[[i]][l] <- sum((n.j - num.prod) * ifelse(is.na(gamma.j.k[, i]), 0, 1) * ifelse(is.na(gamma.j.k[, i]), 0, ifelse(gamma.j.k[, i] == temp.1[l], 1, 0)))/sum((n.j - num.prod) * ifelse(is.na(gamma.j.k[, i]), 0, 1))
            }
        }

        for (i in 1:nfeatures) {
            p.gamma.k.m[[i]] <- sort(p.gamma.k.m[[i]], decreasing = F)
            p.gamma.k.u[[i]] <- sort(p.gamma.k.u[[i]], decreasing = T)
        }

        ## Updated parameters:
        p.new <- c(p.m, p.u, unlist(p.gamma.k.m), unlist(p.gamma.k.u))

        ## Max difference between the updated and old parameters:
        delta <- max(abs(p.new - p.old))
        count <- count + 1

        if(count > iter.max) {
            delta <- 1e-9
        }
    }

    p.gamma.j.m <- p.gamma.j.m/sum(p.gamma.j.m)
    p.gamma.j.u <- p.gamma.j.u/sum(p.gamma.j.u)

    weights <- log(p.gamma.j.m) - log(p.gamma.j.u)

    data.w <- cbind(patterns, weights, p.gamma.j.m, p.gamma.j.u)
    nc <- ncol(data.w)
    colnames(data.w)[nc-2] <- "weights"
    colnames(data.w)[nc-1] <- "p.gamma.j.m"
    colnames(data.w)[nc] <- "p.gamma.j.u"

    output <- list("zeta.j"= zeta.j,"p.m"= p.m, "p.u" = p.u, "p.gamma.k.m" = p.gamma.k.m, "p.gamma.k.u" = p.gamma.k.u,
                   "p.gamma.j.m" = p.gamma.j.m, "p.gamma.j.u" = p.gamma.j.u, "patterns.w" = data.w, "count" = count)
    return(output)
}

