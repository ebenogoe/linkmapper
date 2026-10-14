new_state <- function() {
  shiny::reactiveValues(
    raw = NULL, data = NULL, groups = NULL, map = NULL, cross = NULL,
    qtl = NULL, settings = list(), loaded_at = 0
  )
}

step_fields <- list(
  data = "raw", qc = "data", groups = "groups", order = "map", map = character(),
  qtl = c("cross", "qtl")
)
step_settings <- list(qc = "filter", groups = "groups", order = "order", qtl = "qtl")

reset_after <- function(state, step) {
  later <- names(steps_def)[seq_along(steps_def) > match(step, names(steps_def))]
  for (s in later) {
    for (f in step_fields[[s]]) state[[f]] <- NULL
    if (!is.null(step_settings[[s]])) {
      st <- state$settings
      st[step_settings[[s]]] <- NULL
      state$settings <- st
    }
  }
  invisible(state)
}

set_setting <- function(state, key, value) {
  st <- state$settings
  st[key] <- list(value)
  state$settings <- st
}

step_status <- function(state) {
  d <- state$raw
  has_traits <- !is.null(state$data) && length(trait_names(state$data)) > 0
  list(
    data = list(done = !is.null(d), open = TRUE),
    qc = list(done = !is.null(state$data), open = !is.null(d)),
    groups = list(done = !is.null(state$groups), open = !is.null(state$data)),
    order = list(done = !is.null(state$map), open = !is.null(state$groups)),
    map = list(done = !is.null(state$map), open = !is.null(state$map)),
    qtl = list(done = !is.null(state$qtl), open = !is.null(state$map) && has_traits),
    export = list(done = FALSE, open = !is.null(state$map))
  )
}

#' The horizontal step bar
#' @noRd
stepper_ui <- function(status, current) {
  ids <- names(steps_def)
  shiny::tags$nav(
    class = "lm-stepper", `aria-label` = "Analysis steps",
    shiny::tags$ol(lapply(seq_along(ids), function(i) {
      id <- ids[i]
      s <- status[[id]]
      cls <- paste("lm-step", if (s$done) "is-done", if (!s$open) "is-locked", if (identical(id, current)) "is-current")
      shiny::tags$li(
        class = cls,
        shiny::tags$button(
          type = "button", disabled = if (!s$open) NA,
          `aria-current` = if (identical(id, current)) "step",
          title = if (!s$open) "Pending" else steps_def[[id]],
          onclick = sprintf("Shiny.setInputValue('goto_step', '%s', {priority: 'event'})", id),
          shiny::span(class = "lm-step-num", if (s$done && !identical(id, current)) bsicons::bs_icon("check-lg") else i),
          shiny::span(class = "lm-step-title", steps_def[[id]])
        )
      )
    }))
  )
}
