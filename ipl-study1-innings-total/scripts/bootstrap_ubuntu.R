# Optional root-free bootstrap for Ubuntu with an existing system R.
# Ubuntu binaries match this machine's R better than current CRAN sources.
set.seed(42)
dir.create(".runtime/downloads", recursive = TRUE, showWarnings = FALSE)
pkgs <- c("tidyverse", "here", "ggrepel", "patchwork", "psych", "gparotation",
          "nfactors", "factoextra", "car", "lmtest", "sandwich", "corrplot", "rmarkdown")
requested <- c(paste0("r-cran-", pkgs), "pandoc")
sim <- system2("apt-get", c("-s", "--no-install-recommends", "install", requested), stdout = TRUE)
todo <- sub("^Inst ([^ ]+).*", "\\1", sim[grepl("^Inst ", sim)])
uris <- system2("apt-get", c("--print-uris", "download", todo), stdout = TRUE)
uris <- uris[grepl("^'", uris)]
jobs <- lapply(uris, function(x) strsplit(x, " ", fixed = TRUE)[[1]][1:2])
fetch <- function(j) {
  url <- sub("^'|'$", "", j[1]); url <- sub("'$", "", url)
  url <- sub("^http:", "https:", url)
  out <- file.path(".runtime/downloads", j[2])
  valid <- file.exists(out) && system2("dpkg-deb", c("--contents", shQuote(out)), stdout = FALSE, stderr = FALSE) == 0
  if (!valid) {
    status <- system2("curl", c("-fsSL", "--connect-timeout", "10", "--max-time", "90", "--retry", "3", shQuote(url), "-o", shQuote(out)))
    if (status != 0) stop("Download failed: ", url)
  }
  out
}
files <- parallel::mclapply(jobs, fetch, mc.cores = 8, mc.preschedule = FALSE)
stopifnot(!any(vapply(files, inherits, logical(1), "try-error")))
for (f in files) stopifnot(system2("dpkg-deb", c("-x", shQuote(f), ".runtime")) == 0)
# Debian web assets use absolute links: rewrite them into the local runtime.
all <- list.files(".runtime", recursive = TRUE, full.names = TRUE, all.files = TRUE)
for (f in all) {
  target <- Sys.readlink(f)
  if (!is.na(target) && startsWith(target, "/usr/")) {
    local_target <- file.path(getwd(), ".runtime", substring(target, 2))
    if (file.exists(local_target)) { unlink(f); file.symlink(local_target, f) }
  }
}
cat("Ubuntu runtime prepared. Start a new R session.\n")
source("scripts/repair_runtime.R")
