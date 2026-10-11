# Walkthrough

## Data and features



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



|split      |    N| first_season| last_season|
|:----------|----:|------------:|-----------:|
|test       |   74|         2026|        2026|
|train      | 1037|         2009|        2024|
|validation |   74|         2025|        2025|

The raw-data and historical-feature pipeline remains unchanged. D-018 records the student's analysis-only refactor and retention of basic evaluation.

## Explore, then fit

Descriptive summaries, covariance and correlation precede regression. D-019 adapts Store24 and Boston with visible fits, backward AIC and nested comparisons.



|    N|    mean| median|     sd| minimum| maximum|
|----:|-------:|------:|------:|-------:|-------:|
| 1037| 165.803|    165| 31.967|      56|     287|



|model               |  p| adj_r2|   rmse|    mae|     r2|
|:-------------------|--:|------:|------:|------:|------:|
|B0 training mean    |  0|     NA| 44.264| 36.366| -0.371|
|B1 venue history    |  0|     NA| 43.034| 35.255| -0.296|
|Simple              |  1|  0.007| 43.077| 35.332| -0.299|
|Multiple full       | 17|  0.103| 38.786| 30.897| -0.053|
|Multiple AIC        |  6|  0.105| 39.109| 30.915| -0.071|
|PCR                 |  9|  0.096| 39.043| 30.796| -0.067|
|FA                  |  9|  0.099| 38.753| 30.829| -0.051|
|Multiple clusters   |  7|  0.105| 39.113| 30.964| -0.071|
|Exclude curtailed   | 17|  0.102| 38.903| 30.877| -0.059|
|Exclude influential | 17|  0.118| 38.577| 30.713| -0.042|
|Log total           | 17|  0.089| 39.100| 31.343| -0.070|
|WLS                 | 17|  0.107| 38.782| 30.900| -0.053|

## Compress variables and group venues

D-020 follows principal scores and principal-axis FA; D-021 follows classroom linkage and k-means. Only the proper combined factor solution supplies prediction inputs.



|block    | retained_pcs| retained_factors| pca_variance| min_uniqueness|boundary_warning |
|:--------|------------:|----------------:|------------:|--------------:|:----------------|
|Batting  |            1|                2|        0.603|         -0.041|TRUE             |
|Bowling  |            2|                2|        0.741|         -0.341|TRUE             |
|Combined |            3|                3|        0.681|          0.010|FALSE            |



|  k| silhouette|main_linkage | random_starts|
|--:|----------:|:------------|-------------:|
|  2|      0.395|average      |            25|

## Investigate influence and variance

D-022 retains labelled case-removal comparisons; D-023 uses log response and inverse-group-variance WLS. Assessment innings remain common to every model.



|model     |test            | statistic| p_value|
|:---------|:---------------|---------:|-------:|
|Raw       |Goldfeld–Quandt |     1.203|   0.020|
|Log total |Goldfeld–Quandt |     1.053|   0.282|



|venue_cluster  |   N| variance| predicted_sd|used_pooled_fallback |
|:--------------|---:|--------:|------------:|:--------------------|
|Lower scoring  |  78|  570.796|       23.891|FALSE                |
|Higher scoring | 959|  928.331|       30.469|FALSE                |

## Freeze and evaluate

D-024 selects among fitted regressions using validation. Classical prediction intervals follow the Boston pattern. All revised test rankings are reported without altering the chosen model.



|model               | validation_rmse| training_N| predictors|refit_policy                                        |test_status                                                           |
|:-------------------|---------------:|----------:|----------:|:---------------------------------------------------|:---------------------------------------------------------------------|
|Exclude influential |          38.577|        983|         17|retain training fit; classical prediction intervals |previously assessed season; no test-guided selection in this revision |



|model               |   rmse|    mae|     r2|  p| adj_r2| validation_rmse| test_rank|
|:-------------------|------:|------:|------:|--:|------:|---------------:|---------:|
|B0 training mean    | 49.327| 39.972| -0.438|  0|     NA|          44.264|        12|
|B1 venue history    | 46.570| 38.178| -0.282|  0|     NA|          43.034|        10|
|Exclude curtailed   | 40.911| 31.868|  0.011| 17|  0.102|          38.903|         3|
|Exclude influential | 41.007| 32.084|  0.006| 17|  0.118|          38.577|         6|
|FA                  | 40.934| 32.094|  0.010|  9|  0.099|          38.753|         4|
|Log total           | 41.291| 32.391| -0.008| 17|  0.089|          39.100|         9|
|Multiple AIC        | 40.717| 31.870|  0.020|  6|  0.105|          39.109|         1|
|Multiple clusters   | 40.750| 32.015|  0.019|  7|  0.105|          39.113|         2|
|Multiple full       | 41.020| 31.951|  0.006| 17|  0.103|          38.786|         7|
|PCR                 | 40.962| 32.065|  0.008|  9|  0.096|          39.043|         5|
|Simple              | 47.551| 38.815| -0.336|  1|  0.007|          43.077|        11|
|WLS                 | 41.038| 31.929|  0.005| 17|  0.107|          38.782|         8|



|model               | nominal_coverage| empirical_coverage| mean_width|method                                   |
|:-------------------|----------------:|------------------:|----------:|:----------------------------------------|
|Exclude influential |              0.8|              0.581|     68.036|classical regression prediction interval |

The test season has been evaluated before; it is not a newly untouched experiment. The selected model's interval under-coverage is a material limitation.
