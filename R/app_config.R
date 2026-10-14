app_sys <- function(...) system.file(..., package = "linkmapper")

# shinyapps.io sets R_CONFIG_ACTIVE to "shinyapps", which switches on the hosted limits
get_golem_config <- function(value,
                             config = Sys.getenv("GOLEM_CONFIG_ACTIVE", Sys.getenv("R_CONFIG_ACTIVE", "default")),
                             use_parent = TRUE, file = app_sys("golem-config.yml")) {
  config::get(value = value, config = config, file = file, use_parent = use_parent)
}

app_limits <- function() {
  list(
    hosted = isTRUE(get_golem_config("hosted")),
    max_upload_mb = get_golem_config("max_upload_mb"),
    max_markers = get_golem_config("max_markers"),
    max_perm = get_golem_config("max_perm")
  )
}
