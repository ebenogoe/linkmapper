# CLAUDE.md — Linkmapper Project

> This file is read by Claude Code at the start of every session.
> It contains everything Claude needs to understand the project, make good decisions,
> and avoid breaking things. Keep it updated as the project evolves.

---

## 1. Project Identity

**Tool name:** Linkmapper  
**What it does:** A GUI-based Shiny web application that wraps the `onemap` R package
to let users perform linkage mapping and QTL visualisation on biparental mapping
populations (F2 intercross, backcross and RIL) without writing any code.  
**Primary users:** Students and instructors in molecular genetics / agricultural
biotechnology; researchers who want a GUI alternative to scripting onemap directly.  
**Original context:** Final-year undergraduate dissertation, KNUST (Kwame Nkrumah
University of Science and Technology), Ghana, 2022. Supervisor: Dr. Alexander W. Kena.  
**Authors:** Ogoe Ebenezer, Obeng Michael, Amoako Stephen.

**Publication goal:** Adapt and publish as a peer-reviewed software paper. Primary target
journal: *The Plant Genome* (Wiley). Stretch target: *Bioinformatics* (OUP).  
**Package goal:** Wrap the Shiny app as an installable R package on R-universe first,
then CRAN. The package will let users run the app locally via a single `run_linkmapper()`
call, supported by exported utility functions.

---

## 2. Repository Layout (version 0.2, golem package)

```
linkmapper/
├── DESCRIPTION, NAMESPACE, LICENSE, NEWS.md, README.md
├── app.R                 # shinyapps.io entry point (pkgload::load_all + run_app). Do not rename.
├── R/
│   ├── fct_read.R        # read_cross(), add_traits(), write_mapmaker(), demos, validate_lm_file()
│   ├── fct_qc.R          # qc_summary(), filter_markers()
│   ├── fct_link.R        # suggest_lod(), linkage_groups(), group_markers(), order_groups(), map_positions()
│   ├── fct_qtl.R         # build_cross(), scan_qtl(), genotype_effect()
│   ├── fct_plot.R        # plot_linkage_map(), plot_lod(), plot_rf_heatmap(), plot_segregation(), ...
│   ├── fct_pipeline.R    # default_settings(), run_analysis(), build_script(), save/load_session()
│   ├── fct_report.R      # build_report() (self-contained HTML, no pandoc)
│   ├── mod_*.R           # one Shiny module per step plus home, guide, about
│   ├── utils_ui.R        # theme, shared UI helpers; utils_state.R: per-session state and step bar
│   └── app_ui.R, app_server.R, app_config.R, run_app.R
├── inst/app/www/         # custom.css, custom.js, logo.svg, favicon.svg
├── inst/extdata/         # f2_small.txt (2022 demo), precomputed home-page map
├── inst/golem-config.yml # hosted limits switch on when R_CONFIG_ACTIVE = "shinyapps"
├── tests/testthat/       # engine tests + shinytest2 smoke test
├── data-raw/             # make_home_map.R
├── dev/                  # screenshots.R, 03_deploy.R
└── vignettes/articles/   # pkgdown-only articles (built on CI, where pandoc exists)
```

Deployed to https://ebenogoe.shinyapps.io/linkmapper/ (account `ebenogoe`). The 2022 app
remains at project-genaxy.shinyapps.io/Linkmapper; its rsconnect record is untouched.

---

## 3. Architecture

- Engine functions (`fct_*`) are plain, exported, tested R. The app calls them; the
  "R script" export calls the same functions through `run_analysis()`.
- All state is per session (`new_state()` reactiveValues). Changing a step clears the
  results after it (`reset_after()`).
- Workflow: read_cross -> qc_summary/filter_markers -> linkage_groups (onemap rf_2pts +
  group) -> order_groups (record/rcd/ug/seriation, seeded) -> build_cross (write MAPMAKER +
  onemap::write_map -> qtl::read.cross("mm")) -> scan_qtl (scanone/cim + permutations).
- onemap's map function is a global option: `order_groups()` and `build_cross()` set it
  right before use.

---

## 4. Design

Own identity, distinct from Clusnalyst (its sibling app): teal #0d9488 / dark teal
#0f766e for actions, amber #f59e0b accents, ink #0f2a2a navbar, Manrope from Google Fonts,
8 to 10 px radii, teal-topped cards, horizontal step bar, ladder motif on the home page.
Copy is concise and professional. Do not reuse ebenezerogoe.com's design tokens.

---

## 5. Possible next features

- Outcross (full-sib) populations via onemap's outcross pathway.
- Multiple-QTL models (stepwiseqtl) and two-dimensional scans.
- VCF input with parent genotypes.
- Comparison of orders across algorithms within the app.

---

## 6. (removed: superseded by section 4)

## 7. (removed: the package structure is in place; see section 2)

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
- Modify or delete anything in `rsconnect/` other than records written by a deploy the user asked for.
- Rename `app.R` (shinyapps.io deployment depends on it).
- Add `library()` calls inside package functions.
- Introduce new R package dependencies without noting them.
- Fabricate or assume citation details; flag uncertain references for manual verification.
- Deploy or push without the user's go-ahead.

**ALWAYS do these:**
- Use `::` notation for non-base packages.
- Use roxygen2 comments for exported functions.
- Wrap onemap calls with `quiet()` and surface errors through `safely()` in the app.
- Keep `devtools::check()` at 0 errors, 0 warnings, 0 notes and the tests green.

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
