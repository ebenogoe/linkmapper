mod_map_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    step_header(5, "Linkage map", "Final map with marker positions. QTL intervals are added after QTL mapping."),
    shiny::uiOutput(ns("body"))
  )
}

mod_map_server <- function(id, state, goto, dark) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    output$body <- shiny::renderUI({
      m <- state$map
      if (is.null(m)) {
        return(bslib::card(empty_state("Order the markers in step 4.", shiny::actionButton(ns("back"), "Go to step 4", class = "btn-outline-primary"))))
      }
      has_traits <- length(trait_names(state$data)) > 0
      bslib::layout_columns(
        col_widths = bslib::breakpoints(sm = 12, lg = c(4, 8)),
        shiny::div(
          bslib::card(
            bslib::card_header("Display"),
            shiny::sliderInput(ns("label_size"), "Label size", 1.8, 4.5, 2.9, step = 0.1, width = "100%", ticks = FALSE),
            shiny::checkboxInput(ns("show_qtl"), "Show QTL intervals", TRUE),
            shiny::textInput(ns("title"), "Title", placeholder = "Optional", width = "100%")
          ),
          bslib::card(
            bslib::card_header("Summary"),
            reactable::reactableOutput(ns("summary")),
            shiny::div(
              class = "lm-row-end mt-2",
              if (has_traits) next_button(ns("next"), "QTL mapping") else next_button(ns("next_export"), "Export")
            )
          )
        ),
        shiny::div(
          plot_card(ns, "map", "Linkage map",
            extra_menu = shiny::tagList(
              shiny::tags$li(shiny::tags$hr(class = "dropdown-divider")),
              shiny::tags$li(shiny::downloadLink(ns("pos_csv"), "Positions (CSV)", class = "dropdown-item")),
              shiny::tags$li(shiny::downloadLink(ns("pos_xlsx"), "Positions (Excel)", class = "dropdown-item")),
              shiny::tags$li(shiny::downloadLink(ns("mapchart"), "MapChart file (.mct)", class = "dropdown-item"))
            ),
            footer = shiny::span(class = "small lm-muted", "Hover over a marker for its position. Scroll or use the toolbar to zoom.")
          ),
          bslib::card(full_screen = TRUE, bslib::card_header("Marker positions"), reactable::reactableOutput(ns("positions")))
        )
      )
    })
    shiny::observeEvent(input$back, goto("order"))
    shiny::observeEvent(input[["next"]], goto("qtl"))
    shiny::observeEvent(input$next_export, goto("export"))

    map_plot <- function(dark = FALSE) {
      plot_linkage_map(state$map, if (isTRUE(input$show_qtl)) state$qtl,
        dark = dark,
        label_size = input$label_size %||% 2.9, title = input$title
      )
    }
    output$map <- ggiraph::renderGirafe({
      shiny::req(state$map)
      sz <- map_plot_size(state$map)
      lm_girafe(map_plot(dark()), sz[1], sz[2], dark = dark())
    })
    plot_downloads(
      output, "map", function() map_plot(), function() "linkmapper_map",
      function() map_plot_size(state$map)[1], function() map_plot_size(state$map)[2]
    )
    output$summary <- reactable::renderReactable({
      shiny::req(state$map)
      lm_reactable(map_summary(state$map), page_size = 20)
    })
    output$positions <- reactable::renderReactable({
      shiny::req(state$map)
      lm_reactable(state$map$positions, page_size = 20)
    })
    output$pos_csv <- shiny::downloadHandler(
      function() "linkmapper_positions.csv",
      function(file) utils::write.csv(state$map$positions, file, row.names = FALSE)
    )
    output$pos_xlsx <- shiny::downloadHandler(
      function() "linkmapper_positions.xlsx",
      function(file) {
        writexl::write_xlsx(list(
          positions = state$map$positions,
          summary = map_summary(state$map)
        ), file)
      }
    )
    output$mapchart <- shiny::downloadHandler(
      function() "linkmapper_map.mct",
      function(file) {
        p <- state$map$positions
        out <- unlist(lapply(split(p, factor(p$lg, levels = unique(p$lg))), function(x) {
          c(paste("group", x$lg[1]), sprintf("%s %.2f", x$marker, x$position), "")
        }))
        writeLines(out, file)
      }
    )
    keep_downloads(output, c("pos_csv", "pos_xlsx", "mapchart"))
  })
}
