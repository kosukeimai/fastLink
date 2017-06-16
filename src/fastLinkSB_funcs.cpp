// [[Rcpp::depends(RcppArmadillo)]]
#include <RcppArmadillo.h>
#include <RcppArmadilloExtensions/sample.h>


// sample index
// [[Rcpp::export]]
std::vector<arma::ivec> sample_index(const int nA, const int nB) {
    std::vector<arma::ivec> idx;

    // Rcpp::IntegerVector seq_nA = Rcpp::seq_len(nB);
    // Rcpp::IntegerVector seq_nB = Rcpp::seq_len(nA);
    arma::vec seq_nA = arma::linspace<arma::vec>(0, nB-1, nB);
    arma::vec seq_nB = arma::linspace<arma::vec>(0, nA-1, nA);
    
    // output
    arma::ivec nA_pair(nA); // index of B!
    arma::ivec nB_pair(nB); // index of A!

    // Rcpp::Rcout << "nA: " << seq_nA << "\n";
    // sample pair for nA
    for (int i = 0; i < nA; i++) {
        nA_pair(i) = Rcpp::RcppArmadillo::sample(Rcpp::as<Rcpp::IntegerVector>(Rcpp::wrap(seq_nA)), 1, true)[0];
    }

    idx.push_back(nA_pair);

    // sample pair for nB
    for (int j = 0; j < nB; j++) {
        nB_pair(j) = Rcpp::RcppArmadillo::sample(Rcpp::as<Rcpp::IntegerVector>(Rcpp::wrap(seq_nB)), 1, true)[0];
    }

    idx.push_back(nB_pair);

    return idx;
}

// update lambda 
// [[Rcpp::export]]
arma::mat update_lambda_svb(
    // const arma::vec &pattern_vec,   // pattern vector nA + nB length
    // const arma::mat &pattern,       // pattern mat: [#unique pattern] x [K]
    const arma::vec &nA_pair,       // pair for A: B's index
    const arma::vec &nB_pair,       // pair for B: A's index
    const arma::vec &Lk,
    const arma::vec &lambda_old,    // lambda param one step before
    const arma::mat &psiA,
    const arma::mat &psiB,
    const arma::vec &phi,
    const double alphaL,
    const double betaL,
    const int nA,
    const int nB,
    const int iter,
    const double a_step,
    const double b_step,
    const double kappa_step) {

    const double nAB = static_cast<double>(nA * nB);
    const int n_pairs = nA + nB;

    arma::mat n_grad1(n_pairs, maxQ);
    arma::mat n_grad0(n_pairs, maxQ);

    // ================================ //
    // compute natural gradient
    // ================================ //
    int i = 0; int j = 0;
    for (int count = 0; count < n_pairs; count++) {
        if (count < nA) {
            // count = 1, ..., nA
            for (int z = 0; z < maxQ; z++) {
                n_grad1(count, z) = alphaL + nAB * psiA(i, z) * psiB(nA_pair(i), z) * phi(count); 
                n_grad0(count, z) = betaL  + nAB * psiA(i, z) * psiB(nA_pair(i), z) * (1.0 - phi(count));
            }
            ++i;
        } else {
            // count = nA + 1, ..., nA + nB
            for (int z = 0; z < maxQ; z++) {
                n_grad1(count, z) = alphaL + nAB * psiA(nB_pair(j), z) * psiB(j, z) * phi(count); 
                n_grad0(count, z) = betaL  + nAB * psiA(nB_pair(j), z) * psiB(j, z) * (1.0 - phi(count));
            }
            ++j;
        }
    }

    // ================================ //
    // Update Lambda
    // ================================ //
    arma::mat lambda(maxQ, 2);
    double rho_t = a_step / pow((b_step + static_cast<double>(iter)), kappa_step);

    for (int z = 0; z < maxQ; z++) {
        // average n_grad
        lambda(z, 0) = (1.0 - rho_t) * lambda_old(z, 0) + rho_t * (sum(n_grad0.col(z)) / n_pairs);
        lambda(z, 1) = (1.0 - rho_t) * lambda_old(z, 1) + rho_t * (sum(n_grad1.col(z)) / n_pairs);
    }

    return lambda;
}

// update theta
// [[Rcpp::export]]
arma::vec update_theta_svb(
    const arma::vec &nA_pair,       // pair for A: B's index
    const arma::vec &nB_pair,       // pair for B: A's index
    const arma::mat &psiA,
    const arma::mat &psiB,
    const arma::vec &theta_old,
    const double theta_prior,
    const int maxQ,
    const int nA,
    const int nB,
    const int iter,
    const double a_step,
    const double b_step,
    const double kappa_step) {


    const int n_pairs = nA + nB;
    arma::mat n_grad(n_pairs, maxQ);

    // ================================ //
    // compute natural gradient
    // ================================ //
    int i = 0; int j = 0;
    for (int count = 0; count < n_pairs; count++) {
        if (count < nA) {
            // count = 0, ..., nA
            for (int z = 0; z < maxQ; z++) {
                n_grad(count, z) = nA * psiA(i, z) + nB * psiB(nA_pair(i), z) + theta_prior;
            }
            i += 1;
        } else {
            // count = nA + 1, ..., nA + nB
            for (int z = 0; z < maxQ; z++) {
                n_grad(count, z) = nA * psiA(nB_pair(j), z) + nB * psiB(j, z) + theta_prior;
            }            
            j += 1;
        }     
    }

    // compute step
    double rho_t = a_step / pow((b_step + static_cast<double>(iter)), kappa_step);

    // ================================ //
    // average gradient 
    // update theta
    // ================================ //
    arma::vec ave_n_grad(n_pairs);
    arma::vec theta(maxQ);
    for (int z = 0; z < maxQ; z++) {
        // average gradient
        ave_n_grad(z) = sum(n_grad.col(z)) / n_pairs;

        // update 
        theta(z) = (1.0 - rho_t) * theta_old(z) + rho_t * ave_n_grad(z);
    }

    return theta;
}

// update psiA
// arma::mat update_psiA_svb(
//     const arma::vec &pattern_vec,   // stack from 1,...,nA, nA+1,...,nA+nB        
//     const arma::vec &nA_pair,       // pair for A: B's index
//     const arma::vec &phi,           // [nA + nB] x 1
//     const arma::mat &psiB,          // nB x max_block(Q)
//     const arma::mat &lambda,
//     const int nA,
//     const int maxQ) {

//     arma::mat psiA(nA, maxQ);

//     // all i
//     for (int i = 0; i < nA; i++) {
//         int Ji = nA_pair(i);
//         phi(i)
//         (1.0 - phi(i))

//         for (z = 0; z < maxQ; z++) {
//             psiA(i, z)
//         }

//         psiA.row(i) = psiA.row(i) / sum(psiA.row(i));
//     }

//     return psiA;
// }



// arma::mat update_phi_svb(
//     const arma::mat &psiA,
//     const arma::mat &psiB,
//     ) {


// }


