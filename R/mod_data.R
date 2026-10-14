mod_data_ui <- function(id) {
  ns <- shiny::NS(id)
  demos <- demo_info()
  shiny::tagList(
    step_header(1, "Load data", "Upload a MAPMAKER or onemap genotype file, load a demo dataset, or resume a saved session."),
    bslib::layout_columns(
      col_widths = bslib::breakpoints(sm = 12, lg = c(5, 7)),
      shiny::div(
        bslib::card(
          bslib::card_header("Data source"),
          bslib::navset_underline(
            id = ns("src"),
            bslib::nav_panel(
              "Upload",
              value = "upload",
              shiny::div(
                class = "pt-3",
                shiny::fileInput(ns("file"),
                  label_info("Genotype file",
                    shiny::p("MAPMAKER (.raw, .txt) or onemap raw format. The first line states the population: 'data type f2 intercross', 'f2 backcross', 'ri self' or 'ri sib'."),
                    shiny::p("Codes: A, B and H (heterozygote); C (not BB) and D (not AA) for dominant markers; '-' for missing. Trait lines start with '*' like markers."),
                    title = "Accepted data formats"
                  ),
                  accept = c(".raw", ".txt"), placeholder = "No file chosen", width = "100%"
                ),
                shiny::downloadLink(ns("template"), shiny::tagList(bsicons::bs_icon("file-earmark-text"), "Example file (F2, MAPMAKER format)"))
              )
            ),
            bslib::nav_panel(
              "Demo data",
              value = "demo",
              shiny::div(
                class = "pt-3",
                shiny::radioButtons(ns("demo"), NULL,
                  choiceNames = lapply(seq_len(nrow(demos)), function(i) {
                    shiny::span(class = "lm-choice", shiny::tags$b(demos$title[i]), shiny::span(demos$description[i]))
                  }),
                  choiceValues = demos$name, width = "100%"
                ),
                shiny::actionButton(ns("load_demo"), shiny::tagList(bsicons::bs_icon("play-circle"), "Load demo"), class = "btn-primary")
              )
            ),
            bslib::nav_panel(
              "Resume",
              value = "resume",
              shiny::div(
                class = "pt-3",
                shiny::p("Open a session file exported from the Export step. All steps are rerun with the saved settings and seeds."),
                shiny::fileInput(ns("session"), "Session file (.json)", accept = ".json", width = "100%")
              )
            )
          )
        ),
        bslib::card(
          bslib::card_header(label_info(
            "Trait file (optional)",
            "CSV with one row per individual, in the same order as the genotype file, and one numeric column per trait. A first column named id, individual or ind is ignored. Replaces any traits in the genotype file."
          )),
          shiny::fileInput(ns("traits"), NULL, accept = ".csv", placeholder = "No file chosen", width = "100%"),
          shiny::uiOutput(ns("trait_status"))
        )
      ),
      shiny::div(
        shiny::div(id = ns("summary"), shiny::uiOutput(ns("summary_ui"))),
        bslib::card(full_screen = TRUE, bslib::card_header("Genotype preview"), shiny::uiOutput(ns("preview_ui")))
      )
    )
  )
}

mod_data_server <- function(id, state, goto, lim) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    set_data <- function(d) {
      if (d$onemap$n.mar > lim$max_markers) {
        shiny::showNotification(sprintf(
          "The hosted version accepts up to %s markers; this file has %s. Install the package to run it locally.",
          fmt_n(lim$max_markers), fmt_n(d$onemap$n.mar)
        ), type = "error", duration = 15)
        return(invisible(FALSE))
      }
      reset_after(state, "data")
      state$raw <- d
      state$settings <- list()
      state$loaded_at <- state$loaded_at + 1
      invisible(TRUE)
    }

    shiny::observeEvent(input$file, {
      d <- safely(read_cross(input$file$datapath, input$file$name), "reading the file")
      if (!is.null(d)) set_data(d)
    })
    shiny::observeEvent(input$load_demo, {
      d <- safely(linkmapper_demo(input$demo), "loading the demo")
      if (!is.null(d)) set_data(d)
    })
    shiny::observeEvent(input$traits, {
      shiny::req(state$raw)
      d <- safely(add_traits(state$raw, input$traits$datapath), "reading the trait file")
      if (is.null(d)) {
        return()
      }
      d$source$traits <- input$traits$name
      state$raw <- d
      if (!is.null(state$data)) {
        x <- state$data
        x$onemap$pheno <- d$onemap$pheno
        x$onemap$n.phe <- d$onemap$n.phe
        state$data <- x
      }
      state$cross <- NULL
      state$qtl <- NULL
    })

    shiny::observeEvent(input$session, {
      s <- safely(load_session(input$session$datapath), "opening the session file")
      if (is.null(s) || !set_data(s$data)) {
        return()
      }
      res <- shiny::withProgress(message = "Rebuilding the session", value = 0, {
        safely(
          run_analysis(s$data, s$settings, progress = function(msg) shiny::incProgress(0.2, detail = msg)),
          "rebuilding the session"
        )
      })
      if (is.null(res)) {
        return()
      }
      state$data <- res$data
      state$groups <- res$groups
      state$map <- res$map
      state$cross <- res$cross
      state$qtl <- res$qtl
      state$settings <- s$settings
      shiny::showNotification("Session restored. All steps were rerun.", type = "message")
      goto(if (!is.null(res$qtl)) "qtl" else if (!is.null(res$map)) "map" else "qc")
    })

    output$template <- shiny::downloadHandler(
      filename = function() "linkmapper_example_f2.raw",
      content = function(file) file.copy(system.file("extdata", "mapmaker_example_f2.raw", package = "onemap"), file)
    )

    output$trait_status <- shiny::renderUI({
      d <- state$raw
      if (is.null(d)) {
        return(shiny::p(class = "lm-muted small", "Load genotypes first."))
      }
      tr <- trait_names(d)
      if (!length(tr)) {
        return(shiny::p(class = "lm-muted small", "No traits. QTL mapping requires at least one."))
      }
      shiny::p(
        class = "small", bsicons::bs_icon("check-circle", class = "text-success"),
        sprintf(" %d trait%s: %s", length(tr), if (length(tr) > 1) "s" else "", paste(tr, collapse = ", "))
      )
    })

    output$summary_ui <- shiny::renderUI({
      d <- state$raw
      if (is.null(d)) {
        return(bslib::card(empty_state("Load a file or a demo dataset. View summary here.")))
      }
      obj <- d$onemap
      dom <- sum(obj$segr.type %in% c("C.A", "D.B"))
      bslib::card(
        bslib::card_header(
          class = "lm-card-head", shiny::span(d$source$file %||% "Data"),
          shiny::span(class = "badge lm-badge", cross_label(d$type))
        ),
        stat_row(
          stat_tile(fmt_n(obj$n.ind), "individuals"),
          stat_tile(fmt_n(obj$n.mar), "markers", if (dom) sprintf("%d dominant", dom)),
          stat_tile(sprintf("%.1f%%", 100 * mean(obj$geno == 0)), "missing genotypes"),
          stat_tile(length(trait_names(d)), "traits")
        ),
        shiny::div(class = "lm-row-end", next_button(ns("next"), "Quality control"))
      )
    })

    output$preview_ui <- shiny::renderUI({
      if (is.null(state$raw)) {
        return(shiny::p(class = "lm-muted p-3", "No data loaded."))
      }
      reactable::reactableOutput(ns("preview"))
    })
    output$preview <- reactable::renderReactable({
      d <- state$raw
      shiny::req(d)
      g <- d$onemap$geno
      keep <- seq_len(min(ncol(g), 30))
      lett <- vapply(keep, function(j) {
        l <- geno_letters[[d$onemap$segr.type[j]]]
        ifelse(g[, j] == 0, "-", l[pmax(1, g[, j])])
      }, character(nrow(g)))
      df <- data.frame(individual = seq_len(nrow(g)), lett, check.names = FALSE)
      names(df)[-1] <- colnames(g)[keep]
      if (!is.null(d$onemap$pheno)) df <- cbind(df[1], round(d$onemap$pheno, 3), df[-1])
      lm_reactable(df, page_size = 12)
    })

    shiny::observeEvent(input[["next"]], goto("qc"))
  })
}
