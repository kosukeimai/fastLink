test_that("getMatches preserves column name when dfB has a single unique column", {
  dfA <- data.frame(fname = c("Alice", "Bob"), lname = c("Smith", "Jones"))
  dfB <- data.frame(fname = c("Alice", "Bob"), lname = c("Smith", "Jones"), b_id = c(101, 102))

  ml_out <- structure(list(inds.a = 1:2, inds.b = 1:2), class = "matchesLink")
  res_ml <- getMatches(dfA, dfB, ml_out, combine.dfs = TRUE)
  expect_true("b_id" %in% names(res_ml))
  expect_false("dfB.match[, names.dfB]" %in% names(res_ml))

  fl_out <- structure(
    list(matches = list(inds.a = 1:2, inds.b = 1:2), patterns = matrix(2, 2, 2)),
    class = "fastLink"
  )
  res_fl <- getMatches(dfA, dfB, fl_out, combine.dfs = TRUE)
  expect_true("b_id" %in% names(res_fl))
  expect_false("dfB.match[, names.dfB]" %in% names(res_fl))
})
