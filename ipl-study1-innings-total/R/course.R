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
