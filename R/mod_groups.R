mod_groups_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    step_header(
      3, "Linkage groups",
      "Estimate pairwise recombination fractions and assign markers to linkage groups."
    ),
    shiny::uiOutput(ns("body"))
  )
}

mod_groups_server <- function(id, state, goto, lim) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    lod0 <- shiny::reactive({
      shiny::req(state$data)
      suggest_lod(state$data)
    })

    output$body <- shiny::renderUI({
      if (is.null(state$data)) {
        return(bslib::card(empty_state("Complete quality control in step 2.", shiny::actionButton(ns("back"), "Go to step 2", class = "btn-outline-primary"))))
      }
      prev <- shiny::isolate(state$settings$groups)
      bslib::layout_columns(
        col_widths = bslib::breakpoints(sm = 12, lg = c(4, 8)),
        bslib::card(
          bslib::card_header("Two-point analysis"),
          shiny::numericInput(ns("lod"),
            label_info(
              "LOD threshold",
              sprintf("Minimum LOD score for two markers to be considered linked. The suggested value (%.2f) adjusts for the number of marker pairs tested.", lod0())
            ),
            value = prev$lod %||% lod0(), min = 0.5, max = 20, step = 0.1, width = "100%"
          ),
          shiny::sliderInput(ns("max_rf"),
            label_info(
              "Maximum recombination fraction",
              "Marker pairs with a higher estimated recombination fraction are not considered linked. 0.5 means only the LOD threshold applies."
            ),
            0.05, 0.5, prev$max_rf %||% 0.5,
            step = 0.05, width = "100%", ticks = FALSE
          ),
          shiny::p(class = "lm-muted small", sprintf("Suggested LOD for this dataset: %.2f.", lod0())),
          shiny::actionButton(ns("go"), "Find linkage groups", class = "btn-primary w-100")
        ),
        shiny::uiOutput(ns("result"))
      )
    })
    shiny::observeEvent(input$back, goto("qc"))

    shiny::observeEvent(input$go, {
      d <- state$data
      shiny::req(d)
      g <- shiny::withProgress(message = "Running two-point analysis", value = 0.4, {
        safely(linkage_groups(d, input$lod, input$max_rf), "the two-point analysis")
      })
      if (is.null(g)) {
        return()
      }
      reset_after(state, "groups")
      state$groups <- g
      set_setting(state, "groups", list(lod = input$lod, max_rf = input$max_rf))
    })

    output$result <- shiny::renderUI({
      g <- state$groups
      if (is.null(g)) {
        return(bslib::card(empty_state("Set the thresholds and run the analysis.")))
      }
      tab <- g$table
      shiny::tagList(
        bslib::card(
          bslib::card_header(
            class = "lm-card-head", shiny::span(sprintf("%d linkage groups", nrow(tab))),
            shiny::span(class = "lm-muted small", sprintf("LOD %.2f, maximum rf %.2f", g$lod, g$max_rf))
          ),
          stat_row(
            stat_tile(nrow(tab), "linkage groups"),
            stat_tile(sum(tab$n_markers), "linked markers"),
            stat_tile(length(g$unlinked), "unlinked markers")
          ),
          if (length(g$unlinked)) shiny::p(class = "small lm-muted", "Unlinked: ", paste(g$unlinked, collapse = ", ")),
          if (any(tab$n_markers < 2)) {
            shiny::div(
              class = "alert alert-warning small mb-2",
              "Groups with a single marker cannot be ordered and will be reported as unplaced. A lower LOD threshold may join them to other groups."
            )
          },
          shiny::div(class = "lm-row-end", next_button(ns("next"), "Marker order"))
        ),
        bslib::card(full_screen = TRUE, bslib::card_header("Group membership"), reactable::reactableOutput(ns("table")))
      )
    })
    output$table <- reactable::renderReactable({
      shiny::req(state$groups)
      lm_reactable(state$groups$table, columns = list(markers = reactable::colDef(name = "Marker names", minWidth = 400, style = list(whiteSpace = "normal"))))
    })
    shiny::observeEvent(input[["next"]], goto("order"))
  })
}
