# Presentation talk track

## Short delivery script



| slide| seconds| cumulative_seconds|
|-----:|-------:|------------------:|
|     1|      30|                 30|
|     2|      35|                 65|
|     3|      45|                110|
|     4|      35|                145|
|     5|      50|                195|
|     6|      55|                250|
|     7|      45|                295|
|     8|      45|                340|
|     9|      55|                395|
|    10|      40|                435|
|    11|      50|                485|
|    12|      65|                550|
|    13|      50|                600|

### Slide 1: 1. Objective: a forecast before the first ball

Predict actual first-innings totals after the toss and initial XI announcement, before any delivery.

### Slide 2: 1. Objective: what the study asks

Ask whether context and player histories beat simple benchmarks, whether compression helps, and how diagnostics change interpretation.

### Slide 3: 2. Data: earlier seasons teach, later seasons assess

Read the chronological split: test 74 innings; train 1037 innings; validation 74 innings

### Slide 4: 2. Data: scores have substantial variation

Shortened innings remain part of the actual-total task. Outcomes and realised length are excluded from their own inputs.

### Slide 5: 3. Methods: build history, then fit regression

Inspect data, covariance and correlation, fit simple and multiple regression, then compare backward AIC and nested added terms as in class.

### Slide 6: 3. Methods: simplify related measurements

PCA retains 3 components and proper combined FA retains 3 factors. Saved training weights turn inputs into scores for regression.

### Slide 7: 3. Methods: diagnose and evaluate honestly

Influence prompts labelled sensitivity fits. Goldfeld–Quandt, log response and inverse-group-variance WLS examine unequal variance. Validation chooses a regression.

### Slide 8: 4. Results: venue is an imperfect scoring anchor

Read the venue slope as an average association. The confidence band describes the fitted mean, while individual innings scatter around it.

### Slide 9: 4. Results: compression must preserve useful signal

Compression explains input variation; validation error tests whether the resulting scores retain useful forecasting information. Separate FA blocks are improper.

### Slide 10: 4. Results: venue groups describe historical context

Clusters group venues, using standardized profiles and frozen centres. Membership tables compare average linkage with k-means.

### Slide 11: 4. Results: unusual innings deserve inspection

Read error, leverage and Cook influence separately. Training exclusions are sensitivity alternatives; every assessment innings remains included.

### Slide 12: 4. Results: the frozen comparison decides practical value

Validation selected Exclude influential with test RMSE 41 runs. Nominal intervals cover 58.1 percent of test outcomes.

### Slide 13: 5. Conclusion: an expectation with measured uncertainty

MAE is 32.1 runs and predictive R-squared is 0.006 . The model-based intervals under-cover, limiting precision.

## Detailed speaker notes

Use these notes for practice and questions; use the timed script for the presentation.

### Slide 1: 1. Objective: a forecast before the first ball

Predict actual first-innings totals after the toss and initial XI announcement, before any delivery.

Define the target carefully. Runs include extras and shortened innings. The model uses only information available after the toss and the original roster announcement. Later impact-player choices are excluded. A score estimate can help an analyst compare an innings with its pre-match expectation, but omitted conditions prevent a causal interpretation of that comparison.

### Slide 2: 1. Objective: what the study asks

Ask whether context and player histories beat simple benchmarks, whether compression helps, and how diagnostics change interpretation.

Explain why each class topic has a purpose. Correlated player statistics motivate compression; venue profiles motivate grouping; regression links known inputs to the target. Outlier and variance diagnostics assess assumptions and sensitivity. Baselines establish the value of additional modelling. Success depends on observed prediction error rather than how sophisticated a method sounds.

### Slide 3: 2. Data: earlier seasons teach, later seasons assess

Read the chronological split: test 74 innings; train 1037 innings; validation 74 innings

The split preserves the ordering of seasons. The latest two completed seasons supply validation and test. All learned means, SDs, score weights and cluster centres come from training. Earlier observed matches can update historical features during assessment, simulating forecasts made match by match. The test season was seen in the earlier implementation and this revision is not a new untouched experiment.

### Slide 4: 2. Data: scores have substantial variation

Shortened innings remain part of the actual-total task. Outcomes and realised length are excluded from their own inputs.

Read the distribution before discussing models. The average describes a centre, and standard deviation describes variation across innings. Season means and venue boxplots reveal context differences. Low totals can arise from interruptions as well as poor batting. The pipeline records those outcomes for inspection while keeping them out of prediction inputs. Identity mappings preserve player and franchise histories.

### Slide 5: 3. Methods: build history, then fit regression

Inspect data, covariance and correlation, fit simple and multiple regression, then compare backward AIC and nested added terms as in class.

Use the class sequence: fit lm, inspect summary and confint, inspect residuals, then predict. Multiple regression holds other inputs fixed. Backward AIC removes terms when the criterion improves, and stepAIC verifies the same selection. Added interaction and squared terms start from the full model, retaining main effects. Post-selection significance is exploratory. Correlations and the coefficient-swing table make overlap visible.

### Slide 6: 3. Methods: simplify related measurements

PCA retains 3 components and proper combined FA retains 3 factors. Saved training weights turn inputs into scores for regression.

Walk through standardisation, weights and scores. For PCA, eigenvectors identify directions and eigenvalues measure input variation. Loadings differ from the weights used to compute the class function's unit-variance scores. FA uses principal-axis extraction with varimax and separates common variation from uniqueness. Negative uniqueness in the separate blocks is improper; only the proper combined solution supplies factor forecasts. Both score types enter an ordinary regression with context.

### Slide 7: 3. Methods: diagnose and evaluate honestly

Influence prompts labelled sensitivity fits. Goldfeld–Quandt, log response and inverse-group-variance WLS examine unequal variance. Validation chooses a regression.

A large residual is an unexpected score; leverage is an unusual input combination; influence describes changes in the fit if a case is removed. These are different questions. The class heteroscedasticity script motivates residual plots, Goldfeld–Quandt testing, log response and group-variance weighting. The inverse variances are training estimates. A clearer residual plot does not ensure better forecasts, so validation compares the alternatives.

### Slide 8: 4. Results: venue is an imperfect scoring anchor

Read the venue slope as an average association. The confidence band describes the fitted mean, while individual innings scatter around it.

Use the equation to explain a slope in runs per extra run of earlier venue average. Coefficients describe associations rather than the causal effect of changing grounds. Mean confidence bands and individual prediction intervals have different purposes. Residual panels examine curvature, tails, spread and leverage. An intercept evaluated outside the observed input range is not a realistic cricket scenario.

### Slide 9: 4. Results: compression must preserve useful signal

Compression explains input variation; validation error tests whether the resulting scores retain useful forecasting information. Separate FA blocks are improper.

Compare the same validation targets across raw, component and factor regressions. Input variance explained does not measure target accuracy. The numerical learning-guide example multiplies standardized inputs by training weights and sums to create a score. The regression then multiplies scores and context by its coefficients and adds an intercept. Estimated factor scores can correlate even under an orthogonal latent model. Report improper solutions openly.

### Slide 10: 4. Results: venue groups describe historical context

Clusters group venues, using standardized profiles and frozen centres. Membership tables compare average linkage with k-means.

Explain Euclidean distances after scaling. Single, complete and average linkage define different between-group distances. K-means iterates closest-centre assignments and updates means. The elbow and silhouette examine grouping, while a recorded maximum-silhouette rule chooses the count. Membership labels are arbitrary; use contingency tables to compare algorithms. New venues use earlier history and frozen centres, with a training-profile fallback when no history exists.

### Slide 11: 4. Results: unusual innings deserve inspection

Read error, leverage and Cook influence separately. Training exclusions are sensitivity alternatives; every assessment innings remains included.

Describe the saved thresholds as inspection references rather than proof of recording errors. Cook-influential training cases are omitted only in a labelled alternative, and shortened innings are excluded in another. Assessment remains common to all candidates. A case-removal model may reduce fitted residual spread and produce overly narrow classical intervals. Its point forecast and uncertainty must therefore be assessed separately.

### Slide 12: 4. Results: the frozen comparison decides practical value

Validation selected Exclude influential with test RMSE 41 runs. Nominal intervals cover 58.1 percent of test outcomes.

The final model was selected with validation error and retained before revised test metrics were computed. The smallest test error does not replace that choice. Prediction intervals come from predict.lm under model assumptions, not from an added calibration method. Nominal and empirical coverage are different. Substantial under-coverage means the reported individual-score uncertainty is inadequate for these test innings. State this limitation beside the point-error results.

### Slide 13: 5. Conclusion: an expectation with measured uncertainty

MAE is 32.1 runs and predictive R-squared is 0.006 . The model-based intervals under-cover, limiting precision.

Answer the research questions from saved results. Compare error against both baselines and explain the weak predictive R-squared. Correlated histories, sparse player experience, inferred roles, shortened matches and changing seasons limit accuracy. Principal-axis factor assumptions fail in the separate blocks, and the selected model's classical intervals under-cover. A genuinely later season would provide new evidence. The contribution is a reproducible and understandable application of the supplied course methods.

## Likely professor questions

- **Why actual totals?** The agreed target includes shortened matches; changing that target would change the question.
- **How is leakage prevented?** Strictly earlier dates, original XIs, fixed training transformations and independent historical reconstruction checks.
- **Why a time split?** Later matches should be predicted from earlier evidence. The revised test season was assessed previously.
- **How is the predictor limit checked?** Every design column, including dummy and score columns, is counted before fitting; internal selection fits are audited.
- **Are loadings and weights interchangeable?** No. Loadings describe an axis or factor; score weights calculate each match's numerical score.
- **How do PCA and FA predict runs?** They create scores; lm uses those scores and context to predict runs.
- **What does negative uniqueness mean?** An improper factor solution. The separate blocks are reported as such; the proper combined fit supplies forecasts.
- **Why not delete every flag?** A valid extreme is part of the task. Labelled training sensitivity fits are compared on unchanged assessment rows.
- **Which model won?** Validation chose Exclude influential . Test RMSE is 41 runs; test ranks do not alter that choice.
- **Are the intervals reliable?** Observed coverage is 58.1 percent versus nominal 80 percent. They substantially under-cover.
