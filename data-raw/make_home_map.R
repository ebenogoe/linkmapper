# Precomputes the linkage map shown on the home page, so it appears without
# waiting for marker ordering. Run from the package root:
#   Rscript data-raw/make_home_map.R
pkgload::load_all(quiet = TRUE)
d <- linkmapper_demo("f2")
res <- run_analysis(d, default_settings(d))
utils::write.csv(res$map$positions, "inst/extdata/home_f2_map.csv", row.names = FALSE)
utils::write.csv(res$qtl$peaks, "inst/extdata/home_f2_qtl.csv", row.names = FALSE)
