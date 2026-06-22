# tests/testthat/test-grouping.R
# Unit tests for group_markers()  (R/grouping.R)
# ----------------------------------------------------------------------------
# Ground truth note:
#   The demo file (inst/app/www/data/f2_demo.txt) contains 10 markers
#   explicitly named D1M1–D1M5 and D2M1–D2M5 across 20 individuals.  With
#   LOD = 3 and max_rf = 0.5 this produces 2 linkage groups.
#
#   The dissertation mentions 5 linkage groups, but that refers to the full
#   experimental dataset used in the thesis, which is a different (larger) file.
#   Tests here use the demo file and assert 2 groups.
# ----------------------------------------------------------------------------

# Helper: same pattern as test-read_data.R
demo_path <- function() {
  p <- system.file("app/www/data/f2_demo.txt", package = "linkmapper")
  if (!nzchar(p)) {
    testthat::skip("Demo data file not found. Run devtools::load_all() first.")
  }
  p
}

# Shared fixture: read the demo data once for the onemap-dependent tests.
# Wrapped in local() so the intermediate object (f2_raw) does not leak into
# the test environment.
demo_f2 <- local({
  skip_if_not_installed("onemap")
  p <- system.file("app/www/data/f2_demo.txt", package = "linkmapper")
  if (!nzchar(p)) return(NULL)
  suppressMessages(onemap::read_mapmaker(file = p))
})

# ---- Input validation (fast — no onemap call) -------------------------------

test_that("group_markers() errors when onemap_obj is not class 'onemap'", {
  expect_error(group_markers(list()),        regexp = "class \"onemap\"")
  expect_error(group_markers(data.frame()),  regexp = "class \"onemap\"")
  expect_error(group_markers("not_onemap"),  regexp = "class \"onemap\"")
})

test_that("group_markers() errors when lod is not a single positive number", {
  # Use a trivial non-onemap stand-in just to reach the lod check;
  # the onemap_obj check fires first so we need a valid-looking object.
  # Construct a minimal fake onemap object to reach the lod argument check.
  fake <- structure(list(n.ind = 1L, n.mar = 1L), class = "onemap")

  expect_error(group_markers(fake, lod = -1),          regexp = "positive")
  expect_error(group_markers(fake, lod = 0),           regexp = "positive")
  expect_error(group_markers(fake, lod = c(3, 4)),     regexp = "positive")
})

test_that("group_markers() errors when max_rf is outside [0, 0.5]", {
  fake <- structure(list(n.ind = 1L, n.mar = 1L), class = "onemap")

  expect_error(group_markers(fake, max_rf = -0.1),  regexp = "0 and 0.5")
  expect_error(group_markers(fake, max_rf = 0.6),   regexp = "0 and 0.5")
})

# ---- Return value -----------------------------------------------------------

test_that("group_markers() returns an object of class 'sequence'", {
  skip_on_cran()
  skip_if_not_installed("onemap")
  if (is.null(demo_f2)) skip("Demo data could not be loaded")

  result <- suppressMessages(
    suppressWarnings(group_markers(demo_f2, lod = 3, max_rf = 0.5))
  )

  expect_s3_class(result, "sequence")
})

test_that("group_markers() result contains the $n.groups field", {
  skip_on_cran()
  skip_if_not_installed("onemap")
  if (is.null(demo_f2)) skip("Demo data could not be loaded")

  result <- suppressMessages(
    suppressWarnings(group_markers(demo_f2, lod = 3, max_rf = 0.5))
  )

  expect_true(!is.null(result$n.groups))
  expect_type(result$n.groups, "integer")
})

test_that("group_markers() detects 2 linkage groups from the demo dataset", {
  skip_on_cran()
  skip_if_not_installed("onemap")
  if (is.null(demo_f2)) skip("Demo data could not be loaded")

  # The demo file has 10 markers in two clear groups (D1M1-D1M5, D2M1-D2M5).
  # LOD = 3 and max_rf = 0.5 are the app defaults (app.R slider default = 0.5).
  result <- suppressMessages(
    suppressWarnings(group_markers(demo_f2, lod = 3, max_rf = 0.5))
  )

  expect_equal(result$n.groups, 2L)
})

test_that("group_markers() result$groups assigns all markers to a group", {
  skip_on_cran()
  skip_if_not_installed("onemap")
  if (is.null(demo_f2)) skip("Demo data could not be loaded")

  result <- suppressMessages(
    suppressWarnings(group_markers(demo_f2, lod = 3, max_rf = 0.5))
  )

  # $groups is an integer vector, one entry per marker; 0 = unlinked
  expect_equal(length(result$groups), demo_f2$n.mar)
  expect_true(all(result$groups > 0L),
              info = "All markers should be assigned to a group in this clean demo file")
})
