# Write a self-contained HTML report

Write a self-contained HTML report

## Usage

``` r
build_report(res, settings = list(), path, title = "Linkmapper report")
```

## Arguments

- res:

  A list with any of `raw`, `data`, `qc`, `groups`, `map` and `qtl`, as
  produced by the app or by
  [`run_analysis()`](https://ebenogoe.github.io/linkmapper/reference/run_analysis.md).

- settings:

  The settings list.

- path:

  Output file.

- title:

  Report title.

## Value

`path`, invisibly.
