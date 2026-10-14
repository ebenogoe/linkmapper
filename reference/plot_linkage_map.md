# Draw a linkage map

Each linkage group is a vertical bar with positions (cM) on the left and
marker names on the right. Labels are spread so they do not overlap. QTL
support intervals from
[`scan_qtl()`](https://ebenogoe.github.io/linkmapper/reference/scan_qtl.md)
can be drawn beside the groups.

## Usage

``` r
plot_linkage_map(m, qtl = NULL, dark = FALSE, label_size = 2.9, title = NULL)
```

## Arguments

- m:

  An `lm_map` from
  [`order_groups()`](https://ebenogoe.github.io/linkmapper/reference/order_groups.md),
  or any list with a `positions` data frame (columns `lg`, `marker`,
  `position`).

- qtl:

  Optional `lm_qtl` from
  [`scan_qtl()`](https://ebenogoe.github.io/linkmapper/reference/scan_qtl.md),
  or a list with a `peaks` data frame and a `trait`.

- dark:

  Colours for a dark background.

- label_size:

  Text size.

- title:

  Optional title.

## Value

A ggplot object (interactive with
[`ggiraph::girafe()`](https://davidgohel.github.io/ggiraph/reference/girafe.html)).
