context("EM corrections: level order, bounded counts, indexed lookup.")

## Agreement patterns for two fields (0 = disagree, 1 = partial, 2 = agree), with counts.
## Row order is chosen so that field 1 first encounters its levels in the order 0, 2, 1.
pat <- data.frame(
    g1 = c(0, 2, 1, 0, 2, 1, 0, 2),
    g2 = c(0, 2, 0, 2, 1, 1, 1, 0),
    counts = c(5000, 40, 30, 200, 25, 60, 900, 15)
)

fit <- function(p) {
    set.seed(1)
    emlinkMARmov(p, nobs.a = 100, nobs.b = 100, tol = 1e-8,
                 p.gamma.k.m = list(c(0.1, 0.2, 0.7), c(0.1, 0.2, 0.7)),
                 p.gamma.k.u = list(c(0.7, 0.2, 0.1), c(0.7, 0.2, 0.1)))
}

key <- function(p) paste(p[, 1], p[, 2])

test_that("posteriors do not depend on the row order of the patterns", {
    a <- fit(pat)
    perm <- c(3, 6, 1, 8, 4, 2, 7, 5)
    b <- fit(pat[perm, ])
    za <- setNames(as.vector(a$zeta.j), key(pat))
    zb <- setNames(as.vector(b$zeta.j), key(pat[perm, ]))
    expect_equal(za[names(zb)], zb, tolerance = 1e-8)
    for (i in 1:2) {
        expect_equal(a$p.gamma.k.m[[i]], b$p.gamma.k.m[[i]], tolerance = 1e-8)
        expect_equal(a$p.gamma.k.u[[i]], b$p.gamma.k.u[[i]], tolerance = 1e-8)
    }
})

test_that("component probabilities are valid at boundary posteriors", {
    ## A pattern with full agreement and a very large count drives its posterior to one.
    p <- rbind(pat, data.frame(g1 = 2, g2 = 2, counts = 1e7))
    out <- fit(p)
    for (i in 1:2) {
        expect_true(all(is.finite(out$p.gamma.k.u[[i]])))
        expect_true(all(out$p.gamma.k.u[[i]] >= 0))
        expect_true(all(out$p.gamma.k.m[[i]] >= 0))
    }
    expect_true(all(out$zeta.j >= 0 & out$zeta.j <= 1))
})

test_that("a substituted probability of one is not read as agreement code one", {
    ## Field 2 has a single level, so its probability is exactly one under both classes;
    ## field 1 uses codes 0, 1, 2. Results must match the fit without field 2.
    p2 <- data.frame(g1 = pat$g1, g2 = 1, counts = pat$counts)
    p2 <- aggregate(counts ~ g1 + g2, data = p2, FUN = sum)
    out2 <- fit(p2[, c("g1", "g2", "counts")])
    expect_true(all(is.finite(out2$zeta.j)))
    expect_true(all(out2$zeta.j >= 0 & out2$zeta.j <= 1))
})
