# Figure index



|filename                     |title                                                        |section                      |
|:----------------------------|:------------------------------------------------------------|:----------------------------|
|f01_timeline.png             |16 seasons train the model before later evaluation           |Data                         |
|f02_totals.png               |Training scores average 165.8 runs                           |Data                         |
|f03_season_trend.png         |Season means change by 39.3 runs across training             |Data                         |
|f04_venue_totals.png         |Common venues span 18 runs in median score                   |Data                         |
|f05_correlation.png          |The strongest feature correlation reaches 0.92               |Results: exploration         |
|f06_simple_fit.png           |A higher venue mean predicts 0.31 runs per extra run         |Results: simple regression   |
|f07_simple_diagnostics.png   |Simple regression leaves residual SD of 31.9 runs            |Results: simple regression   |
|f08_related_strength.png     |Batting pace and boundaries correlate at 0.92                |Results: multiple regression |
|f09_coefficients.png         |6 predictors remain in the selected raw model                |Results: multiple regression |
|f10_pca_scree.png            |Parallel analysis retains 3 combined strength components     |Results: PCA                 |
|f11_pca_loadings.png         |Retained PCs explain 68.1% of strength variation             |Results: PCA                 |
|f12_pca_biplot.png           |The leading two PCs explain 57.2% of variation               |Results: PCA                 |
|f13_fa_loadings.png          |3 latent factors summarise shared strength patterns          |Results: Factor Analysis     |
|f14_communalities.png        |Average factor communality is 0.59                           |Results: Factor Analysis     |
|f15_dimension_comparison.png |FA has the lowest validation error in this comparison        |Results: PCA versus FA       |
|f16_cluster_selection.png    |Silhouette favours 2 venue groups                            |Results: cluster analysis    |
|f17_venue_dendrogram.png     |Average linkage provides a second view of 2 venue groups     |Results: cluster analysis    |
|f18_cluster_profiles.png     |Venue groups separate scoring levels across 2 profiles       |Results: cluster analysis    |
|f19_influence.png            |333 training innings trigger an influence check              |Results: outlier detection   |
|f20_cooks.png                |54 innings exceed the Cook's distance reference              |Results: outlier detection   |
|f21_outlier_treatments.png   |Three training fits inspect sensitivity across 17 predictors |Results: outlier detection   |
|f22_residual_mean.png        |Goldfeld–Quandt gives p = 0.02                               |Results: heteroscedasticity  |
|f23_residual_spread.png      |Residual spread is compared across 2 venue groups            |Results: heteroscedasticity  |
|f24_variance_remedy.png      |WLS uses 2 training group variances                          |Results: heteroscedasticity  |
|f25_classical_se.png         |OLS and WLS summaries report uncertainty for 17 effects      |Results: heteroscedasticity  |
|f26_test_predictions.png     |Exclude influential reaches test RMSE 41 runs                |Results: final evaluation    |
|f27_test_comparison.png      |The validation choice ranks 6 on test error                  |Results: final evaluation    |
|f28_season_error.png         |Test error is 2.4 runs higher than validation                |Results: final evaluation    |
