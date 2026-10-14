mod_qtl_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    step_header(
      6, "QTL mapping",
      "Scan the linkage map for quantitative trait loci, with a genome-wide significance threshold from permutations."
    ),
    shiny::uiOutput(ns("body"))
  )
}

mod_qtl_server <- function(id, state, goto, lim, dark) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    output$body <- shiny::renderUI({
      if (is.null(state$map)) {
        return(bslib::card(empty_state("Build the linkage map in steps 3 and 4.", shiny::actionButton(ns("back"), "Go to step 4", class = "btn-outline-primary"))))
      }
      tr <- trait_names(state$data)
      if (!length(tr)) {
        return(bslib::card(empty_state(
          "No traits loaded. Add a trait file in step 1.",
          shiny::actionButton(ns("back1"), "Go to step 1", class = "btn-outline-primary")
        )))
      }
      prev <- shiny::isolate(state$settings$qtl)
      bslib::layout_columns(
        col_widths = bslib::breakpoints(sm = 12, lg = c(4, 8)),
        bslib::card(
          bslib::card_header("Scan settings"),
          shiny::selectInput(ns("trait"), "Trait", tr, selected = prev$trait, width = "100%"),
          shiny::selectInput(ns("method"),
            label_info(
              "Method",
              shiny::p(shiny::tags$b("Haley-Knott regression: "), "fast and close to maximum likelihood for most data."),
              shiny::p(shiny::tags$b("Maximum likelihood (EM): "), "standard interval mapping (Lander and Botstein 1989)."),
              shiny::p(shiny::tags$b("Multiple imputation: "), "handles missing genotypes by simulation (Sen and Churchill 2001).")
            ),
            qtl_methods(),
            selected = prev$method %||% "hk", width = "100%"
          ),
          shiny::checkboxInput(
            ns("cim"),
            label_info(
              "Composite interval mapping",
              "Adds markers elsewhere in the genome as covariates to absorb background QTL effects (Zeng 1994). Permutations are slower."
            ),
            isTRUE(prev$cim)
          ),
          shiny::conditionalPanel("input.cim",
            ns = ns,
            shiny::numericInput(ns("n_marcovar"), "Marker covariates", prev$n_marcovar %||% 3, min = 1, max = 10, width = "100%"),
            shiny::numericInput(ns("window"), "Window (cM)", prev$window %||% 10, min = 1, max = 50, width = "100%")
          ),
          shiny::numericInput(ns("n_perm"),
            label_info("Permutations", "Number of trait permutations used to set the genome-wide LOD threshold (Churchill and Doerge 1994). 1,000 is standard."),
            prev$n_perm %||% 1000,
            min = 50, max = lim$max_perm, step = 50, width = "100%"
          ),
          shiny::selectInput(ns("alpha"), "Genome-wide significance", c("0.05" = 0.05, "0.10" = 0.10, "0.01" = 0.01),
            selected = prev$alpha %||% 0.05, width = "100%"
          ),
          shiny::numericInput(ns("seed"), "Random seed", prev$seed %||% 1, min = 1, step = 1, width = "100%"),
          shiny::actionButton(ns("go"), "Run QTL scan", class = "btn-primary w-100")
        ),
        shiny::uiOutput(ns("result"))
      )
    })
    shiny::observeEvent(input$back, goto("order"))
    shiny::observeEvent(input$back1, goto("data"))

    shiny::observeEvent(input$go, {
      shiny::req(state$map, state$data)
      n_perm <- min(max(50, as.integer(input$n_perm %||% 1000)), lim$max_perm)
      if (is.null(state$cross)) {
        state$cross <- safely(build_cross(state$data, state$map), "preparing the data for QTL mapping")
        if (is.null(state$cross)) {
          return()
        }
      }
      res <- shiny::withProgress(message = sprintf("Scanning %s with %d permutations", input$trait, n_perm), value = 0, {
        safely(scan_qtl(state$cross, input$trait, input$method, isTRUE(input$cim), input$n_marcovar %||% 3,
          input$window %||% 10, n_perm, as.numeric(input$alpha),
          seed = input$seed %||% 1,
          progress = function(p) shiny::setProgress(p)
        ), "the QTL scan")
      })
      if (is.null(res)) {
        return()
      }
      state$qtl <- res
      set_setting(state, "qtl", list(
        trait = input$trait, method = input$method, cim = isTRUE(input$cim),
        n_marcovar = input$n_marcovar %||% 3, window = input$window %||% 10,
        n_perm = n_perm, alpha = as.numeric(input$alpha), seed = input$seed %||% 1
      ))
    })

    output$result <- shiny::renderUI({
      r <- state$qtl
      if (is.null(r)) {
        return(bslib::card(empty_state("Select a trait and run the scan.")))
      }
      pk <- r$peaks
      shiny::tagList(
        bslib::card(
          bslib::card_header(
            class = "lm-card-head", shiny::span(sprintf("%s: %d QTL", r$trait, nrow(pk))),
            shiny::span(class = "lm-muted small", if (r$cim) "Composite interval mapping" else "Interval mapping")
          ),
          stat_row(
            stat_tile(nrow(pk), "QTL detected"),
            stat_tile(sprintf("%.2f", r$threshold), "LOD threshold", sprintf("%g%% genome-wide, %d permutations", 100 * r$alpha, r$n_perm)),
            if (nrow(pk)) stat_tile(sprintf("%.1f%%", max(pk$pve, na.rm = TRUE)), "largest effect", "variance explained")
          ),
          shiny::div(
            class = "lm-row-end",
            shiny::span(class = "lm-muted small", "QTL intervals are now drawn on the linkage map in step 5."),
            next_button(ns("next"), "Export")
          )
        ),
        plot_card(ns, "lod", "LOD profile"),
        if (nrow(pk)) {
          bslib::card(
            full_screen = TRUE,
            bslib::card_header(
              class = "lm-card-head", shiny::span("QTL"),
              shiny::div(
                class = "d-flex gap-2",
                shiny::downloadButton(ns("csv"), "CSV", class = "btn-sm btn-outline-secondary"),
                shiny::downloadButton(ns("xlsx"), "Excel", class = "btn-sm btn-outline-secondary")
              )
            ),
            reactable::reactableOutput(ns("peaks")),
            bslib::card_footer(shiny::span(
              class = "small lm-muted",
              "Interval: 1.5-LOD support interval. pve: percentage of phenotypic variance explained by a single-QTL model."
            ))
          )
        },
        if (nrow(pk)) {
          bslib::card(
            full_screen = TRUE,
            bslib::card_header(
              class = "lm-card-head", shiny::span("Effect at nearest marker"),
              shiny::div(
                class = "d-flex gap-2 align-items-center",
                shiny::selectInput(ns("eff_marker"), NULL, pk$nearest_marker, width = "8rem"),
                download_menu(ns, "eff")
              )
            ),
            ggiraph::girafeOutput(ns("eff"))
          )
        }
      )
    })
    lod_plot <- function(dark = FALSE) plot_lod(state$qtl, dark = dark)
    output$lod <- ggiraph::renderGirafe({
      shiny::req(state$qtl)
      lm_girafe(lod_plot(dark()), 10, 4, dark = dark())
    })
    plot_downloads(output, "lod", function() lod_plot(), function() paste0("linkmapper_lod_", state$qtl$trait), 10, 4)
    peaks_tab <- function() {
      p <- state$qtl$peaks
      lim <- 1 / state$qtl$n_perm
      p$p_value <- ifelse(p$p_value < lim, paste("<", signif(lim, 2)), formatC(p$p_value, format = "fg", digits = 2))
      p
    }
    output$peaks <- reactable::renderReactable({
      shiny::req(state$qtl)
      lm_reactable(peaks_tab())
    })
    output$csv <- shiny::downloadHandler(
      function() paste0("linkmapper_qtl_", state$qtl$trait, ".csv"),
      function(file) utils::write.csv(state$qtl$peaks, file, row.names = FALSE)
    )
    output$xlsx <- shiny::downloadHandler(
      function() paste0("linkmapper_qtl_", state$qtl$trait, ".xlsx"),
      function(file) writexl::write_xlsx(list(qtl = state$qtl$peaks, scan = state$qtl$scan), file)
    )
    eff_plot <- function(dark = FALSE) {
      mk <- input$eff_marker %||% state$qtl$peaks$nearest_marker[1]
      plot_effect(genotype_effect(state$qtl, mk), mk, state$qtl$trait, dark = dark)
    }
    output$eff <- ggiraph::renderGirafe({
      shiny::req(state$qtl, nrow(state$qtl$peaks) > 0)
      lm_girafe(eff_plot(dark()), 9, 3.6, dark = dark())
    })
    plot_downloads(output, "eff", function() eff_plot(), function() "linkmapper_effect", 6, 4.5)
    shiny::observeEvent(input[["next"]], goto("export"))
  })
}
