set.seed(42)
options(mc.cores = 1) # psych's forked defaults otherwise change simulation streams.
blocks <- list(Batting = bat_features, Bowling = bowl_features, Combined = c(bat_features, bowl_features))
dimension_fits <- list(); eigen_tables <- list(); loading_tables <- list(); fa_checks <- list()
for (block in names(blocks)) {
  vars <- blocks[[block]]
  center <- colMeans(tr[, vars])
  spread <- sapply(tr[, vars], sd)
  if (any(spread <= 0)) stop("Constant strength feature in ", block)
  z <- scale(as.matrix(tr[, vars]), center = center, scale = spread)
  print(cor(z))

  # PCA class pattern: compare actual eigenvalues with random reference data.
  parallel <- psych::fa.parallel(z, fa = "both", fm = "pa", n.iter = 100,
    plot = FALSE, error.bars = FALSE)
  prcomp_fit <- prcomp(z, center = FALSE, scale. = FALSE)
  npc <- max(1, sum(prcomp_fit$sdev^2 > parallel$pc.sim))
  pca <- psych::principal(z, nfactors = npc, rotate = "none", scores = TRUE)
  print(unclass(pca$loadings))
  print(head(pca$scores))
  print(pca$weights)

  # principal returns unit-variance component scores. prcomp returns scores
  # with variance equal to the eigenvalues. Compare after that scale adjustment.
  reference <- sweep(prcomp_fit$x[, seq_len(npc), drop = FALSE], 2,
    prcomp_fit$sdev[seq_len(npc)], "/")
  signs <- sign(colSums(reference * pca$scores))
  reference <- sweep(reference, 2, signs, "*")
  stopifnot(isTRUE(all.equal(unname(reference), unname(pca$scores), tolerance = 1e-7)))

  # FA.R uses principal-axis extraction. The estimator must be able to identify
  # the requested number of factors; do not force an oversized parallel count.
  candidates <- seq_len(ncol(z) - 1)
  identifiable <- candidates[(ncol(z) - candidates)^2 >= ncol(z) + candidates]
  nf <- max(1, min(parallel$nfact, max(identifiable)))
  fa_none <- psych::fa(z, nfactors = nf, fm = "pa", rotate = "none", scores = "regression")
  fa <- psych::fa(z, nfactors = nf, fm = "pa", rotate = "varimax", scores = "regression")
  print(unclass(fa_none$loadings))
  print(unclass(fa$loadings))
  print(data.frame(communality = fa$communality, uniqueness = fa$uniquenesses))
  print(head(fa$scores))
  score_reconstruction <- max(abs(z %*% fa$weights - fa$scores))
  stopifnot(score_reconstruction < 1e-7)
  pca_reconstruction <- max(abs(z %*% pca$weights - pca$scores))
  pc_covariance <- cov(pca$scores)
  off_diagonal <- max(abs(pc_covariance - diag(diag(pc_covariance), nrow = npc)))
  fa_checks[[block]] <- tibble(block, variables = ncol(z), retained_pcs = npc, retained_factors = nf,
    parallel_factors = parallel$nfact, pca_variance = sum(pca$values[seq_len(npc)]) / sum(pca$values),
    fa_method = "principal axis", fa_rotation = "varimax", min_uniqueness = min(fa$uniquenesses),
    max_communality = max(fa$communality), boundary_warning = any(fa$uniquenesses <= .005),
    pca_score_error = pca_reconstruction, fa_score_error = score_reconstruction,
    pca_off_diagonal = off_diagonal, prcomp_score_error = max(abs(reference - pca$scores)))
  eigen_tables[[block]] <- tibble(block, component = seq_along(pca$values), eigenvalue = pca$values,
    parallel_eigenvalue = parallel$pc.sim, retained = component <= npc,
    cumulative_variance = cumsum(pca$values) / sum(pca$values))
  dimension_fits[[block]] <- list(vars = vars, center = center, spread = spread,
    pca = pca, npc = npc, fa = fa, fa_none = fa_none)
  loading_tables[[block]] <- as.data.frame(as.table(unclass(pca$loadings))) %>%
    setNames(c("variable", "component", "loading")) %>% mutate(block)
}
save_csv(bind_rows(fa_checks), "dimension_checks")
save_csv(bind_rows(eigen_tables), "pca_eigenvalues")
save_csv(bind_rows(loading_tables), "pca_loadings")
combined <- dimension_fits$Combined
pctr <- transform_strength(tr, combined, "PCA")
pcva <- transform_strength(va, combined, "PCA")
fatr <- transform_strength(tr, combined, "FA")
fava <- transform_strength(va, combined, "FA")

# Components and factors become ordinary numeric regression inputs.
pcr_formula <- model_formula(c(context_features, paste0("PCA", seq_len(combined$npc))))
check_ratio(nrow(pctr), length(context_features) + combined$npc, "PCA-score regression")
pcr <- lm(pcr_formula, data = pctr)
print(summary(pcr))
far_formula <- model_formula(c(context_features, paste0("FA", seq_len(ncol(combined$fa$weights)))))
check_ratio(nrow(fatr), length(context_features) + ncol(combined$fa$weights), "Factor-score regression")
far <- lm(far_formula, data = fatr)
print(summary(far))
register_model("PCR", pcr, pctr, pcva)
register_model("FA", far, fatr, fava)
models$PCR$transform <- "PCA"
models$FA$transform <- "FA"
save_csv(as.data.frame(as.table(combined$pca$weights)) %>%
 setNames(c("variable", "component", "weight")), "pca_score_weights")
save_csv(as.data.frame(as.table(combined$fa$weights)) %>%
 setNames(c("variable", "factor", "weight")), "fa_score_weights")
save_csv(pctr %>% select(match_id, starts_with("PCA")), "pca_training_scores")
save_csv(fatr %>% select(match_id, starts_with("FA")), "fa_training_scores")
eig <- bind_rows(eigen_tables)
p <- ggplot(eig, aes(component, eigenvalue)) + geom_line(colour = palette["batting"]) +
 geom_point(aes(colour = retained), size = 2) + geom_line(aes(y = parallel_eigenvalue), colour = palette["bowling"], linetype = "dashed") +
 geom_hline(yintercept = 1, colour = "grey50", linetype = "dotted") + facet_wrap(~block, scales = "free_x") +
 scale_colour_manual(values = c("FALSE" = "grey60", "TRUE" = unname(palette["batting"])), labels=c("Not retained","Retained")) + labs(x = "Component number", y = "Eigenvalue", colour = NULL)
save_plot(p, 10, "pca_scree", glue::glue("Parallel analysis retains {combined$npc} combined strength components"),
 "Solid eigenvalues exceed dashed random-data references; dotted line is the Kaiser reference", "Results: PCA", "Retained components explain more variation than the random-data reference.", "Training data decide the dimension before any held-out transformation.", TRUE)
rot <- unclass(combined$pca$loadings)
save_plot(heatmap_plot(rot), 11, "pca_loadings", glue::glue("Retained PCs explain {round(100*sum(combined$pca$values[seq_len(combined$npc)])/sum(combined$pca$values), 1)}% of strength variation"),
 "Training PCA loadings; signs describe direction along each axis", "Results: PCA", "Large absolute values identify the variables defining each component.", "Components summarise shared variation, not necessarily predictive signal.")
scores <- as_tibble(combined$pca$scores[, 1:2]); names(scores) <- c("PC1", "PC2"); scores$total <- tr$first_innings_total
arrows <- as.data.frame(unclass(combined$pca$loadings)[, 1:2]) %>% rownames_to_column("variable")
arrows$PC1 <- arrows$PC1 * 2; arrows$PC2 <- arrows$PC2 * 2
p <- ggplot(scores, aes(PC1, PC2, colour = total)) + geom_point(alpha = .35) + scale_colour_viridis_c(guide=guide_colourbar(barwidth=unit(5,"cm"))) +
 geom_segment(data = arrows, aes(x = 0, y = 0, xend = PC1, yend = PC2), inherit.aes = FALSE, arrow = arrow(length = unit(.1, "inches")), colour = "grey30") +
 ggrepel::geom_label_repel(data = arrows, aes(PC1, PC2, label = pretty_feature(variable)), inherit.aes = FALSE, size = 3, seed = 42, max.overlaps = Inf, max.time = Inf, max.iter = 10000, fill = "white") +
 labs(x = "Strength PC1 (standardised score)", y = "Strength PC2 (standardised score)", colour = "Total (runs)")
save_plot(p, 12, "pca_biplot", glue::glue("The leading two PCs explain {round(100*sum(combined$pca$values[1:2])/sum(combined$pca$values), 1)}% of variation"),
 "Training innings and loading arrows; arrows are rescaled for readability", "Results: PCA", "Nearby arrows identify related features; score colour is descriptive only.", "Outcome colour does not influence PCA fitting.")
loads <- unclass(combined$fa$loadings)
save_csv(as.data.frame(as.table(loads)) %>% setNames(c("variable", "factor", "loading")), "fa_loadings")
save_csv(as.data.frame(as.table(unclass(combined$fa_none$loadings))) %>% setNames(c("variable", "factor", "loading")), "fa_unrotated_loadings")
phi <- if(is.null(combined$fa$Phi)) diag(ncol(loads)) else combined$fa$Phi
save_csv(as.data.frame(as.table(phi)) %>% setNames(c("factor1", "factor2", "correlation")), "factor_correlations")
save_plot(heatmap_plot(loads, "Factor", "Strength feature", .3), 13, "fa_loadings", glue::glue("{ncol(loads)} latent factors summarise shared strength patterns"),
 "Principal-axis extraction with varimax; small loadings are left unlabelled", "Results: Factor Analysis", "Loadings connect observed measurements to estimated latent factors.", "Factors are statistical interpretations rather than directly observed abilities.")
cu <- tibble(variable = names(combined$fa$communality), communality = combined$fa$communality, uniqueness = combined$fa$uniquenesses)
save_csv(cu, "communalities")
p <- cu %>% pivot_longer(-variable, names_to = "part", values_to = "value") %>% ggplot(aes(value, variable, fill = part)) +
 geom_col(position = "stack") + scale_fill_manual(values = c(communality = unname(palette["batting"]), uniqueness = "grey75")) +
 scale_y_discrete(labels = pretty_feature) +
 labs(x = "Fraction of standardised variance", y = "Strength feature", fill = "Variance part")
save_plot(p, 14, "communalities", glue::glue("Average factor communality is {round(mean(cu$communality), 2)}"),
 "Shared factor variance and feature-specific variance", "Results: Factor Analysis", "Blue is the fraction explained by common factors; grey is uniqueness.", "Low communality means the factor model represents that variable poorly.")
comparison <- readr::read_csv(here::here("results", "validation_metrics.csv"), show_col_types = FALSE) %>% filter(model %in% c("Multiple AIC", "PCR", "FA"))
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
  bind_rows(name_axis(unclass(fit$pca$loadings),"PCA"),
            name_axis(unclass(fit$fa$loadings),"FA")) %>% mutate(block)
})), "dimension_names")
saveRDS(dimension_fits, here::here("results", "dimension_fits.rds"))
decision("D-020", 5, "PCA and FA must follow the course examples.",
 "Keep the former estimators; use principal and principal-axis fa with varimax.",
 "Use principal unrotated unit-variance scores, verify against prcomp, and compare unrotated with varimax principal-axis factors. Freeze training score weights. Supersedes D-010.",
 "These calls and the score construction match PCA class.R and FA.R.",
 "Loadings and score weights differ. Factor scores are estimates; varimax factor orthogonality does not guarantee orthogonal estimated scores. Boundary solutions are reported.")
phase_result(5, "Course-aligned PCA and Factor Analysis", c("dimension_checks", "dimension_names"),
 "Figures f10–f15 show training parallel analysis, loadings, scores, communalities and validation comparisons. Scores are reconstructed from saved weights.",
 "PCA summarises total variation; FA models shared variation plus uniqueness.", "Does compressing inputs retain useful predictive information?")
