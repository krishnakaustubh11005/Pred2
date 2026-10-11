check_ratio <- function(N, p, label) {
  pass <- is.finite(N) && is.finite(p) && N > 0 && p <= N / 10
  append_csv(tibble(label, N, p, limit = N / 10, pass), "ratio_log")
  if (!pass) stop(glue::glue("Predictor ratio violated for {label}: p={p}, N={N}, limit={N/10}."))
  invisible(TRUE)
}
checked_lm <- function(formula, data, label, weights = NULL) {
  mf <- model.frame(formula, data = data, na.action = na.fail)
  p <- ncol(model.matrix(formula, data)) - 1L
  check_ratio(nrow(mf), p, label)
  if(is.null(weights)) fit <- lm(formula, data = data)
  else {
    # model.frame resolves weights in the data/formula environment, so put the
    # numeric weights in the data instead of exposing the weights() function.
    data$.study_weights <- weights
    fit <- lm(formula, data = data, weights = .study_weights)
  }
  fit$call$formula <- formula
  fit$call$data <- substitute(data)
  fit
}
enable_lm_audit <- function() {
  # Includes lm() calls inside stepAIC and statistical libraries.
  tracer <- quote({
    .audit_data <- if (missing(data)) environment(formula) else data
    .audit_frame <- model.frame(formula, data = .audit_data, na.action = na.omit)
    get("check_ratio", envir = .GlobalEnv)(nrow(.audit_frame), ncol(model.matrix(attr(.audit_frame, "terms"), .audit_frame)) - 1L,
                paste0("lm internal: ", paste(deparse(formula), collapse = " ")))
  })
  exit_log <- quote({
    .audit_fit <- returnValue()
    if(inherits(.audit_fit,"lm")) {
    .audit_range <- if(is.data.frame(.audit_data) && "season" %in% names(.audit_data))
      paste(range(.audit_data$season),collapse="–") else "auxiliary or transformed data"
    get("log_run",envir=.GlobalEnv)("Audited lm fit", paste(deparse(formula),collapse=" "),
      nobs(.audit_fit), ncol(model.matrix(.audit_fit))-1L, .audit_range, "not assessed at fit time",
      adj_r2=summary(.audit_fit)$adj.r.squared, notes="Automatic fit log; selection and diagnostic fits included")
    }
  })
  trace("lm", where = asNamespace("stats"), print = FALSE, tracer = tracer, exit = exit_log)
  trace("lm", where = as.environment("package:stats"), print = FALSE, tracer = tracer, exit = exit_log)
}
leakage_test <- function(matches, batting, bowling, lineups, features) {
  set.seed(42)
  rows <- sample(seq_len(nrow(features)), min(20, nrow(features)))
  cols <- feature_names()
  for (i in rows) {
    m <- matches[match(features$match_id[i], matches$match_id), ]
    # Independent history extraction, rather than reading the cached feature row.
    rebuilt <- feature_row(m, matches %>% filter(date < m$date),
      batting %>% filter(date < m$date), bowling %>% filter(date < m$date),
      lineups %>% filter(match_id == m$match_id))
    stopifnot(isTRUE(all.equal(as.numeric(features[i, cols]), as.numeric(rebuilt[cols]), tolerance = 1e-9)))
  }
  save_csv(tibble(check = "strict earlier-date brute-force reconstruction", rows = length(rows), pass = TRUE), "leakage_audit")
}
metrics <- function(y, pred) tibble(rmse = sqrt(mean((y - pred)^2)),
 mae = mean(abs(y - pred)), r2 = 1 - sum((y - pred)^2) / sum((y - mean(y))^2))
