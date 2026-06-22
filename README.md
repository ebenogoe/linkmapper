# Linkmapper

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R >= 4.1.0](https://img.shields.io/badge/R-%3E%3D%204.1.0-blue.svg)](https://cran.r-project.org/)
[![Platform: Shiny](https://img.shields.io/badge/Platform-Shiny-brightgreen.svg)](https://shiny.posit.co/)
[![Status: Active](https://img.shields.io/badge/Status-Active-success.svg)]()

Linkmapper is a free, open-source Shiny web application that provides a graphical
user interface for linkage mapping and QTL visualisation, built on the
[onemap](https://cran.r-project.org/package=onemap) R package. It is designed for
students and researchers working with biparental mapping populations (currently F2
intercrosses and backcrosses) who want to perform linkage mapping without writing
R code. Linkmapper is available as a hosted web app and as an installable R package.

---

## Features

- Five-step guided workflow with step-locking (steps unlock only when prerequisites
  are complete)
- Prior analysis: missing data visualisation and segregation distortion testing
- Marker grouping using LOD thresholds and maximum recombination frequency
- Three marker ordering algorithms: RECORD, RCD, and UG (unidirectional)
- Interactive linkage map output (plotly) and static PNG download
- QTL scanning with interval mapping (IM) and composite interval mapping (CIM)
- Downloadable results at every step (tables, plots, maps)
- No R knowledge required to use the hosted app
- Available as a hosted web app (ShinyApps.io) and as an R package for local use

---

## Workflow

Linkmapper enforces a sequential five-step pipeline. Each step unlocks only when
the previous one completes successfully, so out-of-order analysis is not possible.

```mermaid
flowchart LR
  A[("MAPMAKER .txt\nF2 or backcross")] --> B["1 · Prior analysis"]
  B --> C["2 · Marker grouping"]
  C --> D["3 · Marker ordering"]
  D --> E["4 · Linkage mapping"]
  E --> F["5 · QTL analysis"]

  style A fill:#fff7ed,stroke:#d4820a,color:#2a2520
  style B fill:#e8f2ec,stroke:#4a7c59,color:#2a2520
  style C fill:#e8f2ec,stroke:#4a7c59,color:#2a2520
  style D fill:#e8f2ec,stroke:#4a7c59,color:#2a2520
  style E fill:#e8f2ec,stroke:#4a7c59,color:#2a2520
  style F fill:#e8f2ec,stroke:#4a7c59,color:#2a2520
```

| Step | What you do | What you get |
|---|---|---|
| **1. Prior analysis** | Upload a MAPMAKER-format `.txt` file. Linkmapper reads the dataset and runs a chi-squared segregation test on every marker. | Dataset summary (individuals, markers, cross type, genotyping rate); missing data heatmap; distorted and non-distorted marker lists. Both plots download as PNG. |
| **2. Marker grouping** | Set a LOD threshold (or accept the data-suggested value from `suggest_lod()`), a maximum recombination frequency, and a mapping function (Kosambi or Haldane). Optionally inspect the RF and LOD estimate for any marker pair. | Markers assigned to linkage groups; group count and sizes; two-point RF estimates for any chosen marker pair. |
| **3. Marker ordering** | Choose an ordering algorithm: RECORD (default, minimises total recombinations), RCD (faster for large groups), or Unidirectional Growth (suited to predominantly heterozygous marker sets). Preview a single group before committing. | Ordered marker sequences within each linkage group, with log-likelihood scores. |
| **4. Linkage mapping** | Set a map title, linkage group name prefix, and chromosome colour. Generate the full multi-group map. | Publication-ready static PNG; interactive plotly map for exploring marker positions and inter-marker distances. Both are downloadable. |
| **5. QTL analysis** | Select a phenotype column from your dataset, choose interval mapping (IM) or composite interval mapping (CIM), and set a LOD significance threshold. | LOD score profile plotted across all linkage groups; QTL summary table with position, flanking markers, and LOD score. Results export as PNG and CSV. |

---

## Supported population types

| Population type | Status |
|---|---|
| F2 intercross | Supported |
| Backcross | Supported |
| RILs | Planned |
| Outcrossing populations | Planned |
| Polyploids | Planned |

---

## Data format

Linkmapper accepts genotype data in MAPMAKER `.txt` format. The file must begin with
a header line declaring the data type, number of individuals, number of markers, and
number of phenotype columns:

```
data type f2 intercross
188 62 2
```

Genotype data follows in standard MAPMAKER encoding (`A`, `B`, `H` for F2; `A`, `B`
for backcross; `-` for missing). Phenotype columns are optional but are required for
QTL analysis. A demo dataset (188 individuals, 62 markers, 2 phenotypes, F2
intercross) is bundled with the package and available from within the app.

---

## Quick start

### Hosted web app

Visit [the hosted web app](https://project-genaxy.shinyapps.io/Linkmapper/) (no installation required).

### R package (local)

```r
# Install from R-universe
install.packages("linkmapper",
  repos = "https://ebenogoe.r-universe.dev"
)

# OR install from GitHub (builds from source; needs Rtools on Windows / Xcode on macOS):
# install.packages("remotes")
remotes::install("ebenogoe/linkmapper")

# Launch the app
linkmapper::run_linkmapper()
```

---

## Package structure

```
linkmapper/                    # Package root (lowercase for CRAN)
├── DESCRIPTION
├── NAMESPACE
├── LICENSE
├── README.md
├── R/
│   ├── run_app.R              # run_linkmapper(): launches the Shiny app
│   ├── read_data.R            # validate_mapmaker_file(), read_f2_data()
│   ├── analysis.R             # prior_analysis_lm(), suggest_lod_lm()
│   ├── grouping.R             # group_markers(), twopts_analysis()
│   ├── ordering.R             # order_linkage_group()
│   ├── mapping.R              # generate_linkage_map(), draw_interactive_map()
│   └── utils.R                # Shared helpers
├── inst/
│   └── app/                   # The Shiny app lives here
│       ├── app.R
│       └── www/
├── tests/
│   └── testthat/
├── vignettes/
│   └── linkmapper-workflow.Rmd
├── data/                      # Built-in demo dataset
│   └── f2_demo.rda
└── man/                       # Auto-generated by roxygen2
```

---

## Citation

<!-- FILL: add citation once published -->

```
Ogoe, E., Obeng, M., Amoako, B. S., & Kena, A. W. (in preparation).
Linkmapper: a web application for linkage mapping and QTL visualisation.
The Plant Genome.
```

---

## Dependencies

| Package | Role |
|---|---|
| shiny | Core web application framework |
| bslib | Bootstrap 5 UI components and theming |
| shinyjs | JavaScript interactions (enable/disable UI elements) |
| waiter | Loading spinners for long-running operations |
| onemap | Linkage mapping engine (two-point analysis, grouping, ordering, map estimation) |
| qtl | QTL scanning (interval mapping and CIM) |
| ggplot2 | Static plot generation |
| plotly | Interactive linkage map output |
| bsicons | Bootstrap icons for the UI |

---

## License

MIT. See [LICENSE](LICENSE) for details.

---

## Acknowledgements

Linkmapper was developed as a final-year undergraduate dissertation project at the
Kwame Nkrumah University of Science and Technology (KNUST), Kumasi, Ghana, within
the Department of Crop and Soil Sciences, Faculty of Agriculture. The authors thank
Dr. Alexander W. Kena for supervision and guidance throughout the project.
