# Read a genotype file

Reads MAPMAKER files (`.raw` or `.txt`, as used by MAPMAKER/EXP and
R/qtl) and onemap raw files. Supported populations are F2 intercross,
backcross, and recombinant inbred lines from selfing or sib mating.

## Usage

``` r
read_cross(path, name = basename(path))
```

## Arguments

- path:

  Path to the file.

- name:

  Original file name, if `path` is a temporary upload.

## Value

An `lm_data` object holding the onemap object, the population type and
the file contents.

## Examples

``` r
d <- read_cross(system.file("extdata", "mapmaker_example_bc.raw", package = "onemap"))
d
#> <Linkmapper data>
#>   Population:  Backcross 
#>   Individuals: 150 
#>   Markers:     67 
#>   Traits:      1 
```
