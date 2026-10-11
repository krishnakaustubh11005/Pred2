run_audits <- function() {
  rr <- function(name) readr::read_csv(here::here("results", paste0(name, ".csv")), show_col_types = FALSE)
  ratio <- rr("ratio_log"); leakage <- rr("leakage_audit"); fm <- rr("figure_manifest")
  report <- readLines(here::here("report", "final_report.Rmd"))
  slides <- readLines(here::here("presentation", "slides.Rmd"))
  headings <- report[str_detect(report, "^# ")]
  expected <- paste0("# ", c("Objective (Problem)", "Data description (overview)", "Methods used", "Results", "Conclusion"))
  slide_count <- sum(str_detect(slides, "^## "))
  slides_html <- xml2::read_html(here::here("presentation","slides.html"))
  rendered_slide_count <- length(xml2::xml_find_all(slides_html,"//slide[not(contains(@class,'backdrop'))]"))
  references <- str_match_all(paste(report,collapse="\n"), "show_figures\\(([0-9:]+)\\)")[[1]][,2]
  figure_ids <- unique(unlist(lapply(references,function(x) eval(parse(text=x)))))
  html <- paste(readLines(here::here("report", "final_report.html")), collapse = "\n")
  checks <- tibble(check = c("all predictor ratios pass", "strict-date leakage reconstruction passes",
    "exact report sections and order", "required slide count", "all prescribed figures present",
    "all figures have messages, captions and sections", "all figures referenced in report", "all course topics covered",
    "report embeds images", "code folding available", "all split features finite", "test selection matches validation rule",
    "all final prediction rows finite", "interval bounds ordered"),
    pass = c(all(ratio$pass), all(leakage$pass) && leakage$rows == 20, identical(headings, expected),
      slide_count == 13 && rendered_slide_count == 13, nrow(fm)==28 && identical(as.integer(sort(fm$id)), 1:28) && all(file.exists(here::here("figures", fm$filename))),
      all(nzchar(fm$title) & nzchar(fm$subtitle) & nzchar(fm$how) & nzchar(fm$meaning) & nzchar(fm$section) & fm$labelled_axes),
      all(fm$id %in% figure_ids),
      nrow(rr("course_coverage")) == 8, str_detect(html, "data:image/png;base64"), str_detect(html, "code-folding"),
      all(is.finite(as.matrix(d[, feature_names()]))),
      identical(rr("final_selection")$model, rr("validation_metrics") %>%
        filter(!model %in% c("B0 training mean", "B1 venue history")) %>% arrange(rmse, p) %>% slice(1) %>% pull(model)),
      all(is.finite(rr("test_predictions")$predicted)),
      all(rr("prediction_intervals")$lower <= rr("prediction_intervals")$upper)))
  save_csv(checks, "verification")
  source(here::here("scripts", "test_course_analysis.R"))
  scope <- rr("course_scope_audit")
  analysis_tests <- rr("course_analysis_tests")
  checks <- bind_rows(checks, tibble(check = c("course scope and provenance pass", "course analysis invariants pass"),
    pass = c(all(scope$pass), all(analysis_tests$pass))))
  source(here::here("R","numerical_audit.R")); numerical <- audit_reported_numbers()
  checks <- bind_rows(checks,tibble(check="reported numeric values have saved-results provenance",pass=all(numerical$pass)))
  save_csv(checks,"verification")
  print(rr("course_coverage")); print(checks)
  if(!all(checks$pass)) stop("Final audit failed: ", paste(checks$check[!checks$pass], collapse = "; "))
  invisible(checks)
}
