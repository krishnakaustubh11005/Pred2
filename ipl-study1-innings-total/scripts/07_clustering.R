set.seed(42)
profiles <- tr %>% group_by(venue) %>% summarise(mean = mean(first_innings_total), sd = sd(first_innings_total),
 boundary = mean(boundary_rate), matches = n(), .groups = "drop") %>% mutate(sd = replace_na(sd, sd(tr$first_innings_total)))
profile_vars <- c("mean", "sd", "boundary", "matches")
center <- colMeans(profiles[, profile_vars]); spread <- vapply(profiles[, profile_vars], sd, numeric(1))
z <- scale(as.matrix(profiles[, profile_vars]), center = center, scale = spread)
rownames(z) <- profiles$venue
ks <- 2:min(6, nrow(z) - 1)
km <- lapply(ks, function(k) kmeans(z, centers = k, nstart = 50)); names(km) <- ks
selection <- tibble(k = ks, within_ss = vapply(km, function(x) x$tot.withinss, numeric(1)),
 silhouette = vapply(km, function(x) mean(cluster::silhouette(x$cluster, dist(z))[, 3]), numeric(1)))
gap <- cluster::clusGap(z, FUNcluster = function(x, k) list(cluster = kmeans(x, k, nstart = 20)$cluster), K.max = max(ks), B = 50)
selection$gap <- gap$Tab[ks, "gap"]; selection$gap_se <- gap$Tab[ks, "SE.sim"]
k <- selection$k[which.max(selection$silhouette)]; chosen <- km[[as.character(k)]]
# Sort names by scoring level so cluster colours keep a stable interpretation.
ordered <- order(chosen$centers[, "mean"])
rank_map <- setNames(seq_len(k), ordered)
profiles$cluster <- as.integer(rank_map[as.character(chosen$cluster)])
labels <- paste0("Scoring group ", seq_len(k)); labels[1] <- "Lower scoring"; labels[k] <- "Higher scoring"
profiles$cluster_name <- labels[profiles$cluster]
centers <- chosen$centers[ordered, , drop = FALSE]
hier <- hclust(dist(z), method = "ward.D2"); hc <- cutree(hier, k)
tab <- table(chosen$cluster, hc); choose2 <- function(x) x * (x - 1) / 2
expected <- sum(choose2(rowSums(tab))) * sum(choose2(colSums(tab))) / choose2(sum(tab))
ari <- (sum(choose2(tab)) - expected) / ((sum(choose2(rowSums(tab))) + sum(choose2(colSums(tab)))) / 2 - expected)
save_csv(selection, "cluster_selection"); save_csv(profiles, "venue_profiles")
save_csv(tibble(k, adjusted_rand_index = ari, silhouette = max(selection$silhouette), gap_recommended = cluster::maxSE(gap$Tab[, "gap"], gap$Tab[, "SE.sim"], method = "firstSEmax")), "cluster_summary")
cluster_fit <- list(profiles = profiles, center = center, spread = spread, centers = centers, labels = labels)
assign_cluster <- function(data, fit) {
  cluster <- fit$profiles$cluster_name[match(data$venue, fit$profiles$venue)]
  unseen <- which(is.na(cluster))
  for (i in unseen) {
    # New-venue profiles use only earlier-date history, never their current total.
    profile <- c(mean = data$venue_avg_first_inn[i], sd = data$venue_sd_first_inn[i],
                 boundary = data$venue_boundary_rate[i], matches = data$venue_prior_matches[i])
    if(data$venue_prior_matches[i] == 0) profile <- fit$center
    scaled <- (profile - fit$center) / fit$spread
    closest <- which.min(rowSums(sweep(fit$centers, 2, scaled, "-")^2))
    cluster[i] <- fit$labels[closest]
  }
  data$venue_cluster <- factor(cluster, levels = fit$labels); data
}
ctr <- assign_cluster(tr, cluster_fit); cva <- assign_cluster(va, cluster_fit)
cluster_model <- checked_lm(update(formula(raw), . ~ . + venue_cluster), ctr, "Raw with venue groups")
register_model("Multiple clusters", cluster_model, ctr, cva); models[["Multiple clusters"]]$cluster <- TRUE
selection_long <- selection %>% select(k, within_ss, silhouette, gap) %>% pivot_longer(-k, names_to = "criterion", values_to = "value")
selection_long <- bind_rows(selection_long,tibble(k=1L,criterion="gap",value=gap$Tab[1,"gap"])) %>%
 mutate(criterion=factor(criterion,levels=c("within_ss","silhouette","gap"),labels=c("Within-group variation","Silhouette separation","Gap versus random")))
p <- ggplot(selection_long, aes(k, value)) + geom_line(colour = palette["batting"]) + geom_point(colour = palette["batting"]) +
 geom_errorbar(data=tibble(k=seq_len(nrow(gap$Tab)),criterion=factor("Gap versus random",levels=levels(selection_long$criterion)),value=gap$Tab[,"gap"],low=gap$Tab[,"gap"]-gap$Tab[,"SE.sim"],high=gap$Tab[,"gap"]+gap$Tab[,"SE.sim"]),aes(ymin=low,ymax=high),width=.12,colour="grey55") +
 geom_vline(xintercept = k, linetype = "dashed", colour = palette["bowling"]) + facet_wrap(~criterion, scales = "free_y") +
 labs(x = "Number of venue clusters", y = "Criterion value")
save_plot(p, 16, "cluster_selection", glue::glue("Silhouette favours {k} venue groups"),
 "Elbow, silhouette and gap; dashed line shows the silhouette-based choice", "Results: cluster analysis", "Lower within-group variation and higher silhouette or gap support stronger grouping.", "Different criteria need not agree; the stated rule makes the choice reproducible.", TRUE)
# Convert the dendrogram to segments for the shared ggplot theme.
dend_segments <- function(h) {
  leaves <- setNames(seq_along(h$order), h$order); nodes <- list(); out <- list()
  for(i in seq_len(nrow(h$merge))) {
    child <- lapply(h$merge[i, ], function(j) if(j < 0) c(x = leaves[as.character(-j)], y = 0) else nodes[[j]])
    x <- mean(vapply(child, function(a) unname(a[1]), numeric(1))); y <- h$height[i]
    parent_height <- y
    for(a in child) out[[length(out)+1]] <- tibble(x = unname(a[1]), y = unname(a[2]), xend = unname(a[1]), yend = parent_height)
    out[[length(out)+1]] <- tibble(x = unname(child[[1]][1]), y, xend = unname(child[[2]][1]), yend = y)
    nodes[[i]] <- c(x = x, y = y)
  }; bind_rows(out)
}
segments <- dend_segments(hier); leaf <- tibble(x = seq_along(hier$order), venue = profiles$venue[hier$order], cluster = profiles$cluster_name[hier$order])
p <- ggplot(segments) + geom_segment(aes(x, y, xend = xend, yend = yend), colour = "grey45") +
 geom_point(data = leaf, aes(x, 0, colour = cluster), inherit.aes = FALSE, size = 3) +
 scale_x_continuous(breaks = leaf$x, labels = str_trunc(leaf$venue,22)) + scale_colour_viridis_d(end = .85) +
 labs(x = "Training venue (abbreviated; full names in venue profiles)", y = "Ward merge distance", colour = "K-means group") + theme(axis.text.x = element_text(angle = 65, hjust = 1, size = 7))
save_plot(p, 17, "venue_dendrogram", glue::glue("Hierarchical and k-means agreement is {round(ari, 2)}"),
 "Ward.D2 tree with leaf colours from k-means groups", "Results: cluster analysis", "Nearby venues merge earlier; leaf colours indicate the alternative grouping.", "Agreement measures whether two algorithms tell a similar venue story.", TRUE)
cp <- profiles %>% group_by(cluster_name) %>% summarise(across(all_of(profile_vars), ~base::mean(.x)), .groups = "drop")
mat <- scale(as.matrix(cp[, profile_vars]), center = center, scale = spread); rownames(mat) <- cp$cluster_name
save_plot(heatmap_plot(mat, "Venue profile measurement", "Venue group"), 18, "cluster_profiles", glue::glue("Venue groups separate scoring levels across {k} profiles"),
 "Group averages expressed relative to training venue means", "Results: cluster analysis", "Blue is above the training mean and orange below it.", "Match-count differences also influence these historical groups.")
saveRDS(cluster_fit, here::here("results", "cluster_fit.rds"))
decision("D-011", 6, "Venue categories need a small training-derived representation.", "Individual venue dummies; standardised venue-profile groups.",
 "Fit Ward.D2 and k-means on training profiles; choose k by maximum silhouette and report elbow and gap as supporting checks. Assign unseen venues to frozen nearest centres.",
 "Groups reduce the number of categorical predictors while allowing venue-context differences.", "Venue sample sizes affect profiles. Unseen venues with no history use the training overall profile; cluster names describe averages, not fixed ground qualities.")
phase_result(6, "Venue clustering", c("cluster_summary", "cluster_selection"), "Figures f16–f18 show cluster selection, algorithm agreement and profiles. Test outcomes play no part in fitting or assigning groups.", "Clustering groups similar measurements without using prediction labels.", "Which innings exert disproportionate influence on regression?")
