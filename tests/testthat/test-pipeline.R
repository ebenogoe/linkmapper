test_that("sessions reproduce the map and QTL exactly", {
  d <- linkmapper_demo("bc")
  s <- default_settings(d)
  s$qtl$n_perm <- 50
  f <- tempfile(fileext = ".json")
  save_session(d, s, f)
  back <- load_session(f)
  a <- run_analysis(d, s)
  b <- run_analysis(back$data, back$settings)
  expect_identical(a$map$positions, b$map$positions)
  expect_identical(a$qtl$peaks, b$qtl$peaks)
})

test_that("the script parses and the report is a full page", {
  d <- linkmapper_demo("small")
  s <- default_settings(d)
  s$qtl$n_perm <- 50
  expect_silent(parse(text = build_script(s, list(demo = "small"))))
  res <- run_analysis(d, s)
  f <- tempfile(fileext = ".html")
  build_report(res, s, f)
  html <- paste(readLines(f), collapse = "\n")
  expect_match(html, "<head>", fixed = TRUE)
  expect_match(html, "Linkage map", fixed = TRUE)
  expect_match(html, "<svg", fixed = TRUE)
})
