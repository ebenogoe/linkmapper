#' Run the Linkmapper Shiny application
#'
#' Launches the Linkmapper GUI in the default web browser (or RStudio Viewer).
#' The application provides a point-and-click workflow for linkage mapping and
#' QTL visualisation on biparental mapping populations using the onemap package
#' as the computational back-end.
#'
#' @param ... Additional arguments passed to [shiny::runApp()], such as
#'   `port`, `launch.browser`, `host`, or `display.mode`.
#'
#' @return Does not return a value; called for its side effect of launching
#'   the Shiny application. The function blocks until the app is stopped.
#'
#' @examples
#' \dontrun{
#' # Launch on a random available port and open in the default browser
#' run_linkmapper()
#'
#' # Launch on a specific port without opening a browser
#' run_linkmapper(port = 4321, launch.browser = FALSE)
#' }
#'
#' @export
run_linkmapper <- function(...) {
  required_pkgs <- c("shinyjs", "waiter", "bslib", "bsicons",
                     "qtl", "ggplot2", "plotly")
  missing_pkgs <- required_pkgs[!vapply(required_pkgs, requireNamespace,
                                        logical(1), quietly = TRUE)]
  if (length(missing_pkgs) > 0) {
    stop(
      "The following packages are required to run Linkmapper but are not ",
      "installed:\n  ", paste(missing_pkgs, collapse = ", "), "\n\n",
      "Install them with:\n",
      "  install.packages(c(\"", paste(missing_pkgs, collapse = "\", \""), "\"))",
      call. = FALSE
    )
  }

  app_dir <- system.file("app", package = "linkmapper")
  if (app_dir == "") {
    stop(
      "Could not find the Linkmapper app directory. ",
      "Try re-installing the package with: install.packages(\"linkmapper\")",
      call. = FALSE
    )
  }
  shiny::runApp(app_dir, ...)
}
