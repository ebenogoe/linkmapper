# Order markers within each linkage group

Orders each group with the chosen algorithm and estimates map distances
with the chosen mapping function. Groups with fewer than two markers
cannot be ordered and are reported as unplaced.

## Usage

``` r
order_groups(
  groups,
  method = "record",
  map_fun = c("kosambi", "haldane"),
  seed = 1,
  progress = NULL
)
```

## Arguments

- groups:

  An `lm_groups` object from
  [`linkage_groups()`](https://ebenogoe.github.io/linkmapper/reference/linkage_groups.md).

- method:

  One of
  [`order_methods()`](https://ebenogoe.github.io/linkmapper/reference/order_methods.md).

- map_fun:

  `"kosambi"` or `"haldane"`.

- seed:

  Random seed. RECORD and UG use random starting orders, so the seed
  makes the map repeatable.

- progress:

  Optional function called with the share done (0 to 1).

## Value

An `lm_map` list with the ordered onemap sequences (`maps`), a
`positions` table and settings.
