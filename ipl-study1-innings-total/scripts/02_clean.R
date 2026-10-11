set.seed(42)
for (f in c("logging", "checks", "features", "plots", "diagnostics")) source(here::here("R", paste0(f, ".R")))
info_files <- list.files(here::here("data", "raw"), pattern = "_info.csv$", full.names = TRUE)
read_info <- function(path) {
  x <- read.csv(path, header = FALSE, fill = TRUE, col.names = paste0("v", 1:5), stringsAsFactors = FALSE)
  get <- function(key, default = NA_character_) { z <- x$v3[x$v2 == key]; if (length(z)) z[1] else default }
  id <- get("match_id")
  people <- x[x$v2 == "registry" & x$v3 == "people", ]
  players <- x[x$v2 == "player", ]
  registry <- setNames(people$v5, people$v4)
  json_path <- here::here("data", "raw", "json", paste0(id, ".json"))
  j <- jsonlite::fromJSON(json_path, simplifyVector = FALSE)
  incoming <- character()
  for (inn in j$innings) for (over in inn$overs) for (del in over$deliveries)
    for (rep in del$replacements$match) incoming <- c(incoming, rep$`in`)
  players <- players[!players$v4 %in% incoming, ]
  lineups <- tibble(match_id = id, team = players$v3, player = players$v4,
                   player_id = unname(registry[players$v4]))
  stage <- if (is.null(j$info$event$stage)) "" else j$info$event$stage
  meta <- tibble(match_id = id, date = as.Date(get("date"), "%Y/%m/%d"),
    season = as.integer(format(date, "%Y")), venue = get("venue"),
    toss_winner = get("toss_winner"), toss_decision = get("toss_decision"),
    no_result = get("outcome", "") == "no result", dl = get("method", "") %in% c("D/L", "DLS"),
    final = tolower(stage) == "final", super_overs = list(as.integer(x$v3[x$v2 == "super_over"])),
    xi_verified = nrow(lineups) == 22 && all(table(lineups$team) == 11))
  list(meta = meta, lineups = lineups, registry = registry)
}
parts <- lapply(info_files, read_info)
meta <- bind_rows(lapply(parts, `[[`, "meta"))
lineups <- bind_rows(lapply(parts, `[[`, "lineups"))
team_map <- tibble(raw_name = sort(unique(lineups$team))) %>% mutate(canonical = case_when(
 raw_name == "Delhi Daredevils" ~ "Delhi Capitals", raw_name == "Kings XI Punjab" ~ "Punjab Kings",
 raw_name == "Royal Challengers Bangalore" ~ "Royal Challengers Bengaluru", TRUE ~ raw_name))
readr::write_csv(team_map, here::here("data", "reference", "team_names.csv"))
venue_map <- tibble(raw_name = sort(unique(meta$venue))) %>% mutate(canonical = case_when(
 str_detect(raw_name, "Chinnaswamy") ~ "M Chinnaswamy Stadium",
 str_detect(raw_name, "Chidambaram") ~ "MA Chidambaram Stadium",
 str_detect(raw_name, "Feroz Shah|Arun Jaitley") ~ "Arun Jaitley Stadium",
 str_detect(raw_name, "Punjab Cricket Association") ~ "PCA IS Bindra Stadium",
 str_detect(raw_name, "Rajiv Gandhi") ~ "Rajiv Gandhi International Stadium",
 str_detect(raw_name, "Zayed") ~ "Sheikh Zayed Stadium",
 str_detect(raw_name, "Yadavindra") ~ "Maharaja Yadavindra Singh Stadium",
 str_detect(raw_name, "Sardar Patel|Narendra Modi") ~ "Narendra Modi Stadium",
 str_detect(raw_name, "Subrata Roy|Maharashtra Cricket") ~ "Maharashtra Cricket Association Stadium",
 TRUE ~ str_remove(raw_name, ", (Mumbai|Delhi|Kolkata|Dharamsala|Pune|Jaipur|Raipur|Guwahati|Visakhapatnam)$")))
readr::write_csv(venue_map, here::here("data", "reference", "venue_names.csv"))
canon_team <- function(x) team_map$canonical[match(x, team_map$raw_name)]
meta$venue <- venue_map$canonical[match(meta$venue, venue_map$raw_name)]
meta$toss_winner <- canon_team(meta$toss_winner)
lineups$team <- canon_team(lineups$team)
read_balls <- function(i) {
  id <- parts[[i]]$meta$match_id
  b <- readr::read_csv(here::here("data", "raw", paste0(id, ".csv")),
    col_types = cols(.default = col_character()), progress = FALSE)
  if (!nrow(b)) return(NULL)
  b <- janitor::clean_names(b)
  # This real column is boolean text, not a numeric extra-run count.
  stopifnot(all(is.na(b$non_boundary) | b$non_boundary %in% c("true", "false", "0", "1")))
  b$non_boundary <- as.integer(replace_na(b$non_boundary, "false") %in% c("true", "1"))
  needed <- c("innings", "ball", "runs_off_bat", "extras", "wides", "noballs", "byes", "legbyes", "penalty", "non_boundary")
  for (v in needed) b[[v]] <- replace_na(as.numeric(b[[v]]), 0)
  b <- b %>% mutate(match_id = as.character(match_id),
    batting_team = canon_team(batting_team), bowling_team = canon_team(bowling_team),
    batter_id = unname(parts[[i]]$registry[striker]), nonstriker_id = unname(parts[[i]]$registry[non_striker]),
    bowler_id = unname(parts[[i]]$registry[bowler]), dismissed_id = unname(parts[[i]]$registry[player_dismissed]),
    date = parts[[i]]$meta$date, venue = parts[[i]]$meta$venue,
    legal = wides == 0 & noballs == 0, faced = wides == 0,
    total_runs = runs_off_bat + extras, boundary = runs_off_bat %in% c(4, 6) & non_boundary == 0,
    dismissed = !is.na(wicket_type) & !wicket_type %in% c("retired hurt", "obstructing the field"),
    bowler_wicket = dismissed & !wicket_type %in% c("run out", "retired out"),
    charged = total_runs - byes - legbyes - penalty, death = floor(ball) >= 15,
    super_over = innings %in% parts[[i]]$meta$super_overs[[1]] | innings > 2)
  b
}
balls_all <- bind_rows(lapply(seq_along(parts), read_balls))
balls <- balls_all %>% filter(!super_over)
innings <- balls %>% group_by(match_id, innings) %>% summarise(
  batting_team = first(batting_team), bowling_team = first(bowling_team),
  first_innings_total = sum(total_runs), legal_balls = sum(legal), wickets = sum(dismissed) + sum(!is.na(other_wicket_type)),
  boundary_rate = mean(boundary), .groups = "drop")
matches <- meta %>% select(-super_overs) %>% inner_join(innings %>% filter(innings == 1), by = "match_id") %>%
  mutate(curtailed = legal_balls < 120 & wickets < 10, log_total = log(first_innings_total)) %>% arrange(date, match_id)
positions <- balls %>% group_by(match_id, innings) %>% group_modify(~{
  p <- unique(as.vector(t(as.matrix(.x[, c("batter_id", "nonstriker_id")]))))
  tibble(player_id = p, position = seq_along(p))
}) %>% ungroup()
batting <- balls %>% group_by(match_id, innings, date, player_id = batter_id) %>% summarise(
  runs = sum(runs_off_bat), balls = sum(faced), boundaries = sum(boundary), .groups = "drop")
outs <- balls %>% filter(dismissed) %>% count(match_id, innings, player_id = dismissed_id, name = "outs")
batting <- batting %>% left_join(outs, by = c("match_id", "innings", "player_id")) %>%
  mutate(outs = replace_na(outs, 0L)) %>% left_join(positions, by = c("match_id", "innings", "player_id"))
bowling <- balls %>% group_by(match_id, date, player_id = bowler_id) %>% summarise(
  runs = sum(charged), balls = sum(legal), wickets = sum(bowler_wicket), dots = sum(legal & total_runs == 0),
  death_runs = sum(charged[death]), death_balls = sum(legal[death]), appearances = 1, .groups = "drop")
saveRDS(list(matches = matches, batting = batting, bowling = bowling, lineups = lineups), here::here("data", "interim", "clean.rds"))
quality <- tibble(item = c("info files", "raw deliveries", "super-over deliveries removed", "first innings",
 "no-result first innings", "D/L first innings", "curtailed first innings", "unverified initial XI", "missing player registry IDs", "date start", "date end", "seasons"),
 value = as.character(c(length(info_files), nrow(balls_all), sum(balls_all$super_over), nrow(matches),
 sum(matches$no_result), sum(matches$dl), sum(matches$curtailed), sum(!matches$xi_verified),
 sum(is.na(lineups$player_id)), as.character(min(matches$date)), as.character(max(matches$date)), n_distinct(matches$season))))
save_csv(quality, "data_quality")
save_csv(meta %>% group_by(season) %>% summarise(matches = n(), has_final = any(final), .groups = "drop"), "season_completeness")
decision("D-004", 1, "CSV player lists include later substitutes.", "Use all listed players; reconstruct initial XI from JSON substitutions.",
 "Supplement CSV with Cricsheet JSON, remove incoming match substitutes, and require verified initial XIs.",
 "Only the initial XI is available at the prediction time. JSON is used for identities and season-final markers, not target features.",
 "Unreconstructable XIs are excluded from modelling but retained in historical aggregates; substitution metadata is used solely to identify the original roster.")
decision("D-005", 1, "Names and special innings need consistent treatment.", "Keep spelling variants; canonicalise documented aliases.",
 "Use reference mapping tables, actual calendar season years, registry player IDs, remove super overs, retain D/L and no-result first innings with deliveries.",
 "Renames should not erase history. No deliveries means no observable target.", "Stadium redevelopment is combined under one venue; no-result totals may be incomplete. Home status is omitted because neutral and relocated fixtures make inference unreliable.")
phase_result(1, "Data and cleaning", c("data_quality", "season_completeness"),
 "Delivery rows became innings totals; identity corrections preserve histories. Special match outcomes remain flags rather than predictors.",
 "Cleaning decisions determine which question the model answers.", "How much do shortened innings affect predictive error?")
