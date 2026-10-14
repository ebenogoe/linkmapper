# Run a whole analysis from settings

Run a whole analysis from settings

## Usage

``` r
run_analysis(d, settings = default_settings(d), progress = NULL)
```

## Arguments

- d:

  An `lm_data` object as read.

- settings:

  A list like
  [`default_settings()`](https://ebenogoe.github.io/linkmapper/reference/default_settings.md).
  Steps whose entry is `NULL` are skipped.

- progress:

  Optional function called with a message at each step.

## Value

A list with `data`, `groups`, `map`, `cross` and `qtl`.
