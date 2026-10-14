# Group markers (Linkmapper 0.1 interface)

Kept for scripts written for Linkmapper 0.1. Prefer
[`linkage_groups()`](https://ebenogoe.github.io/linkmapper/reference/linkage_groups.md).

## Usage

``` r
group_markers(onemap_obj, lod = 3, max_rf = 0.5, map_fun = "kosambi")
```

## Arguments

- onemap_obj:

  A onemap object.

- lod:

  LOD threshold.

- max_rf:

  Largest recombination fraction treated as linkage.

- map_fun:

  `"kosambi"` or `"haldane"`.

## Value

The onemap `group` object.
