#' Group markers into linkage groups
#'
#' Performs two-point linkage analysis with [onemap::rf_2pts()] and groups
#' markers into linkage groups with [onemap::group()].  This is Module 2 of
#' the Linkmapper analytical workflow.
#'
#' To obtain a data-suggested LOD threshold instead of supplying a fixed value,
#' call [onemap::suggest_lod()] on the `onemap` object first and pass the
#' result as `lod`.
#'
#' @param onemap_obj An `onemap` object returned by [validate_lm_file()] or
#'   [onemap::read_mapmaker()].
#' @param lod Numeric. LOD score threshold for declaring linkage. Passed to
#'   [onemap::rf_2pts()]. Default `3`.
#' @param max_rf Numeric in \[0, 0.5\]. Maximum recombination frequency for
#'   declaring linkage. Passed to [onemap::rf_2pts()]. Default `0.5`.
#' @param map_fun Character. Mapping function. One of `"kosambi"` (default)
#'   or `"haldane"`. Passed to [onemap::set_map_fun()].
#'
#' @return An object of class `"sequence"` (as returned by [onemap::group()])
#'   with field `$n.groups` giving the number of linkage groups detected.
#'
#' @examples
#' \dontrun{
#' f2data <- validate_lm_file("path/to/mydata.txt")
#'
#' # Use a fixed LOD threshold
#' lgs <- group_markers(f2data, lod = 3, max_rf = 0.5)
#' lgs$n.groups
#'
#' # Or let onemap suggest the LOD
#' suggested <- onemap::suggest_lod(f2data)
#' lgs <- group_markers(f2data, lod = suggested, max_rf = 0.5)
#' }
#'
#' @export
group_markers <- function(onemap_obj, lod = 3, max_rf = 0.5, map_fun = "kosambi") {
  if (!inherits(onemap_obj, "onemap")) {
    stop(
      "'onemap_obj' must be an object of class \"onemap\". ",
      "Use validate_lm_file() or onemap::read_mapmaker() to create one.",
      call. = FALSE
    )
  }
  if (!is.numeric(lod) || length(lod) != 1L || lod <= 0) {
    stop("'lod' must be a single positive number.", call. = FALSE)
  }
  if (!is.numeric(max_rf) || length(max_rf) != 1L || max_rf < 0 || max_rf > 0.5) {
    stop("'max_rf' must be a single number between 0 and 0.5.", call. = FALSE)
  }
  map_fun <- match.arg(map_fun, c("kosambi", "haldane"))

  onemap::set_map_fun(type = map_fun)
  two_point  <- onemap::rf_2pts(onemap_obj, LOD = lod, max.rf = max_rf)
  all_seq    <- onemap::make_seq(two_point, "all")
  onemap::group(all_seq)
}
