#' Linkmapper theme: teal and amber, Manrope
#' @noRd
lm_theme <- function() {
  sans <- bslib::font_collection(
    bslib::font_google("Manrope", wght = "400..800", local = FALSE),
    "system-ui", "-apple-system", "Segoe UI", "sans-serif"
  )
  mono <- bslib::font_collection("ui-monospace", "SF Mono", "Menlo", "Consolas", "monospace")
  bslib::bs_theme(
    version = 5,
    primary = "#0f766e", secondary = "#4b6260", success = "#0f766e",
    info = "#0e7490", warning = "#b45309", danger = "#b91c1c",
    base_font = sans, heading_font = sans, code_font = mono,
    "body-bg" = "#f4f8f7", "body-color" = "#21403d",
    "body-bg-dark" = "#0b1716", "body-color-dark" = "#d9ebe8",
    "link-color" = "#0f766e", "link-color-dark" = "#5eead4",
    "headings-font-weight" = 700,
    "border-radius" = "8px", "border-radius-sm" = "6px", "border-radius-lg" = "10px",
    "font-size-base" = "0.97rem"
  )
}

steps_def <- c(
  data = "Load data", qc = "Quality control", groups = "Linkage groups",
  order = "Marker order", map = "Linkage map", qtl = "QTL mapping", export = "Export"
)

step_header <- function(n, title, text) {
  shiny::div(
    class = "lm-step-head",
    shiny::span(class = "lm-kicker", sprintf("Step %d of %d", n, length(steps_def))),
    shiny::h2(title),
    shiny::p(class = "lm-lede", text)
  )
}

info <- function(..., title = NULL) {
  bslib::popover(
    shiny::tags$button(
      type = "button", class = "lm-info", `aria-label` = "More information",
      bsicons::bs_icon("question-circle")
    ),
    ...,
    title = title, options = list(trigger = "focus click")
  )
}

label_info <- function(label, ..., title = NULL) {
  shiny::tags$span(class = "lm-label", label, info(..., title = title))
}

stat_tile <- function(value, label, note = NULL) {
  shiny::div(
    class = "lm-stat",
    shiny::div(class = "lm-stat-value", value),
    shiny::div(class = "lm-stat-label", label),
    if (!is.null(note)) shiny::div(class = "lm-stat-note", note)
  )
}

stat_row <- function(...) shiny::div(class = "lm-stats", ...)

empty_state <- function(text, ...) {
  shiny::div(class = "lm-empty", bsicons::bs_icon("bar-chart-steps", size = "1.5rem"), shiny::p(text), ...)
}

download_menu <- function(ns, id, extra = NULL) {
  item <- function(suffix, label) {
    shiny::tags$li(shiny::downloadLink(ns(paste0(id, "_", suffix)), label, class = "dropdown-item"))
  }
  shiny::div(
    class = "dropdown lm-download",
    shiny::tags$button(
      type = "button", class = "btn btn-sm btn-outline-secondary dropdown-toggle",
      `data-bs-toggle` = "dropdown", `aria-expanded` = "false",
      bsicons::bs_icon("download"), shiny::span("Download")
    ),
    shiny::tags$ul(
      class = "dropdown-menu dropdown-menu-end",
      item("png", "PNG image (300 dpi)"), item("svg", "SVG (editable)"), item("pdf", "PDF"), extra
    )
  )
}

plot_card <- function(ns, id, title, footer = NULL, extra_menu = NULL, height = NULL) {
  bslib::card(
    full_screen = TRUE, class = "lm-plot-card",
    bslib::card_header(class = "lm-card-head", shiny::span(title), download_menu(ns, id, extra_menu)),
    bslib::card_body(ggiraph::girafeOutput(ns(id), height = height)),
    if (!is.null(footer)) bslib::card_footer(footer)
  )
}

plot_downloads <- function(output, id, plot_fn, name, width = 8, height = 6) {
  wh <- function(v) if (is.function(v)) v() else v
  save <- function(file, device) {
    ggplot2::ggsave(file, plot_fn(),
      width = wh(width), height = wh(height), dpi = 300,
      bg = "white", device = device, limitsize = FALSE
    )
  }
  output[[paste0(id, "_png")]] <- shiny::downloadHandler(function() paste0(name(), ".png"), function(file) save(file, "png"))
  output[[paste0(id, "_svg")]] <- shiny::downloadHandler(function() paste0(name(), ".svg"), function(file) save(file, svglite::svglite))
  output[[paste0(id, "_pdf")]] <- shiny::downloadHandler(function() paste0(name(), ".pdf"), function(file) save(file, grDevices::pdf))
  keep_downloads(output, paste0(id, c("_png", "_svg", "_pdf")))
}

# Download links inside a closed dropdown count as hidden; keep them active
keep_downloads <- function(output, ids) {
  for (i in ids) shiny::outputOptions(output, i, suspendWhenHidden = FALSE)
}

lm_girafe <- function(p, width = 8, height = 6, dark = FALSE, toolbar = TRUE) {
  tip_css <- sprintf(
    "background:%s;color:%s;padding:7px 11px;border-radius:8px;font-family:'Manrope',sans-serif;font-size:13px;max-width:300px;",
    if (dark) "#d9ebe8" else "#0f2a2a", if (dark) "#0b1716" else "#ffffff"
  )
  ggiraph::girafe(
    ggobj = p, width_svg = width, height_svg = height, bg = "transparent",
    options = list(
      ggiraph::opts_sizing(rescale = TRUE),
      ggiraph::opts_tooltip(css = tip_css, offx = 14, offy = 14, use_fill = FALSE),
      ggiraph::opts_hover(css = "stroke:#f59e0b;stroke-width:2.5px;fill:#b45309;"),
      ggiraph::opts_selection(type = "none"),
      if (toolbar) ggiraph::opts_zoom(min = 0.5, max = 6) else ggiraph::opts_zoom(min = 1, max = 1),
      if (toolbar) {
        ggiraph::opts_toolbar(position = "topright", saveaspng = FALSE, hidden = c("lasso_select", "lasso_deselect"))
      } else {
        ggiraph::opts_toolbar(saveaspng = FALSE, hidden = c("selection", "zoom", "misc"))
      }
    )
  )
}

safely <- function(expr, what = "that step") {
  tryCatch(
    withCallingHandlers(expr, warning = function(w) invokeRestart("muffleWarning")),
    error = function(e) {
      shiny::showNotification(
        shiny::tags$span(shiny::tags$b(sprintf("Could not complete %s.", what)), shiny::tags$br(), conditionMessage(e)),
        type = "error", duration = 15
      )
      NULL
    }
  )
}

next_button <- function(id, label) {
  shiny::actionButton(id, shiny::tagList(label, bsicons::bs_icon("arrow-right")), class = "btn-primary lm-next")
}

fmt_n <- function(x) format(x, big.mark = ",", scientific = FALSE, trim = TRUE)

lm_reactable <- function(df, ..., columns = list(), page_size = 15, digits = 3) {
  rownames(df) <- NULL
  num <- vapply(df, function(v) is.numeric(v) && any(abs(v - round(v)) > 1e-9, na.rm = TRUE), logical(1))
  cols <- lapply(names(df)[num], function(n) reactable::colDef(format = reactable::colFormat(digits = digits)))
  names(cols) <- names(df)[num]
  # Readable headers for the column names used across the app
  for (n in intersect(names(col_labels), names(df))) {
    base <- cols[[n]] %||% reactable::colDef()
    base$name <- col_labels[[n]]
    cols[[n]] <- base
  }
  cols[names(columns)] <- columns
  reactable::reactable(
    df, ...,
    columns = cols, defaultPageSize = page_size, compact = TRUE, highlight = TRUE,
    searchable = nrow(df) > 15, resizable = TRUE, wrap = FALSE,
    defaultColDef = reactable::colDef(minWidth = 90, headerClass = "lm-th", headerStyle = list(whiteSpace = "normal", verticalAlign = "bottom")),
    class = "lm-table", language = reactable::reactableLang(searchPlaceholder = "Search")
  )
}

col_labels <- c(
  lg = "Linkage group", order = "Order", marker = "Marker", position = "Position (cM)",
  interval = "Interval (cM)", markers = "Markers", length_cM = "Length (cM)",
  mean_spacing = "Mean spacing (cM)", largest_gap = "Largest gap (cM)", type = "Type",
  expected = "Expected ratio", missing = "Missing rate", chisq = "Chi-square", p_value = "p",
  distorted = "Distorted", group = "Group", n_markers = "Markers", individual = "Individual",
  lod = "LOD", interval_low = "Interval from (cM)", interval_high = "Interval to (cM)",
  nearest_marker = "Nearest marker", pve = "Variance explained (%)", additive = "Additive",
  dominance = "Dominance"
)
