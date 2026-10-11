# Debian dependencies already installed system-wide were not re-downloaded.
# Reconnect their relative asset links to the existing read-only system files.
links <- system2("find", c(".runtime", "-type", "l"), stdout = TRUE)
normalise_parts <- function(path) {
  parts <- strsplit(path, "/", fixed = TRUE)[[1]]; stack <- character()
  for(p in parts) { if(p == "..") stack <- head(stack, -1) else if(p != "." && nzchar(p)) stack <- c(stack, p) }
  paste0("/", paste(stack, collapse = "/"))
}
runtime <- file.path(getwd(), ".runtime")
for(f in links) if(!file.exists(f)) {
  s <- Sys.readlink(f)
  full <- if(startsWith(s, "/")) s else normalise_parts(file.path(getwd(), dirname(f), s))
  host <- if(startsWith(full, runtime)) substring(full, nchar(runtime)+1) else full
  if(file.exists(host)) { unlink(f); file.symlink(host, f) }
}
