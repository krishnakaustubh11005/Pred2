# Provenance for the methods, not a second modelling implementation.
course_alignment <- function() {
  source <- c("Intro to R/Introductory R and graphics (2).R",
    "Multiple Regression/Boston data analysis.txt", "Multiple Regression/Store24.R",
    "PCA/PCA class.R", "FA/FA.R", "Cluster Analysis/CA.R",
    "Cluster Analysis/cluster analysis.txt", "Cluster Analysis/Cluster Analysis Utilities example.R",
    "Outliers/outliers.R", "Cluster Analysis/Cluster Analysis.pdf",
    "Heteroscedasticity/Heteroskedasticity.R")
  data.frame(topic = c("Introduction to R", "Simple Regression", "Multiple Regression", "PCA",
    "Factor Analysis", "Cluster Analysis", "Cluster Analysis", "Cluster Analysis",
    "Outlier Detection", "Outlier Detection", "Heteroscedasticity"),
    method = c("Import, inspect, summaries, covariance and correlation",
      "lm, summary, confint, predict and residual diagnostics",
      "Multiple lm, backward step / stepAIC, squared terms and anova",
      "Parallel analysis, principal scores and prcomp comparison",
      "Principal-axis fa with no rotation and varimax",
      "Scale, Euclidean distance and average-linkage clustering",
      "Complete linkage, k-means, elbow and silhouette",
      "Single linkage, cutree, centres and membership tables",
      "Studentized residuals, leverage, Cook, DFFITS and DFBETAS",
      "Mahalanobis distance with covariance adjustment",
      "Goldfeld–Quandt, log response and group-variance WLS"),
    source = paste0("../Predictive Modelling/", source), stringsAsFactors = FALSE)
}
record_course_sources <- function() {
  alignment <- course_alignment()
  stopifnot(all(file.exists(here::here(alignment$source))))
  save_csv(alignment, "course_alignment")
  root <- here::here("..", "Predictive Modelling")
  paths <- sort(list.files(root, recursive = TRUE, full.names = TRUE))
  save_csv(data.frame(source = paste0("../Predictive Modelling/", substring(paths, nchar(root) + 2)),
    md5 = unname(tools::md5sum(paths))), "course_source_manifest")
  decision("D-018", 3, "The student supplied course files and approved strict alignment.",
    "Rewrite the entire data pipeline; rewrite statistical analysis while retaining verified preparation.",
    "Refactor analysis into sequential classroom-style R, use only sourced analytical concepts, and retain basic chronological evaluation and software checks. Supersedes conflicting requirements in Agents.md and D-002, D-009 through D-014, and D-016.",
    "The student chose analysis-only refactoring and retained the chronological split and basic metrics.",
    "The earlier implementation already assessed the test season. The revised test comparison is not newly untouched evidence. Course example typos and interactive commands are corrected rather than copied.")
}

# Inspect executed calls rather than matching words inside comments or examples.
course_scope_audit <- function() {
  paths <- c(here::here("R", "modelling.R"), here::here("R", "diagnostics.R"),
    list.files(here::here("scripts"), pattern = "^0[4-9]_.*\\.R$", full.names = TRUE))
  calls <- character()
  walk <- function(x) {
    if (is.call(x)) {
      head <- x[[1]]
      if (is.symbol(head)) calls <<- c(calls, as.character(head))
      if (is.call(head) && as.character(head[[1]]) %in% c("::", ":::"))
        calls <<- c(calls, as.character(head[[3]]))
    }
    if (is.call(x) || is.expression(x) || is.pairlist(x)) {
      parts <- as.list(x)
      for (i in seq_along(parts)) {
        if (identical(parts[[i]], quote(expr=))) next
        walk(parts[[i]])
      }
    }
  }
  for (path in paths) walk(parse(path))
  excluded <- c("vif", "bptest", "vcovHC", "clusGap", "rlm", "rolling_raw", "choose_raw", "replicate", "sample")
  scope <- data.frame(check = paste("excluded analytical call absent:", excluded), pass = !excluded %in% calls)
  alignment <- read.csv(here::here("results", "course_alignment.csv"))
  manifest <- read.csv(here::here("results", "course_source_manifest.csv"))
  scope <- rbind(scope, data.frame(check = c("course reference files exist", "course source hashes match",
    "principal-axis varimax settings", "unrotated principal component settings", "all eight topics mapped"),
    pass = c(all(file.exists(here::here(alignment$source))),
      identical(unname(tools::md5sum(here::here(manifest$source))), manifest$md5),
      all(vapply(dimension_fits, function(f) f$fa$fm == "pa" && f$fa$rotation == "varimax", logical(1))),
      all(vapply(dimension_fits, function(f) is.null(f$pca$rot.mat), logical(1))),
      length(unique(alignment$topic)) == 8)))
  save_csv(scope, "course_scope_audit")
  scope
}
