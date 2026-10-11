set.seed(42)
archive <- here::here("data", "raw", "ipl_csv2.zip")
url <- "https://cricsheet.org/downloads/ipl_csv2.zip"
if (!file.exists(archive)) download.file(url, archive, mode = "wb", method = "libcurl")
files <- unzip(archive, list = TRUE)
if (!length(list.files(here::here("data", "raw"), pattern = "_info.csv$")))
  unzip(archive, exdir = here::here("data", "raw"))
json_archive <- here::here("data", "raw", "ipl_json.zip")
if (!file.exists(json_archive)) download.file("https://cricsheet.org/downloads/ipl_json.zip", json_archive, mode = "wb")
if (!dir.exists(here::here("data", "raw", "json"))) unzip(json_archive, exdir = here::here("data", "raw", "json"))
manifest <- tibble(source = c(url, "https://cricsheet.org/downloads/ipl_json.zip"),
 sha256 = vapply(c(archive,json_archive), function(path) strsplit(system2("sha256sum",shQuote(path),stdout=TRUE)," ")[[1]][1],character(1),USE.NAMES=FALSE),
 archive_files = c(nrow(files), nrow(unzip(json_archive,list=TRUE))))
lock <- here::here("data","reference","source_lock.csv")
if(file.exists(lock)) {
  previous <- readr::read_csv(lock,show_col_types=FALSE)
  if(!identical(previous$sha256,manifest$sha256)) stop("Source archives differ from the locked study snapshot. Restore the original archives; a deliberate data refresh requires a new documented study run.")
} else readr::write_csv(manifest,lock)
readr::write_csv(manifest, here::here("results", "source_manifest.csv"))
cat("Archive inspected and extracted.\n")
