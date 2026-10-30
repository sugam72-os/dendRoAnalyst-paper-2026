# =============================================================================
# Figure 3 (manuscript) and Figure S3 (supplementary material):
# ABr.value relationships and the effect of the duration exponent beta.
# The statistics of the relationships for the default beta = 1 that are given
# in the text are printed to the console.
# Uses output/tennenlohe_objects.RData created by 02_prepare_tennenlohe.R.
# Run from the repository root.
# =============================================================================
set.seed(1)  # reproducible jitter and random null distributions
suppressMessages({ library(dendRoAnalyst); library(ggplot2); library(cowplot) })
invisible(Sys.setlocale("LC_TIME", "English"))
load("output/tennenlohe_objects.RData"); pdf(NULL)
dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)

# ---- ABr.value vs. duration and maximum TWD (beta = 1; statistics in the text) --

z <- subset(zg$ZG_cycle, Phases == 1 & is.finite(ABr.value) & Duration_h > 0 & max.twd > 0)
z$Month <- factor(format(z$Start, "%b"), levels = month.abb)
month_cols <- c(Jan = "#1F4E9C", Feb = "#4393C3", Mar = "#92C5DE", Apr = "#A6DBA0", May = "#5AAE61",
                Jun = "#FDB863", Jul = "#F46D43", Aug = "#D73027", Sep = "#A6611A", Oct = "#DFC27D",
                Nov = "#8073AC", Dec = "#2D004B")
sup <- function(e) chartr("-0123456789", "\u207B\u2070\u00B9\u00B2\u00B3\u2074\u2075\u2076\u2077\u2078\u2079", as.character(e))
sci <- function(v) { e <- floor(log10(v)); if (e >= -2 && e <= 3) sprintf("%.3g", v) else paste0(sprintf("%.2f \u00D7 10", v / 10^e), sup(e)) }

rel_panel <- function(xvar, xlab) {
  d <- data.frame(x = z[[xvar]], y = z$ABr.value, Month = z$Month)
  st <- coef(lm(log10(10^y - 1 + 1e-6) ~ log10(x), data = d, subset = y > 0.05))
  m <- nls(y ~ log10(1 + 10^(la + b * log10(x))), data = d, start = list(la = unname(st[1]), b = unname(st[2])))
  cf <- summary(m)$coefficients
  r2 <- 1 - sum(resid(m)^2) / sum((d$y - mean(d$y))^2)
  pb <- cf["b", 4]
  ptxt <- if (pb < 0.001) "p < 0.001" else sprintf("p = %.3f", pb)
  rmse <- sqrt(mean(resid(m)^2)); rho <- cor(d$x, d$y, method = "spearman")
  nd <- data.frame(x = seq(min(d$x), max(d$x), length.out = 3000)); nd$fit <- predict(m, nd)
  lab <- sprintf("a = %s, b = %.2f\nR\u00B2 = %.2f, %s\nRMSE = %.2f, n = %d\nSpearman's \u03C1 = %.2f",
                 sci(10^cf["la", 1]), cf["b", 1], r2, ptxt, rmse, nrow(d), rho)
  cat(xvar, ":", gsub("\n", " | ", lab), "\n")
  ggplot(d, aes(x, y)) +
    geom_line(data = nd, aes(x = x, y = fit), colour = "grey20", linewidth = 1) +
    geom_point(aes(fill = Month), shape = 21, size = 2.6, colour = "grey15", stroke = 0.3, alpha = 0.9) +
    scale_fill_manual(values = month_cols, drop = TRUE, name = "Start month") +
    annotate("label", x = max(d$x), y = min(d$y), label = lab, hjust = 1, vjust = 0, size = 3.3 * 1.3, fill = "white") +
    labs(x = xlab, y = "ABr.value") + theme_bw(base_size = 12 * 1.3)
}
p1 <- rel_panel("Duration_h", "Duration of TWD phase (h)")
p2 <- rel_panel("max.twd", "Maximum TWD (mm)")

# ---- Figure 3: effect of the duration exponent beta ----------------------------

# TWD phases of tree T1; growing season at Tennenlohe = DOY 112-312 (Debel et al., 2024)
z <- subset(zg$ZG_cycle, Phases == 1 & ABr.value.raw > 0 & Duration_h > 0 & max.twd > 0)
doy <- as.integer(format(z$Start, "%j"))
gs_lab <- "Growing season (DOY 112\u2013312)"; dm_lab <- "Dormant season"
z$Season <- factor(ifelse(doy >= 112 & doy <= 312, gs_lab, dm_lab), levels = c(gs_lab, dm_lab))
abr_beta <- function(b) log10(1 + 100 * z$Avg.twd * z$max.twd * (z$Duration_h / 24)^b)
stopifnot(isTRUE(all.equal(abr_beta(1), z$ABr.value, tolerance = 1e-8)))

betas <- c(0, 0.25, 0.5, 1, 1.5)
blab <- c("0", "0.25", "0.5", "1 (default)", "1.5")
beta_cols <- setNames(c("#440154", "#3B528B", "#21908C", "#E6550D", "#B8860B"), blab)
long <- do.call(rbind, lapply(seq_along(betas), function(i) data.frame(beta = blab[i], D = z$Duration_h, M = z$max.twd,
                                                                      y = abr_beta(betas[i]), Season = z$Season)))
long$beta <- factor(long$beta, levels = blab)

fit_curve <- function(x, y) {
  d <- data.frame(x = x, y = y)
  st <- coef(lm(log10(10^y - 1 + 1e-6) ~ log10(x), data = d, subset = y > 0.05))
  m <- tryCatch(nls(y ~ log10(1 + 10^(la + b * log10(x))), data = d, start = list(la = unname(st[1]), b = unname(st[2]))), error = function(e) NULL)
  if (is.null(m)) return(NULL)
  nd <- data.frame(x = seq(min(x), max(x), length.out = 1500)); nd$fit <- predict(m, nd)
  list(curve = nd, r2 = 1 - sum(resid(m)^2) / sum((y - mean(y))^2))
}
panel <- function(xvar, xlab) {
  cv <- list(); st <- character()
  for (i in seq_along(blab)) {
    s <- long[long$beta == blab[i], ]; f <- fit_curve(s[[xvar]], s$y)
    if (!is.null(f)) { f$curve$beta <- blab[i]; cv[[i]] <- f$curve }
    st[i] <- sprintf("\u03B2 = %s: R\u00B2 = %s, \u03C1 = %.2f", sub(" \\(default\\)", "", blab[i]),
                     if (is.null(f)) "n.a." else sprintf("%.2f", f$r2), cor(s[[xvar]], s$y, method = "spearman"))
  }
  cv <- do.call(rbind, cv); cv$beta <- factor(cv$beta, levels = blab)
  cat(xvar, ":", paste(st, collapse = " | "), "\n")
  # white box with the full text hidden, then each line overlaid in the colour of its \u03B2 curve
  k <- length(st); bx <- max(long[[xvar]])
  p <- ggplot(long, aes(.data[[xvar]], y)) +
    geom_point(aes(colour = beta, shape = Season), size = 2.6 * 1.3, alpha = 0.75) +
    geom_line(data = cv, aes(x, fit, colour = beta), linewidth = 1.3) +
    annotate("label", x = bx, y = 0, label = paste(st, collapse = "\n"), hjust = 1, vjust = 0, size = fs,
             fill = "white", text.colour = "white", border.colour = "grey20")
  for (i in seq_len(k)) {
    li <- paste(c(rep(" ", i - 1), st[i], rep(" ", k - i)), collapse = "\n")
    p <- p + annotate("label", x = bx, y = 0, label = li, hjust = 1, vjust = 0, size = fs, fill = NA,
                      text.colour = beta_cols[[i]], border.colour = NA, fontface = "bold")
  }
  p + scale_colour_manual(values = beta_cols, name = "\u03B2") +
    scale_shape_manual(values = c(16, 17), name = "Start of TWD phase") +
    labs(x = xlab, y = "ABr.value") +
    theme_bw(base_size = 14 * 1.3) + theme(legend.text = element_text(size = 12 * 1.3), legend.title = element_text(size = 13 * 1.3))
}
fs <- 3.6 * 1.3
pa <- panel("D", "Duration of TWD phase (h)")
pb <- panel("M", "Maximum TWD (mm)")
leg <- get_legend(pa + theme(legend.position = "bottom", legend.box = "vertical") +
                    guides(colour = guide_legend(nrow = 1, override.aes = list(linewidth = 1.5, size = 4), order = 1),
                           shape = guide_legend(nrow = 1, override.aes = list(size = 4.5), order = 2)))
fig6 <- plot_grid(plot_grid(pa + theme(legend.position = "none"), pb + theme(legend.position = "none"),
                            ncol = 2, labels = c("a", "b"), label_size = 16 * 1.3),
                  leg, ncol = 1, rel_heights = c(1, 0.25))
ggsave("output/figures/Figure3_beta_effect.png", fig6, width = 11, height = 7.2, dpi = 400, bg = "white", device = ragg::agg_png)
ggsave("output/figures/Figure3_beta_effect.tiff", fig6, width = 11, height = 7.2, dpi = 400, bg = "white", device = ragg::agg_tiff, compression = "lzw")

# Supplementary Figure S3
ls_lab <- "Long, shallow phases (\u2265 100 h, max. TWD < 0.2 mm)"
ls <- z$Duration_h >= 100 & z$max.twd < 0.2
line_cols <- setNames(c("#D95F02", "#1F78B4", "#8C510A"), c(gs_lab, dm_lab, ls_lab))
line_types <- setNames(c("solid", "solid", "22"), c(gs_lab, dm_lab, ls_lab))
bs <- seq(0, 2, by = 0.05)
# shares are calculated from ABr.value.raw (summing log-compressed values is not meaningful)
abr_raw_beta <- function(b) z$Avg.twd * z$max.twd * (z$Duration_h / 24)^b
stopifnot(isTRUE(all.equal(abr_raw_beta(1), z$ABr.value.raw, tolerance = 1e-8)))
share <- do.call(rbind, lapply(bs, function(b) {
  v <- abr_raw_beta(b); s <- tapply(v, z$Season, sum) / sum(v)
  data.frame(beta = b, Group = c(names(s), ls_lab), share = c(as.numeric(s), sum(v[ls]) / sum(v)))
}))
for (b in c(0, 1, 1.5)) {
  s <- share[abs(share$beta - b) < 1e-9, ]
  cat(sprintf("beta = %.1f: shares of total ABr.value.raw: %s\n", b, paste(sprintf("%s %.2f%%", s$Group, 100 * s$share), collapse = "; ")))
}
cat(sprintf("mean ABr.value of long, shallow phases: beta = 1: %.2f, beta = 0: %.2f\n", mean(abr_beta(1)[ls]), mean(abr_beta(0)[ls])))
cat(sprintf("share of the five highest events in total ABr.value.raw (beta = 1): %.1f%%\n",
            100 * sum(sort(abr_raw_beta(1), decreasing = TRUE)[1:5]) / sum(abr_raw_beta(1))))
share$Group <- factor(share$Group, levels = c(gs_lab, dm_lab, ls_lab))
ps1 <- ggplot(share, aes(beta, 100 * share, colour = Group, linetype = Group)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey50") +
  annotate("text", x = 1, y = 100, label = "default \u03B2 = 1", hjust = -0.05, vjust = 1, size = 4.2, colour = "grey30") +
  geom_line(linewidth = 1.3) +
  scale_colour_manual(values = line_cols, name = NULL) + scale_linetype_manual(values = line_types, name = NULL) +
  coord_cartesian(ylim = c(0, 100)) +
  labs(x = "\u03B2 (duration exponent)", y = "Share of total ABr.value.raw (%)") +
  theme_bw(base_size = 14) + theme(legend.position = "bottom", legend.direction = "vertical", legend.key.width = unit(1.4, "cm"))
rk <- do.call(rbind, lapply(bs, function(b) { v <- abr_beta(b); o <- order(-v); data.frame(beta = b, rank = seq_along(o), id = o) }))
ids <- unique(rk$id[rk$rank <= 6]); rk <- subset(rk, id %in% ids)
rk$Season <- z$Season[rk$id]
rk$lab <- sprintf("%s (%.0f h, %.1f mm)", format(z$Start[rk$id], "%b %Y"), z$Duration_h[rk$id], z$max.twd[rk$id])
ps2 <- ggplot(rk, aes(beta, rank, group = id, colour = Season)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey50") + geom_line(linewidth = 1.2) +
  geom_text(data = subset(rk, beta == 2), aes(label = lab), hjust = -0.05, size = 3.8, show.legend = FALSE) +
  scale_y_reverse(breaks = 1:10) + coord_cartesian(ylim = c(10, 1), xlim = c(0, 3.2)) +
  scale_x_continuous(breaks = c(0, 0.5, 1, 1.5, 2)) +
  scale_colour_manual(values = line_cols[1:2], name = NULL) +
  labs(x = "\u03B2 (duration exponent)", y = "Rank of TWD phase by ABr.value") +
  theme_bw(base_size = 14) + theme(legend.position = "bottom")
figS1 <- plot_grid(ps1, ps2, ncol = 2, labels = c("a", "b"), label_size = 16, rel_widths = c(0.9, 1.2), align = "h", axis = "tb")
ggsave("output/figures/FigureS3_beta_sensitivity.png", figS1, width = 13, height = 6.5, dpi = 400, bg = "white", device = ragg::agg_png)
ggsave("output/figures/FigureS3_beta_sensitivity.tiff", figS1, width = 13, height = 6.5, dpi = 400, bg = "white", device = ragg::agg_tiff, compression = "lzw")
