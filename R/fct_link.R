#' Suggest a LOD threshold
#'
#' Uses onemap's suggestion, which accounts for the number of tests made in
#' the two-point analysis.
#'
#' @param d An `lm_data` object.
#' @return A number.
#' @export
suggest_lod <- function(d) {
  round(quiet(onemap::suggest_lod(d$onemap)), 2)
}

#' Find linkage groups
#'
#' Runs two-point analysis on every pair of markers and groups markers that
#' are linked at or above the LOD threshold and at or below the maximum
#' recombination fraction.
#'
#' @param d An `lm_data` object.
#' @param lod LOD threshold. Defaults to [suggest_lod()].
#' @param max_rf Largest recombination fraction treated as linkage.
#' @return An `lm_groups` list with the onemap `twopts` and `groups`
#'   objects and a `table` of groups.
#' @export
#' @examples
#' \donttest{
#' g <- linkage_groups(linkmapper_demo("bc"))
#' g$table
#' }
linkage_groups <- function(d, lod = NULL, max_rf = 0.5) {
  lod <- lod %||% suggest_lod(d)
  if (!is.numeric(lod) || lod <= 0) lm_abort("The LOD threshold must be a positive number.")
  if (!is.numeric(max_rf) || max_rf <= 0 || max_rf > 0.5) lm_abort("The maximum recombination fraction must be between 0 and 0.5.")
  tp <- quiet(onemap::rf_2pts(d$onemap, LOD = lod, max.rf = max_rf, verbose = FALSE))
  all <- quiet(onemap::make_seq(tp, "all"))
  gr <- quiet(onemap::group(all, LOD = lod, max.rf = max_rf, verbose = FALSE))
  names <- colnames(d$onemap$geno)
  tab <- do.call(rbind, lapply(seq_len(gr$n.groups), function(i) {
    idx <- gr$seq.num[gr$groups == i]
    data.frame(group = i, n_markers = length(idx), markers = paste(names[idx], collapse = ", "))
  }))
  unlinked <- names[gr$seq.num[gr$groups == 0]]
  structure(
    list(twopts = tp, groups = gr, table = tab, unlinked = unlinked, lod = lod, max_rf = max_rf),
    class = "lm_groups"
  )
}

#' @export
print.lm_groups <- function(x, ...) {
  cat("<Linkage groups>", nrow(x$table), "groups,", length(x$unlinked), "unlinked markers\n")
  print(x$table[, c("group", "n_markers")], row.names = FALSE)
  invisible(x)
}

#' Group markers (Linkmapper 0.1 interface)
#'
#' Kept for scripts written for Linkmapper 0.1. Prefer [linkage_groups()].
#'
#' @param onemap_obj A onemap object.
#' @param lod LOD threshold.
#' @param max_rf Largest recombination fraction treated as linkage.
#' @param map_fun `"kosambi"` or `"haldane"`.
#' @return The onemap `group` object.
#' @export
group_markers <- function(onemap_obj, lod = 3, max_rf = 0.5, map_fun = "kosambi") {
  if (!inherits(onemap_obj, "onemap")) {
    lm_abort("'onemap_obj' must be an object of class \"onemap\". Use read_cross() or onemap::read_mapmaker() to create one.")
  }
  if (!is.numeric(lod) || length(lod) != 1L || lod <= 0) lm_abort("'lod' must be a single positive number.")
  if (!is.numeric(max_rf) || length(max_rf) != 1L || max_rf < 0 || max_rf > 0.5) {
    lm_abort("'max_rf' must be a single number between 0 and 0.5.")
  }
  map_fun <- match.arg(map_fun, c("kosambi", "haldane"))
  onemap::set_map_fun(type = map_fun)
  tp <- quiet(onemap::rf_2pts(onemap_obj, LOD = lod, max.rf = max_rf, verbose = FALSE))
  quiet(onemap::group(onemap::make_seq(tp, "all"), verbose = FALSE))
}

#' Ordering algorithms
#' @return A named character vector (labels as names).
#' @export
order_methods <- function() {
  c(
    "RECORD (recombination counting)" = "record",
    "RCD (rapid chain delineation)" = "rcd",
    "Unidirectional growth (UG)" = "ug",
    "Seriation" = "seriation"
  )
}

order_label <- function(m) names(order_methods())[match(m, order_methods())]

#' Order markers within each linkage group
#'
#' Orders each group with the chosen algorithm and estimates map distances
#' with the chosen mapping function. Groups with fewer than two markers
#' cannot be ordered and are reported as unplaced.
#'
#' @param groups An `lm_groups` object from [linkage_groups()].
#' @param method One of [order_methods()].
#' @param map_fun `"kosambi"` or `"haldane"`.
#' @param seed Random seed. RECORD and UG use random starting orders, so the
#'   seed makes the map repeatable.
#' @param progress Optional function called with the share done (0 to 1).
#' @return An `lm_map` list with the ordered onemap sequences (`maps`), a
#'   `positions` table and settings.
#' @export
order_groups <- function(groups, method = "record", map_fun = c("kosambi", "haldane"), seed = 1,
                         progress = NULL) {
  map_fun <- match.arg(map_fun)
  if (!method %in% order_methods()) lm_abort("Unknown ordering method: ", method)
  onemap::set_map_fun(type = map_fun)
  gr <- groups$groups
  maps <- list()
  unplaced <- character()
  ids <- seq_len(gr$n.groups)
  for (k in seq_along(ids)) {
    i <- ids[k]
    s <- quiet(onemap::make_seq(gr, i))
    if (length(s$seq.num) < 2) {
      unplaced <- c(unplaced, marker_names(groups)[s$seq.num])
    } else {
      fun <- switch(method,
        record = onemap::record,
        rcd = onemap::rcd,
        ug = onemap::ug,
        seriation = onemap::seriation
      )
      o <- tryCatch(with_seed(seed + i, quiet(fun(s, verbose = FALSE))), error = function(e) NULL)
      if (is.null(o)) {
        unplaced <- c(unplaced, marker_names(groups)[s$seq.num])
      } else {
        maps[[length(maps) + 1]] <- o
      }
    }
    if (!is.null(progress)) progress(k / length(ids))
  }
  if (!length(maps)) lm_abort("No linkage group could be ordered. Try a lower LOD threshold.")
  names(maps) <- paste0("LG", seq_along(maps))
  res <- structure(
    list(
      maps = maps, method = method, map_fun = map_fun, seed = seed, unplaced = unplaced,
      marker_names = marker_names(groups)
    ),
    class = "lm_map"
  )
  res$positions <- map_positions(res)
  res
}

marker_names <- function(groups) colnames(groups$twopts$data.name$geno)

#' Marker positions on a map
#'
#' @param m An `lm_map` from [order_groups()].
#' @return A data frame with one row per marker: linkage group, order,
#'   marker, position (cM) and distance to the previous marker.
#' @export
map_positions <- function(m) {
  fun <- if (m$map_fun == "haldane") onemap::haldane else onemap::kosambi
  do.call(rbind, lapply(names(m$maps), function(lg) {
    s <- m$maps[[lg]]
    gaps <- fun(s$seq.rf)
    pos <- c(0, cumsum(gaps))
    data.frame(
      lg = lg, order = seq_along(s$seq.num), marker = m$marker_names[s$seq.num],
      position = round(pos, 2), interval = round(c(NA, gaps), 2)
    )
  }))
}

#' Summary of each linkage group
#' @param m An `lm_map`.
#' @return A data frame with markers, length, mean and largest spacing per group.
#' @export
map_summary <- function(m) {
  p <- m$positions
  out <- do.call(rbind, lapply(split(p, factor(p$lg, levels = unique(p$lg))), function(x) {
    data.frame(
      lg = x$lg[1], markers = nrow(x), length_cM = max(x$position),
      mean_spacing = round(mean(x$interval, na.rm = TRUE), 2),
      largest_gap = max(x$interval, na.rm = TRUE)
    )
  }))
  rownames(out) <- NULL
  out
}
