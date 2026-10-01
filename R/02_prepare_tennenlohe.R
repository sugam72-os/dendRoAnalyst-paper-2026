# =============================================================================
# Tennenlohe example: import, preprocessing, and analysis objects
# Creates output/tennenlohe_objects.RData, which is used by the figure scripts.
# Data: four Pinus sylvestris trees (T1-T4), 30-min dendrometer records,
#       2022-01-30 to 2023-10-19; hourly climate of the DWD station Nuremberg (ID 3668).
# Requires dendRoAnalyst >= 2.0.0. Run from the repository root.
# =============================================================================
library(dendRoAnalyst)
invisible(Sys.setlocale("LC_TIME", "English"))
dir.create("output", showWarnings = FALSE)
set.seed(1)

# ---- dendrometer data: import, jump correction, gap filling -----------------
dm_raw <- read.dendrometer("data/tennenlohe_dendrometer_T1-T4.csv",
                           date_col = "DATE", time_col = "TIME", tz = "UTC")
# artificial jumps (> 1 mm between consecutive observations) in all series
dm_jf <- jump.locator(df = dm_raw, detection_method = "manual", manual_threshold = 1)
dm_fill <- dm.na.interpolation(df = dm_jf, resolution = 30, fill = TRUE, method = "spline")
dm_na_fill <- dm_fill$data

# ---- climate data -------------------------------------------------------------
# precipitation uses -999 for missing values (handled by read.climate());
# VPD is provided in hPa and converted to kPa
clim_hourly <- read.climate("data/dwd_nuremberg_3668_hourly.csv", verbose = FALSE)
names(clim_hourly)[names(clim_hourly) == "Rain"] <- "prec"
names(clim_hourly)[names(clim_hourly) == "vpd"] <- "VPD"
clim_hourly$VPD <- clim_hourly$VPD / 10
clim_hourly <- clim_hourly[clim_hourly$TIME >= as.POSIXct("2021-12-01", tz = "UTC") &
                           clim_hourly$TIME < as.POSIXct("2024-01-01", tz = "UTC"), ]
clim_day <- dm_daily_clim(clim_hourly, mean_vars = c("temp", "VPD", "RH"),
                          max_vars = c("temp", "VPD"), sum_vars = c("prec"))

# ---- daily, stem-cycle, and zero-growth analyses (tree T1) -------------------
dd <- daily.data(df = dm_na_fill, TreeNum = 1)
sc <- phase.sc(df = dm_na_fill, TreeNum = 1, smoothing = 12)
zg <- phase.zg(df = dm_na_fill, TreeNum = 1, smoothing = 6)

# ---- climate attached to ZG phases -------------------------------------------
ZG_clim <- dm_add_climate(zg, clim_hourly, scale = "phase", mean_vars = c("temp", "VPD", "RH"),
                          max_vars = c("temp", "VPD"), sum_vars = c("prec"))

# ---- adverse periods (all four trees) ----------------------------------------
twd_out <- clim.twd(df = dm_na_fill, Clim = clim_day[, c("DATE", "prec_sum")], dailyValue = "max",
                    thresholdClim = "<0.1", thresholdDays = ">3", showPlot = FALSE)
twd_stats <- clim.twd.stats(x = twd_out, response = "full_period_change", group_by = "tree",
                            center = "median", conf_level = 0.95, doy_window = c(150, 250))

# ---- superposed epoch analysis ------------------------------------------------
ev <- dm_event_times(zg, event = "TWD_start")
ep <- dm_epoch_extract(events = ev, clim = clim_hourly, vars = c("temp", "VPD", "prec"),
                       lag_before = 24, lag_after = 24, unit = "hours")
ep_test <- dm_epoch_test(ep, statistic = "mean", null = "same_month")

# ---- seasonal growth fitting and detrending (trees T1 and T2) ----------------
fit1 <- dm.growth.fit(df = dm_na_fill, TreeNum = 1:2, method = "gompertz", year_mode = "yearly", verbose = FALSE)
det1 <- dm.detrend.fit(fit1)
ev_fit <- dm.growth.evaluate(df = dm_na_fill, TreeNum = 1:2, methods = c("gompertz", "richards", "loess", "gam"),
                             year_mode = "yearly", verbose = FALSE)

# ---- running correlations and wavelet analyses (tree T1) ---------------------
mc <- mov.cor.dm(df = dm_na_fill, Clim = clim_day, TreeNum = 1, win_size = 21, dm_stat = "amplitude",
                 clim_vars = c("temp_mean", "VPD_mean", "prec_sum"),
                 clim_fun = c(temp_mean = "raw", VPD_mean = "raw", prec_sum = "sum"),
                 lag_days = c(temp_mean = 0, VPD_mean = 0, prec_sum = 1),
                 accum_days = c(temp_mean = 1, VPD_mean = 1, prec_sum = 7))
wv <- dm_wavelet(x = dm_na_fill, TreeNum = 1, source = "raw", make_pval = TRUE, verbose = FALSE)
wc <- dm_wavelet_coherence(dm = dm_na_fill, clim = clim_hourly, TreeNum = 1, clim_vars = c("temp", "VPD"),
                           source = "raw", dm_fun = "mean", clim_funs = c(temp = "mean", VPD = "mean"),
                           loess_span = 0, make.pval = TRUE, n.sim = 10, verbose = FALSE)

save(dm_raw, dm_jf, dm_na_fill, clim_hourly, clim_day, dd, sc, zg, ZG_clim, twd_out, twd_stats,
     ev, ep, ep_test, fit1, det1, ev_fit, mc, wv, wc, file = "output/tennenlohe_objects.RData")
cat("Saved output/tennenlohe_objects.RData\n")
