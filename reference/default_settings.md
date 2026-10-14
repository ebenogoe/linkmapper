# Default analysis settings

Every step of the app is described by one entry in this list. The app
fills it in as you go,
[`run_analysis()`](https://ebenogoe.github.io/linkmapper/reference/run_analysis.md)
replays it, and
[`build_script()`](https://ebenogoe.github.io/linkmapper/reference/build_script.md)
turns it into R code.

## Usage

``` r
default_settings(d = NULL)
```

## Arguments

- d:

  Optional `lm_data`, used to pick the first trait.

## Value

A named list.
