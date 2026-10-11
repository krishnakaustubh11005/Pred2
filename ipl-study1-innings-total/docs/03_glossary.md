# Glossary



|term                        |definition                                                                                                        |
|:---------------------------|:-----------------------------------------------------------------------------------------------------------------|
|Adjusted R-squared          |Training fit adjusted for model size.                                                                             |
|Adjusted Rand index         |Chance-adjusted similarity of two cluster partitions.                                                             |
|AIC                         |Fit-versus-complexity criterion using a parameter penalty.                                                        |
|Bartlett's test             |Test of whether a correlation matrix is identity.                                                                 |
|Baseline                    |Simple reference prediction rule.                                                                                 |
|Batting average             |Bat runs per dismissal, with the project's finite-denominator and shrinkage rules.                                |
|BIC                         |Fit-versus-complexity criterion with sample-size-dependent penalty.                                               |
|Biplot                      |Plot of component scores and feature loading directions.                                                          |
|Bootstrap                   |Repeated resampling to estimate uncertainty.                                                                      |
|Boundary rate               |Fraction of deliveries or faced balls that are actual boundaries, as specified.                                   |
|Bowling economy             |Bowler-charged runs per over of legal deliveries.                                                                 |
|Bowling strike rate         |Legal balls per bowler-credited wicket, with finite-denominator handling.                                         |
|Breusch-Pagan               |Test linking squared residual variation with predictors.                                                          |
|Burn-in                     |Initial history excluded from modelling to support later features.                                                |
|Candidate pool              |All proposed predictors before selection.                                                                         |
|Cluster                     |Group of similar feature profiles.                                                                                |
|Coefficient                 |Estimated conditional association between an input and the response.                                              |
|Cold start                  |Little or no historical information.                                                                              |
|Collinearity                |Predictors that overlap strongly in their information.                                                            |
|Communality                 |Fraction of feature variance represented by common factors.                                                       |
|Confidence interval         |Range describing uncertainty about a mean relationship or parameter.                                              |
|Cook's distance             |Summary of an observation's effect on the fitted model.                                                           |
|Covariance                  |How two numerical measurements vary together.                                                                     |
|Curtailed innings           |Fewer scheduled legal balls without being all out.                                                                |
|Death overs                 |Final scheduled overs used for late-innings bowling rates.                                                        |
|Design matrix               |Numerical columns actually fitted, including dummy and transformed terms.                                         |
|DFBETAS                     |Coefficient change after removing a case, standardised by uncertainty.                                            |
|DFFITS                      |Standardised prediction change after removing a case.                                                             |
|Dot ball                    |Legal delivery on which no total runs are conceded in this study.                                                 |
|Dummy variable              |Indicator column representing one categorical contrast.                                                           |
|Eigenvalue                  |Variance along a component direction.                                                                             |
|Exchangeability             |Observations can be permuted without changing their joint distribution; temporal drift can break this.            |
|Extras                      |Runs outside the batter's bat runs, including wides, no-balls, byes and leg-byes.                                 |
|F-test                      |Variance-ratio test used to compare fitted regression explanations.                                               |
|Factor                      |Latent source of shared measurement variation.                                                                    |
|Factor loading              |Relationship between a measurement and a latent factor.                                                           |
|Factor score                |Estimated location of an observation along latent factors.                                                        |
|First innings               |The regular innings of the team batting first, excluding super overs.                                             |
|Gap statistic               |Clustering separation compared with random reference profiles.                                                    |
|Goldfeld-Quandt             |Variance comparison between ordered subsets.                                                                      |
|HC3                         |Leverage-adjusted robust coefficient covariance estimator.                                                        |
|Heteroscedasticity          |Conditional error variance differs among observations.                                                            |
|Identifiability             |Parameters can be uniquely estimated under the model's constraints.                                               |
|Interaction                 |Effect of one predictor depends on another.                                                                       |
|Intercept                   |Fitted mean when included numerical inputs and categorical contrasts are zero.                                    |
|K-means                     |Clustering by minimising squared distances to group centres.                                                      |
|Kaiser rule                 |Retain standardised components with eigenvalues above unity; used here only as a reference.                       |
|KMO                         |Measure of suitability for shared factor structure.                                                               |
|Leakage                     |Information unavailable at prediction time enters model construction.                                             |
|Legal ball                  |Delivery that is neither a wide nor a no-ball.                                                                    |
|Leverage                    |Unusualness of an observation's predictor combination.                                                            |
|Log likelihood              |Logarithm of the model's likelihood at its fitted parameters.                                                     |
|MAE                         |Mean absolute prediction error.                                                                                   |
|Mahalanobis distance        |Multivariate distance accounting for covariance.                                                                  |
|Maximum likelihood          |Fit parameters by maximising the model's likelihood.                                                              |
|Normality                   |Distributional shape assumption often examined using residual quantiles.                                          |
|Oblimin                     |Rotation allowing factors to correlate.                                                                           |
|OLS                         |Ordinary least squares minimises squared residuals.                                                               |
|Outlier                     |Observation unusual relative to a specified model or feature space.                                               |
|P-value                     |Probability of a test statistic at least as extreme under its null model.                                         |
|Parallel analysis           |Compare observed dimensions with random-data dimensions.                                                          |
|Partial F-test              |Nested-model test of whether added terms reduce residual variation enough.                                        |
|PCA                         |Principal components analysis summarises total variation.                                                         |
|PCR                         |Regression using principal component scores.                                                                      |
|Playing XI                  |Original team roster announced at the prediction time; later substitutes are excluded.                            |
|Polynomial term             |Nonlinear basis term such as a squared input.                                                                     |
|Prediction interval         |Range intended to describe a future individual outcome.                                                           |
|Predictive R-squared        |Improvement in squared error over the held-out outcome mean; can be negative.                                     |
|Rank deficiency             |Design columns contain redundant linear combinations, preventing unique coefficient estimates.                    |
|Residual                    |Observed outcome minus fitted or predicted outcome.                                                               |
|Residual standard error     |Training estimate of residual spread in outcome units.                                                            |
|RMSE                        |Root mean squared prediction error.                                                                               |
|RMSEA                       |Factor-model approximation-error measure per degree of freedom; smaller values indicate better approximate fit.   |
|Robust regression           |Fit that reduces the influence of large residuals.                                                                |
|Rolling origin              |Train on earlier seasons and assess on the next season.                                                           |
|Sample SD                   |Estimated spread around a sample mean in the variable's original units.                                           |
|Season split                |Chronological rather than random allocation of observations.                                                      |
|Shrinkage                   |Blend sparse individual history with earlier league information.                                                  |
|Silhouette                  |Measure of within-cluster closeness relative to separation.                                                       |
|Silhouette width            |Observation-level comparison of its cluster closeness and its nearest alternative cluster.                        |
|Slope                       |Change in fitted mean per unit change of an input.                                                                |
|Smearing                    |Training residual correction for exponentiating a log prediction.                                                 |
|Split conformal calibration |Use held-out residual quantiles to calibrate individual-outcome intervals, subject to distributional assumptions. |
|Standard error              |Estimated uncertainty in a coefficient or other fitted quantity.                                                  |
|Standardisation             |Subtract training means and divide by training standard deviations.                                               |
|Studentized residual        |Residual divided by its case-specific estimated uncertainty.                                                      |
|Temporal drift              |Data relationships or scoring conditions change over time.                                                        |
|Training data               |Earlier seasons used to fit coefficients and learned transformations.                                             |
|Uniqueness                  |Feature variance left outside the common-factor representation.                                                   |
|Validation                  |Held-out season used for final model selection.                                                                   |
|Variance                    |Average squared spread about a mean.                                                                              |
|Varimax                     |Rotation keeping factors orthogonal.                                                                              |
|Venue profile               |Training summary of a venue's scoring level, spread, boundaries and match count.                                  |
|VIF                         |Variance inflation from predictor overlap.                                                                        |
|Ward.D2                     |Hierarchical merging based on within-group squared variation.                                                     |
|White test                  |Auxiliary squared-residual test; this project uses fitted values and their square.                                |
|WLS                         |Weighted least squares using positive inverse-variance weights.                                                   |
