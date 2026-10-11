bat_features <- c("bat_average", "bat_strike_rate", "bat_boundary_pct", "bat_top_order_sr", "bat_depth", "team_last10_total")
bowl_features <- c("bowl_economy", "bowl_strike_rate", "bowl_dot_pct", "bowl_wickets_match", "bowl_death_economy")
context_features <- c("venue_avg_first_inn", "venue_sd_first_inn", "venue_prior_matches", "venue_boundary_rate", "season_index", "toss_winner_batting_first")
feature_names <- function() c(context_features, bat_features, bowl_features)
safe_rate <- function(a, b, fallback = 0) if (sum(b) > 0) sum(a) / sum(b) else fallback
player_rates <- function(bat, bowl, players) {
  ba <- bat %>% group_by(player_id) %>% summarise(runs = sum(runs), balls = sum(balls), outs = sum(outs),
    boundaries = sum(boundaries), position = mean(position), .groups = "drop")
  bo <- bowl %>% group_by(player_id) %>% summarise(runs_b = sum(runs), balls_b = sum(balls), wickets_b = sum(wickets),
    dots_b = sum(dots), death_runs = sum(death_runs), death_balls = sum(death_balls), appearances = sum(appearances), .groups = "drop")
  league <- c(avg = safe_rate(bat$runs, bat$outs), sr = 100 * safe_rate(bat$runs, bat$balls),
    boundary = 100 * safe_rate(bat$boundaries, bat$balls), econ = 6 * safe_rate(bowl$runs, bowl$balls),
    bowl_sr = safe_rate(bowl$balls, bowl$wickets), dot = 100 * safe_rate(bowl$dots, bowl$balls),
    wpm = safe_rate(bowl$wickets, bowl$appearances), death = 6 * safe_rate(bowl$death_runs, bowl$death_balls))
  rates <- players %>% left_join(ba, by = "player_id") %>% left_join(bo, by = "player_id")
  blend <- function(value, count, mean) {
    w <- pmin(replace_na(count, 0) / 20, 1)
    w * replace_na(value, mean) + (1 - w) * mean
  }
  rates %>% mutate(avg = blend(runs / pmax(outs, 1), balls, league["avg"]),
    sr = blend(100 * runs / pmax(balls, 1), balls, league["sr"]),
    boundary_pct = blend(100 * boundaries / pmax(balls, 1), balls, league["boundary"]),
    econ = blend(6 * runs_b / pmax(balls_b, 1), balls_b, league["econ"]),
    bowl_sr = blend(balls_b / pmax(wickets_b, 1), balls_b, league["bowl_sr"]),
    dot = blend(100 * dots_b / pmax(balls_b, 1), balls_b, league["dot"]),
    wpm = blend(wickets_b / pmax(appearances, 1), balls_b, league["wpm"]),
    death_econ = blend(6 * death_runs / pmax(death_balls, 1), death_balls, league["death"]))
}
feature_row <- function(m, past, bat, bowl, lineup, rates = NULL) {
  if (is.null(rates)) rates <- player_rates(bat, bowl, lineup)
  v <- past %>% filter(venue == m$venue)
  league_mean <- if (nrow(past)) mean(past$first_innings_total) else 0
  league_sd <- if (nrow(past) > 1) sd(past$first_innings_total) else 0
  b <- rates %>% filter(team == m$batting_team)
  o <- rates %>% filter(team == m$bowling_team)
  top <- b %>% arrange(replace_na(position, Inf), player_id) %>% slice_head(n = 3)
  team <- past %>% filter(batting_team == m$batting_team) %>% arrange(date, match_id) %>% slice_tail(n = 10)
  tibble(match_id = m$match_id,
    venue_avg_first_inn = if (nrow(v)) mean(v$first_innings_total) else league_mean,
    venue_sd_first_inn = if (nrow(v) > 1) sd(v$first_innings_total) else league_sd,
    venue_prior_matches = nrow(v), venue_boundary_rate = if (nrow(v)) mean(v$boundary_rate) else if(nrow(past)) mean(past$boundary_rate) else 0,
    season_index = m$season - min(c(past$season, m$season)) + 1,
    toss_winner_batting_first = as.integer(m$toss_winner == m$batting_team),
    bat_average = mean(b$avg), bat_strike_rate = mean(b$sr), bat_boundary_pct = mean(b$boundary_pct),
    bat_top_order_sr = mean(top$sr), bat_depth = sum(b$sr > 125),
    team_last10_total = if(nrow(team)) mean(team$first_innings_total) else league_mean,
    bowl_economy = mean(o$econ), bowl_strike_rate = mean(o$bowl_sr), bowl_dot_pct = mean(o$dot),
    bowl_wickets_match = mean(o$wpm), bowl_death_economy = mean(o$death_econ))
}
build_features <- function(clean) {
  m <- clean$matches %>% arrange(date, match_id)
  # Daily cumulative history excludes the current date, including all double-headers.
  out <- lapply(sort(unique(m$date)), function(d) {
    today <- m %>% filter(date == d)
    past <- m %>% filter(date < d)
    bat <- clean$batting %>% filter(date < d)
    bowl <- clean$bowling %>% filter(date < d)
    players <- clean$lineups %>% filter(match_id %in% today$match_id)
    rates <- player_rates(bat, bowl, players)
    bind_rows(lapply(seq_len(nrow(today)), function(i) {
      r <- rates %>% filter(match_id == today$match_id[i])
      feature_row(today[i, ], past, bat, bowl, players, r)
    }))
  })
  result <- m %>% left_join(bind_rows(out), by = "match_id")
  # Independent expanding venue state: aggregate same-day matches first, then
  # lag cumulative sums so none of today's results can enter today's inputs.
  venue_history <- m %>% group_by(venue, date) %>% summarise(
    count = n(), total = sum(first_innings_total), total2 = sum(first_innings_total^2),
    boundary_sum = sum(boundary_rate), .groups = "drop") %>% arrange(venue, date) %>%
    group_by(venue) %>% mutate(
      prior_n = lag(cumsum(count), default = 0), prior_runs = lag(cumsum(total), default = 0),
      prior_runs2 = lag(cumsum(total2), default = 0), prior_boundary = lag(cumsum(boundary_sum), default = 0)) %>%
    ungroup() %>% select(venue, date, starts_with("prior_"))
  result %>% left_join(venue_history, by = c("venue", "date")) %>% mutate(
    venue_avg_first_inn = ifelse(prior_n > 0, prior_runs / pmax(prior_n, 1), venue_avg_first_inn),
    venue_sd_first_inn = ifelse(prior_n > 1,
      sqrt(pmax(0, (prior_runs2 - prior_runs^2 / pmax(prior_n, 1)) / pmax(prior_n - 1, 1))), venue_sd_first_inn),
    venue_prior_matches = prior_n,
    venue_boundary_rate = ifelse(prior_n > 0, prior_boundary / pmax(prior_n, 1), venue_boundary_rate)) %>% select(-starts_with("prior_"))
}
