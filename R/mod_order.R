order_notes <- list(
  record = "Minimises the total number of recombination events along the group (Van Os et al. 2005). Performs well on most datasets.",
  rcd = "Builds the order by repeatedly adding the marker with the smallest recombination fraction to either end (Doerge 1996).",
  ug = "Grows the order in one direction from a starting pair, using the recombination fractions (Tan and Fu 2006).",
  seriation = "Orders markers so that recombination fractions increase away from the diagonal (Buetow and Chakravarti 1987)."
)

mod_order_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    step_header(4, "Marker order", "Order the markers within each linkage group and estimate map distances."),
    shiny::uiOutput(ns("body"))
  )
}

mod_order_server <- function(id, state, goto, dark) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    output$body <- shiny::renderUI({
      if (is.null(state$groups)) {
        return(bslib::card(empty_state("Find linkage groups in step 3.", shiny::actionButton(ns("back"), "Go to step 3", class = "btn-outline-primary"))))
      }
      prev <- shiny::isolate(state$settings$order)
      bslib::layout_columns(
        col_widths = bslib::breakpoints(sm = 12, lg = c(4, 8)),
        bslib::card(
          bslib::card_header("Ordering"),
          shiny::selectInput(ns("method"), "Algorithm", order_methods(), selected = prev$method %||% "record", width = "100%"),
          shiny::uiOutput(ns("note")),
          shiny::radioButtons(ns("map_fun"),
            label_info(
              "Mapping function",
              shiny::p(shiny::tags$b("Kosambi: "), "allows for crossover interference. Standard for most plant mapping studies."),
              shiny::p(shiny::tags$b("Haldane: "), "assumes no interference.")
            ),
            c("Kosambi" = "kosambi", "Haldane" = "haldane"),
            selected = prev$map_fun %||% "kosambi", inline = TRUE
          ),
          shiny::numericInput(ns("seed"), label_info("Random seed", "RECORD and UG start from random orders. A fixed seed makes the result repeatable."),
            prev$seed %||% 1,
            min = 1, step = 1, width = "100%"
          ),
          shiny::actionButton(ns("go"), "Order markers", class = "btn-primary w-100")
        ),
        shiny::uiOutput(ns("result"))
      )
    })
    shiny::observeEvent(input$back, goto("groups"))
    output$note <- shiny::renderUI({
      shiny::req(input$method)
      shiny::p(class = "lm-note", order_notes[[input$method]])
    })

    shiny::observeEvent(input$go, {
      g <- state$groups
      shiny::req(g)
      m <- shiny::withProgress(message = sprintf("Ordering %d linkage groups", nrow(g$table)), value = 0, {
        safely(order_groups(g, input$method, input$map_fun,
          seed = input$seed %||% 1,
          progress = function(p) shiny::setProgress(p)
        ), "ordering")
      })
      if (is.null(m)) {
        return()
      }
      reset_after(state, "order")
      state$map <- m
      set_setting(state, "order", list(method = input$method, map_fun = input$map_fun, seed = input$seed %||% 1))
    })

    output$result <- shiny::renderUI({
      m <- state$map
      if (is.null(m)) {
        return(bslib::card(empty_state("Select an algorithm and order the markers. Ordering can take a minute for large groups.")))
      }
      s <- map_summary(m)
      shiny::tagList(
        bslib::card(
          bslib::card_header(
            class = "lm-card-head", shiny::span(order_label(m$method)),
            shiny::span(class = "lm-muted small", paste(tools::toTitleCase(m$map_fun), "mapping function"))
          ),
          stat_row(
            stat_tile(nrow(s), "linkage groups"), stat_tile(sum(s$markers), "markers placed"),
            stat_tile(sprintf("%.1f cM", sum(s$length_cM)), "total length")
          ),
          if (length(m$unplaced)) shiny::p(class = "small lm-muted", "Not placed: ", paste(m$unplaced, collapse = ", ")),
          shiny::div(class = "lm-row-end", next_button(ns("next"), "Linkage map"))
        ),
        bslib::card(
          full_screen = TRUE,
          bslib::card_header(
            class = "lm-card-head", shiny::span("Recombination fractions"),
            shiny::div(
              class = "d-flex gap-2 align-items-center",
              shiny::selectInput(ns("lg"), NULL, names(m$maps), width = "8rem"),
              download_menu(ns, "rf")
            )
          ),
          ggiraph::girafeOutput(ns("rf")),
          bslib::card_footer(shiny::span(class = "small lm-muted", "Markers in map order. Dark cells indicate tight linkage; a dark band along the diagonal indicates a consistent order."))
        )
      )
    })
    rf_plot <- function(dark = FALSE) plot_rf_heatmap(state$map, input$lg %||% "LG1", dark = dark)
    rf_size <- function() {
      n <- length(state$map$maps[[input$lg %||% "LG1"]]$seq.num)
      s <- min(12, max(5, n * 0.28 + 1.5))
      c(s + 1.2, s)
    }
    output$rf <- ggiraph::renderGirafe({
      shiny::req(state$map, input$lg)
      sz <- rf_size()
      lm_girafe(rf_plot(dark()), sz[1], sz[2], dark = dark())
    })
    plot_downloads(
      output, "rf", function() rf_plot(), function() paste0("linkmapper_rf_", input$lg),
      function() rf_size()[1], function() rf_size()[2]
    )
    shiny::observeEvent(input[["next"]], goto("map"))
  })
}
