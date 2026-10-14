test_that("all demo datasets read with the right population type", {
  expect_equal(linkmapper_demo("f2")$type, "f2")
  expect_equal(linkmapper_demo("bc")$type, "backcross")
  expect_equal(linkmapper_demo("ril")$type, "riself")
  d <- linkmapper_demo("small")
  expect_equal(c(d$onemap$n.ind, d$onemap$n.mar), c(20, 10))
})

test_that("validate_lm_file still works for 0.1 scripts", {
  obj <- validate_lm_file(system.file("extdata", "f2_small.txt", package = "linkmapper"))
  expect_s3_class(obj, "onemap")
  expect_error(validate_lm_file(tmp_lines("x", ".csv")), "Expected a .txt or .raw")
  expect_error(validate_lm_file("missing.txt"), "not found")
})

test_that("files without a header or with outcross data are refused", {
  expect_error(read_cross(tmp_lines(c("hello", "1 2 3"))), "first line")
  expect_error(read_cross(tmp_lines(c("data type outcross", "2 2 0 0 0"))), "Outcross")
})

test_that("write_mapmaker round-trips genotypes and traits", {
  for (nm in c("f2", "bc", "ril")) {
    d <- linkmapper_demo(nm)
    f <- tempfile(fileext = ".raw")
    write_mapmaker(d, f)
    back <- read_cross(f)
    expect_equal(unname(back$onemap$geno), unname(d$onemap$geno), info = nm)
    expect_equal(back$onemap$segr.type, d$onemap$segr.type, info = nm)
    if (!is.null(d$onemap$pheno)) expect_equal(unname(back$onemap$pheno), unname(d$onemap$pheno), tolerance = 1e-6)
  }
})

test_that("traits can be added from a CSV", {
  d <- linkmapper_demo("ril")
  f <- tempfile(fileext = ".csv")
  utils::write.csv(data.frame(id = 1:100, height = rnorm(100), yield = rnorm(100)), f, row.names = FALSE)
  d2 <- add_traits(d, f)
  expect_equal(trait_names(d2), c("height", "yield"))
  utils::write.csv(data.frame(height = 1:5), f, row.names = FALSE)
  expect_error(add_traits(d, f), "rows")
})
