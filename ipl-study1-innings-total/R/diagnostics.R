diagnostic_panels <- function(model) {
  d <- tibble(fitted = fitted(model), residual = residuals(model), student = rstudent(model),
              leverage = hatvalues(model))
  a <- ggplot(d, aes(fitted, residual)) + geom_point(alpha = .35, colour = palette["batting"]) +
    geom_hline(yintercept = 0, colour = "grey50") + geom_smooth(method = "loess", se = FALSE) +
    labs(x = "Fitted score (runs)", y = "Residual (runs)", subtitle = "A flat pattern supports a linear mean")
  b <- ggplot(d, aes(sample = student)) + stat_qq(alpha = .4) + stat_qq_line() +
    labs(x = "Normal reference quantile", y = "Studentized residual", subtitle = "Points should hug the reference line")
  c <- ggplot(d, aes(fitted, sqrt(abs(student)))) + geom_point(alpha = .35) +
    geom_smooth(method = "loess", se = FALSE) + labs(x = "Fitted score (runs)",
      y = "Square-root absolute residual", subtitle = "Similar spread supports constant variance")
  e <- ggplot(d, aes(leverage, student)) + geom_point(alpha = .35) +
    geom_hline(yintercept = c(-3, 0, 3), linetype = "dashed") + labs(x = "Leverage", y = "Studentized residual",
      subtitle = "Unusual inputs and large errors deserve inspection")
  (a + b) / (c + e)
}
vif_table <- function(model) {
  v <- car::vif(model)
  if (is.matrix(v)) tibble(term = rownames(v), vif = v[, 1]^(1 / v[, 2]))
  else tibble(term = names(v), vif = as.numeric(v))
}
hetero_tests <- function(model, data, label, weighted = FALSE) {
  # The fitted-value White test avoids a quadratic expansion of the whole pool,
  # which would violate the course's candidate predictor limit.
  resid <- residuals(model)
  if(weighted) resid <- resid * sqrt(weights(model))
  aux <- tibble(e2 = resid^2, fit = fitted(model))
  white <- checked_lm(e2 ~ fit + I(fit^2), aux, paste0(label, " White auxiliary"))
  white_stat <- nrow(aux) * summary(white)$r.squared
  variance_data <- data; variance_data$.squared_error <- resid^2
  bp_formula <- formula(model); bp_formula[[2]] <- quote(.squared_error)
  bp_fit <- checked_lm(bp_formula,variance_data,paste0(label," BP auxiliary"))
  bp_stat <- nrow(data)*summary(bp_fit)$r.squared
  ordered <- order(data$season_index); n <- nrow(data)
  first_half <- ordered[seq_len(floor(n/2))]; second_half <- ordered[ceiling(n/2+.01):n]
  lower_data <- data[first_half,]; upper_data <- data[second_half,]
  first_fit <- checked_lm(formula(model),lower_data,paste0(label," GQ early segment"),
    weights=if(weighted) weights(model)[first_half] else NULL)
  second_fit <- checked_lm(formula(model),upper_data,paste0(label," GQ late segment"),
    weights=if(weighted) weights(model)[second_half] else NULL)
  gq_stat <- (deviance(second_fit)/df.residual(second_fit))/(deviance(first_fit)/df.residual(first_fit))
  if(!weighted) {
    # Cross-check our audited regressions against the installed reference tests.
    stopifnot(isTRUE(all.equal(bp_stat,unname(lmtest::bptest(model)$statistic),tolerance=1e-8)),
      isTRUE(all.equal(gq_stat,unname(lmtest::gqtest(model,order.by=data$season_index)$statistic),tolerance=1e-8)))
  }
  tibble(model = label, test = c("Breusch-Pagan", "White fitted-value", "Goldfeld-Quandt"),
         statistic = c(bp_stat, white_stat, gq_stat),
         p_value = c(pchisq(bp_stat,length(coef(bp_fit))-1,lower.tail=FALSE),pchisq(white_stat, 2, lower.tail = FALSE),
           pf(gq_stat,df.residual(second_fit),df.residual(first_fit),lower.tail=FALSE)))
}
