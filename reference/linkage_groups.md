# Find linkage groups

Runs two-point analysis on every pair of markers and groups markers that
are linked at or above the LOD threshold and at or below the maximum
recombination fraction.

## Usage

``` r
linkage_groups(d, lod = NULL, max_rf = 0.5)
```

## Arguments

- d:

  An `lm_data` object.

- lod:

  LOD threshold. Defaults to
  [`suggest_lod()`](https://ebenogoe.github.io/linkmapper/reference/suggest_lod.md).

- max_rf:

  Largest recombination fraction treated as linkage.

## Value

An `lm_groups` list with the onemap `twopts` and `groups` objects and a
`table` of groups.

## Examples

``` r
# \donttest{
g <- linkage_groups(linkmapper_demo("bc"))
g$table
#>   group n_markers
#> 1     1        17
#> 2     2        28
#> 3     3        22
#>                                                                                                                                markers
#> 1                                                    M1, M2, M14, M20, M28, M37, M42, M44, M45, M47, M49, M50, M53, M58, M62, M63, M64
#> 2 M3, M4, M5, M6, M8, M9, M10, M11, M13, M16, M18, M19, M25, M26, M29, M31, M32, M34, M36, M39, M40, M41, M46, M52, M57, M59, M65, M67
#> 3                          M7, M12, M15, M17, M21, M22, M23, M24, M27, M30, M33, M35, M38, M43, M48, M51, M54, M55, M56, M60, M61, M66
# }
```
