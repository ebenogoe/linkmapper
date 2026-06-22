# tests/testthat/test-read_data.R
# Unit tests for validate_lm_file()  (R/read_data.R)
# ----------------------------------------------------------------------------
# Tests that call onemap (i.e. require the demo file) are marked skip_on_cran()
# because they perform real file I/O and depend on onemap being installed.
# Fast tests (only file system operations, no onemap calls) run everywhere.
# ----------------------------------------------------------------------------

# Helper: resolve the demo dataset path whether running from a source tree
# (devtools::test() / devtools::load_all()) or an installed package.
demo_path <- function() {
  p <- system.file("app/www/data/f2_demo.txt", package = "linkmapper")
  if (!nzchar(p)) {
    testthat::skip("Demo data file not found. Run devtools::load_all() first.")
  }
  p
}

# ---- Successful read --------------------------------------------------------

test_that("validate_lm_file() returns an object of class 'onemap' for a valid file", {
  skip_on_cran()
  skip_if_not_installed("onemap")

  result <- suppressMessages(validate_lm_file(demo_path()))

  expect_s3_class(result, "onemap")
})

test_that("validate_lm_file() result has non-zero individuals and markers", {
  skip_on_cran()
  skip_if_not_installed("onemap")

  result <- suppressMessages(validate_lm_file(demo_path()))

  # demo file: 20 individuals, 10 markers (header line: "20 10 2")
  expect_equal(result$n.ind, 20L)
  expect_equal(result$n.mar, 10L)
})

# ---- Extension check (fast — no onemap call) --------------------------------

test_that("validate_lm_file() errors when the file does not have a .txt extension", {
  f <- tempfile(fileext = ".csv")
  file.create(f)
  on.exit(unlink(f), add = TRUE)

  expect_error(validate_lm_file(f), regexp = "\\.txt")
})

# ---- Non-MAPMAKER content (fast — onemap parse attempt will fail quickly) ---

test_that("validate_lm_file() errors on a .txt file that is not MAPMAKER-formatted", {
  skip_if_not_installed("onemap")

  f <- tempfile(fileext = ".txt")
  writeLines(c("this is not", "a mapmaker file"), f)
  on.exit(unlink(f), add = TRUE)

  expect_error(validate_lm_file(f), regexp = "Could not parse")
})

# ---- Input validation (no file I/O) ----------------------------------------

test_that("validate_lm_file() errors when path is not a character string", {
  expect_error(validate_lm_file(42L), regexp = "single character string")
  expect_error(validate_lm_file(c("a.txt", "b.txt")), regexp = "single character string")
})

test_that("validate_lm_file() errors when the file does not exist", {
  expect_error(validate_lm_file(tempfile(fileext = ".txt")), regexp = "File not found")
})
