set.seed(42)
vm <- read.csv(here::here("results", "validation_metrics.csv"))
# Baselines benchmark the task; the final model is chosen among fitted regressions.
eligible <- subset(vm, !model %in% c("B0 training mean", "B1 venue history"))
eligible <- eligible[order(eligible$rmse, eligible$p), ]
winner <- eligible$model[1]
entry <- models[[winner]]
save_csv(data.frame(model = winner, validation_rmse = eligible$rmse[1],
 training_N = nobs(entry$fit), predictors = length(coef(entry$fit)) - 1,
 refit_policy = "retain training fit; classical prediction intervals",
 test_status = "previously assessed season; no test-guided selection in this revision"), "final_selection")
saveRDS(list(winner = winner, models = models, dimension_fits = dimension_fits, cluster_fit = cluster_fit,
 training_mean = mean(tr$first_innings_total), feature_names = feature_names()), here::here("results", "frozen_models.rds"))

# Freeze first, then assess every candidate on the same later-season innings.
te <- subset(d, split == "test")
predictions <- bind_rows(lapply(names(models), function(name) data.frame(model = name, match_id = te$match_id,
 date = te$date, season = te$season, actual = te$first_innings_total, predicted = predict_candidate(name, te))))
test_metrics <- predictions %>% group_by(model) %>% group_modify(~metrics(.x$actual, .x$predicted)) %>% ungroup() %>%
 left_join(vm %>% select(model, p, adj_r2, validation_rmse = rmse), by = "model") %>%
 mutate(test_rank = rank(rmse, ties.method = "min"))
save_csv(test_metrics, "test_metrics")
save_csv(predictions, "test_predictions")

# Boston example: use the regression's prediction interval for an individual.
interval_data <- te
if (!is.null(entry$transform)) interval_data <- transform_strength(te, combined, entry$transform)
if (isTRUE(entry$cluster)) interval_data <- assign_cluster(interval_data, cluster_fit)
if (winner == "WLS") {
 new_weights <- 1 / group_variance(interval_data, entry$variance)
 interval_matrix <- predict(entry$fit, newdata = interval_data, interval = "prediction", level = .80,
   weights = new_weights)
} else {
 interval_matrix <- predict(entry$fit, newdata = interval_data, interval = "prediction", level = .80)
}
if (entry$type == "log") interval_matrix <- exp(interval_matrix)
intervals <- data.frame(match_id = te$match_id, actual = te$first_innings_total,
 predicted = interval_matrix[, "fit"], lower = interval_matrix[, "lwr"], upper = interval_matrix[, "upr"])
stopifnot(isTRUE(all.equal(as.numeric(intervals$predicted), predict_candidate(winner, te), tolerance = 1e-8)))
coverage <- mean(intervals$actual >= intervals$lower & intervals$actual <= intervals$upper)
save_csv(intervals, "prediction_intervals")
save_csv(data.frame(model = winner, nominal_coverage = .80, empirical_coverage = coverage,
 mean_width = mean(intervals$upper - intervals$lower), method = "classical regression prediction interval"), "interval_summary")
save_csv(data.frame(key = c("report_sections", "course_topics", "slides", "short_talk_minutes",
 "detailed_note_seconds_low", "detailed_note_seconds_high", "parallel_replicates", "interval_percent",
 "confidence_percent", "loading_label_threshold", "ratio_denominator", "interaction_significance",
 "training_sd_plot_scale", "figure_height_inches", "figure_width_inches", "wide_figure_width_inches",
 "figure_dpi", "single_thread_simulations", "team_history_window", "scheduled_death_overs", "XI_players",
 "inferred_top_order_players", "kmeans_random_starts", "cluster_minimum_k", "cluster_maximum_k",
 "uniqueness_warning_reference"), value = c(5,8,13,10,60,90,100,80,95,.3,10,.05,1,5,8,11,200,1,10,5,11,3,25,2,6,.005)), "settings")

axis_limits <- range(c(0, intervals$actual, intervals$predicted, intervals$lower, intervals$upper))
axis_limits <- c(floor(axis_limits[1]/50)*50, ceiling(axis_limits[2]/50)*50)
p <- ggplot(intervals, aes(actual, predicted)) + geom_errorbar(aes(ymin = lower, ymax = upper), alpha = .25, colour = palette["batting"]) +
 geom_point(colour = palette["batting"], alpha = .6) + geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = palette["bowling"]) +
 scale_x_continuous(limits = axis_limits) + scale_y_continuous(limits = axis_limits) +
 labs(x = "Actual first-innings total (runs)", y = "Predicted total (runs)")
save_plot(p, 26, "test_predictions", glue::glue("{winner} reaches test RMSE {round(test_metrics$rmse[match(winner, test_metrics$model)], 1)} runs"),
 "Frozen training fit with classical regression prediction intervals", "Results: final evaluation",
 "Points near equality predict well; bars describe individual-score uncertainty.",
 glue::glue("Observed interval coverage is {round(100*coverage,1)}%; model assumptions and season changes affect coverage."))
p <- ggplot(test_metrics, aes(rmse, reorder(model, rmse))) + geom_point(aes(colour = model == winner), size = 3) +
 scale_colour_manual(values = c("FALSE" = unname(palette["batting"]), "TRUE" = unname(palette["bowling"])), labels = c("Other", "Selected")) +
 labs(x = "Test RMSE (runs)", y = "Candidate", colour = "Selected on validation")
save_plot(p, 27, "test_comparison", glue::glue("The validation choice ranks {test_metrics$test_rank[match(winner, test_metrics$model)]} on test error"),
 "Same held-out innings for every candidate; no extra uncertainty procedure", "Results: final evaluation",
 "Lower RMSE means smaller squared prediction errors.", "Test ranks describe results without changing the selected model.")
errors <- data.frame(season = c(unique(va$season), unique(te$season)),
 rmse = c(eligible$rmse[1], test_metrics$rmse[match(winner, test_metrics$model)]),
 source = c("Validation", "Test"))
save_csv(errors, "season_errors")
p <- ggplot(errors, aes(factor(season), rmse, fill = source)) + geom_col(width = .5) +
 scale_fill_manual(values = c(Validation = unname(palette["validation"]), Test = unname(palette["test"]))) +
 geom_text(aes(label = round(rmse,1)), vjust = -.4) + expand_limits(y = max(errors$rmse)*1.1) +
 labs(x = "Assessment season", y = "RMSE (runs)", fill = "Assessment")
save_plot(p, 28, "season_error", glue::glue("Test error is {round(abs(diff(errors$rmse)),1)} runs {if(diff(errors$rmse)>=0) 'higher' else 'lower'} than validation"),
 "The same frozen model is assessed on validation and test seasons", "Results: final evaluation",
 "Bar heights show error with a common zero origin.", "Season changes can alter forecasting performance.")
log_run(paste("Final", winner), paste(deparse(formula(entry$fit)), collapse = " "), nobs(entry$fit),
 eligible$p[1], paste(range(tr$season), collapse = "–"), as.character(unique(te$season)),
 test_metrics$rmse[match(winner,test_metrics$model)], test_metrics$mae[match(winner,test_metrics$model)],
 test_metrics$r2[match(winner,test_metrics$model)], eligible$adj_r2[1], "Selection frozen before revised test metrics")
decision("D-024", 8, "Evaluation must retain basic checks and stay within the chosen course scope.",
 "Keep the earlier evaluation extensions; use validation selection and classical regression intervals.",
 paste("Choose", winner, "among fitted regressions by validation RMSE, with fewer predictors breaking exact ties. Keep baseline benchmarks and classical prediction intervals. Supersedes D-014."),
 "The student explicitly retained chronological evaluation and basic metrics; interval prediction appears in the Boston script.",
 "The test season was examined previously. This revision is not a new untouched experiment. Log forecasts target a median; intervals depend on the fitted model assumptions.")
phase_result(8, "Course-aligned frozen evaluation", c("final_selection", "test_metrics", "interval_summary"),
 "Figures f26–f28 report point predictions, class-style intervals, common-row comparisons and seasonal errors.",
 "Keep the validation choice even if its test ranking differs.", "Are the observed errors and interval coverage useful in practice?")
