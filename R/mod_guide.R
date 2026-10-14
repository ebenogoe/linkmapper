mod_guide_ui <- function(id) {
  ns <- shiny::NS(id)
  ref <- function(...) shiny::tags$li(...)
  row <- function(a, b, c) shiny::tags$tr(shiny::tags$td(a), shiny::tags$td(b), shiny::tags$td(c))
  shiny::div(
    class = "lm-page",
    shiny::p(class = "lm-kicker", "Guide"),
    shiny::h1("Using Linkmapper"),
    shiny::p(class = "lm-lede", "Workflow, accepted data formats, method notes and references."),
    shiny::div(
      class = "lm-guide-actions",
      shiny::actionButton(ns("tour"), shiny::tagList(bsicons::bs_icon("signpost-split"), "Take the tour"), class = "btn-primary"),
      shiny::actionButton(ns("demo"), "Open a demo", class = "btn-outline-primary")
    ),
    shiny::tags$section(
      class = "lm-section",
      shiny::h2("Workflow"),
      shiny::tags$ol(
        class = "lm-flow",
        shiny::tags$li(shiny::tags$b("Load data. "), "MAPMAKER or onemap genotype file, with an optional trait CSV."),
        shiny::tags$li(shiny::tags$b("Quality control. "), "Missing data and chi-square segregation tests with Bonferroni correction; marker filters."),
        shiny::tags$li(shiny::tags$b("Linkage groups. "), "Two-point recombination fractions and LOD scores; grouping by LOD and maximum recombination fraction."),
        shiny::tags$li(shiny::tags$b("Marker order. "), "RECORD, RCD, UG or seriation within each group; Kosambi or Haldane distances; recombination-fraction heatmaps."),
        shiny::tags$li(shiny::tags$b("Linkage map. "), "Interactive map with positions, group summaries and exports including MapChart."),
        shiny::tags$li(shiny::tags$b("QTL mapping. "), "Interval or composite interval mapping with permutation thresholds, support intervals and effects."),
        shiny::tags$li(shiny::tags$b("Export. "), "HTML report, R script and session file.")
      )
    ),
    shiny::tags$section(
      class = "lm-section",
      shiny::h2("Accepted data formats"),
      shiny::div(class = "lm-table-wrap", shiny::tags$table(
        class = "table lm-formats",
        shiny::tags$thead(shiny::tags$tr(shiny::tags$th("Population"), shiny::tags$th("Header line"), shiny::tags$th("Genotype codes"))),
        shiny::tags$tbody(
          row("F2 intercross", "data type f2 intercross", "A, H, B; C (not BB), D (not AA); - missing"),
          row("Backcross", "data type f2 backcross", "A, H; - missing"),
          row("RIL, selfing", "data type ri self", "A, B; - missing"),
          row("RIL, sib mating", "data type ri sib", "A, B; - missing")
        )
      )),
      shiny::p(class = "lm-muted", "Files can be in MAPMAKER format (second line: individuals, markers, traits) or onemap raw format. Traits can be included as '*Trait' lines or uploaded separately as a CSV with one row per individual in file order.")
    ),
    bslib::accordion(
      id = ns("acc"), multiple = TRUE, open = FALSE,
      bslib::accordion_panel(
        "Choosing thresholds",
        icon = bsicons::bs_icon("sliders"),
        shiny::tags$dl(
          class = "lm-dl",
          shiny::tags$dt("LOD threshold"),
          shiny::tags$dd("The suggested value from onemap accounts for the number of marker pairs tested. Raise it if unrelated groups merge; lower it if real groups split or many markers stay unlinked."),
          shiny::tags$dt("Maximum recombination fraction"),
          shiny::tags$dd("0.5 leaves grouping to the LOD threshold. Values of 0.35 to 0.4 are stricter."),
          shiny::tags$dt("Segregation distortion"),
          shiny::tags$dd("Distorted markers are flagged after Bonferroni correction. Removing them is optional: distortion can come from genotyping error, but also from selection or gametic effects."),
          shiny::tags$dt("Permutations"),
          shiny::tags$dd("1,000 permutations give a stable 5% threshold. Composite interval mapping permutations are slower; 100 to 200 are usually adequate for exploration.")
        )
      ),
      bslib::accordion_panel(
        "Limits of the hosted version",
        icon = bsicons::bs_icon("cloud"),
        shiny::p("The shinyapps.io copy accepts files up to 20 MB, 1,500 markers and 1,000 permutations. Data are held in memory for the session only. Install the package to run larger analyses locally:"),
        shiny::tags$pre(class = "lm-code", 'install.packages("linkmapper", repos = c("https://ebenogoe.r-universe.dev", "https://cloud.r-project.org"))\nlinkmapper::run_app()')
      ),
      bslib::accordion_panel(
        "References",
        icon = bsicons::bs_icon("journal-text"),
        shiny::tags$ul(
          class = "lm-refs",
          ref("Broman, K. W., Wu, H., Sen, S. and Churchill, G. A. (2003). R/qtl: QTL mapping in experimental crosses. Bioinformatics 19, 889 to 890."),
          ref("Buetow, K. H. and Chakravarti, A. (1987). Multipoint gene mapping using seriation. American Journal of Human Genetics 41, 180 to 188."),
          ref("Churchill, G. A. and Doerge, R. W. (1994). Empirical threshold values for quantitative trait mapping. Genetics 138, 963 to 971."),
          ref("Doerge, R. W. (1996). Constructing genetic maps by rapid chain delineation. Journal of Quantitative Trait Loci 2, 121 to 132."),
          ref("Haley, C. S. and Knott, S. A. (1992). A simple regression method for mapping quantitative trait loci in line crosses using flanking markers. Heredity 69, 315 to 324."),
          ref("Kosambi, D. D. (1944). The estimation of map distances from recombination values. Annals of Eugenics 12, 172 to 175."),
          ref("Lander, E. S. and Botstein, D. (1989). Mapping Mendelian factors underlying quantitative traits using RFLP linkage maps. Genetics 121, 185 to 199."),
          ref("Margarido, G. R. A., Souza, A. P. and Garcia, A. A. F. (2007). OneMap: software for genetic mapping in outcrossing species. Hereditas 144, 78 to 79."),
          ref("Sen, S. and Churchill, G. A. (2001). A statistical framework for quantitative trait mapping. Genetics 159, 371 to 387."),
          ref("Taniguti, C. H. and others (2023). Developing best practices for genotyping-by-sequencing analysis in the construction of linkage maps. GigaScience 12, giad092."),
          ref("Tan, Y. and Fu, Y. (2006). A novel method for estimating linkage maps. Genetics 173, 2383 to 2390."),
          ref("Van Os, H., Stam, P., Visser, R. G. F. and Van Eck, H. J. (2005). RECORD: a novel method for ordering loci on a genetic linkage map. Theoretical and Applied Genetics 112, 30 to 40."),
          ref("Zeng, Z.-B. (1994). Precision mapping of quantitative trait loci. Genetics 136, 1457 to 1468.")
        )
      )
    )
  )
}

mod_guide_server <- function(id, goto, start_tour) {
  shiny::moduleServer(id, function(input, output, session) {
    shiny::observeEvent(input$tour, start_tour())
    shiny::observeEvent(input$demo, {
      goto("data")
      bslib::nav_select("data-src", "demo", session = session$rootScope())
    })
  })
}
