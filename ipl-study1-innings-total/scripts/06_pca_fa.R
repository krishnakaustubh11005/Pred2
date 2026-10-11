set.seed(42)
options(mc.cores = 1) # psych's forked defaults otherwise change simulation streams.
blocks <- list(Batting = bat_features, Bowling = bowl_features, Combined = c(bat_features, bowl_features))
dimension_fits <- list(); eigen_tables <- list(); loading_tables <- list(); fa_checks <- list()
for (block in names(blocks)) {
  vars <- blocks[[block]]
  center <- vapply(tr[, vars], mean, numeric(1)); spread <- vapply(tr[, vars], sd, numeric(1))
  if (any(spread <= 0)) stop("Constant strength feature in ", block)
  z <- scale(as.matrix(tr[, vars]), center = center, scale = spread)
  pca <- prcomp(z, center = FALSE, scale. = FALSE)
  parallel <- psych::fa.parallel(z, fa = "both", fm = "ml", n.iter = 100, plot = FALSE, error.bars = FALSE)
  npc <- max(1, sum(pca$sdev^2 > parallel$pc.sim))
  candidates <- seq_len(ncol(z) - 1)
  identifiable <- candidates[(ncol(z) - candidates)^2 >= ncol(z) + candidates]
  nf <- max(1, min(parallel$nfact, max(identifiable)))
  fa <- psych::fa(z, nfactors = nf, fm = "ml", rotate = "oblimin", scores = "regression")
  varimax <- psych::fa(z, nfactors = nf, fm = "ml", rotate = "varimax", scores = "regression")
  bart <- psych::cortest.bartlett(cor(z), n = nrow(z)); kmo <- psych::KMO(cor(z))
  fa_checks[[block]] <- tibble(block, variables = ncol(z), retained_pcs = npc, retained_factors = nf,
    pca_variance = sum(pca$sdev[seq_len(npc)]^2) / sum(pca$sdev^2),
    KMO = kmo$MSA, Bartlett_statistic = bart$chisq, Bartlett_df = bart$df, Bartlett_p = bart$p.value,
    fa_df = fa$dof, fa_RMSEA = if(is.null(fa$RMSEA)) NA_real_ else fa$RMSEA[1],
    min_uniqueness = min(fa$uniquenesses))
  eigen_tables[[block]] <- tibble(block, component = seq_along(pca$sdev), eigenvalue = pca$sdev^2,
    parallel_eigenvalue = parallel$pc.sim, retained = component <= npc,
    cumulative_variance = cumsum(pca$sdev^2) / sum(pca$sdev^2))
  dimension_fits[[block]] <- list(vars = vars, center = center, spread = spread, pca = pca, npc = npc, fa = fa, varimax = varimax)
  loading_tables[[block]] <- as.data.frame(as.table(pca$rotation)) %>% setNames(c("variable", "component", "loading")) %>% mutate(block)
}
save_csv(bind_rows(fa_checks), "dimension_checks"); save_csv(bind_rows(eigen_tables), "pca_eigenvalues")
save_csv(bind_rows(loading_tables), "pca_loadings")
transform_strength <- function(data, fit, kind) {
  z <- scale(as.matrix(data[, fit$vars]), center = fit$center, scale = fit$spread)
  scores <- if(kind == "PCA") z %*% fit$pca$rotation[, seq_len(fit$npc), drop = FALSE] else z %*% fit$fa$weights
  scores <- as_tibble(scores); names(scores) <- paste0(kind, seq_len(ncol(scores)))
  bind_cols(data, scores)
}
combined <- dimension_fits$Combined
pctr <- transform_strength(tr, combined, "PCA"); pcva <- transform_strength(va, combined, "PCA")
fatr <- transform_strength(tr, combined, "FA"); fava <- transform_strength(va, combined, "FA")
pcr <- checked_lm(model_formula(c(context_features, paste0("PCA", seq_len(combined$npc)))), pctr, "PCR")
far <- checked_lm(model_formula(c(context_features, paste0("FA", seq_len(ncol(combined$fa$weights))))), fatr, "Factor score regression")
register_model("PCR", pcr, pctr, pcva); register_model("FA", far, fatr, fava)
models$PCR$transform <- "PCA"; models$FA$transform <- "FA"
save_csv(bind_rows(vif_table(pcr) %>% mutate(model = "PCR"), vif_table(far) %>% mutate(model = "FA")), "vif_dimensions")
eig <- bind_rows(eigen_tables)
p <- ggplot(eig, aes(component, eigenvalue)) + geom_line(colour = palette["batting"]) +
 geom_point(aes(colour = retained), size = 2) + geom_line(aes(y = parallel_eigenvalue), colour = palette["bowling"], linetype = "dashed") +
 geom_hline(yintercept = 1, colour = "grey50", linetype = "dotted") + facet_wrap(~block, scales = "free_x") +
 scale_colour_manual(values = c("FALSE" = "grey60", "TRUE" = unname(palette["batting"])), labels=c("Not retained","Retained")) + labs(x = "Component number", y = "Eigenvalue", colour = NULL)
save_plot(p, 10, "pca_scree", glue::glue("Parallel analysis retains {combined$npc} combined strength components"),
 "Solid eigenvalues exceed dashed random-data references; dotted line is the Kaiser reference", "Results: PCA", "Retained components explain more variation than the random-data reference.", "Training data decide the dimension before any held-out transformation.", TRUE)
rot <- combined$pca$rotation[, seq_len(combined$npc), drop = FALSE]
save_plot(heatmap_plot(rot), 11, "pca_loadings", glue::glue("Retained PCs explain {round(100*sum(combined$pca$sdev[seq_len(combined$npc)]^2)/sum(combined$pca$sdev^2), 1)}% of strength variation"),
 "Training PCA loadings; signs describe direction along each axis", "Results: PCA", "Large absolute values identify the variables defining each component.", "Components summarise shared variation, not necessarily predictive signal.")
scores <- as_tibble(combined$pca$x[, 1:2]); names(scores) <- c("PC1", "PC2"); scores$total <- tr$first_innings_total
arrows <- as.data.frame(combined$pca$rotation[, 1:2]) %>% rownames_to_column("variable")
arrows$PC1 <- arrows$PC1 * 4; arrows$PC2 <- arrows$PC2 * 4
p <- ggplot(scores, aes(PC1, PC2, colour = total)) + geom_point(alpha = .35) + scale_colour_viridis_c(guide=guide_colourbar(barwidth=unit(5,"cm"))) +
 geom_segment(data = arrows, aes(x = 0, y = 0, xend = PC1, yend = PC2), inherit.aes = FALSE, arrow = arrow(length = unit(.1, "inches")), colour = "grey30") +
 ggrepel::geom_label_repel(data = arrows, aes(PC1, PC2, label = pretty_feature(variable)), inherit.aes = FALSE, size = 3, seed = 42, max.overlaps = Inf, max.time = Inf, max.iter = 10000, fill = "white") +
 labs(x = "Strength PC1 (standardised score)", y = "Strength PC2 (standardised score)", colour = "Total (runs)")
save_plot(p, 12, "pca_biplot", glue::glue("The leading two PCs explain {round(100*sum(combined$pca$sdev[1:2]^2)/sum(combined$pca$sdev^2), 1)}% of variation"),
 "Training innings and loading arrows; arrows are rescaled for readability", "Results: PCA", "Nearby arrows identify related features; score colour is descriptive only.", "Outcome colour does not influence PCA fitting.")
loads <- unclass(combined$fa$loadings)
save_csv(as.data.frame(as.table(loads)) %>% setNames(c("variable", "factor", "loading")), "fa_loadings")
save_csv(as.data.frame(as.table(unclass(combined$varimax$loadings))) %>% setNames(c("variable", "factor", "loading")), "fa_varimax_loadings")
phi <- if(is.null(combined$fa$Phi)) diag(ncol(loads)) else combined$fa$Phi
save_csv(as.data.frame(as.table(phi)) %>% setNames(c("factor1", "factor2", "correlation")), "factor_correlations")
save_plot(heatmap_plot(loads, "Factor", "Strength feature", .3), 13, "fa_loadings", glue::glue("{ncol(loads)} latent factors summarise shared strength patterns"),
 "Maximum likelihood with oblimin; small loadings are left unlabelled", "Results: Factor Analysis", "Loadings connect observed measurements to estimated latent factors.", "Factors are statistical interpretations rather than directly observed abilities.")
cu <- tibble(variable = names(combined$fa$communality), communality = combined$fa$communality, uniqueness = combined$fa$uniquenesses)
save_csv(cu, "communalities")
p <- cu %>% pivot_longer(-variable, names_to = "part", values_to = "value") %>% ggplot(aes(value, variable, fill = part)) +
 geom_col(position = "stack") + scale_fill_manual(values = c(communality = unname(palette["batting"]), uniqueness = "grey75")) +
 scale_y_discrete(labels = pretty_feature) +
 labs(x = "Fraction of standardised variance", y = "Strength feature", fill = "Variance part")
save_plot(p, 14, "communalities", glue::glue("Average factor communality is {round(mean(cu$communality), 2)}"),
 "Shared factor variance and feature-specific variance", "Results: Factor Analysis", "Blue is the fraction explained by common factors; grey is uniqueness.", "Low communality means the factor model represents that variable poorly.")
comparison <- readr::read_csv(here::here("results", "validation_metrics.csv"), show_col_types = FALSE) %>% filter(model %in% c("Multiple selected", "PCR", "FA"))
coefs <- bind_rows(broom::tidy(raw) %>% mutate(model = "Raw"), broom::tidy(pcr) %>% mutate(model = "PCR"), broom::tidy(far) %>% mutate(model = "FA")) %>%
 filter(term %in% context_features) %>% mutate(estimate = estimate * vapply(term,function(v) sd(tr[[v]]),numeric(1)))
save_csv(coefs, "dimension_context_coefficients")
p1 <- ggplot(coefs, aes(estimate, term, colour = model)) + geom_point(position = position_dodge(width = .5)) +
 scale_colour_manual(values = setNames(unname(palette[c("batting","neutral","bowling")]),c("Raw","PCR","FA"))) +
 geom_vline(xintercept = 0, colour = "grey50") + labs(x = "Context effect per training SD (runs)", y = "Predictor")
p2 <- ggplot(comparison, aes(rmse, model)) + geom_point(colour = palette["batting"], size = 3) + labs(x = "Validation RMSE (runs)", y = "Model")
save_plot(p1 + p2, 15, "dimension_comparison", glue::glue("{comparison$model[which.min(comparison$rmse)]} has the lowest validation error in this comparison"),
 "Compare common context coefficients and validation accuracy; strength coefficients use different units", "Results: PCA versus FA", "Compare context effects across methods and RMSE on the same held-out season.", "Reducing dimensions is useful only if it preserves relevant information.", TRUE)
name_axis <- function(mat, kind) tibble(kind, axis = colnames(mat),
  strongest_feature = rownames(mat)[apply(abs(mat), 2, which.max)],
  interpretation = case_when(str_detect(strongest_feature,"^bat|^team") ~ "Batting pace and depth",
    strongest_feature == "bowl_economy" ~ "Bowling economy and run control",
    strongest_feature == "bowl_wickets_match" ~ "Bowling wicket threat",
    strongest_feature == "bowl_strike_rate" ~ "Wicket-taking efficiency and mixed strength",
    TRUE ~ "Bowling control and late-over pressure"))
save_csv(bind_rows(lapply(names(dimension_fits),function(block) {
  fit <- dimension_fits[[block]]
  bind_rows(name_axis(fit$pca$rotation[,seq_len(fit$npc),drop=FALSE],"PCA"),
            name_axis(unclass(fit$fa$loadings),"FA")) %>% mutate(block)
})), "dimension_names")
saveRDS(dimension_fits, here::here("results", "dimension_fits.rds"))
decision("D-010", 5, "Correlated strength measurements need interpretable reductions.", "Kaiser-only PCA and arbitrary factors; training parallel analysis with identifiable factor counts.",
 "Analyse batting, bowling and combined blocks; retain PCA components by parallel analysis; fit ML factors with oblimin and compare varimax. Apply training weights unchanged. Display numerical coefficient effects per training SD for comparability while keeping original estimates in tables.",
 "Parallel analysis compares signal with random variation; factor identifiability prevents an overparameterised latent model.", "FA assumptions may be weak and Heywood cases must be reported; context predictors can correlate with PCs, so overall PCR VIF need not be near unity.")
phase_result(5, "PCA and Factor Analysis", c("dimension_checks", "dimension_names"), "Figures f10–f15 describe component retention, loadings, score geometry, factor variance and model comparison. Latent summaries and original coefficients answer different questions.", "PCA explains total variation; FA models shared variation and leaves uniqueness.", "Do venue groups offer useful context beyond continuous venue history?")
