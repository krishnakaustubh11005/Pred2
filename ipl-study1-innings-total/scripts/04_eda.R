set.seed(42)
source(here::here("R", "course.R"))
record_course_sources()
d <- readRDS(here::here("data", "processed", "features.rds"))
tr <- subset(d, split == "train")
# Intro-to-R pattern: inspect rows, dimensions and descriptive measures first.
print(head(tr[, c("season", "venue", "first_innings_total")]))
print(summary(tr$first_innings_total))
save_csv(data.frame(N = nrow(tr), mean = mean(tr$first_innings_total),
 median = median(tr$first_innings_total), sd = sd(tr$first_innings_total),
 minimum = min(tr$first_innings_total), maximum = max(tr$first_innings_total)), "score_summary")
training_covariance <- cov(tr[, feature_names()])
save_csv(as.data.frame(as.table(training_covariance)) %>%
 setNames(c("feature1", "feature2", "covariance")), "covariances")
timeline <- d %>% count(season, split)
p <- ggplot(timeline, aes(season, n, fill = split)) + geom_col() +
 scale_fill_manual(values = palette[c("train", "validation", "test")]) +
 labs(x = "Season (calendar year)", y = "First innings (count)")
save_plot(p, 1, "timeline", glue::glue("{sum(timeline$split == 'train')} seasons train the model before later evaluation"),
 "Chronological allocation; bar height shows usable innings", "Data", "Read from left to right; colour marks each split.", "Later seasons test how well earlier evidence transfers.")
p <- ggplot(tr, aes(first_innings_total)) + geom_histogram(binwidth = 10, fill = palette["batting"], colour = "white") +
 geom_vline(xintercept = c(mean(tr$first_innings_total), median(tr$first_innings_total)), linetype = c("solid", "dashed"), colour = palette["bowling"]) +
 annotate("text", x = mean(tr$first_innings_total), y = Inf, label = sprintf("Mean %.1f; median %.1f", mean(tr$first_innings_total), median(tr$first_innings_total)), vjust = 2, hjust = .4, size = 3.5) +
 labs(x = "First-innings total (runs)", y = "Innings (count)")
save_plot(p, 2, "totals", glue::glue("Training scores average {round(mean(tr$first_innings_total), 1)} runs"),
 "Training-only distribution, including shortened innings", "Data", "Bars count scores; solid and dashed lines mark mean and median.", "Shortened and unusually strong innings broaden the distribution.")
season <- tr %>% group_by(season) %>% summarise(N = n(), mean = mean(first_innings_total),
 se = sd(first_innings_total) / sqrt(n()), .groups = "drop") %>% mutate(low = mean - qt(.975, N - 1) * se, high = mean + qt(.975, N - 1) * se)
record <- tr %>% slice_max(first_innings_total, n = 1, with_ties = FALSE)
p <- ggplot(season, aes(season, mean)) + geom_ribbon(aes(ymin = low, ymax = high), fill = palette["batting"], alpha = .15) +
 geom_line(colour = palette["batting"]) + geom_point(colour = palette["batting"]) +
 geom_point(data = record, aes(x = season, y = first_innings_total), inherit.aes = FALSE, colour = palette["highlight"], size = 2.5) +
 ggrepel::geom_label_repel(data = record, aes(x = season, y = first_innings_total, label = paste(batting_team, first_innings_total, "runs")), inherit.aes = FALSE, size = 3, seed = 42) +
 labs(x = "Season (calendar year)", y = "First-innings total (runs)")
save_plot(p, 3, "season_trend", glue::glue("Season means change by {round(tail(season$mean, 1) - head(season$mean, 1), 1)} runs across training"),
 "Season averages with confidence bands; the highest individual training innings is annotated", "Data", "The ribbon measures uncertainty in each season mean, not individual scores.", "Changing scoring conditions motivate a time predictor.")
top <- tr %>% count(venue, sort = TRUE) %>% slice_head(n = 10) %>% pull(venue)
p <- ggplot(tr %>% filter(venue %in% top), aes(first_innings_total, reorder(venue, first_innings_total, median))) +
 geom_boxplot(fill = palette["batting"], alpha = .3, outlier.alpha = .3) +
 scale_y_discrete(labels = function(x) str_wrap(x, 30)) + labs(x = "First-innings total (runs)", y = "Venue") + theme(axis.text.y = element_text(size = 10))
venue_summary <- tr %>% group_by(venue) %>% summarise(N = n(), mean = mean(first_innings_total), median = median(first_innings_total), .groups = "drop")
save_plot(p, 4, "venue_totals", glue::glue("Common venues span {round(diff(range(venue_summary$median[venue_summary$venue %in% top])), 1)} runs in median score"),
 "Most frequent training venues, ordered by median", "Data", "The box spans the middle half of scores; the central line is the median.", "Venue differences are useful but their score distributions overlap.")
correlation <- cor(tr[, feature_names()]); order <- hclust(as.dist(1 - abs(correlation)))$order
p <- heatmap_plot(correlation[order, order], "Pre-innings feature", "Pre-innings feature") +
 theme(axis.text.x = element_text(angle = 65, hjust = 1, size = 8), axis.text.y = element_text(size = 8))
save_plot(p, 5, "correlation", glue::glue("The strongest feature correlation reaches {round(max(abs(correlation[upper.tri(correlation)])), 2)}"),
 "Training correlations; nearby variables have similar relationships", "Results: exploration", "Colour and printed values show direction and strength.", "Correlated measurements can destabilise regression coefficients.", TRUE)
save_csv(season, "season_eda"); save_csv(venue_summary, "venue_eda")
save_csv(as.data.frame(as.table(correlation)) %>% setNames(c("feature1", "feature2", "correlation")), "correlations")
decision("D-008", 3, "Exploration can accidentally reveal final outcomes.", "Plot every season's outcomes; plot training outcomes only.",
 "Show split sizes for all seasons but use training-only outcome and correlation plots; limit venue boxplots to the most frequent grounds.",
 "The report can motivate models without looking at held-out outcomes.", "Exploratory patterns describe historical training data, not guaranteed future behaviour.")
phase_result(3, "Exploration", c("season_eda", "venue_eda"), "Figures f01–f05 describe time, score distributions, venues and feature correlations. Venue and player histories can overlap in what they measure.", "Good plots explain both a pattern and its uncertainty.", "Does adding correlated strength measurements improve future predictions?")
