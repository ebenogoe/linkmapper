# Changelog

## linkmapper 0.2.0

A rewrite of the app as a modular package.

### New

- Backcross and recombinant inbred line populations, alongside F2
  intercrosses; onemap raw files as well as MAPMAKER.
- Trait files in CSV, in addition to traits in the genotype file.
- Segregation tests with Bonferroni correction, missing-data summaries
  and marker filters.
- Seriation ordering, Haldane distances, and recombination-fraction
  heatmaps per linkage group.
- Interactive linkage map with QTL support intervals; MapChart, CSV and
  Excel exports.
- QTL mapping with R/qtl: Haley-Knott, EM or imputation interval mapping
  and composite interval mapping, permutation thresholds, 1.5-LOD
  support intervals, variance explained, effects and genotype plots.
- HTML report, reproducible R script and session files; PNG, SVG and PDF
  for every figure.
- Horizontal step bar, guided tour, dark mode and its own visual
  identity.
- [`read_cross()`](https://ebenogoe.github.io/linkmapper/reference/read_cross.md),
  [`qc_summary()`](https://ebenogoe.github.io/linkmapper/reference/qc_summary.md),
  [`filter_markers()`](https://ebenogoe.github.io/linkmapper/reference/filter_markers.md),
  [`linkage_groups()`](https://ebenogoe.github.io/linkmapper/reference/linkage_groups.md),
  [`order_groups()`](https://ebenogoe.github.io/linkmapper/reference/order_groups.md),
  [`build_cross()`](https://ebenogoe.github.io/linkmapper/reference/build_cross.md),
  [`scan_qtl()`](https://ebenogoe.github.io/linkmapper/reference/scan_qtl.md),
  [`run_analysis()`](https://ebenogoe.github.io/linkmapper/reference/run_analysis.md)
  and related functions are exported.

### Fixed

- Analysis state was held in global variables, so sessions on the hosted
  app could interfere with each other.
- The QTL step did not detect QTL on the demo data.
- The map image was written to the working directory.
- Marker ordering was not reproducible between runs.

### Compatibility

- [`run_linkmapper()`](https://ebenogoe.github.io/linkmapper/reference/run_app.md),
  [`validate_lm_file()`](https://ebenogoe.github.io/linkmapper/reference/validate_lm_file.md)
  and
  [`group_markers()`](https://ebenogoe.github.io/linkmapper/reference/group_markers.md)
  keep their 0.1 behaviour.
