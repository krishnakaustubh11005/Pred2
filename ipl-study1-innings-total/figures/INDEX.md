# Figure index



|filename                     |title                                                         |section                      |
|:----------------------------|:-------------------------------------------------------------|:----------------------------|
|f01_timeline.png             |16 seasons train the model before later evaluation            |Data                         |
|f02_totals.png               |Training scores average 165.8 runs                            |Data                         |
|f03_season_trend.png         |Season means change by 39.3 runs across training              |Data                         |
|f04_venue_totals.png         |Common venues span 18 runs in median score                    |Data                         |
|f05_correlation.png          |The strongest feature correlation reaches 0.92                |Results: exploration         |
|f06_simple_fit.png           |A higher venue mean predicts 0.31 runs per extra run          |Results: simple regression   |
|f07_simple_diagnostics.png   |Simple regression leaves residual SD of 31.9 runs             |Results: simple regression   |
|f08_vif.png                  |The full model's largest VIF is 11.1                          |Results: multiple regression |
|f09_coefficients.png         |6 predictors remain in the selected raw model                 |Results: multiple regression |
|f10_pca_scree.png            |Parallel analysis retains 3 combined strength components      |Results: PCA                 |
|f11_pca_loadings.png         |Retained PCs explain 68.1% of strength variation              |Results: PCA                 |
|f12_pca_biplot.png           |The leading two PCs explain 57.2% of variation                |Results: PCA                 |
|f13_fa_loadings.png          |3 latent factors summarise shared strength patterns           |Results: Factor Analysis     |
|f14_communalities.png        |Average factor communality is 0.59                            |Results: Factor Analysis     |
|f15_dimension_comparison.png |FA has the lowest validation error in this comparison         |Results: PCA versus FA       |
|f16_cluster_selection.png    |Silhouette favours 2 venue groups                             |Results: cluster analysis    |
|f17_venue_dendrogram.png     |Hierarchical and k-means agreement is 1                       |Results: cluster analysis    |
|f18_cluster_profiles.png     |Venue groups separate scoring levels across 2 profiles        |Results: cluster analysis    |
|f19_influence.png            |187 training innings trigger an influence check               |Results: outlier detection   |
|f20_cooks.png                |61 innings exceed the Cook's distance reference               |Results: outlier detection   |
|f21_outlier_treatments.png   |Three treatments compare sensitivity across 4 predictors      |Results: outlier detection   |
|f22_residual_mean.png        |Breusch-Pagan gives p = 0.011                                 |Results: heteroscedasticity  |
|f23_residual_spread.png      |Residual spread is compared across 2 venue groups and seasons |Results: heteroscedasticity  |
|f24_variance_remedy.png      |WLS uses a variance floor of 2.3 squared runs                 |Results: heteroscedasticity  |
|f25_robust_se.png            |The median HC3-to-classical SE ratio is 0.97                  |Results: heteroscedasticity  |
|f26_test_predictions.png     |WLS reaches test RMSE 41 runs                                 |Results: final evaluation    |
|f27_test_comparison.png      |The validation-selected model ranks 7 on test RMSE            |Results: final evaluation    |
|f28_season_error.png         |Season error ranges from 26.7 to 41 runs                      |Results: final evaluation    |
