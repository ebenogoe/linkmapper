app_ui <- function(request) {
  lim <- app_limits()
  shiny::tagList(
    golem_add_external_resources(),
    bslib::page_navbar(
      id = "nav",
      title = shiny::tags$span(
        class = "lm-brand",
        shiny::tags$img(src = "www/logo.svg", alt = "", width = 26, height = 26),
        shiny::tags$span("Linkmapper")
      ),
      window_title = "Linkmapper: linkage maps and QTL without code",
      theme = lm_theme(),
      fillable = FALSE,
      lang = "en",
      navbar_options = bslib::navbar_options(collapsible = TRUE, theme = "dark"),
      header = shiny::useBusyIndicators(spinners = TRUE, pulse = TRUE),
      bslib::nav_panel("Home", value = "home", icon = bsicons::bs_icon("house"), mod_home_ui("home")),
      bslib::nav_panel("Workspace", value = "work", icon = bsicons::bs_icon("bar-chart-steps"), workspace_ui(lim)),
      bslib::nav_panel("Guide", value = "guide", icon = bsicons::bs_icon("book"), mod_guide_ui("guide")),
      bslib::nav_panel("About", value = "about", icon = bsicons::bs_icon("info-circle"), mod_about_ui("about")),
      bslib::nav_spacer(),
      bslib::nav_item(shiny::tags$a(
        class = "nav-link lm-icon-link", href = "https://github.com/ebenogoe/linkmapper",
        target = "_blank", rel = "noopener", `aria-label` = "Source code on GitHub",
        bsicons::bs_icon("github"), shiny::span(class = "d-lg-none ms-2", "Source code")
      )),
      bslib::nav_item(bslib::input_dark_mode(id = "dark_mode", mode = "light")),
      footer = lm_footer()
    )
  )
}

workspace_ui <- function(lim) {
  shiny::div(
    class = "lm-workspace",
    shiny::div(
      class = "lm-stepbar",
      # uiOutput containers have no box of their own, so the tour targets this wrapper
      shiny::div(id = "tour-steps", class = "lm-stepper-wrap", shiny::uiOutput("stepper")),
      shiny::div(
        class = "lm-stepbar-tools",
        shiny::actionLink("start_tour", shiny::tagList(bsicons::bs_icon("signpost-split"), "Tour")),
        shiny::actionLink("reset_all", shiny::tagList(bsicons::bs_icon("arrow-counterclockwise"), "Reset"))
      )
    ),
    shiny::div(
      class = "lm-stage",
      if (lim$hosted) {
        shiny::p(
          class = "lm-hosted-note",
          sprintf(
            "Hosted version: files up to %d MB, %s markers and %s permutations. Install the package for larger analyses.",
            lim$max_upload_mb, fmt_n(lim$max_markers), fmt_n(lim$max_perm)
          )
        )
      },
      bslib::navset_hidden(
        id = "step",
        bslib::nav_panel_hidden("data", mod_data_ui("data")),
        bslib::nav_panel_hidden("qc", mod_qc_ui("qc")),
        bslib::nav_panel_hidden("groups", mod_groups_ui("groups")),
        bslib::nav_panel_hidden("order", mod_order_ui("order")),
        bslib::nav_panel_hidden("map", mod_map_ui("map")),
        bslib::nav_panel_hidden("qtl", mod_qtl_ui("qtl")),
        bslib::nav_panel_hidden("export", mod_export_ui("export"))
      )
    )
  )
}

lm_footer <- function() {
  shiny::tags$footer(
    class = "lm-footer",
    shiny::div(shiny::HTML(sprintf(
      'Linkmapper %s. Created by Ebenezer Ogoe, Michael Obeng and Stephen Amoako (KNUST, 2022). Maintained by <a href="https://ebenezerogoe.com" target="_blank" rel="noopener">Ebenezer Ogoe</a>.',
      utils::packageVersion("linkmapper")
    ))),
    shiny::div(
      shiny::tags$a(href = "https://github.com/ebenogoe/linkmapper", target = "_blank", rel = "noopener", "Source"),
      shiny::span(class = "lm-sep", "\u00b7"), shiny::span("MIT licence")
    )
  )
}

golem_add_external_resources <- function() {
  golem::add_resource_path("www", app_sys("app/www"))
  shiny::tags$head(
    golem::favicon(ext = "svg"),
    shiny::tags$meta(name = "description", content = "Genetic linkage maps and QTL mapping for F2, backcross and RIL populations, without code."),
    golem::bundle_resources(path = app_sys("app/www"), app_title = "Linkmapper"),
    cicerone::use_cicerone()
  )
}
