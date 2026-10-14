test_that("QTL scans find the simulated QTL in the backcross demo", {
  d <- linkmapper_demo("bc")
  m <- order_groups(linkage_groups(d))
  cr <- build_cross(d, m)
  expect_equal(names(cr$geno), names(m$maps))
  r <- scan_qtl(cr, n_perm = 50, seed = 1)
  expect_gte(nrow(r$peaks), 2)
  expect_true(all(r$peaks$lod >= r$threshold))
  expect_true(all(r$peaks$interval_low <= r$peaks$position & r$peaks$position <= r$peaks$interval_high))
  expect_false(anyNA(r$peaks$additive))
  r2 <- scan_qtl(cr, n_perm = 50, seed = 1)
  expect_identical(r$peaks, r2$peaks)
  e <- genotype_effect(r, r$peaks$nearest_marker[1])
  expect_setequal(levels(droplevels(e$genotype)), c("AA", "AB"))
})

test_that("the small 2022 demo now finds its QTL (0.1 bug)", {
  d <- linkmapper_demo("small")
  r <- scan_qtl(build_cross(d, order_groups(linkage_groups(d))), n_perm = 50)
  expect_gte(nrow(r$peaks), 1)
})

test_that("QTL mapping without traits explains itself", {
  d <- linkmapper_demo("ril")
  expect_error(build_cross(d, order_groups(linkage_groups(d))), "no traits")
})
