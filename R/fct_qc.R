#' Marker and individual quality summary
#'
#' Missing data per marker and per individual, genotype counts, and the
#' chi-square test of each marker against its expected Mendelian ratio
#' (1:2:1, 3:1, 1:1). The significance threshold is Bonferroni-corrected
#' for the number of markers.
#'
#' @param d An `lm_data` object.
#' @param alpha Family-wise significance level for segregation distortion.
#' @return A list with `markers` and `individuals` data frames and the
#'   corrected threshold `alpha_bonferroni`.
#' @export
qc_summary <- function(d, alpha = 0.05) {
  obj <- d$onemap
  g <- obj$geno
  seg <- quiet(onemap::test_segregation(obj))
  tab <- quiet(print(seg))
  bonf <- alpha / obj$n.mar
  type <- ifelse(obj$segr.type %in% c("C.A", "D.B"), "dominant", "codominant")
  counts <- t(vapply(seq_len(ncol(g)), function(j) {
    lett <- geno_letters[[obj$segr.type[j]]]
    v <- g[, j][g[, j] > 0]
    out <- c(A = 0, H = 0, B = 0, C = 0, D = 0)
    if (length(v)) {
      tb <- table(lett[v])
      out[names(tb)] <- as.numeric(tb)
    }
    out
  }, numeric(5)))
  markers <- data.frame(
    marker = colnames(g),
    type = type,
    expected = tab$H0,
    missing = colMeans(g == 0),
    counts,
    chisq = tab$`Chi-square`,
    p_value = tab$`p-value`,
    distorted = tab$`p-value` < bonf,
    row.names = NULL,
    check.names = FALSE
  )
  markers <- markers[, colSums(markers != 0, na.rm = TRUE) > 0 | !names(markers) %in% c("A", "H", "B", "C", "D")]
  list(
    markers = markers,
    individuals = data.frame(individual = seq_len(obj$n.ind), missing = rowMeans(g == 0)),
    alpha_bonferroni = bonf,
    n_distorted = sum(markers$distorted)
  )
}

#' Filter markers
#'
#' @param d An `lm_data` object.
#' @param max_missing Largest share of missing genotypes allowed per marker.
#' @param drop_distorted Remove markers with significant segregation
#'   distortion (Bonferroni-corrected).
#' @param alpha Family-wise significance level for distortion.
#' @return The filtered `lm_data`, with a `filter` element recording what
#'   was removed.
#' @export
filter_markers <- function(d, max_missing = 0.25, drop_distorted = FALSE, alpha = 0.05) {
  q <- qc_summary(d, alpha)$markers
  keep <- q$missing <= max_missing
  if (drop_distorted) keep <- keep & !q$distorted
  removed <- q$marker[!keep]
  if (sum(keep) < 2) lm_abort("Fewer than two markers are left after filtering. Relax the thresholds.")
  if (length(removed)) d$onemap <- quiet(onemap::split_onemap(d$onemap, mks = which(keep)))
  d$filter <- list(
    settings = list(max_missing = max_missing, drop_distorted = drop_distorted, alpha = alpha),
    before = length(keep), after = sum(keep), removed = removed
  )
  d
}
