set.seed(42)
write_doc <- function(lines, path) writeLines(lines, here::here(path))
rr <- function(name) readr::read_csv(here::here("results", paste0(name, ".csv")), show_col_types = FALSE)
table_md <- function(x) paste(capture.output(knitr::kable(x, digits = 3)), collapse = "\n")
selected <- rr("final_selection")
tm <- rr("test_metrics")
final <- subset(tm, model == selected$model)
interval <- rr("interval_summary")
dc <- subset(rr("dimension_checks"), block == "Combined")

# A real validation match shows the arithmetic from input to score to forecast.
example <- va[1, ]
x <- as.numeric(example[, combined$vars])
z <- (x - combined$center) / combined$spread
score_example <- data.frame(variable = combined$vars, input = x, training_mean = combined$center,
 training_sd = combined$spread, standardized = z, PC1_weight = combined$pca$weights[,1],
 PC1_contribution = z * combined$pca$weights[,1], FA1_weight = combined$fa$weights[,1],
 FA1_contribution = z * combined$fa$weights[,1], row.names = NULL)
save_csv(score_example, "score_example_features")
example_scores <- data.frame(method = c("PCR", "FA"), match_id = example$match_id,
 actual = example$first_innings_total, first_score = c(sum(score_example$PC1_contribution), sum(score_example$FA1_contribution)),
 predicted = c(predict_candidate("PCR", example), predict_candidate("FA", example)))
save_csv(example_scores, "score_example_summary")
bridge <- bind_rows(lapply(c("PCR", "FA"), function(method) {
 entry <- models[[method]]
 input <- transform_strength(example, combined, entry$transform)
 design <- model.matrix(delete.response(terms(entry$fit)), input)
 beta <- coef(entry$fit)
 data.frame(method, term = names(beta), input_value = as.numeric(design[1,names(beta)]),
 coefficient = beta, contribution_runs = as.numeric(design[1,names(beta)]) * beta, row.names = NULL)
}))
save_csv(bridge, "score_example_prediction_terms")
stopifnot(all(abs(tapply(bridge$contribution_runs, bridge$method, sum) -
 example_scores$predicted[match(names(tapply(bridge$contribution_runs, bridge$method, sum)), example_scores$method)]) < 1e-7))

topics <- data.frame(topic = c("Introduction to R", "Simple Regression", "Multiple Regression", "PCA",
 "Factor Analysis", "Cluster Analysis", "Outlier Detection", "Heteroscedasticity"),
 script = c("02_clean.R / 03_features.R", "05_regression.R", "05_regression.R", "06_pca_fa.R",
 "06_pca_fa.R", "07_clustering.R", "08_outliers_hetero.R", "08_outliers_hetero.R"),
 figures = c("f01–f05", "f06–f07", "f08–f09", "f10–f12, f15", "f13–f15", "f16–f18", "f19–f21", "f22–f25"),
 report_section = c("Data and Methods", rep("Methods and Results", 7)))
save_csv(topics, "course_coverage")
sentences <- c("R converts raw cricket records into reproducible tables and outputs.",
 "Simple regression fits an average straight-line relationship using one input.",
 "Multiple regression fits conditional associations using several inputs.",
 "PCA replaces correlated measurements with component scores describing input variation.",
 "Factor analysis models shared variation and feature-specific uniqueness.",
 "Clustering groups venues that have similar historical profiles.",
 "Outlier diagnostics distinguish unusual errors, unusual inputs and influential observations.",
 "Heteroscedasticity means model-error variance differs across contexts.")
analogies <- c("A recipe turns raw ingredients into a repeatable meal.",
 "A ruler through a cloud of points shows an average direction.",
 "Comparing house prices while accounting for size and location changes what each effect means.",
 "Several related fitness measurements can be summarised along a few directions.",
 "Exam questions may share a skill while retaining question-specific variation.",
 "Sort grounds by their scoring climate instead of alphabetically by name.",
 "A surprising exam score may or may not change the fitted relationship substantially.",
 "Journey times can have similar averages but different uncertainty in different traffic conditions.")
steps <- list(
 c("Use read.csv(), head(), tail(), names(), dim(), summary(), mean(), sd(), cov() and cor() to inspect a table, as in the Intro-to-R script. The existing raw-data preparation uses the tested import and aggregation pipeline; this refactor does not rewrite it.",
   "Each delivery supplies bat runs and extras. Sum them within the first innings to obtain the target. Dates determine which earlier matches can supply history. The final table has one row per first innings and a separate target column.",
   "The season split assigns earlier innings to fitting and later innings to assessment. Match outcomes can update historical inputs only for strictly later dates; they cannot change a feature for their own match."),
 c("The model is $Y_i=\\beta_0+\\beta_1V_i+\\epsilon_i$. $Y_i$ is total runs, $V_i$ is earlier venue mean, $\\beta_0$ is the intercept, $\\beta_1$ is slope and $\\epsilon_i$ is an unobserved error.",
   "Least squares minimises $\\sum_i(Y_i-\\beta_0-\\beta_1V_i)^2$. For one input, the fitted slope is $\\widehat\\beta_1=\\sum_i(V_i-\\bar V)(Y_i-\\bar Y)/\\sum_i(V_i-\\bar V)^2$, and the intercept is $\\widehat\\beta_0=\\bar Y-\\widehat\\beta_1\\bar V$.",
   "Run lm(), inspect summary() and confint(), then predict() for new input values. Residuals are actual minus fitted scores. A confidence interval concerns an average relationship; a prediction interval concerns an individual innings."),
 c("Write $Y=X\\beta+\\epsilon$. $Y$ contains training totals, $X$ contains an intercept column and predictor columns, $\\beta$ contains coefficients and $\\epsilon$ contains errors. With full column rank, least squares gives $\\widehat\\beta=(X^\\mathsf{T}X)^{-1}X^\\mathsf{T}Y$. R's lm() performs the fit without requiring us to invert the matrix manually.",
   "A coefficient describes score change while other included predictors stay fixed. Correlated features contain overlapping information, so adding a feature can change the other coefficients. We compare the simple and full venue coefficient and show the batting strike-rate/boundary relationship.",
   "The Store24 example uses backward step() and stepAIC(). AIC balances fitted likelihood with the number of parameters. Starting from the full model, backward selection removes terms when AIC improves. The two taught functions are checked for agreement.",
   "The Boston example adds interactions and squared terms, then uses anova() for nested comparisons. Our extensions start from the full model to retain main effects. Added terms with the saved training significance criterion become validation candidates."),
 c("First examine correlation: $r_{ab}=\\mathrm{cov}(X_a,X_b)/(s_as_b)$. Covariance uses paired deviations from each variable's mean, while correlation divides by both standard deviations. Correlation describes linear co-movement, not causation.",
   "Standardise strength feature $j$ as $z_{ij}=(x_{ij}-\\mu_j)/s_j$, using training mean $\\mu_j$ and SD $s_j$. This prevents units such as runs and percentages from determining the axes just because their numerical spreads differ.",
   "Form the training correlation matrix $R=Z^\\mathsf{T}Z/(N-1)$. Its eigenvectors $v_k$ satisfy $Rv_k=\\lambda_kv_k$; $\\lambda_k$ is the variance along direction $k$. The raw score $Zv_k$ has that variance, and explained share is $\\lambda_k/\\sum_\\ell\\lambda_\\ell$.",
   "The class principal() function returns unit-variance scores. Its component loading is $L_{jk}=v_{jk}\\sqrt{\\lambda_k}$, while the score weight is $W_{jk}=v_{jk}/\\sqrt{\\lambda_k}$. Compute $PC_{ik}=\\sum_jz_{ij}W_{jk}$. We verify the equivalent prcomp scores after adjusting sign and scale.",
   "Parallel analysis compares actual eigenvalues with random-data references. Retained scores become ordinary inputs to lm(): $\\widehat Y_i=\\widehat\\beta_0+\\sum_c\\widehat\\beta_c C_{ic}+\\sum_k\\widehat\\gamma_k PC_{ik}$. $C$ contains context inputs and $\\gamma$ contains the fitted component effects. PCA does not use the target to learn its axes."),
 c("The model is $z_i=L f_i+u_i$: $z_i$ contains standardised strength measurements, $L$ contains loadings, $f_i$ represents unobserved common factors, and $u_i$ represents feature-specific variation.",
   "For orthogonal factors, $\\mathrm{Cov}(z_i)\\approx LL^\\mathsf{T}+\\Psi$. $\\Psi$ is diagonal uniqueness. Feature $j$ has communality $h_j^2=\\sum_kL_{jk}^2$ and uniqueness approximately $1-h_j^2$. A negative uniqueness is an improper variance decomposition.",
   "FA.R uses principal-axis extraction: fa(..., fm='pa'). This estimates common variation rather than allocating all variance to components. Compare rotate='none' with rotate='varimax'; varimax seeks simpler loading patterns while preserving the orthogonal model's common covariance.",
   "Factors are unobserved. Estimated scores use the training regression-score weights returned by fa(): $\\widehat F=ZW_F$. Multiply each standardised input by its weight and sum. Loading values are not interchangeable with score weights.",
   "Use those estimated scores in another lm(): $\\widehat Y_i=\\widehat\\alpha_0+\\sum_c\\widehat\\alpha_c C_{ic}+\\sum_k\\widehat\\delta_k\\widehat F_{ik}$. Estimated factor scores need not be perfectly uncorrelated. The separate batting/bowling solutions are improper, so only the proper combined solution supplies forecasts."),
 c("Each venue is an observation with training mean total, SD, boundary rate and match count. Standardise these profile columns using training profile means and SDs. Euclidean distance is $d(i,j)=\\sqrt{\\sum_m(z_{im}-z_{jm})^2}$, with $m$ indexing profile measurements.",
   "Hierarchical clustering starts with separate observations and repeatedly merges clusters. Single linkage uses the nearest pair, complete linkage the farthest pair and average linkage the average pairwise distance. hclust() creates the tree; cutree() supplies memberships for a chosen k.",
   "K-means alternates assignment to the closest centre and centre updates. It minimises $\\sum_k\\sum_{i\\in C_k}\\lVert z_i-\\mu_k\\rVert^2$. Several starts reduce dependence on a poor initial choice. The elbow displays within-group variation as k changes; silhouette compares closeness within a group with separation from alternatives.",
   "Choose k by the recorded maximum-silhouette rule and compare hierarchical/k-means membership tables. Group labels are arbitrary: cluster 1 from two algorithms need not describe the same observations. A categorical venue group adds dummy predictor columns to regression. New venues use earlier history and frozen centres."),
 c("For innings i, residual $e_i=Y_i-\\widehat Y_i$ describes score error. rstandard() rescales residuals using fitted residual spread and leverage; rstudent() uses a case-deleted estimate of spread. hatvalues() returns leverage, which describes unusual input combinations.",
   "Cook's distance summarises how fitted values change if a case is omitted. DFFITS describes a fitted-value change; DFBETAS describes standardized changes in individual coefficients. These are related diagnostics with different questions.",
   "The clustering notes also cover Mahalanobis distance: $D_i^2=(x_i-\\bar x)^\\mathsf{T}S^{-1}(x_i-\\bar x)$. $S$ is predictor covariance. A covariance-aware inverse is restricted to nonzero-variance directions so redundant columns do not produce an invalid inverse.",
   "The saved thresholds mark cases for inspection. They do not establish a data error. Keep valid extremes in the dataset and compare explicitly labelled training case-removal fits; do not remove challenging validation or test innings."),
 c("Write $\\mathrm{Var}(\\epsilon_i\\mid X_i)=\\sigma_i^2$. A changing vertical spread in residual plots suggests unequal variance. Goldfeld–Quandt compares residual mean squares from earlier/later season segments: $GQ=(RSS_2/df_2)/(RSS_1/df_1)$, where RSS is residual sum of squares and df is residual degrees of freedom.",
   "The class script compares a raw response with log(y). Exponentiating a fitted log value gives a conditional median under the usual log-error interpretation; it does not directly produce a conditional arithmetic mean.",
   "The market-share example uses tapply(residuals(model), group, var). We do the same with training venue groups. Give a case weight $w_i=1/\\widehat\\sigma^2_{g(i)}$; a noisier group contributes less to weighted fitting. Invalid or undersized groups use pooled training residual variance.",
   "Fit lm(..., weights=wts), inspect summary() and standardized residuals. The weighted least-squares expression is $\\widehat\\beta=(X^\\mathsf{T}WX)^{-1}X^\\mathsf{T}WY$, where W is diagonal weights. New-innings prediction intervals require the corresponding frozen group weight. Do not use a diagnostic that silently ignores weights."))
use_cases <- c("Use a pipeline when data corrections must update all results. Do not edit generated CSVs by hand.",
 "Use a single-input model as an interpretable starting point. Check residual patterns before relying on its line.",
 "Use several pre-innings inputs when they may add information. Avoid causal claims and excessive candidate pools.",
 "Use PCA for correlated numeric measurements. Avoid assuming explained input variance guarantees predictive accuracy.",
 "Use FA when a common-factor interpretation is plausible. Do not interpret an improper solution as a valid variance model.",
 "Use clustering for exploratory grouping. Do not treat labels as known natural ground types or prediction scores.",
 "Use diagnostics to investigate sensitivity. Avoid deleting all flagged observations as if flags proved errors.",
 "Use log or weighted fits when residual patterns motivate them. Diagnose and compare accuracy separately.")
result_names <- c("score_summary", "simple_coefficients", "coefficient_swing", "pca_eigenvalues",
 "dimension_checks", "cluster_summary", "influence_thresholds", "heteroscedasticity_tests")
readings <- c("The descriptive table shows the centre and spread of actual training totals. Shortened innings remain included.",
 "The intercept and slope are in runs. Confidence limits describe uncertainty about the estimated coefficients, not the spread of an individual innings.",
 "The same venue input has different coefficients in the simple and full models because the full coefficient holds other included inputs fixed.",
 "Read eigenvalues and cumulative input variance alongside the retained flag. These numbers are about inputs, not runs-prediction accuracy.",
 "Negative uniqueness in the separate batting/bowling blocks means improper solutions. The combined model's saved minimum uniqueness is positive; its scores feed the FA regression.",
 "Read k and silhouette as grouping choices. Use the membership table to compare methods without requiring identical group numbers.",
 "Read thresholds as inspection references and count all dummy columns in p. Unusual errors, leverage and influence are different signals.",
 "The Goldfeld–Quandt p-value concerns increased variance between season segments. The WLS group-variance table concerns differences across venue groups.")
mistakes <- c("Mixing future outcomes into history; confusing delivery rows with innings rows; editing generated outputs.",
 "Treating the fitted line as an exact score; interpreting the intercept outside observed input ranges; confusing mean and prediction intervals.",
 "Treating coefficients as causal; omitting main effects from interaction comparisons; claiming post-selection significance is confirmatory.",
 "Using loadings directly as score weights; fitting scaling on later data; confusing variance explained with prediction accuracy.",
 "Treating negative uniqueness as meaningful; substituting loadings for score weights; treating estimated scores as directly observed abilities.",
 "Clustering unscaled mixed units; treating arbitrary numeric labels as ordered; fitting centres using test outcomes.",
 "Confusing a large residual with influence; silently deleting valid extremes; removing assessment cases after seeing their scores.",
 "Exponentiating a log prediction and calling it a mean; using invalid weights; assuming a better-looking plot guarantees better predictions.")
self_checks <- list(
 c("What is one row? — One first innings.", "May this match supply its own history? — No.", "What does the target include? — Bat runs and extras."),
 c("What does the slope describe? — Change in predicted average per input unit.", "What is a residual? — Actual minus fitted value.", "Which interval concerns one match? — A prediction interval."),
 c("What is held fixed by a coefficient? — Other included inputs.", "What does backward selection do? — Removes terms when AIC improves.", "Why keep main effects? — To make added-term comparisons properly nested and interpretable."),
 c("Does PCA use the outcome to find axes? — No.", "Are loadings and weights identical? — No; their eigenvalue scaling differs.", "How are scores used? — As numeric inputs to regression."),
 c("What is uniqueness? — Feature-specific variance not explained by common factors.", "What does negative uniqueness indicate? — An improper factor solution.", "How are held-out scores calculated? — With training means, SDs and saved score weights."),
 c("What does standardisation prevent? — Numerical units dominating distance.", "Do matching label numbers prove agreement? — No.", "How is a new venue assigned? — To a frozen nearest centre using earlier history."),
 c("What is leverage? — Unusualness of the predictor combination.", "Does a flag prove an error? — No.", "What stays common across sensitivity evaluations? — The validation/test innings."),
 c("Why inverse-variance weights? — Noisier groups get less fitting weight.", "What does exp(log prediction) represent? — A conditional median under the model interpretation.", "Does nominal interval coverage guarantee actual coverage? — No."))
guide <- c("# Learning guide", "", "The statistical examples follow the supplied course files. Basic time splitting and prediction metrics remain agreed project checks.", "")
for (i in seq_len(nrow(topics))) {
 example_output <- rr(result_names[i])
 if(i == 4) example_output <- subset(example_output, block == "Combined")
 if(i == 5) example_output <- example_output %>% select(block, variables, retained_factors, min_uniqueness, max_communality, boundary_warning)
 guide <- c(guide, paste0("## ", topics$topic[i]), "", "### In one sentence", "", sentences[i], "",
 "### An everyday analogy", "", analogies[i], "", "### The idea step by step (light maths, every symbol defined)", "",
 paste0(seq_along(steps[[i]]), ". ", steps[[i]]), "", "### When to use it and when not", "", use_cases[i], "",
 "### What we did in THIS project (link scripts and figures)", "",
 paste0("Follow [", topics$script[i], "](../scripts/", strsplit(topics$script[i], " / ")[[1]][1],
 ") and ", topics$figures[i], " in the [figure index](../figures/INDEX.md)."), "",
 "### How to read the output (annotated example from our real output)", "", table_md(head(example_output,12)), "", readings[i], "",
 "### Common mistakes", "", mistakes[i], "", "### Self-check questions (3, with short answers)", "", paste0("- ", self_checks[[i]]), "")
}
guide <- c(guide, "## How the techniques connect", "",
 "Raw deliveries become innings totals and strictly earlier historical inputs. Exploration examines scoring distributions, season changes, venues and correlations. Simple regression gives a readable baseline relationship; multiple regression combines context and team strength. PCA and FA construct alternative numerical inputs, and clustering constructs a venue-group input. Influence and variance diagnostics lead to labelled alternative fits. Validation chooses a fitted regression before the revised test comparison.", "",
 "### A real match: standardisation and score construction", "",
 paste0("The saved example is validation match ", example$match_id, ". All transformation parameters were learned from training seasons."), "",
 table_md(rr("score_example_features")), "",
 "For PC1, multiply each standardized value by its PC1 weight, then add the contribution column. For FA1, use the FA1 weights instead. These are different transformations of the same historical inputs.", "",
 table_md(rr("score_example_summary")), "",
 "### From scores to predicted runs", "",
 "The following table shows the regression arithmetic: input value times fitted coefficient gives that term's contribution in runs. Add the intercept contribution and all remaining contributions within each method. The result equals the saved prediction above. The actual total is shown only for comparison; it never determines the scores for this match.", "",
 table_md(rr("score_example_prediction_terms")), "",
 "### What the final evaluation teaches", "",
 table_md(final), "", table_md(interval), "",
 paste0("Validation selected ", selected$model, ". Its nominal intervals cover ", round(100*interval$empirical_coverage,1),
 "% of test scores, substantially below the nominal ", round(100*interval$nominal_coverage),
 "%. A point forecast can beat old historical baselines while its model-based uncertainty is too narrow. The test season was already examined in the earlier implementation; this revision is not newly untouched evidence."))
write_doc(guide, "docs/01_learning_guide.md")

walkthrough <- c("# Walkthrough", "", "## Data and features", "", table_md(rr("data_quality")), "", table_md(rr("split_summary")), "",
 "The raw-data and historical-feature pipeline remains unchanged. D-018 records the student's analysis-only refactor and retention of basic evaluation.", "",
 "## Explore, then fit", "", "Descriptive summaries, covariance and correlation precede regression. D-019 adapts Store24 and Boston with visible fits, backward AIC and nested comparisons.", "", table_md(rr("score_summary")), "", table_md(rr("validation_metrics")), "",
 "## Compress variables and group venues", "", "D-020 follows principal scores and principal-axis FA; D-021 follows classroom linkage and k-means. Only the proper combined factor solution supplies prediction inputs.", "", table_md(rr("dimension_checks") %>% select(block,retained_pcs,retained_factors,pca_variance,min_uniqueness,boundary_warning)), "", table_md(rr("cluster_summary")), "",
 "## Investigate influence and variance", "", "D-022 retains labelled case-removal comparisons; D-023 uses log response and inverse-group-variance WLS. Assessment innings remain common to every model.", "", table_md(rr("heteroscedasticity_tests")), "", table_md(rr("venue_variance")), "",
 "## Freeze and evaluate", "", "D-024 selects among fitted regressions using validation. Classical prediction intervals follow the Boston pattern. All revised test rankings are reported without altering the chosen model.", "", table_md(rr("final_selection")), "", table_md(tm), "", table_md(interval), "",
 "The test season has been evaluated before; it is not a newly untouched experiment. The selected model's interval under-coverage is a material limitation.")
write_doc(walkthrough, "docs/02_walkthrough.md")

# This replaces the glossary so obsolete concepts do not reappear on a rebuild.
glossary <- data.frame(term = c("AIC", "Adjusted R-squared", "Average linkage", "Baseline", "Boundary rate", "Burn-in",
 "Candidate pool", "Cluster", "Coefficient", "Communality", "Complete linkage", "Confidence interval", "Correlation",
 "Covariance", "DFBETAS", "DFFITS", "Eigenvalue", "Eigenvector", "Factor", "Factor score", "Goldfeld–Quandt",
 "Heteroscedasticity", "Initial XI", "Interaction", "K-means", "Leverage", "Loading", "MAE", "Mahalanobis distance",
 "Median forecast", "Nested model", "OLS", "Outlier", "Parallel analysis", "PCA", "Prediction interval", "Predictor",
 "Residual", "RMSE", "Score weight", "Season index", "Silhouette", "Single linkage", "Standard deviation", "Standard error",
 "Standardisation", "Studentized residual", "Test set", "Training set", "Uniqueness", "Validation set", "Varimax", "WLS"),
 definition = c("Likelihood-based fit/complexity criterion used for backward selection.", "Training fit measure adjusted for predictor count.",
 "Merges clusters using average pairwise distance.", "Simple reference forecast used to judge added modelling value.",
 "Historical fraction of delivery events producing actual boundaries.", "Earliest season supplying history before modelled innings.",
 "All proposed predictor columns, including added terms and dummies.", "Group of observations with similar measurements.",
 "Estimated conditional effect of an included predictor.", "Variance represented by common factors.", "Merges using the farthest pair.",
 "Interval estimating an average or parameter under specified assumptions.", "Standardized linear co-movement of two variables.",
 "Average product of paired deviations from their means.", "Standardized coefficient sensitivity to deleting a case.",
 "Standardized fitted-value sensitivity to deleting a case.", "Variance along a component direction.", "Direction satisfying the matrix eigenvalue equation.",
 "Unobserved common source of covariance in an assumed model.", "Estimated position computed from observed inputs and factor score weights.",
 "Compares residual mean squares across two ordered segments.", "Error variance differs across observations or contexts.",
 "Original announced eleven players; later substitutes are excluded.", "Term allowing one predictor's association to depend on another.",
 "Groups observations by repeatedly updating nearest-centre assignments.", "Unusualness of an input combination in the fitted design.",
 "Association between a measurement and a component/factor; distinct from score weights.", "Mean absolute prediction error in runs.",
 "Covariance-adjusted distance from a multivariate centre.", "Conditional middle outcome; exp of fitted log response has this interpretation.",
 "Restricted specification contained within a larger one.", "Ordinary least squares minimises squared residuals.",
 "Observation unusual under an inspection rule; not necessarily erroneous.", "Compares observed eigenvalues with random-data references.",
 "Summarises input variation through uncorrelated component directions.", "Model-based interval for an individual outcome.",
 "Input known at the prediction time.", "Actual outcome minus fitted or predicted outcome.", "Square root of mean squared prediction error in runs.",
 "Multiplier used to construct a component/factor score from standardized inputs.", "Ordered numerical season position.",
 "Compares within-cluster closeness with nearest-alternative separation.", "Merges using the nearest pair.",
 "Spread of observations in the original units.", "Estimated uncertainty in an average or fitted quantity.",
 "Subtract training mean and divide by training SD.", "Residual rescaled using a case-deleted estimate of spread.",
 "Later season reserved for revised performance assessment.", "Earlier seasons used for fitted parameters and transformations.",
 "Feature-specific variance; a negative estimate signals an improper factor solution.", "Season used to choose among fitted candidates.",
 "Orthogonal rotation seeking simpler loading patterns.", "Weighted least squares uses positive case weights."))
glossary <- rbind(glossary, data.frame(term="Cook’s distance", definition="Joint fitted-value sensitivity to deleting a case."))
write_doc(c("# Glossary", "", table_md(glossary)), "docs/03_glossary.md")
write_doc(c("# Course alignment", "", "The supplied course directory is the authority for analytical scope.", "", table_md(rr("course_alignment")), "",
 "The verified preparation pipeline and basic chronological evaluation are retained by the student's explicit choices. Mathematical validity checks, reproducibility checks, logging and document rendering are software support.", "",
 "The reference examples sometimes contain undefined objects, local Windows paths, inconsistent filenames or interactive commands. The adaptation uses explicit data arguments, defined objects and portable paths. In mathematical notes, sample covariance notation may use a different denominator; cov() and cor() use R's sample convention consistently.", "",
 "Principal-axis FA is shown for every requested block, including the improper separate-block solutions. No other extraction method is substituted. FAMD is a reference for mixed data; the existing strength blocks are numeric, so it is not added to this study.", "",
 "Superseding decisions identify former analyses that are no longer part of the active study. Historical decision entries remain intact."), "docs/04_course_alignment.md")

manifest <- rr("figure_manifest") %>% arrange(id)
save_csv(rr("ratio_log") %>% group_by(label) %>% summarise(fits_checked=n(), minimum_N=min(N), maximum_p=max(p), all_pass=all(pass), .groups="drop"), "ratio_summary")
write_doc(c("# Figure index", "", table_md(manifest %>% select(filename, title, section))), "figures/INDEX.md")

short <- c("Predict actual first-innings totals after the toss and initial XI announcement, before any delivery.",
 "Ask whether context and player histories beat simple benchmarks, whether compression helps, and how diagnostics change interpretation.",
 paste("Read the chronological split:", paste(rr("split_summary")$split, rr("split_summary")$N, "innings", collapse="; ")),
 "Shortened innings remain part of the actual-total task. Outcomes and realised length are excluded from their own inputs.",
 "Inspect data, covariance and correlation, fit simple and multiple regression, then compare backward AIC and nested added terms as in class.",
 paste("PCA retains",dc$retained_pcs,"components and proper combined FA retains",dc$retained_factors,"factors. Saved training weights turn inputs into scores for regression."),
 "Influence prompts labelled sensitivity fits. Goldfeld–Quandt, log response and inverse-group-variance WLS examine unequal variance. Validation chooses a regression.",
 "Read the venue slope as an average association. The confidence band describes the fitted mean, while individual innings scatter around it.",
 "Compression explains input variation; validation error tests whether the resulting scores retain useful forecasting information. Separate FA blocks are improper.",
 "Clusters group venues, using standardized profiles and frozen centres. Membership tables compare average linkage with k-means.",
 "Read error, leverage and Cook influence separately. Training exclusions are sensitivity alternatives; every assessment innings remains included.",
 paste("Validation selected",selected$model,"with test RMSE",round(final$rmse,1),"runs. Nominal intervals cover",round(100*interval$empirical_coverage,1),"percent of test outcomes."),
 paste("MAE is",round(final$mae,1),"runs and predictive R-squared is",round(final$r2,3),". The model-based intervals under-cover, limiting precision."))
extensions <- c(
 "Define the target carefully. Runs include extras and shortened innings. The model uses only information available after the toss and the original roster announcement. Later impact-player choices are excluded. A score estimate can help an analyst compare an innings with its pre-match expectation, but omitted conditions prevent a causal interpretation of that comparison.",
 "Explain why each class topic has a purpose. Correlated player statistics motivate compression; venue profiles motivate grouping; regression links known inputs to the target. Outlier and variance diagnostics assess assumptions and sensitivity. Baselines establish the value of additional modelling. Success depends on observed prediction error rather than how sophisticated a method sounds.",
 "The split preserves the ordering of seasons. The latest two completed seasons supply validation and test. All learned means, SDs, score weights and cluster centres come from training. Earlier observed matches can update historical features during assessment, simulating forecasts made match by match. The test season was seen in the earlier implementation and this revision is not a new untouched experiment.",
 "Read the distribution before discussing models. The average describes a centre, and standard deviation describes variation across innings. Season means and venue boxplots reveal context differences. Low totals can arise from interruptions as well as poor batting. The pipeline records those outcomes for inspection while keeping them out of prediction inputs. Identity mappings preserve player and franchise histories.",
 "Use the class sequence: fit lm, inspect summary and confint, inspect residuals, then predict. Multiple regression holds other inputs fixed. Backward AIC removes terms when the criterion improves, and stepAIC verifies the same selection. Added interaction and squared terms start from the full model, retaining main effects. Post-selection significance is exploratory. Correlations and the coefficient-swing table make overlap visible.",
 "Walk through standardisation, weights and scores. For PCA, eigenvectors identify directions and eigenvalues measure input variation. Loadings differ from the weights used to compute the class function's unit-variance scores. FA uses principal-axis extraction with varimax and separates common variation from uniqueness. Negative uniqueness in the separate blocks is improper; only the proper combined solution supplies factor forecasts. Both score types enter an ordinary regression with context.",
 "A large residual is an unexpected score; leverage is an unusual input combination; influence describes changes in the fit if a case is removed. These are different questions. The class heteroscedasticity script motivates residual plots, Goldfeld–Quandt testing, log response and group-variance weighting. The inverse variances are training estimates. A clearer residual plot does not ensure better forecasts, so validation compares the alternatives.",
 "Use the equation to explain a slope in runs per extra run of earlier venue average. Coefficients describe associations rather than the causal effect of changing grounds. Mean confidence bands and individual prediction intervals have different purposes. Residual panels examine curvature, tails, spread and leverage. An intercept evaluated outside the observed input range is not a realistic cricket scenario.",
 "Compare the same validation targets across raw, component and factor regressions. Input variance explained does not measure target accuracy. The numerical learning-guide example multiplies standardized inputs by training weights and sums to create a score. The regression then multiplies scores and context by its coefficients and adds an intercept. Estimated factor scores can correlate even under an orthogonal latent model. Report improper solutions openly.",
 "Explain Euclidean distances after scaling. Single, complete and average linkage define different between-group distances. K-means iterates closest-centre assignments and updates means. The elbow and silhouette examine grouping, while a recorded maximum-silhouette rule chooses the count. Membership labels are arbitrary; use contingency tables to compare algorithms. New venues use earlier history and frozen centres, with a training-profile fallback when no history exists.",
 "Describe the saved thresholds as inspection references rather than proof of recording errors. Cook-influential training cases are omitted only in a labelled alternative, and shortened innings are excluded in another. Assessment remains common to all candidates. A case-removal model may reduce fitted residual spread and produce overly narrow classical intervals. Its point forecast and uncertainty must therefore be assessed separately.",
 "The final model was selected with validation error and retained before revised test metrics were computed. The smallest test error does not replace that choice. Prediction intervals come from predict.lm under model assumptions, not from an added calibration method. Nominal and empirical coverage are different. Substantial under-coverage means the reported individual-score uncertainty is inadequate for these test innings. State this limitation beside the point-error results.",
 "Answer the research questions from saved results. Compare error against both baselines and explain the weak predictive R-squared. Correlated histories, sparse player experience, inferred roles, shortened matches and changing seasons limit accuracy. Principal-axis factor assumptions fail in the separate blocks, and the selected model's classical intervals under-cover. A genuinely later season would provide new evidence. The contribution is a reproducible and understandable application of the supplied course methods.")
timing <- data.frame(slide=seq_along(short), seconds=c(30,35,45,35,50,55,45,45,55,40,50,65,50))
timing$cumulative_seconds <- cumsum(timing$seconds)
stopifnot(sum(timing$seconds)==60*rr("settings")$value[rr("settings")$key=="short_talk_minutes"])
save_csv(timing,"talk_timing")
slide_titles <- sub("^## ","",readLines(here::here("presentation","slides.Rmd"))[grepl("^## ",readLines(here::here("presentation","slides.Rmd")))])
talk <- c("# Presentation talk track", "", "## Short delivery script", "", table_md(timing), "")
for (i in seq_along(short)) talk <- c(talk,paste0("### Slide ",i,": ",slide_titles[i]),"",short[i],"")
talk <- c(talk,"## Detailed speaker notes","","Use these notes for practice and questions; use the timed script for the presentation.","")
for (i in seq_along(short)) talk <- c(talk,paste0("### Slide ",i,": ",slide_titles[i]),"",short[i],"",extensions[i],"")
qa <- c("**Why actual totals?** The agreed target includes shortened matches; changing that target would change the question.",
 "**How is leakage prevented?** Strictly earlier dates, original XIs, fixed training transformations and independent historical reconstruction checks.",
 "**Why a time split?** Later matches should be predicted from earlier evidence. The revised test season was assessed previously.",
 "**How is the predictor limit checked?** Every design column, including dummy and score columns, is counted before fitting; internal selection fits are audited.",
 "**Are loadings and weights interchangeable?** No. Loadings describe an axis or factor; score weights calculate each match's numerical score.",
 "**How do PCA and FA predict runs?** They create scores; lm uses those scores and context to predict runs.",
 "**What does negative uniqueness mean?** An improper factor solution. The separate blocks are reported as such; the proper combined fit supplies forecasts.",
 "**Why not delete every flag?** A valid extreme is part of the task. Labelled training sensitivity fits are compared on unchanged assessment rows.",
 paste("**Which model won?** Validation chose",selected$model,". Test RMSE is",round(final$rmse,1),"runs; test ranks do not alter that choice."),
 paste("**Are the intervals reliable?** Observed coverage is",round(100*interval$empirical_coverage,1),"percent versus nominal",round(100*interval$nominal_coverage),"percent. They substantially under-cover."))
write_doc(c(talk,"## Likely professor questions","",paste0("- ",qa)),"presentation/talk_track.md")
save_csv(data.frame(slide=seq_along(short), detailed_words=sapply(seq_along(short),function(i) length(strsplit(paste(short[i],extensions[i]),"\\s+")[[1]]))),"speaker_note_lengths")
decision("D-025",9,"Teaching materials must regenerate the syllabus-aligned analysis.",
 "Edit only the generated documents; update their generator and source report/slides.",
 "Regenerate beginner chapters, mathematical PCA/FA prediction examples, course-source mappings, revised results and timed notes. Supersedes the former teaching method descriptions and evaluation narrative.",
 "A rebuild must reproduce the explanation as well as the models.",
 "Report the improper separate factor solutions and interval under-coverage. Historical decisions remain as provenance, not active method specifications.")
render_options <- if(dir.exists(here::here(".runtime","usr","share","pandoc","data")))
 list(pandoc_args=c("--mathml","--data-dir",here::here(".runtime","usr","share","pandoc","data"))) else list(pandoc_args="--mathml")
rmarkdown::render(here::here("report","final_report.Rmd"),output_options=render_options,quiet=TRUE,envir=new.env())
rmarkdown::render(here::here("presentation","slides.Rmd"),output_options=render_options,quiet=TRUE,envir=new.env())
phase_result(9,"Course-aligned documentation",c("course_coverage","course_alignment","speaker_note_lengths"),
 "The report, slides and guides regenerate from saved results and identify the source course examples.",
 "Explaining score construction and prediction makes the methods reviewable.",
 "What new season would provide genuinely new evidence?")
cat("Course-aligned documents rendered.\n")
