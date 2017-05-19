#' emlinkMARmov
#'
#' Expectation-Maximization algorithm for Record Linkage under the
#' Missing at Random (MAR) assumption.
#'
#' @usage emlinkMARmov(patterns, nobs.a, nobs.b, p.m, iter.max,
#' tol, p.gamma.k.m, p.gamma.k.u, prior.lambda, w.lambda,
#' prior.pi, w.pi, address.field, gender.field)
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
#' @param address.field Boolean indicators for whether a given field is an address field. Default is NULL (FALSE for all fields).
#' Address fields should be set to TRUE while non-address fields are set to FALSE if provided.
#' @param gender.field Boolean indicators for whether a given field is for gender. If so, exact match is conducted on gender.
#' Default is NULL (FALSE for all fields). The one gender field should be set to TRUE while all other fields are set to FALSE if provided.
#'
#' @return \code{emlinkMARmov} returns a list with the following components:
#' \item{zeta.j}{The posterior match probabilities for each unique pattern.}
#' \item{p.m}{The posterior probability of a pair matching.}
#' \item{p.u}{The posterior probability of a pair not matching.}
#' \item{p.gamma.k.m}{The posterior of the matching probability for a specific matching field.}
#' \item{p.gamma.k.u}{The posterior of the non-matching probability for a specific matching field.}
#' \item{p.gamma.j.m}{The posterior probability that a pair is in the matched set given a particular agreement pattern.}
#' \item{p.gamma.j.u}{The posterior probability that a pair is in the unmatched set given a particular agreement pattern.}
#' \item{patterns.w}{Counts of the agreement patterns observed, along with the Felligi-Sunter Weights.}
#' \item{iter.converge}{The number of iterations it took the EM algorithm to converge.}
#' \item{nobs.a}{The number of observations in dataset A.}
#' \item{nobs.b}{The number of observations in dataset B.}
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com> and Kosuke Imai
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
#' em <- emlinkMAR(tc, nobs.a = nrow(dfA), nobs.b = nrow(dfB))
#' }
#'
#' @export
#' @importFrom gtools rdirichlet
emlinkMARmov <- function(patterns, nobs.a, nobs.b,
                         p.m = 0.1, iter.max = 5000, tol = 1e-5, p.gamma.k.m = NULL, p.gamma.k.u = NULL,
                         prior.lambda = NULL, w.lambda = NULL, 
                         prior.pi = NULL, w.pi = NULL, address.field = NULL,
                         gender.field = NULL) {

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

        ## Optimal hyperparameters for lambda
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

        ## Optimal hyperparameters for pi
        alpha0 <- c.pi * prior.pi * exp.match + 1
        alpha1 <- alpha0 * (1 - prior.pi) / prior.pi

        if(w.pi == 0){
            alpha0 <- 1
            alpha1 <- 1
        }
    }else{
        alpha0 <- 1
        alpha1 <- 1
        address.field <- rep(FALSE, nfeatures)
    }

    ## Gender match
    if(!is.null(gender.field) & sum(gender.field) == 0){
        gender.field <- NULL
    }
    if(!is.null(gender.field)){
        if(is.null(prior.lambda)){
            stop("If matching on gender, you must specify a prior for lambda.") 
        }
        prior.gen <- 1 - 1e-05
        w.gen <- 1 - 1e-05
        c.gen <- w.gen / (1 - w.gen)
        exp.match <- prior.lambda * nobs.a * nobs.b

        ## Optimal hyperparameters for pi.gender
        alpha1g <- c.gen * prior.gen * exp.match + 1
        alpha0g <- alpha1g * (1 - prior.gen) / (prior.gen)
        
    }else{
        alpha1g <- 1
        alpha0g <- 1
        gender.field <- rep(FALSE, nfeatures)
    }

    ## Overall Prob of finding a Match
    p.u <- 1 - p.m

    ## Field specific probability of observing gamma.k conditional on M
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

        if((count %% 100) == 0) {
            cat("Iteration number", count, "\n")
            cat("Maximum difference in log-likelihood =", round(delta, 4), "\n")
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

            temp.2g <- rep(alpha0g, (length(temp.1) - 1))
            temp.3g <- c(temp.2g, alpha1g)
            for (l in 1:length(temp.1)) {
                p.gamma.k.m[[i]][l] <- (
                    sum(num.prod * ifelse(is.na(gamma.j.k[, i]), 0, 1) * ifelse(is.na(gamma.j.k[, i]), 0, ifelse(gamma.j.k[, i] == temp.1[l], 1, 0))) +
                    address.field[i] * (temp.3[l] - 1) + gender.field[i] * (temp.3g[l] - 1)
                ) / (
                    sum(num.prod * ifelse(is.na(gamma.j.k[, i]), 0, 1)) + (address.field[i] * sum(temp.3 - 1)) + gender.field[i] * sum(temp.3g - 1)
                )
                p.gamma.k.u[[i]][l] <- (
                    sum((n.j - num.prod) * ifelse(is.na(gamma.j.k[, i]), 0, 1) * ifelse(is.na(gamma.j.k[, i]), 0, ifelse(gamma.j.k[, i] == temp.1[l], 1, 0)))
                ) / (
                    sum((n.j - num.prod) * ifelse(is.na(gamma.j.k[, i]), 0, 1))
                )
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
            warning("The EM algorithm has run for the specified number of iterations but has not converged yet.")
            break
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
                   "p.gamma.j.m" = p.gamma.j.m, "p.gamma.j.u" = p.gamma.j.u, "patterns.w" = data.w, "iter.converge" = count,
                   "nobs.a" = nobs.a, "nobs.b" = nobs.b)
    class(output) <- c("fastLink", "fastLink.EM")
    
    return(output)
}

#' emlinkRS
#'
#' Calculates Felligi-Sunter weights and posterior zeta probabilities
#' for matching patterns observed in a larger population that are
#' not present in a sub-sample used to estimate the EM.
#'
#' @usage emlinkRS(patterns.out, em.out, nobs.a, nobs.b)
#'
#' @param patterns.out The output from `tableCounts()` or `emlinkMARmov()` (run on full dataset),
#' containing all observed matching patterns in the full sample and the number of times that pattern
#' is observed.
#' @param em.out The output from `emlinkMARmov()`, an EM object estimated
#' on a smaller random sample to apply to counts from a larger sample
#' @param nobs.a Total number of observations in dataset A
#' @param nobs.b Total number of observations in dataset B
#'
#' @return \code{emlinkMARmov} returns a list with the following components:
#' \item{zeta.j}{The posterior match probabilities for each unique pattern.}
#' \item{p.m}{The posterior probability of a pair matching.}
#' \item{p.u}{The posterior probability of a pair not matching.}
#' \item{p.gamma.k.m}{The posterior of the matching probability for a specific matching field.}
#' \item{p.gamma.k.u}{The posterior of the non-matching probability for a specific matching field.}
#' \item{p.gamma.j.m}{The posterior probability that a pair is in the matched set given a particular agreement pattern.}
#' \item{p.gamma.j.u}{The posterior probability that a pair is in the unmatched set given a particular agreement pattern.}
#' \item{patterns.w}{Counts of the agreement patterns observed, along with the Felligi-Sunter Weights.}
#' \item{iter.converge}{The number of iterations it took the EM algorithm to converge.}
#' \item{nobs.a}{The number of observations in dataset A.}
#' \item{nobs.b}{The number of observations in dataset B.}
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com> and Ben Fifield <benfifield@gmail.com>
#'
#' @examples
#' \dontrun{
#' ## -------------
#' ## Run on subset
#' ## -------------
#' dfA.s <- dfA[sample(1:nrow(dfA), 50),]; dfB.s <- dfB[sample(1:nrow(dfB), 50),]
#' 
#' ## Calculate gammas
#' g1 <- gammaCKpar(dfA.s$firstname, dfB.s$firstname)
#' g2 <- gammaCKpar(dfA.s$middlename, dfB.s$middlename)
#' g3 <- gammaCKpar(dfA.s$lastname, dfB.s$lastname)
#' g4 <- gammaKpar(dfA.s$birthyear, dfB.s$birthyear)
#'
#' ## Run tableCounts
#' tc <- tableCounts(list(g1, g2, g3, g4), nobs.a = nrow(dfA.s), nobs.b = nrow(dfB.s))
#'
#' ## Run EM
#' em <- emlinkMAR(tc, nobs.a = nrow(dfA.s), nobs.b = nrow(dfB.s))
#'
#' ## ------------------
#' ## Apply to full data
#' ## ------------------
#'
#' ## Calculate gammas
#' g1 <- gammaCKpar(dfA$firstname, dfB$firstname)
#' g2 <- gammaCKpar(dfA$middlename, dfB$middlename)
#' g3 <- gammaCKpar(dfA$lastname, dfB$lastname)
#' g4 <- gammaKpar(dfA$birthyear, dfB$birthyear)
#'
#' ## Run tableCounts
#' tc <- tableCounts(list(g1, g2, g3, g4), nobs.a = nrow(dfA), nobs.b = nrow(dfB))
#'
#' em.full <- emlinkRS(tc, em, nrow(dfA), nrow(dfB)
#' }
#'
#' @export
emlinkRS <- function(patterns.out, em.out, nobs.a, nobs.b){
    if("tableCounts" %in% class(patterns.out)){
        patterns.out <- patterns.out
    }else if("fastLink.EM" %in% class(patterns.out)){
        patterns.out <- patterns.out$patterns.w
        inds <- grep("gamma.[[:digit:]]", colnames(patterns.out))
        inds <- c(inds, max(inds)+1)
        patterns.out <- patterns.out[,inds]
    }else{
        stop("Your `patterns.out` object is not a valid tableCounts or emlinkMARmov object.")
    }
    if(!("fastLink.EM" %in% class(em.out))){
        stop("Your `em.out` object is not a valid emlinkMARmov object.")
    }
    options(digits = 16)
    nfeatures <- ncol(patterns.out) - 1
    gamma.j.k <- as.matrix(patterns.out[, 1:nfeatures])
    N <- nrow(gamma.j.k)
    
    p.m <- em.out$p.m
    p.u <- 1 - p.m

    p.gamma.k.m <- em.out$p.gamma.k.m
    p.gamma.k.u <- em.out$p.gamma.k.u

    p.gamma.k.j.m <- matrix(rep(NA, N * nfeatures), nrow = nfeatures, 
                            ncol = N)
    p.gamma.k.j.u <- matrix(rep(NA, N * nfeatures), nrow = nfeatures, 
                            ncol = N)
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
    
    sumlog <- function(x) {
        sum(log(x), na.rm = T)
    }
    
    p.gamma.j.m <- as.matrix((apply(p.gamma.k.j.m, 2, sumlog)))
    p.gamma.j.m <- exp(p.gamma.j.m)
    p.gamma.j.u <- as.matrix((apply(p.gamma.k.j.u, 2, sumlog)))
    p.gamma.j.u <- exp(p.gamma.j.u)
    log.prod <- log(p.gamma.j.m) + log(p.m)
    logxpy <- function(lx, ly) {
        temp <- cbind(lx, ly)
        apply(temp, 1, max) + log1p(exp(-abs(lx - ly)))
    }
    log.sum <- logxpy(log(p.gamma.j.m) + log(p.m), log(p.gamma.j.u) + 
                                                   log(p.u))
    zeta.j <- exp(log.prod - log.sum)

    ## Renormalize
    p.gamma.j.m <- p.gamma.j.m/sum(p.gamma.j.m)
    p.gamma.j.u <- p.gamma.j.u/sum(p.gamma.j.u)
    
    weights <- log(p.gamma.j.m) - log(p.gamma.j.u)
    data.w <- cbind(patterns.out, weights, p.gamma.j.m, p.gamma.j.u)
    nc <- ncol(data.w)
    colnames(data.w)[nc - 3] <- "counts"
    colnames(data.w)[nc - 2] <- "weights"
    colnames(data.w)[nc - 1] <- "p.gamma.j.m"  
    colnames(data.w)[nc] <- "p.gamma.j.u"
    
    output <- list("zeta.j" = zeta.j, "p.m" = em.out$p.m, "p.u" = em.out$p.u, "p.gamma.k.m" = em.out$p.gamma.k.m, "p.gamma.k.u" = em.out$p.gamma.k.u,
                   "p.gamma.j.m" = p.gamma.j.m, "p.gamma.j.u" = p.gamma.j.u, "patterns.w" = data.w, "iter.converge" = em.out$iter.converge,
                   "nobs.a" = nobs.a, "nobs.b" = nobs.b)
    class(output) <- c("fastLink", "fastLink.EM")
    
    return(output)
}
