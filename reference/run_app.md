# Run the Linkmapper app

`run_linkmapper()` is the name used in Linkmapper 0.1 and still works.

## Usage

``` r
run_app(
  onStart = NULL,
  options = list(),
  enableBookmarking = NULL,
  uiPattern = "/",
  ...
)

run_linkmapper(...)
```

## Arguments

- onStart, options, enableBookmarking, uiPattern:

  Passed to
  [`shiny::shinyApp()`](https://rdrr.io/pkg/shiny/man/shinyApp.html).

- ...:

  Options passed to the app as golem options.

## Value

A Shiny app object.

## Examples

``` r
if (interactive()) run_app()
```
