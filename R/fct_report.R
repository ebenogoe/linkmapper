svg_string <- function(p, width = 8, height = 6) {
  s <- svglite::svgstring(width = width, height = height, standalone = FALSE)
  ok <- FALSE
  on.exit(if (!ok) grDevices::dev.off())
  print(p)
  grDevices::dev.off()
  ok <- TRUE
  htmltools::HTML(as.character(s()))
}

html_table <- function(df, digits = 3, max_rows = 300) {
  if (is.null(df) || !nrow(df)) {
    return(NULL)
  }
  more <- nrow(df) > max_rows
  df <- utils::head(df, max_rows)
  fmt <- lapply(df, function(v) {
    if (is.numeric(v)) ifelse(is.na(v), "", formatC(v, digits = digits, format = "fg")) else as.character(v)
  })
  h <- htmltools::tags
  htmltools::tagList(
    h$table(
      h$thead(h$tr(lapply(names(df), h$th))),
      h$tbody(lapply(seq_len(nrow(df)), function(i) h$tr(lapply(fmt, function(v) h$td(v[i])))))
    ),
    if (more) h$p(class = "note", sprintf("First %d rows shown.", max_rows))
  )
}

report_css <- "
:root { --bg:#f4f8f7; --surface:#ffffff; --text:#21403d; --muted:#4b6260; --teal:#0d9488; --amber:#b45309; --line:#dbe7e5; }
* { box-sizing: border-box; }
body { margin:0; background:var(--bg); color:var(--text); font:16px/1.6 'Manrope',system-ui,-apple-system,'Segoe UI',sans-serif; }
main { max-width: 62rem; margin: 0 auto; padding: 2rem 1rem 4rem; }
h1 { font-size: 2.2rem; line-height: 1.1; margin: 0 0 .25rem; font-weight: 800; letter-spacing: -.02em; }
h2 { font-size: 1.3rem; margin: 2.25rem 0 .75rem; padding-top: .75rem; border-top: 2px solid var(--teal); }
.lede { color: var(--muted); margin: 0 0 1.5rem; }
.facts { display:grid; grid-template-columns: repeat(auto-fit, minmax(9rem,1fr)); gap:.75rem; margin: 1rem 0; }
.fact { background:var(--surface); border:1px solid var(--line); border-left:4px solid var(--teal); border-radius:8px; padding:.65rem .9rem; }
.fact b { display:block; font-size:1.4rem; color:var(--teal); }
.fact span { font-size:.85rem; color:var(--muted); }
table { border-collapse: collapse; width: 100%; font-size: .82rem; background:var(--surface); margin:.5rem 0 1rem; }
th, td { border-bottom: 1px solid var(--line); padding: .3rem .5rem; text-align: left; }
th { background:#e6f2f0; }
.fig { background:var(--surface); border:1px solid var(--line); border-radius:8px; padding:.75rem; margin:.75rem 0; overflow:auto; }
.fig svg { max-width: 100%; height: auto; }
.fig svg text { font-family: 'Manrope', system-ui, sans-serif !important; }
.note { color: var(--muted); font-size: .9rem; }
pre { background:#0f2a2a; color:#d9ebe8; padding: 1rem; border-radius: 8px; overflow:auto; font-size:.8rem; }
footer { margin-top: 3rem; color: var(--muted); font-size: .85rem; }
a { color: var(--teal); }
"

fact <- function(value, label) {
  htmltools::div(class = "fact", htmltools::tags$b(value), htmltools::tags$span(label))
}

#' Write a self-contained HTML report
#'
#' @param res A list with any of `raw`, `data`, `qc`, `groups`, `map` and
#'   `qtl`, as produced by the app or by [run_analysis()].
#' @param settings The settings list.
#' @param path Output file.
#' @param title Report title.
#' @return `path`, invisibly.
#' @export
build_report <- function(res, settings = list(), path, title = "Linkmapper report") {
  h <- htmltools::tags
  d <- res$data %||% res$raw
  obj <- d$onemap
  sec <- list()
  sec$data <- htmltools::tagList(
    h$h2("Data"),
    htmltools::div(
      class = "facts",
      fact(cross_label(d$type), "population"), fact(obj$n.ind, "individuals"),
      fact(obj$n.mar, "markers"), fact(length(trait_names(d)), "traits")
    ),
    h$p(class = "note", paste0("Source: ", d$source$file %||% "not recorded", "."))
  )
  if (!is.null(d$filter)) {
    f <- d$filter
    sec$qc <- htmltools::tagList(
      h$h2("Quality control"),
      h$p(sprintf(
        "%d of %d markers kept (maximum missing rate %.2f%s).", f$after, f$before,
        f$settings$max_missing, if (isTRUE(f$settings$drop_distorted)) ", distorted markers removed" else ""
      )),
      if (length(f$removed)) h$p(class = "note", "Removed: ", paste(f$removed, collapse = ", "))
    )
  }
  if (!is.null(res$groups)) {
    g <- res$groups
    sec$groups <- htmltools::tagList(
      h$h2("Linkage groups"),
      h$p(sprintf(
        "Two-point analysis with LOD %.2f and maximum recombination fraction %.2f gave %d groups and %d unlinked markers.",
        g$lod, g$max_rf, nrow(g$table), length(g$unlinked)
      )),
      html_table(g$table)
    )
  }
  if (!is.null(res$map)) {
    m <- res$map
    sz <- map_plot_size(m)
    s <- map_summary(m)
    sec$map <- htmltools::tagList(
      h$h2("Linkage map"),
      h$p(sprintf(
        "Markers ordered with %s; distances from the %s mapping function. Total length %.1f cM.",
        order_label(m$method), tools::toTitleCase(m$map_fun), sum(s$length_cM)
      )),
      htmltools::div(class = "fig", svg_string(plot_linkage_map(m, res$qtl), sz[1], sz[2])),
      html_table(s),
      if (length(m$unplaced)) h$p(class = "note", "Not placed: ", paste(m$unplaced, collapse = ", ")),
      h$h3("Marker positions"),
      html_table(m$positions[, c("lg", "order", "marker", "position", "interval")])
    )
  }
  if (!is.null(res$qtl)) {
    q <- res$qtl
    sec$qtl <- htmltools::tagList(
      h$h2("QTL"),
      h$p(sprintf(
        "%s for %s (%s), %d permutations, genome-wide alpha %.2f: LOD threshold %.2f.",
        if (q$cim) "Composite interval mapping" else "Interval mapping", q$trait,
        names(qtl_methods())[match(q$method, qtl_methods())], q$n_perm, q$alpha, q$threshold
      )),
      htmltools::div(class = "fig", svg_string(plot_lod(q), 10, 4)),
      if (nrow(q$peaks)) html_table(q$peaks) else h$p("No QTL passed the threshold.")
    )
  }
  sec$settings <- htmltools::tagList(
    h$h2("Settings and software"),
    h$pre(paste(utils::capture.output(utils::str(settings, give.attr = FALSE, no.list = TRUE)), collapse = "\n")),
    h$p(class = "note", sprintf(
      "linkmapper %s, onemap %s, qtl %s, %s. Written %s.",
      utils::packageVersion("linkmapper"), utils::packageVersion("onemap"),
      utils::packageVersion("qtl"), R.version.string, format(Sys.time(), "%d %B %Y %H:%M")
    ))
  )
  body <- h$body(h$main(
    h$h1(title),
    h$p(class = "lede", paste0("Linkage mapping with Linkmapper, ", format(Sys.Date(), "%d %B %Y"), ".")),
    sec,
    h$footer(htmltools::HTML(paste0(
      "Linkmapper was created by Ebenezer Ogoe, Michael Obeng and Stephen Amoako. ",
      "Source: <a href=\"https://github.com/ebenogoe/linkmapper\">github.com/ebenogoe/linkmapper</a>."
    )))
  ))
  head <- paste0(
    "<head>\n<meta charset=\"utf-8\">\n<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n",
    "<title>", htmltools::htmlEscape(title), "</title>\n",
    "<link rel=\"stylesheet\" href=\"https://fonts.googleapis.com/css2?family=Manrope:wght@400..800&display=swap\">\n",
    "<style>", report_css, "</style>\n</head>"
  )
  writeLines(c("<!DOCTYPE html>", "<html lang=\"en\">", head, as.character(body), "</html>"), path, useBytes = TRUE)
  invisible(path)
}
