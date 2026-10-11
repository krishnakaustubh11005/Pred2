# Decision log

## D-001
Date: 2026-10-10  
Phase: 0  
Context: Agreed learning and evaluation plan.  
Options considered: beginner explanations or advanced shorthand; repeated test comparisons or reserved test evaluation.  
Decision: Teach from basics, explain every phase and continue automatically; reserve the latest completed season until all modelling decisions are frozen. Use validation for earlier comparisons.  
Rationale: The student should understand the methods, and final test results should measure genuinely unseen performance.  
Consequences or risks: Earlier phase comparisons deviate from the requested test metrics; final reporting includes frozen comparisons on the test season.  
Status: active

## D-002
Date: 2026-10-10  
Phase: 0  
Context: System R is present; dependencies and Pandoc are missing and sudo needs a password.  
Options considered: system installation or a project-local Ubuntu binary runtime.  
Decision: Use compatible Ubuntu binaries locally and CRAN sources for missing packages; keep runtime artifacts out of Git.  
Rationale: This preserves the student's system and supports its existing R.  
Consequences or risks: The optional bootstrap is Ubuntu-specific; standard R package installation remains supported. Package versions and session information are recorded.  
Status: superseded by D-018

## D-003
Date: 2026-10-10  
Phase: 0  
Context: The presentation must be short but the brief requests detailed notes.  
Options considered: detailed delivery only or separate short and detailed scripts.  
Decision: Supply the agreed short delivery script and detailed learning notes; predict actual totals, retaining shortened innings for sensitivity analysis.  
Rationale: This matches the student's presentation time and target choice.  
Consequences or risks: Shortened innings add unpredictable variation to the actual-total target.  
Status: active

## D-004
Date: 2026-10-10  
Phase: 1  
Context: CSV player lists include later substitutes.  
Options considered: Use all listed players; reconstruct initial XI from JSON substitutions.  
Decision: Supplement CSV with Cricsheet JSON, remove incoming match substitutes, and require verified initial XIs.  
Rationale: Only the initial XI is available at the prediction time. JSON is used for identities and season-final markers, not target features.  
Consequences or risks: Unreconstructable XIs are excluded from modelling but retained in historical aggregates; substitution metadata is used solely to identify the original roster.  
Status: active
## D-005
Date: 2026-10-10  
Phase: 1  
Context: Names and special innings need consistent treatment.  
Options considered: Keep spelling variants; canonicalise documented aliases.  
Decision: Use reference mapping tables, actual calendar season years, registry player IDs, remove super overs, retain D/L and no-result first innings with deliveries.  
Rationale: Renames should not erase history. No deliveries means no observable target.  
Consequences or risks: Stadium redevelopment is combined under one venue; no-result totals may be incomplete. Home status is omitted because neutral and relocated fixtures make inference unreliable.  
Status: active
## D-006
Date: 2026-10-10  
Phase: 2  
Context: Sparse history and batting roles require defaults.  
Options considered: Drop debutants; shrink sparse histories.  
Decision: Drop earliest season as burn-in; linearly blend player rates to earlier league means until the specified history threshold. Infer top order from previous positions, and use prior league venue fallbacks.  
Rationale: This allows debutants without knowing anything about their future performance.  
Consequences or risks: Career means include non-specialists; batting average and bowling strike rate use a minimum denominator to avoid infinity. Death overs are the final five scheduled overs.  
Status: active

## D-007
Date: 2026-10-10  
Phase: 2  
Context: Season completion and time split must be auditable.  
Options considered: Assume current year is complete; require a recorded final.  
Decision: Use JSON final-stage markers to confirm completed seasons; reserve the latest two for test and validation. All learned transformations remain fitted on training seasons.  
Rationale: A current or partial season cannot silently become the final benchmark.  
Consequences or risks: Completed-season coverage depends on Cricsheet availability; later validation histories may use earlier observed matches, simulating live forecasts rather than a season-start forecast.  
Status: active

## D-008
Date: 2026-10-10  
Phase: 3  
Context: Exploration can accidentally reveal final outcomes.  
Options considered: Plot every season's outcomes; plot training outcomes only.  
Decision: Show split sizes for all seasons but use training-only outcome and correlation plots; limit venue boxplots to the most frequent grounds.  
Rationale: The report can motivate models without looking at held-out outcomes.  
Consequences or risks: Exploratory patterns describe historical training data, not guaranteed future behaviour.  
Status: active

## D-009
Date: 2026-10-10  
Phase: 4  
Context: Many features compete and overlap.  
Options considered: Select by training fit; select AIC/BIC/full procedures by rolling-origin error.  
Decision: Use AIC as the raw selection procedure; compare training-significant interaction and polynomial candidates on validation.  
Rationale: Chronological cross-validation evaluates each selection procedure on later training seasons.  
Consequences or risks: Stepwise selection makes ordinary coefficient intervals exploratory; significance is not proof of causal influence.  
Status: superseded by D-019

## D-010
Date: 2026-10-10  
Phase: 5  
Context: Correlated strength measurements need interpretable reductions.  
Options considered: Kaiser-only PCA and arbitrary factors; training parallel analysis with identifiable factor counts.  
Decision: Analyse batting, bowling and combined blocks; retain PCA components by parallel analysis; fit ML factors with oblimin and compare varimax. Apply training weights unchanged.  
Rationale: Parallel analysis compares signal with random variation; factor identifiability prevents an overparameterised latent model.  
Consequences or risks: FA assumptions may be weak and Heywood cases must be reported; context predictors can correlate with PCs, so overall PCR VIF need not be near unity.  
Status: superseded by D-020

## D-011
Date: 2026-10-10  
Phase: 6  
Context: Venue categories need a small training-derived representation.  
Options considered: Individual venue dummies; standardised venue-profile groups.  
Decision: Fit Ward.D2 and k-means on training profiles; choose k by maximum silhouette and report elbow and gap as supporting checks. Assign unseen venues to frozen nearest centres.  
Rationale: Groups reduce the number of categorical predictors while allowing venue-context differences.  
Consequences or risks: Venue sample sizes affect profiles. Unseen venues with no history use the training overall profile; cluster names describe averages, not fixed ground qualities.  
Status: superseded by D-021

## D-012
Date: 2026-10-10  
Phase: 7  
Context: Influence flags must not dictate deletion.  
Options considered: Delete statistical outliers; retain observations and compare explicit treatments.  
Decision: Retain flagged innings, compare excluding curtailed training innings and robust regression on the same validation target.  
Rationale: Valid extremes are part of the actual-total prediction problem; sensitivity analyses reveal their effects.  
Consequences or risks: Narratives identify plausible statistical explanations rather than claiming independently verified match events.  
Status: superseded by D-022

## D-013
Date: 2026-10-10  
Phase: 7  
Context: Error variance may change with venue and time.  
Options considered: Assume constant variance; compare logs, WLS and HC3 inference.  
Decision: Compare log regression with training smearing, WLS from a training variance model, and HC3 standard errors; bound fitted variances below a training residual quantile.  
Rationale: Log retransformation needs bias correction and inverse-variance weights must remain positive.  
Consequences or risks: Use a fitted-value White test to respect the predictor limit; report it as a reduced-form test. WLS may fail to remove heteroscedasticity. Wider intervals at high-scoring grounds are a conditional explanation, not an assumed finding.  
Status: superseded by D-023

## D-014
Date: 2026-10-10  
Phase: 8  
Context: Final model selection must precede test outcomes.  
Options considered: Pick the best test model; freeze the lowest-validation-RMSE candidate.  
Decision: Freeze WLS using validation RMSE, breaking exact ties by fewer predictors; retain training fit and use validation-calibrated intervals.  
Rationale: The held-out test season measures transfer after decisions are locked.  
Consequences or risks: Using validation for both selection and calibration weakens formal conformal coverage guarantees, as does temporal drift. Interval coverage is therefore assessed empirically; no guaranteed coverage claim is made.  
Status: superseded by D-024

## D-015
Date: 2026-10-10  
Phase: 9  
Context: The student needs a short presentation and a substantial learning reference.  
Options considered: Compress all explanations into slides; separate concise slides and delivery from fuller teaching documents.  
Decision: Render the required self-contained report and ioslides, generate beginner chapters and real-output walkthroughs, and provide short delivery plus fuller notes.  
Rationale: Each artifact serves its audience while reading all numerical evidence from saved results.  
Consequences or risks: The short talk cannot explain every diagnostic in depth; detailed notes and professor answers provide the supporting evidence.  
Status: active

## D-016
Date: 2026-10-10  
Phase: 9  
Context: Rebuilds must keep displayed numerical evidence consistent with saved results.  
Options considered: Retain stale phase tables; refresh phase summaries from current outputs while preserving decision and Git history.  
Decision: Refresh RESULTS phase tables during reproducible rebuilds; retain append-only decisions and phase commits. Use shared bootstrap date resamples for frozen-model comparisons, sequential seeded parallel analysis, and standardised numerical effect plots.  
Rationale: These choices keep generated explanations current, random results reproducible and comparisons readable without changing the selected point forecasts.  
Consequences or risks: Refreshing existing RESULTS sections adjusts the literal append-only workflow; historical versions remain in phase commits. Documentation and display changes after test evaluation never change model selection.  
Status: superseded by D-018

## D-017
Date: 2026-10-11  
Phase: 9  
Context: Historical-role proxies and teaching output need exact definitions.  
Options considered: Use generic feature descriptions; document the actual denominators, shrinkage, fallback and inferred roles.  
Decision: Provide variable-specific construction rules, per-column missing counts, annotated real-output readings and an expanded glossary. Wickets per match is explicitly a bowling-appearance proxy; top order uses prior positions, not the realised current batting order.  
Rationale: The student should be able to explain exactly what each measurement and diagnostic means.  
Consequences or risks: Role inference and finite denominators are imperfect proxies; reporting their definitions does not change frozen model forecasts.  
Status: active

## D-019
Date: 2026-10-11  
Phase: 4  
Context: The supplied classroom pattern must govern modelling.  
Options considered: Retain the previous procedures; adapt the Store24 and Boston examples.  
Decision: Use visible lm fits, backward AIC step and stepAIC verification, nested interaction and polynomial tests, correlation and coefficient comparisons. Supersedes D-009.  
Rationale: The analysis can be followed alongside the actual course scripts.  
Consequences or risks: Stepwise coefficient intervals are exploratory. Added terms retain their main effects.  
Status: active

## D-018
Date: 2026-10-11  
Phase: 3  
Context: The student supplied course files and approved strict alignment.  
Options considered: Rewrite the entire data pipeline; rewrite statistical analysis while retaining verified preparation.  
Decision: Refactor analysis into sequential classroom-style R, use only sourced analytical concepts, and retain basic chronological evaluation and software checks. Supersedes conflicting requirements in Agents.md and D-002, D-009 through D-014, and D-016.  
Rationale: The student chose analysis-only refactoring and retained the chronological split and basic metrics.  
Consequences or risks: The earlier implementation already assessed the test season. The revised test comparison is not newly untouched evidence. Course example typos and interactive commands are corrected rather than copied.  
Status: active

## D-020
Date: 2026-10-11  
Phase: 5  
Context: PCA and FA must follow the course examples.  
Options considered: Keep the former estimators; use principal and principal-axis fa with varimax.  
Decision: Use principal unrotated unit-variance scores, verify against prcomp, and compare unrotated with varimax principal-axis factors. Freeze training score weights. Supersedes D-010.  
Rationale: These calls and the score construction match PCA class.R and FA.R.  
Consequences or risks: Loadings and score weights differ. Factor scores are estimates; varimax factor orthogonality does not guarantee orthogonal estimated scores. Boundary solutions are reported.  
Status: active

## D-021
Date: 2026-10-11  
Phase: 6  
Context: Venue clustering must match the supplied class scripts.  
Options considered: Keep the earlier choices; compare the linkage and k-means methods taught in class.  
Decision: Use scaled Euclidean profiles, single/complete/average linkage, k-means with the classroom random-start count, elbow and maximum silhouette. Compare memberships with tables. Supersedes D-011.  
Rationale: These procedures appear in CA.R, cluster analysis.txt and the Utilities example.  
Consequences or risks: Clusters are descriptive. Small venue histories influence profiles; unseen venues retain the frozen-centre fallback.  
Status: active

## D-022
Date: 2026-10-11  
Phase: 7  
Context: Influence analysis must use taught diagnostics.  
Options considered: Keep the earlier alternatives; use classical diagnostics and labelled case-removal fits.  
Decision: Retain valid extremes in the main fit, compare exclusion of curtailed or Cook-influential training cases, and keep all assessment rows. Supersedes D-012.  
Rationale: The notes explain deletion diagnostics and the class R files demonstrate the selected measures.  
Consequences or risks: Sensitivity exclusions are not a claim that flagged innings are erroneous. The existing Cook reference remains; the example's alternative reference is not silently substituted.  
Status: active

## D-023
Date: 2026-10-11  
Phase: 7  
Context: Unequal variance remedies must follow Heteroskedasticity.R.  
Options considered: Keep the previous variance modelling; use the class group-variance weighting example.  
Decision: Use log-response median forecasts, Goldfeld–Quandt tests on raw/log OLS fits, and WLS inverse variances estimated by tapply from training venue groups. Supersedes D-013.  
Rationale: The group-weight construction and direct lm weights are visible in the supplied script.  
Consequences or risks: Small or invalid group variances use pooled training variance. Do not apply an OLS test that silently ignores WLS weights; inspect its standardized residuals instead.  
Status: active

## D-024
Date: 2026-10-11  
Phase: 8  
Context: Evaluation must retain basic checks and stay within the chosen course scope.  
Options considered: Keep the earlier evaluation extensions; use validation selection and classical regression intervals.  
Decision: Choose Exclude influential among fitted regressions by validation RMSE, with fewer predictors breaking exact ties. Keep baseline benchmarks and classical prediction intervals. Supersedes D-014.  
Rationale: The student explicitly retained chronological evaluation and basic metrics; interval prediction appears in the Boston script.  
Consequences or risks: The test season was examined previously. This revision is not a new untouched experiment. Log forecasts target a median; intervals depend on the fitted model assumptions.  
Status: active

## D-025
Date: 2026-10-11  
Phase: 9  
Context: Teaching materials must regenerate the syllabus-aligned analysis.  
Options considered: Edit only the generated documents; update their generator and source report/slides.  
Decision: Regenerate beginner chapters, mathematical PCA/FA prediction examples, course-source mappings, revised results and timed notes. Supersedes the former teaching method descriptions and evaluation narrative.  
Rationale: A rebuild must reproduce the explanation as well as the models.  
Consequences or risks: Report the improper separate factor solutions and interval under-coverage. Historical decisions remain as provenance, not active method specifications.  
Status: active
