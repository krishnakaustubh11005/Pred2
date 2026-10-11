set.seed(42)
source(here::here("R", "modelling.R")); enable_lm_audit()
tr <- subset(d, split == "train")
va <- subset(d, split == "validation")
print(head(tr))
print(dim(tr))
models <- list()
register_model("B0 training mean", NULL, tr, va, rep(mean(tr$first_innings_total), nrow(va)), "baseline")
register_model("B1 venue history", NULL, tr, va, va$venue_avg_first_inn, "baseline")
check_ratio(nrow(tr), 1, "Simple regression")
simple <- lm(first_innings_total ~ venue_avg_first_inn, data = tr)
print(summary(simple))
print(confint(simple))
register_model("Simple", simple, tr, va)
save_csv(broom::tidy(simple, conf.int = TRUE), "simple_coefficients"); save_csv(broom::glance(simple), "simple_summary")
grid <- tibble(venue_avg_first_inn = seq(min(tr$venue_avg_first_inn), max(tr$venue_avg_first_inn), length.out = 100))
grid <- bind_cols(grid, as_tibble(predict(simple, grid, interval = "confidence")))
p <- ggplot(tr, aes(venue_avg_first_inn, first_innings_total)) + geom_point(alpha = .3, colour = palette["batting"]) +
 geom_ribbon(data = grid, aes(ymin = lwr, ymax = upr, y = fit), alpha = .15) +
 geom_line(data = grid, aes(y = fit), colour = palette["bowling"]) +
 annotate("text", x = -Inf, y = Inf, label = sprintf("Score = %.1f + %.2f × venue mean", coef(simple)[1], coef(simple)[2]), hjust = -.1, vjust = 1.7, size = 3.5) +
 labs(x = "Earlier venue average (runs)", y = "Actual total (runs)")
save_plot(p, 6, "simple_fit", glue::glue("A higher venue mean predicts {round(coef(simple)[2], 2)} runs per extra run"),
 "Training simple regression with a confidence band for the mean", "Results: simple regression", "The line predicts the mean; individual scores scatter around it.", "Venue history is an imperfect anchor rather than a precise score forecast.")
save_plot(diagnostic_panels(simple), 7, "simple_diagnostics", glue::glue("Simple regression leaves residual SD of {round(summary(simple)$sigma, 1)} runs"),
 "Residual shape, normality, spread and leverage", "Results: simple regression", "Each panel's subtitle describes the desirable pattern.", "Diagnostics test whether the model's assumptions are plausible.", TRUE)
# Store24 pattern: inspect the full model, then select backward using AIC.
full_formula <- first_innings_total ~ venue_avg_first_inn + venue_sd_first_inn +
  venue_prior_matches + venue_boundary_rate + season_index + toss_winner_batting_first +
  bat_average + bat_strike_rate + bat_boundary_pct + bat_top_order_sr + bat_depth +
  team_last10_total + bowl_economy + bowl_strike_rate + bowl_dot_pct +
  bowl_wickets_match + bowl_death_economy
check_ratio(nrow(tr), length(feature_names()), "Full multiple regression")
full <- lm(full_formula, data = tr)
print(summary(full))
raw <- step(full, direction = "backward", trace = 0)
print(summary(raw))
# Both functions are demonstrated in class; do not register duplicate candidates.
step_comparison <- MASS::stepAIC(full, direction = "backward", trace = FALSE)
stopifnot(identical(names(coef(raw)), names(coef(step_comparison))))
register_model("Multiple full", full, tr, va)
register_model("Multiple AIC", raw, tr, va)
save_csv(as.data.frame(raw$anova), "aic_selection_path")

# Boston pattern: nested comparisons with main effects retained in the full fit.
interaction <- update(full_formula, . ~ . + venue_avg_first_inn:season_index)
polynomial <- update(full_formula, . ~ . + I(season_index^2))
check_ratio(nrow(tr), length(feature_names()) + 1, "Interaction candidate")
fi <- lm(interaction, data = tr)
check_ratio(nrow(tr), length(feature_names()) + 1, "Polynomial candidate")
fp <- lm(polynomial, data = tr)
print(anova(full, fi))
print(anova(full, fp))
partial <- tibble(term = c("venue × season", "season squared"),
 p_value = c(anova(full, fi)$`Pr(>F)`[2], anova(full, fp)$`Pr(>F)`[2]))
save_csv(partial, "partial_f_tests")
# Only training evidence decides whether these extensions enter the candidate set.
if (partial$p_value[1] < .05) register_model("Multiple interaction", fi, tr, va)
if (partial$p_value[2] < .05) register_model("Multiple polynomial", fp, tr, va)
save_csv(broom::tidy(raw, conf.int = TRUE), "multiple_coefficients"); save_csv(broom::glance(raw), "multiple_summary")
strength_correlation <- cor(tr$bat_strike_rate, tr$bat_boundary_pct)
save_csv(tibble(feature1 = "bat_strike_rate", feature2 = "bat_boundary_pct", correlation = strength_correlation), "correlated_strength")
p <- ggplot(tr, aes(bat_strike_rate, bat_boundary_pct)) + geom_point(alpha = .3, colour = palette["batting"]) +
 labs(x = "XI historical strike rate (runs per 100 balls)", y = "XI historical boundary deliveries (%)")
save_plot(p, 8, "related_strength", glue::glue("Batting pace and boundaries correlate at {round(strength_correlation, 2)}"),
 "Two training features carry overlapping information", "Results: multiple regression", "An upward point cloud shows measurements moving together.", "Related inputs can redistribute coefficient estimates when fitted together.")
effects <- broom::tidy(raw, conf.int = TRUE) %>% filter(term != "(Intercept)") %>%
 mutate(training_sd = vapply(term, function(v) sd(tr[[v]]), numeric(1)),
        estimate = estimate * training_sd, conf.low = conf.low * training_sd, conf.high = conf.high * training_sd)
save_csv(effects,"standardised_coefficients")
save_plot(coef_plot(effects) + labs(x = "Score change per training SD (runs)"), 9, "coefficients", glue::glue("{length(coef(raw))-1} predictors remain in the selected raw model"),
 "Effects and confidence intervals scaled to one training standard deviation", "Results: multiple regression", "Intervals crossing zero indicate uncertain conditional effects; the common scale permits comparison.", "Each effect holds other included predictors fixed and is not causal; original units remain in the coefficient table.")
swing <- bind_rows(broom::tidy(simple) %>% mutate(model = "Simple"), broom::tidy(full) %>% mutate(model = "Full")) %>% filter(term == "venue_avg_first_inn")
save_csv(swing, "coefficient_swing")
decision("D-019", 4, "The supplied classroom pattern must govern modelling.",
 "Retain the previous procedures; adapt the Store24 and Boston examples.",
 "Use visible lm fits, backward AIC step and stepAIC verification, nested interaction and polynomial tests, correlation and coefficient comparisons. Supersedes D-009.",
 "The analysis can be followed alongside the actual course scripts.",
 "Stepwise coefficient intervals are exploratory. Added terms retain their main effects.")
phase_result(4, "Course-aligned regression", c("simple_summary", "validation_metrics", "partial_f_tests", "coefficient_swing"),
 "Figures f06–f09 show the simple fit, diagnostics, overlapping strength inputs and selected coefficients. All comparisons use validation outcomes.",
 "An association can change when other predictors enter the model.", "Can a smaller set of input scores preserve prediction accuracy?")
