# Scan for QTL

Interval mapping
([`qtl::scanone()`](https://rdrr.io/pkg/qtl/man/scanone.html)) or
composite interval mapping
([`qtl::cim()`](https://rdrr.io/pkg/qtl/man/cim.html)) for one trait,
with a genome-wide LOD threshold from permutations (Churchill and Doerge
1994). For each linkage group whose highest LOD passes the threshold,
the peak is reported with its 1.5-LOD support interval, nearest marker,
genome-wide p-value, percentage of phenotypic variance explained and
estimated effects.

## Usage

``` r
scan_qtl(
  cross,
  trait = NULL,
  method = "hk",
  cim = FALSE,
  n_marcovar = 3,
  window = 10,
  n_perm = 1000,
  alpha = 0.05,
  step = 1,
  seed = 1,
  progress = NULL
)
```

## Arguments

- cross:

  A cross from
  [`build_cross()`](https://ebenogoe.github.io/linkmapper/reference/build_cross.md).

- trait:

  Trait name.

- method:

  One of
  [`qtl_methods()`](https://ebenogoe.github.io/linkmapper/reference/qtl_methods.md).

- cim:

  Use composite interval mapping.

- n_marcovar, window:

  Marker covariates and window (cM) for CIM.

- n_perm:

  Number of permutations.

- alpha:

  Genome-wide significance level.

- step:

  Spacing (cM) of the scan.

- seed:

  Random seed.

- progress:

  Optional function called with the share done (0 to 1).

## Value

An `lm_qtl` list.
