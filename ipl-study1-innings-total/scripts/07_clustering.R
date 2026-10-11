set.seed(42)
profiles <- tr %>% group_by(venue) %>% summarise(mean = mean(first_innings_total), sd = sd(first_innings_total),
 boundary = mean(boundary_rate), matches = n(), .groups = "drop") %>% mutate(sd = replace_na(sd, sd(tr$first_innings_total)))
profile_vars <- c("mean", "sd", "boundary", "matches")
center <- colMeans(profiles[, profile_vars]); spread <- vapply(profiles[, profile_vars], sd, numeric(1))
z <- scale(as.matrix(profiles[, profile_vars]), center = center, scale = spread)
rownames(z) <- profiles$venue
ks <- 2:min(6, nrow(z) - 1)
km <- lapply(ks, function(k) kmeans(z, centers = k, nstart = 25)); names(km) <- ks
selection <- tibble(k = ks, within_ss = vapply(km, function(x) x$tot.withinss, numeric(1)),
 silhouette = vapply(km, function(x) mean(cluster::silhouette(x$cluster, dist(z))[, 3]), numeric(1)))
k <- selection$k[which.max(selection$silhouette)]; chosen <- km[[as.character(k)]]
# Sort names by scoring level so cluster colours keep a stable interpretation.
ordered <- order(chosen$centers[, "mean"])
rank_map <- setNames(seq_len(k), ordered)
profiles$cluster <- as.integer(rank_map[as.character(chosen$cluster)])
labels <- paste0("Scoring group ", seq_len(k)); labels[1] <- "Lower scoring"; labels[k] <- "Higher scoring"
profiles$cluster_name <- labels[profiles$cluster]
centers <- chosen$centers[ordered, , drop = FALSE]
# Class examples compare linkage choices on the same scaled distances.
venue_distance <- dist(z, method = "euclidean")
hier_single <- hclust(venue_distance, method = "single")
hier_complete <- hclust(venue_distance, method = "complete")
hier <- hclust(venue_distance, method = "average")
hc <- cutree(hier, k = k)
print(table(chosen$cluster, hc))
print(chosen$centers)
print(chosen$size)
print(chosen$withinss)
comparison <- bind_rows(lapply(list(single = hier_single, complete = hier_complete, average = hier), function(tree) {
  as.data.frame(table(kmeans = profiles$cluster_name, hierarchical = cutree(tree, k = k)))
}), .id = "linkage")
save_csv(comparison, "cluster_membership_tables")
save_csv(selection, "cluster_selection")
save_csv(profiles, "venue_profiles")
save_csv(tibble(k, silhouette = max(selection$silhouette), main_linkage = "average", random_starts = 25), "cluster_summary")
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
cluster_formula <- update(formula(raw), . ~ . + venue_cluster)
check_ratio(nrow(ctr), ncol(model.matrix(cluster_formula, ctr)) - 1, "Multiple regression with venue groups")
cluster_model <- lm(cluster_formula, data = ctr)
print(summary(cluster_model))
register_model("Multiple clusters", cluster_model, ctr, cva); models[["Multiple clusters"]]$cluster <- TRUE
selection_long <- selection %>% select(k, within_ss, silhouette) %>%
 pivot_longer(-k, names_to = "criterion", values_to = "value") %>%
 mutate(criterion = factor(criterion, levels = c("within_ss", "silhouette"),
 labels = c("Within-group variation: elbow", "Silhouette separation")))
p <- ggplot(selection_long, aes(k, value)) + geom_line(colour = palette["batting"]) +
 geom_point(colour = palette["batting"]) + geom_vline(xintercept = k, linetype = "dashed", colour = palette["bowling"]) +
 facet_wrap(~criterion, scales = "free_y") + labs(x = "Number of venue clusters", y = "Criterion value")
save_plot(p, 16, "cluster_selection", glue::glue("Silhouette favours {k} venue groups"),
 "Classroom elbow and silhouette checks; dashed line marks the selected k", "Results: cluster analysis",
 "Within-group variation falls as k grows; larger silhouette means better separation.",
 "The recorded silhouette rule makes the choice reproducible.", TRUE)
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
 labs(x = "Training venue (abbreviated; full names in venue profiles)", y = "Average-linkage merge distance", colour = "K-means group") + theme(axis.text.x = element_text(angle = 65, hjust = 1, size = 7))
save_plot(p, 17, "venue_dendrogram", glue::glue("Average linkage provides a second view of {k} venue groups"),
 "Average-linkage tree with leaf colours from k-means groups", "Results: cluster analysis", "Nearby venues merge earlier; leaf colours indicate the alternative grouping.", "Membership tables compare the grouping methods without treating labels as ordered numbers.", TRUE)
cp <- profiles %>% group_by(cluster_name) %>% summarise(across(all_of(profile_vars), ~base::mean(.x)), .groups = "drop")
mat <- scale(as.matrix(cp[, profile_vars]), center = center, scale = spread); rownames(mat) <- cp$cluster_name
save_plot(heatmap_plot(mat, "Venue profile measurement", "Venue group"), 18, "cluster_profiles", glue::glue("Venue groups separate scoring levels across {k} profiles"),
 "Group averages expressed relative to training venue means", "Results: cluster analysis", "Blue is above the training mean and orange below it.", "Match-count differences also influence these historical groups.")
saveRDS(cluster_fit, here::here("results", "cluster_fit.rds"))
decision("D-021", 6, "Venue clustering must match the supplied class scripts.",
 "Keep the earlier choices; compare the linkage and k-means methods taught in class.",
 "Use scaled Euclidean profiles, single/complete/average linkage, k-means with the classroom random-start count, elbow and maximum silhouette. Compare memberships with tables. Supersedes D-011.",
 "These procedures appear in CA.R, cluster analysis.txt and the Utilities example.",
 "Clusters are descriptive. Small venue histories influence profiles; unseen venues retain the frozen-centre fallback.")
phase_result(6, "Course-aligned venue clustering", c("cluster_summary", "cluster_selection", "cluster_membership_tables"),
 "Figures f16–f18 show selection, the average-linkage tree and venue group profiles. All learned profiles and centres use training seasons.",
 "Clustering groups observations, while PCA and FA summarise variables.", "Do the venue groups improve validation forecasts?")
