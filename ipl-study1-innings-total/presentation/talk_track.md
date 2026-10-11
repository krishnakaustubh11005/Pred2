# Presentation talk track

## Short delivery script

Use the agreed 10-minute slot; keep explanations concise and point to the figure before reading a metric.



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

The suggested timings include pauses to explain the figures.

### Slide 1: 1. Objective: a forecast before the first ball
The question is an actual first-innings total before the first ball, after the toss and announced XI. This gives a useful expectation against which to judge the eventual innings.

### Slide 2: 1. Objective: what the study asks
We ask whether forecasts beat two simple baselines, whether player strength adds useful context, whether dimensional reduction helps, and whether unusual scores or changing variance alter the conclusions.

### Slide 3: 2. Data: earlier seasons teach, later seasons assess
The split is chronological. test 74 innings; train 1037 innings; validation 74 innings. Later seasons remain held out while earlier ones teach the model.

### Slide 4: 2. Data: scores have substantial variation
The distribution includes shortened innings. That makes the actual-total question harder, but dropping those assessment cases would change the target. Historical inputs never include the realised innings length.

### Slide 5: 3. Methods: build history, then fit regression
R turns deliveries into innings and strictly earlier histories. A simple venue regression starts the analysis; multiple regression introduces strength and context. Rolling training seasons compare the selection procedures.

### Slide 6: 3. Methods: simplify related measurements
PCA retains 3 combined axes; FA retains 3 factors. PCA summarises total variation, FA models shared variation, and clustering describes venue profiles. Everything learned is fitted on training seasons.

### Slide 7: 3. Methods: diagnose and evaluate honestly
Diagnostics inspect errors and assumptions. Influence flags prompt sensitivity fits, while log models, WLS and HC3 address different uncertainty problems. Validation fixes the model before the test season is examined.

### Slide 8: 4. Results: venue is an imperfect scoring anchor
The simple fitted line gives an average relationship. The broad scatter reminds us that venue history alone cannot pin down a single cricket score. A mean confidence band is narrower than an individual prediction interval.

### Slide 9: 4. Results: compression must preserve useful signal
Here we compare raw regression with PCA and factor-score regression on the same validation season. Compact inputs are useful only when they retain predictive information; explained input variance is not a forecasting score.

### Slide 10: 4. Results: venue groups describe historical context
Venue clusters describe similarities in training profiles. Group labels refer to average historical scoring context and are not permanent ground identities. New venues use earlier history and frozen centres.

### Slide 11: 4. Results: unusual innings deserve inspection
Large bubbles indicate influence on regression coefficients. The case with the largest error need not be the most influential. Valid extremes remain in the forecasting problem, and shortened-innings and robust fits are explicit alternatives.

### Slide 12: 4. Results: the frozen comparison decides practical value
Validation selected WLS. Its test RMSE is 41 runs, and interval coverage is 83.8 percent. The other frozen test results are reported without changing the chosen model.

### Slide 13: 5. Conclusion: an expectation with measured uncertainty
The selected model's MAE is 32.2 runs. Compare its error with both baselines before claiming practical improvement. Sparse histories, shortened matches and changing seasons limit precision; the reproducible evidence is the project's main contribution.

## Detailed speaker notes

Aim for 60–90 seconds per slide during practice. These fuller notes support questions; use the short script for the timed presentation.

### Slide 1: 1. Objective: a forecast before the first ball
The question is an actual first-innings total before the first ball, after the toss and announced XI. This gives a useful expectation against which to judge the eventual innings.

Explain the distinction between predicting a realised score and imagining a full-length innings. The realised score includes extras and interruptions. Our prediction point permits the toss and original playing XI but excludes delivery outcomes and later tactical substitutions. A fan could use the estimate as context rather than a promise; an analyst could compare an actual innings with the forecast and its interval. Be careful not to turn that residual into a causal measure of a batter's contribution, because conditions and team decisions can still be omitted.

### Slide 2: 1. Objective: what the study asks
We ask whether forecasts beat two simple baselines, whether player strength adds useful context, whether dimensional reduction helps, and whether unusual scores or changing variance alter the conclusions.

Introduce the baselines before the sophisticated methods. A baseline establishes what is gained by additional modelling effort. The research questions connect the syllabus to concrete problems: correlated strength inputs motivate PCA and factor analysis, many venues motivate grouping, and unusual innings motivate diagnostic checks. Success was stated before results were seen. We report a negative outcome honestly if the model does not beat both reference rules on the final season. None of these methods produces a win probability in this study.

### Slide 3: 2. Data: earlier seasons teach, later seasons assess
The split is chronological. test 74 innings; train 1037 innings; validation 74 innings. Later seasons remain held out while earlier ones teach the model.

Read the timeline from left to right and name which season is validation and which is test using the saved split table. We confirmed completion using a recorded final, rather than assuming the latest calendar label was complete. Matches on a shared date cannot contribute outcomes to one another's histories. Venue and player features may update from earlier observed matches during validation and test; this simulates forecasts made match by match, rather than predictions made for a whole season before it begins.

### Slide 4: 2. Data: scores have substantial variation
The distribution includes shortened innings. That makes the actual-total question harder, but dropping those assessment cases would change the target. Historical inputs never include the realised innings length.

Point out that the target includes extras and that all-out innings differ from curtailed innings. A low score is not automatically poor batting: fewer available deliveries can create the same total. Our cleaning preserves those cases and records flags for sensitivity analysis. Stable registry identifiers prevent renames or player-name variations from erasing history. JSON substitution records are used only to reconstruct the original XI, not to let a later incoming player influence the pre-innings forecast. Reference tables document stadium and franchise aliases.

### Slide 5: 3. Methods: build history, then fit regression
R turns deliveries into innings and strictly earlier histories. A simple venue regression starts the analysis; multiple regression introduces strength and context. Rolling training seasons compare the selection procedures.

Explain least squares using the vertical distances between points and the fitted line. Adding predictors changes what a coefficient means because it now holds more inputs fixed. Count dummy columns and proposed interaction terms, not only names in the source table. AIC and BIC are procedures that balance training fit and complexity; rolling-origin assessment asks which procedure predicts the next season better. Stepwise coefficient significance is exploratory because the data helped select the specification. VIF is evidence of overlapping inputs, not evidence that forecasting is impossible.

### Slide 6: 3. Methods: simplify related measurements
PCA retains 3 combined axes; FA retains 3 factors. PCA summarises total variation, FA models shared variation, and clustering describes venue profiles. Everything learned is fitted on training seasons.

Describe PCA as a new set of directions through the standardised input cloud and FA as a model for shared variation with uniqueness. Their mathematical outputs look similar, but their goals and assumptions differ. KMO and Bartlett support inspection of suitability rather than proving the latent model. Parallel analysis compares observed structure with random references, while identifiability limits the factor count. Cluster profiles use training venue totals, spread, boundaries and match counts. Held-out observations use training scaling, loadings and centres without recomputing those learned quantities.

### Slide 7: 3. Methods: diagnose and evaluate honestly
Diagnostics inspect errors and assumptions. Influence flags prompt sensitivity fits, while log models, WLS and HC3 address different uncertainty problems. Validation fixes the model before the test season is examined.

Separate diagnosis from remedy. A large residual concerns a score surprise; leverage concerns unusual historical inputs; influence concerns movement in the fitted coefficients. Robust regression downweights large errors, while excluding shortened training innings changes exposure in the fitting sample. Heteroscedasticity concerns conditional variance. HC3 adjusts uncertainty without changing forecasts, and WLS changes the fit using positive weights from a training variance model. Validation makes the final choice and also calibrates intervals, so later coverage is assessed empirically rather than advertised as guaranteed.

### Slide 8: 4. Results: venue is an imperfect scoring anchor
The simple fitted line gives an average relationship. The broad scatter reminds us that venue history alone cannot pin down a single cricket score. A mean confidence band is narrower than an individual prediction interval.

Use the equation and axes to explain the venue slope in runs per extra run of earlier venue average. An intercept outside the observed venue range is not a realistic cricket forecast. The confidence ribbon describes uncertainty around the average fitted line, while the scatter contains individual-match variation. Mention that residual plots are needed to assess curvature, non-normal tails and changing spread. The simple model is valuable as an interpretable benchmark even when a more complex candidate predicts better. Avoid implying that changing grounds directly causes the estimated score difference.

### Slide 9: 4. Results: compression must preserve useful signal
Here we compare raw regression with PCA and factor-score regression on the same validation season. Compact inputs are useful only when they retain predictive information; explained input variance is not a forecasting score.

Read the common context effects and validation error side by side. The plotted effects share training-standard-deviation scales, whereas principal-component and factor-score coefficients use transformed units and should not be compared directly with raw strength coefficients. Components with high input variance can still carry weak score information. PCA scores are orthogonal within the fitted strength block, but can correlate with context variables, so overall PCR VIF need not equal unity. Factor correlations and uniqueness provide extra interpretation. Report warnings or near-boundary factor solutions instead of using confident hidden-ability labels.

### Slide 10: 4. Results: venue groups describe historical context
Venue clusters describe similarities in training profiles. Group labels refer to average historical scoring context and are not permanent ground identities. New venues use earlier history and frozen centres.

Explain that the heatmap expresses group averages relative to training venue means. The match-count feature helps describe confidence and historical frequency, but also influences the distance used to group grounds. Elbow, silhouette and gap may disagree; the recorded maximum-silhouette rule makes the choice reproducible. Ward.D2 supplies an independent hierarchical comparison, and adjusted Rand agreement summarises whether the partitions are similar. None of this proves the groups improve forecasts: the regression with venue groups is separately evaluated on validation. A new venue with no history uses the training overall profile.

### Slide 11: 4. Results: unusual innings deserve inspection
Large bubbles indicate influence on regression coefficients. The case with the largest error need not be the most influential. Valid extremes remain in the forecasting problem, and shortened-innings and robust fits are explicit alternatives.

Read horizontal leverage, vertical studentized error and bubble-size Cook's distance separately. Threshold crossings invite inspection rather than deletion. The table gives plausible cricket explanations such as shortened exposure or an unusually high total; those statements are not independently verified match narratives. Coefficient sensitivity is assessed with all innings, without shortened training innings and with robust fitting, while assessment rows remain the same. Variance diagnostics ask a different question about changing residual spread. A small p-value may identify an assumption problem without identifying the best predictive remedy.

### Slide 12: 4. Results: the frozen comparison decides practical value
Validation selected WLS. Its test RMSE is 41 runs, and interval coverage is 83.8 percent. The other frozen test results are reported without changing the chosen model.

Read lower RMSE as better prediction on the same untouched season. Uncertainty bars come from resampling match dates so same-day observations remain together. The validation-selected candidate stays selected even if another frozen candidate has the lowest test error. Predictive R-squared can be negative because it compares squared error with the held-out score mean. Prediction intervals use earlier validation residuals, and their observed coverage can miss the nominal level under season shifts. They communicate uncertainty about an individual innings; they are not coefficient confidence intervals or proof of guaranteed future coverage.

### Slide 13: 5. Conclusion: an expectation with measured uncertainty
The selected model's MAE is 32.2 runs. Compare its error with both baselines before claiming practical improvement. Sparse histories, shortened matches and changing seasons limit precision; the reproducible evidence is the project's main contribution.

Answer each research question using the saved comparison tables rather than recollection. State the selected model's error, the baseline relationship and observed interval coverage. The practical conclusion may be that a simple history-based forecast competes well with sophisticated transformations. Explain limitations that change interpretation: shortened innings, sparse careers, combined venue identities, unknown later substitutions and temporal scoring shifts. Future work could use independently verified weather forecasts and an additional calibration season. End by explaining that a reproducible result that exposes its weaknesses is more defensible than an impressive-looking fit obtained with future information.

## Likely professor questions

- **Why predict actual totals rather than full-length totals?** The agreed target includes what actually happened. Shortened innings remain in assessment, and we test sensitivity to their removal from fitting.
- **How did you prevent leakage?** Features use strictly earlier dates, including double-headers. Initial XIs are reconstructed from substitution records, and a saved brute-force reconstruction audit checks sampled rows.
- **Why a time split?** The practical task predicts later seasons from earlier cricket. Random allocation would mix future scoring conditions into training.
- **Did you respect the predictor limit?** Each candidate and fitted design matrix is logged; dummy columns, components, factors and added terms count separately. The final ratio audit must pass.
- **Why both PCA and FA?** PCA summarises total input variation; FA models shared variation plus uniqueness. Their validation forecasts test whether either representation preserves useful score information.
- **Why can coefficients change with more variables?** Coefficients become conditional on different information; overlapping histories can redistribute estimated associations. VIF and the coefficient-swing table expose this.
- **Why not delete outliers?** A valid extraordinary innings belongs to the target population. We retain flags and compare robust and shortened-innings alternatives on common validation outcomes.
- **What does HC3 improve?** Coefficient uncertainty under unequal variance. It leaves fitted values and point-prediction error unchanged.
- **Which model won, and did you change it after testing?** Validation chose WLS. Its final test RMSE is 41 runs. Test rankings did not alter the frozen choice.
- **Can you guarantee interval coverage next season?** No. Observed test coverage is 83.8 percent; temporal drift and shared validation selection/calibration prevent a guaranteed-coverage claim.
