#' Validate and read a MAPMAKER linkage mapping input file
#'
#' Attempts to read a MAPMAKER-format text file using
#' [onemap::read_mapmaker()], then validates that the result is a non-empty
#' `onemap` object.  This is the first step in the Linkmapper analytical
#' workflow; all downstream functions expect the object this function returns.
#'
#' @param path Character string. Path to the `.txt` MAPMAKER input file.
#'   The file must have a `.txt` extension and be a valid MAPMAKER/onemap
#'   dataset (F2 intercross or backcross format).
#'
#' @return An `onemap` object as returned by [onemap::read_mapmaker()].
#'   Stops with an informative error if (a) the file cannot be found,
#'   (b) the extension is not `.txt`, (c) [onemap::read_mapmaker()] throws
#'   an error, (d) the result is not an `onemap` object, or (e) the dataset
#'   contains zero individuals or zero markers.
#'
#' @examples
#' \dontrun{
#' f2data <- validate_lm_file("path/to/mydata.txt")
#' f2data   # prints onemap summary: n individuals, n markers, cross type
#' }
#'
#' @export
validate_lm_file <- function(path) {
  if (!is.character(path) || length(path) != 1L) {
    stop("'path' must be a single character string.", call. = FALSE)
  }

  if (!file.exists(path)) {
    stop("File not found: ", path, call. = FALSE)
  }

  if (tools::file_ext(path) != "txt") {
    stop(
      "Expected a .txt file; got '.", tools::file_ext(path), "'. ",
      "MAPMAKER input files must have a .txt extension.",
      call. = FALSE
    )
  }

  result <- tryCatch(
    onemap::read_mapmaker(file = path),
    error = function(e) {
      stop(
        "Could not parse '", basename(path), "' as a MAPMAKER/onemap input file.\n",
        "Original error: ", conditionMessage(e),
        call. = FALSE
      )
    }
  )

  if (!inherits(result, "onemap")) {
    stop(
      "File was read but did not produce a valid onemap object. ",
      "Please verify the file is in MAPMAKER format.",
      call. = FALSE
    )
  }

  if (result$n.ind < 1 || result$n.mar < 1) {
    stop(
      "Dataset appears empty: ", result$n.ind, " individual(s), ",
      result$n.mar, " marker(s). ",
      "Please check the input file.",
      call. = FALSE
    )
  }

  result
}
