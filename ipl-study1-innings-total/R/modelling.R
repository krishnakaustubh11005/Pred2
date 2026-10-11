model_formula <- function(vars, target = "first_innings_total") reformulate(vars, response = target)
register_model <- function(name, fit, train, valid, prediction = NULL, type = "lm") {
  if (is.null(prediction)) prediction <- as.numeric(predict(fit, newdata = valid))
  met <- metrics(valid$first_innings_total, prediction)
  p <- if(is.null(fit)) 0 else length(coef(fit)) - 1
  adj <- if(type %in% c("lm","log")) summary(fit)$adj.r.squared else NA_real_
  log_run(name, if(is.null(fit)) name else paste(deparse(formula(fit)), collapse = " "), nrow(train), p,
    paste(range(train$season), collapse = "–"), paste(range(valid$season), collapse = "–"),
    met$rmse, met$mae, met$r2, adj, "Validation only; test untouched")
  append_csv(bind_cols(tibble(model = name, p, adj_r2 = adj), met), "validation_metrics")
  models[[name]] <<- list(fit = fit, type = type, validation_prediction = prediction)
}
choose_raw <- function(train, method) {
  full <- checked_lm(model_formula(feature_names()), train, paste(method, "candidate pool"))
  if (method == "Full") return(full)
  MASS::stepAIC(full, direction = "backward", k = if(method == "BIC") log(nrow(train)) else 2, trace = FALSE)
}
rolling_raw <- function(train) {
  years <- sort(unique(train$season)); years <- years[seq_along(years) > 5]
  bind_rows(lapply(years, function(year) {
    early <- train %>% filter(season < year); later <- train %>% filter(season == year)
    bind_rows(lapply(c("Full", "AIC", "BIC"), function(method) {
      fit <- choose_raw(early, method)
      bind_cols(tibble(method, season = year, N_train = nrow(early), N_assess = nrow(later)),
        metrics(later$first_innings_total, predict(fit, later)))
    }))
  }))
}
