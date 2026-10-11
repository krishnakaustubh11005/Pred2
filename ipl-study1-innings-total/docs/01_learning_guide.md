# Learning guide

Read this alongside the report. Every output example below comes from a saved result table.

## Introduction to R

### In one sentence
R turns raw cricket records into a repeatable chain of checked tables and results.

### An everyday analogy
Think of a recipe: raw ingredients become a meal through ordered steps, and changing an ingredient should update every later step.

### The idea step by step (light maths, every symbol defined)
Import with readr, standardise names with reference tables, and use group_by plus summarise to aggregate deliveries. Arrange historical records by date; lag cumulative venue totals so today's outcome is excluded. For target Y, sum each delivery's bat runs and extras. A row is an innings, not a delivery.

### When to use it and when not
Use a pipeline whenever outputs must be reproducible. Do not manually edit generated results to obtain a preferred story.

### What we did in THIS project
See [the analysis script](../scripts/02_clean.R) and [the figure index](../figures/INDEX.md). f01–f05 accompany the report's explanation.

### How to read the output (annotated example from our real output)


|item                          |value  |
|:-----------------------------|:------|
|info files                    |1243   |
|raw deliveries                |295732 |
|super-over deliveries removed |175    |
|first innings                 |1243   |
|no-result first innings       |9      |
|D/L first innings             |23     |
|curtailed first innings       |28     |
|unverified initial XI         |0      |

This table is read directly from results/data_quality.csv. Read each cleaning count as a separate diagnostic, not as quantities that can all be added: a curtailed match may also be a D/L match. Raw deliveries and first innings have different units. The modelling sample is smaller because burn-in is a deliberate history-building step.

### Common mistakes
Mixing delivery rows with innings rows; treating later substitutes as the original XI; letting same-day matches share outcomes.

### Self-check questions
- What is one modelling row? — One first innings.
- Can a later match contribute to today's player mean? — No.
- Why keep raw data separate? — To preserve the source and regenerate derived tables.

## Simple Regression

### In one sentence
Simple regression estimates a straight mean relationship between one input and the score.

### An everyday analogy
Think of a ruler placed through a cloud of observations: it gives an average direction, not an exact route through every point.

### The idea step by step (light maths, every symbol defined)
Use Y = beta0 + beta1 V + epsilon. Y is the score in runs; V is earlier venue average; beta0 is the intercept; beta1 is the slope; epsilon is the unexplained error. Least squares minimises the sum of squared errors. Confidence intervals concern the mean relationship; prediction intervals concern an individual future innings.

### When to use it and when not
Use it for an interpretable starting relationship. Avoid treating a straight line as sufficient when residuals show strong curvature or an omitted time trend.

### What we did in THIS project
See [the analysis script](../scripts/05_regression.R) and [the figure index](../figures/INDEX.md). f06–f07 accompany the report's explanation.

### How to read the output (annotated example from our real output)


|term                | estimate| std.error| statistic| p.value| conf.low| conf.high|
|:-------------------|--------:|---------:|---------:|-------:|--------:|---------:|
|(Intercept)         |  115.209|    17.385|     6.627|   0.000|   81.095|   149.323|
|venue_avg_first_inn |    0.314|     0.108|     2.915|   0.004|    0.103|     0.525|

This table is read directly from results/simple_coefficients.csv. The venue slope is 0.31 runs per extra run of historical venue average. The intercept is the fitted score at a venue average of zero, outside normal observed conditions; do not treat it as a realistic cricket expectation. A small slope p-value can coexist with very little explained score variation.

### Common mistakes
Confusing the fitted mean's confidence band with a prediction interval; extrapolating beyond historical venue averages.

### Self-check questions
- What does the slope describe? — Change in mean predicted score per unit of venue average.
- Does a confidence band contain individual innings? — It targets mean uncertainty, not individual spread.
- Is the venue slope causal? — No; it describes an association.

## Multiple Regression

### In one sentence
Multiple regression estimates each predictor's association while holding other included inputs fixed.

### An everyday analogy
Think of comparing house prices while accounting for size and location; a coefficient depends on what else is included.

### The idea step by step (light maths, every symbol defined)
Use Y = beta0 + sum(beta_j X_j) + epsilon. X_j is input j and beta_j its conditional coefficient; p is the number of design-matrix columns excluding the intercept. VIF_j = 1/(1-R_j squared), where R_j squared measures how well the other inputs explain input j. AIC penalises fitted complexity and BIC penalises it more strongly as the sample grows; rolling assessment evaluates the entire selection procedure on later seasons.

### When to use it and when not
Use it when several known inputs may help. Avoid causal interpretations, an oversized candidate pool or coefficient claims that ignore selection and collinearity.

### What we did in THIS project
See [the analysis script](../scripts/05_regression.R) and [the figure index](../figures/INDEX.md). f08–f09 accompany the report's explanation.

### How to read the output (annotated example from our real output)


|method |   rmse|
|:------|------:|
|AIC    | 31.304|
|Full   | 31.362|
|BIC    | 31.918|

This table is read directly from results/rolling_cv_summary.csv. The rolling table ranks AIC first at RMSE 31.3 runs. These are later-training-season errors, not final test errors. AIC is a selection procedure, and the final candidate is still chosen separately on validation.

### Common mistakes
Counting feature names rather than design-matrix columns; selecting a model after seeing the final test score; treating stepwise p-values as confirmatory.

### Self-check questions
- What counts as a predictor? — Each design-matrix column apart from the intercept.
- Why use rolling assessment? — Future seasons should be predicted from earlier evidence.
- Why can coefficients change after adding inputs? — They now describe different conditional associations.

## PCA

### In one sentence
PCA replaces overlapping measurements with orthogonal directions of input variation.

### An everyday analogy
Think of taking several related fitness measurements and finding a few independent directions that capture their movement together.

### The idea step by step (light maths, every symbol defined)
Standardise each input as S_j = (X_j - training mean_j)/training SD_j. Find loading directions W from the training correlation structure and compute scores Z = S W. An eigenvalue measures variance along an axis. Parallel analysis compares observed eigenvalues with random reference data; only retained axes enter PCR, alongside context.

### When to use it and when not
Use it for correlated numeric inputs. Avoid assuming high explained input variance means high prediction accuracy, or fitting scaling on held-out seasons.

### What we did in THIS project
See [the analysis script](../scripts/06_pca_fa.R) and [the figure index](../figures/INDEX.md). f10–f12, f15 accompany the report's explanation.

### How to read the output (annotated example from our real output)


|block    | component| eigenvalue| parallel_eigenvalue|retained | cumulative_variance|
|:--------|---------:|----------:|-------------------:|:--------|-------------------:|
|Combined |         1|      4.079|               1.161|TRUE     |               0.371|
|Combined |         2|      2.214|               1.117|TRUE     |               0.572|
|Combined |         3|      1.198|               1.081|TRUE     |               0.681|
|Combined |         4|      0.719|               1.051|FALSE    |               0.746|
|Combined |         5|      0.701|               1.026|FALSE    |               0.810|
|Combined |         6|      0.586|               0.999|FALSE    |               0.863|
|Combined |         7|      0.529|               0.972|FALSE    |               0.911|
|Combined |         8|      0.367|               0.943|FALSE    |               0.945|

This table is read directly from results/pca_eigenvalues.csv. In the combined block, 3 retained components capture 68.1 percent of strength variation. A component's eigenvalue measures input variance; the retained flag compares it with random references. This percentage is not the fraction of cricket-score variation explained by the regression.

### Common mistakes
Scaling on all seasons; naming axes without checking loadings; assuming all PCR predictors are uncorrelated when context is also included.

### Self-check questions
- What does PCA optimise? — Input variance captured by linear axes.
- Where are means and SDs learned? — Training seasons only.
- Can PCA hurt forecasts? — Yes, if discarded low-variance directions contain useful signal.

## Factor Analysis

### In one sentence
Factor analysis models common variation through latent factors and leaves feature-specific uniqueness.

### An everyday analogy
Think of several exam questions reflecting a shared skill, while each question also has its own difficulty and noise.

### The idea step by step (light maths, every symbol defined)
Use X = Lambda F + u. X is a vector of standardised measurements, Lambda contains loadings, F contains latent factor scores and u is feature-specific variation. Communality is the fraction represented by common factors; uniqueness is the remainder. KMO checks shared correlation suitability, Bartlett checks departure from an identity correlation matrix, and the identifiable factor count limits how many factors can be estimated.

### When to use it and when not
Use it when a common-factor explanation is plausible. Avoid forcing many factors, ignoring poor KMO, or overlooking near-zero uniqueness and unstable solutions.

### What we did in THIS project
See [the analysis script](../scripts/06_pca_fa.R) and [the figure index](../figures/INDEX.md). f13–f15 accompany the report's explanation.

### How to read the output (annotated example from our real output)


|block    | variables| retained_pcs| retained_factors| pca_variance|   KMO| Bartlett_statistic| Bartlett_df| Bartlett_p| fa_df| fa_RMSEA| min_uniqueness|
|:--------|---------:|------------:|----------------:|------------:|-----:|------------------:|-----------:|----------:|-----:|--------:|--------------:|
|Batting  |         6|            1|                2|        0.603| 0.791|           3994.111|          15|          0|     4|    0.075|          0.005|
|Bowling  |         5|            2|                2|        0.741| 0.571|           1719.828|          10|          0|     1|    0.245|          0.005|
|Combined |        11|            3|                3|        0.681| 0.760|           6086.668|          55|          0|    25|    0.092|          0.005|

This table is read directly from results/dimension_checks.csv. Combined KMO is 0.76, while minimum uniqueness is 0.005. Near-boundary uniqueness warrants caution, and the separate bowling block has weaker suitability. Bartlett probabilities displayed as zero reflect numerical underflow, not an exactly zero probability.

### Common mistakes
Confusing factors with observed player abilities; recomputing scoring weights on validation data; treating a significant Bartlett test as sufficient justification.

### Self-check questions
- What is uniqueness? — Variation not represented by common factors.
- Why oblimin? — Strength factors may be correlated.
- Does Bartlett prove the factor model? — No; it only rejects identity correlation.

## Cluster Analysis

### In one sentence
Cluster analysis groups venues with similar historical profiles.

### An everyday analogy
Think of sorting grounds into groups using their historical scoring climate rather than their names.

### The idea step by step (light maths, every symbol defined)
Create a venue vector containing mean score, score SD, boundary rate and match count, then standardise with training profile means and SDs. K-means minimises squared distances to group centres mu_k; Ward.D2 merges groups while controlling within-group variation. Silhouette compares within-group closeness with separation from other groups. New venue assignments use frozen centres and strictly earlier profiles.

### When to use it and when not
Use it for an exploratory grouping or compact venue categories. Avoid assigning later venues using their current or future innings scores.

### What we did in THIS project
See [the analysis script](../scripts/07_clustering.R) and [the figure index](../figures/INDEX.md). f16–f18 accompany the report's explanation.

### How to read the output (annotated example from our real output)


|  k| adjusted_rand_index| silhouette| gap_recommended|
|--:|-------------------:|----------:|---------------:|
|  2|                   1|      0.395|               1|

This table is read directly from results/cluster_summary.csv. Silhouette chooses 2 groups, but gap recommends 1. The adjusted Rand index compares the two partitions; it is not forecast accuracy. This disagreement means the group labels should be treated as exploratory summaries.

### Common mistakes
Treating names like 'Higher scoring' as permanent properties; forgetting that match count influences distance; using held-out targets to build profiles.

### Self-check questions
- Does clustering use innings scores as prediction labels? — No; it uses training venue profile summaries.
- What happens at a new venue? — Assign an earlier-history profile to a frozen centre, or use the training overall profile.
- Is agreement a prediction metric? — No; it compares partitions.

## Outlier Detection

### In one sentence
Influence diagnostics identify unusual errors, inputs and observations that move a fitted model.

### An everyday analogy
Think of checking whether one unusual exam score changes the class average: unusualness and influence are different questions.

### The idea step by step (light maths, every symbol defined)
A studentized residual rescales the error by its estimated uncertainty. Leverage measures how unusual the predictors are, while Cook's distance measures the fit's sensitivity to removing a case. DFFITS describes prediction sensitivity and DFBETAS coefficient sensitivity; Mahalanobis distance describes joint predictor unusualness. Inspect cases, retain valid extremes, and compare explicit sensitivity fits on identical validation outcomes.

### When to use it and when not
Use diagnostics before trusting coefficient interpretations. Avoid deleting cases solely because a cutoff was crossed.

### What we did in THIS project
See [the analysis script](../scripts/08_outliers_hetero.R) and [the figure index](../figures/INDEX.md). f19–f21 accompany the report's explanation.

### How to read the output (annotated example from our real output)


|    N| predictors| studentized_cutoff| leverage_cutoff| cooks_cutoff| dffits_cutoff| dfbetas_cutoff| mahalanobis_cutoff|
|----:|----------:|------------------:|---------------:|------------:|-------------:|--------------:|------------------:|
| 1037|          4|                  3|            0.01|        0.004|         0.139|          0.062|             13.277|

This table is read directly from results/influence_thresholds.csv. The Cook's reference is 0.00386. Crossing it asks us to inspect coefficient sensitivity; it does not prove an innings is invalid. The predictor count in these cutoffs comes from the selected diagnostic model, not the original full pool.

### Common mistakes
Calling every large residual an input outlier; silently removing shortened innings from the assessment target; claiming unverified match narratives.

### Self-check questions
- Can a valid innings be influential? — Yes.
- Does leverage imply a large error? — No; it concerns unusual inputs.
- Why assess all treatments on the same validation rows? — To make accuracy comparisons fair.

## Heteroscedasticity

### In one sentence
Heteroscedasticity means prediction errors have different variances in different contexts.

### An everyday analogy
Think of travel times: the average journey can be predicted fairly well while uncertainty grows during rush hour.

### The idea step by step (light maths, every symbol defined)
Write Var(epsilon_i given X_i) = sigma_i squared: sigma_i is the conditional error SD for case i. WLS uses weight w_i = 1/estimated variance_i so noisier contexts contribute less to fitting. HC3 adjusts coefficient uncertainty without changing fitted values. A log target changes the forecast scale; exponentiating predictions needs training-based bias correction.

### When to use it and when not
Use variance diagnostics when uncertainty or inference matters. Avoid claiming a variance remedy worked just because one test became non-significant.

### What we did in THIS project
See [the analysis script](../scripts/08_outliers_hetero.R) and [the figure index](../figures/INDEX.md). f22–f25 accompany the report's explanation.

### How to read the output (annotated example from our real output)


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

This table is read directly from results/heteroscedasticity_tests.csv. Compare raw and remedied test rows on their stated residual scale. Log and weighted residuals can be less variable even though their numerical units differ from raw runs. A larger p-value after treatment means weaker evidence against the assumption; it does not guarantee constant variance or better forecasts.

### Common mistakes
Thinking HC3 improves point forecasts; using negative inverse-variance weights; comparing weighted and raw residual sizes as if their units were identical.

### Self-check questions
- Does HC3 change predictions? — No.
- Why floor fitted variances? — Weights must be finite and positive.
- Is later-season interval coverage guaranteed? — No; drift and validation reuse weaken that claim.

## How the techniques connect

Start with delivery records and reliable player identities. Build only earlier-date histories, then use exploration to understand score variation and overlapping predictors. Regression creates interpretable forecasts; PCA and FA test whether compact strength summaries help, and clustering supplies venue context. Influence and variance diagnostics reveal where assumptions strain. Validation freezes a choice before the final season is assessed, and the report explains both its usefulness and its limits.
