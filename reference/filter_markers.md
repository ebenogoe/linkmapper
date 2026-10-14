# Filter markers

Filter markers

## Usage

``` r
filter_markers(d, max_missing = 0.25, drop_distorted = FALSE, alpha = 0.05)
```

## Arguments

- d:

  An `lm_data` object.

- max_missing:

  Largest share of missing genotypes allowed per marker.

- drop_distorted:

  Remove markers with significant segregation distortion
  (Bonferroni-corrected).

- alpha:

  Family-wise significance level for distortion.

## Value

The filtered `lm_data`, with a `filter` element recording what was
removed.
