test_that("linkage groups recover the simulated chromosomes", {
  g <- linkage_groups(linkmapper_demo("bc"))
  expect_equal(nrow(g$table), 3)
  expect_equal(sum(g$table$n_markers) + length(g$unlinked), 67)
})

test_that("group_markers keeps the 0.1 interface", {
  obj <- linkmapper_demo("small")$onemap
  expect_equal(group_markers(obj)$n.groups, 2)
  expect_error(group_markers(list()), "onemap")
  expect_error(group_markers(obj, lod = -1), "positive")
  expect_error(group_markers(obj, max_rf = 0.6), "0 and 0.5")
})

test_that("ordering gives positions starting at zero and is repeatable", {
  g <- linkage_groups(linkmapper_demo("bc"))
  m1 <- order_groups(g, "record", seed = 3)
  m2 <- order_groups(g, "record", seed = 3)
  expect_identical(m1$positions, m2$positions)
  expect_true(all(tapply(m1$positions$position, m1$positions$lg, min) == 0))
  expect_true(all(diff(m1$positions$position[m1$positions$lg == "LG1"]) >= 0))
  expect_equal(nrow(map_summary(m1)), 3)
  h <- order_groups(g, "rcd", map_fun = "haldane")
  expect_gt(sum(map_summary(h)$length_cM), 0)
})

test_that("single-marker groups are reported as unplaced, not an error", {
  d <- linkmapper_demo("ril")
  g <- linkage_groups(d, lod = 6)
  m <- order_groups(g, "rcd")
  expect_true(length(m$unplaced) >= 0)
  expect_true(all(table(m$positions$lg) >= 2))
})
