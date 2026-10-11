# Invariants for changed statistics; run after document generation.
local({
  checks <- list()
  add <- function(label, pass) {
    checks[[length(checks) + 1]] <<- data.frame(check = label, pass = isTRUE(pass))
  }
  dimensions <- read.csv(here::here("results", "dimension_checks.csv"))
  add("training scores reconstruct from saved weights", all(dimensions$pca_score_error < 1e-7 & dimensions$fa_score_error < 1e-7))
  add("unrotated component scores are orthogonal", all(dimensions$pca_off_diagonal < 1e-7))
  add("class principal scores agree with scaled prcomp", all(dimensions$prcomp_score_error < 1e-7))
  add("improper separate factor solutions are flagged", all(dimensions$boundary_warning[dimensions$min_uniqueness < 0]))
  add("prediction factor solution has nonnegative uniqueness", all(combined$fa$uniquenesses >= 0))
  original <- transform_strength(va[1:2, ], combined, "PCA")
  changed <- va[1:2, ]
  changed[2, combined$vars] <- as.list(as.numeric(changed[2, combined$vars]) * 100)
  perturbed <- transform_strength(changed, combined, "PCA")
  add("later-row changes cannot alter another row's scaling", identical(original[1,paste0("PCA",seq_len(combined$npc))],perturbed[1,paste0("PCA",seq_len(combined$npc))]))
  add("test factor scores remain finite", all(is.finite(as.matrix(transform_strength(te,combined,"FA")[,paste0("FA",seq_len(ncol(combined$fa$weights)))]))))
  add("group-variance weights remain positive", all(is.finite(group_variance(te,variance_fit)) & group_variance(te,variance_fit)>0))
  invalid <- variance_fit
  invalid$variances[] <- NA_real_
  add("invalid group variance uses pooled fallback", all(group_variance(te,invalid)==invalid$pooled_variance))
  unseen <- te[1, ]
  unseen$venue <- "Never observed course-test ground"
  unseen$venue_prior_matches <- 0
  add("unseen venue gets a valid frozen cluster", !is.na(assign_cluster(unseen,cluster_fit)$venue_cluster))

  # Independently replay persisted fits and score weights.
  bundle <- readRDS(here::here("results","frozen_models.rds"))
  saved <- read.csv(here::here("results","test_predictions.csv"))
  replay_ok <- vapply(names(bundle$models), function(name) {
    entry <- bundle$models[[name]]
    input <- te
    if(!is.null(entry$transform)) {
      fit <- bundle$dimension_fits$Combined
      z <- scale(as.matrix(input[,fit$vars]),center=fit$center,scale=fit$spread)
      weights <- if(entry$transform=="PCA") fit$pca$weights else fit$fa$weights
      scores <- as.data.frame(z %*% weights)
      names(scores) <- paste0(entry$transform,seq_len(ncol(scores)))
      input <- cbind(input,scores)
    }
    if(isTRUE(entry$cluster)) input <- assign_cluster(input,bundle$cluster_fit)
    actual <- if(name=="B0 training mean") rep(bundle$training_mean,nrow(te)) else
      if(name=="B1 venue history") input$venue_avg_first_inn else as.numeric(predict(entry$fit,newdata=input))
    if(entry$type=="log") actual <- exp(actual)
    isTRUE(all.equal(actual,saved$predicted[saved$model==name],tolerance=1e-10))
  },logical(1))
  add("persisted bundle reproduces every test prediction",all(replay_ok))
  add("all candidates assess the same test innings",all(table(saved$model)==nrow(te)))
  intervals <- read.csv(here::here("results","prediction_intervals.csv"))
  add("intervals are finite and contain point forecasts",all(is.finite(as.matrix(intervals[,c("predicted","lower","upper")])) & intervals$lower<=intervals$predicted & intervals$predicted<=intervals$upper))
  interval_summary <- read.csv(here::here("results","interval_summary.csv"))
  add("coverage matches observed inclusions",isTRUE(all.equal(interval_summary$empirical_coverage,mean(intervals$actual>=intervals$lower & intervals$actual<=intervals$upper))))
  example <- read.csv(here::here("results","score_example_prediction_terms.csv"))
  forecast <- read.csv(here::here("results","score_example_summary.csv"))
  sums <- tapply(example$contribution_runs,example$method,sum)
  add("teaching arithmetic equals saved forecasts",all(abs(sums-forecast$predicted[match(names(sums),forecast$method)])<1e-7))
  reference_features <- Sys.getenv("IPL_REFERENCE_FEATURES")
  reference_split <- Sys.getenv("IPL_REFERENCE_SPLIT")
  if(nzchar(reference_features) && !file.exists(reference_features)) stop("Requested original-feature reference is missing")
  if(nzchar(reference_split) && !file.exists(reference_split)) stop("Requested original-split reference is missing")
  if(nzchar(reference_features) && file.exists(reference_features))
    add("modelling data unchanged from before refactor",identical(d,readRDS(reference_features)))
  if(nzchar(reference_split) && file.exists(reference_split))
    add("season split unchanged from before refactor",identical(read.csv(here::here("results","split_summary.csv")),readRDS(reference_split)))
  result <- do.call(rbind,checks)
  save_csv(result,"course_analysis_tests")
  scope <- course_scope_audit()
  print(result)
  if(!all(result$pass) || !all(scope$pass)) stop("Course analysis invariant or scope audit failed")
})
