context("Tests the lambda M-step under prior.lambda.")

## Dense block: 2,000 pairs, true lambda 0.6, three binary fields.
set.seed(1)
N <- 2000
match <- rbinom(N, 1, 0.6)
g <- function(pm, pu) ifelse(runif(N) < ifelse(match == 1, pm, pu), 2, 0)
d <- data.frame(g1 = g(0.95, 0.10), g2 = g(0.90, 0.20), g3 = g(0.85, 0.15))
patterns <- aggregate(list(counts = rep(1, N)), d, sum)
em <- function(prior = NULL, w = NULL)
    fastLink:::emlinkMARmov(patterns, nobs.a = N, nobs.b = 1, prior.lambda = prior,
                            w.lambda = w, varnames = names(d), tol = 1e-8)$p.m

test_that("lambda under a Beta prior lies between the data and the prior mean.", {
    free <- em()
    for (w in c(0.1, 0.5, 0.9)) {
        lam <- em(0.5, w)
        expect_true(lam > 0.5 && lam < free, label = paste("w.lambda =", w))
    }
    expect_true(em(0.5, 0.9) < em(0.5, 0.1), label = "a heavier prior pulls lambda closer to its mean")
})
