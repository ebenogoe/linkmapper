mod_about_ui <- function(id) {
  shiny::div(
    class = "lm-page",
    shiny::p(class = "lm-kicker", "About"),
    shiny::h1("About Linkmapper"),
    shiny::p(class = "lm-lede", "A point-and-click interface for genetic linkage mapping and QTL analysis in biparental populations."),
    shiny::h2("History"),
    shiny::p("Linkmapper was created in 2022 as a final-year project at the Kwame Nkrumah University of Science and Technology (KNUST), Kumasi, to make linkage mapping with onemap accessible without scripting."),
    shiny::p("In 2026 it was rewritten as an R package. The new version adds backcross and RIL populations, segregation tests with Bonferroni correction, recombination-fraction heatmaps, an interactive map, QTL mapping with R/qtl, and report, script and session exports. It also fixes problems in the original, including shared state between sessions and a QTL step that did not detect QTL."),
    shiny::h2("Authors"),
    shiny::p(
      "Linkmapper was created by Ebenezer Ogoe, Michael Obeng and Stephen Amoako. The 2026 package was written and is maintained by ",
      shiny::tags$a(href = "https://ebenezerogoe.com", target = "_blank", rel = "noopener", "Ebenezer Ogoe", .noWS = "after"), "."
    ),
    shiny::h2("Run it locally"),
    shiny::tags$pre(class = "lm-code", 'install.packages("linkmapper", repos = c("https://ebenogoe.r-universe.dev", "https://cloud.r-project.org"))\nlinkmapper::run_app()'),
    shiny::h2("Citation"),
    shiny::p("Cite the package together with onemap and R/qtl. Run ", shiny::tags$code('citation("linkmapper")'), " in R for the current citation."),
    shiny::h2("Built with"),
    shiny::p("R and Shiny, with onemap, qtl, bslib, ggplot2, ggiraph, reactable and cicerone. Text is set in Manrope, served by Google Fonts under the SIL Open Font License."),
    shiny::p(
      class = "lm-muted", sprintf("Version %s. MIT licence. ", utils::packageVersion("linkmapper")),
      shiny::tags$a(href = "https://github.com/ebenogoe/linkmapper", target = "_blank", rel = "noopener", "Source code and issues"), "."
    )
  )
}
