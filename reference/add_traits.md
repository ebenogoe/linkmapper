# Add trait values to a dataset

Reads a CSV with one row per individual, in the same order as in the
genotype file, and one numeric column per trait. A first column named
`id`, `individual` or `ind` is ignored.

## Usage

``` r
add_traits(d, path)
```

## Arguments

- d:

  An `lm_data` object.

- path:

  Path to the CSV file.

## Value

`d` with the traits in `d$onemap$pheno` (replacing any traits from the
genotype file).
