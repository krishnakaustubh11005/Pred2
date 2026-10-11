# Glossary



|term                 |definition                                                                             |
|:--------------------|:--------------------------------------------------------------------------------------|
|AIC                  |Likelihood-based fit/complexity criterion used for backward selection.                 |
|Adjusted R-squared   |Training fit measure adjusted for predictor count.                                     |
|Average linkage      |Merges clusters using average pairwise distance.                                       |
|Baseline             |Simple reference forecast used to judge added modelling value.                         |
|Boundary rate        |Historical fraction of delivery events producing actual boundaries.                    |
|Burn-in              |Earliest season supplying history before modelled innings.                             |
|Candidate pool       |All proposed predictor columns, including added terms and dummies.                     |
|Cluster              |Group of observations with similar measurements.                                       |
|Coefficient          |Estimated conditional effect of an included predictor.                                 |
|Communality          |Variance represented by common factors.                                                |
|Complete linkage     |Merges using the farthest pair.                                                        |
|Confidence interval  |Interval estimating an average or parameter under specified assumptions.               |
|Correlation          |Standardized linear co-movement of two variables.                                      |
|Covariance           |Average product of paired deviations from their means.                                 |
|DFBETAS              |Standardized coefficient sensitivity to deleting a case.                               |
|DFFITS               |Standardized fitted-value sensitivity to deleting a case.                              |
|Eigenvalue           |Variance along a component direction.                                                  |
|Eigenvector          |Direction satisfying the matrix eigenvalue equation.                                   |
|Factor               |Unobserved common source of covariance in an assumed model.                            |
|Factor score         |Estimated position computed from observed inputs and factor score weights.             |
|Goldfeld–Quandt      |Compares residual mean squares across two ordered segments.                            |
|Heteroscedasticity   |Error variance differs across observations or contexts.                                |
|Initial XI           |Original announced eleven players; later substitutes are excluded.                     |
|Interaction          |Term allowing one predictor's association to depend on another.                        |
|K-means              |Groups observations by repeatedly updating nearest-centre assignments.                 |
|Leverage             |Unusualness of an input combination in the fitted design.                              |
|Loading              |Association between a measurement and a component/factor; distinct from score weights. |
|MAE                  |Mean absolute prediction error in runs.                                                |
|Mahalanobis distance |Covariance-adjusted distance from a multivariate centre.                               |
|Median forecast      |Conditional middle outcome; exp of fitted log response has this interpretation.        |
|Nested model         |Restricted specification contained within a larger one.                                |
|OLS                  |Ordinary least squares minimises squared residuals.                                    |
|Outlier              |Observation unusual under an inspection rule; not necessarily erroneous.               |
|Parallel analysis    |Compares observed eigenvalues with random-data references.                             |
|PCA                  |Summarises input variation through uncorrelated component directions.                  |
|Prediction interval  |Model-based interval for an individual outcome.                                        |
|Predictor            |Input known at the prediction time.                                                    |
|Residual             |Actual outcome minus fitted or predicted outcome.                                      |
|RMSE                 |Square root of mean squared prediction error in runs.                                  |
|Score weight         |Multiplier used to construct a component/factor score from standardized inputs.        |
|Season index         |Ordered numerical season position.                                                     |
|Silhouette           |Compares within-cluster closeness with nearest-alternative separation.                 |
|Single linkage       |Merges using the nearest pair.                                                         |
|Standard deviation   |Spread of observations in the original units.                                          |
|Standard error       |Estimated uncertainty in an average or fitted quantity.                                |
|Standardisation      |Subtract training mean and divide by training SD.                                      |
|Studentized residual |Residual rescaled using a case-deleted estimate of spread.                             |
|Test set             |Later season reserved for revised performance assessment.                              |
|Training set         |Earlier seasons used for fitted parameters and transformations.                        |
|Uniqueness           |Feature-specific variance; a negative estimate signals an improper factor solution.    |
|Validation set       |Season used to choose among fitted candidates.                                         |
|Varimax              |Orthogonal rotation seeking simpler loading patterns.                                  |
|WLS                  |Weighted least squares uses positive case weights.                                     |
|Cook’s distance      |Joint fitted-value sensitivity to deleting a case.                                     |
