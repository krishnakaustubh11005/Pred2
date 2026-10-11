set.seed(42)
source("scripts/00_setup.R")
for(f in c("logging","checks","features")) source(here::here("R",paste0(f,".R")))
clean <- readRDS(here::here("data","interim","clean.rds"))
features <- readRDS(here::here("data","processed","features.rds"))
leakage_test(clean$matches,clean$batting,clean$bowling,clean$lineups,features)
checks <- list(tibble(check="historical reconstruction",pass=TRUE))
m <- clean$matches %>% filter(season==2025) %>% slice(1)
past <- clean$matches %>% filter(date<m$date)
bat <- clean$batting %>% filter(date<m$date); bowl <- clean$bowling %>% filter(date<m$date)
xi <- clean$lineups %>% filter(match_id==m$match_id)
original <- feature_row(m,past,bat,bowl,xi)
changed <- m; changed$first_innings_total <- m$first_innings_total*10; changed$wickets <- 0; changed$legal_balls <- 1
stopifnot(identical(original,feature_row(changed,past,bat,bowl,xi)))
checks[[2]] <- tibble(check="current target and realised length cannot alter predictors",pass=TRUE)
newvenue <- m; newvenue$venue <- "Unseen fixture ground"
new <- feature_row(newvenue,past,bat,bowl,xi)
stopifnot(new$venue_prior_matches==0, isTRUE(all.equal(new$venue_avg_first_inn,mean(past$first_innings_total))))
checks[[3]] <- tibble(check="unseen venue uses earlier league fallback",pass=TRUE)
stopifnot(all(features$xi_verified),all(is.finite(as.matrix(features[,feature_names()]))),
 max(features$season[features$split=="train"])<min(features$season[features$split=="validation"]),
 max(features$season[features$split=="validation"])<min(features$season[features$split=="test"]))
checks[[4]] <- tibble(check="verified XI, finite inputs and chronological boundaries",pass=TRUE)
expected_batting <- vapply(seq_len(nrow(clean$matches)),function(i) {
  m <- clean$matches[i,]
  if(m$toss_decision=="bat") m$toss_winner else setdiff(unique(clean$lineups$team[clean$lineups$match_id==m$match_id]),m$toss_winner)[1]
},character(1))
stopifnot(identical(expected_batting,clean$matches$batting_team))
checks[[6]] <- tibble(check="batting identity follows pre-innings toss metadata",pass=TRUE)
# Isolate the expected failing ratio fixture from actual-model fit logs.
original_append <- append_csv; fixture_log <- NULL
append_csv <- function(x,name) fixture_log <<- x
ratio_error <- tryCatch({check_ratio(20,3,"intentional unit fixture");FALSE},error=function(e) grepl("ratio violated",conditionMessage(e)))
append_csv <- original_append
stopifnot(ratio_error,!fixture_log$pass,fixture_log$p==3)
checks[[5]] <- tibble(check="ratio violation stops and records a failing row",pass=TRUE)
save_csv(bind_rows(checks),"invariant_tests")
print(bind_rows(checks))
