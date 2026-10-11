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
