tmp_lines <- function(lines, ext = ".raw") {
  f <- tempfile(fileext = ext)
  writeLines(lines, f)
  f
}
