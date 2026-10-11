# Resolve dependencies relative to the project, including on older Ubuntu R.
local({
  lib <- file.path(getwd(), ".runtime", "usr", "lib", "R", "site-library")
  if (dir.exists(lib)) .libPaths(c(lib, .libPaths()))
  pandoc <- file.path(getwd(), ".runtime", "usr", "bin")
  if (file.exists(file.path(pandoc, "pandoc"))) Sys.setenv(RSTUDIO_PANDOC = pandoc)
  native <- file.path(getwd(), ".runtime", "usr", "lib", "x86_64-linux-gnu")
  Sys.setenv(TZ = "Asia/Kolkata")
  if (dir.exists(native)) Sys.setenv(LD_LIBRARY_PATH = paste(native, Sys.getenv("LD_LIBRARY_PATH"), sep = ":"))
})
