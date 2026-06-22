# CLAUDE.md — Linkmapper Project

> This file is read by Claude Code at the start of every session.
> It contains everything Claude needs to understand the project, make good decisions,
> and avoid breaking things. Keep it updated as the project evolves.

---

## 1. Project Identity

**Tool name:** Linkmapper  
**What it does:** A GUI-based Shiny web application that wraps the `onemap` R package
to let users perform linkage mapping and QTL visualisation on biparental mapping
populations (currently F2 intercrosses and backcrosses) without writing any code.  
**Primary users:** Students and instructors in molecular genetics / agricultural
biotechnology; researchers who want a GUI alternative to scripting onemap directly.  
**Original context:** Final-year undergraduate dissertation, KNUST (Kwame Nkrumah
University of Science and Technology), Ghana, 2022. Supervisor: Dr. Alexander W. Kena.  
**Authors:** Ogoe Ebenezer, Obeng Michael, Amoako Barnie Stephen.

**Publication goal:** Adapt and publish as a peer-reviewed software paper. Primary target
journal: *The Plant Genome* (Wiley). Stretch target: *Bioinformatics* (OUP).  
**Package goal:** Wrap the Shiny app as an installable R package on R-universe first,
then CRAN. The package will let users run the app locally via a single `run_linkmapper()`
call, supported by exported utility functions.

---

## 2. Repository Layout

```
Linkmapper/
├── app.R                  # Single-file Shiny app — the ENTIRE application
├── app.R.bak              # Backup of app.R — DO NOT MODIFY OR DELETE
├── Linkmapper.Rproj       # RStudio project file
├── README.md
├── rsconnect/             # ShinyApps.io deployment metadata — DO NOT MODIFY
│   └── shinyapps.io/
│       └── project-genaxy/
│           └── Linkmapper.dcf
└── www/                   # Static assets served by Shiny
    ├── Faculty_logo.jpg
    ├── KNUST_logo.jpg
    ├── Montserrat-Regular.otf
    ├── styler.css         # Custom CSS — modify with care
    ├── Welcome.html       # Welcome page content
    └── Welcome.html.bak   # Backup — DO NOT MODIFY OR DELETE
```

**Future layout (R package):** See Section 9.

---

## 3. Current app.R Architecture

The app is a standard single-file Shiny app (lines 1–537) with this structure:

### Dependencies (lines 1–7)
```r
library(shiny)
library(shinyjs)
library(tools)
library(ggplot2)
library(onemap)
library(shinydashboard)
library(shinydashboardPlus)
```

### UI (lines 9–210)
Built with `dashboardPage()` from `shinydashboard`. Four functional modules plus
Welcome, Help, and About Us pages.

| Module | Tab name | Purpose |
|--------|----------|---------|
| 1 | `analysis_page` | Prior analysis — upload TXT, missing data plot, segregation distortion |
| 2 | `grouping_page` | Marker grouping — LOD, max RF, mapping function, two-point analysis |
| 3 | `ordering_page` | Marker ordering — RECORD / RCD / UNIDIRECTIONAL algorithms |
| 4 | `mapping_page` | Generate final linkage map — title, prefix, colour, download |

### Server (lines 214–529)
Organised into four explicit sections (comments in code):

- **Section 1** (lines 216–226): Global variables — `reactiveValues`, bare variables
  (`code_succeeded`, `linkage_groups`, `f2data`, etc.)
- **Section 2** (lines 229–301): `observeEvent()` expressions — button click handlers
  with `tryCatch` wrappers
- **Section 3** (lines 305–355): `observe()` expressions + download handlers
- **Section 4** (lines 359–528): Core functions — `prior_analysis()`, `groupings()`,
  `twoptsAnalysis()`, `orderLG()`, `elegant_map_generator()`

### Key onemap workflow
```
read_mapmaker() → test_segregation() → rf_2pts() → group() → make_seq() →
record()/rcd()/ug() → map() → draw_map2()
```

---

## 4. Known Code Quality Issues (Audit)

These are the areas Claude Code should fix. Fix them incrementally — do not refactor
everything in one session.

### 4.1 Critical bugs / correctness issues
- `elegant_map_generator()` uses `code_succeeded` (a bare global, line 221) as a
  dependency guard, but `code_succeeded` is never reset when a new file is uploaded.
  A session with a failed upload followed by a valid one may behave unexpectedly.
- The `Gs_groups`, `Gs_ords`, `Gs_maps`, `Gs_maps_final` vectors are initialised with
  `numeric(n.groups)` (lines 473–476) but used as lists. Should be `vector("list", n.groups)`.
- `generated_map.png` is written to the working directory (line 508), which is
  problematic in multi-user or containerised deployments. Should use `tempfile()`.
- Section 1 mixes `reactiveValues` with bare global assignment (`<<-`). The bare
  globals are not reactive and create subtle state bugs across sessions.

### 4.2 Best practice violations
- Bare `<<-` assignments used throughout Section 4 to mutate globals from inside
  functions — anti-pattern in Shiny; all shared state should go through `reactiveValues`.
- `observeEvent()` wraps a `reactive()` call inside it (lines 234–235, 251–252, etc.) —
  this is incorrect usage. `reactive()` should be defined outside `observeEvent()`.
- `output$*` assignments inside non-reactive helper functions (e.g., `prior_analysis()`,
  `groupings()`) — side-effect-heavy functions that are hard to test and debug.
- No input validation beyond file extension check. Malformed but `.txt`-named files
  will crash with an unhelpful error.
- `tryCatch` error messages concatenate with `sep = "\n"` but `paste()` doesn't use
  `sep` the same way as `paste0()` — minor but inconsistent.
- `disabled()` on a `downloadButton` before the map is generated is correct, but
  `shinyjs::enable()` is called inside `renderImage()`, which is a side effect inside
  a render function — fragile.
- Icon names use `verify_fa = FALSE` throughout, suppressing Font Awesome warnings
  rather than fixing them. Update to valid FA6 icon names.

### 4.3 UI / UX issues
- The current UI uses `shinydashboard` which renders a flat, dated AdminLTE2 look.
  Target: migrate to `bslib` with Bootstrap 5 for a modern, card-based layout.
- All sidebar icons are `icon("gears")` — non-descriptive; should use meaningful icons
  per module (e.g., `microscope`, `diagram-project`, `map`, `download`).
- No progress indicator for long-running operations (ordering + map generation can
  take minutes). Implement `shiny::withProgress()` or a `waiter` spinner.
- No persistent state between modules — if the user refreshes or navigates away,
  all uploaded data is lost. Consider `shinyjs::extendShinyjs()` or `session`-scoped
  `reactiveValues` with a clear workflow indicator showing which steps are complete.
- Welcome page is a static HTML file (`Welcome.html`) — replace with a proper Shiny
  `tabItem` using `bslib` cards and embedded sample data download link.

---

## 5. Planned New Features (for publication)

Add these features to strengthen the paper's contribution. Implement in order of priority:

### Priority 1 — Core feature gaps
- [ ] **QTL scanning module (Module 5):** Expose `onemap`'s QTL scanning capability.
  Accept phenotype data, run interval mapping or CIM, display LOD score profile,
  export QTL table. This is the biggest gap between current state and publication-ready.
- [ ] **Backcross support:** The app currently accepts F2 data via `read_mapmaker()`.
  Add explicit UI pathway and validation for backcross populations.
- [ ] **Interactive linkage map:** Replace the static PNG output from `draw_map2()` with
  an interactive plot using `plotly` — allow hover-to-see-marker-info.

### Priority 2 — Usability improvements
- [ ] **Sample data download:** Provide the F2 demo dataset as a downloadable file from
  within the app so users can try it immediately without hunting for test data.
- [ ] **Workflow progress indicator:** Visual stepper (Module 1 → 2 → 3 → 4) showing
  which steps are complete, locked, or available. Prevents out-of-order usage errors.
- [ ] **Results summary table:** Downloadable CSV of marker statistics per linkage group
  (currently displayed only as console text).
- [ ] **Export to Excel:** Add `.xlsx` export of marker statistics table using `openxlsx`.

### Priority 3 — Polish
- [ ] **Help tooltips:** Inline `?` tooltips (using `shinyBS` or `bslib` popovers) for
  technical parameters (LOD threshold, mapping functions, ordering algorithms).
- [ ] **Dark mode toggle:** Trivial with `bslib` — adds perceived modernity.
- [ ] **Responsive layout:** Test and fix on tablet/mobile screen widths.

---

## 6. UI Redesign Guidelines

When redesigning the UI, follow these principles:

- **Framework:** Migrate from `shinydashboard` to `bslib` (Bootstrap 5). Use
  `bslib::page_navbar()` as the top-level container.
- **Cards:** Use `bslib::card()` with `card_header()` and `card_body()` for each
  module section. Avoid raw `sidebarPanel()` / `mainPanel()` layout.
- **Colour palette:** Keep the existing blue accent (`#2c3e50` header,
  `#3498db` primary action). Do not introduce more than 3 brand colours.
- **Typography:** Montserrat is already in `www/` — ensure it loads correctly via
  `@font-face` in `styler.css`. Use 16px base, 1.5 line-height for body text.
- **Shadows and depth:** Use `box-shadow: 0 2px 8px rgba(0,0,0,0.12)` on cards —
  this alone eliminates the "flat" feel of the current AdminLTE2 theme.
- **Buttons:** Use Bootstrap 5 filled primary buttons for main actions, outline
  secondary for downloads. Never use bare `actionButton()` without a class.
- **Icons:** Use Font Awesome 6 free icons. Valid names for each module:
  `fa-flask` (prior analysis), `fa-layer-group` (grouping),
  `fa-sort-numeric-up` (ordering), `fa-map` (linkage map), `fa-chart-line` (QTL).

---

## 7. R Package Architecture (Target)

When converting to an R package, use this structure:

```
linkmapper/                    # Package root (lowercase for CRAN)
├── DESCRIPTION
├── NAMESPACE
├── LICENSE
├── README.md
├── R/
│   ├── run_app.R              # run_linkmapper() — launches the Shiny app
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

**Key decisions:**
- `run_linkmapper()` calls `shiny::runApp(system.file("app", package = "linkmapper"))`.
- All utility functions in `R/` are exported and documented with `roxygen2`.
- The demo F2 dataset is bundled as `data/f2_demo.rda` and accessible as `linkmapper::f2_demo`.
- R-universe: add a `universe` field to DESCRIPTION or maintain a `packages.json`
  in a separate `<username>/universe` repo.
- CRAN: run `devtools::check()` with zero errors/warnings/notes before submission.
  Key CRAN requirements: no `library()` calls inside package code (use `::` notation),
  no internet access in tests, all examples must run in < 5s or be wrapped in `\dontrun{}`.

---

## 8. Manuscript Notes (for the journal paper)

### What to keep from the dissertation
- The linkage mapping case study motivation (Section 2.1.1) — tighten to ~2 paragraphs.
- The onemap workflow description (Section 3.6) — reframe as "Implementation" section.
- Table 4.1 marker statistics — keep as a results validation example.
- Figure 4.6 (final linkage map) — keep as the primary results figure.

### What to drop entirely
- All Clusnalyst content (Sections 3.7, 4.2, 5.2) — out of scope for this paper.
- Section 2.3 (R language overview) — too introductory for a research journal.
- Section 2.3.1 (R technical specs) — not relevant.
- Dedication, Acknowledgements (dissertation boilerplate).
- Stack Overflow visits chart (Figure 2.5) — too dated (2017 data).
- WebGimm section (2.2.4) — JWS-specific critique is now moot; WebGimm is dead.
  Mention briefly or drop.

### Claims requiring citation verification (DO NOT assume these are valid)
- "CRAN currently contains over 10,000 packages" — as of dissertation (2022) this was
  true but the number is now higher. **Verify current count at cran.r-project.org.**
- Robinson (2017) Stack Overflow R growth post — **verify URL still resolves.**
- Margarido et al. (2007) onemap paper — **verify this is the correct/primary citation
  for onemap; there may be a more recent paper (e.g., Gesteira et al., 2023 for onemap3).**
- JoinMap license fees — these change. **Do not cite specific prices; describe as
  "commercially licensed."**
- WebGimm (Joshi et al., 2011) — the claim that JWS was phased out by March 2025
  is factually accurate but should be reframed as historical context.
- Chao et al. (2021) MG2C citation — **verify this is still an appropriate comparator;
  confirm MG2C is still accessible and maintained.**

### Outdated facts to update
- R version 4.0.3 / 4.1.2 mentioned in methodology — update to current version used.
- RStudio version 2022.07.1 — update to current Posit IDE version.
- `shinydashboard` / `shinydashboardPlus` as primary UI packages — if migrating to
  `bslib`, update the methodology accordingly.
- ShinyApps.io free tier limits have changed since 2022 — verify current limits.

### Structural changes for journal submission
- Add an **Availability** section: GitHub URL, R-universe URL, DOI (Zenodo).
- Add a **Comparison table** of Linkmapper vs. existing tools (MAPMAKER, JoinMap,
  LinkageMapView, MG2C) across dimensions: open source, GUI, web-based,
  QTL support, cross types supported, active maintenance.
- Add a **Limitations** section — honest about F2/backcross only, no polyploid support,
  ShinyApps.io free tier concurrency limits.
- Results section must show the new features added (QTL module, interactive map)
  not just the original undergraduate demo run.

---

## 9. Hard Rules for Claude Code

**NEVER do these without explicit instruction:**
- Modify or delete `app.R.bak`, `Welcome.html.bak`, or anything in `rsconnect/`.
- Rename `app.R` (ShinyApps.io deployment depends on this exact filename).
- Add `library()` calls inside any function in the future R package code.
- Introduce new R package dependencies without noting them — every new dependency
  is a CRAN check burden and a user install cost.
- Fabricate or assume citation details — flag any uncertain reference for manual
  verification instead.
- Run `shiny::runApp()` or any long-running process without warning.
- Overwrite `styler.css` without first showing the proposed diff.

**ALWAYS do these:**
- Use `::` notation when calling functions from non-base packages in utility functions
  (e.g., `onemap::read_mapmaker()`, not `read_mapmaker()`).
- Use `roxygen2`-style comments (`#'`) for all exported functions.
- Run `styler::style_file()` on any R file after editing.
- Use `here::here()` for file paths, never `setwd()`.
- After any significant UI change, note which CSS classes/IDs were modified.
- Wrap all `onemap` calls in `tryCatch()` — the package is verbose with warnings.

---

## 10. Session Management & /clear Guidance

See the separate **PROMPTS_PLAYBOOK.md** for full prompt texts.  
Use `/clear` between the following task boundaries to prevent context bleed:

| After completing... | Before starting... | /clear? |
|---|---|---|
| Code quality refactor | UI redesign | YES |
| UI redesign | New feature (QTL module) | YES |
| Any feature addition | Manuscript editing | YES |
| Manuscript editing | R package scaffolding | YES |
| One module's feature work | Another module's feature work | Optional |
| Reading/auditing code | Making changes to same code | NO |

---

## 11. Current Package Versions (as of dissertation, 2022)

Verify and update these when starting a new development session:

| Package | Version in dissertation | Notes |
|---|---|---|
| shiny | 1.7.1 | Check for breaking changes in 1.8+ |
| onemap | not specified | Likely 2.x; onemap3 may exist — verify |
| shinydashboard | not specified | May be superseded by bslib migration |
| shinydashboardPlus | 2.0.3 | Check compatibility with shinydashboard |
| shinyjs | 2.1.0 | Stable |
| ggplot2 | not specified | Stable |

---

*Last updated: Project initialisation. Update this file whenever the architecture,
dependencies, or publication targets change.*
