test_that("tableCounts agrees with individual pair comparisons", {
    a <- c("a", "b", NA, "a")
    b <- c("b", "a", "c", NA)
    x <- c(10, 10, 12, 14)
    y <- c(11, 10, 14, 13)
    exact <- gammaKpar(a, b, n.cores = 1)
    numeric <- gammaNUMCKpar(x, y, n.cores = 1, cut.a = 0.5, cut.p = 1.1)
    observed <- tableCounts(list(exact, numeric), length(a), length(b), n.cores = 1)

    first <- as.vector(2 * outer(a, b, "=="))
    distance <- as.vector(abs(outer(x, y, "-")))
    second <- ifelse(distance == 0, 2, ifelse(distance == 1, 1, 0))
    pairs <- data.frame(gamma.1 = first, gamma.2 = second)
    patterns <- unique(pairs)
    count <- function(i) {
        one <- patterns$gamma.1[i]
        same <- if (is.na(one)) is.na(first) else !is.na(first) & first == one
        sum(same & second == patterns$gamma.2[i])
    }
    patterns$counts <- vapply(seq_len(nrow(patterns)), count, integer(1))
    patterns <- patterns[order(patterns$gamma.2, patterns$gamma.1), ]
    expected <- as.matrix(patterns)
    rownames(expected) <- NULL
    expect_identical(unclass(observed), expected)
    expect_identical(class(observed), c("fastLink", "tableCounts"))
})

test_that("high fields retain exact low-order differences", {
    a <- c("a", "a", "b", NA)
    b <- c("a", "b", NA)
    first <- gammaKpar(a, b, n.cores = 1)
    last <- gammaKpar(rev(a), rev(b), n.cores = 1)
    fields <- c(rep(list(first), 16), list(last))
    narrow <- tableCounts(list(first, last), length(a), length(b), n.cores = 1)
    wide <- tableCounts(fields, length(a), length(b), n.cores = 1)
    expect_identical(unname(wide[, c(1, 17, 18)]), unname(unclass(narrow)))
    for (i in 2:16) expect_identical(wide[, i], wide[, 1])
    expect_error(tableCounts(c(fields, list(last)), length(a), length(b), 1), "17")
})

test_that("counts add across record slices", {
    a <- rep(c("x", "y"), 8000)
    b <- c("x", "z")
    field <- gammaKpar(a, b, n.cores = 1)
    observed <- tableCounts(list(field), length(a), length(b), n.cores = 1)
    expect_identical(observed[, "gamma.1"], c(0, 2))
    expect_identical(observed[, "counts"], c(24000, 8000))
})

test_that("counts keep the sole observed pattern and omit zero counts", {
    no.matches <- gammaKpar(c("a", "b"), c("c", "d"), n.cores = 1)
    same <- gammaKpar(c("a", "a"), c("a", "a"), n.cores = 1)
    expect_identical(unclass(tableCounts(list(no.matches), 2, 2, n.cores = 1)),
                     c(gamma.1 = 0, counts = 4))
    expect_identical(unclass(tableCounts(list(same), 2, 2, n.cores = 1)),
                     c(gamma.1 = 2, counts = 4))
})
