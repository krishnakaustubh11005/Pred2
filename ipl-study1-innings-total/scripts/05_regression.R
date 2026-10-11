set.seed(42)
source(here::here("R", "modelling.R")); enable_lm_audit()
tr <- d %>% filter(split == "train"); va <- d %>% filter(split == "validation")
models <- list()
register_model("B0 training mean", NULL, tr, va, rep(mean(tr$first_innings_total), nrow(va)), "baseline")
register_model("B1 venue history", NULL, tr, va, va$venue_avg_first_inn, "baseline")
simple <- checked_lm(first_innings_total ~ venue_avg_first_inn, tr, "Simple regression")
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
cv <- rolling_raw(tr); save_csv(cv, "rolling_cv")
cv_summary <- cv %>% group_by(method) %>% summarise(rmse = sqrt(weighted.mean(rmse^2, N_assess)), .groups = "drop") %>% arrange(rmse)
save_csv(cv_summary, "rolling_cv_summary")
raw_fits <- setNames(lapply(c("Full", "AIC", "BIC"), function(method) choose_raw(tr, method)), c("Full", "AIC", "BIC"))
for (name in names(raw_fits)) register_model(paste("Multiple", name), raw_fits[[name]], tr, va)
raw <- raw_fits[[cv_summary$method[1]]]
interaction <- update(formula(raw), . ~ . + venue_avg_first_inn:season_index)
polynomial <- update(formula(raw), . ~ . + I(season_index^2))
fi <- checked_lm(interaction, tr, "Interaction candidate"); fp <- checked_lm(polynomial, tr, "Polynomial candidate")
partial <- tibble(term = c("venue × season", "season squared"), p_value = c(anova(raw, fi)$`Pr(>F)`[2], anova(raw, fp)$`Pr(>F)`[2]))
save_csv(partial, "partial_f_tests")
# Only training evidence decides whether these extensions enter the candidate set.
if (partial$p_value[1] < .05) register_model("Multiple interaction", fi, tr, va)
if (partial$p_value[2] < .05) register_model("Multiple polynomial", fp, tr, va)
register_model("Multiple selected", raw, tr, va)
save_csv(broom::tidy(raw, conf.int = TRUE), "multiple_coefficients"); save_csv(broom::glance(raw), "multiple_summary")
vif <- vif_table(raw_fits$Full); save_csv(vif, "vif_raw")
p <- ggplot(vif, aes(vif, reorder(term, vif))) + geom_col(fill = palette["batting"]) +
 geom_vline(xintercept = c(5, 10), linetype = "dashed", colour = palette["bowling"]) +
 labs(x = "Variance inflation factor", y = "Predictor") + theme(axis.text.y = element_text(size = 9))
save_plot(p, 8, "vif", glue::glue("The full model's largest VIF is {round(max(vif$vif), 1)}"),
 "Full raw model; dashed thresholds mark moderate and severe inflation", "Results: multiple regression", "Longer bars indicate more overlap with other predictors.", "Collinearity makes individual effects harder to interpret.")
effects <- broom::tidy(raw, conf.int = TRUE) %>% filter(term != "(Intercept)") %>%
 mutate(training_sd = vapply(term, function(v) sd(tr[[v]]), numeric(1)),
        estimate = estimate * training_sd, conf.low = conf.low * training_sd, conf.high = conf.high * training_sd)
save_csv(effects,"standardised_coefficients")
save_plot(coef_plot(effects) + labs(x = "Score change per training SD (runs)"), 9, "coefficients", glue::glue("{length(coef(raw))-1} predictors remain in the selected raw model"),
 "Effects and confidence intervals scaled to one training standard deviation", "Results: multiple regression", "Intervals crossing zero indicate uncertain conditional effects; the common scale permits comparison.", "Each effect holds other included predictors fixed and is not causal; original units remain in the coefficient table.")
swing <- bind_rows(broom::tidy(simple) %>% mutate(model = "Simple"), broom::tidy(raw_fits$Full) %>% mutate(model = "Full")) %>% filter(term == "venue_avg_first_inn")
save_csv(swing, "coefficient_swing")
decision("D-009", 4, "Many features compete and overlap.", "Select by training fit; select AIC/BIC/full procedures by rolling-origin error.",
 paste("Use", cv_summary$method[1], "as the raw selection procedure; compare training-significant interaction and polynomial candidates on validation."),
 "Chronological cross-validation evaluates each selection procedure on later training seasons.", "Stepwise selection makes ordinary coefficient intervals exploratory; significance is not proof of causal influence.")
phase_result(4, "Regression", c("rolling_cv_summary", "simple_summary", "validation_metrics", "partial_f_tests"),
 "Figures f06–f09 show the simple fit, assumptions, collinearity and coefficients. Model comparisons use validation outcomes only.", "Prediction quality and coefficient interpretability are different goals.", "Can dimension reduction simplify overlapping player measurements?")
