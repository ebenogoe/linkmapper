# Takes the README and website screenshots by driving the installed app.
# Run from the package root after devtools::install(): NOT_CRAN=true Rscript dev/screenshots.R
library(shinytest2)
out <- "man/figures"
dir.create(out, showWarnings = FALSE, recursive = TRUE)
app <- AppDriver$new(linkmapper::run_app(), width = 1440, height = 1000, load_timeout = 60000, timeout = 120000, seed = 1)
on.exit(app$stop())
go <- function(step) {
  app$run_js(sprintf("Shiny.setInputValue('goto_step', '%s', {priority: 'event'})", step))
  app$wait_for_idle(duration = 800)
}
shot <- function(name) {
  app$run_js("window.scrollTo(0, 0)")
  Sys.sleep(1)
  f <- file.path(out, paste0(name, ".png"))
  unlink(f)
  app$get_screenshot(f, selector = "html")
}
app$wait_for_idle(duration = 1500)
shot("01-home")
go("data"); app$click("data-load_demo"); app$wait_for_idle(duration = 1000); shot("02-data")
go("qc"); app$click("qc-apply"); app$wait_for_idle(duration = 1000); shot("03-quality")
go("groups"); app$click("groups-go"); app$wait_for_idle(duration = 1000); shot("04-groups")
go("order"); app$click("order-go"); app$wait_for_idle(duration = 2000, timeout = 120000); shot("05-order")
go("qtl"); app$set_inputs(`qtl-n_perm` = 300); app$click("qtl-go"); app$wait_for_idle(duration = 2000, timeout = 120000); shot("07-qtl")
go("map"); app$wait_for_idle(duration = 1500); shot("06-map")
go("export"); shot("08-export")
