# Check reported numeric tokens against saved output values and their display
# rounding. IDs, dates and code are structural metadata rather than findings.
audit_reported_numbers <- function() {
  pattern <- "(?<![[:alnum:]_])[-+]?[0-9]+(?:\\.[0-9]+)?(?:[eE][-+]?[0-9]+)?(?![[:alnum:]_])"
  tokens <- function(x) {
    x <- str_replace_all(x,"D-[0-9]+|[0-9]{4}-[0-9]{2}-[0-9]{2}"," ")
    unlist(str_extract_all(x,pattern))
  }
  files <- list.files(here::here("results"),pattern="\\.csv$",full.names=TRUE)
  files <- files[!str_detect(basename(files),"reported_numbers")]
  pool <- bind_rows(lapply(files,function(file) {
    x <- readr::read_csv(file,col_types=cols(.default=col_character()),show_col_types=FALSE)
    values <- unique(tokens(unlist(x,use.names=FALSE)))
    tibble(value=suppressWarnings(as.numeric(values)),source=basename(file))
  })) %>% filter(is.finite(value)) %>% distinct(value,.keep_all=TRUE)
  display <- bind_rows(lapply(0:6,function(digit) pool %>% mutate(value=round(value,digit)))) %>% distinct(value,.keep_all=TRUE)
  docs <- c(here::here("README.md"),here::here("DECISIONS.md"),here::here("RESULTS.md"),
    list.files(here::here("docs"),pattern="\\.md$",full.names=TRUE),here::here("figures","INDEX.md"),here::here("presentation","talk_track.md"))
  claims <- bind_rows(lapply(docs,function(file) tibble(document=basename(file),token=unique(tokens(readLines(file,warn=FALSE))))))
  for(file in c(here::here("report","final_report.html"),here::here("presentation","slides.html"))) {
    html <- xml2::read_html(file)
    xml2::xml_remove(xml2::xml_find_all(html,"//script|//style|//pre|//code"))
    claims <- bind_rows(claims,tibble(document=basename(file),token=unique(tokens(xml2::xml_text(xml2::xml_find_first(html,"//body"))))))
  }
  claims <- claims %>% mutate(value=as.numeric(token),source=display$source[match(value,display$value)],pass=!is.na(source))
  save_csv(claims,"reported_numbers_audit")
  if(any(!claims$pass)) {
    print(claims %>% filter(!pass))
    stop("A reported numeric value has no saved-results provenance.")
  }
  invisible(claims)
}
