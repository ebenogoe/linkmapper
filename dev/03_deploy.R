# Deploy the app to shinyapps.io (account: ebenogoe).
# Run from the package root after pushing to GitHub and installing from there with
#   remotes::install_github("ebenogoe/linkmapper")
# so the bundle records where linkmapper itself comes from.
options(repos = BiocManager::repositories())
rsconnect::deployApp(appDir = ".", appName = "linkmapper", appTitle = "Linkmapper",
                     account = "ebenogoe", server = "shinyapps.io", forceUpdate = TRUE)
