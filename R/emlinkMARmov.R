#' emlinkMARmov
#'
#' Expectation-Maximization algorithm for Record Linkage under the
#' Missing at Random (MAR) assumption.
#'
#' @param patterns table that holds the counts for each unique agreement
#' pattern. This object is produced by the function: tableCounts.
#'
#' @param p.m probability of finding a match
#' @param nobs.a Number of observations in dataset A
#' @param nobs.b Number of observations in dataset B
#' @param p.gamma.k.m probability that conditional of being in the matched set we observed a specific agreement value for field k.
#' @param p.gamma.k.u probability that conditional of being in the non-matched set we observed a specific agreement value for field k.
#' @param tol convergence tolerance
#' @param iter.max Max Number of Iterations (5000 by default)
#' @param address_field Binary indicators for whether a given field is an address field. To be used when 'alpha0' and 'alpha1' are specified.
#' Default is 0 for all fields. Address fields should be set to 1 while non-address fields are set to 0.
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
        mu <- prior.lambda * c.lambda * nobs.a * nobs.b + 1
        psi <- (1 - prior.lambda) * mu / prior.lambda
        if(w.lambda == 0){
            psi <- 1
            mu <- 1
        }
    }else{
        psi <- 1
        mu <- 1
    }

    ## ## alpha0, alpha1
    ## if(adaptive.pi){
    ##     c.pi <- w.pi / (1 - w.pi)
    ## }else{
    ##     alpha0 <- 1
    ##     alpha1 <- 1
    ##     address_field <- rep(FALSE, nfeatures)
    ## }

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

        ## ## Update alphas
        ## if(adaptive.pi){
        ##     k <- min(which(address_field == TRUE))
        ##     s <- sum(num.prod * ifelse(is.na(gamma.j.k[, k]), 0, 1) * ifelse(is.na(gamma.j.k[, k]), 0, ifelse(gamma.j.k[, k] == 0, 1, 0)))
        ##     alpha1 <- (c.pi * s * prior.pi - prior.pi + 1) / ((l.address - 1) * prior.pi)
        ##     alpha0 <- ((l.address - 1) * alpha1 * prior.pi) / (1 - prior.pi)
        ## }

        for (i in 1:nfeatures) {
            temp.01 <- temp.02 <- gamma.j.k[, i]
            temp.1 <- unique(na.omit(temp.01))
            temp.2 <- rep(alpha1, (length(temp.1) - 1))
            temp.3 <- c(alpha0, temp.2)
            for (l in 1:length(temp.1)) {
                p.gamma.k.m[[i]][l] <- (sum(num.prod * ifelse(is.na(gamma.j.k[, i]), 0, 1) * ifelse(is.na(gamma.j.k[, i]), 0, ifelse(gamma.j.k[, i] == temp.1[l], 1, 0))) + address_field[i] * (temp.3[l] - 1))/ (sum(num.prod * ifelse(is.na(gamma.j.k[, i]), 0, 1)) + (address_field[i]  * sum(temp.3 - 1)))
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

    output<-list("zeta.j"= zeta.j,"p.m"= p.m, "p.u" = p.u, "p.gamma.k.m" = p.gamma.k.m, "p.gamma.k.u" = p.gamma.k.u,
                 "p.gamma.j.m" = p.gamma.j.m, "p.gamma.j.u" = p.gamma.j.u, "patterns.w" = data.w, "count" = count)
    return(output)
}

