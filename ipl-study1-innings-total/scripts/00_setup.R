set.seed(42)
options(mc.cores = 1)
dirs <- c("R", "scripts", "data/raw", "data/interim", "data/processed", "data/reference",
          "results", "figures", "docs", "report", "presentation")
for (d in dirs) dir.create(d, recursive = TRUE, showWarnings = FALSE)
local_lib <- file.path(getwd(), ".runtime", "usr", "lib", "R", "site-library")
if (dir.exists(local_lib)) .libPaths(c(local_lib, .libPaths()))
required <- c("tidyverse", "here", "lubridate", "janitor", "glue", "ggrepel", "patchwork",
 "scales", "viridis", "psych", "GPArotation", "nFactors", "factoextra", "cluster", "car",
 "lmtest", "sandwich", "MASS", "broom", "olsrr", "corrplot", "knitr", "rmarkdown")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  dir.create(local_lib, recursive = TRUE, showWarnings = FALSE)
  .libPaths(c(local_lib, .libPaths()))
  install.packages(missing, lib = local_lib, repos = "https://cloud.r-project.org")
}
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Missing packages: ", paste(missing, collapse = ", "))
here::i_am("run_all.R")
pandoc <- here::here(".runtime", "usr", "bin")
if (file.exists(file.path(pandoc, "pandoc"))) Sys.setenv(RSTUDIO_PANDOC = pandoc)
native <- here::here(".runtime", "usr", "lib", "x86_64-linux-gnu")
if (dir.exists(native)) Sys.setenv(LD_LIBRARY_PATH = paste(native, Sys.getenv("LD_LIBRARY_PATH"), sep = ":"))
if (!rmarkdown::pandoc_available()) stop("Install Pandoc: sudo apt install pandoc; then rerun.")
smoke <- file.path(tempdir(),"ipl_setup.Rmd")
writeLines(c("---","title: Setup check","output: html_document","---","Rendering works."),smoke)
render_options <- if(dir.exists(here::here(".runtime","usr","share","pandoc","data")))
  list(pandoc_args=c("--data-dir",here::here(".runtime","usr","share","pandoc","data"))) else list()
rmarkdown::render(smoke,output_file="ipl_setup.html",output_dir=tempdir(),output_options=render_options,quiet=TRUE)
readr::write_csv(tibble::tibble(check=c("R dependencies","Pandoc HTML rendering"),pass=TRUE),here::here("results","setup_checks.csv"))
suppressPackageStartupMessages(library(tidyverse))
writeLines(capture.output(sessionInfo()), here::here("results", "session_info.txt"))
readr::write_csv(tibble(package = required,
 version = vapply(required, function(p) as.character(packageVersion(p)), character(1))),
 here::here("results", "package_versions.csv"))
cat("Setup checks passed.\n")
