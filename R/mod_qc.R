mod_qc_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    step_header(
      2, "Quality control",
      "Review missing data and segregation ratios, and set marker filters. Markers are removed only when filters are applied."
    ),
    shiny::uiOutput(ns("body"))
  )
}

mod_qc_server <- function(id, state, goto, dark) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    qc <- shiny::reactive({
      shiny::req(state$raw)
      qc_summary(state$raw)
    })

    output$body <- shiny::renderUI({
      if (is.null(state$raw)) {
        return(bslib::card(empty_state("Load data in step 1.", shiny::actionButton(ns("back"), "Go to step 1", class = "btn-outline-primary"))))
      }
      bslib::layout_columns(
        col_widths = bslib::breakpoints(sm = 12, lg = c(4, 8)),
        bslib::card(
          bslib::card_header("Filters"),
          shiny::sliderInput(ns("max_missing"),
            label_info(
              "Maximum missing rate per marker",
              "Markers missing in a larger proportion of individuals are removed. 0.25 is a common threshold for mapping populations."
            ),
            0, 1, 0.25,
            step = 0.05, width = "100%", ticks = FALSE
          ),
          shiny::checkboxInput(
            ns("drop_distorted"),
            label_info(
              "Remove distorted markers",
              "Markers whose genotype ratios deviate from the expected 1:2:1, 3:1 or 1:1 after Bonferroni correction. Distortion can reflect genotyping errors or real biology; review before removing."
            ),
            FALSE
          ),
          shiny::div(
            class = "lm-row-end",
            shiny::actionLink(ns("skip"), "Skip filtering"),
            shiny::actionButton(ns("apply"), "Apply filters", class = "btn-primary")
          )
        ),
        shiny::div(
          shiny::uiOutput(ns("result")),
          plot_card(ns, "seg", "Segregation tests",
            footer = shiny::span(class = "small lm-muted", "Dashed line: Bonferroni-corrected 5% threshold. Hover over a point for the marker.")
          ),
          plot_card(ns, "miss", "Missing genotypes"),
          bslib::card(full_screen = TRUE, bslib::card_header("Marker statistics"), reactable::reactableOutput(ns("markers")))
        )
      )
    })
    shiny::observeEvent(input$back, goto("data"))

    preview <- shiny::reactive({
      shiny::req(state$raw, input$max_missing)
      tryCatch(filter_markers(state$raw, input$max_missing, isTRUE(input$drop_distorted)), error = function(e) e)
    })

    output$result <- shiny::renderUI({
      f <- preview()
      q <- qc()
      applied <- state$data
      body <- if (inherits(f, "error")) {
        shiny::div(class = "alert alert-warning mb-0", conditionMessage(f))
      } else {
        stat_row(
          stat_tile(sprintf("%s / %s", f$filter$after, f$filter$before), "markers kept"),
          stat_tile(q$n_distorted, "distorted markers"),
          stat_tile(sprintf("%.1f%%", 100 * mean(q$markers$missing)), "mean missing rate")
        )
      }
      bslib::card(
        bslib::card_header(
          class = "lm-card-head", shiny::span("Filter preview"),
          if (!is.null(applied)) shiny::span(class = "badge lm-badge-done", "Applied")
        ),
        body,
        if (!is.null(applied)) {
          shiny::div(
            class = "lm-row-end",
            shiny::span(class = "lm-muted small", sprintf("Using %d markers.", applied$onemap$n.mar)),
            next_button(ns("next"), "Linkage groups")
          )
        }
      )
    })

    shiny::observeEvent(input$apply, {
      f <- safely(filter_markers(state$raw, input$max_missing, isTRUE(input$drop_distorted)), "filtering")
      if (is.null(f)) {
        return()
      }
      reset_after(state, "qc")
      state$data <- f
      set_setting(state, "filter", f$filter$settings)
      shiny::showNotification(sprintf("Filters applied: %d of %d markers kept.", f$filter$after, f$filter$before), type = "message")
    })
    shiny::observeEvent(input$skip, {
      reset_after(state, "qc")
      state$data <- state$raw
      set_setting(state, "filter", NULL)
      goto("groups")
    })
    shiny::observeEvent(input[["next"]], goto("groups"))

    output$seg <- ggiraph::renderGirafe(lm_girafe(plot_segregation(qc(), dark()), 9, 3.6, dark = dark()))
    plot_downloads(output, "seg", function() plot_segregation(qc()), function() "linkmapper_segregation", 9, 3.6)
    output$miss <- ggiraph::renderGirafe(lm_girafe(plot_missing(qc(), input$max_missing, dark()), 9, 3.2, dark = dark()))
    plot_downloads(output, "miss", function() plot_missing(qc(), input$max_missing), function() "linkmapper_missing", 9, 3.2)
    output$markers <- reactable::renderReactable({
      m <- qc()$markers
      lm_reactable(m, rowStyle = function(i) if (isTRUE(m$distorted[i])) list(background = "rgba(245, 158, 11, 0.14)"))
    })
  })
}
