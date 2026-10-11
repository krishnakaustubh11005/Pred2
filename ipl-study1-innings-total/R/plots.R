palette <- c(batting = "#0072B2", bowling = "#D55E00", neutral = "#009E73",
             highlight = "#CC79A7", train = "#0072B2", validation = "#E69F00", test = "#009E73")
study_theme <- function() theme_minimal(base_size = 14) + theme(
  plot.title = element_text(face = "bold", size = 16),
  plot.subtitle = element_text(colour = "grey40", size = 11),
  panel.grid.minor = element_blank(), panel.grid.major = element_line(colour = "grey92"),
  legend.position = "bottom", plot.margin = margin(12, 20, 12, 12))
theme_set(study_theme())
pretty_feature <- function(x) dplyr::recode(x,
 venue_avg_first_inn = "Venue mean", venue_sd_first_inn = "Venue SD", venue_prior_matches = "Venue history count",
 venue_boundary_rate = "Venue boundaries", season_index = "Season index", toss_winner_batting_first = "Toss winner bats",
 bat_average = "Batting average", bat_strike_rate = "Batting strike rate", bat_boundary_pct = "Batting boundaries",
 bat_top_order_sr = "Top-order strike rate", bat_depth = "Batting depth", team_last10_total = "Team recent total",
 bowl_economy = "Bowling economy", bowl_strike_rate = "Bowling strike rate", bowl_dot_pct = "Bowling dot rate",
 bowl_wickets_match = "Wickets per appearance", bowl_death_economy = "Death-over economy", .default = x)
save_plot <- function(plot, id, name, title, subtitle, section, how, meaning, wide = FALSE) {
  filename <- sprintf("f%02d_%s.png", id, name)
  title <- stringr::str_wrap(as.character(title), if (wide) 85 else 65)
  subtitle <- stringr::str_wrap(subtitle, if (wide) 110 else 85)
  if(inherits(plot, "patchwork")) plot <- plot + patchwork::plot_annotation(title = title,
    subtitle = subtitle, theme = study_theme())
  else plot <- plot + labs(title = title, subtitle = subtitle)
  ggsave(here::here("figures", filename), plot, width = if (wide) 11 else 8, height = 5,
         dpi = 200, bg = "white", limitsize = FALSE)
  gather_labels <- function(p) {
    own <- if(inherits(p,"patchwork") && is.null(p$labels$x) && is.null(p$labels$y)) list() else list(p$labels)
    c(own,unlist(lapply(p$patches$plots,gather_labels),recursive=FALSE))
  }
  labels <- gather_labels(plot)
  labelled_axes <- length(labels)>0 && all(vapply(labels,function(z) !is.null(z$x) && !is.null(z$y) && nzchar(z$x) && nzchar(z$y),logical(1)))
  append_csv(tibble(id, filename, title = as.character(title), subtitle, section, how, meaning,
    labelled_axes, width_inches=if(wide) 11 else 8,height_inches=5,dpi=200), "figure_manifest")
  invisible(filename)
}
heatmap_plot <- function(mat, xlab = "Component", ylab = "Variable", cutoff = 0) {
  df <- as.data.frame(as.table(mat)) %>% setNames(c("variable", "component", "value"))
  ggplot(df, aes(component, variable, fill = value)) + geom_tile() +
    geom_text(aes(label = ifelse(abs(value) >= cutoff, sprintf("%.2f", value), "")), size = 3) +
    scale_fill_gradient2(low = palette["bowling"], mid = "white", high = palette["batting"], midpoint = 0,
      breaks = scales::pretty_breaks(n=3), guide = guide_colourbar(barwidth = unit(4,"cm"))) +
    labs(x = xlab, y = ylab, fill = "Value") +
    scale_x_discrete(labels = pretty_feature) + scale_y_discrete(labels = pretty_feature) +
    theme(axis.text.y = element_text(size = 9))
}
coef_plot <- function(df) ggplot(df %>% filter(term != "(Intercept)"),
 aes(estimate, reorder(term, estimate))) + geom_vline(xintercept = 0, colour = "grey60") +
 geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = .2, colour = palette["batting"]) +
 geom_point(colour = palette["batting"]) + labs(x = "Coefficient (runs per feature unit)", y = "Predictor") +
 theme(axis.text.y = element_text(size = 9))
