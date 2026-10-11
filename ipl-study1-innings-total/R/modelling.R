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
# Applying saved training weights is bookkeeping; fits are explicit in scripts.
transform_strength <- function(data, fit, kind) {
  z <- scale(as.matrix(data[, fit$vars]), center = fit$center, scale = fit$spread)
  weights <- if (kind == "PCA") fit$pca$weights else fit$fa$weights
  scores <- as.data.frame(z %*% weights)
  names(scores) <- paste0(kind, seq_len(ncol(scores)))
  bind_cols(data, scores)
}
predict_candidate <- function(name, data) {
  entry <- models[[name]]
  if (name == "B0 training mean") return(rep(mean(tr$first_innings_total), nrow(data)))
  if (name == "B1 venue history") return(data$venue_avg_first_inn)
  if (!is.null(entry$transform)) data <- transform_strength(data, combined, entry$transform)
  if (isTRUE(entry$cluster)) data <- assign_cluster(data, cluster_fit)
  prediction <- as.numeric(predict(entry$fit, newdata = data))
  if (entry$type == "log") prediction <- exp(prediction)
  prediction
}
group_variance <- function(data, fit) {
  group <- assign_cluster(data, cluster_fit)$venue_cluster
  value <- unname(fit$variances[as.character(group)])
  value[!is.finite(value) | value <= 0] <- fit$pooled_variance
  value
}
