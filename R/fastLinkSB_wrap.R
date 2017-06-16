
## ************************************ ##
## Wrapper function to implement        ##
##  Stochastic Blocking Fellegi-Sunter  ##
## ************************************ ##


# fastLinkSB
# 
# @description Fast implementation of Record Linkage with stochastic blocking.
# @details
#  This function implements Stochastic Blocking Fellegi-Sunter Model (SBFS) using 
#  using stochastic Variational Inference.
# @seealso \code{\link{fastLink}} for fast implementation of Fellegi-Sunter model.
# @author Soichiro Yamauchi \email{syamauchi@princeton.edu}
# 
# fastLinkSB <- function(dfA, dfB 
#     # varnames, stringdist.match,
#     #  partial.match, stringdist.method, cut.a, cut.p, jw.weight,
#     #  priors.obj, w.lambda, w.pi,
#     #  address.field, gender.field, estimate.only, em.obj,
#     #  dedupe.matches, linprog.dedupe,
#     #  reweight.names, firstname.field,
#     #  return.df, n.cores, tol.em, threshold.match, verbose
#     ) {


#     ## running EM
#     x <- 1
#     return(x)
# }


#' svblinkSB
#' 
#' @description Stochastic Variational Inference for Record Linkage with Stochastic Blocking.
#' @details
#'  This function implements stochastic variational inference (with mini-batch) for parameter estimation 
#'  for Stochastic Blocking Fellegi-Sunter Model (SBFS).
#' @seealso \code{\link{fastLink}} for fast implementation of Fellegi-Sunter model,
#'  and \code{\link{fastLinkSB}} for the full procedure.
#' @author Soichiro Yamauchi \email{syamauchi@princeton.edu}
#' 
#' 
#' @export
svblinkSB <- function(dfA, dfB, nA, nB, n_block, tol, Lk, iter.max) {
    # ------------------ #
    # Getting info
    # ------------------ #
    # df_all <- rbind(dfA, dfB) # replace this with dplyr


    # initialization
    rand_idx <- sample_index(nA, nB)
    pair_keep <- Matrix::Matrix(0, nrow = nA, ncol = nB, sparse = TRUE) # matrix to keep existing pairs 
    pair_rec  <- Matrix::Matrix(0, nrow = nA, ncol = nB, sparse = TRUE) # matrix to keep patterns
    
    # parameter holder 
    psiA <- matrix(NA, nrow = nA, ncol = n_block) # this is necessary for block assignment
    psiB <- matrix(NA, nrow = nB, ncol = n_block) # this is necessary for block assignment
    phi  <- rep(NA, nA + nB)
    lambda <- matrix(NA, nrow = n_block, ncol = 2)
    theta  <- rep(NA, n_block)
    
    count <- 1
    # Running SBV
    for (s in 1:iter.max) {
        # --------------------------------------------------------- #
        # Random sample: 
        #   1. sample index for each i \in [nA] from 1:nB -> (i, Ji) 
        #   2. sample index for each j \in [nB] from 1:nA -> (Ij, j)
        #   3. make a set of pairs F = {(i, Ji), (Ij, j)} \forall i,j
        #   4. compute agreement vector (if not computed befor) for F
        # --------------------------------------------------------- #
        
        # sample index (step 1 & 2)
        rand_idx <- sample_index(nA, nB) # total pair should be nA + nB
        nA_pair <- rand_idx[[1]]    # (i, Ji) --> index is for B
        nB_pair <- rand_idx[[2]]    # (Ij, j) --> index is for A

        # dfA_sub <- dfA[rand_idx[[2]],] # index is define for pair; for A - indx of B
        # dfB_sub <- dfB[rand_idx[[1]],] # index is define for pair; for B - indx of A
        # df_sub <- cbind(dfB_sub, dfA_sub)


        # compute agreement for the pair
        n_pairs <- nA + nB
        for (i in 1:nA) {
            if (pair_keep[i, nA_pair[i]] == 0) {
                ## compute agreement vector for (i, Ji)


                ## update record
                pair_keep[i, nA_pair[i]] <- 1
            }
        }

        for (j in 1:nB) {
            if (pair_keep[nB_pair[j], j] == 0) {
                ## compute agreement vector for (Ij, j)

                ## update record
                pair_keep[nB_pair[j], j] <- 1
            }
        }

        # --------------------------------------------------------- #
        # Estimate parameter:
        # 1. E-step update local parameters {psiA, psiB, phi}
        #     1.1 psiA[nA, max_block]: block assignment probability
        #     1.2 phi[nA + nB]: prob for march of pairs in F
        # 2. M-spte update global (variational) parameters for {theta, piK, lambda}
        #     2.1 zeta_theta: dirichlet params for block simplex
        #     2.2 zeta_pik: dirihlet pram for agreement vector simple
        #     2.3 zeta_lambda: beta param for matching prob for a given pair
        # --------------------------------------------------------- #
        # "E-step"
        # psiA <- update_psiA_svb
        # psiB <- update_psiB_svb
        # phi  <- 

        # "M-step"
        theta  <- update_theta_svb(nA_pair, nB_pair, psiA, psiB, 
                                   theta_old, theta_prior, maxQ, nA, nB, 
                                   iter, a_step, b_step, kappa_step)
        lambda <- update_lambda_svb(pattern_vec, pattern, nA_pair, nB_pair, Lk,
                                    lambda_old, psiA, psiB, phi, alphaL, betaL,
                                    nA, nB, iter, a_step, b_step, kappa_step)        
        # pi_K   <- 
        # --------------------------------------------------------- #
        # convergence diagnostic:
        #   1. Compute ELBO (too constly)
        #   2. Compute held out log-likelihood (for which data?)
        # --------------------------------------------------------- #
        # evaluate criterion function


        # terminate the algorithm if converged
        if (elbo_diff > tol ) {
            cat('Algorithm converged!\n')
            break
        }

        count <- count + 1
        if (count > iter.max) {
            cat("Algorithm run for the maximum iteration but did not converge.\n")
        }
    }


    out <- list()
    class(out) <- "svblinkSB" 
    return(out)
}





