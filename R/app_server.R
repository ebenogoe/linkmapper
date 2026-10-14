app_server <- function(input, output, session) {
  lim <- app_limits()
  options(shiny.maxRequestSize = lim$max_upload_mb * 1024^2)
  state <- new_state()
  current <- shiny::reactiveVal("data")
  dark <- shiny::reactive(identical(input$dark_mode, "dark"))

  goto <- function(step) {
    # Use the root session so this works when called from inside a module
    bslib::nav_select("nav", "work", session = session)
    bslib::nav_select("step", step, session = session)
    current(step)
    session$sendCustomMessage("lm-scroll-top", list())
  }
  status <- shiny::reactive(step_status(state))
  output$stepper <- shiny::renderUI(stepper_ui(status(), current()))
  shiny::observeEvent(input$goto_step, {
    if (isTRUE(status()[[input$goto_step]]$open)) goto(input$goto_step)
  })

  shiny::observeEvent(input$reset_all, {
    shiny::showModal(shiny::modalDialog(
      title = "Reset the analysis?", "All data and results in this session will be cleared.",
      footer = shiny::tagList(
        shiny::modalButton("Cancel"),
        shiny::actionButton("reset_confirm", "Clear all", class = "btn-danger")
      ),
      easyClose = TRUE
    ))
  })
  shiny::observeEvent(input$reset_confirm, {
    shiny::removeModal()
    reset_after(state, "data")
    state$raw <- NULL
    state$settings <- list()
    state$loaded_at <- state$loaded_at + 1
    goto("data")
  })

  mod_home_server("home", goto = goto, dark = dark)
  mod_data_server("data", state = state, goto = goto, lim = lim)
  mod_qc_server("qc", state = state, goto = goto, dark = dark)
  mod_groups_server("groups", state = state, goto = goto, lim = lim)
  mod_order_server("order", state = state, goto = goto, dark = dark)
  mod_map_server("map", state = state, goto = goto, dark = dark)
  mod_qtl_server("qtl", state = state, goto = goto, lim = lim, dark = dark)
  mod_export_server("export", state = state, goto = goto)

  tour <- cicerone::Cicerone$new(
    allow_close = TRUE, padding = 6, opacity = 0.5, done_btn_text = "Done",
    close_btn_text = "Close", next_btn_text = "Next", prev_btn_text = "Back"
  )
  tour$step("stepper", "Workflow",
    "Seven steps from genotype file to QTL. Each step unlocks when the previous one is complete; completed steps are marked with a tick.",
    position = "bottom"
  )$
    step("data-src", "Data source", "Upload a MAPMAKER or onemap file, load a demo dataset, or resume a saved session.")$
    step("data-summary", "Summary", "Population type, individuals, markers and traits read from the file.")$
    step("dark_mode", "Theme", "Switch between light and dark themes. Downloads always use a white background.")
  start_tour <- function() {
    goto("data")
    tour$init()$start()
  }
  shiny::observeEvent(input$start_tour, start_tour())
  shiny::observeEvent(input$lm_first_visit, if (isTRUE(input$lm_first_visit)) tour$init()$start())
  mod_guide_server("guide", goto = goto, start_tour = start_tour)
}
