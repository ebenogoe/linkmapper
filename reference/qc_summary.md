# Marker and individual quality summary

Missing data per marker and per individual, genotype counts, and the
chi-square test of each marker against its expected Mendelian ratio
(1:2:1, 3:1, 1:1). The significance threshold is Bonferroni-corrected
for the number of markers.

## Usage

``` r
qc_summary(d, alpha = 0.05)
```

## Arguments

- d:

  An `lm_data` object.

- alpha:

  Family-wise significance level for segregation distortion.

## Value

A list with `markers` and `individuals` data frames and the corrected
threshold `alpha_bonferroni`.
