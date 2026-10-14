# linkmapper 0.2.0

A rewrite of the app as a modular package.

## New

* Backcross and recombinant inbred line populations, alongside F2 intercrosses; onemap raw files as well as MAPMAKER.
* Trait files in CSV, in addition to traits in the genotype file.
* Segregation tests with Bonferroni correction, missing-data summaries and marker filters.
* Seriation ordering, Haldane distances, and recombination-fraction heatmaps per linkage group.
* Interactive linkage map with QTL support intervals; MapChart, CSV and Excel exports.
* QTL mapping with R/qtl: Haley-Knott, EM or imputation interval mapping and composite interval mapping, permutation thresholds, 1.5-LOD support intervals, variance explained, effects and genotype plots.
* HTML report, reproducible R script and session files; PNG, SVG and PDF for every figure.
* Horizontal step bar, guided tour, dark mode and its own visual identity.
* `read_cross()`, `qc_summary()`, `filter_markers()`, `linkage_groups()`, `order_groups()`, `build_cross()`, `scan_qtl()`, `run_analysis()` and related functions are exported.

## Fixed

* Analysis state was held in global variables, so sessions on the hosted app could interfere with each other.
* The QTL step did not detect QTL on the demo data.
* The map image was written to the working directory.
* Marker ordering was not reproducible between runs.

## Compatibility

* `run_linkmapper()`, `validate_lm_file()` and `group_markers()` keep their 0.1 behaviour.
