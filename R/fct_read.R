lm_abort <- function(...) stop(paste0(...), call. = FALSE)

`%||%` <- function(a, b) if (is.null(a)) b else a

cross_types <- c(
  f2 = "F2 intercross", backcross = "Backcross",
  riself = "RIL (selfing)", risib = "RIL (sib mating)"
)

cross_label <- function(type) unname(cross_types[type])

cross_type_of <- function(obj) {
  hit <- intersect(names(cross_types), class(obj))
  if (!length(hit)) lm_abort("Unsupported population type: ", paste(class(obj), collapse = ", "), ".")
  hit[1]
}

new_lm_data <- function(obj, lines, source = list()) {
  structure(
    list(onemap = obj, type = cross_type_of(obj), lines = lines, source = source),
    class = "lm_data"
  )
}

#' @export
print.lm_data <- function(x, ...) {
  cat("<Linkmapper data>\n")
  cat("  Population: ", cross_label(x$type), "\n")
  cat("  Individuals:", x$onemap$n.ind, "\n")
  cat("  Markers:    ", x$onemap$n.mar, "\n")
  cat("  Traits:     ", if (is.null(x$onemap$pheno)) 0 else ncol(x$onemap$pheno), "\n")
  invisible(x)
}

#' Read a genotype file
#'
#' Reads MAPMAKER files (`.raw` or `.txt`, as used by MAPMAKER/EXP and
#' R/qtl) and onemap raw files. Supported populations are F2 intercross,
#' backcross, and recombinant inbred lines from selfing or sib mating.
#'
#' @param path Path to the file.
#' @param name Original file name, if `path` is a temporary upload.
#' @return An `lm_data` object holding the onemap object, the population
#'   type and the file contents.
#' @export
#' @examples
#' d <- read_cross(system.file("extdata", "mapmaker_example_bc.raw", package = "onemap"))
#' d
read_cross <- function(path, name = basename(path)) {
  if (!file.exists(path)) lm_abort("File not found: ", name)
  lines <- readLines(path, warn = FALSE)
  lines <- sub("^\ufeff", "", lines)
  first <- trimws(lines[nzchar(trimws(lines))][1])
  if (is.na(first) || !grepl("^data type", first, ignore.case = TRUE)) {
    lm_abort(
      "The first line must state the population, for example 'data type f2 intercross'. ",
      "Linkmapper reads MAPMAKER and onemap raw files."
    )
  }
  if (grepl("outcross", first, ignore.case = TRUE)) {
    lm_abort("Outcross (full-sib) populations are not supported. Use F2, backcross or RIL data.")
  }
  second <- strsplit(trimws(lines[which(nzchar(trimws(lines)))[2]]), "\\s+")[[1]]
  format <- if (length(second) >= 5) "onemap" else "mapmaker"
  tmp <- tempfile(fileext = ".raw")
  writeLines(lines, tmp)
  obj <- tryCatch(
    quiet(if (format == "onemap") onemap::read_onemap(inputfile = tmp) else onemap::read_mapmaker(file = tmp)),
    error = function(e) lm_abort("Could not read ", name, " as a ", format, " file: ", conditionMessage(e))
  )
  if (obj$n.ind < 2 || obj$n.mar < 2) lm_abort("The file needs at least two individuals and two markers.")
  new_lm_data(obj, lines, source = list(file = name, format = format))
}

#' Check that a file can be read
#'
#' Kept from Linkmapper 0.1 for scripts that use it. Prefer [read_cross()].
#'
#' @param path Path to a MAPMAKER or onemap file.
#' @return A onemap object.
#' @export
validate_lm_file <- function(path) {
  if (!is.character(path) || length(path) != 1L) {
    lm_abort("'path' must be a single character string.")
  }
  if (!file.exists(path)) lm_abort("File not found: ", path)
  if (!tolower(tools::file_ext(path)) %in% c("txt", "raw")) {
    lm_abort("Expected a .txt or .raw file; got '.", tools::file_ext(path), "'.")
  }
  read_cross(path)$onemap
}

# Run onemap code without its console output
quiet <- function(expr) {
  out <- NULL
  utils::capture.output(out <- suppressWarnings(suppressMessages(expr)))
  out
}

#' Add trait values to a dataset
#'
#' Reads a CSV with one row per individual, in the same order as in the
#' genotype file, and one numeric column per trait. A first column named
#' `id`, `individual` or `ind` is ignored.
#'
#' @param d An `lm_data` object.
#' @param path Path to the CSV file.
#' @return `d` with the traits in `d$onemap$pheno` (replacing any traits
#'   from the genotype file).
#' @export
add_traits <- function(d, path) {
  tab <- utils::read.csv(path, check.names = FALSE, na.strings = c("", "NA", "-", "."))
  if (tolower(names(tab)[1]) %in% c("id", "individual", "ind", "sample", "line")) tab <- tab[-1]
  num <- vapply(tab, is.numeric, logical(1))
  if (!any(num)) lm_abort("The trait file has no numeric columns.")
  if (nrow(tab) != d$onemap$n.ind) {
    lm_abort(
      "The trait file has ", nrow(tab), " rows but the genotype file has ",
      d$onemap$n.ind, " individuals. Rows must match individuals in order."
    )
  }
  ph <- as.matrix(tab[, num, drop = FALSE])
  colnames(ph) <- make.names(colnames(ph), unique = TRUE)
  d$onemap$pheno <- ph
  d$onemap$n.phe <- ncol(ph)
  d$source$traits <- basename(path)
  d
}

trait_names <- function(d) {
  if (is.null(d$onemap$pheno)) character() else colnames(d$onemap$pheno)
}

# Letters for each onemap genotype code, by segregation type
geno_letters <- list(
  "A.H.B" = c("A", "H", "B"),
  "C.A" = c("C", "A"),
  "D.B" = c("D", "B"),
  "A.H" = c("A", "H"),
  "A.B" = c("A", "-", "B")
)

mapmaker_header <- c(
  f2 = "data type f2 intercross", backcross = "data type f2 backcross",
  riself = "data type ri self", risib = "data type ri sib"
)

#' Write a dataset in MAPMAKER format
#'
#' Used to pass data from onemap to R/qtl, and useful for exporting a
#' filtered dataset.
#'
#' @param d An `lm_data` object.
#' @param file Output path.
#' @return `file`, invisibly.
#' @export
write_mapmaker <- function(d, file) {
  obj <- d$onemap
  g <- obj$geno
  ph <- obj$pheno
  out <- c(mapmaker_header[[d$type]], paste(obj$n.ind, obj$n.mar, if (is.null(ph)) 0 else ncol(ph)))
  for (j in seq_len(ncol(g))) {
    lett <- geno_letters[[obj$segr.type[j]]]
    if (is.null(lett)) lm_abort("Unsupported marker type: ", obj$segr.type[j])
    v <- ifelse(g[, j] == 0, "-", lett[pmax(1, g[, j])])
    out <- c(out, paste0("*", colnames(g)[j], " ", paste(v, collapse = " ")))
  }
  if (!is.null(ph)) {
    for (k in seq_len(ncol(ph))) {
      v <- ifelse(is.na(ph[, k]), "-", format(ph[, k], digits = 8, trim = TRUE))
      out <- c(out, paste0("*", colnames(ph)[k], " ", paste(v, collapse = " ")))
    }
  }
  writeLines(out, file)
  invisible(file)
}

#' Demo datasets
#'
#' The F2 and backcross demos are the simulated example data shipped with
#' onemap (200 and 150 individuals, one trait each). The RIL demo is
#' onemap's selfed RIL example (100 lines, no traits). `small` is the
#' 20-individual F2 file from the 2022 Linkmapper.
#'
#' @return `demo_info()` returns a data frame describing each dataset.
#' @export
demo_info <- function() {
  data.frame(
    name = c("f2", "bc", "ril", "small"),
    title = c("F2 intercross", "Backcross", "Recombinant inbred lines", "Small F2"),
    description = c(
      "200 simulated F2 plants, 66 markers (36 codominant, 30 dominant) and one quantitative trait. From the onemap package.",
      "150 simulated backcross plants, 67 markers and one quantitative trait. From the onemap package.",
      "100 simulated selfed RILs and 68 markers, no traits. From the onemap package.",
      "20 F2 plants and 10 markers in two linkage groups. The demo file from the 2022 Linkmapper."
    ),
    stringsAsFactors = FALSE
  )
}

#' @rdname demo_info
#' @param name One of `demo_info()$name`.
#' @return `linkmapper_demo()` returns an `lm_data` object.
#' @export
linkmapper_demo <- function(name = c("f2", "bc", "ril", "small")) {
  name <- match.arg(name)
  path <- switch(name,
    f2 = system.file("extdata", "mapmaker_example_f2.raw", package = "onemap", mustWork = TRUE),
    bc = system.file("extdata", "mapmaker_example_bc.raw", package = "onemap", mustWork = TRUE),
    ril = system.file("extdata", "onemap_example_riself.raw", package = "onemap", mustWork = TRUE),
    small = system.file("extdata", "f2_small.txt", package = "linkmapper", mustWork = TRUE)
  )
  d <- read_cross(path)
  d$source$file <- paste("Demo:", demo_info()$title[demo_info()$name == name])
  d$source$demo <- name
  d
}
