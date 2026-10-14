test_that("segregation tests and Bonferroni threshold", {
  q <- qc_summary(linkmapper_demo("ril"))
  expect_equal(q$alpha_bonferroni, 0.05 / 68)
  expect_true(all(q$markers$p_value >= 0 & q$markers$p_value <= 1))
  expect_equal(q$n_distorted, sum(q$markers$p_value < q$alpha_bonferroni))
})

test_that("filters remove what they report", {
  d <- linkmapper_demo("ril")
  f <- filter_markers(d, max_missing = 0.2, drop_distorted = TRUE)
  expect_equal(f$onemap$n.mar, f$filter$after)
  expect_equal(f$filter$before - f$filter$after, length(f$filter$removed))
  expect_false(any(f$filter$removed %in% colnames(f$onemap$geno)))
  expect_error(filter_markers(linkmapper_demo("f2"), max_missing = 0.05), "Fewer than two")
})
