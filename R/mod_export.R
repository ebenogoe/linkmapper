mod_export_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    step_header(7, "Export", "Download the HTML report, an R script that reproduces the analysis, or a session file."),
    shiny::uiOutput(ns("body"))
  )
}

mod_export_server <- function(id, state, goto) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    output$body <- shiny::renderUI({
      if (is.null(state$map)) {
        return(bslib::card(empty_state("Build the linkage map first.", shiny::actionButton(ns("back"), "Go to step 4", class = "btn-outline-primary"))))
      }
      bslib::layout_columns(
        col_widths = bslib::breakpoints(sm = 12, lg = c(5, 7)),
        shiny::div(
          bslib::card(
            bslib::card_header("Report"),
            shiny::p("Self-contained HTML file with the data summary, linkage groups, map, QTL results and settings. Opens in any browser and prints to PDF."),
            shiny::textInput(ns("title"), "Title", "Linkmapper report", width = "100%"),
            shiny::downloadButton(ns("report"), "Download report", class = "btn-primary w-100")
          ),
          bslib::card(
            bslib::card_header("R script"),
            shiny::p("Reproduces the analysis with the linkmapper package, using the same settings and seeds."),
            shiny::downloadButton(ns("script"), "Download R script", class = "btn-outline-primary w-100")
          ),
          bslib::card(
            bslib::card_header("Session file"),
            shiny::p("Genotypes, traits and settings, for reopening under Load data, Resume. No data are stored on the server."),
            shiny::downloadButton(ns("session"), "Download session file", class = "btn-outline-primary w-100")
          )
        ),
        bslib::card(
          full_screen = TRUE, bslib::card_header("R script preview"),
          shiny::textOutput(ns("script_text"), container = function(...) shiny::tags$pre(class = "lm-code", ...))
        )
      )
    })
    shiny::observeEvent(input$back, goto("order"))

    settings <- shiny::reactive({
      st <- state$settings
      keys <- c("filter", "groups", "order", "qtl")
      out <- stats::setNames(vector("list", length(keys)), keys)
      for (k in keys) if (!is.null(st[[k]])) out[k] <- list(st[[k]])
      out
    })
    source_info <- shiny::reactive({
      s <- state$raw$source
      list(demo = s$demo, file = if (is.null(s$demo)) s$file, traits = s$traits)
    })
    script_text <- shiny::reactive({
      shiny::req(state$raw)
      build_script(settings(), source_info())
    })
    output$script_text <- shiny::renderText(script_text())

    output$report <- shiny::downloadHandler(
      filename = function() paste0("linkmapper_report_", format(Sys.Date()), ".html"),
      content = function(file) {
        shiny::withProgress(message = "Writing the report", value = 0.5, {
          build_report(list(raw = state$raw, data = state$data, groups = state$groups, map = state$map, qtl = state$qtl),
            settings(), file,
            title = input$title %||% "Linkmapper report"
          )
        })
      }
    )
    output$script <- shiny::downloadHandler(function() "linkmapper_analysis.R", function(file) writeLines(script_text(), file))
    output$session <- shiny::downloadHandler(
      function() paste0("linkmapper_session_", format(Sys.Date()), ".json"),
      function(file) save_session(state$raw, settings(), file)
    )
  })
}
