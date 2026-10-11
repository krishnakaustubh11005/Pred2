TASK
Build a complete, reproducible R project for a university Predictive Modelling course presentation. The study: predict a team's FIRST-innings total in IPL cricket using only information known before the innings starts.

The student must DEMONSTRATE these course topics, each applied with a clear purpose, diagnosed, interpreted and explained in plain language:

Introduction to R (import, cleaning, aggregation)
PCA
Factor Analysis (FA)
Cluster Analysis
Simple Regression
Multiple Regression
Outlier Detection
Heteroscedasticity
The student is also here to LEARN, so the quality of explanation matters as much as the code.

WORKING RULES
Language is R. Run Rscript --version first. If R is missing, stop and tell the student how to install it. Do not switch languages.
Work in the phases below. After EVERY phase: run the code from a clean state, fix all errors, append to DECISIONS.md and RESULTS.md, then git commit with the message 'Phase N: short description' (git init in phase 0).
NEVER invent numbers. Every number in any document comes from code output (inline R in Rmd files, or read from results/*.csv). If it was not computed, do not state it.
Do not ask the student questions unless you are blocked (for example the data cannot be downloaded). Otherwise choose a sensible default and log it in DECISIONS.md.
Report honestly. Weak or surprising results are fine. Explain them, never hide them.
set.seed(42) in every script that uses randomness. Save sessionInfo() to results/session_info.txt.
Code style: tidyverse, small functions in R/, one numbered script per step, comments that explain WHY, no absolute paths (use here::here()).
Keep raw data out of git (.gitignore data/raw/).
HARD CONSTRAINTS
The 1:10 rule
For every regression, number of predictors p must satisfy p <= N/10. Count every dummy, principal component, factor score and interaction term as one predictor. Apply the rule to the CANDIDATE pool as well as the final model. Implement check_ratio(N, p, label) in R/checks.R: it must stop() with a clear message when violated and append (label, N, p, N/10, pass) to results/ratio_log.csv. Call it before every lm() fit.

No leakage
Any feature for a match dated d is computed ONLY from data strictly before d. Use arrange() plus lag or cumulative functions. In R/checks.R write a test that recomputes 20 random rows by brute-force date filtering and asserts equality with the pipeline output. Run it inside run_all.R.

Time-based splitting, and PCA/FA/clustering fitted on training data only
Split by season, never randomly. Everything that is learned from data (means, standard deviations, PCA rotation, factor loadings, cluster centres, number of components, venue profiles) is fitted on the TRAINING seasons only and then applied unchanged to validation and test seasons.

FINAL REPORT FORMAT (MANDATORY)
report/final_report.Rmd renders to a self-contained HTML file with a floating table of contents and code hidden by default (with a show-code toggle). The body has EXACTLY these five numbered sections, in this order, and no other top-level sections:

Objective (Problem)
The question in plain English and why it is interesting (what would a team, analyst or fan do with a good prediction?).
3 to 4 specific research questions, a one-line definition of success, and what is out of scope.
Data description (overview)
Source, time span, unit of observation (one first innings), N, target definition.
A variable dictionary table: name, plain description, type, units, how it is built, and 'known before the innings: yes'.
Cleaning summary (what was removed or fixed and how many rows), missing values, and the 1:10 rule table.
A timeline figure of the train, validation and test seasons.
3 exploratory figures (target distribution, trend over seasons, venue differences).
Methods used
One short subsection per course topic, in the order: Introduction to R pipeline, Simple regression, Multiple regression (with VIF and model selection), PCA, Factor Analysis, Cluster analysis, Outlier detection, Heteroscedasticity.
For each: what it does in 3 to 5 plain sentences, why we used it on this data (the problem it solves), the key formula, and the settings chosen (link the decision IDs).
Then evaluation: the time split, metrics (RMSE, MAE, R-squared) and baselines.
Results
Follow the analysis order. Each subsection starts with a one-sentence headline finding, then the figure(s), a compact table, a 'How to read this' note and a 'What it means' note.
End with a model comparison table and the final test-set evaluation.
Conclusion
Direct answers to each research question, the 3 to 5 key findings, limitations and honest caveats, practical meaning, and ideas for future work. Finish with a 3-sentence bottom line.
Things that do NOT go in the body (decision log, session info, glossary, learning guide) live in separate files and are linked from README.md. The slides in presentation/slides.Rmd follow the same five-part order.

PLOT STANDARDS (MANDATORY: plots must be easy to understand and look professional)
Build one shared theme and palette in R/plots.R and use it for every figure.

Message first: every plot has an ACTION TITLE that states the takeaway (for example 'Scores have climbed about X runs since the first season'), built with glue from computed values, plus a grey subtitle saying what is plotted. Never use a bare title such as 'Histogram of total'.
Clean look: theme_minimal(base_size = 14), light grid lines, no chart junk, large readable text, labelled axes with units, thousands separators, no overlapping labels (use ggrepel).
Colour: a colour-blind-safe palette (Okabe-Ito or viridis). Keep colour meaning consistent across the project (for example batting = one colour, bowling = another, cluster colours reused wherever clusters appear).
Direct labelling: label lines, clusters and key points directly instead of using large legends where possible. Annotate important points (for example the record innings, the elbow, the threshold) with short text.
Honest charts: no 3D, no pie charts, no dual axes, no truncated bars. Use transparency or hex binning against overplotting. Add uncertainty (ribbons or error bars) when showing fitted lines or estimates.
Reference lines: y = x on predicted-vs-actual, thresholds on diagnostics (Cook's distance 4/N, VIF 5 and 10, Kaiser line at 1), zero lines on residual plots.
Replace base-R diagnostic plots with custom ggplot versions arranged with patchwork, each panel with a plain-English subtitle (for example 'Points should hug the line').
Export PNG at 8 x 5 inches and 200 dpi (wide panels 11 x 5), white background, to figures/ with names f01_..., f02_... in report order.
A caption under each figure in the report: 'How to read this' (1 to 2 sentences) and 'What it means' (1 sentence).
After generating each figure, VIEW the PNG and fix overlapping text, clipped labels, unreadable fonts or confusing colours before moving on. Create figures/INDEX.md listing every figure, its message and the section where it is used.
PROJECT STRUCTURE
ipl-study1-innings-total/
README.md what this is, one-command run, folder map, troubleshooting
DECISIONS.md decision log (format below)
RESULTS.md results log (format below)
run_all.R runs everything from a clean state
R/ checks.R, features.R, plots.R, diagnostics.R, logging.R
scripts/ 00_setup.R, 01_get_data.R, 02_clean.R, 03_features.R, 04_eda.R, 05_regression.R, 06_pca_fa.R, 07_clustering.R, 08_outliers_hetero.R, 09_final_model.R
data/raw/ data/interim/ data/processed/ data/reference/
results/ figures/
docs/ 01_learning_guide.md, 02_walkthrough.md, 03_glossary.md
report/final_report.Rmd
presentation/slides.Rmd (ioslides) and talk_track.md

DECISIONS.md AND RESULTS.md
DECISIONS.md: numbered D-001, D-002 and so on, newest at the bottom. Each entry has Date, Phase, Context, Options considered (at least 2), Decision, Rationale in plain words, Consequences or risks, Status (active or superseded by D-xxx). Log every data filter, transformation, dropped variable, model choice, outlier treatment and deviation from this prompt. Never delete entries; supersede them.
RESULTS.md: organised by phase; for each analysis give what was run, key numbers copied from output, figure filenames, and a 2 to 3 sentence plain reading. End each phase with 'What I learned' and 'Open questions'. Helper log_run(model, formula, N, p, train_range, test_range, rmse, mae, r2, adj_r2, notes) appends a row to results/run_log.csv for every model.

PHASE 0: SETUP
git init, .gitignore, folder tree, README skeleton. scripts/00_setup.R checks and installs: tidyverse, here, lubridate, janitor, glue, ggrepel, patchwork, scales, viridis, psych, GPArotation, nFactors, factoextra, cluster, car, lmtest, sandwich, MASS, broom, olsrr, corrplot, knitr, rmarkdown. Confirm rmarkdown can render HTML (pandoc); if not, tell the student how to install it and log it.

PHASE 1: DATA AND CLEANING (Introduction to R)
Source: Cricsheet IPL ball-by-ball CSV (the ipl_csv2 archive on cricsheet.org/downloads). Download and unzip to data/raw/. Inspect the REAL columns and file layout first; do not assume them. Each match has a ball-by-ball file and an info file (teams, venue, date, toss, season, players).
Cleaning: standardise franchise renames (for example Delhi Daredevils to Delhi Capitals, Kings XI Punjab to Punjab Kings) through data/reference/team_names.csv; merge duplicate venue names through data/reference/venue_names.csv; remove super-over innings; flag no-result and D/L matches and log the counts. Save a data quality report to results/data_quality.csv (rows, missing values, seasons, date range).

PHASE 2: FEATURES (one row per first innings)
Target: first_innings_total (runs including extras); also keep log(total). Compute legal balls and wickets for each innings; flag curtailed = legal balls < 120 and wickets < 10. Do NOT drop curtailed innings yet; they are used in the outlier analysis.
Pre-match, leakage-safe features:

Venue: venue_avg_first_inn (expanding mean of earlier first innings there), venue_sd_first_inn, venue_prior_matches, venue_boundary_rate.
Context: season_index, toss_winner_batting_first. Add a home-team flag only if it is derivable, otherwise log the omission.
Batting team strength from the playing XI using each player's career-to-date numbers before the match: mean batting average, mean strike rate, mean boundary percentage, top-order (positions 1 to 3) strike rate, depth (number of XI with career strike rate above 125), and the team's mean first-innings total over its last 10 matches.
Opposition bowling strength (XI career-to-date): mean economy, mean bowling strike rate, mean dot-ball percentage, mean wickets per match, death-over economy.
Cold start: drop the first season as burn-in. Players with under 20 balls of history are shrunk to the league mean (log the rule).
About 15 to 25 numeric features. Check the ratio. Split: train = earlier seasons, validation = second-latest completed season, test = latest completed season, all detected from the data and logged. Use rolling-origin cross-validation inside the training seasons for model selection.

PHASE 3: EXPLORATION (script 04)
Figures: (f01) timeline of the split; (f02) distribution of totals with mean and median lines; (f03) average total by season as a line with a confidence ribbon and the record innings annotated; (f04) venue boxplots ordered by median (top venues only, readable labels); (f05) clustered correlation heatmap with the values printed, plus a short note on which groups of variables are collinear.

PHASE 4: REGRESSION (script 05)
Baselines first: B0 = training mean, B1 = venue_avg_first_inn. Report test RMSE, MAE, R-squared.
4.1 SIMPLE REGRESSION: total ~ venue_avg_first_inn on training data. Report slope, intercept, 95 percent CI, R-squared, residual standard error and a cricket-language interpretation. Figure (f06): scatter with fitted line, confidence band and the equation annotated. Figure (f07): custom four-panel diagnostics with plain-English panel subtitles.
4.2 MULTIPLE REGRESSION: full model on all candidate features. Coefficient table (broom), F-test, adjusted R-squared. VIF with figure (f08): horizontal bar chart with threshold lines at 5 and 10. Model selection by AIC and BIC (MASS::stepAIC). Partial F-tests for one interaction (venue_avg_first_inn x season_index) and one polynomial term (season_index squared); keep only if justified and log it. Show how coefficients swing when collinear variables enter. Figure (f09): coefficient dot-and-whisker plot.

PHASE 5: PCA AND FACTOR ANALYSIS (script 06)
Batting-strength and bowling-strength variables are analysed separately, then together. Standardise using training means and standard deviations.
5.1 PCA: eigenvalues, scree plot with the parallel-analysis line overlaid and the retained components highlighted (f10); cumulative variance; loadings as a labelled heatmap (f11); biplot with labelled arrows, points coloured by total (f12). Name each retained component in cricket terms. Then principal components regression with context features; compare VIF (should be near 1), adjusted R-squared and test RMSE with the raw model.
5.2 FACTOR ANALYSIS: KMO and Bartlett's test (interpret both). Number of factors by parallel analysis and the identifiability condition. Maximum likelihood with oblimin (main) and varimax (comparison). Loadings heatmap showing values above 0.3 (f13); communality and uniqueness bar chart (f14); factor correlation matrix. Name the factors. Factor scores into a regression.
5.3 A plain-language PCA-versus-FA comparison table (assumptions, purpose, result here) and a figure (f15) comparing coefficient estimates and test RMSE for the raw, PCR and FA models.

PHASE 6: CLUSTER ANALYSIS (script 07)
Venue profiles from TRAINING seasons only: average total, sd, boundary rate, matches. Standardise. Ward.D2 hierarchical clustering and k-means. Choose k with elbow, silhouette and gap statistic shown as a three-panel figure (f16). Coloured dendrogram (f17). Cluster profile figure (f18) as a heatmap or small-multiple bars with named clusters (for example 'batting paradises', 'bowler-friendly grounds'). Compare hierarchical vs k-means agreement. Use venue_cluster as a categorical predictor (this replaces dozens of venue dummies and respects the 1:10 rule; explain that in the text). New venues in the test set are assigned to the nearest training cluster.

PHASE 7: OUTLIERS AND HETEROSCEDASTICITY (script 08)
7.1 OUTLIERS on the best multiple regression: studentized residuals, leverage (hat values), Cook's distance, DFFITS, DFBETAS; cutoffs |studentized| > 3, leverage > 2(p+1)/N, Cook's D > 4/N; Mahalanobis distance on the feature space. Figures: influence bubble plot with leverage on x, studentized residual on y, bubble size = Cook's D and the worst innings labelled (f19); Cook's distance lollipop with threshold (f20). Table of flagged innings (match, venue, season, total, curtailed flag) with a cricket explanation for each. Refit three ways (all data, without curtailed innings, robust MASS::rlm) and compare with a coefficient plot (f21) and test RMSE. Decide keep, drop or flag for each treatment and log it.
7.2 HETEROSCEDASTICITY: residual-vs-fitted with a smoother (f22), residual spread by venue cluster and by season (f23). Tests: Breusch-Pagan, White, Goldfeld-Quandt. Remedies side by side: (a) log(total), (b) WLS with weights from a variance model (regress squared residuals on venue cluster and season, then weight by 1 / fitted variance), (c) robust standard errors (sandwich::vcovHC, HC3, with lmtest::coeftest). Figure (f24): residual plots before and after; figure (f25): standard errors, classical vs robust, as paired bars. Re-run the tests on the remedied model. Explain in plain words why prediction intervals widen at high-scoring grounds.

PHASE 8: FINAL MODEL (script 09)
Pick the final model on the validation season, evaluate ONCE on the test season. Report RMSE, MAE and R-squared against B0 and B1. Figures: predicted vs actual with the y = x line and 80 percent prediction intervals (f26); model comparison (baselines, simple, multiple, PCR, FA, final) with RMSE as a dot plot with uncertainty (f27); error by season (f28). Report empirical coverage of the intervals. State plainly what the model can and cannot do.

PHASE 9: DOCUMENTATION AND PRESENTATION
docs/01_learning_guide.md: one chapter per course topic, each with these headings: In one sentence; An everyday analogy; The idea step by step (light maths, every symbol defined); When to use it and when not; What we did in THIS project (link scripts and figures); How to read the output (annotated example from our real output); Common mistakes; Self-check questions (3, with short answers). Add a closing chapter 'How the techniques connect' telling the story from messy data to the final model.
docs/02_walkthrough.md narrates the study in order with decision IDs and real numbers. docs/03_glossary.md has every technical term in one line.
report/final_report.Rmd follows the five-part format above exactly, and knits without errors.
presentation/slides.Rmd (12 to 14 slides) in the same five-part order: Objective (2 slides), Data (2), Methods (3), Results (5 to 6, figure first with minimal text), Conclusion (1 to 2). presentation/talk_track.md has speaker notes (60 to 90 seconds per slide) and 10 likely professor questions with prepared answers drawn from our actual decisions and results.

FINAL VERIFICATION (do all of it and report the outcome)
Delete data/interim, data/processed, results and figures, then source('run_all.R') from a clean R session. It must finish without error and regenerate everything.
Render the report and slides. No knit errors, no missing figures.
ratio_log.csv shows all rows passing, and the leakage test passes.
Course coverage audit: print a table of the 8 topics with the script, figure numbers and report section where each appears. Fix any gap.
Figure audit: every figure has an action title, labelled axes, a caption and a row in figures/INDEX.md.
DECISIONS.md has entries for every phase, RESULTS.md has a section for every phase, and no document contains a number that is absent from results/.
Finish with a short summary for the student: what was built, headline results, the 5 most important decisions, and what to read first.
OPTIONAL STRETCH (only after everything passes; label it beyond the syllabus)
Turn predicted score differences into a win probability with logistic regression. One section and one figure, and say that logistic regression is not part of the course.
