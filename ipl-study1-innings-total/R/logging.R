save_csv <- function(x, name) readr::write_csv(x, here::here("results", paste0(name, ".csv")))
append_csv <- function(x, name) {
  path <- here::here("results", paste0(name, ".csv"))
  readr::write_csv(x, path, append = file.exists(path))
}
log_run <- function(model, formula, N, p, train_range, test_range, rmse = NA_real_,
                    mae = NA_real_, r2 = NA_real_, adj_r2 = NA_real_, notes = "") {
  append_csv(tibble(model, formula, N, p, train_range, test_range, rmse, mae, r2, adj_r2, notes), "run_log")
}
decision <- function(id, phase, context, options, choice, rationale, risks) {
  path <- here::here("DECISIONS.md")
  if (any(grepl(paste0("^## ", id, "$"), readLines(path, warn = FALSE)))) return(invisible(NULL))
  cat(glue::glue("\n\n## {id}\nDate: {Sys.Date()}  \nPhase: {phase}  \nContext: {context}  \nOptions considered: {options}  \nDecision: {choice}  \nRationale: {rationale}  \nConsequences or risks: {risks}  \nStatus: active\n"),
      "\n", file = path, append = TRUE, sep = "")
}
phase_result <- function(phase, title, tables, reading, learned, questions) {
  path <- here::here("RESULTS.md")
  marker <- paste0("## Phase ", phase, ": ")
  content <- c(paste0(marker,title),"")
  for (name in tables) {
    x <- readr::read_csv(here::here("results", paste0(name, ".csv")), show_col_types = FALSE)
    content <- c(content,paste0(name,":"),"",capture.output(knitr::kable(head(x,12),digits=3)),"")
  }
  content <- c(content,reading,"",paste0("What I learned: ",learned),"",paste0("Open questions: ",questions),"")
  existing <- readLines(path,warn=FALSE); start <- which(startsWith(existing,marker))
  if(length(start)) {
    later <- which(str_detect(existing,"^## Phase ") & seq_along(existing)>start[1])
    end <- if(length(later)) later[1]-1 else length(existing)
    before <- if(start[1]>1) existing[seq_len(start[1]-1)] else character()
    after <- if(end<length(existing)) existing[(end+1):length(existing)] else character()
    writeLines(c(before,content,after),path)
  } else cat("\n",paste(content,collapse="\n"),"\n",file=path,append=TRUE,sep="")
}
