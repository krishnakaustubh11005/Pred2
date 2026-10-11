set.seed(42)
vm <- readr::read_csv(here::here("results", "validation_metrics.csv"), show_col_types = FALSE)
best_raw_name <- vm %>% filter(str_detect(model, "^Multiple")) %>% arrange(rmse, p) %>% slice(1) %>% pull(model)
best_raw <- models[[best_raw_name]]$fit
diag <- ctr %>% select(match_id, venue, season, first_innings_total, curtailed) %>% mutate(
 standardized = rstandard(best_raw), studentized = rstudent(best_raw),
 leverage = hatvalues(best_raw), cooks = cooks.distance(best_raw),
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
 scale_size_continuous(breaks = scales::pretty_breaks(n = 3)) +
 labs(x = "Leverage", y = "Studentized residual", colour = "Shortened", size = "Cook's distance") +
 theme(legend.box = "vertical")
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
# The class notes motivate deletion diagnostics, not automatic deletion.
# These are labelled sensitivity fits; every validation innings remains included.
unshort <- subset(ctr, !curtailed)
check_ratio(nrow(unshort), pp, "Exclude shortened training innings")
reduced <- lm(formula(best_raw), data = unshort)
print(summary(reduced))
register_model("Exclude curtailed", reduced, unshort, cva)
models[["Exclude curtailed"]]$cluster <- isTRUE(models[[best_raw_name]]$cluster)
influential <- diag$cooks > 4/N
unaffected <- ctr[!influential, ]
check_ratio(nrow(unaffected), pp, "Exclude Cook-influential training innings")
deleted_fit <- lm(formula(best_raw), data = unaffected)
print(summary(deleted_fit))
register_model("Exclude influential", deleted_fit, unaffected, cva)
models[["Exclude influential"]]$cluster <- isTRUE(models[[best_raw_name]]$cluster)
cc <- bind_rows(broom::tidy(best_raw) %>% mutate(treatment = "All innings"),
 broom::tidy(reduced) %>% mutate(treatment = "Exclude shortened"),
 broom::tidy(deleted_fit) %>% mutate(treatment = "Exclude influential")) %>% filter(term != "(Intercept)")
effect_sd <- apply(model.matrix(best_raw)[, -1, drop = FALSE], 2, sd)
cc <- cc %>% mutate(estimate = estimate * unname(effect_sd[term]))
save_csv(cc, "outlier_coefficients")
p <- ggplot(cc, aes(estimate, term, colour = treatment)) + geom_point(position = position_dodge(width = .5)) +
 scale_colour_manual(values = c("All innings" = unname(palette["batting"]), "Exclude shortened" = unname(palette["bowling"]), "Exclude influential" = unname(palette["neutral"]))) +
 geom_vline(xintercept = 0, colour = "grey60") + labs(x = "Effect per training design-column SD (runs)", y = "Predictor", colour = "Training fit") +
 theme(axis.text.y = element_text(size = 8))
save_plot(p, 21, "outlier_treatments", glue::glue("Three training fits inspect sensitivity across {pp} predictors"),
 "All innings compared with shortened or Cook-influential cases excluded", "Results: outlier detection",
 "Compare each coefficient across the three fits.", "Sensitivity exclusions never remove assessment cases.", TRUE)

# Heteroskedasticity.R: log the response, inspect residuals, and run gqtest.
log_formula <- formula(best_raw)
log_formula[[2]] <- quote(log_total)
check_ratio(nrow(ctr), pp, "Log-total regression")
logfit <- lm(log_formula, data = ctr)
print(summary(logfit))
register_model("Log total", logfit, ctr, cva, exp(predict(logfit, newdata = cva)), "log")
models[["Log total"]]$cluster <- isTRUE(models[[best_raw_name]]$cluster)

# gqtest fits two submodels via lm.fit internally. Check both segment ratios
# before calling the demonstrated function; order observations by season.
segment_n <- c(floor(nrow(ctr)/2), nrow(ctr) - floor(nrow(ctr)/2))
for (test_name in c("Raw", "Log total")) for (segment in seq_along(segment_n)) {
 label <- paste(test_name, "GQ internal OLS segment", segment)
 check_ratio(segment_n[segment], pp, label)
 segment_formula <- if(test_name == "Raw") formula(best_raw) else formula(logfit)
 log_run(label, paste(deparse(segment_formula), collapse = " "), segment_n[segment], pp,
   "training segment ordered by season", "variance diagnostic only", notes = "gqtest internal lm.fit; checked before invocation")
}
raw_gq <- lmtest::gqtest(best_raw, order.by = ctr$season_index)
log_gq <- lmtest::gqtest(logfit, order.by = ctr$season_index)
print(raw_gq)
print(log_gq)
tests <- data.frame(model = c("Raw", "Log total"), test = "Goldfeld–Quandt",
 statistic = c(unname(raw_gq$statistic), unname(log_gq$statistic)),
 p_value = c(raw_gq$p.value, log_gq$p.value))
save_csv(tests, "heteroscedasticity_tests")

# Market-share example: estimate residual variance separately for each group.
raw_residuals <- residuals(best_raw)
vars <- tapply(raw_residuals, ctr$venue_cluster, var)
group_n <- table(ctr$venue_cluster)
pooled_variance <- var(raw_residuals)
if (!is.finite(pooled_variance) || pooled_variance <= 0) stop("No positive residual variance for WLS")
fallback <- group_n < 2 | !is.finite(vars) | vars <= 0
vars[fallback] <- pooled_variance
variance_fit <- list(variances = vars, pooled_variance = pooled_variance)
training_variance <- unname(vars[as.character(ctr$venue_cluster)])
wts <- 1 / training_variance
stopifnot(all(is.finite(wts) & wts > 0))
ctr$.study_weights <- wts
check_ratio(nrow(ctr), pp, "Group-variance weighted least squares")
wls <- lm(formula(best_raw), data = ctr, weights = .study_weights)
print(summary(wls))
register_model("WLS", wls, ctr, cva)
models$WLS$variance <- variance_fit
models$WLS$cluster <- TRUE
save_csv(data.frame(venue_cluster = names(vars), N = as.numeric(group_n), variance = as.numeric(vars),
 predicted_sd = sqrt(as.numeric(vars)), used_pooled_fallback = as.logical(fallback)), "venue_variance")

# Classical summaries only: no separate covariance-estimator method is added.
se <- bind_rows(lapply(list(OLS = best_raw, WLS = wls), function(fit) {
  x <- as.data.frame(summary(fit)$coefficients)
  data.frame(term = rownames(x), se = x[[2]])
}), .id = "method") %>% filter(term != "(Intercept)")
save_csv(se, "standard_errors")
rd <- ctr %>% mutate(fitted = fitted(best_raw), residual = residuals(best_raw))
p <- ggplot(rd, aes(fitted, residual)) + geom_point(alpha = .3, colour = palette["batting"]) +
 geom_hline(yintercept = 0) + labs(x = "Fitted total (runs)", y = "Residual (runs)")
save_plot(p, 22, "residual_mean", glue::glue("Goldfeld–Quandt gives p = {format.pval(raw_gq$p.value, digits=2)}"),
 "Raw-model residuals; the test compares earlier and later season segments", "Results: heteroscedasticity",
 "Look for changing vertical spread around zero.", "A variance test does not establish which remedy predicts better.")
p1 <- ggplot(rd, aes(venue_cluster, residual)) + geom_boxplot(fill = palette["batting"], alpha = .3) +
 geom_hline(yintercept = 0) + labs(x = "Training venue group", y = "Residual (runs)")
p2 <- ggplot(rd, aes(factor(season), residual)) + geom_boxplot(fill = palette["neutral"], alpha = .3) +
 geom_hline(yintercept = 0) + labs(x = "Training season", y = "Residual (runs)") +
 theme(axis.text.x = element_text(angle = 60, hjust = 1, size = 8))
save_plot(p1 + p2, 23, "residual_spread", glue::glue("Residual spread is compared across {nlevels(rd$venue_cluster)} venue groups"),
 "Classroom plots inspect group and season differences", "Results: heteroscedasticity",
 "Compare box heights rather than only their centres.", "Group residual variances determine the WLS weights.", TRUE)
before <- data.frame(fitted = fitted(best_raw), residual = rstandard(best_raw), treatment = "OLS standardized residuals")
after <- data.frame(fitted = fitted(wls), residual = rstandard(wls), treatment = "WLS standardized residuals")
p <- ggplot(bind_rows(before, after), aes(fitted, residual)) + geom_point(alpha = .3, colour = palette["batting"]) +
 geom_hline(yintercept = 0) + facet_wrap(~treatment) + labs(x = "Fitted total (runs)", y = "Standardized residual")
save_plot(p, 24, "variance_remedy", glue::glue("WLS uses {length(vars)} training group variances"),
 "Before and after weighting; the same standardized-residual axes are used", "Results: heteroscedasticity",
 "Compare spread within each panel.", "Weighting changes the fit; it does not ensure equal remaining variance.", TRUE)
p <- se %>% mutate(se = se * unname(effect_sd[term])) %>% ggplot(aes(se, term, fill = method)) +
 geom_col(position = "dodge") + scale_fill_manual(values = c(OLS = unname(palette["batting"]), WLS = unname(palette["bowling"]))) +
 labs(x = "Classical effect SE per training SD (runs)", y = "Predictor", fill = "Fitted model") +
 theme(axis.text.y = element_text(size = 8))
save_plot(p, 25, "classical_se", glue::glue("OLS and WLS summaries report uncertainty for {pp} effects"),
 "Classical standard errors from two differently fitted models", "Results: heteroscedasticity",
 "Longer bars mean larger model-based coefficient uncertainty.", "These estimates rely on each fitted model's variance assumptions.", TRUE)
decision("D-022", 7, "Influence analysis must use taught diagnostics.",
 "Keep the earlier alternatives; use classical diagnostics and labelled case-removal fits.",
 "Retain valid extremes in the main fit, compare exclusion of curtailed or Cook-influential training cases, and keep all assessment rows. Supersedes D-012.",
 "The notes explain deletion diagnostics and the class R files demonstrate the selected measures.",
 "Sensitivity exclusions are not a claim that flagged innings are erroneous. The existing Cook reference remains; the example's alternative reference is not silently substituted.")
decision("D-023", 7, "Unequal variance remedies must follow Heteroskedasticity.R.",
 "Keep the previous variance modelling; use the class group-variance weighting example.",
 "Use log-response median forecasts, Goldfeld–Quandt tests on raw/log OLS fits, and WLS inverse variances estimated by tapply from training venue groups. Supersedes D-013.",
 "The group-weight construction and direct lm weights are visible in the supplied script.",
 "Small or invalid group variances use pooled training variance. Do not apply an OLS test that silently ignores WLS weights; inspect its standardized residuals instead.")
phase_result(7, "Course-aligned influence and unequal variance", c("influence_thresholds", "heteroscedasticity_tests", "venue_variance", "validation_metrics"),
 "Figures f19–f25 distinguish influence, case-removal sensitivity, residual spread and classical model summaries.",
 "A diagnostic warning and better future predictions are different claims.", "Which permitted regression predicts the validation season best?")
