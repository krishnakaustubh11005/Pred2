set.seed(42)
vm <- readr::read_csv(here::here("results", "validation_metrics.csv"), show_col_types = FALSE)
winner <- vm %>% arrange(rmse, p) %>% slice(1) %>% pull(model)
predict_candidate <- function(name, data) {
  entry <- models[[name]]
  if(name == "B0 training mean") return(rep(mean(tr$first_innings_total), nrow(data)))
  if(name == "B1 venue history") return(data$venue_avg_first_inn)
  if(!is.null(entry$transform)) data <- transform_strength(data, combined, entry$transform)
  if(isTRUE(entry$cluster)) data <- assign_cluster(data, cluster_fit)
  pred <- as.numeric(predict(entry$fit, data))
  if(entry$type == "log") pred <- exp(pred)*entry$smear
  pred
}
# Freeze the model choice before accessing test targets or deriving test metrics.
save_csv(tibble(model = winner, validation_rmse = vm$rmse[match(winner, vm$model)], refit_policy = "training fit retained; validation calibrates intervals"), "final_selection")
saveRDS(list(winner = winner, models = models, dimension_fits = dimension_fits, cluster_fit = cluster_fit,
             training_mean = mean(tr$first_innings_total), feature_names = feature_names()), here::here("results", "frozen_models.rds"))
te <- d %>% filter(split == "test")
predictions <- bind_rows(lapply(names(models), function(name) tibble(model = name, match_id = te$match_id,
 date = te$date, season = te$season, actual = te$first_innings_total, predicted = predict_candidate(name, te))))
test_metrics <- predictions %>% group_by(model) %>% group_modify(~metrics(.x$actual, .x$predicted)) %>% ungroup()
# Resample entire match dates, preserving within-day dependence.
uncertainty <- predictions %>% group_by(model) %>% group_modify(~{
  set.seed(42) # Shared resamples give identical predictions identical intervals.
  dates <- unique(.x$date)
  boot <- replicate(500, {
    picked <- sample(dates, length(dates), replace = TRUE)
    idx <- unlist(lapply(picked, function(date) which(.x$date == date)))
    sqrt(mean((.x$actual[idx] - .x$predicted[idx])^2))
  })
  tibble(low = quantile(boot, .025), high = quantile(boot, .975))
}) %>% ungroup()
test_metrics <- test_metrics %>% left_join(uncertainty, by = "model") %>% left_join(vm %>% select(model, p, adj_r2, validation_rmse = rmse), by = "model")
test_metrics <- test_metrics %>% mutate(test_rank=rank(rmse,ties.method="min"))
save_csv(test_metrics, "test_metrics"); save_csv(predictions, "test_predictions")
entry <- models[[winner]]
validation_pred <- predict_candidate(winner, va); test_pred <- predict_candidate(winner, te)
if(winner == "WLS") {
  validation_scale <- sqrt(pmax(predict(entry$variance, assign_cluster(va, cluster_fit)), entry$variance_floor))
  test_scale <- sqrt(pmax(predict(entry$variance, assign_cluster(te, cluster_fit)), entry$variance_floor))
} else { validation_scale <- rep(1, nrow(va)); test_scale <- rep(1, nrow(te)) }
# Split-conformal order statistic; temporal exchangeability is not guaranteed.
calibration_scores <- sort(abs(va$first_innings_total - validation_pred) / validation_scale)
quantile_index <- min(length(calibration_scores), ceiling((length(calibration_scores) + 1) * .8))
radius <- calibration_scores[quantile_index]
intervals <- tibble(match_id = te$match_id, actual = te$first_innings_total, predicted = test_pred,
 lower = pmax(0, test_pred - radius*test_scale), upper = test_pred + radius*test_scale)
coverage <- mean(intervals$actual >= intervals$lower & intervals$actual <= intervals$upper)
save_csv(intervals, "prediction_intervals")
save_csv(tibble(model = winner, nominal_coverage = .8, empirical_coverage = coverage,
 mean_width = mean(intervals$upper - intervals$lower), calibration_N = length(calibration_scores), calibration_radius = radius), "interval_summary")
save_csv(tibble(key = c("report_sections", "course_topics", "slides", "short_talk_minutes", "detailed_note_seconds_low", "detailed_note_seconds_high", "bootstrap_replicates", "parallel_replicates", "gap_replicates", "interval_percent", "confidence_percent", "vif_moderate", "vif_severe", "loading_label_threshold"),
 value = c(5, 8, 13, 10, 60, 90, 500, 100, 50, 80, 95, 5, 10, .3)), "settings")
append_csv(tibble(key=c("ratio_denominator","interaction_significance","uniqueness_lower_bound","training_sd_plot_scale","figure_height_inches","figure_width_inches","wide_figure_width_inches","figure_dpi","single_thread_simulations","team_history_window","scheduled_death_overs","XI_players","inferred_top_order_players"),
 value=c(10,.05,.005,1,5,8,11,200,1,10,5,11,3)),"settings")
p <- ggplot(intervals, aes(actual, predicted)) + geom_errorbar(aes(ymin = lower, ymax = upper), alpha = .25, colour = palette["batting"]) +
 geom_point(colour = palette["batting"], alpha = .6) + geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = palette["bowling"]) +
 scale_x_continuous(limits=c(0,ceiling(max(c(intervals$actual,intervals$upper))/50)*50)) +
 scale_y_continuous(limits=c(0,ceiling(max(c(intervals$actual,intervals$upper))/50)*50)) +
 labs(x = "Actual first-innings total (runs)", y = "Predicted total (runs)")
save_plot(p, 26, "test_predictions", glue::glue("{winner} reaches test RMSE {round(test_metrics$rmse[match(winner,test_metrics$model)], 1)} runs"),
 "Frozen model with validation-calibrated prediction intervals", "Results: final evaluation", "Points near the dashed equality line predict well; bars show score uncertainty.", glue::glue("Empirical coverage is {round(100*coverage, 1)}%, which can differ from nominal coverage."))
p <- ggplot(test_metrics, aes(rmse, reorder(model, rmse))) + geom_errorbarh(aes(xmin = low, xmax = high), height = .15, colour = "grey55") +
 geom_point(aes(colour = model == winner), size = 3) + scale_colour_manual(values = c("FALSE" = unname(palette["batting"]), "TRUE" = unname(palette["bowling"]))) +
 labs(x = "Test RMSE (runs)", y = "Frozen candidate", colour = "Selected using validation")
save_plot(p, 27, "test_comparison", glue::glue("The validation-selected model ranks {rank(test_metrics$rmse, ties.method='min')[match(winner,test_metrics$model)]} on test RMSE"),
 "Date-block bootstrap intervals describe test RMSE uncertainty", "Results: final evaluation", "Lower values predict better; compare overlapping uncertainty intervals cautiously.", "The test ranking is reported without changing the frozen model.")
errors <- cv %>% filter(method == cv_summary$method[1]) %>% transmute(season, rmse, source = "Rolling raw procedure")
errors <- bind_rows(errors, tibble(season = unique(va$season), rmse = vm$rmse[match(winner, vm$model)], source = "Final validation"),
 tibble(season = unique(te$season), rmse = test_metrics$rmse[match(winner, test_metrics$model)], source = "Final test"))
save_csv(errors, "season_errors")
p <- ggplot(errors, aes(season, rmse, colour = source)) + geom_point(size = 3) +
 geom_line(data = errors %>% filter(source == "Rolling raw procedure")) +
 ggrepel::geom_text_repel(aes(label = round(rmse, 1)), size = 3, seed = 42) +
 labs(x = "Assessment season", y = "RMSE (runs)", colour = "Evaluation")
save_plot(p, 28, "season_error", glue::glue("Season error ranges from {round(min(errors$rmse),1)} to {round(max(errors$rmse),1)} runs"),
 "Rolling raw-procedure errors and frozen final-model evaluation; procedures differ", "Results: final evaluation", "Points show prediction error on later seasons, not training fit.", "Changing seasons can expose weaknesses hidden by pooled summaries.")
log_run(paste("Final", winner), if(is.null(entry$fit)) winner else paste(deparse(formula(entry$fit)), collapse = " "), nrow(tr), vm$p[match(winner,vm$model)],
 paste(range(tr$season),collapse="–"), as.character(unique(te$season)), test_metrics$rmse[match(winner,test_metrics$model)],
 test_metrics$mae[match(winner,test_metrics$model)], test_metrics$r2[match(winner,test_metrics$model)], vm$adj_r2[match(winner,vm$model)], "One frozen final test evaluation")
decision("D-014", 8, "Final model selection must precede test outcomes.", "Pick the best test model; freeze the lowest-validation-RMSE candidate.",
 paste("Freeze", winner, "using validation RMSE, breaking exact ties by fewer predictors; retain training fit and use validation-calibrated intervals."),
 "The held-out test season measures transfer after decisions are locked.", "Using validation for both selection and calibration weakens formal conformal coverage guarantees, as does temporal drift. Interval coverage is therefore assessed empirically; no guaranteed coverage claim is made.")
phase_result(8, "Frozen final evaluation", c("final_selection", "test_metrics", "interval_summary"),
 "Figures f26–f28 show forecasts, frozen comparisons and temporal error. The validation winner is retained even if another candidate performs better on test.", "Honest evaluation separates model selection from performance reporting.", "How would performance change with verified weather forecasts and rule-era features?")
