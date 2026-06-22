# Scaffold only — server wiring pending
# Drop-in bslib replacement for the shinydashboard UI in app.R.
# All inputId / outputId values are identical to app.R so the server
# function can be attached without changes.

library(shiny)
library(shinyjs)
library(tools)
library(ggplot2)
library(onemap)
library(bslib)
library(waiter)

# ---------------------------------------------------------------------------
# Theme
# ---------------------------------------------------------------------------
linkmapper_theme <- bs_theme(
  version    = 5,
  primary    = "#3498db",
  fg         = "#222222",
  bg         = "#f4f6f9",
  base_font  = font_face(
    family = "defaultFont",
    src    = "url('Montserrat-Regular.otf')"
  ),
  # Darken the navbar to match the original #2c3e50 header
  "navbar-bg" = "#2c3e50",
  "navbar-light-color"         = "#ffffff",
  "navbar-light-hover-color"   = "#3498db",
  "navbar-light-active-color"  = "#3498db"
)

# ---------------------------------------------------------------------------
# Reusable card wrapper that mirrors old sidebarPanel / mainPanel split
# layout_sidebar() gives us a proper BS5 sidebar inside a card.
# ---------------------------------------------------------------------------

ui <- page_navbar(
  title  = tags$span(
    tags$img(src = "KNUST_logo.jpg", height = "30px",
             style = "margin-right:8px; vertical-align:middle;"),
    "LINKMAPPER"
  ),
  theme    = linkmapper_theme,
  fluid    = TRUE,
  bg       = "#2c3e50",
  inverse  = TRUE,
  collapsible = TRUE,

  # Inject custom CSS, shinyjs, and the workflow progress stepper.
  # The stepper sits between the navbar and the panel content on every page.
  # Step 1 (Upload) is active by default; the server will toggle .active/.done
  # via shinyjs::addClass() / shinyjs::removeClass() as the user progresses.
  header = tagList(
    tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "styler.css")),
    useShinyjs(),
    waiter::useWaiter(),
    tags$div(
      class = "lm-stepper",
      id    = "workflow-stepper",

      tags$div(
        class = "lm-step active", id = "lm-step-1",
        tags$div(class = "lm-step-circle", "1"),
        tags$span(class = "lm-step-label", icon("upload"), " Upload")
      ),
      tags$div(class = "lm-step-connector"),

      tags$div(
        class = "lm-step", id = "lm-step-2",
        tags$div(class = "lm-step-circle", "2"),
        tags$span(class = "lm-step-label", icon("layer-group"), " Group")
      ),
      tags$div(class = "lm-step-connector"),

      tags$div(
        class = "lm-step", id = "lm-step-3",
        tags$div(class = "lm-step-circle", "3"),
        tags$span(class = "lm-step-label", icon("arrow-down-1-9"), " Order")
      ),
      tags$div(class = "lm-step-connector"),

      tags$div(
        class = "lm-step", id = "lm-step-4",
        tags$div(class = "lm-step-circle", "4"),
        tags$span(class = "lm-step-label", icon("map"), " Map")
      )
    )
  ),

  # ── Welcome ────────────────────────────────────────────────────────────
  nav_panel(
    title = "Welcome",
    icon  = icon("house"),
    card(
      full_screen = FALSE,
      card_header(
        class = "bg-primary text-white",
        tags$h4("Welcome to Linkmapper", class = "mb-0")
      ),
      card_body(
        class = "text-center",
        tags$h5(
          tags$b("KWAME NKRUMAH UNIVERSITY OF SCIENCE AND TECHNOLOGY"),
          style = "font-size:20px;"
        ),
        tags$h6(
          "COLLEGE OF AGRICULTURE AND NATURAL RESOURCES",
          style = "font-size:16px;"
        ),
        tags$br(),
        fluidRow(
          column(6, tags$img(src = "KNUST_logo.jpg",   style = "width:20%; margin:auto; display:block;")),
          column(6, tags$img(src = "Faculty_logo.jpg", style = "width:20%; margin:auto; display:block;"))
        ),
        tags$br(),
        tags$h3(tags$b("LINKMAPPER")),
        tags$p("A simple tool for performing linkage mapping of molecular data."),
        tags$p(
          "This web app simplifies the process of performing segregation distortion tests,",
          "multipoint linkage analysis, and ultimately the generation of linkage maps from",
          "molecular data. With an intuitive user interface, a plethora of options, and a",
          "streamlined workflow, the user is assured of great flexibility and unparalleled",
          "control at each step.",
          style = "text-align:justify; max-width:700px; margin:auto;"
        ),
        tags$br(),
        tags$p(
          tags$small(
            "\u00a9 Copyright 2022, Project Genaxy | Ebenezer Ogoe | Michael Obeng | Stephen Amoako"
          )
        )
      )
    )
  ),

  # ── Prior Analysis ─────────────────────────────────────────────────────
  nav_panel(
    title = "Prior Analysis",
    icon  = icon("flask"),
    layout_sidebar(
      sidebar = sidebar(
        title = "Input parameters",
        width = 300,

        fileInput(
          inputId = "uploadTXT",
          label   = "Upload TXT file",
          accept  = ".txt"
        ),

        tags$h6("Options", class = "fw-bold mt-3"),

        radioButtons(
          inputId  = "missing_datapoints",
          label    = "Display missing datapoints plot",
          selected = 1,
          choices  = list("True" = 1, "False" = 0),
          inline   = TRUE
        ),

        radioButtons(
          inputId  = "seg_distort",
          label    = "Display segregation distortion plot",
          selected = 1,
          choices  = list("True" = 1, "False" = 0),
          inline   = TRUE
        ),

        actionButton(
          inputId = "submitTXT",
          label   = "Submit",
          class   = "btn btn-primary w-100 mt-2"
        ),

        hr(),

        tags$h6("Download options", class = "fw-bold"),
        downloadButton(outputId = "missingDatapoints", label = "Missing datapoints plot",
                       class = "btn btn-outline-secondary w-100 mb-2"),
        downloadButton(outputId = "segDistortion",     label = "Segregation distortion plot",
                       class = "btn btn-outline-secondary w-100")
      ),

      # Main output area
      card(
        card_header("Output"),
        card_body(
          verbatimTextOutput("general_info"),
          verbatimTextOutput("distorted_markers_info"),
          verbatimTextOutput("nondistorted_markers_info"),
          fluidRow(
            column(width = 6, plotOutput(outputId = "missing_datapoints_plot")),
            column(width = 6, plotOutput(outputId = "seg_distortion_plot"))
          )
        )
      )
    )
  ),

  # ── Marker Grouping ────────────────────────────────────────────────────
  nav_panel(
    title = "Marker Grouping",
    icon  = icon("layer-group"),
    layout_sidebar(
      sidebar = sidebar(
        title = "Input parameters",
        width = 300,

        sliderInput(
          inputId = "maxRF",
          label   = "Maximum recombination frequency",
          min = 0, max = 1, value = 0.5, step = 0.1
        ),

        radioButtons(
          inputId  = "lod_choice",
          label    = "LOD to use",
          selected = 1,
          choices  = list("Data-suggested" = 1, "User-defined" = 2)
        ),

        # Hidden until user selects "User-defined"
        shinyjs::hidden(
          numericInput(
            inputId = "user_lod_value",
            label   = "Choose LOD value",
            value = 3, min = 1, max = 10, step = 0.01
          )
        ),

        selectInput(
          inputId  = "map_func_type",
          label    = "Map function",
          selected = "kosambi",
          choices  = list("Haldane" = "haldane", "Kosambi" = "kosambi")
        ),

        actionButton(
          inputId = "make_groupings",
          label   = "Generate linkage groups",
          class   = "btn btn-primary w-100 mt-2"
        ),

        hr(),

        tags$h6("Two-point marker pair analysis", class = "fw-bold"),

        selectInput(
          inputId = "twopts_marker1",
          label   = "Select Marker 1",
          choices = c("One", "Two")
        ),
        selectInput(
          inputId = "twopts_marker2",
          label   = "Select Marker 2",
          choices = c("One", "Two")
        ),

        actionButton(
          inputId = "two_marker_analysis",
          label   = "Analyze markers",
          class   = "btn btn-outline-primary w-100"
        )
      ),

      card(
        card_header("Output"),
        card_body(
          verbatimTextOutput(outputId = "linkage_groups"),
          verbatimTextOutput(outputId = "twopts_output")
        )
      )
    )
  ),

  # ── Ordering ───────────────────────────────────────────────────────────
  nav_panel(
    title = "Ordering",
    icon  = icon("arrow-down-1-9"),
    layout_sidebar(
      sidebar = sidebar(
        title = "Input parameters",
        width = 300,

        radioButtons(
          inputId  = "order_LG",
          label    = "Ordering algorithm",
          selected = 1,
          choices  = list("RECORD" = 1, "RCD" = 2, "UNIDIRECTIONAL" = 3)
        ),

        numericInput(
          inputId = "lg_to_order",
          label   = "Linkage group to order",
          min = 1, max = 50, value = 1
        ),

        actionButton(
          inputId = "submit_lg_to_order",
          label   = "Order and map linkage group",
          class   = "btn btn-primary w-100 mt-2"
        )
      ),

      card(
        card_header("Output"),
        card_body(
          verbatimTextOutput(outputId = "lg_ordering")
        )
      )
    )
  ),

  # ── Linkage Mapping ────────────────────────────────────────────────────
  nav_panel(
    title = "Linkage Mapping",
    icon  = icon("map"),
    layout_sidebar(
      sidebar = sidebar(
        title = "Input parameters",
        width = 300,

        tags$h6("Linkage map settings", class = "fw-bold"),

        textInput(
          inputId     = "map_title",
          label       = "Title of map",
          placeholder = "Ex. Linkage map"
        ),

        textInput(
          inputId     = "group_prefix",
          label       = "Prefix of linkage group name",
          placeholder = "Ex. LG-"
        ),

        selectInput(
          inputId  = "LG_colour",
          label    = "Linkage group colour",
          selected = "grey",
          choices  = list(
            "Red" = "red", "Blue" = "blue", "Green" = "green",
            "Grey" = "grey", "Cyan" = "cyan", "Orange" = "orange"
          )
        ),

        actionButton(
          inputId = "generate_linkage_map",
          icon    = icon("map"),
          label   = span("Generate linkage map  ", id = "UpdateAnimate", class = ""),
          class   = "btn btn-primary w-100 mt-2"
        ),

        tags$br(),

        disabled(
          downloadButton(
            outputId = "downloadMap",
            label    = "Download map",
            class    = "btn btn-outline-secondary w-100"
          )
        ),

        tags$br(),

        tags$p(
          tags$small(
            tags$em(
              "Warning: Depending on the number of markers, individuals, and linkage groups,",
              "map generation may take from a few seconds to several minutes."
            )
          ),
          class = "text-muted mt-2"
        )
      ),

      card(
        card_header("Output"),
        card_body(
          # processing_status text element removed: the waiter overlay on
          # "elegant_plot" now handles the in-progress indication.
          imageOutput(outputId = "elegant_plot", width = "100%")
        )
      )
    )
  ),

  # Push Help and About to the right end of the navbar
  nav_spacer(),

  # ── Help ───────────────────────────────────────────────────────────────
  nav_panel(
    title = "Help",
    icon  = icon("circle-question"),
    card(
      card_header("How to use Linkmapper"),
      card_body(
        tags$ol(
          tags$li(
            tags$b("Prior Analysis (Step 1):"),
            " Upload a MAPMAKER/onemap-formatted TXT file. Review the missing",
            " datapoints plot and segregation distortion results to assess data quality."
          ),
          tags$li(
            tags$b("Marker Grouping (Step 2):"),
            " Set the maximum recombination frequency and LOD threshold, then generate",
            " linkage groups. Optionally inspect any marker pair with the two-point analysis."
          ),
          tags$li(
            tags$b("Ordering (Step 3):"),
            " Choose an ordering algorithm (RECORD, RCD, or UNIDIRECTIONAL) and order",
            " each linkage group individually to inspect marker order and distances."
          ),
          tags$li(
            tags$b("Linkage Mapping (Step 4):"),
            " Set a map title and group prefix, choose a colour scheme, then generate",
            " and download the final linkage map image."
          )
        ),
        tags$hr(),
        tags$p(
          tags$b("Input file format:"),
          " Linkmapper accepts the MAPMAKER/onemap text format for F2 intercross",
          " and backcross populations. A sample dataset is available from the",
          " onemap package documentation."
        ),
        tags$p(
          tags$b("Supported population types:"),
          " F2 intercross (current release). Backcross support is planned."
        )
      )
    )
  ),

  # ── About ──────────────────────────────────────────────────────────────
  nav_panel(
    title = "About",
    icon  = icon("circle-info"),
    card(
      card_header("About Linkmapper"),
      card_body(
        tags$h5("Linkmapper"),
        tags$p(
          "A GUI-based Shiny web application that wraps the ",
          tags$code("onemap"), " R package",
          " to perform linkage mapping and QTL visualisation on biparental",
          " mapping populations without writing any code."
        ),
        tags$hr(),
        tags$h6("Authors"),
        tags$ul(
          tags$li("Ogoe Ebenezer"),
          tags$li("Obeng Michael"),
          tags$li("Amoako Barnie Stephen")
        ),
        tags$h6("Institution"),
        tags$p(
          "Kwame Nkrumah University of Science and Technology (KNUST),",
          " College of Agriculture and Natural Resources, Ghana."
        ),
        tags$h6("Supervisor"),
        tags$p("Dr. Alexander W. Kena"),
        tags$hr(),
        tags$p(
          tags$small(
            "\u00a9 Copyright 2022, Project Genaxy. ",
            "Original context: Final-year undergraduate dissertation, KNUST, 2022."
          )
        )
      )
    )
  )

) # end page_navbar


# ---------------------------------------------------------------------------
# Server — ported from app.R with two waiter substitutions:
#   shinyjs::show("processing_status")  →  w$show()
#   shinyjs::hide("processing_status")  →  w$hide()
# Everything else is identical to app.R.
# ---------------------------------------------------------------------------
server <- function(input, output, session) {

  #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
  #                       Section 1. Global variables                        #
  #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
  rv <- reactiveValues(
    code_succeeded = FALSE,
    linkage_groups = NULL,
    f2data         = NULL,
    f2data_test    = NULL,
    two_point      = NULL,
    suggested_lod  = 0,
    map_path       = NULL
  )

  session$onSessionEnded(function() {
    if (!is.null(rv$map_path) && file.exists(rv$map_path))
      unlink(rv$map_path)
  })

  # Waiter scoped to the elegant_plot output element only (not the whole page).
  # w$show() overlays a spinner + message on the output card.
  # w$hide() dismisses it once renderImage() has written the PNG.
  w <- waiter::Waiter$new(
    id    = "elegant_plot",
    html  = tagList(
      waiter::spin_ring(),
      tags$p(
        "Generating linkage map\u2026 this may take a few minutes.",
        style = "color:#ffffff; margin-top:14px; font-size:14px; text-align:center;"
      )
    ),
    color = "rgba(44, 62, 80, 0.88)"
  )

  #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
  #                   Section 2. ObserveEvent() Expressions                  #
  #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
  observeEvent(input$make_groupings, {
    tryCatch({
      groupings()
    },
    warning = function(cond) {
      showNotification(paste("Fatal warning! Please check your submitted data/options and
                              try again.", cond), type = "warning", duration = 10)
    },
    error = function(cond) {
      showNotification(paste("An error occured! Please check your submitted data/options and
                              try again.", cond, sep = "\n"), type = "err", duration = 10)
    })
  })

  observeEvent(input$submit_lg_to_order, {
    tryCatch({
      orderLG()
    },
    warning = function(cond) {
      showNotification(paste("Fatal warning! Please check your submitted data/options and
                              try again.", cond), type = "warning", duration = 10)
    },
    error = function(cond) {
      showNotification(paste("An error occured! Please check your submitted data/options and
                              try again.", cond, sep = "\n"), type = "err", duration = 10)
    })
  })

  observeEvent(input$two_marker_analysis, {
    tryCatch({
      twoptsAnalysis()
    },
    warning = function(cond) {
      showNotification(paste("Fatal warning! Please check your submitted data/options and
                              try again.", cond), type = "warning", duration = 10)
    },
    error = function(cond) {
      showNotification(paste("An error occured! Please check your submitted data/options and
                              try again.", cond, sep = "\n"), type = "err", duration = 10)
    })
  })

  observeEvent(input$submitTXT, {
    shinyjs::disable(id = "downloadMap")
    file <- input$uploadTXT
    ext <- file_ext(file$datapath)
    req(file)
    validate(need(ext == "txt", "Please upload a Text (TXT) file!"))

    tryCatch({
      prior_analysis(file$datapath)
    },
    warning = function(cond) {
      showNotification(paste("Fatal warning! Please check your submitted data/options and
                              try again.", cond), type = "warning", duration = 10)
    },
    error = function(cond) {
      showNotification(paste("An error occured! Please check your submitted data/options and
                              try again.", cond, sep = "\n"), type = "err", duration = 10)
    })
  })

  observeEvent(input$generate_linkage_map, {
    w$show()                                              # was: shinyjs::show("processing_status")
    shinyjs::addClass(id = "UpdateAnimate", class = "loading dots")
    shinyjs::disable("generate_linkage_map")
    elegant_map_generator()
  })

  #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
  #              Section 3. Observe() Expressions and Downloaders            #
  #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
  observe({
    if (input$lod_choice == 1) {
      shinyjs::hide(id = "user_lod_value")
    } else {
      shinyjs::show(id = "user_lod_value")
    }
  })

  output$downloadMap <- downloadHandler(
    filename = function() { paste("Linkage map.png") },
    content  = function(file) { file.copy(rv$map_path, file) }
  )

  output$missingDatapoints <- downloadHandler(
    filename = function() { paste("Missing datapoints.png") },
    content  = function(file) {
      png(file, width = 900, height = 550)
      print(plot(rv$f2data))
      dev.off()
    }
  )

  output$segDistortion <- downloadHandler(
    filename = function() { paste("Segregation distortion.png") },
    content  = function(file) {
      png(file, width = 900, height = 550)
      print(plot(rv$f2data_test))
      dev.off()
    }
  )

  #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
  #                Section 4. Regular functions (the "workhorses")           #
  #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
  prior_analysis <- function(x) {
    rv$code_succeeded <- FALSE
    rv$f2data <- NULL

    rv$f2data <- tryCatch(
      read_mapmaker(file = x),
      error = function(e) {
        showNotification(
          paste("Could not read file. Is it a valid MAPMAKER/onemap input file?",
                conditionMessage(e)),
          type = "error", duration = 15
        )
        NULL
      }
    )
    if (is.null(rv$f2data)) return()

    if (!inherits(rv$f2data, "onemap")) {
      showNotification(
        "File was read but did not produce a valid onemap dataset. Please check the file format.",
        type = "error", duration = 15
      )
      rv$f2data <- NULL
      return()
    }

    if (rv$f2data$n.ind < 1 || rv$f2data$n.mar < 1) {
      showNotification(
        paste0(
          "Dataset is empty: ", rv$f2data$n.ind, " individual(s), ",
          rv$f2data$n.mar, " marker(s). Please check your input file."
        ),
        type = "error", duration = 15
      )
      rv$f2data <- NULL
      return()
    }

    output$general_info <- renderPrint({ rv$f2data })

    if (input$missing_datapoints == 1) {
      show(id = "missing_datapoints_plot")
      output$missing_datapoints_plot <- renderPlot({ plot(rv$f2data) })
    } else {
      hide(id = "missing_datapoints_plot")
    }

    rv$f2data_test <- test_segregation(rv$f2data)
    Bonferroni_alpha(rv$f2data_test)

    output$nondistorted_markers_info <- renderPrint({
      no_distortion <- select_segreg(rv$f2data_test, distorted = FALSE, numbers = TRUE)
      cat("Number of markers without segregation distortion:", length(no_distortion), "\n\n")
      cat("Markers:", no_distortion)
    })

    output$distorted_markers_info <- renderPrint({
      distortion <- select_segreg(rv$f2data_test, distorted = TRUE, numbers = TRUE)
      cat("Number of markers with segregation distortion:", length(distortion), "\n\n")
      cat("Markers:", distortion)
    })

    if (input$seg_distort == 1) {
      show(id = "seg_distortion_plot")
      output$seg_distortion_plot <- renderPlot({ plot(rv$f2data_test) })
    } else {
      hide(id = "seg_distortion_plot")
    }
  }

  groupings <- function(x) {
    if (is.null(rv$f2data)) {
      showNotification("Please upload and submit a valid data file first.",
                       type = "warning", duration = 8)
      return()
    }

    if (input$lod_choice == 1) {
      rv$suggested_lod <- suggest_lod(rv$f2data)
    } else if (input$lod_choice == 2) {
      rv$suggested_lod <- input$user_lod_value
    }

    set_map_fun(type = input$map_func_type)
    rv$two_point      <- rf_2pts(rv$f2data, LOD = rv$suggested_lod,
                                 max.rf = as.numeric(input$maxRF))
    Sequence_all_markers <- make_seq(rv$two_point, "all")
    rv$linkage_groups <- group(Sequence_all_markers)

    updateNumericInput(inputId = "lg_to_order", max = rv$linkage_groups$n.groups)
    updateSelectInput(inputId = "twopts_marker1", choices = colnames(rv$f2data$geno))
    updateSelectInput(inputId = "twopts_marker2", choices = colnames(rv$f2data$geno))

    output$linkage_groups <- renderPrint({ rv$linkage_groups })
    rv$code_succeeded <- TRUE
  }

  twoptsAnalysis <- function() {
    output$twopts_output <- renderPrint({
      print(rv$two_point, c(input$twopts_marker1, input$twopts_marker2))
    })
  }

  orderLG <- function() {
    if (is.null(rv$f2data)) {
      showNotification("Please upload and submit a valid data file first.",
                       type = "warning", duration = 8)
      return()
    }

    LGi <- make_seq(rv$linkage_groups, input$lg_to_order)

    if (input$order_LG == 1) {
      LGi_ord <- onemap::record(LGi, hmm = FALSE)
      LGi_map <- map(LGi_ord)
    } else if (input$order_LG == 2) {
      LGi_ord <- onemap::rcd(LGi, hmm = FALSE)
      LGi_map <- map(LGi_ord)
    } else {
      LGi_ord <- onemap::ug(LGi, hmm = FALSE)
      LGi_map <- map(LGi_ord)
    }

    output$lg_ordering <- renderPrint({ LGi_map })
  }

  elegant_map_generator <- function() {
    if (is.null(rv$f2data)) {
      showNotification("Please upload and submit a valid data file first.",
                       type = "warning", duration = 8)
      return()
    }

    if (isTRUE(rv$code_succeeded)) {

      n.groups        <- rv$linkage_groups$n.groups
      Gs_groups       <- vector("list", n.groups)   # fixed: was numeric()
      Gs_ords         <- vector("list", n.groups)
      Gs_maps         <- vector("list", n.groups)
      Gs_maps_final   <- vector("list", n.groups)

      for (i in 1:n.groups) {
        Gs_groups[[i]] <- make_seq(rv$linkage_groups, i)

        if (input$order_LG == 1) {
          Gs_ords[[i]] <- onemap::record(Gs_groups[[i]], hmm = FALSE)
        } else if (input$order_LG == 2) {
          Gs_ords[[i]] <- onemap::rcd(Gs_groups[[i]], hmm = FALSE)
        } else {
          Gs_ords[[i]] <- onemap::ug(Gs_groups[[i]], hmm = FALSE)
        }

        Gs_maps_final[[i]] <- map(Gs_ords[[i]])
      }

      rv$map_path <- tempfile(fileext = ".png")

      output$elegant_plot <- renderImage(deleteFile = FALSE, {

        if (!is.null(rv$map_path) && file.exists(rv$map_path))
          unlink(rv$map_path)

        draw_map2(Gs_maps_final, tag = "all",
                  main        = input$map_title,
                  group.names = paste0(input$group_prefix, 1:rv$linkage_groups$n.groups),
                  cex.label   = 0.5,
                  col.group   = input$LG_colour,
                  col.tag     = "black",
                  output      = rv$map_path)

        shinyjs::enable("generate_linkage_map")
        shinyjs::removeClass(id = "UpdateAnimate", class = "loading dots")
        w$hide()                                        # was: shinyjs::hide("processing_status")
        shinyjs::enable(id = "downloadMap")

        list(src = rv$map_path, height = "100%", width = "auto")
      })

    } else {
      output$general_info <- renderPrint({
        cat("Please upload a valid file and submit first!")
      })
    }
  }

}

shinyApp(ui = ui, server = server)
