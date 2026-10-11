set.seed(42)
clean <- readRDS(here::here("data", "interim", "clean.rds"))
all_features <- build_features(clean)
complete <- clean$matches %>% group_by(season) %>% summarise(done = any(final), .groups = "drop") %>% filter(done) %>% pull(season)
if (length(complete) < 4) stop("Insufficient confirmed completed seasons for chronological evaluation.")
test_season <- max(complete); validation_season <- max(complete[complete < test_season])
features <- all_features %>% filter(season > min(season), season <= test_season, xi_verified,
                                    first_innings_total > 0) %>% mutate(split = case_when(
  season == test_season ~ "test", season == validation_season ~ "validation", TRUE ~ "train"))
stopifnot(all(is.finite(as.matrix(features[, feature_names()]))))
check_ratio(sum(features$split == "train"), length(feature_names()) + 2, "candidate pool including interaction and polynomial")
leakage_test(clean$matches, clean$batting, clean$bowling, clean$lineups, features)
saveRDS(features, here::here("data", "processed", "features.rds"))
readr::write_csv(features, here::here("data", "processed", "features.csv"))
save_csv(features %>% group_by(split) %>% summarise(N = n(), first_season = min(season), last_season = max(season), .groups = "drop"), "split_summary")
save_csv(tibble(item = c("burn-in innings", "unverified XI after burn-in", "incomplete-season innings", "nonpositive totals", "modelled innings", "numeric predictors", "seed", "shrinkage balls", "depth strike-rate threshold", "leakage audit rows"),
 value = c(sum(all_features$season == min(all_features$season)), sum(!all_features$xi_verified & all_features$season > min(all_features$season)),
 sum(all_features$season > test_season), sum(all_features$first_innings_total <= 0), nrow(features), length(feature_names()), 42, 20, 125, 20)), "feature_quality")
dictionary <- tibble(name = feature_names(), description = c(
 "Earlier venue mean first-innings total", "Earlier venue standard deviation", "Number of earlier venue innings", "Earlier venue boundary-delivery share",
 "Calendar season position", "Toss winner is batting first", "XI mean career batting average", "XI mean career strike rate", "XI mean career boundary percentage",
 "Strike rate of three XI players with earliest historical batting positions", "XI count with historical strike rate above threshold", "Team mean of most recent historical first innings",
 "Opposition XI mean economy", "Opposition XI mean bowling strike rate", "Opposition XI mean dot percentage", "Opposition XI mean wickets per bowling appearance", "Opposition XI mean death-over economy"),
 type = "numeric", units = c("runs", "runs", "innings", "proportion", "index", "binary", "runs/dismissal", "runs/100 balls", "percent", "runs/100 balls", "players", "runs", "runs/over", "balls/wicket", "percent", "wickets/appearance", "runs/over"),
 construction = c(
 "Mean of earlier-date first-innings totals at this venue; earlier league mean if none",
 "Sample SD of earlier-date venue totals; earlier league SD if fewer than two",
 "Count of first innings played at this venue on earlier dates",
 "Mean earlier venue innings boundary-delivery fraction, including all delivery events; earlier league fallback",
 "Calendar season year minus the earliest source year, plus the index offset",
 "Binary indicator that the toss winner is the team batting first, checked against toss decision",
 "XI mean of player bat runs divided by at least one dismissal; sparse histories blend with earlier league rates",
 "XI mean of player bat runs per hundred faced balls; wides excluded from faced balls",
 "XI mean of actual boundary events per hundred faced balls; running fours excluded",
 "Mean strike rate of the three XI players with earliest historical mean batting positions; registry IDs break ties",
 "Count of XI players whose earlier shrunken career strike rate exceeds the saved depth threshold",
 "Mean of the team's most recent earlier first innings, up to the saved history window; league fallback",
 "Opposition XI mean charged runs per over of legal balls; byes, leg-byes and penalties excluded",
 "Opposition XI mean legal balls divided by at least one bowler-credited wicket",
 "Opposition XI mean percent of legal deliveries conceding no total runs",
 "Opposition XI mean credited wickets per match with a bowling appearance, rather than per XI selection",
 "Opposition XI mean charged runs per over in the final scheduled overs; sparse death-ball history blends with league rate"),
 known_before_innings = "yes")
save_csv(dictionary, "variable_dictionary")
save_csv(features %>% summarise(across(everything(),~sum(is.na(.x)))) %>%
 pivot_longer(everything(),names_to="variable",values_to="missing_values"),"missing_values")
decision("D-006", 2, "Sparse history and batting roles require defaults.", "Drop debutants; shrink sparse histories.",
 "Drop earliest season as burn-in; linearly blend player rates to earlier league means until the specified history threshold. Infer top order from previous positions, and use prior league venue fallbacks.",
 "This allows debutants without knowing anything about their future performance.", "Career means include non-specialists; batting average and bowling strike rate use a minimum denominator to avoid infinity. Death overs are the final five scheduled overs.")
decision("D-007", 2, "Season completion and time split must be auditable.", "Assume current year is complete; require a recorded final.",
 "Use JSON final-stage markers to confirm completed seasons; reserve the latest two for test and validation. All learned transformations remain fitted on training seasons.",
 "A current or partial season cannot silently become the final benchmark.", "Completed-season coverage depends on Cricsheet availability; later validation histories may use earlier observed matches, simulating live forecasts rather than a season-start forecast.")
phase_result(2, "Historical features", c("split_summary", "feature_quality", "leakage_audit"),
 "Every input uses earlier match dates. The latest completed season is reserved, while the previous season supports final model selection.",
 "A strong-looking feature is invalid if it uses future information.", "Will player strength add predictive information beyond venue and time?")
