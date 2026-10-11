# Learning guide

The statistical examples follow the supplied course files. Basic time splitting and prediction metrics remain agreed project checks.

## Introduction to R

### In one sentence

R converts raw cricket records into reproducible tables and outputs.

### An everyday analogy

A recipe turns raw ingredients into a repeatable meal.

### The idea step by step (light maths, every symbol defined)

1. Use read.csv(), head(), tail(), names(), dim(), summary(), mean(), sd(), cov() and cor() to inspect a table, as in the Intro-to-R script. The existing raw-data preparation uses the tested import and aggregation pipeline; this refactor does not rewrite it.
2. Each delivery supplies bat runs and extras. Sum them within the first innings to obtain the target. Dates determine which earlier matches can supply history. The final table has one row per first innings and a separate target column.
3. The season split assigns earlier innings to fitting and later innings to assessment. Match outcomes can update historical inputs only for strictly later dates; they cannot change a feature for their own match.

### When to use it and when not

Use a pipeline when data corrections must update all results. Do not edit generated CSVs by hand.

### What we did in THIS project (link scripts and figures)

Follow [02_clean.R / 03_features.R](../scripts/02_clean.R) and f01–f05 in the [figure index](../figures/INDEX.md).

### How to read the output (annotated example from our real output)



|    N|    mean| median|     sd| minimum| maximum|
|----:|-------:|------:|------:|-------:|-------:|
| 1037| 165.803|    165| 31.967|      56|     287|

The descriptive table shows the centre and spread of actual training totals. Shortened innings remain included.

### Common mistakes

Mixing future outcomes into history; confusing delivery rows with innings rows; editing generated outputs.

### Self-check questions (3, with short answers)

- What is one row? — One first innings.
- May this match supply its own history? — No.
- What does the target include? — Bat runs and extras.

## Simple Regression

### In one sentence

Simple regression fits an average straight-line relationship using one input.

### An everyday analogy

A ruler through a cloud of points shows an average direction.

### The idea step by step (light maths, every symbol defined)

1. The model is $Y_i=\beta_0+\beta_1V_i+\epsilon_i$. $Y_i$ is total runs, $V_i$ is earlier venue mean, $\beta_0$ is the intercept, $\beta_1$ is slope and $\epsilon_i$ is an unobserved error.
2. Least squares minimises $\sum_i(Y_i-\beta_0-\beta_1V_i)^2$. For one input, the fitted slope is $\widehat\beta_1=\sum_i(V_i-\bar V)(Y_i-\bar Y)/\sum_i(V_i-\bar V)^2$, and the intercept is $\widehat\beta_0=\bar Y-\widehat\beta_1\bar V$.
3. Run lm(), inspect summary() and confint(), then predict() for new input values. Residuals are actual minus fitted scores. A confidence interval concerns an average relationship; a prediction interval concerns an individual innings.

### When to use it and when not

Use a single-input model as an interpretable starting point. Check residual patterns before relying on its line.

### What we did in THIS project (link scripts and figures)

Follow [05_regression.R](../scripts/05_regression.R) and f06–f07 in the [figure index](../figures/INDEX.md).

### How to read the output (annotated example from our real output)



|term                | estimate| std.error| statistic| p.value| conf.low| conf.high|
|:-------------------|--------:|---------:|---------:|-------:|--------:|---------:|
|(Intercept)         |  115.209|    17.385|     6.627|   0.000|   81.095|   149.323|
|venue_avg_first_inn |    0.314|     0.108|     2.915|   0.004|    0.103|     0.525|

The intercept and slope are in runs. Confidence limits describe uncertainty about the estimated coefficients, not the spread of an individual innings.

### Common mistakes

Treating the fitted line as an exact score; interpreting the intercept outside observed input ranges; confusing mean and prediction intervals.

### Self-check questions (3, with short answers)

- What does the slope describe? — Change in predicted average per input unit.
- What is a residual? — Actual minus fitted value.
- Which interval concerns one match? — A prediction interval.

## Multiple Regression

### In one sentence

Multiple regression fits conditional associations using several inputs.

### An everyday analogy

Comparing house prices while accounting for size and location changes what each effect means.

### The idea step by step (light maths, every symbol defined)

1. Write $Y=X\beta+\epsilon$. $Y$ contains training totals, $X$ contains an intercept column and predictor columns, $\beta$ contains coefficients and $\epsilon$ contains errors. With full column rank, least squares gives $\widehat\beta=(X^\mathsf{T}X)^{-1}X^\mathsf{T}Y$. R's lm() performs the fit without requiring us to invert the matrix manually.
2. A coefficient describes score change while other included predictors stay fixed. Correlated features contain overlapping information, so adding a feature can change the other coefficients. We compare the simple and full venue coefficient and show the batting strike-rate/boundary relationship.
3. The Store24 example uses backward step() and stepAIC(). AIC balances fitted likelihood with the number of parameters. Starting from the full model, backward selection removes terms when AIC improves. The two taught functions are checked for agreement.
4. The Boston example adds interactions and squared terms, then uses anova() for nested comparisons. Our extensions start from the full model to retain main effects. Added terms with the saved training significance criterion become validation candidates.

### When to use it and when not

Use several pre-innings inputs when they may add information. Avoid causal claims and excessive candidate pools.

### What we did in THIS project (link scripts and figures)

Follow [05_regression.R](../scripts/05_regression.R) and f08–f09 in the [figure index](../figures/INDEX.md).

### How to read the output (annotated example from our real output)



|term                | estimate| std.error| statistic| p.value|model  |
|:-------------------|--------:|---------:|---------:|-------:|:------|
|venue_avg_first_inn |    0.314|     0.108|     2.915|   0.004|Simple |
|venue_avg_first_inn |   -0.539|     0.204|    -2.642|   0.008|Full   |

The same venue input has different coefficients in the simple and full models because the full coefficient holds other included inputs fixed.

### Common mistakes

Treating coefficients as causal; omitting main effects from interaction comparisons; claiming post-selection significance is confirmatory.

### Self-check questions (3, with short answers)

- What is held fixed by a coefficient? — Other included inputs.
- What does backward selection do? — Removes terms when AIC improves.
- Why keep main effects? — To make added-term comparisons properly nested and interpretable.

## PCA

### In one sentence

PCA replaces correlated measurements with component scores describing input variation.

### An everyday analogy

Several related fitness measurements can be summarised along a few directions.

### The idea step by step (light maths, every symbol defined)

1. First examine correlation: $r_{ab}=\mathrm{cov}(X_a,X_b)/(s_as_b)$. Covariance uses paired deviations from each variable's mean, while correlation divides by both standard deviations. Correlation describes linear co-movement, not causation.
2. Standardise strength feature $j$ as $z_{ij}=(x_{ij}-\mu_j)/s_j$, using training mean $\mu_j$ and SD $s_j$. This prevents units such as runs and percentages from determining the axes just because their numerical spreads differ.
3. Form the training correlation matrix $R=Z^\mathsf{T}Z/(N-1)$. Its eigenvectors $v_k$ satisfy $Rv_k=\lambda_kv_k$; $\lambda_k$ is the variance along direction $k$. The raw score $Zv_k$ has that variance, and explained share is $\lambda_k/\sum_\ell\lambda_\ell$.
4. The class principal() function returns unit-variance scores. Its component loading is $L_{jk}=v_{jk}\sqrt{\lambda_k}$, while the score weight is $W_{jk}=v_{jk}/\sqrt{\lambda_k}$. Compute $PC_{ik}=\sum_jz_{ij}W_{jk}$. We verify the equivalent prcomp scores after adjusting sign and scale.
5. Parallel analysis compares actual eigenvalues with random-data references. Retained scores become ordinary inputs to lm(): $\widehat Y_i=\widehat\beta_0+\sum_c\widehat\beta_c C_{ic}+\sum_k\widehat\gamma_k PC_{ik}$. $C$ contains context inputs and $\gamma$ contains the fitted component effects. PCA does not use the target to learn its axes.

### When to use it and when not

Use PCA for correlated numeric measurements. Avoid assuming explained input variance guarantees predictive accuracy.

### What we did in THIS project (link scripts and figures)

Follow [06_pca_fa.R](../scripts/06_pca_fa.R) and f10–f12, f15 in the [figure index](../figures/INDEX.md).

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
|Combined |         9|      0.313|               0.916|FALSE    |               0.973|
|Combined |        10|      0.233|               0.885|FALSE    |               0.995|
|Combined |        11|      0.060|               0.849|FALSE    |               1.000|

Read eigenvalues and cumulative input variance alongside the retained flag. These numbers are about inputs, not runs-prediction accuracy.

### Common mistakes

Using loadings directly as score weights; fitting scaling on later data; confusing variance explained with prediction accuracy.

### Self-check questions (3, with short answers)

- Does PCA use the outcome to find axes? — No.
- Are loadings and weights identical? — No; their eigenvalue scaling differs.
- How are scores used? — As numeric inputs to regression.

## Factor Analysis

### In one sentence

Factor analysis models shared variation and feature-specific uniqueness.

### An everyday analogy

Exam questions may share a skill while retaining question-specific variation.

### The idea step by step (light maths, every symbol defined)

1. The model is $z_i=L f_i+u_i$: $z_i$ contains standardised strength measurements, $L$ contains loadings, $f_i$ represents unobserved common factors, and $u_i$ represents feature-specific variation.
2. For orthogonal factors, $\mathrm{Cov}(z_i)\approx LL^\mathsf{T}+\Psi$. $\Psi$ is diagonal uniqueness. Feature $j$ has communality $h_j^2=\sum_kL_{jk}^2$ and uniqueness approximately $1-h_j^2$. A negative uniqueness is an improper variance decomposition.
3. FA.R uses principal-axis extraction: fa(..., fm='pa'). This estimates common variation rather than allocating all variance to components. Compare rotate='none' with rotate='varimax'; varimax seeks simpler loading patterns while preserving the orthogonal model's common covariance.
4. Factors are unobserved. Estimated scores use the training regression-score weights returned by fa(): $\widehat F=ZW_F$. Multiply each standardised input by its weight and sum. Loading values are not interchangeable with score weights.
5. Use those estimated scores in another lm(): $\widehat Y_i=\widehat\alpha_0+\sum_c\widehat\alpha_c C_{ic}+\sum_k\widehat\delta_k\widehat F_{ik}$. Estimated factor scores need not be perfectly uncorrelated. The separate batting/bowling solutions are improper, so only the proper combined solution supplies forecasts.

### When to use it and when not

Use FA when a common-factor interpretation is plausible. Do not interpret an improper solution as a valid variance model.

### What we did in THIS project (link scripts and figures)

Follow [06_pca_fa.R](../scripts/06_pca_fa.R) and f13–f15 in the [figure index](../figures/INDEX.md).

### How to read the output (annotated example from our real output)



|block    | variables| retained_factors| min_uniqueness| max_communality|boundary_warning |
|:--------|---------:|----------------:|--------------:|---------------:|:----------------|
|Batting  |         6|                2|         -0.041|           1.041|TRUE             |
|Bowling  |         5|                2|         -0.341|           1.341|TRUE             |
|Combined |        11|                3|          0.010|           0.990|FALSE            |

Negative uniqueness in the separate batting/bowling blocks means improper solutions. The combined model's saved minimum uniqueness is positive; its scores feed the FA regression.

### Common mistakes

Treating negative uniqueness as meaningful; substituting loadings for score weights; treating estimated scores as directly observed abilities.

### Self-check questions (3, with short answers)

- What is uniqueness? — Feature-specific variance not explained by common factors.
- What does negative uniqueness indicate? — An improper factor solution.
- How are held-out scores calculated? — With training means, SDs and saved score weights.

## Cluster Analysis

### In one sentence

Clustering groups venues that have similar historical profiles.

### An everyday analogy

Sort grounds by their scoring climate instead of alphabetically by name.

### The idea step by step (light maths, every symbol defined)

1. Each venue is an observation with training mean total, SD, boundary rate and match count. Standardise these profile columns using training profile means and SDs. Euclidean distance is $d(i,j)=\sqrt{\sum_m(z_{im}-z_{jm})^2}$, with $m$ indexing profile measurements.
2. Hierarchical clustering starts with separate observations and repeatedly merges clusters. Single linkage uses the nearest pair, complete linkage the farthest pair and average linkage the average pairwise distance. hclust() creates the tree; cutree() supplies memberships for a chosen k.
3. K-means alternates assignment to the closest centre and centre updates. It minimises $\sum_k\sum_{i\in C_k}\lVert z_i-\mu_k\rVert^2$. Several starts reduce dependence on a poor initial choice. The elbow displays within-group variation as k changes; silhouette compares closeness within a group with separation from alternatives.
4. Choose k by the recorded maximum-silhouette rule and compare hierarchical/k-means membership tables. Group labels are arbitrary: cluster 1 from two algorithms need not describe the same observations. A categorical venue group adds dummy predictor columns to regression. New venues use earlier history and frozen centres.

### When to use it and when not

Use clustering for exploratory grouping. Do not treat labels as known natural ground types or prediction scores.

### What we did in THIS project (link scripts and figures)

Follow [07_clustering.R](../scripts/07_clustering.R) and f16–f18 in the [figure index](../figures/INDEX.md).

### How to read the output (annotated example from our real output)



|  k| silhouette|main_linkage | random_starts|
|--:|----------:|:------------|-------------:|
|  2|      0.395|average      |            25|

Read k and silhouette as grouping choices. Use the membership table to compare methods without requiring identical group numbers.

### Common mistakes

Clustering unscaled mixed units; treating arbitrary numeric labels as ordered; fitting centres using test outcomes.

### Self-check questions (3, with short answers)

- What does standardisation prevent? — Numerical units dominating distance.
- Do matching label numbers prove agreement? — No.
- How is a new venue assigned? — To a frozen nearest centre using earlier history.

## Outlier Detection

### In one sentence

Outlier diagnostics distinguish unusual errors, unusual inputs and influential observations.

### An everyday analogy

A surprising exam score may or may not change the fitted relationship substantially.

### The idea step by step (light maths, every symbol defined)

1. For innings i, residual $e_i=Y_i-\widehat Y_i$ describes score error. rstandard() rescales residuals using fitted residual spread and leverage; rstudent() uses a case-deleted estimate of spread. hatvalues() returns leverage, which describes unusual input combinations.
2. Cook's distance summarises how fitted values change if a case is omitted. DFFITS describes a fitted-value change; DFBETAS describes standardized changes in individual coefficients. These are related diagnostics with different questions.
3. The clustering notes also cover Mahalanobis distance: $D_i^2=(x_i-\bar x)^\mathsf{T}S^{-1}(x_i-\bar x)$. $S$ is predictor covariance. A covariance-aware inverse is restricted to nonzero-variance directions so redundant columns do not produce an invalid inverse.
4. The saved thresholds mark cases for inspection. They do not establish a data error. Keep valid extremes in the dataset and compare explicitly labelled training case-removal fits; do not remove challenging validation or test innings.

### When to use it and when not

Use diagnostics to investigate sensitivity. Avoid deleting all flagged observations as if flags proved errors.

### What we did in THIS project (link scripts and figures)

Follow [08_outliers_hetero.R](../scripts/08_outliers_hetero.R) and f19–f21 in the [figure index](../figures/INDEX.md).

### How to read the output (annotated example from our real output)



|    N| predictors| studentized_cutoff| leverage_cutoff| cooks_cutoff| dffits_cutoff| dfbetas_cutoff| mahalanobis_cutoff|
|----:|----------:|------------------:|---------------:|------------:|-------------:|--------------:|------------------:|
| 1037|         17|                  3|           0.035|        0.004|         0.263|          0.062|             33.409|

Read thresholds as inspection references and count all dummy columns in p. Unusual errors, leverage and influence are different signals.

### Common mistakes

Confusing a large residual with influence; silently deleting valid extremes; removing assessment cases after seeing their scores.

### Self-check questions (3, with short answers)

- What is leverage? — Unusualness of the predictor combination.
- Does a flag prove an error? — No.
- What stays common across sensitivity evaluations? — The validation/test innings.

## Heteroscedasticity

### In one sentence

Heteroscedasticity means model-error variance differs across contexts.

### An everyday analogy

Journey times can have similar averages but different uncertainty in different traffic conditions.

### The idea step by step (light maths, every symbol defined)

1. Write $\mathrm{Var}(\epsilon_i\mid X_i)=\sigma_i^2$. A changing vertical spread in residual plots suggests unequal variance. Goldfeld–Quandt compares residual mean squares from earlier/later season segments: $GQ=(RSS_2/df_2)/(RSS_1/df_1)$, where RSS is residual sum of squares and df is residual degrees of freedom.
2. The class script compares a raw response with log(y). Exponentiating a fitted log value gives a conditional median under the usual log-error interpretation; it does not directly produce a conditional arithmetic mean.
3. The market-share example uses tapply(residuals(model), group, var). We do the same with training venue groups. Give a case weight $w_i=1/\widehat\sigma^2_{g(i)}$; a noisier group contributes less to weighted fitting. Invalid or undersized groups use pooled training residual variance.
4. Fit lm(..., weights=wts), inspect summary() and standardized residuals. The weighted least-squares expression is $\widehat\beta=(X^\mathsf{T}WX)^{-1}X^\mathsf{T}WY$, where W is diagonal weights. New-innings prediction intervals require the corresponding frozen group weight. Do not use a diagnostic that silently ignores weights.

### When to use it and when not

Use log or weighted fits when residual patterns motivate them. Diagnose and compare accuracy separately.

### What we did in THIS project (link scripts and figures)

Follow [08_outliers_hetero.R](../scripts/08_outliers_hetero.R) and f22–f25 in the [figure index](../figures/INDEX.md).

### How to read the output (annotated example from our real output)



|model     |test            | statistic| p_value|
|:---------|:---------------|---------:|-------:|
|Raw       |Goldfeld–Quandt |     1.203|   0.020|
|Log total |Goldfeld–Quandt |     1.053|   0.282|

The Goldfeld–Quandt p-value concerns increased variance between season segments. The WLS group-variance table concerns differences across venue groups.

### Common mistakes

Exponentiating a log prediction and calling it a mean; using invalid weights; assuming a better-looking plot guarantees better predictions.

### Self-check questions (3, with short answers)

- Why inverse-variance weights? — Noisier groups get less fitting weight.
- What does exp(log prediction) represent? — A conditional median under the model interpretation.
- Does nominal interval coverage guarantee actual coverage? — No.

## How the techniques connect

Raw deliveries become innings totals and strictly earlier historical inputs. Exploration examines scoring distributions, season changes, venues and correlations. Simple regression gives a readable baseline relationship; multiple regression combines context and team strength. PCA and FA construct alternative numerical inputs, and clustering constructs a venue-group input. Influence and variance diagnostics lead to labelled alternative fits. Validation chooses a fitted regression before the revised test comparison.

### A real match: standardisation and score construction

The saved example is validation match 1473438. All transformation parameters were learned from training seasons.



|variable           |   input| training_mean| training_sd| standardized| PC1_weight| PC1_contribution| FA1_weight| FA1_contribution|
|:------------------|-------:|-------------:|-----------:|------------:|----------:|----------------:|----------:|----------------:|
|bat_average        |  24.457|        23.121|       2.623|        0.509|      0.134|            0.068|     -0.021|           -0.011|
|bat_strike_rate    | 135.559|       122.490|       7.640|        1.710|      0.219|            0.375|      1.266|            2.166|
|bat_boundary_pct   |  18.567|        15.214|       1.520|        2.206|      0.201|            0.444|     -0.280|           -0.618|
|bat_top_order_sr   | 137.630|       130.936|      10.291|        0.650|      0.151|            0.099|      0.038|            0.025|
|bat_depth          |   7.000|         5.667|       2.124|        0.628|      0.205|            0.129|      0.050|            0.032|
|team_last10_total  | 203.300|       164.284|      12.867|        3.032|      0.172|            0.522|      0.019|            0.057|
|bowl_economy       |   8.598|         8.023|       0.361|        1.594|      0.146|            0.232|     -0.215|           -0.343|
|bowl_strike_rate   |  25.877|        22.945|       2.556|        1.147|     -0.027|           -0.031|      0.027|            0.032|
|bowl_dot_pct       |  33.276|        35.353|       1.797|       -1.156|     -0.104|            0.120|      0.020|           -0.024|
|bowl_wickets_match |   0.802|         0.854|       0.090|       -0.579|      0.014|           -0.008|     -0.049|            0.029|
|bowl_death_economy |  10.315|         9.505|       0.410|        1.976|      0.106|            0.209|      0.018|            0.036|

For PC1, multiply each standardized value by its PC1 weight, then add the contribution column. For FA1, use the FA1 weights instead. These are different transformations of the same historical inputs.



|method | match_id| actual| first_score| predicted|
|:------|--------:|------:|-----------:|---------:|
|PCR    |  1473438|    174|       2.158|   191.746|
|FA     |  1473438|    174|       1.381|   190.723|

### From scores to predicted runs

The following table shows the regression arithmetic: input value times fitted coefficient gives that term's contribution in runs. Add the intercept contribution and all remaining contributions within each method. The result equals the saved prediction above. The actual total is shown only for comparison; it never determines the scores for this match.



|method |term                      | input_value| coefficient| contribution_runs|
|:------|:-------------------------|-----------:|-----------:|-----------------:|
|PCR    |(Intercept)               |       1.000|     174.707|           174.707|
|PCR    |venue_avg_first_inn       |     166.280|      -0.471|           -78.278|
|PCR    |venue_sd_first_inn        |      32.772|       0.002|             0.060|
|PCR    |venue_prior_matches       |      93.000|       0.048|             4.477|
|PCR    |venue_boundary_rate       |       0.175|     335.121|            58.556|
|PCR    |season_index              |      18.000|       1.342|            24.154|
|PCR    |toss_winner_batting_first |       0.000|      -2.747|             0.000|
|PCR    |PCA1                      |       2.158|       3.754|             8.100|
|PCR    |PCA2                      |      -1.206|       0.192|            -0.231|
|PCR    |PCA3                      |       0.155|       1.290|             0.200|
|FA     |(Intercept)               |       1.000|     178.353|           178.353|
|FA     |venue_avg_first_inn       |     166.280|      -0.477|           -79.312|
|FA     |venue_sd_first_inn        |      32.772|       0.019|             0.633|
|FA     |venue_prior_matches       |      93.000|       0.052|             4.800|
|FA     |venue_boundary_rate       |       0.175|     330.046|            57.670|
|FA     |season_index              |      18.000|       1.088|            19.584|
|FA     |toss_winner_batting_first |       0.000|      -2.867|             0.000|
|FA     |FA1                       |       1.381|       4.442|             6.137|
|FA     |FA2                       |       1.366|       2.129|             2.908|
|FA     |FA3                       |      -0.717|       0.070|            -0.050|

### What the final evaluation teaches



|model               |   rmse|    mae|    r2|  p| adj_r2| validation_rmse| test_rank|
|:-------------------|------:|------:|-----:|--:|------:|---------------:|---------:|
|Exclude influential | 41.007| 32.084| 0.006| 17|  0.118|          38.577|         6|



|model               | nominal_coverage| empirical_coverage| mean_width|method                                   |
|:-------------------|----------------:|------------------:|----------:|:----------------------------------------|
|Exclude influential |              0.8|              0.581|     68.036|classical regression prediction interval |

Validation selected Exclude influential. Its nominal intervals cover 58.1% of test scores, substantially below the nominal 80%. A point forecast can beat old historical baselines while its model-based uncertainty is too narrow. The test season was already examined in the earlier implementation; this revision is not newly untouched evidence.
