# Project walkthrough

Run `Rscript run_all.R` from the project directory.

Setup checks dependencies and rendering (D-001–D-003). The CSV supplies deliveries; JSON reconstructs initial XIs (D-004). Reference names and regular innings define the cleaned history (D-005).



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

Historical features use earlier dates and cold-start shrinkage; completed-season finals define the split (D-006–D-007).



|split      |    N| first_season| last_season|
|:----------|----:|------------:|-----------:|
|test       |   74|         2026|        2026|
|train      | 1037|         2009|        2024|
|validation |   74|         2025|        2025|



|check                                          | rows|pass |
|:----------------------------------------------|----:|:----|
|strict earlier-date brute-force reconstruction |   20|TRUE |

Training-only exploration motivates venue and season context (D-008). Rolling-origin assessment compares raw selection procedures before interaction and polynomial candidates enter validation (D-009).



|method |   rmse|
|:------|------:|
|AIC    | 31.304|
|Full   | 31.362|
|BIC    | 31.918|

Training PCA and ML factor models analyse batting, bowling and combined blocks (D-010). Frozen venue profiles produce compact categories (D-011).



|block    | variables| retained_pcs| retained_factors| pca_variance|   KMO| Bartlett_statistic| Bartlett_df| Bartlett_p| fa_df| fa_RMSEA| min_uniqueness|
|:--------|---------:|------------:|----------------:|------------:|-----:|------------------:|-----------:|----------:|-----:|--------:|--------------:|
|Batting  |         6|            1|                2|        0.603| 0.791|           3994.111|          15|          0|     4|    0.075|          0.005|
|Bowling  |         5|            2|                2|        0.741| 0.571|           1719.828|          10|          0|     1|    0.245|          0.005|
|Combined |        11|            3|                3|        0.681| 0.760|           6086.668|          55|          0|    25|    0.092|          0.005|



|  k| adjusted_rand_index| silhouette| gap_recommended|
|--:|-------------------:|----------:|---------------:|
|  2|                   1|      0.395|               1|

Influence flags trigger sensitivity comparisons, and variance remedies are assessed rather than assumed effective (D-012–D-013).



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

Validation freezes the final choice before test outcomes are scored (D-014).



|model | validation_rmse|refit_policy                                           |
|:-----|---------------:|:------------------------------------------------------|
|WLS   |          38.671|training fit retained; validation calibrates intervals |



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
|Simple            | 47.551| 38.815| -0.336| 40.449| 54.630|  1|  0.007|          43.077|        13|
|WLS               | 40.959| 32.231|  0.009| 31.876| 51.548|  4|  0.100|          38.671|         7|



|model | nominal_coverage| empirical_coverage| mean_width| calibration_N| calibration_radius|
|:-----|----------------:|------------------:|----------:|-------------:|------------------:|
|WLS   |              0.8|              0.838|     95.329|            74|              1.455|

Read the learning guide first, the HTML report next, and the talk track when preparing to present.
