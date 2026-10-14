mod_home_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::div(
    class = "lm-home",
    shiny::tags$section(
      class = "lm-hero",
      ladder_svg(),
      shiny::div(
        class = "lm-hero-text",
        shiny::p(class = "lm-kicker", "Linkage mapping and QTL analysis"),
        shiny::h1("Link", shiny::span("mapper", .noWS = "outside")),
        shiny::p(
          class = "lm-hero-lede",
          "Build genetic linkage maps and locate QTL in F2, backcross and RIL populations. A point-and-click interface to onemap and R/qtl."
        ),
        shiny::div(
          class = "lm-hero-actions",
          shiny::actionButton(ns("go_upload"), shiny::tagList(bsicons::bs_icon("upload"), "Upload genotypes"),
            class = "btn-primary btn-lg"
          ),
          shiny::actionButton(ns("go_demo"), shiny::tagList(bsicons::bs_icon("play-circle"), "Open a demo"),
            class = "btn-outline-primary btn-lg"
          )
        ),
        shiny::p(class = "lm-hero-small", "Data are held for the current session only. Export a session file to resume later.")
      ),
      shiny::div(
        class = "lm-hero-figure",
        bslib::card(
          class = "lm-hero-card",
          bslib::card_header(
            class = "lm-card-head", shiny::span("F2 demo, three linkage groups"),
            shiny::span(class = "lm-muted small", "QTL intervals in amber")
          ),
          bslib::card_body(ggiraph::girafeOutput(ns("preview"), height = NULL))
        )
      )
    )
  )
}

mod_home_server <- function(id, goto, dark) {
  shiny::moduleServer(id, function(input, output, session) {
    pre <- list(
      positions = utils::read.csv(app_sys("extdata", "home_f2_map.csv")),
      peaks = utils::read.csv(app_sys("extdata", "home_f2_qtl.csv"))
    )
    output$preview <- ggiraph::renderGirafe({
      m <- list(positions = pre$positions)
      q <- list(peaks = pre$peaks, trait = "Trait_1")
      lm_girafe(plot_linkage_map(m, q, dark = dark(), label_size = 2.6), 7, 7, dark = dark(), toolbar = FALSE)
    })
    shiny::observeEvent(input$go_upload, {
      goto("data")
      bslib::nav_select("data-src", "upload", session = session$rootScope())
    })
    shiny::observeEvent(input$go_demo, {
      goto("data")
      bslib::nav_select("data-src", "demo", session = session$rootScope())
    })
  })
}

# Decorative linkage-group ladders behind the hero
ladder_svg <- function() {
  bar <- function(x, top, len, ticks, col, op) {
    t <- vapply(ticks, function(y) {
      sprintf(
        '<line x1="%s" x2="%s" y1="%s" y2="%s" stroke="%s" stroke-width="3"/>',
        x - 14, x + 14, top + y, top + y, col
      )
    }, character(1))
    paste0(sprintf(
      '<g opacity="%s"><rect x="%s" y="%s" width="20" height="%s" rx="10" fill="%s" fill-opacity="0.25" stroke="%s" stroke-width="2"/>',
      op, x - 10, top, len, col, col
    ), paste(t, collapse = ""), "</g>")
  }
  svg <- paste0(
    '<svg class="lm-ladders" viewBox="0 0 640 520" aria-hidden="true" focusable="false">',
    bar(90, 40, 360, c(20, 55, 70, 130, 170, 230, 250, 300, 340), "#0d9488", 0.35),
    bar(250, 100, 280, c(15, 60, 110, 125, 190, 240, 265), "#f59e0b", 0.4),
    bar(410, 20, 420, c(30, 80, 95, 150, 210, 260, 300, 330, 390), "#0d9488", 0.25),
    bar(570, 140, 300, c(25, 70, 140, 180, 210, 280), "#f59e0b", 0.3),
    "</svg>"
  )
  shiny::HTML(svg)
}
