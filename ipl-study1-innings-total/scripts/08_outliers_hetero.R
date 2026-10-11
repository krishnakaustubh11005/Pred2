set.seed(42)
vm <- readr::read_csv(here::here("results", "validation_metrics.csv"), show_col_types = FALSE)
best_raw_name <- vm %>% filter(str_detect(model, "^Multiple")) %>% arrange(rmse, p) %>% slice(1) %>% pull(model)
best_raw <- models[[best_raw_name]]$fit
diag <- ctr %>% select(match_id, venue, season, first_innings_total, curtailed) %>% mutate(
 studentized = rstudent(best_raw), leverage = hatvalues(best_raw), cooks = cooks.distance(best_raw),
 dffits = dffits(best_raw), max_dfbetas = apply(abs(dfbetas(best_raw)), 1, max))
mm <- model.matrix(best_raw)[, -1, drop = FALSE]
covmat <- cov(mm); ev <- eigen(covmat, symmetric = TRUE); keep <- ev$values > max(ev$values) * 1e-9
inverse <- ev$vectors[, keep, drop = FALSE] %*% diag(1/ev$values[keep], nrow = sum(keep)) %*% t(ev$vectors[, keep, drop = FALSE])
diag$mahalanobis <- mahalanobis(mm, colMeans(mm), inverse, inverted = TRUE)
N <- nrow(ctr); pp <- length(coef(best_raw)) - 1
diag <- diag %>% mutate(flagged = abs(studentized) > 3 | leverage > 2*(pp+1)/N | cooks > 4/N |
 abs(dffits) > 2*sqrt((pp+1)/N) | max_dfbetas > 2/sqrt(N) | mahalanobis > qchisq(.99, sum(keep)),
 explanation = case_when(curtailed ~ "Fewer legal balls without being all out: shortened exposure may explain the low score.",
 studentized > 3 ~ "Much higher total than the pre-match model expected: inspect exceptional scoring.",
 studentized < -3 ~ "Much lower total than expected: inspect a batting collapse or interruption.",
 leverage > 2*(pp+1)/N ~ "Unusual historical feature combination, often a venue or roster cold start.",
 TRUE ~ "Coefficient sensitivity merits inspection; the statistical flag alone is not grounds for deletion."))
save_csv(diag, "influence_diagnostics"); save_csv(diag %>% filter(flagged), "flagged_innings")
save_csv(tibble(N, predictors = pp, studentized_cutoff = 3, leverage_cutoff = 2*(pp+1)/N,
 cooks_cutoff = 4/N, dffits_cutoff = 2*sqrt((pp+1)/N), dfbetas_cutoff = 2/sqrt(N), mahalanobis_cutoff = qchisq(.99, sum(keep))), "influence_thresholds")
worst <- diag %>% slice_max(cooks, n = 4)
p <- ggplot(diag, aes(leverage, studentized, size = cooks, colour = curtailed)) + geom_point(alpha = .4) +
 geom_hline(yintercept = c(-3, 0, 3), linetype = "dashed") + geom_vline(xintercept = 2*(pp+1)/N, linetype = "dashed") +
 ggrepel::geom_text_repel(data = worst, aes(label = match_id), size = 3, seed = 42, show.legend = FALSE) +
 scale_colour_manual(values = c("FALSE" = unname(palette["batting"]), "TRUE" = unname(palette["bowling"]))) +
 labs(x = "Leverage", y = "Studentized residual", colour = "Shortened", size = "Cook's distance")
save_plot(p, 19, "influence", glue::glue("{sum(diag$flagged)} training innings trigger an influence check"),
 "Unusual inputs, large errors and coefficient sensitivity", "Results: outlier detection", "Large bubbles affect coefficients; dashed lines mark inspection thresholds.", "Statistical flags prompt explanation rather than automatic deletion.")
diag$order <- seq_len(nrow(diag))
p <- ggplot(diag, aes(order, cooks)) + geom_segment(aes(xend = order, yend = 0), colour = palette["batting"], alpha = .6) +
 geom_hline(yintercept = 4/N, colour = palette["bowling"], linetype = "dashed") +
 ggrepel::geom_text_repel(data = diag %>% slice_max(cooks, n = 4), aes(label = match_id), size = 3, seed = 42) +
 scale_x_continuous(labels=scales::comma) +
 labs(x = "Training innings in date order", y = "Cook's distance")
save_plot(p, 20, "cooks", glue::glue("{sum(diag$cooks > 4/N)} innings exceed the Cook's distance reference"),
 "Influence measured across the training timeline", "Results: outlier detection", "Stems above the dashed line merit investigation.", "A few influential innings can change estimated relationships.")
unshort <- ctr %>% filter(!curtailed)
reduced <- checked_lm(formula(best_raw), unshort, "Exclude shortened training innings")
register_model("Exclude curtailed", reduced, unshort, cva); models[["Exclude curtailed"]]$cluster <- !is.null(models[[best_raw_name]]$cluster)
check_ratio(nrow(ctr), pp, "Robust regression")
robust <- MASS::rlm(formula(best_raw), data = ctr, maxit = 100)
register_model("Robust", robust, ctr, cva, type = "rlm"); models$Robust$cluster <- !is.null(models[[best_raw_name]]$cluster)
cc <- bind_rows(broom::tidy(best_raw) %>% mutate(treatment = "All innings"), broom::tidy(reduced) %>% mutate(treatment = "Exclude shortened"),
 broom::tidy(robust) %>% mutate(treatment = "Robust fit")) %>% filter(term != "(Intercept)")
effect_sd <- apply(model.matrix(best_raw)[,-1,drop=FALSE],2,sd)
cc <- cc %>% mutate(estimate = estimate * unname(effect_sd[term]))
save_csv(cc, "outlier_coefficients")
p <- ggplot(cc, aes(estimate, term, colour = treatment)) + geom_point(position = position_dodge(width = .5)) +
 geom_vline(xintercept = 0, colour = "grey60") + labs(x = "Effect per training design-column SD (runs)", y = "Predictor", colour = "Treatment") + theme(axis.text.y = element_text(size = 9))
save_plot(p, 21, "outlier_treatments", glue::glue("Three treatments compare sensitivity across {pp} predictors"),
 "Same formula with all innings, shortened innings removed, or robust fitting", "Results: outlier detection", "Compare positions of each predictor across colours.", "Large movement shows dependence on influential or shortened observations.")
base_tests <- hetero_tests(best_raw, ctr, "Raw")
log_formula <- formula(best_raw); log_formula[[2]] <- quote(log_total)
logfit <- checked_lm(log_formula, ctr, "Log-total model")
smear <- mean(exp(residuals(logfit)))
register_model("Log total", logfit, ctr, cva, exp(predict(logfit, cva)) * smear, "log")
models[["Log total"]]$smear <- smear; models[["Log total"]]$cluster <- !is.null(models[[best_raw_name]]$cluster)
variance_data <- ctr %>% mutate(squared_residual = residuals(best_raw)^2)
variance_model <- checked_lm(squared_residual ~ venue_cluster + season_index, variance_data, "Variance candidate")
variance_floor <- max(1, quantile(variance_data$squared_residual, .05))
training_variance <- pmax(predict(variance_model, ctr), variance_floor)
save_csv(ctr %>% mutate(predicted_variance=training_variance,raw_residual=residuals(best_raw)) %>%
 group_by(venue_cluster) %>% summarise(N=n(),predicted_sd=sqrt(mean(predicted_variance)),observed_residual_sd=sd(raw_residual),.groups="drop"),"venue_variance")
wls <- checked_lm(formula(best_raw), ctr, "Weighted least squares", weights = 1 / training_variance)
register_model("WLS", wls, ctr, cva); models$WLS$variance <- variance_model; models$WLS$variance_floor <- variance_floor
models$WLS$cluster <- TRUE
hc3 <- lmtest::coeftest(best_raw, vcov. = sandwich::vcovHC(best_raw, type = "HC3"))
se <- tibble(term = names(coef(best_raw)), classical = sqrt(diag(vcov(best_raw))), HC3 = hc3[, 2]) %>% filter(term != "(Intercept)")
save_csv(se, "standard_errors")
tests <- bind_rows(base_tests, hetero_tests(logfit, ctr, "Log total"), hetero_tests(wls, ctr, "WLS weighted residuals", weighted=TRUE))
weighted_aux <- tibble(e2 = (sqrt(1/training_variance)*residuals(wls))^2, fit = fitted(wls))
weighted_test <- checked_lm(e2 ~ fit + I(fit^2), weighted_aux, "WLS weighted-residual White")
stopifnot(isTRUE(all.equal(tests$statistic[tests$model=="WLS weighted residuals" & tests$test=="White fitted-value"],nrow(ctr)*summary(weighted_test)$r.squared)))
save_csv(tests, "heteroscedasticity_tests")
rd <- ctr %>% mutate(fitted = fitted(best_raw), residual = residuals(best_raw))
p <- ggplot(rd, aes(fitted, residual)) + geom_point(alpha = .3, colour = palette["batting"]) + geom_hline(yintercept = 0) +
 geom_smooth(method = "loess", se = FALSE) + labs(x = "Fitted total (runs)", y = "Residual (runs)")
save_plot(p, 22, "residual_mean", glue::glue("Breusch-Pagan gives p = {format.pval(base_tests$p_value[1], digits=2)}"),
 "Training residuals of the selected multiple regression", "Results: heteroscedasticity", "Look for changing vertical spread as well as a curved centre.", "A variance test concerns uncertainty, not just the mean prediction.")
p1 <- ggplot(rd, aes(venue_cluster, residual)) + geom_boxplot(fill = palette["batting"], alpha = .3) + geom_hline(yintercept = 0) +
 labs(x = "Training venue group", y = "Residual (runs)") + theme(axis.text.x = element_text(size = 10))
p2 <- ggplot(rd, aes(factor(season), residual)) + geom_boxplot(fill = palette["neutral"], alpha = .3) + geom_hline(yintercept = 0) +
 labs(x = "Training season", y = "Residual (runs)") + theme(axis.text.x = element_text(angle = 60, hjust = 1, size = 8))
save_plot(p1+p2, 23, "residual_spread", glue::glue("Residual spread is compared across {nlevels(rd$venue_cluster)} venue groups and seasons"),
 "Boxes compare the middle half of residuals", "Results: heteroscedasticity", "Different box heights suggest different error variance.", "Venue-dependent uncertainty is plausible but must be supported by evidence.", TRUE)
before <- tibble(fitted = fitted(best_raw), residual = residuals(best_raw), treatment = "Raw residuals (runs)")
after <- tibble(fitted = fitted(wls), residual = sqrt(1/training_variance)*residuals(wls), treatment = "Weighted residuals (standardised)")
p <- ggplot(bind_rows(before, after), aes(fitted, residual)) + geom_point(alpha = .3, colour = palette["batting"]) +
 geom_hline(yintercept = 0) + geom_smooth(method = "loess", se = FALSE) + facet_wrap(~treatment, scales = "free_y") +
 labs(x = "Fitted total (runs)", y = "Residual (panel units)")
save_plot(p, 24, "variance_remedy", glue::glue("WLS uses a variance floor of {round(variance_floor, 1)} squared runs"),
 "Raw and weighted residual patterns; vertical units differ", "Results: heteroscedasticity", "Assess whether spread remains stable within each panel, not relative point heights.", "Weighting changes the fitted mean and the scale of its diagnostics.", TRUE)
p <- se %>% mutate(across(c(classical,HC3),~.x*unname(effect_sd[term]))) %>%
 pivot_longer(-term, names_to = "method", values_to = "se") %>% ggplot(aes(se, term, fill = method)) +
 geom_col(position = "dodge") + scale_fill_manual(values = c(classical = unname(palette["batting"]), HC3 = unname(palette["bowling"]))) +
 labs(x = "Effect standard error per training SD (runs)", y = "Predictor", fill = "Uncertainty estimate") + theme(axis.text.y = element_text(size = 9))
save_plot(p, 25, "robust_se", glue::glue("The median HC3-to-classical SE ratio is {round(median(se$HC3/se$classical), 2)}"),
 "Classical and heteroscedasticity-robust uncertainty", "Results: heteroscedasticity", "Longer bars mean greater uncertainty in a coefficient.", "HC3 changes inference while leaving point predictions unchanged.")
decision("D-012", 7, "Influence flags must not dictate deletion.", "Delete statistical outliers; retain observations and compare explicit treatments.",
 "Retain flagged innings, compare excluding curtailed training innings and robust regression on the same validation target.",
 "Valid extremes are part of the actual-total prediction problem; sensitivity analyses reveal their effects.", "Narratives identify plausible statistical explanations rather than claiming independently verified match events.")
decision("D-013", 7, "Error variance may change with venue and time.", "Assume constant variance; compare logs, WLS and HC3 inference.",
 "Compare log regression with training smearing, WLS from a training variance model, and HC3 standard errors; bound fitted variances below a training residual quantile.",
 "Log retransformation needs bias correction and inverse-variance weights must remain positive.", "Use a fitted-value White test to respect the predictor limit; report it as a reduced-form test. WLS may fail to remove heteroscedasticity. Wider intervals at high-scoring grounds are a conditional explanation, not an assumed finding.")
phase_result(7, "Influence and unequal variance", c("influence_thresholds", "heteroscedasticity_tests", "validation_metrics"), "Figures f19–f25 inspect influence, treatment sensitivity, residual spread and robust uncertainty. A small p-value diagnoses an assumption; it does not prove that a remedy predicts better.", "Uncertainty estimates and point forecasts can respond differently to a remedy.", "Which candidate performs best on the reserved validation season?")
