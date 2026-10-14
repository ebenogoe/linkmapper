# Build an R/qtl cross from a Linkmapper map

Writes the mapped markers and the traits in MAPMAKER format, writes the
map with
[`onemap::write_map()`](https://rdrr.io/pkg/onemap/man/write_map.html),
and reads both with
[`qtl::read.cross()`](https://rdrr.io/pkg/qtl/man/read.cross.html).
Chromosomes are the linkage groups in map order.

## Usage

``` r
build_cross(d, m)
```

## Arguments

- d:

  The `lm_data` the map was built from.

- m:

  An `lm_map` from
  [`order_groups()`](https://ebenogoe.github.io/linkmapper/reference/order_groups.md).

## Value

An R/qtl `cross` object.
