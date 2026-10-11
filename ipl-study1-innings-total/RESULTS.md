# Results log

Results below are generated from saved analysis outputs as each phase is verified.


## Phase 0: Setup


setup_checks:



|check                 |pass |
|:---------------------|:----|
|R dependencies        |TRUE |
|Pandoc HTML rendering |TRUE |

package_versions:



|package     |version   |
|:-----------|:---------|
|tidyverse   |1.3.1     |
|here        |1.0.1     |
|lubridate   |1.8.0     |
|janitor     |2.2.0     |
|glue        |1.6.1     |
|ggrepel     |0.9.1     |
|patchwork   |1.1.1     |
|scales      |1.1.1     |
|viridis     |0.6.2     |
|psych       |2.1.9     |
|GPArotation |2014.11.1 |
|nFactors    |2.4.1     |

R dependencies load and a self-contained HTML smoke report renders. Local runtime artifacts are excluded from version control.

What I learned: R Markdown combines code and explanation into a reproducible document.

Open questions: Can the raw cricket records support valid pre-innings features?


## Phase 1: Data and cleaning

data_quality:



|item                          |value      |
|:-----------------------------|:----------|
|info files                    |1243       |
|raw deliveries                |295732     |
|super-over deliveries removed |175        |
|first innings                 |1243       |
|no-result first innings       |9          |
|D/L first innings             |23         |
|curtailed first innings       |28         |
|unverified initial XI         |0          |
|missing player registry IDs   |0          |
|date start                    |2008-04-18 |
|date end                      |2026-05-31 |
|seasons                       |19         |

season_completeness:



| season| matches|has_final |
|------:|-------:|:---------|
|   2008|      58|TRUE      |
|   2009|      57|TRUE      |
|   2010|      60|TRUE      |
|   2011|      73|TRUE      |
|   2012|      74|TRUE      |
|   2013|      76|TRUE      |
|   2014|      60|TRUE      |
|   2015|      59|TRUE      |
|   2016|      60|TRUE      |
|   2017|      59|TRUE      |
|   2018|      60|TRUE      |
|   2019|      60|TRUE      |

Delivery rows became innings totals; identity corrections preserve histories. Special match outcomes remain flags rather than predictors.

What I learned: Cleaning decisions determine which question the model answers.

Open questions: How much do shortened innings affect predictive error?

## Phase 2: Historical features

split_summary:



|split      |    N| first_season| last_season|
|:----------|----:|------------:|-----------:|
|test       |   74|         2026|        2026|
|train      | 1037|         2009|        2024|
|validation |   74|         2025|        2025|

feature_quality:



|item                        | value|
|:---------------------------|-----:|
|burn-in innings             |    58|
|unverified XI after burn-in |     0|
|incomplete-season innings   |     0|
|nonpositive totals          |     0|
|modelled innings            |  1185|
|numeric predictors          |    17|
|seed                        |    42|
|shrinkage balls             |    20|
|depth strike-rate threshold |   125|
|leakage audit rows          |    20|

leakage_audit:



|check                                          | rows|pass |
|:----------------------------------------------|----:|:----|
|strict earlier-date brute-force reconstruction |   20|TRUE |

Every input uses earlier match dates. The latest completed season is reserved, while the previous season supports final model selection.

What I learned: A strong-looking feature is invalid if it uses future information.

Open questions: Will player strength add predictive information beyond venue and time?

## Phase 3: Exploration

season_eda:



| season|  N|    mean|    se|     low|    high|
|------:|--:|-------:|-----:|-------:|-------:|
|   2009| 57| 150.263| 3.201| 143.851| 156.676|
|   2010| 60| 164.783| 3.719| 157.341| 172.225|
|   2011| 73| 152.370| 3.882| 144.630| 160.109|
|   2012| 74| 157.541| 3.441| 150.684| 164.397|
|   2013| 76| 155.895| 3.426| 149.070| 162.720|
|   2014| 60| 163.067| 3.662| 155.740| 170.393|
|   2015| 59| 166.254| 3.863| 158.521| 173.987|
|   2016| 60| 162.600| 3.822| 154.953| 170.247|
|   2017| 59| 165.780| 4.021| 157.730| 173.829|
|   2018| 60| 172.467| 3.649| 165.164| 179.769|
|   2019| 60| 166.733| 4.172| 158.384| 175.082|
|   2020| 60| 169.500| 3.714| 162.067| 176.933|

venue_eda:



|venue                                                                 |  N|    mean| median|
|:---------------------------------------------------------------------|--:|-------:|------:|
|Arun Jaitley Stadium                                                  | 84| 169.571|  168.0|
|Barabati Stadium                                                      |  7| 167.714|  170.0|
|Barsapara Cricket Stadium                                             |  3| 180.000|  197.0|
|Bharat Ratna Shri Atal Bihari Vajpayee Ekana Cricket Stadium, Lucknow | 14| 165.429|  165.0|
|Brabourne Stadium                                                     | 27| 178.519|  180.0|
|Buffalo Park                                                          |  3| 147.333|  148.0|
|De Beers Diamond Oval                                                 |  3| 158.000|  166.0|
|Dr DY Patil Sports Academy                                            | 33| 161.364|  160.0|
|Dr. Y.S. Rajasekhara Reddy ACA-VDCA Cricket Stadium                   | 15| 167.333|  167.0|
|Dubai International Cricket Stadium                                   | 46| 163.761|  164.5|
|Eden Gardens                                                          | 86| 168.430|  170.5|
|Green Park                                                            |  4| 161.250|  163.0|

Figures f01–f05 describe time, score distributions, venues and feature correlations. Venue and player histories can overlap in what they measure.

What I learned: Good plots explain both a pattern and its uncertainty.

Open questions: Does adding correlated strength measurements improve future predictions?

## Phase 4: Course-aligned regression

simple_summary:



| r.squared| adj.r.squared|  sigma| statistic| p.value| df|  logLik|     AIC|      BIC| deviance| df.residual| nobs|
|---------:|-------------:|------:|---------:|-------:|--:|-------:|-------:|--------:|--------:|-----------:|----:|
|     0.008|         0.007| 31.852|     8.497|   0.004|  1| -5059.6| 10125.2| 10140.03|  1050061|        1035| 1037|

validation_metrics:



|model            |  p| adj_r2|   rmse|    mae|     r2|
|:----------------|--:|------:|------:|------:|------:|
|B0 training mean |  0|     NA| 44.264| 36.366| -0.371|
|B1 venue history |  0|     NA| 43.034| 35.255| -0.296|
|Simple           |  1|  0.007| 43.077| 35.332| -0.299|
|Multiple full    | 17|  0.103| 38.786| 30.897| -0.053|
|Multiple AIC     |  6|  0.105| 39.109| 30.915| -0.071|

partial_f_tests:



|term           | p_value|
|:--------------|-------:|
|venue × season |   0.412|
|season squared |   0.094|

coefficient_swing:



|term                | estimate| std.error| statistic| p.value|model  |
|:-------------------|--------:|---------:|---------:|-------:|:------|
|venue_avg_first_inn |    0.314|     0.108|     2.915|   0.004|Simple |
|venue_avg_first_inn |   -0.539|     0.204|    -2.642|   0.008|Full   |

Figures f06–f09 show the simple fit, diagnostics, overlapping strength inputs and selected coefficients. All comparisons use validation outcomes.

What I learned: An association can change when other predictors enter the model.

Open questions: Can a smaller set of input scores preserve prediction accuracy?

## Phase 5: Course-aligned PCA and Factor Analysis

dimension_checks:



|block    | variables| retained_pcs| retained_factors| parallel_factors| pca_variance|fa_method      |fa_rotation | min_uniqueness| max_communality|boundary_warning | pca_score_error| fa_score_error| pca_off_diagonal| prcomp_score_error|
|:--------|---------:|------------:|----------------:|----------------:|------------:|:--------------|:-----------|--------------:|---------------:|:----------------|---------------:|--------------:|----------------:|------------------:|
|Batting  |         6|            1|                2|                2|        0.603|principal axis |varimax     |         -0.041|           1.041|TRUE             |               0|              0|                0|                  0|
|Bowling  |         5|            2|                2|                3|        0.741|principal axis |varimax     |         -0.341|           1.341|TRUE             |               0|              0|                0|                  0|
|Combined |        11|            3|                3|                3|        0.681|principal axis |varimax     |          0.010|           0.990|FALSE            |               0|              0|                0|                  0|

dimension_names:



|kind |axis |strongest_feature  |interpretation                              |block    |
|:----|:----|:------------------|:-------------------------------------------|:--------|
|PCA  |PC1  |bat_strike_rate    |Batting pace and depth                      |Batting  |
|FA   |PA1  |bat_strike_rate    |Batting pace and depth                      |Batting  |
|FA   |PA2  |team_last10_total  |Batting pace and depth                      |Batting  |
|PCA  |PC1  |bowl_dot_pct       |Bowling control and late-over pressure      |Bowling  |
|PCA  |PC2  |bowl_strike_rate   |Wicket-taking efficiency and mixed strength |Bowling  |
|FA   |PA1  |bowl_economy       |Bowling economy and run control             |Bowling  |
|FA   |PA2  |bowl_wickets_match |Bowling wicket threat                       |Bowling  |
|PCA  |PC1  |bat_strike_rate    |Batting pace and depth                      |Combined |
|PCA  |PC2  |bowl_wickets_match |Bowling wicket threat                       |Combined |
|PCA  |PC3  |bowl_strike_rate   |Wicket-taking efficiency and mixed strength |Combined |
|FA   |PA1  |bat_strike_rate    |Batting pace and depth                      |Combined |
|FA   |PA2  |bowl_economy       |Bowling economy and run control             |Combined |

Figures f10–f15 show training parallel analysis, loadings, scores, communalities and validation comparisons. Scores are reconstructed from saved weights.

What I learned: PCA summarises total variation; FA models shared variation plus uniqueness.

Open questions: Does compressing inputs retain useful predictive information?

## Phase 6: Course-aligned venue clustering

cluster_summary:



|  k| silhouette|main_linkage | random_starts|
|--:|----------:|:------------|-------------:|
|  2|      0.395|average      |            25|

cluster_selection:



|  k| within_ss| silhouette|
|--:|---------:|----------:|
|  2|    74.336|      0.395|
|  3|    55.113|      0.332|
|  4|    42.993|      0.343|
|  5|    35.863|      0.317|
|  6|    28.760|      0.323|

cluster_membership_tables:



|linkage  |kmeans         | hierarchical| Freq|
|:--------|:--------------|------------:|----:|
|single   |Higher scoring |            1|   24|
|single   |Lower scoring  |            1|   11|
|single   |Higher scoring |            2|    0|
|single   |Lower scoring  |            2|    1|
|complete |Higher scoring |            1|   24|
|complete |Lower scoring  |            1|    0|
|complete |Higher scoring |            2|    0|
|complete |Lower scoring  |            2|   12|
|average  |Higher scoring |            1|   24|
|average  |Lower scoring  |            1|    0|
|average  |Higher scoring |            2|    0|
|average  |Lower scoring  |            2|   12|

Figures f16–f18 show selection, the average-linkage tree and venue group profiles. All learned profiles and centres use training seasons.

What I learned: Clustering groups observations, while PCA and FA summarise variables.

Open questions: Do the venue groups improve validation forecasts?

## Phase 7: Influence and unequal variance

influence_thresholds:



|    N| predictors| studentized_cutoff| leverage_cutoff| cooks_cutoff| dffits_cutoff| dfbetas_cutoff| mahalanobis_cutoff|
|----:|----------:|------------------:|---------------:|------------:|-------------:|--------------:|------------------:|
| 1037|          4|                  3|            0.01|        0.004|         0.139|          0.062|             13.277|

heteroscedasticity_tests:



|model                  |test               | statistic| p_value|
|:----------------------|:------------------|---------:|-------:|
|Raw                    |Breusch-Pagan      |    12.970|   0.011|
|Raw                    |White fitted-value |    10.354|   0.006|
|Raw                    |Goldfeld-Quandt    |     1.177|   0.033|
|Log total              |Breusch-Pagan      |     8.399|   0.078|
|Log total              |White fitted-value |     0.656|   0.720|
|Log total              |Goldfeld-Quandt    |     1.031|   0.364|
|WLS weighted residuals |Breusch-Pagan      |     7.375|   0.117|
|WLS weighted residuals |White fitted-value |     4.165|   0.125|
|WLS weighted residuals |Goldfeld-Quandt    |     0.980|   0.590|

validation_metrics:



|model             |  p| adj_r2|   rmse|    mae|     r2|
|:-----------------|--:|------:|------:|------:|------:|
|B0 training mean  |  0|     NA| 44.264| 36.366| -0.371|
|B1 venue history  |  0|     NA| 43.034| 35.255| -0.296|
|Simple            |  1|  0.007| 43.077| 35.332| -0.299|
|Multiple Full     | 17|  0.103| 38.786| 30.897| -0.053|
|Multiple AIC      |  6|  0.105| 39.109| 30.915| -0.071|
|Multiple BIC      |  4|  0.100| 38.728| 30.804| -0.050|
|Multiple selected |  6|  0.105| 39.109| 30.915| -0.071|
|PCR               |  9|  0.096| 39.043| 30.796| -0.067|
|FA                |  9|  0.099| 38.757| 30.735| -0.051|
|Multiple clusters |  7|  0.105| 39.113| 30.964| -0.071|
|Exclude curtailed |  4|  0.099| 38.765| 30.782| -0.052|
|Robust            |  4|     NA| 38.706| 30.735| -0.049|

Figures f19–f25 inspect influence, treatment sensitivity, residual spread and robust uncertainty. A small p-value diagnoses an assumption; it does not prove that a remedy predicts better.

What I learned: Uncertainty estimates and point forecasts can respond differently to a remedy.

Open questions: Which candidate performs best on the reserved validation season?

## Phase 8: Frozen final evaluation

final_selection:



|model | validation_rmse|refit_policy                                           |
|:-----|---------------:|:------------------------------------------------------|
|WLS   |          38.671|training fit retained; validation calibrates intervals |

test_metrics:



|model             |   rmse|    mae|     r2|    low|   high|  p| adj_r2| validation_rmse| test_rank|
|:-----------------|------:|------:|------:|------:|------:|--:|------:|---------------:|---------:|
|B0 training mean  | 49.327| 39.972| -0.438| 42.299| 56.079|  0|     NA|          44.264|        14|
|B1 venue history  | 46.570| 38.178| -0.282| 39.532| 53.743|  0|     NA|          43.034|        12|
|Exclude curtailed | 40.970| 32.189|  0.008| 31.777| 51.746|  4|  0.099|          38.765|         9|
|FA                | 40.828| 32.007|  0.015| 31.426| 51.670|  9|  0.099|          38.757|         4|
|Log total         | 40.883| 32.059|  0.012| 31.566| 51.821|  4|  0.085|          38.786|         5|
|Multiple AIC      | 40.717| 31.870|  0.020| 31.394| 51.565|  6|  0.105|          39.109|         1|
|Multiple BIC      | 40.942| 32.174|  0.009| 31.751| 51.658|  4|  0.100|          38.728|         6|
|Multiple clusters | 40.750| 32.015|  0.019| 31.536| 51.393|  7|  0.105|          39.113|         3|
|Multiple Full     | 41.020| 31.951|  0.006| 31.312| 52.033| 17|  0.103|          38.786|        11|
|Multiple selected | 40.717| 31.870|  0.020| 31.394| 51.565|  6|  0.105|          39.109|         1|
|PCR               | 40.962| 32.065|  0.008| 31.729| 51.543|  9|  0.096|          39.043|         8|
|Robust            | 40.971| 32.217|  0.008| 31.844| 51.644|  4|     NA|          38.706|        10|

interval_summary:



|model | nominal_coverage| empirical_coverage| mean_width| calibration_N| calibration_radius|
|:-----|----------------:|------------------:|----------:|-------------:|------------------:|
|WLS   |              0.8|              0.838|     95.329|            74|              1.455|

Figures f26–f28 show forecasts, frozen comparisons and temporal error. The validation winner is retained even if another candidate performs better on test.

What I learned: Honest evaluation separates model selection from performance reporting.

Open questions: How would performance change with verified weather forecasts and rule-era features?

## Phase 9: Documentation and presentation

course_coverage:



|topic               |script                     |figures      |report_section      |
|:-------------------|:--------------------------|:------------|:-------------------|
|Introduction to R   |02_clean.R / 03_features.R |f01–f05      |Data and Methods    |
|Simple Regression   |05_regression.R            |f06–f07      |Methods and Results |
|Multiple Regression |05_regression.R            |f08–f09      |Methods and Results |
|PCA                 |06_pca_fa.R                |f10–f12, f15 |Methods and Results |
|Factor Analysis     |06_pca_fa.R                |f13–f15      |Methods and Results |
|Cluster Analysis    |07_clustering.R            |f16–f18      |Methods and Results |
|Outlier Detection   |08_outliers_hetero.R       |f19–f21      |Methods and Results |
|Heteroscedasticity  |08_outliers_hetero.R       |f22–f25      |Methods and Results |

speaker_note_lengths:



| slide| detailed_words|
|-----:|--------------:|
|     1|            116|
|     2|            109|
|     3|            106|
|     4|            110|
|     5|            115|
|     6|            114|
|     7|            112|
|     8|            125|
|     9|            121|
|    10|            118|
|    11|            120|
|    12|            117|

The report and slides render from actual saved outputs. The beginner guide connects every method to a question, assumptions and interpretation.

What I learned: Clear explanation is part of the evidence, not decoration after modelling.

Open questions: What would an independent reader need to reproduce and challenge this study?

