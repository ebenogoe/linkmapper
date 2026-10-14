#' Default analysis settings
#'
#' Every step of the app is described by one entry in this list. The app
#' fills it in as you go, [run_analysis()] replays it, and [build_script()]
#' turns it into R code.
#'
#' @param d Optional `lm_data`, used to pick the first trait.
#' @return A named list.
#' @export
default_settings <- function(d = NULL) {
  list(
    filter = list(max_missing = 0.25, drop_distorted = FALSE, alpha = 0.05),
    groups = list(lod = if (is.null(d)) NULL else suggest_lod(d), max_rf = 0.5),
    order = list(method = "record", map_fun = "kosambi", seed = 1),
    qtl = if (!is.null(d) && length(trait_names(d))) {
      list(
        trait = trait_names(d)[1], method = "hk", cim = FALSE, n_marcovar = 3,
        window = 10, n_perm = 1000, alpha = 0.05, seed = 1
      )
    }
  )
}

#' Run a whole analysis from settings
#'
#' @param d An `lm_data` object as read.
#' @param settings A list like [default_settings()]. Steps whose entry is
#'   `NULL` are skipped.
#' @param progress Optional function called with a message at each step.
#' @return A list with `data`, `groups`, `map`, `cross` and `qtl`.
#' @export
run_analysis <- function(d, settings = default_settings(d), progress = NULL) {
  say <- function(msg) if (!is.null(progress)) progress(msg)
  out <- list()
  if (!is.null(settings$filter)) {
    say("Filtering markers")
    f <- settings$filter
    d <- filter_markers(d, f$max_missing %||% 0.25, isTRUE(f$drop_distorted), f$alpha %||% 0.05)
  }
  out$data <- d
  if (is.null(settings$groups)) {
    return(out)
  }
  say("Grouping markers")
  out$groups <- linkage_groups(d, settings$groups$lod, settings$groups$max_rf %||% 0.5)
  if (is.null(settings$order)) {
    return(out)
  }
  say("Ordering markers")
  out$map <- order_groups(out$groups, settings$order$method %||% "record", settings$order$map_fun %||% "kosambi",
    seed = settings$order$seed %||% 1
  )
  q <- settings$qtl
  if (!is.null(q) && length(trait_names(d))) {
    say("Scanning for QTL")
    out$cross <- build_cross(d, out$map)
    out$qtl <- scan_qtl(out$cross, q$trait, q$method %||% "hk", isTRUE(q$cim), q$n_marcovar %||% 3,
      q$window %||% 10, q$n_perm %||% 1000, q$alpha %||% 0.05,
      seed = q$seed %||% 1
    )
  }
  out
}

#' Write an R script that repeats an analysis
#'
#' @param settings A settings list.
#' @param source List with `demo` (a demo name) or `file`, and optionally
#'   `traits` (trait file name).
#' @return A character string of R code.
#' @export
build_script <- function(settings, source) {
  L <- c(
    "# Linkmapper analysis script",
    paste0("# Written by linkmapper ", utils::packageVersion("linkmapper"), " on ", format(Sys.Date())),
    "# Install once with:",
    "# install.packages(\"linkmapper\", repos = c(\"https://ebenogoe.r-universe.dev\", \"https://cloud.r-project.org\"))",
    "",
    "library(linkmapper)",
    ""
  )
  if (!is.null(source$demo)) {
    L <- c(L, sprintf("d <- linkmapper_demo(\"%s\")", source$demo))
  } else {
    L <- c(
      L, "# Put your data file in the working directory, or give its full path",
      sprintf("d <- read_cross(\"%s\")", basename(source$file %||% "your_file.raw"))
    )
  }
  if (!is.null(source$traits)) L <- c(L, sprintf("d <- add_traits(d, \"%s\")", basename(source$traits)))
  L <- c(
    L, "", paste0("settings <- ", paste(deparse(settings, width.cutoff = 70L), collapse = "\n")), "",
    "res <- run_analysis(d, settings, progress = message)", "",
    "# Linkage groups and map",
    "res$groups",
    "map_summary(res$map)",
    "positions <- res$map$positions",
    "plot_linkage_map(res$map, res$qtl)",
    "",
    "# QTL",
    "if (!is.null(res$qtl)) {",
    "  print(res$qtl$peaks)",
    "  print(plot_lod(res$qtl))",
    "}",
    "",
    "# Save the map for MapChart or R/qtl",
    "write.csv(positions, \"linkmapper_map.csv\", row.names = FALSE)",
    ""
  )
  paste(L, collapse = "\n")
}

#' Save and restore an analysis session
#'
#' A session file is JSON holding the genotype file contents, any traits
#' and the settings. Results are recomputed when the session is opened.
#'
#' @param d The `lm_data` as read (with traits, if added).
#' @param settings The settings list.
#' @param path File to write or read.
#' @return `save_session()` returns `path` invisibly; `load_session()`
#'   returns a list with `data` and `settings`.
#' @export
save_session <- function(d, settings, path) {
  ph <- d$onemap$pheno
  obj <- list(
    app = "linkmapper", version = 1L,
    package_version = as.character(utils::packageVersion("linkmapper")),
    saved = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    lines = d$lines, source = d$source,
    traits = if (!is.null(ph)) stats::setNames(lapply(seq_len(ncol(ph)), function(k) ph[, k]), colnames(ph)),
    settings = settings
  )
  writeLines(jsonlite::toJSON(obj, auto_unbox = TRUE, null = "null", na = "null", digits = NA), path)
  invisible(path)
}

#' @rdname save_session
#' @export
load_session <- function(path) {
  obj <- tryCatch(jsonlite::fromJSON(path, simplifyVector = TRUE, simplifyDataFrame = FALSE),
    error = function(e) lm_abort("This is not a Linkmapper session file.")
  )
  if (!identical(obj$app, "linkmapper")) lm_abort("This is not a Linkmapper session file.")
  tmp <- tempfile(fileext = ".raw")
  writeLines(unlist(obj$lines), tmp)
  d <- read_cross(tmp, name = obj$source$file %||% "session")
  d$source <- utils::modifyList(d$source, obj$source %||% list())
  if (!is.null(obj$traits)) {
    vals <- lapply(obj$traits, function(v) as.numeric(unlist(lapply(v, function(e) if (is.null(e)) NA else e))))
    ph <- do.call(cbind, vals)
    colnames(ph) <- names(obj$traits)
    d$onemap$pheno <- ph
    d$onemap$n.phe <- ncol(ph)
  }
  list(data = d, settings = obj$settings)
}
