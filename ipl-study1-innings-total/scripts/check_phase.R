# Verify one phase in a fresh process using the saved, verified upstream data.
set.seed(42)
source("scripts/00_setup.R")
for(f in c("logging", "checks", "features", "plots", "diagnostics")) source(here::here("R",paste0(f,".R")))
phase <- as.integer(commandArgs(trailingOnly = TRUE)[1])
if(phase == 2) source(here::here("scripts","03_features.R"))
if(phase >= 3) {
  for(name in c("run_log", "validation_metrics", "figure_manifest", "pipeline_warnings")) unlink(here::here("results",paste0(name,".csv")))
  check_ratio(sum(readRDS(here::here("data","processed","features.rds"))$split == "train"), length(feature_names())+2, "candidate pool including proposed extensions")
  for(i in 4:(phase+1)) {
    script <- list.files(here::here("scripts"),pattern=sprintf("^%02d_",i),full.names=TRUE)
    message("Running ",basename(script))
    withCallingHandlers(source(script),warning=function(w) append_csv(tibble(script=basename(script),warning=conditionMessage(w)),"pipeline_warnings"))
  }
}
