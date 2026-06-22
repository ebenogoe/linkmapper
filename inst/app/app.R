library(shiny)
library(shinyjs)
library(waiter)
library(tools)
library(ggplot2)
library(onemap)
library(qtl)
library(plotly)
library(bslib)
library(bsicons)

lm_theme <- bslib::bs_theme(
  version      = 5,
  bg           = "#fafafa",
  fg           = "#111827",
  primary      = "#0d9488",
  secondary    = "#e5e7eb",
  success      = "#0d9488",
  warning      = "#f97316",
  info         = "#0369a1",
  base_font    = bslib::font_google("Nunito Sans"),
  heading_font = bslib::font_google("Nunito"),
  font_scale   = 0.95
)

# Stepper UI component
lm_stepper <- function(active_step = 1) {
  steps <- list(
    list(n = 1, label = "Upload & analyse"),
    list(n = 2, label = "Group markers"),
    list(n = 3, label = "Order groups"),
    list(n = 4, label = "Linkage map"),
    list(n = 5, label = "QTL analysis")
  )

  step_items <- lapply(seq_along(steps), function(i) {
    s <- steps[[i]]
    state <- if (s$n < active_step) "done" else if (s$n == active_step) "active" else "locked"

    circle_content <- if (state == "done") {
      tags$svg(
        xmlns = "http://www.w3.org/2000/svg",
        width = "16", height = "16", viewBox = "0 0 20 20",
        fill = "none", stroke = "currentColor",
        `stroke-width` = "2.5", `stroke-linecap` = "round",
        `stroke-linejoin` = "round",
        tags$polyline(points = "4,10 8,14 16,6")
      )
    } else if (state == "locked") {
      tags$svg(
        xmlns = "http://www.w3.org/2000/svg",
        width = "14", height = "14", viewBox = "0 0 20 20",
        fill = "none", stroke = "currentColor",
        `stroke-width` = "1.6", `stroke-linecap` = "round",
        `stroke-linejoin` = "round",
        tags$rect(x = "5", y = "9", width = "10", height = "8", rx = "2"),
        tags$path(d = "M7 9 V7 a3 3 0 0 1 6 0 v2")
      )
    } else {
      as.character(s$n)
    }

    tags$div(
      class = paste("lm-step", state),
      tags$div(class = "lm-step-circle", circle_content),
      tags$div(class = "lm-step-label",
        paste0(s$n, " \u00b7 ", s$label)
      )
    )
  })

  tags$div(
    class = "lm-stepper-wrap",
    tags$div(class = "lm-stepper", step_items)
  )
}

# Standard module layout: left param panel + right output panel
lm_module_layout <- function(sidebar_content, output_content,
                               active_step = 1) {
  tagList(
    lm_stepper(active_step),
    tags$div(
      class = "lm-main",
      tags$div(class = "lm-sidebar", sidebar_content),
      tags$div(class = "lm-output-panel", output_content)
    )
  )
}

# Inline SVG icon helper
lm_icon <- function(id, size = 16) {
  icon_paths <- list(
    arrow  = tagList(
               tags$polyline(points = "3,10 17,10"),
               tags$polyline(points = "11,4 17,10 11,16")
             ),
    dna    = tagList(
               tags$path(d = "M6 2 C6 2 14 6 14 10 C14 14 6 18 6 18"),
               tags$path(d = "M14 2 C14 2 6 6 6 10 C6 14 14 18 14 18"),
               tags$line(x1="7.5", y1="5.5",  x2="12.5", y2="5.5"),
               tags$line(x1="7",   y1="10",   x2="13",   y2="10"),
               tags$line(x1="7.5", y1="14.5", x2="12.5", y2="14.5")
             ),
    chart  = tagList(
               tags$polyline(points = "2,15 6,9 10,12 14,5 18,8"),
               tags$line(x1="2", y1="17", x2="18", y2="17"),
               tags$line(x1="2", y1="4",  x2="2",  y2="17")
             ),
    dl     = tagList(
               tags$line(x1="10", y1="3",  x2="10", y2="13"),
               tags$polyline(points = "6,9 10,13 14,9"),
               tags$path(d = "M3 15 L3 17 L17 17 L17 15")
             ),
    upload = tagList(
               tags$line(x1="10", y1="13", x2="10", y2="3"),
               tags$polyline(points = "6,7 10,3 14,7"),
               tags$path(d = "M3 15 L3 17 L17 17 L17 15")
             ),
    file   = tagList(
               tags$path(d = "M12 2 H5 a1 1 0 0 0 -1 1 v14 a1 1 0 0 0 1 1 h10 a1 1 0 0 0 1 -1 V6 Z"),
               tags$polyline(points = "12,2 12,6 16,6"),
               tags$line(x1="7", y1="10", x2="13", y2="10"),
               tags$line(x1="7", y1="13", x2="11", y2="13")
             ),
    layers = tagList(
               tags$polygon(points = "10,2 18,6 10,10 2,6"),
               tags$polyline(points = "2,10 10,14 18,10"),
               tags$polyline(points = "2,14 10,18 18,14")
             ),
    sort   = tagList(
               tags$line(x1="4", y1="5",  x2="16", y2="5"),
               tags$line(x1="4", y1="10", x2="12", y2="10"),
               tags$line(x1="4", y1="15", x2="8",  y2="15")
             ),
    map    = tagList(
               tags$polyline(points = "7,3 7,17"),
               tags$polyline(points = "13,3 13,17"),
               tags$line(x1="4",  y1="5",  x2="7",  y2="5"),
               tags$line(x1="7",  y1="9",  x2="13", y2="9"),
               tags$line(x1="13", y1="13", x2="16", y2="13"),
               tags$line(x1="4",  y1="3",  x2="4",  y2="17"),
               tags$line(x1="16", y1="3",  x2="16", y2="17")
             ),
    check  = tags$polyline(points = "4,10 8,14 16,6"),
    info   = tagList(
               tags$circle(cx="10", cy="10", r="8"),
               tags$line(x1="10", y1="9",   x2="10", y2="14"),
               tags$circle(cx="10", cy="6.5", r="0.8",
                 fill="currentColor", stroke="none")
             ),
    leaf   = tagList(
               tags$path(d = "M17 3 C17 3 10 3 6 7 C2 11 3 17 3 17 C3 17 9 18 13 14 C17 10 17 3 17 3 Z"),
               tags$line(x1="3", y1="17", x2="10", y2="10")
             ),
    play   = tagList(
               tags$circle(cx="10", cy="10", r="8"),
               tags$polygon(points = "8,7 14,10 8,13",
                 fill="currentColor", stroke="none")
             )
  )

  tags$svg(
    xmlns             = "http://www.w3.org/2000/svg",
    width             = size, height = size,
    viewBox           = "0 0 20 20",
    fill              = "none",
    stroke            = "currentColor",
    `stroke-width`    = "1.6",
    `stroke-linecap`  = "round",
    `stroke-linejoin` = "round",
    style             = "display:inline-flex;vertical-align:middle;flex-shrink:0;",
    icon_paths[[id]]
  )
}

# Info card helper
lm_info_card <- function(icon_id, accent = "sage", title, desc) {
  accent_class <- paste0("lm-info-icon-", accent)
  tags$div(
    class = "lm-info-card",
    tags$div(class = paste("lm-info-icon", accent_class),
      lm_icon(icon_id, size = 20)
    ),
    tags$div(class = "lm-info-card-title", title),
    tags$div(class = "lm-info-card-desc",  desc)
  )
}

# FAQ item
lm_faq <- function(question, answer) {
  tags$div(
    class = "lm-faq-item",
    tags$div(class = "lm-faq-q",
      lm_icon("info", 13), tags$span(question)
    ),
    tags$div(class = "lm-faq-a", answer)
  )
}

# About info card
lm_about_card <- function(label, value) {
  tags$div(
    class = "lm-param-card",
    tags$div(class = "lm-param-label", label),
    tags$div(class = "lm-param-value", value)
  )
}

# Author card
lm_author_card <- function(initials, name) {
  tags$div(
    class = "lm-author-card",
    tags$div(class = "lm-author-avatar", initials),
    tags$div(class = "lm-author-name", name)
  )
}

ui <- bslib::page_navbar(
  theme  = lm_theme,
  title  = tags$div(
    class = "lm-brand",
    tags$div(
      class = "lm-brand-icon",
      tags$svg(
        xmlns          = "http://www.w3.org/2000/svg",
        width          = "18", height = "18",
        viewBox        = "0 0 20 20",
        fill           = "none",
        stroke         = "#2d5a3d",
        `stroke-width` = "2.2",
        `stroke-linecap` = "round",
        tags$line(x1 = "10", y1 = "2",  x2 = "10", y2 = "18"),
        tags$line(x1 = "4",  y1 = "6",  x2 = "16", y2 = "6"),
        tags$line(x1 = "5",  y1 = "10", x2 = "15", y2 = "10"),
        tags$line(x1 = "7",  y1 = "14", x2 = "13", y2 = "14")
      )
    ),
    tags$div(
      tags$div(class = "lm-brand-name", "Linkmapper"),
      tags$div(class = "lm-brand-tag",  "Linkage mapping & QTL visualisation")
    )
  ),
  header = tagList(
    tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "styler.css")),
    useShinyjs(),
    useWaiter()
  ),
  id = "main_navbar",
  nav_spacer(),
  nav_item(
    downloadButton("sampleDataNav",
      label = tagList(lm_icon("dl", 13), " Demo dataset"),
      class = "lm-nav-btn lm-nav-btn-primary",
      icon  = NULL
    )
  ),
  nav_panel(
    title = "Welcome",
    tags$div(
      class = "lm-welcome-wrap",

      # Hero banner
      tags$div(
        class = "lm-hero",
        tags$div(class = "lm-hero-label", "Free \u00b7 Open source \u00b7 No coding needed"),
        tags$h1(class = "lm-hero-title",
          "Map markers.", tags$br(),
          "Discover QTL.", tags$br(),
          "Understand your genome."
        ),
        tags$p(class = "lm-hero-desc",
          "Linkmapper wraps the power of the onemap R package in a friendly
           interface. Upload your biparental population data and generate
           publication-quality linkage maps and QTL profiles in minutes."
        ),
        tags$div(
          class = "lm-hero-cta",
          actionButton("goToAnalysis",
            label = tagList(lm_icon("arrow"), " Get started"),
            class = "lm-hero-btn lm-hero-btn-primary",
            onclick = paste0(
              "Shiny.setInputValue('nav_goto', 'Prior analysis',",
              "{priority: 'event'});"
            )
          ),
          downloadButton("sampleData", label = "Download demo dataset",
            class = "lm-hero-btn lm-hero-btn-secondary",
            icon  = NULL
          )
        )
      ),

      # Info cards row
      tags$div(
        class = "lm-info-grid",
        lm_info_card(
          icon_id = "dna",
          accent  = "sage",
          title   = "Linkage mapping",
          desc    = "Assign markers to linkage groups, order them by
                     recombination frequency, and generate annotated
                     maps for F2 and backcross populations."
        ),
        lm_info_card(
          icon_id = "chart",
          accent  = "amber",
          title   = "QTL visualisation",
          desc    = "Run interval or composite interval mapping and
                     visualise LOD score profiles across all your
                     linkage groups."
        ),
        lm_info_card(
          icon_id = "dl",
          accent  = "blue",
          title   = "Export everything",
          desc    = "Download maps as high-resolution PNG, marker
                     statistics as CSV, and QTL tables ready for
                     your publications."
        )
      )
    )
  ),
  nav_panel(
    title = "Analysis",
    value = "Analysis",
    bslib::navset_hidden(
      id = "workflow_tabs",
  nav_panel(
    "Prior analysis",
    lm_module_layout(
      active_step = 1,

      sidebar_content = tagList(
        tags$div(class = "lm-step-badge", lm_icon("upload", 12), "Step 1 of 5 \u00b7 Active"),
        tags$div(class = "lm-section-label", "Data file"),

        # Upload zone
        tags$div(
          class = "lm-upload-zone",
          id    = "uploadZoneDisplay",
          fileInput(
            inputId     = "uploadTXT",
            label       = NULL,
            accept      = ".txt",
            buttonLabel = tagList(lm_icon("upload", 14), "Browse files"),
            placeholder = "No file selected"
          ),
          tags$div(class = "lm-upload-hint",
            lm_icon("file", 14), " .txt MAPMAKER format"
          )
        ),

        tags$div(class = "lm-section-label", "Display options"),

        tags$div(class = "lm-field-group",
          tags$label(class = "lm-field-label", "Missing data plot"),
          radioButtons("missing_datapoints", label = NULL,
            choices  = list("Show" = 1, "Hide" = 0),
            selected = 1, inline = TRUE
          )
        ),

        tags$div(class = "lm-field-group",
          tags$label(class = "lm-field-label", "Segregation distortion plot"),
          radioButtons("seg_distort", label = NULL,
            choices  = list("Show" = 1, "Hide" = 0),
            selected = 1, inline = TRUE
          )
        ),

        tags$div(class = "lm-btn-stack",
          actionButton("submitTXT", class = "btn btn-primary w-100",
            label = tagList(lm_icon("chart", 15), "Run prior analysis")
          ),
          tags$div(class = "lm-divider"),
          tags$div(class = "lm-section-label", "Downloads"),
          downloadButton("missingDatapoints",
            label = tagList(lm_icon("dl", 14), " Missing data plot"),
            class = "btn btn-outline-primary w-100 lm-btn-sm",
            icon  = NULL
          ),
          downloadButton("segDistortion",
            label = tagList(lm_icon("dl", 14), " Segregation distortion plot"),
            class = "btn btn-outline-primary w-100 lm-btn-sm",
            icon  = NULL
          )
        )
      ),

      output_content = tagList(
        bslib::card(
          bslib::card_header(
            tags$div(class = "lm-card-header-row",
              tags$div(class = "d-flex align-items-center gap-2",
                lm_icon("file", 18), tags$span("Prior analysis summary")
              ),
              uiOutput("priorBadge")
            )
          ),
          bslib::card_body(
            tags$div(class = "lm-stat-grid",
              tags$div(class = "lm-stat-box",
                tags$div(class = "lm-stat-num", textOutput("n_individuals", inline = TRUE)),
                tags$div(class = "lm-stat-label", "Individuals")
              ),
              tags$div(class = "lm-stat-box",
                tags$div(class = "lm-stat-num", textOutput("n_markers", inline = TRUE)),
                tags$div(class = "lm-stat-label", "Markers")
              ),
              tags$div(class = "lm-stat-box",
                tags$div(class = "lm-stat-num", textOutput("pct_genotyped", inline = TRUE)),
                tags$div(class = "lm-stat-label", "Genotyped")
              ),
              tags$div(class = "lm-stat-box",
                tags$div(class = "lm-stat-num", textOutput("n_distorted", inline = TRUE)),
                tags$div(class = "lm-stat-label", "Distorted")
              )
            ),
            verbatimTextOutput("general_info"),
            verbatimTextOutput("distorted_markers_info"),
            verbatimTextOutput("nondistorted_markers_info"),
            tags$div(
              class = "lm-plot-grid",
              tags$div(plotOutput("missing_datapoints_plot",  height = "220px")),
              tags$div(plotOutput("seg_distortion_plot",      height = "220px"))
            )
          )
        ),
        uiOutput("nextBtn_s1")
      )
    )
  ),
  nav_panel(
    "Marker grouping",
    lm_module_layout(
      active_step = 2,

      sidebar_content = tagList(
        tags$div(class = "lm-step-badge",
          lm_icon("layers", 12), "Step 2 of 5 \u00b7 Active"
        ),

        tags$div(class = "lm-section-label", "Grouping parameters"),

        tags$div(class = "lm-field-group",
          tags$label(class = "lm-field-label",
            "Maximum recombination frequency"
          ),
          sliderInput("maxRF", label = NULL,
            min = 0, max = 1, value = 0.5, step = 0.1,
            width = "100%"
          )
        ),

        tags$div(class = "lm-field-group",
          tags$label(class = "lm-field-label", "LOD value"),
          radioButtons("lod_choice", label = NULL,
            choices  = list("Data-suggested" = 1, "User-defined" = 2),
            selected = 1
          ),
          shinyjs::hidden(
            numericInput("user_lod_value", label = NULL,
              value = 3, min = 1, max = 10, step = 0.01
            )
          )
        ),

        tags$div(class = "lm-field-group",
          tags$label(class = "lm-field-label", "Mapping function"),
          selectInput("map_func_type", label = NULL,
            choices  = list("Kosambi" = "kosambi", "Haldane" = "haldane"),
            selected = "kosambi",
            width    = "100%"
          )
        ),

        actionButton("make_groupings",
          label = tagList(lm_icon("layers", 15), "Generate linkage groups"),
          class = "btn btn-warning w-100"
        ),

        tags$div(class = "lm-divider"),
        tags$div(class = "lm-section-label", "Two-point marker analysis"),

        tags$div(class = "lm-field-group",
          tags$label(class = "lm-field-label", "Marker 1"),
          selectInput("twopts_marker1", label = NULL,
            choices = c("\u2014"), width = "100%"
          )
        ),

        tags$div(class = "lm-field-group",
          tags$label(class = "lm-field-label", "Marker 2"),
          selectInput("twopts_marker2", label = NULL,
            choices = c("\u2014"), width = "100%"
          )
        ),

        actionButton("two_marker_analysis",
          label = tagList(lm_icon("chart", 15), "Analyse marker pair"),
          class = "btn btn-outline-primary w-100"
        )
      ),

      output_content = tagList(

        bslib::card(
          bslib::card_header(
            tags$div(class = "lm-card-header-row",
              tags$div(class = "d-flex align-items-center gap-2",
                lm_icon("layers", 18),
                tags$span("Linkage groups")
              ),
              tags$span(class = "lm-badge lm-badge-sage",
                textOutput("n_groups_badge", inline = TRUE)
              )
            )
          ),
          bslib::card_body(
            tags$div(class = "lm-stat-grid",
              tags$div(class = "lm-stat-box",
                tags$div(class = "lm-stat-num",
                  textOutput("n_groups_stat", inline = TRUE)
                ),
                tags$div(class = "lm-stat-label", "Groups")
              ),
              tags$div(class = "lm-stat-box",
                tags$div(class = "lm-stat-num",
                  textOutput("n_linked_stat", inline = TRUE)
                ),
                tags$div(class = "lm-stat-label", "Linked")
              ),
              tags$div(class = "lm-stat-box",
                tags$div(class = "lm-stat-num",
                  textOutput("lod_used_stat", inline = TRUE)
                ),
                tags$div(class = "lm-stat-label", "LOD used")
              ),
              tags$div(class = "lm-stat-box",
                tags$div(class = "lm-stat-num",
                  textOutput("maxrf_stat", inline = TRUE)
                ),
                tags$div(class = "lm-stat-label", "Max RF")
              )
            ),
            verbatimTextOutput("linkage_groups")
          )
        ),

        bslib::card(
          bslib::card_header(
            tags$div(class = "d-flex align-items-center gap-2",
              lm_icon("chart", 18),
              tags$span("Two-point analysis result")
            )
          ),
          bslib::card_body(
            verbatimTextOutput("twopts_output")
          )
        ),
        uiOutput("nextBtn_s2")
      )
    )
  ),
  nav_panel(
    "Ordering",
    lm_module_layout(
      active_step = 3,

      sidebar_content = tagList(
        tags$div(class = "lm-step-badge",
          lm_icon("sort", 12), "Step 3 of 5 \u00b7 Active"
        ),

        tags$div(class = "lm-section-label", "Ordering algorithm"),

        radioButtons("order_LG", label = NULL,
          choices  = list("RECORD" = 1, "RCD" = 2, "Unidirectional (UG)" = 3),
          selected = 1
        ),

        tags$div(class = "lm-divider"),
        tags$div(class = "lm-section-label", "Preview single group"),

        tags$div(class = "lm-field-group",
          tags$label(class = "lm-field-label", "Linkage group to order"),
          numericInput("lg_to_order", label = NULL,
            value = 1, min = 1, max = 50, width = "100%"
          )
        ),

        actionButton("submit_lg_to_order",
          label = tagList(lm_icon("sort", 15), "Order and map group"),
          class = "btn btn-outline-primary w-100"
        ),

        tags$div(class = "lm-divider"),

        tags$div(class = "lm-hint",
          lm_icon("info", 13),
          tags$span(style = "margin-left:5px",
            "Preview a single group before ordering all.
             The chosen algorithm will also be used in the
             Linkage mapping step."
          )
        )
      ),

      output_content = tagList(
        bslib::card(
          bslib::card_header(
            tags$div(class = "lm-card-header-row",
              tags$div(class = "d-flex align-items-center gap-2",
                lm_icon("sort", 18),
                tags$span("Marker order")
              ),
              tags$span(class = "lm-badge lm-badge-sage",
                textOutput("ordering_loglik_badge", inline = TRUE)
              )
            )
          ),
          bslib::card_body(
            verbatimTextOutput("lg_ordering")
          )
        ),
        uiOutput("nextBtn_s3")
      )
    )
  ),
  nav_panel(
    "Linkage mapping",
    lm_module_layout(
      active_step = 4,

      sidebar_content = tagList(
        tags$div(class = "lm-step-badge",
          lm_icon("map", 12), "Step 4 of 5 \u00b7 Active"
        ),

        tags$div(class = "lm-section-label", "Map appearance"),

        tags$div(class = "lm-field-group",
          tags$label(class = "lm-field-label", "Map title"),
          textInput("map_title", label = NULL,
            placeholder = "e.g. Linkage map of F2 data",
            width = "100%"
          )
        ),

        tags$div(class = "lm-field-group",
          tags$label(class = "lm-field-label", "Linkage group name prefix"),
          textInput("group_prefix", label = NULL,
            placeholder = "e.g. LG-",
            width = "100%"
          )
        ),

        tags$div(class = "lm-field-group",
          tags$label(class = "lm-field-label", "Chromosome colour"),
          selectInput("LG_colour", label = NULL,
            choices = list(
              "Sage green" = "green",
              "Amber"      = "orange",
              "Steel blue" = "blue",
              "Rose"       = "red",
              "Grey"       = "grey"
            ),
            selected = "green",
            width    = "100%"
          )
        ),

        tags$div(class = "lm-btn-stack",
          actionButton("generate_linkage_map",
            label = tagList(
              lm_icon("map", 15),
              tags$span("Generate linkage map",
                id = "UpdateAnimate", class = ""
              )
            ),
            class = "btn btn-warning w-100"
          ),

          shinyjs::disabled(
            tags$a(
              id       = "downloadMap",
              class    = "btn btn-outline-primary w-100 lm-btn-sm shiny-download-link",
              href     = "",
              target   = "_blank",
              download = NA,
              tagList(lm_icon("dl", 14), " Download map (PNG)")
            )
          )
        ),

        tags$div(class = "lm-hint", style = "margin-top: 10px",
          lm_icon("info", 13),
          tags$span(style = "margin-left:5px",
            "Generation time depends on the number of markers,
             individuals, and linkage groups. May take several minutes."
          )
        )
      ),

      output_content = tagList(
        bslib::card(
          bslib::card_header(
            tags$div(class = "lm-card-header-row",
              tags$div(class = "d-flex align-items-center gap-2",
                lm_icon("map", 18),
                tags$span("Linkage map output")
              ),
              uiOutput("mapStatusBadge")
            )
          ),
          bslib::card_body(
            shinyjs::hidden(
              tags$p(id = "processing_status",
                class = "lm-hint",
                lm_icon("info", 13),
                tags$span(style = "margin-left:5px",
                  "Processing \u2014 this may take a few minutes. Please wait."
                )
              )
            ),
            imageOutput("elegant_plot", width = "100%")
          )
        ),
        uiOutput("nextBtn_s4")
      )
    )
  ),
  nav_panel(
    "QTL analysis",
    lm_module_layout(
      active_step = 5,

      sidebar_content = tagList(
        tags$div(class = "lm-step-badge",
          lm_icon("chart", 12), "Step 5 of 5 \u00b7 Active"
        ),

        tags$div(class = "lm-section-label", "QTL scan settings"),

        tags$div(class = "lm-field-group",
          tags$label(class = "lm-field-label", "Phenotype"),
          selectInput("qtl_phenotype", label = NULL,
            choices = c("\u2014 run prior analysis first \u2014"),
            width   = "100%"
          )
        ),

        tags$div(class = "lm-field-group",
          tags$label(class = "lm-field-label", "Method"),
          selectInput("qtl_method", label = NULL,
            choices = list(
              "Interval mapping (IM)"            = "im",
              "Composite interval mapping (CIM)" = "cim"
            ),
            width = "100%"
          )
        ),

        tags$div(class = "lm-field-group",
          tags$label(class = "lm-field-label", "LOD threshold"),
          sliderInput("qtl_lod_threshold", label = NULL,
            min = 1, max = 10, value = 3, step = 0.5,
            width = "100%"
          )
        ),

        tags$div(class = "lm-btn-stack",
          actionButton("run_qtl_scan",
            label = tagList(lm_icon("chart", 15), "Run QTL scan"),
            class = "btn btn-primary w-100"
          ),
          tags$div(class = "lm-divider"),
          tags$div(class = "lm-section-label", "Downloads"),
          downloadButton("qtl_download_plot",
            label = tagList(lm_icon("dl", 14), " LOD profile (PNG)"),
            class = "btn btn-outline-primary w-100 lm-btn-sm",
            icon  = NULL
          ),
          downloadButton("qtl_download_table",
            label = tagList(lm_icon("dl", 14), " QTL table (CSV)"),
            class = "btn btn-outline-primary w-100 lm-btn-sm",
            icon  = NULL
          )
        ),

        tags$div(class = "lm-hint", style = "margin-top:10px",
          lm_icon("info", 13),
          tags$span(style = "margin-left:5px",
            "QTL scanning requires linkage mapping (Step 4)
             to be completed first. Phenotype options are
             populated from your uploaded data file."
          )
        )
      ),

      output_content = tagList(

        bslib::card(
          bslib::card_header(
            tags$div(class = "lm-card-header-row",
              tags$div(class = "d-flex align-items-center gap-2",
                lm_icon("chart", 18),
                tags$span("LOD score profile")
              ),
              tags$span(class = "lm-badge lm-badge-amber",
                textOutput("qtl_status_badge", inline = TRUE)
              )
            )
          ),
          bslib::card_body(
            plotOutput("qtl_lod_plot", height = "260px")
          )
        ),

        bslib::card(
          bslib::card_header(
            tags$div(class = "d-flex align-items-center gap-2",
              lm_icon("sort", 18),
              tags$span("Detected QTL")
            )
          ),
          bslib::card_body(
            tableOutput("qtl_summary_table")
          )
        )
      )
    )
  )          # close QTL analysis nav_panel
    )        # close navset_hidden
  ),         # close Analysis nav_panel
  nav_panel(
    title = "Help and FAQs",
    tags$div(
      class = "lm-welcome-wrap",

      bslib::card(
        bslib::card_header(
          tags$div(class = "d-flex align-items-center gap-2",
            lm_icon("info", 18), tags$span("Help & documentation")
          )
        ),
        bslib::card_body(

          lm_faq("Data format",
            "Linkmapper accepts MAPMAKER-format .txt files containing
             F2 intercross or backcross data. Co-dominant, dominant,
             and recessive markers are all supported. Missing data is
             permitted. Download the demo dataset from the Welcome page
             to see an example of the required format."
          ),

          lm_faq("Which LOD value should I use?",
            "Use the data-suggested LOD unless you have a specific
             reason to override it. The suggested value is calculated
             directly from your data using onemap's suggest_lod()
             function and is appropriate for most analyses."
          ),

          lm_faq("Kosambi vs Haldane mapping function",
            "Kosambi accounts for crossover interference between
             adjacent loci and is recommended for most organisms.
             Haldane assumes no interference \u2014 use it when the
             Kosambi assumption is known to be violated for your
             study organism."
          ),

          lm_faq("Which ordering algorithm should I use?",
            "RECORD (the default) minimises the total number of
             recombination events and is the best general-purpose
             choice. RCD is faster for large groups but less
             accurate. Unidirectional Growth (UG) performs well
             when most loci are co-dominant and heterozygous."
          ),

          lm_faq("Why is map generation slow?",
            "Linkage map generation time scales with the number of
             markers, individuals, and linkage groups. For large
             datasets this may take several minutes. The app will
             display a processing indicator \u2014 do not navigate away
             or refresh the page while it runs."
          ),

          lm_faq("QTL analysis requirements",
            "The QTL module requires prior analysis, marker grouping,
             ordering, and linkage map generation (Steps 1\u20134) to be
             completed first. Your data file must also contain at
             least one phenotype column for QTL scanning to work."
          )
        )
      )
    )
  ),
  nav_panel(
    title = "About Us",
    tags$div(
      class = "lm-welcome-wrap",

      bslib::card(
        bslib::card_header(
          tags$div(class = "d-flex align-items-center gap-2",
            lm_icon("leaf", 18), tags$span("About Linkmapper")
          )
        ),
        bslib::card_body(
          tags$p(
            style = "font-size:14px; line-height:1.8;
                     color:var(--lm-text-mid); margin-bottom:20px;",
            "Linkmapper is a free, open-source Shiny web application
             that provides a graphical user interface for linkage
             mapping and QTL visualisation, built on the ",
            tags$strong("onemap"), " R package (Margarido et al., 2007).
             It was developed to make molecular genetics analysis
             accessible to students and researchers without requiring
             programming knowledge."
          ),

          tags$div(
            style = "display:grid; grid-template-columns:1fr 1fr;
                     gap:12px; margin-bottom:20px;",
            lm_about_card("Institution", "KNUST, Kumasi, Ghana"),
            lm_about_card("Department",
              "Crop and Soil Sciences, Faculty of Agriculture"),
            lm_about_card("Supervisor",  "Dr. Alexander W. Kena"),
            lm_about_card("Core engine", "onemap R package"),
            lm_about_card("Framework",   "R Shiny + bslib"),
            lm_about_card("License",     "MIT")
          ),

          tags$div(class = "lm-section-label",
            style = "padding-top:4px;", "Authors"
          ),
          tags$div(
            style = "display:grid; grid-template-columns:repeat(3,1fr);
                     gap:12px; margin-top:8px;",
            lm_author_card("OE", "Ogoe Ebenezer"),
            lm_author_card("OM", "Obeng Michael"),
            lm_author_card("AB", "Amoako Barnie Stephen")
          ),
          tags$div(
            style = "margin-top: 10px;",
            tags$div(class = "lm-section-label",
              style = "padding-top:4px;",
              "Supervisor"
            ),
            tags$div(
              style = "display:grid; grid-template-columns:repeat(1,1fr);
                       gap:12px; margin-top:8px; max-width:220px;",
              lm_author_card("AK", "Dr. Alexander W. Kena")
            )
          ),
          tags$p(
            style = "font-size:13px; color:var(--lm-text-soft);
                     margin-top:24px; border-top:1px solid var(--lm-sand-border);
                     padding-top:14px;",
            "© 2022–2026 Ogoe Ebenezer, Obeng Michael, Amoako Barnie Stephen.
             Released under the MIT License."
          )
        )
      )
    )
  )
)



server <- function(input, output, session) {
  `%||%` <- function(a, b) if (!is.null(a) && nchar(a) > 0) a else b

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
  #                         Section 1. Global variables                                     #
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
  rv <- reactiveValues(
    code_succeeded  = FALSE,
    linkage_groups  = NULL,
    f2data          = NULL,
    f2data_test     = NULL,
    two_point       = NULL,
    suggested_lod   = 0,
    map_path        = NULL,
    Gs_maps_final       = NULL,   # list of ordered+mapped sequence objects; set by elegant_map_generator()
    interactive_map_obj = NULL,   # plotly figure of the linkage map; rebuilt each time the map is generated
    qtl_scan_result     = NULL,   # data.frame of significant QTL peaks for the summary table
    qtl_plot_obj        = NULL,   # ggplot object of the LOD profile for rendering + download
    qtl_scan            = NULL,   # raw scan_result data.frame from scanone()/cim()
    qtl_peaks           = NULL,   # data.frame of peaks above threshold
    qtl_method          = NULL,   # "im" or "cim" — the method used for the last scan
    qtl_lod_threshold   = NULL,   # numeric LOD threshold used for the last scan
    last_ordered_lg     = NULL    # integer: the last LG number sent through orderLG()
  )

  # Clean up the per-session temp file when the user disconnects.
  # isolate() is required because onSessionEnded runs outside a reactive context.
  session$onSessionEnded(function() {
    path <- isolate(rv$map_path)
    if (!is.null(path) && file.exists(path))
      unlink(path)
  })
  
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
  #                       Section 2. ObserveEvent() Expressions                             #
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
  ## Invoke the function to group markers into linkage groups
  observeEvent(input$make_groupings, {
    w <- waiter::Waiter$new(
      html = tagList(
        waiter::spin_ring(),
        tags$p("Grouping markers\u2026", style = "color:#fff; margin-top:12px;")
      ),
      color = "rgba(44,62,80,0.82)"
    )
    w$show()
    on.exit(w$hide(), add = TRUE)
    tryCatch({
      groupings()
    },
    warning = function(cond) {
      showNotification(
        paste("Warning during grouping:", conditionMessage(cond)),
        type = "warning", duration = 8
      )
    },
    error = function(cond) {
      showNotification(
        paste("Grouping failed:", conditionMessage(cond)),
        type = "error", duration = 10
      )
    })
  })


  ## Invoke the function to order the markers in the chosen linkage group
  observeEvent(input$submit_lg_to_order, {
    tryCatch({
      orderLG()
    },
    warning = function(cond) {
      showNotification(
        paste("Warning during ordering:", conditionMessage(cond)),
        type = "warning", duration = 8
      )
    },
    error = function(cond) {
      showNotification(
        paste("Ordering failed:", conditionMessage(cond)),
        type = "error", duration = 10
      )
    })
  })

  ## Invoke the two-point analysis of only two markers
  observeEvent(input$two_marker_analysis, {
    tryCatch({
      twoptsAnalysis()
    },
    warning = function(cond) {
      showNotification(
        paste("Warning during two-point analysis:", conditionMessage(cond)),
        type = "warning", duration = 8
      )
    },
    error = function(cond) {
      showNotification(
        paste("Two-point analysis failed:", conditionMessage(cond)),
        type = "error", duration = 10
      )
    })
  })

  ## Invoke the function that does prior analysis
  observeEvent(input$submitTXT, {
    shinyjs::disable(id = "downloadMap")
    file <- input$uploadTXT
    ext  <- file_ext(file$datapath)
    req(file)
    validate(need(ext == "txt", "Please upload a Text (TXT) file!"))

    tryCatch({
      prior_analysis(file$datapath)
    },
    warning = function(cond) {
      showNotification(
        paste("Warning during file read:", conditionMessage(cond)),
        type = "warning", duration = 8
      )
    },
    error = function(cond) {
      showNotification(
        paste("File processing failed:", conditionMessage(cond)),
        type = "error", duration = 10
      )
    })
  })
  
  
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
  #                 Section 3. Observe() Expressions and Downloaders                        #
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
  ## If the user chooses to enter his own LOD value, provide the box to do so
  observe({
    if (input$lod_choice == 1){
      shinyjs::hide(id = "user_lod_value")
    }
    else
      shinyjs::show(id = "user_lod_value")
  })

  ## Populate QTL phenotype selector once prior analysis has run
  observe({
    req(rv$f2data)
    pheno_names <- colnames(rv$f2data$pheno)
    if (!is.null(pheno_names) && length(pheno_names) > 0) {
      updateSelectInput(
        session,
        inputId  = "qtl_phenotype",
        choices  = pheno_names,
        selected = pheno_names[1]
      )
    }
  })
  
  ## Serves the built-in demo F2 dataset
  output$sampleData <- downloadHandler(
    filename = function() "f2_demo.txt",
    content  = function(file) {
      # When running as a package, system.file() resolves the path.
      # When running the app directly from the project directory (dev mode),
      # fall back to the relative path from the project root.
      src <- system.file("app/www/data/f2_demo.txt", package = "linkmapper")
      if (nchar(src) == 0)
        src <- file.path("inst", "app", "www", "data", "f2_demo.txt")
      if (!file.exists(src)) {
        showNotification("Demo data file not found. Please check the installation.",
                         type = "error", duration = 10)
        return()
      }
      file.copy(src, file)
    }
  )

  ## Serves demo dataset from navbar button (same file as sampleData)
  output$sampleDataNav <- downloadHandler(
    filename = function() "f2_demo.txt",
    content  = function(file) {
      src <- system.file("app/www/data/f2_demo.txt", package = "linkmapper")
      if (nchar(src) == 0)
        src <- file.path("inst", "app", "www", "data", "f2_demo.txt")
      if (!file.exists(src)) {
        showNotification("Demo data file not found. Please check the installation.",
                         type = "error", duration = 10)
        return()
      }
      file.copy(src, file)
    }
  )

  ## Downloads generated map
  output$downloadMap <- downloadHandler(
    filename = function() {
      paste0(
        gsub("[^A-Za-z0-9_-]", "_", isolate(input$map_title) %||% "Linkage_map"),
        ".png"
      )
    },
    content  = function(file) {

      req(rv$map_path)

      if (!file.exists(rv$map_path)) {
        showNotification(
          "Map file not found. Please regenerate the linkage map before downloading.",
          type = "warning", duration = 6
        )
        return()
      }

      # Re-render at high resolution for download rather than copying the preview file
      n.groups <- rv$linkage_groups$n.groups

      png(file,
          width  = max(1200, n.groups * 300),
          height = 1600,
          res    = 150,
          units  = "px")

      onemap::draw_map2(
        rv$Gs_maps_final,
        tag         = "all",
        main        = isolate(input$map_title),
        group.names = paste0(isolate(input$group_prefix), seq_len(n.groups)),
        cex.label   = 0.7,
        col.group   = isolate(input$LG_colour),
        col.tag     = "black"
      )

      dev.off()
    }
  )
  
  ## Downloads missing datapoints plot
  output$missingDatapoints <- downloadHandler(
    filename = function() {
      paste("Missing datapoints.png")
    },
    content = function(file) {
      png(file, width = 1600, height = 900, res = 150, units = "px")
      par(bg = "#fafafa")
      print(plot(rv$f2data))
      dev.off()
    }
  )

  ## Downloads segregation distortion plot
  output$segDistortion <- downloadHandler(
    filename = function() {
      paste("Segregation distortion.png")
    },
    content = function (file) {
      png(file, width = 1600, height = 900, res = 150, units = "px")
      par(bg = "#fafafa")
      print(plot(rv$f2data_test))
      dev.off()
    }
  )
 
  ## Stat box: number of individuals
  output$n_individuals <- renderText({
    if (is.null(rv$f2data)) "--" else as.character(rv$f2data$n.ind)
  })

  ## Stat box: number of markers
  output$n_markers <- renderText({
    if (is.null(rv$f2data)) "--" else as.character(rv$f2data$n.mar)
  })

  ## Stat box: percentage of cells genotyped
  output$pct_genotyped <- renderText({
    if (is.null(rv$f2data)) "--"
    else paste0(round(100 * sum(!is.na(rv$f2data$geno)) /
      (rv$f2data$n.ind * rv$f2data$n.mar)), "%")
  })

  ## Stat box: number of distorted markers
  output$n_distorted <- renderText({
    if (is.null(rv$f2data)) "--"
    else {
      dist <- tryCatch(
        length(select_segreg(test_segregation(rv$f2data),
          distorted = TRUE, numbers = TRUE)),
        error = function(e) "--"
      )
      as.character(dist)
    }
  })

  ## Grouping stat: badge text
  output$n_groups_badge <- renderText({
    if (is.null(rv$linkage_groups)) "Awaiting grouping"
    else paste(rv$linkage_groups$n.groups, "groups found")
  })

  ## Grouping stat: number of groups
  output$n_groups_stat <- renderText({
    if (is.null(rv$linkage_groups)) "--"
    else as.character(rv$linkage_groups$n.groups)
  })

  ## Grouping stat: number of linked markers
  output$n_linked_stat <- renderText({
    if (is.null(rv$linkage_groups)) "--"
    else as.character(rv$linkage_groups$n.mar)
  })

  ## Grouping stat: LOD value used
  output$lod_used_stat <- renderText({
    if (rv$suggested_lod == 0) "--"
    else as.character(round(rv$suggested_lod, 2))
  })

  ## Grouping stat: max RF value
  output$maxrf_stat <- renderText({
    as.character(input$maxRF)
  })

  ## Ordering badge text
  output$ordering_loglik_badge <- renderText({
    if (is.null(rv$linkage_groups)) return("Awaiting ordering")
    "Ready \u2014 click Order and map group"
  })

  ## Linkage map status badge
  output$mapStatusBadge <- renderUI({
    if (is.null(rv$map_path) || !file.exists(rv$map_path)) {
      tags$span(class = "lm-badge lm-badge-amber", "Ready to generate")
    } else {
      tags$span(class = "lm-badge lm-badge-sage", "Map generated")
    }
  })

  ## Prior analysis status badge
  output$priorBadge <- renderUI({
    if (is.null(rv$f2data)) {
      tags$span(class = "lm-badge lm-badge-amber", "Awaiting data")
    } else {
      tags$span(class = "lm-badge lm-badge-sage", "\u2713 Complete")
    }
  })

  ## QTL status badge
  output$qtl_status_badge <- renderText({
    if (is.null(rv$qtl_scan)) return("Awaiting QTL scan")
    n_qtl      <- if (is.null(rv$qtl_peaks)) 0L else nrow(rv$qtl_peaks)
    method_str <- if (identical(rv$qtl_method, "cim")) "CIM" else "IM"
    lod_str    <- if (is.null(rv$qtl_lod_threshold)) "" else
                  paste0(" | LOD \u2265 ", rv$qtl_lod_threshold)
    paste0(n_qtl, " QTL(s) detected (", method_str, lod_str, ")")
  })

  ## Render the interactive plotly linkage map
  output$interactive_map <- plotly::renderPlotly({
    if (is.null(rv$interactive_map_obj)) return(NULL)
    rv$interactive_map_obj
  })

  ## Render the QTL LOD profile plot
  output$qtl_lod_plot <- renderPlot({
    if (is.null(rv$qtl_plot_obj)) return(NULL)
    rv$qtl_plot_obj
  })

  ## Render the QTL summary table
  output$qtl_summary_table <- renderTable({
    if (is.null(rv$qtl_scan_result)) return(NULL)
    rv$qtl_scan_result
  }, striped = TRUE, hover = TRUE, bordered = TRUE, digits = 3)

  ## Download the LOD profile as PNG
  output$qtl_download_plot <- downloadHandler(
    filename = function() {
      method_str <- if (identical(rv$qtl_method, "cim")) "CIM" else "IM"
      paste0("QTL_LOD_profile_", method_str, ".png")
    },
    content  = function(file) {
      if (is.null(rv$qtl_plot_obj)) {
        showNotification("No QTL plot available. Run a scan first.", type = "warning")
        return()
      }
      ggplot2::ggsave(file, plot = rv$qtl_plot_obj,
                      width = 10, height = 5, dpi = 150, units = "in")
    }
  )

  ## Download the QTL summary table as CSV
  output$qtl_download_table <- downloadHandler(
    filename = function() {
      method_str <- if (identical(rv$qtl_method, "cim")) "CIM" else "IM"
      paste0("QTL_summary_", method_str, ".csv")
    },
    content  = function(file) {
      if (is.null(rv$qtl_scan_result)) {
        showNotification("No QTL results available. Run a scan first.", type = "warning")
        return()
      }
      write.csv(rv$qtl_scan_result, file, row.names = FALSE)
    }
  )

  ## Render the QTL Analysis module UI (guard: prior analysis + grouping must be complete)
  output$qtl_page_ui <- renderUI({
    if (!isTRUE(rv$code_succeeded) || is.null(rv$linkage_groups) || is.null(rv$Gs_maps_final)) {
      return(
        tags$div(
          class = "alert alert-warning",
          style = "margin: 20px; padding: 18px; font-size: 15px;",
          icon("triangle-exclamation"),
          tags$strong(" Prerequisites not met."),
          tags$br(),
          "Complete prior analysis (Module 1), marker grouping (Module 2), and linkage map generation (Module 4) first. The QTL scan requires an ordered map."
        )
      )
    }

    pheno_choices <- if (!is.null(rv$f2data$pheno)) colnames(rv$f2data$pheno) else character(0)

    sidebarLayout(
      sidebarPanel(
        tags$label(tags$h3("QTL scan parameters")),
        tags$br(),

        selectInput(
          inputId  = "qtl_phenotype",
          label    = "Phenotype",
          choices  = pheno_choices,
          selected = if (length(pheno_choices) > 0) pheno_choices[[1]] else NULL
        ),

        selectInput(
          inputId  = "qtl_method",
          label    = "QTL method",
          choices  = list("Interval Mapping" = "im", "Composite Interval Mapping" = "cim"),
          selected = "im"
        ),

        sliderInput(
          inputId = "qtl_lod_threshold",
          label   = "LOD threshold",
          min     = 1, max = 10, value = 3, step = 0.5
        ),

        actionButton(
          inputId = "run_qtl_scan",
          label   = "Run QTL scan",
          icon    = icon("magnifying-glass-chart"),
          class   = "btn-primary"
        ),

        tags$br(), tags$br(), tags$br(),
        tags$h4("Download options"),
        downloadButton(outputId = "qtl_download_plot",  label = "Download LOD plot",       icon = NULL),
        tags$br(), tags$br(),
        downloadButton(outputId = "qtl_download_table", label = "Download QTL table (CSV)", icon = NULL)
      ),

      mainPanel(
        tags$label(tags$h3("Output")),
        tags$br(),
        plotOutput(outputId = "qtl_lod_plot", height = "400px"),
        tags$br(),
        tableOutput(outputId = "qtl_summary_table")
      )
    )
  })

  ## Run the QTL scanning pipeline
  observeEvent(input$run_qtl_scan, {
    if (is.null(rv$f2data)) {
      showNotification("Please upload and process a data file first.",
                       type = "error", duration = 10)
      return()
    }
    if (is.null(rv$Gs_maps_final)) {
      showNotification("Please generate a linkage map before running QTL analysis.",
                       type = "error", duration = 10)
      return()
    }

    pheno_df <- tryCatch(as.data.frame(rv$f2data$pheno), error = function(e) NULL)
    if (is.null(pheno_df) || ncol(pheno_df) == 0) {
      showNotification(
        paste("No phenotype data found in the uploaded file.",
              "QTL scanning requires phenotype data embedded in the MAPMAKER input file."),
        type = "error", duration = 15
      )
      return()
    }

    threshold     <- input$qtl_lod_threshold
    method_label  <- if (input$qtl_method == "cim") "Composite Interval Mapping" else "Interval Mapping"

    withProgress(message = "Running QTL scan\u2026", value = 0, {
      tryCatch({

        # ---- Step 1: Convert onemap maps to an R/qtl cross object ----
        setProgress(0.1, detail = "Converting to R/qtl format")
        cross <- tryCatch(
          build_rqtl_cross(rv$f2data, rv$Gs_maps_final),
          error = function(e) stop(paste("Cross conversion failed:", conditionMessage(e)))
        )

        # ---- Step 2: Resolve phenotype column ----
        pheno_col <- which(names(cross$pheno) == input$qtl_phenotype)
        if (length(pheno_col) == 0) pheno_col <- 1L

        # ---- Step 3: Estimate conditional genotype probabilities ----
        setProgress(0.3, detail = "Calculating genotype probabilities")
        cross <- qtl::calc.genoprob(cross, step = 1, error.prob = 0.001,
                                    map.function = "kosambi")

        # ---- Step 4: Run the chosen scan method ----
        setProgress(0.5, detail = paste("Running", method_label))
        scan_result <- tryCatch(
          if (input$qtl_method == "cim") {
            qtl::cim(cross, pheno.col = pheno_col, method = "em")
          } else {
            qtl::scanone(cross, pheno.col = pheno_col, method = "em")
          },
          error = function(e) stop(paste("Scan failed:", conditionMessage(e)))
        )

        scan_df       <- as.data.frame(scan_result)
        scan_df$chr   <- as.character(scan_df$chr)

        # ---- Step 5: Identify peaks and build LOD profile plot ----
        setProgress(0.75, detail = "Building LOD profile")
        peaks <- find_qtl_peaks(scan_df, threshold)

        p <- ggplot2::ggplot(scan_df, ggplot2::aes(x = pos, y = lod)) +
          ggplot2::geom_line(colour = "#0d9488", linewidth = 0.8) +
          ggplot2::geom_hline(yintercept = threshold,
                              linetype   = "dashed",
                              colour     = "#f97316",
                              linewidth  = 0.7) +
          ggplot2::facet_grid(. ~ chr, scales = "free_x", space = "free_x") +
          ggplot2::labs(
            title = paste0("LOD score profile \u2014 ", method_label),
            x     = "Position (cM)",
            y     = "LOD score"
          ) +
          ggplot2::theme_minimal(base_size = 13) +
          ggplot2::theme(
            strip.background = ggplot2::element_rect(fill = "#134e4a", colour = NA),
            strip.text       = ggplot2::element_text(colour = "white", face = "bold"),
            panel.spacing    = ggplot2::unit(0.3, "lines"),
            plot.background  = ggplot2::element_rect(fill = "#fafafa", colour = NA),
            panel.background = ggplot2::element_rect(fill = "#fafafa", colour = NA),
            axis.text        = ggplot2::element_text(colour = "#9ca3af"),
            axis.title       = ggplot2::element_text(colour = "#4b5563")
          )

        if (nrow(peaks) > 0) {
          p <- p +
            ggplot2::geom_point(
              data   = peaks,
              ggplot2::aes(x = pos, y = lod),
              colour = "#f97316", size = 3, shape = 18
            ) +
            ggplot2::geom_text(
              data  = peaks,
              ggplot2::aes(x = pos, y = lod,
                           label = sprintf("%.1f cM\nLOD %.2f", pos, lod)),
              vjust = -0.7, size = 3, colour = "#f97316"
            )
        }

        # ---- Step 6: Build the summary table ----
        setProgress(0.9, detail = "Preparing summary table")
        n_ind <- rv$f2data$n.ind

        if (nrow(peaks) > 0) {
          # Approximate % variance explained (Lander & Botstein 1989 formula for F2):
          # r² ≈ 1 - 10^(-2 * LOD / n)
          pve <- round((1 - 10^(-2 * peaks$lod / n_ind)) * 100, 2)
          summary_tbl <- data.frame(
            `Linkage Group`         = peaks$chr,
            `Peak Position (cM)`    = round(peaks$pos, 2),
            `LOD Score`             = round(peaks$lod, 3),
            `% Var. Expl. (approx)` = pve,
            check.names             = FALSE,
            stringsAsFactors        = FALSE
          )
        } else {
          summary_tbl <- data.frame(
            `Linkage Group`         = character(0),
            `Peak Position (cM)`    = numeric(0),
            `LOD Score`             = numeric(0),
            `% Var. Expl. (approx)` = numeric(0),
            check.names             = FALSE,
            stringsAsFactors        = FALSE
          )
          showNotification(
            paste0("No significant QTLs detected above LOD threshold of ", threshold, "."),
            type = "message", duration = 8
          )
        }

        # ---- Commit all results to rv atomically ----
        rv$qtl_scan          <- scan_df
        rv$qtl_peaks         <- peaks
        rv$qtl_method        <- input$qtl_method
        rv$qtl_lod_threshold <- threshold
        rv$qtl_plot_obj      <- p
        rv$qtl_scan_result   <- summary_tbl

        setProgress(1, detail = "Done")

      }, error = function(e) {
        showNotification(
          paste("QTL scan failed:", conditionMessage(e)),
          type = "error", duration = 15
        )
      })
    })
  })

  # Invoke the function that generates and downloads linkage maps
  observeEvent(input$generate_linkage_map, {
    w <- waiter::Waiter$new(
      html = tagList(
        waiter::spin_ring(),
        tags$p("Generating linkage map\u2026", style = "color:#fff; margin-top:12px;")
      ),
      color = "rgba(44,62,80,0.82)"
    )
    w$show()
    on.exit(w$hide(), add = TRUE)

    # Show the "Processing. Please wait" text
    shinyjs::show(id = "processing_status")

    # Add the loading dots animation to the Generate map button
    shinyjs::addClass(id = "UpdateAnimate", class = "loading dots")

    # While the linkage map is being generated, disable the Generate map button so the user
    # doesn't interrupt the process by issuing another map generation operation
    shinyjs::disable("generate_linkage_map")

    # Begin the linkage map generation
    elegant_map_generator()
  })

  
  ## Navigate to a named tab (used by "Get started" and all "Next" buttons)
  observeEvent(input$nav_goto, {
    req(input$nav_goto)
    bslib::nav_select("main_navbar", "Analysis")
    bslib::nav_select("workflow_tabs", input$nav_goto)
  })

  ## Next-step buttons — appear only after the relevant step has produced output
  output$nextBtn_s1 <- renderUI({
    if (!isTRUE(rv$code_succeeded)) return(NULL)
    tags$div(class = "lm-next-btn-wrap",
      actionButton("next_s1",
        label = tagList("Go to Marker grouping", lm_icon("arrow", 15)),
        class = "btn btn-warning lm-next-btn",
        onclick = paste0(
          "Shiny.setInputValue('nav_goto', 'Marker grouping',",
          "{priority: 'event'});"
        )
      )
    )
  })

  output$nextBtn_s2 <- renderUI({
    if (is.null(rv$linkage_groups)) return(NULL)
    tags$div(class = "lm-next-btn-wrap",
      actionButton("next_s2",
        label = tagList("Go to Ordering", lm_icon("arrow", 15)),
        class = "btn btn-warning lm-next-btn",
        onclick = paste0(
          "Shiny.setInputValue('nav_goto', 'Ordering',",
          "{priority: 'event'});"
        )
      )
    )
  })

  output$nextBtn_s3 <- renderUI({
    if (is.null(rv$last_ordered_lg)) return(NULL)
    tags$div(class = "lm-next-btn-wrap",
      actionButton("next_s3",
        label = tagList("Go to Linkage mapping", lm_icon("arrow", 15)),
        class = "btn btn-warning lm-next-btn",
        onclick = paste0(
          "Shiny.setInputValue('nav_goto', 'Linkage mapping',",
          "{priority: 'event'});"
        )
      )
    )
  })

  output$nextBtn_s4 <- renderUI({
    if (is.null(rv$map_path) || !file.exists(rv$map_path)) return(NULL)
    tags$div(class = "lm-next-btn-wrap",
      actionButton("next_s4",
        label = tagList("Go to QTL analysis", lm_icon("arrow", 15)),
        class = "btn btn-warning lm-next-btn",
        onclick = paste0(
          "Shiny.setInputValue('nav_goto', 'QTL analysis',",
          "{priority: 'event'});"
        )
      )
    )
  })

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
  #                   Section 4. Regular functions (the "workhorses")                       #
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
  ## Function that performs the prior analysis
  prior_analysis <- function(x) {
    # The code is just about to begin, so we set its success state to FALSE
    rv$code_succeeded <- FALSE
    rv$f2data <- NULL

    # Attempt to parse the file; catch unparseable inputs before they crash downstream
    rv$f2data <- tryCatch(
      read_mapmaker(file = x),
      error = function(e) {
        showNotification(
          paste("Could not read file. Is it a valid MAPMAKER/onemap input file?", conditionMessage(e)),
          type = "error", duration = 15
        )
        NULL
      }
    )
    if (is.null(rv$f2data)) return()

    # Confirm read_mapmaker() returned an onemap object
    if (!inherits(rv$f2data, "onemap")) {
      showNotification(
        "File was read but does not appear to be a valid onemap MAPMAKER file. Check the format and try again.",
        type = "error", duration = 10
      )
      rv$f2data <- NULL
      return()
    }

    if (rv$f2data$n.mar < 1) {
      showNotification(
        "No markers found in the uploaded file. Check the file format and try again.",
        type = "error", duration = 10
      )
      rv$f2data <- NULL
      return()
    }

    if (rv$f2data$n.ind < 2) {
      showNotification(
        "Fewer than 2 individuals found in the file. A valid mapping population requires multiple individuals.",
        type = "error", duration = 10
      )
      rv$f2data <- NULL
      return()
    }

    # Print some general info at the very top
    output$general_info <- renderPrint({
      rv$f2data
    })

    if (input$missing_datapoints == 1) {
      show(id = "missing_datapoints_plot")
      output$missing_datapoints_plot <-renderPlot({
          plot(rv$f2data)
        })

    }
    else {
      hide(id = "missing_datapoints_plot")
    }

    # Check for segregation distortions for markers
    rv$f2data_test <- test_segregation(rv$f2data)

    # Apply Bonferroni correction
    Bonferroni_alpha(rv$f2data_test)

    output$nondistorted_markers_info <- renderPrint({
      # Show the markers numbers without segregation distortion
      no_distortion <- select_segreg(rv$f2data_test, distorted = FALSE, numbers = TRUE)
      cat("Number of markers without segregation distortion:", length(no_distortion), "\n\n")
      cat("Markers:", no_distortion)
    })

    output$distorted_markers_info <- renderPrint({
      # Show the markers numbers with segregation distortion
      distortion <- select_segreg(rv$f2data_test, distorted = TRUE, numbers = TRUE)
      cat("Number of markers with segregation distortion:", length(distortion), "\n\n")
      cat("Markers:", distortion)
    })

    if (input$seg_distort == 1) {
      show(id = "seg_distortion_plot")
      output$seg_distortion_plot <- renderPlot({
          plot(rv$f2data_test)
        })
    }

    else {
      hide(id = "seg_distortion_plot")
    }

    showNotification(
      tagList(
        "Prior analysis complete \u2014 ",
        tags$strong(paste(rv$f2data$n.mar, "markers,")),
        paste(rv$f2data$n.ind, "individuals")
      ),
      type = "message", duration = 5
    )
  }

  # Function that performs linkage groupings
  groupings <- function(x) {
    if (is.null(rv$f2data)) return()
    # Compute LoD
    if (input$lod_choice == 1) {
      rv$suggested_lod <- suggest_lod(rv$f2data)
    }

    else if (input$lod_choice == 2) {
      rv$suggested_lod <- input$user_lod_value
    }

    # Set map function type using the user's chosen option
    set_map_fun(type = input$map_func_type)

    # Compute two-point data
    rv$two_point <- rf_2pts(rv$f2data, LOD = rv$suggested_lod, max.rf = as.numeric(input$maxRF))

    # Identify linkage groups
    Sequence_all_markers <- make_seq(rv$two_point, "all")
    rv$linkage_groups <- group(Sequence_all_markers)

    # Update the highest linkage group number that can be chosen
    updateNumericInput(inputId = "lg_to_order", max = rv$linkage_groups$n.groups)

    # Update the marker selectors with names of the markers
    updateSelectInput(inputId = "twopts_marker1", choices = colnames(rv$f2data$geno))
    updateSelectInput(inputId = "twopts_marker2", choices = colnames(rv$f2data$geno))

    # Print detailed information about generated linkage groups
    output$linkage_groups <- renderPrint({
      rv$linkage_groups
    })

    # If the code is able to run to the end, we set its success state to true
    # If for any reason the code isn't able to run to this point, further analysis
    # and operations will be unavailable e.g generating and downloading a linkage map
    rv$code_succeeded <- TRUE

    showNotification(
      tagList(
        "Linkage groups generated \u2014 ",
        tags$strong(paste(rv$linkage_groups$n.groups,
          "groups,", rv$linkage_groups$n.mar, "markers linked"))
      ),
      type = "message", duration = 5
    )
  }

  twoptsAnalysis <- function() {
    if (is.null(rv$two_point)) return()
    output$twopts_output <- renderPrint({
      print(rv$two_point, c(input$twopts_marker1, input$twopts_marker2))
    })
  }
  
  ## Function that orders the markers in a chosen linkage group
  orderLG <- function() {
    if (is.null(rv$linkage_groups)) return()
    LGi <- make_seq(rv$linkage_groups, input$lg_to_order)
    
    if(input$order_LG == 1){
    LGi_ord <- onemap::record(LGi, hmm = FALSE)
    LGi_map <- map(LGi_ord)
    } else if (input$order_LG == 2){
      LGi_ord <- onemap::rcd(LGi, hmm = FALSE)
      LGi_map <- map(LGi_ord)
    } else {
      LGi_ord <- onemap::ug(LGi, hmm = FALSE)
      LGi_map <- map(LGi_ord)
    }
   
    # Send ordering information to the UI
    output$lg_ordering <- renderPrint({
      LGi_map
    })

    rv$last_ordered_lg <- input$lg_to_order

    showNotification(
      paste("Linkage group", input$lg_to_order, "ordered successfully"),
      type = "message", duration = 4
    )
  }
  
  
  ## This function continues directly from where the previous one ended. It does the
  ## sequencing of markers and draws the linkage map. Has been revised for efficiency
  elegant_map_generator <- function() {
    if (!isTRUE(rv$code_succeeded)) return()
    if (is.null(rv$linkage_groups)) return()

    {
      # Preallocate space in memory to store the groups, orders, and maps
      n.groups <- rv$linkage_groups$n.groups
      Gs_groups     <- vector("list", n.groups)
      Gs_ords       <- vector("list", n.groups)
      Gs_maps       <- vector("list", n.groups)
      Gs_maps_final <- vector("list", n.groups)
      
      # "For" loop to work on each linkage group
      for(i in 1:n.groups) {
        
        Gs_groups[i] <- list(make_seq(rv$linkage_groups, i))
        
        if(input$order_LG == 1){
          Gs_ords[i] <- list(onemap::record(Gs_groups[[i]], hmm = FALSE))
          
        } else if (input$order_LG == 2){
          Gs_ords[i] <- list(onemap::rcd(Gs_groups[[i]], hmm = FALSE))
          
        } else {
          Gs_ords[i] <- list(onemap::ug(Gs_groups[[i]], hmm = FALSE))
          
        }
        
        Gs_maps_final[i] <- list(map(Gs_ords[[i]]))
      }

      # Persist ordered maps so the QTL module can access them
      rv$Gs_maps_final <- Gs_maps_final

      # Build the interactive plotly version (uses same position extraction as draw_map2)
      rv$interactive_map_obj <- build_interactive_map(Gs_maps_final, input$group_prefix)

      # Allocate a new per-session temp file for this map generation run
      rv$map_path <- tempfile(fileext = ".png")

      # Handles everything about the final linkage map
      output$elegant_plot <- renderImage(deleteFile = FALSE, {

        # Remove any leftover file from a previous render at this path
        if (!is.null(rv$map_path) && file.exists(rv$map_path))
          unlink(rv$map_path)

        # Looks familiar?
        draw_map2(Gs_maps_final, tag = "all",
                  main = input$map_title,
                  group.names = c(paste0(input$group_prefix, 1:rv$linkage_groups$n.groups)),
                  cex.label = 0.5,
                  col.group = input$LG_colour, col.tag = "black",
                  output = rv$map_path)

        # After the map has successfully been generated, re-enable the Generate map button
        shinyjs::enable("generate_linkage_map")

        # Remove the loading animation from the button
        shinyjs::removeClass(id = "UpdateAnimate", class = "loading dots")

        # Hide the "Processing. Please wait" text
        shinyjs::hide(id = "processing_status")

        # Enable the initially disabled Download button in case the user wants to download
        # the generated linkage map
        shinyjs::enable(id = "downloadMap")

        showNotification(
          "Linkage map generated \u2014 ready to download",
          type = "message", duration = 5
        )

        # Tell the renderImage function what to render and how to render it
        list(src = rv$map_path, height = "100%", width = "auto")
        })
    }
  }
  # ---------------------------------------------------------------------------
  # build_interactive_map()
  #
  # Converts rv$Gs_maps_final (a list of onemap sequence objects produced by
  # map()) into a plotly figure showing one vertical chromosome arm per
  # linkage group, with horizontal tick marks at each marker position.
  #
  # Position extraction mirrors draw_map2() internals:
  #   names  = colnames(seq$data.name$geno)[seq$seq.num]
  #   pos_cM = c(0, cumsum(onemap::kosambi(seq$seq.rf)))
  # ---------------------------------------------------------------------------
  build_interactive_map <- function(maps_final, group_prefix) {
    if (length(trimws(group_prefix)) == 0 || trimws(group_prefix) == "")
      group_prefix <- "LG "

    n_groups <- length(maps_final)

    # ---- Build tidy data.frame of marker positions -------------------------
    map_rows <- lapply(seq_len(n_groups), function(i) {
      seq_obj <- maps_final[[i]]

      # Marker names: index the global name vector with the sequence's marker indices
      markers <- colnames(seq_obj$data.name$geno)[seq_obj$seq.num]

      # cM positions: Kosambi-converted RFs → cumulative sum from 0
      pos <- if (length(seq_obj$seq.rf) > 0) {
        c(0, cumsum(onemap::kosambi(seq_obj$seq.rf)))
      } else {
        0  # single-marker LG has no inter-marker distances
      }

      data.frame(
        lg_num = i,
        lg     = paste0(group_prefix, i),
        marker = markers,
        pos_cM = round(pos, 3),
        stringsAsFactors = FALSE
      )
    })
    map_df <- do.call(rbind, map_rows)

    lg_labels <- paste0(group_prefix, seq_len(n_groups))

    # ---- Chromosome backbone: one continuous trace, NAs separate groups ----
    # Numeric x (1, 2, … n_groups) avoids plotly categorical axis issues with NA
    max_pos <- tapply(map_df$pos_cM, map_df$lg_num, max)
    x_back  <- c()
    y_back  <- c()
    for (i in seq_len(n_groups)) {
      x_back <- c(x_back, i, i, NA)
      y_back <- c(y_back, 0, max_pos[[i]], NA)
    }

    # ---- Build figure -------------------------------------------------------
    plotly::plot_ly() |>
      # Chromosome arm (thick vertical line per LG)
      plotly::add_trace(
        x          = x_back,
        y          = y_back,
        type       = "scatter",
        mode       = "lines",
        line       = list(color = "#134e4a", width = 7),
        hoverinfo  = "none",
        showlegend = FALSE,
        name       = "Chromosome arm"
      ) |>
      # Marker positions (horizontal tick marks; name + cM on hover)
      plotly::add_trace(
        data       = map_df,
        x          = ~lg_num,
        y          = ~pos_cM,
        type       = "scatter",
        mode       = "markers",
        marker     = list(
          symbol = "line-ew-open",
          size   = 20,
          line   = list(color = "#f97316", width = 2)
        ),
        text       = ~paste0(
          "<b>", marker, "</b><br>",
          pos_cM, " cM<br>",
          "<i>", lg, "</i>"
        ),
        hoverinfo  = "text",
        showlegend = FALSE,
        name       = "Marker"
      ) |>
      plotly::layout(
        xaxis = list(
          title      = list(text = "Linkage Group", standoff = 20),
          tickvals   = seq_len(n_groups),
          ticktext   = lg_labels,
          zeroline   = FALSE,
          showgrid   = FALSE,
          fixedrange = TRUE   # prevent x-zoom (only y-zoom is meaningful)
        ),
        yaxis = list(
          title      = "Position (cM)",
          autorange  = "reversed",   # 0 at top, chromosome tip at bottom
          zeroline   = FALSE,
          showgrid   = TRUE,
          gridcolor  = "#e8e8e8",
          gridwidth  = 1
        ),
        plot_bgcolor  = "#fafafa",
        paper_bgcolor = "#ffffff",
        hovermode     = "closest",
        margin        = list(t = 40, b = 70, l = 70, r = 30)
      )
  }

  # ---------------------------------------------------------------------------
  # build_rqtl_cross()
  #
  # Converts an onemap dataset + list of ordered map sequences into the
  # R/qtl `cross` object required by scanone() / cim().
  #
  # Genotype recoding (F2 intercross):
  #   onemap: 0=missing, 1=AA, 2=AB, 3=BB, 4=A_ (not-AA), 5=_B (not-BB)
  #   R/qtl:  NA=missing, 1=AA, 2=AB, 3=BB
  # Partially informative codes 4 and 5 have no R/qtl equivalent and are
  # treated as missing for standard interval mapping.
  #
  # Map positions are built from the inter-marker cM distances stored in
  # each sequence's $seq.dist slot (length = n_markers - 1).
  # ---------------------------------------------------------------------------
  build_rqtl_cross <- function(f2data, maps_final) {
    # Validate maps_final before conversion
    valid_maps <- Filter(Negate(is.null), maps_final)

    if (length(valid_maps) == 0) {
      stop("No valid linkage groups found. Complete marker ordering before running QTL analysis.")
    }

    n_groups  <- length(valid_maps)
    geno_list <- vector("list", n_groups)

    for (i in seq_len(n_groups)) {
      seq_obj  <- valid_maps[[i]]
      markers  <- seq_obj$seq.num          # global marker indices (1-based)
      dists    <- seq_obj$seq.dist         # cM gaps, length = n_markers - 1

      # Guard: empty marker list or distance vector length mismatch
      if (length(markers) == 0) next
      if (length(dists) != length(markers) - 1) {
        warning(paste0("Skipping LG", i, ": expected ", length(markers) - 1,
                       " distance(s) but seq.dist has length ", length(dists)))
        next
      }

      positions        <- c(0, cumsum(dists))
      names(positions) <- colnames(f2data$geno)[markers]

      # Extract and recode genotype matrix
      geno_mat <- f2data$geno[, markers, drop = FALSE]
      geno_mat[geno_mat == 0 | geno_mat > 3] <- NA
      storage.mode(geno_mat) <- "integer"

      geno_list[[i]] <- list(data = geno_mat, map = positions)
    }
    names(geno_list) <- paste0("LG", seq_len(n_groups))

    # Remove any NULL entries (skipped groups)
    geno_list <- Filter(Negate(is.null), geno_list)

    # Phenotype data.frame — may be absent in some MAPMAKER files
    pheno_df <- if (!is.null(f2data$pheno) && ncol(as.data.frame(f2data$pheno)) > 0) {
      as.data.frame(f2data$pheno)
    } else {
      data.frame(row.names = seq_len(f2data$n.ind))
    }

    cross <- list(geno = geno_list, pheno = pheno_df)
    class(cross) <- c("f2", "cross")
    cross
  }

  # ---------------------------------------------------------------------------
  # find_qtl_peaks()
  #
  # Given a scanone-format data.frame (columns: chr, pos, lod) and a numeric
  # threshold, returns one row per linkage group for the highest-LOD position
  # that exceeds the threshold.
  # ---------------------------------------------------------------------------
  find_qtl_peaks <- function(scan_df, threshold) {
    above <- scan_df[scan_df$lod >= threshold, , drop = FALSE]
    if (nrow(above) == 0) return(above[0, , drop = FALSE])

    chrs      <- unique(above$chr)
    peak_rows <- lapply(chrs, function(ch) {
      sub <- above[above$chr == ch, , drop = FALSE]
      sub[which.max(sub$lod), , drop = FALSE]
    })
    do.call(rbind, peak_rows)
  }

}

# Per-session temp file cleanup is handled by session$onSessionEnded() inside server()

# Run the application 
shinyApp(ui = ui, server = server)