# =============================================================================
# Figures 2-4 and 7-16 of the manuscript (400 dpi, PNG and TIFF)
# Uses output/tennenlohe_objects.RData created by 02_prepare_tennenlohe.R.
# Figures 5, 6, and S1 are created by 04_figures_ABr_beta.R.
# Figure 1 (workflow flowchart) is a drawing and is not created with R.
# Run from the repository root.
# =============================================================================
suppressMessages({ library(dendRoAnalyst); library(ggplot2); library(cowplot) })
invisible(Sys.setlocale("LC_TIME", "English"))
load("output/tennenlohe_objects.RData")
dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)
pdf(NULL)

gg <- function(p, ...) { if (inherits(p, "ggplot")) p + labs(...) else p }
save_fig <- function(p, name, w, h) {
  f <- file.path("output/figures", name)
  ggsave(paste0(f, ".png"), p, width = w, height = h, dpi = 400, bg = "white", device = ragg::agg_png)
  ggsave(paste0(f, ".tiff"), p, width = w, height = h, dpi = 400, bg = "white", device = ragg::agg_tiff, compression = "lzw")
  cat("saved", name, "\n")
}
run <- function(name, expr) tryCatch(expr, error = function(e) cat("ERROR", name, ":", conditionMessage(e), "\n"))
yr <- 2023

# Figure 2: daily.data()
run("fig2", {
  p1 <- gg(plot(dd), y = "Stem radius (mm)", x = "Date")
  p2 <- gg(plot(dd, type = "timing", Year = yr, DOY = c(51, 59)), y = "Hour of day", x = "Date")
  p3 <- gg(plot(dd, type = "boxplot", stat = "amplitude", by = "month_of_year"), y = "Daily amplitude (mm)")
  save_fig(plot_grid(plot_grid(p1, p2, ncol = 2, labels = c("a", "b")), p3, ncol = 1, labels = c("", "c")), "Figure02_daily_data", 9, 7)
})

# one colour per stem-cycle phase, used in all panels of Figure 3 (Increment always green)
sc_levels <- c("Shrinkage", "Expansion", "Increment")
sc_cols <- c(Shrinkage = "#D55E00", Expansion = "#0072B2", Increment = "#009E73")
sc_fill <- c(Shrinkage = "#F2B48C", Expansion = "#99C7E6", Increment = "#8FD6BF")

# Figure 3: phase.sc()
run("fig3", {
  p1 <- plot(sc, type = "points", Year = yr, DOY = c(150, 160))
  p1$layers[[2]]$data$Phases <- factor(p1$layers[[2]]$data$Phases, levels = sc_levels)
  p1 <- p1 + scale_colour_manual(values = sc_cols, name = "Phase", drop = FALSE) + labs(y = "Stem radius (mm)")
  p2 <- plot(sc, type = "ribbon", Year = yr, DOY = c(150, 160))
  p2$layers[[1]]$data$Phases <- factor(p2$layers[[1]]$data$Phases, levels = sc_levels)
  p2 <- p2 + scale_fill_manual(values = sc_fill, name = "Phase", drop = FALSE) + labs(y = "Stem radius (mm)")
  p3 <- plot(sc, type = "boxplot", stat = "Magnitude", temporal = "monthly")
  d3 <- p3$data
  d3 <- d3[as.integer(substr(as.character(d3$.period), 6, 7)) %in% 4:10, ]   # growing seasons only (April-October)
  d3$.phase <- factor(d3$.phase, levels = sc_levels)
  d3$.period <- droplevels(factor(d3$.period))
  p3$data <- d3
  p3$layers[[1]]$mapping <- aes(colour = .phase)                            # outline and outliers in phase colour
  p3 <- p3 + scale_fill_manual(values = sc_fill, name = "Phase") +
    scale_colour_manual(values = sc_cols, name = "Phase") +
    labs(y = "Magnitude (mm)", x = "Month",
         subtitle = "One observation per phase; grouped by phase start date (April–October)")
  save_fig(plot_grid(p1, p2, p3, ncol = 1, labels = c("a", "b", "c"), align = "v", axis = "lr"), "Figure03_phase_sc", 8, 9)
})
# Figure 7: phase.zg()
run("fig7", {
  p1 <- plot(zg) +
    scale_y_continuous(breaks = scales::breaks_pretty(n = 3)) +
    guides(colour = guide_legend(order = 1, title = "Phase"), fill = guide_legend(order = 2, title = NULL)) +
    labs(y = "Stem radius and TWD (mm)") + theme(axis.title.y = element_text(size = 13))
  p2 <- gg(plot(zg, type = "twd"), y = "Tree water deficit (mm)")
  p3 <- plot(zg, type = "boxplot", stat = "ABr.value", temporal = "monthly") +
    scale_fill_manual(values = c(TWD = scales::alpha("#d95f0e", 0.5)), name = "Phase") +
    labs(y = "ABr.value", x = "Month") + theme(legend.position = "top")
  save_fig(plot_grid(p1, p2, p3, ncol = 1, labels = c("a", "b", "c"), align = "v", axis = "lr", rel_heights = c(1.15, 1, 1)),
           "Figure07_phase_zg", 8, 10.5)
})

# Figure 8: climate attached to ZG phases
run("fig8", {
  p1 <- gg(plot(ZG_clim, climate_var = "VPD_mean_phase", scale = "cycle", type = "boxplot"), y = "Mean VPD within phase (kPa)") +
    theme(plot.margin = margin(5, 5, 25, 5))
  p2 <- plot(ZG_clim, scale = "cycle", type = "cor_heatmap",
             numeric_vars = c("Duration_h", "max.twd", "ABr.value", "temp_mean_phase",
                              "VPD_mean_phase", "RH_mean_phase", "prec_sum_phase")) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1), plot.margin = margin(20, 5, 5, 5))
  save_fig(plot_grid(p1, p2, ncol = 1, labels = c("a", "b"), rel_heights = c(1, 1.1)), "Figure08_zg_climate", 7.5, 9)
})

# Figure 9: clim.twd() / clim.twd.stats()
run("fig9", {
  ids <- c(11, 12)
  p1 <- plot(twd_stats, type = "trajectory", ids = ids)
  p1$layers <- c(geom_hline(yintercept = 0, linewidth = 0.9, colour = "grey20"), p1$layers)   # bold zero line behind the curves
  p1 <- p1 + labs(y = "Relative change (mm)")
  p2 <- plot(twd_stats, type = "id_metric", ids = ids, metric = "lag_to_return_zero", facet_by = "IDs") +
    facet_wrap(~IDs, ncol = 1, scales = "fixed") +                                          # same y range for both events
    labs(y = "Lag to return to zero (days)") + theme(axis.text.y = element_text(angle = 0))
  save_fig(plot_grid(p1, p2, ncol = 2, labels = c("a", "b"), rel_widths = c(1.3, 1)), "Figure09_clim_twd", 10, 5.5)
})

# Figure 10: superposed epoch analysis (package default titles)
run("fig10", {
  p1 <- plot(ep_test, type = "composite", show_ci = TRUE)
  p2 <- plot(ep_test, type = "difference") + labs(title = "Difference between observed\ncomposite and null mean", y = "Observed − null mean")
  save_fig(plot_grid(p1, p2, ncol = 2, labels = c("a", "b")), "Figure10_epoch", 10, 5.5)
})

# Figure 11: growth fit (onset, cessation, and active-growth period in panel b)
run("fig11", {
  p1 <- gg(plot(fit1, type = "fit", series = names(dm_na_fill)[2]), y = "Cumulative growth (mm)", x = "Date")
  p2 <- plot(fit1, type = "timing", series = names(dm_na_fill)[2])
  p2 <- p2 + labs(y = "Year") +
    scale_colour_discrete(labels = c("overall season" = "Growth onset to cessation (10–90% of growth)",
                                     "rate season" = "Active growth (10% of peak rate)"))
  save_fig(plot_grid(p1, p2, ncol = 1, labels = c("a", "b"), rel_heights = c(1.2, 0.8)), "Figure11_growth_fit", 8.5, 7.5)
})

# Figure 4: schematic of a TWD phase and the variables used for ABr.value
png("output/figures/Figure04_ABr_schematic.png", width = 2933, height = 1867, res = 400, family = "sans")
par(mar = c(2.2, 3.2, 0.6, 1), xpd = NA)
t0 <- 2; t1 <- 8.5; tp <- 6; top <- 7; low <- 3.8
tt <- seq(t0, t1, length.out = 400)
twd <- ifelse(tt <= tp, (top - low) * sin((tt - t0) / (tp - t0) * pi / 2)^1.3,
                        (top - low) * cos((tt - tp) / (t1 - tp) * pi / 2)^1.1)
y <- top - twd
avg <- mean(twd)
plot(NA, xlim = c(0, 10), ylim = c(2, 9.0), axes = FALSE, xlab = "", ylab = "")
arrows(0, 2, 10.1, 2, length = 0.08, lwd = 1.6); arrows(0, 2, 0, 9.4, length = 0.08, lwd = 1.6)
mtext("Time", side = 1, line = 0.6, cex = 1.1)
mtext("Stem radius (mm)", side = 2, line = 0.6, cex = 1.1)
polygon(c(tt[tt <= tp], rev(tt[tt <= tp])), c(y[tt <= tp], rep(top, sum(tt <= tp))), col = adjustcolor("#F4A582", 0.35), border = NA)
polygon(c(tt[tt >= tp], rev(tt[tt >= tp])), c(y[tt >= tp], rep(top, sum(tt >= tp))), col = adjustcolor("#A6DBA0", 0.35), border = NA)
lines(c(0.3, t0), c(top, top), lwd = 2); lines(c(t1, 9.6), c(top, top), lwd = 2)
lines(tt, y, lwd = 2)
segments(t0, top, t1, top, col = "#1B9E3A", lwd = 2, lty = 2)
text(9.7, top + 0.3, "measured stem radius", cex = 0.75, font = 3, adj = 1)
text(t0 + 1.6, top + 0.3, "GRO-line (phase.zg())", col = "#1B9E3A", cex = 0.8)
segments(t0, top - avg, t1, top - avg, col = "#2166AC", lwd = 1.8, lty = 3)
text(t1 + 0.1, top - avg, "mean TWD
(Avg.twd)", col = "#2166AC", cex = 0.75, adj = 0)
arrows(tp, top, tp, low, code = 3, length = 0.07, lwd = 1.5)
text(tp - 0.12, low + 0.9, "max.twd", cex = 0.8, font = 3, adj = 1)
points(c(t0, tp, t1), c(top, low, top), pch = 19, cex = 1)
for (v in c(t0, tp, t1)) segments(v, 2, v, 8.3, lty = 3, col = "grey40", lwd = 0.8)
text(t0, 8.55, "TWD phase start", cex = 0.78); text(tp, 8.55, "Time of maximum TWD", cex = 0.78); text(t1, 8.55, "TWD phase end", cex = 0.78)
text((t0 + tp) / 2 + 0.3, top - 0.9, "AUC.load", col = "#D6604D", cex = 0.78, font = 3)
text((tp + t1) / 2 - 0.2, top - 0.9, "AUC.recovery", col = "#1B7837", cex = 0.78, font = 3)
arrows(t0, 2.45, t1, 2.45, code = 3, length = 0.07, lwd = 1.2)
text((t0 + t1) / 2, 2.75, "TWD phase duration (Duration_h / 24 = duration.twd.days)", cex = 0.78)
dev.off()
cat("saved Figure04_ABr_schematic\n")

# Figure 12: detrended series
run("fig12", {
  p <- plot(det1, type = "detrended", series = names(dm_na_fill)[2], ncol = 1) +
    labs(y = "Detrended standardized index (dimensionless)")
  save_fig(p, "Figure12_detrended", 8, 6)
})
# Figure 13: growth-fit evaluation
run("fig11", {
  p1 <- gg(plot(ev_fit, metric = "r2", type = "mean"), y = expression(R^2))
  p2 <- gg(plot(ev_fit, metric = "rmse", type = "boxplot"), y = "RMSE (mm)")
  save_fig(plot_grid(p1, p2, ncol = 1, labels = c("a", "b")), "Figure13_growth_evaluation", 7, 8)
})
# Figure 14: running correlations
run("fig12", {
  p1 <- plot(mc, type = "heatmap")
  p2 <- gg(plot(mc, type = "facet"), y = "Correlation coefficient")
  save_fig(plot_grid(p1, p2, ncol = 1, labels = c("a", "b")), "Figure14_moving_correlation", 8, 9)
})
# Figure 15: wavelet power
run("fig13", {
  p <- plot(wv)
  save_fig(p, "Figure15_wavelet", 8, 5)
})
# Figure 16: wavelet coherence
run("fig14", {
  p1 <- plot(wc, type = "average_coherence")
  p2 <- plot(wc, type = "coherence")
  p3 <- plot(wc, type = "cross_power")
  save_fig(plot_grid(p1, p2, p3, ncol = 1, labels = c("a", "b", "c")), "Figure16_wavelet_coherence", 8, 11)
})
