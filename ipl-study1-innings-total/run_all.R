#!/usr/bin/env Rscript
# Run from the project directory: Rscript run_all.R
set.seed(42)
if(Sys.getenv("IPL_CLEAN", "0") == "1") {
  # Only generated analysis directories are reset; source archives are retained.
  for(path in c("data/interim", "data/processed", "results", "figures")) unlink(path, recursive = TRUE)
}
source("scripts/00_setup.R")
for (name in c("ratio_log", "run_log", "figure_manifest", "validation_metrics", "pipeline_warnings"))
  unlink(here::here("results", paste0(name, ".csv")))
steps <- sort(list.files(here::here("scripts"), pattern = "^[0-9][0-9]_.*\\.R$", full.names = TRUE))
through <- as.integer(Sys.getenv("IPL_THROUGH", "10"))
steps <- steps[as.integer(substr(basename(steps), 1, 2)) <= through]
for (script in steps[!grepl("00_setup", steps)]) {
  message("Running ", basename(script))
  withCallingHandlers(source(script), warning = function(w) {
    readr::write_csv(tibble::tibble(script = basename(script), warning = conditionMessage(w)),
      here::here("results", "pipeline_warnings.csv"), append = file.exists(here::here("results", "pipeline_warnings.csv")))
  })
  if(basename(script) == "03_features.R") source(here::here("scripts","test_invariants.R"))
}
if(through >= 10) {
  source(here::here("R", "audit.R")); run_audits()
  writeLines(capture.output(sessionInfo()), here::here("results", "session_info.txt"))
}
