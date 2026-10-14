lm_col <- list(
  teal = "#0d9488", teal_dark = "#2dd4bf", amber = "#f59e0b", amber_text = "#b45309",
  ink = "#0f2a2a", text = "#21403d", text_dark = "#d9ebe8", muted = "#4b6260",
  muted_dark = "#93b3ae", line = "#dbe7e5", line_dark = "#1f3a37", bar = "#ccebe7",
  bar_dark = "#134e4a"
)

#' ggplot2 theme used by Linkmapper
#' @param base_size Base font size.
#' @param dark Use colours for a dark background.
#' @return A ggplot2 theme.
#' @export
theme_linkmapper <- function(base_size = 12, dark = FALSE) {
  txt <- if (dark) lm_col$text_dark else lm_col$text
  mut <- if (dark) lm_col$muted_dark else lm_col$muted
  grid <- if (dark) lm_col$line_dark else lm_col$line
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      text = ggplot2::element_text(colour = txt),
      axis.text = ggplot2::element_text(colour = mut),
      plot.title = ggplot2::element_text(face = "bold", size = base_size * 1.15),
      plot.title.position = "plot",
      plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
      panel.background = ggplot2::element_rect(fill = "transparent", colour = NA),
      legend.background = ggplot2::element_rect(fill = "transparent", colour = NA),
      panel.grid.major = ggplot2::element_line(colour = grid, linewidth = 0.35),
      panel.grid.minor = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(colour = txt, face = "bold"),
      legend.position = "bottom"
    )
}

# Spread label positions so neighbours are at least `gap` apart, staying
# as close as possible to the original positions
spread_labels <- function(y, gap) {
  o <- order(y)
  v <- y[o]
  n <- length(v)
  if (n > 1) {
    for (i in 2:n) v[i] <- max(v[i], v[i - 1] + gap)
    shift <- mean(v - y[o])
    v <- v - shift
    if (v[1] < min(y) - gap) v <- v + (min(y) - gap - v[1])
    for (i in 2:n) v[i] <- max(v[i], v[i - 1] + gap)
  }
  out <- numeric(n)
  out[o] <- v
  out
}

#' Size of a linkage map figure in inches
#' @param m An `lm_map`.
#' @return `c(width, height)`.
#' @export
map_plot_size <- function(m) {
  n_lg <- length(unique(m$positions$lg))
  most <- max(table(m$positions$lg))
  c(max(6, 2.1 * n_lg + 0.6), min(28, max(6, most * 0.2 + 1.6)))
}

#' Draw a linkage map
#'
#' Each linkage group is a vertical bar with positions (cM) on the left and
#' marker names on the right. Labels are spread so they do not overlap.
#' QTL support intervals from [scan_qtl()] can be drawn beside the groups.
#'
#' @param m An `lm_map` from [order_groups()], or any list with a
#'   `positions` data frame (columns `lg`, `marker`, `position`).
#' @param qtl Optional `lm_qtl` from [scan_qtl()], or a list with a `peaks`
#'   data frame and a `trait`.
#' @param dark Colours for a dark background.
#' @param label_size Text size.
#' @param title Optional title.
#' @return A ggplot object (interactive with [ggiraph::girafe()]).
#' @export
plot_linkage_map <- function(m, qtl = NULL, dark = FALSE, label_size = 2.9, title = NULL) {
  p <- m$positions
  lgs <- unique(p$lg)
  p$x <- match(p$lg, lgs) * 2
  height <- map_plot_size(m)[2]
  max_len <- max(p$position, 1)
  gap <- max_len / (height - 1.6) * 0.15
  p$label_y <- unlist(lapply(split(p$position, factor(p$lg, levels = lgs)), spread_labels, gap = gap))
  p$tip <- sprintf("%s<br>%s at %.1f cM", p$marker, p$lg, p$position)
  ends <- stats::aggregate(position ~ lg, p, max)
  ends$x <- match(ends$lg, lgs) * 2
  txt <- if (dark) lm_col$text_dark else lm_col$text
  mut <- if (dark) lm_col$muted_dark else lm_col$muted
  bar <- if (dark) lm_col$bar_dark else lm_col$bar
  edge <- if (dark) lm_col$teal_dark else lm_col$teal
  g <- ggplot2::ggplot() +
    ggplot2::geom_rect(
      data = ends, ggplot2::aes(
        xmin = .data$x - 0.13, xmax = .data$x + 0.13,
        ymin = 0, ymax = .data$position
      ),
      fill = bar, colour = edge, linewidth = 0.5
    ) +
    ggiraph::geom_segment_interactive(
      data = p, ggplot2::aes(
        x = .data$x - 0.13, xend = .data$x + 0.13,
        y = .data$position, yend = .data$position,
        tooltip = .data$tip, data_id = .data$marker
      ),
      colour = edge, linewidth = 0.6
    ) +
    ggplot2::geom_segment(
      data = p, ggplot2::aes(
        x = .data$x + 0.13, xend = .data$x + 0.32,
        y = .data$position, yend = .data$label_y
      ),
      colour = mut, linewidth = 0.25
    ) +
    ggplot2::geom_segment(
      data = p, ggplot2::aes(
        x = .data$x - 0.13, xend = .data$x - 0.32,
        y = .data$position, yend = .data$label_y
      ),
      colour = mut, linewidth = 0.25
    ) +
    ggiraph::geom_text_interactive(
      data = p, ggplot2::aes(
        x = .data$x + 0.36, y = .data$label_y, label = .data$marker,
        tooltip = .data$tip, data_id = .data$marker
      ),
      hjust = 0, size = label_size, colour = txt
    ) +
    ggplot2::geom_text(
      data = p, ggplot2::aes(
        x = .data$x - 0.36, y = .data$label_y,
        label = formatC(.data$position, format = "f", digits = 1)
      ),
      hjust = 1, size = label_size * 0.9, colour = mut
    ) +
    ggplot2::annotate("text",
      x = seq_along(lgs) * 2, y = -max_len * 0.05, label = lgs,
      fontface = "bold", size = label_size * 1.3, colour = txt
    )
  if (!is.null(qtl) && nrow(qtl$peaks)) {
    q <- qtl$peaks
    q$x <- match(q$lg, lgs) * 2
    q$tip <- sprintf(
      "QTL for %s<br>%s at %.1f cM, LOD %.1f<br>Interval %.1f to %.1f cM",
      qtl$trait, q$lg, q$position, q$lod, q$interval_low, q$interval_high
    )
    g <- g +
      ggiraph::geom_rect_interactive(
        data = q, ggplot2::aes(
          xmin = .data$x + 0.17, xmax = .data$x + 0.27,
          ymin = .data$interval_low, ymax = .data$interval_high,
          tooltip = .data$tip, data_id = paste0("qtl", .data$lg)
        ),
        fill = lm_col$amber, colour = NA
      ) +
      ggplot2::geom_point(
        data = q, ggplot2::aes(x = .data$x + 0.22, y = .data$position),
        shape = 23, size = 2.4, fill = lm_col$amber, colour = lm_col$amber_text
      )
  }
  g <- g + ggplot2::scale_y_reverse(expand = ggplot2::expansion(mult = c(0.03, 0.08))) +
    ggplot2::scale_x_continuous(limits = c(0.9, length(lgs) * 2 + 1.1)) +
    ggplot2::theme_void() +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
      plot.title = ggplot2::element_text(colour = txt, face = "bold", size = 14)
    )
  if (!is.null(title) && nzchar(title)) g <- g + ggplot2::ggtitle(title)
  g
}

#' Segregation test plot
#' @param q Result of [qc_summary()].
#' @param dark Colours for a dark background.
#' @return A ggplot object.
#' @export
plot_segregation <- function(q, dark = FALSE) {
  df <- q$markers
  df$index <- seq_len(nrow(df))
  df$logp <- -log10(pmax(df$p_value, 1e-300))
  df$status <- ifelse(df$distorted, "Distorted", "Expected ratio")
  df$tip <- sprintf("%s (%s, %s)<br>p = %.2g", df$marker, df$type, df$expected, df$p_value)
  ggplot2::ggplot(df, ggplot2::aes(.data$index, .data$logp, colour = .data$status)) +
    ggplot2::geom_hline(yintercept = -log10(q$alpha_bonferroni), linetype = 2, colour = lm_col$amber_text) +
    ggiraph::geom_point_interactive(ggplot2::aes(tooltip = .data$tip, data_id = .data$marker), size = 2.3) +
    ggplot2::scale_colour_manual(
      values = c("Distorted" = lm_col$amber, "Expected ratio" = if (dark) lm_col$teal_dark else lm_col$teal),
      name = NULL
    ) +
    ggplot2::labs(x = "Marker (file order)", y = expression(-log[10](p))) +
    theme_linkmapper(dark = dark)
}

#' Missing data plot
#' @param q Result of [qc_summary()].
#' @param threshold Optional cut-off to draw.
#' @param dark Colours for a dark background.
#' @return A ggplot object.
#' @export
plot_missing <- function(q, threshold = NULL, dark = FALSE) {
  df <- rbind(
    data.frame(v = q$markers$missing, what = "Per marker"),
    data.frame(v = q$individuals$missing, what = "Per individual")
  )
  g <- ggplot2::ggplot(df, ggplot2::aes(.data$v)) +
    ggplot2::geom_histogram(bins = 25, fill = if (dark) lm_col$teal_dark else lm_col$teal) +
    ggplot2::facet_wrap(~what, scales = "free_y") +
    ggplot2::scale_x_continuous(labels = function(x) paste0(round(100 * x), "%")) +
    ggplot2::labs(x = "Missing genotypes", y = "Count") +
    theme_linkmapper(dark = dark)
  if (!is.null(threshold)) {
    g <- g + ggplot2::geom_vline(
      data = data.frame(what = "Per marker", t = threshold),
      ggplot2::aes(xintercept = .data$t), linetype = 2, colour = lm_col$amber_text
    )
  }
  g
}

#' Recombination fraction heatmap for one linkage group
#'
#' Markers are in map order. Darker cells mean tighter linkage.
#'
#' @param m An `lm_map`.
#' @param lg Linkage group name, for example `"LG1"`.
#' @param dark Colours for a dark background.
#' @return A ggplot object.
#' @export
plot_rf_heatmap <- function(m, lg, dark = FALSE) {
  s <- m$maps[[lg]]
  if (is.null(s)) lm_abort("Unknown linkage group: ", lg)
  p <- quiet(onemap::rf_graph_table(s, inter = FALSE, display = FALSE))
  df <- p$data
  # onemap stores marker numbers as factors
  df$x <- as.numeric(as.character(df$x))
  df$y <- as.numeric(as.character(df$y))
  ord <- s$seq.num
  nm <- m$marker_names
  df <- df[df$x %in% ord & df$y %in% ord & df$x != df$y, ]
  df$mx <- factor(nm[df$x], levels = nm[ord])
  df$my <- factor(nm[df$y], levels = rev(nm[ord]))
  df$tip <- sprintf("%s and %s<br>rf = %.2f, LOD = %.1f", df$mx, df$my, df$rf, df$LOD)
  ggplot2::ggplot(df, ggplot2::aes(.data$mx, .data$my, fill = .data$rf)) +
    ggiraph::geom_tile_interactive(ggplot2::aes(tooltip = .data$tip, data_id = .data$tip)) +
    ggplot2::scale_fill_gradientn(
      colours = c("#134e4a", "#0d9488", "#5eead4", "#fef3c7", "#fbbf24"),
      limits = c(0, 0.5), na.value = "transparent", name = "rf"
    ) +
    ggplot2::coord_fixed() +
    ggplot2::labs(x = NULL, y = NULL) +
    theme_linkmapper(dark = dark) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 90, hjust = 1, vjust = 0.5, size = 7),
      axis.text.y = ggplot2::element_text(size = 7), panel.grid.major = ggplot2::element_blank(),
      legend.position = "right"
    )
}

#' LOD profile plot
#' @param res An `lm_qtl` from [scan_qtl()].
#' @param dark Colours for a dark background.
#' @return A ggplot object.
#' @export
plot_lod <- function(res, dark = FALSE) {
  sc <- res$scan
  col <- if (dark) lm_col$teal_dark else lm_col$teal
  g <- ggplot2::ggplot(sc, ggplot2::aes(.data$position, .data$lod)) +
    ggplot2::geom_hline(yintercept = res$threshold, linetype = 2, colour = lm_col$amber_text) +
    ggplot2::geom_line(colour = col, linewidth = 0.8) +
    ggplot2::facet_grid(~lg, scales = "free_x", space = "free_x") +
    ggplot2::labs(
      x = "Position (cM)", y = "LOD",
      subtitle = sprintf(
        "%s, %s. Dashed line: genome-wide %g%% threshold (LOD %.2f, %d permutations).",
        res$trait, if (res$cim) "composite interval mapping" else "interval mapping",
        100 * res$alpha, res$threshold, res$n_perm
      )
    ) +
    theme_linkmapper(dark = dark) +
    ggplot2::theme(panel.spacing = ggplot2::unit(0.6, "lines"))
  if (nrow(res$peaks)) {
    pk <- res$peaks
    pk$tip <- sprintf(
      "%s at %.1f cM<br>LOD %.2f, %.1f%% of variance<br>Nearest marker %s",
      pk$lg, pk$position, pk$lod, pk$pve, pk$nearest_marker
    )
    pk$lg <- factor(pk$lg, levels = levels(sc$lg))
    g <- g + ggiraph::geom_point_interactive(
      data = pk, ggplot2::aes(.data$position, .data$lod,
        tooltip = .data$tip, data_id = .data$lg
      ),
      shape = 23, size = 3.2, fill = lm_col$amber, colour = lm_col$amber_text
    )
  }
  g
}

#' Trait values by genotype
#' @param df Result of [genotype_effect()].
#' @param marker Marker name, for the title.
#' @param trait Trait name, for the axis.
#' @param dark Colours for a dark background.
#' @return A ggplot object.
#' @export
plot_effect <- function(df, marker, trait, dark = FALSE) {
  col <- if (dark) lm_col$teal_dark else lm_col$teal
  ggplot2::ggplot(df, ggplot2::aes(.data$genotype, .data$value)) +
    ggplot2::geom_boxplot(fill = NA, colour = col, outlier.shape = NA, width = 0.5) +
    ggplot2::geom_jitter(width = 0.15, height = 0, alpha = 0.45, colour = col, size = 1.4) +
    ggplot2::labs(x = paste("Genotype at", marker), y = trait) +
    theme_linkmapper(dark = dark)
}
