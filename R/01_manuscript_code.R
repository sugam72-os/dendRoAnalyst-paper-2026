# =============================================================================
# Code printed in the manuscript
# Aryal et al. 'dendRoAnalyst 2.0: an expanded R package for preprocessing,
# integrating, modeling, and analyzing dendrometer data with climate time series'
#
# All code blocks are reproduced in the order in which they appear in the paper.
# They use the example datasets included in the package (nepa17, gf_nepa17,
# ktm_clim_hourly; Nepal Standard Time, UTC+05:45). Lines that need a user's
# own file path are commented out and marked with '# [user file]'.
# Requires dendRoAnalyst >= 2.0.1 (until it is on CRAN, install it from
# package/dendRoAnalyst_2.0.1.tar.gz; see README). The two wavelet analyses
# with 1000 simulations run for a long time; reduce n_sim for a quick test.
# =============================================================================


# ---- 2.3. Data import and temporal standardization -------------------------

set.seed(1)  # reproducible jitter and random null distributions
library(dendRoAnalyst)
# import dendrometer data
# dm_raw <- read.dendrometer("path/to/dendrometer_file.csv", tz = "UTC")  # [user file]
# import climate data
# clim_hourly <- read.climate(  # [user file]
#   "path/to/climate_file.csv",  # [user file]
#   vars = c("temp", "prec", "VPD", "RH"))  # [user file]
# alternatively, use the example datasets included in the package
data(nepa17)
data(gf_nepa17)
data(ktm_clim_hourly)
dm_raw <- nepa17
clim_hourly <- ktm_clim_hourly
# check the time resolution (in minutes)
reso_dm(dm_raw[[1]])


# ---- 2.4. Preprocessing and quality control --------------------------------

# detect and adjust jumps in all dendrometer series
# (differences larger than 1 mm between consecutive observations)
dm_jf <- jump.locator(
  df = dm_raw,
  detection_method = "manual",
  manual_threshold = 1)
# alternatively, use the automatic changepoint detection
dm_jf_auto <- jump.locator(df = dm_raw, detection_method = "auto")

# detect timestamp gaps without filling
dm_na_check <- dm.na.interpolation(
  df = dm_jf,
  resolution = 60,
  fill = FALSE)
# fill missing values using spline interpolation
dm_fill <- dm.na.interpolation(
  df = dm_jf,
  resolution = 60,
  fill = TRUE,
  method = "spline")
# the gap-filled time series is stored in the element 'data'
dm_na_fill <- dm_fill$data
# evaluate interpolation skill for different gap lengths
na_assess <- dm.na.interpolation(
  df = dm_jf,
  resolution = 60,
  fill = TRUE,
  method = "seasonal",
  assess = TRUE)
plot(na_assess, type = "assessment")

# create an artificial gap in the first series
df_gap <- dm_na_fill
df_gap[40:50, 2] <- NA
# fill the gap using a reference network
# (here, the gap-filled example series gf_nepa17)
dm_ni_prop <- network.interpolation(
  df = df_gap,
  referenceDF = gf_nepa17,
  niMethod = "proportional")
dm_ni_lin <- network.interpolation(
  df = df_gap,
  referenceDF = gf_nepa17,
  niMethod = "linear")

# truncate to one calendar year or a selected day-of-year window
dm_2017 <- dendro.truncate(df = dm_na_fill, CalYear = 2017, DOY = c(1, 365))
# aggregate the hourly series to daily maxima (coarser resolution)
dm_daily <- dendro.resample(df = dm_na_fill, by = "D", value = "max")
# interpolate the hourly series to 30-minute values (finer resolution)
dm_30min <- dendro.resample(df = dm_na_fill, by = "30M", method = "interpolate")


# ---- 2.5. Daily, stem-cycle, and zero-growth analyses ----------------------

dd <- daily.data(df = dm_na_fill, TreeNum = 1)
head(dd)
plot(dd)
plot(dd, type = "timing")
plot(dd, type = "boxplot", stat = "amplitude", by = "month_of_year")

sc <- phase.sc(df = dm_na_fill, TreeNum = 1, smoothing = 12)
head(sc$SC_cycle)
head(sc$SC_phase)
plot(sc)
plot(sc, type = "ribbon")
plot(sc, type = "boxplot", stat = "Magnitude", temporal = "monthly")

zg <- phase.zg(df = dm_na_fill, TreeNum = 1, smoothing = 6)
head(zg$ZG_cycle)
head(zg$ZG_phase)
head(zg$ZG_drought)
# rank TWD phases according to their ABr.value
twd_events <- subset(zg$ZG_cycle, Phases == 1)
head(twd_events[order(-twd_events$ABr.value),
  c("Start", "Duration_h", "max.twd", "Avg.twd",
    "ABr.value.raw", "ABr.value")])
plot(zg)
plot(zg, type = "twd")
plot(zg, type = "boxplot", stat = "ABr.value", temporal = "monthly")
# relationship between two phase variables with a linear fit
plot(zg, type = "scatter", source = "ZG_cycle",
  xvar = "max.twd", yvar = "ABr.value", fit = "linear")

twd_max <- twd.maxima(df = dm_na_fill, TreeNum = 1, smoothing = 5)
head(twd_max)


# ---- 2.6. Climate standardization, feature engineering, and attachment to dendrometer outputs ---

# standardize climate data
clim_std <- read.climate(clim_hourly, time_col = "TIME", verbose = FALSE)


# derive daily climate summaries
clim_day <- dm_daily_clim(
  clim_std,
  mean_vars = c("temp", "VPD", "RH"),
  max_vars  = c("temp", "VPD"),
  sum_vars  = c("prec")
)


# derive sub-daily climate features
clim_sub <- dm_subdaily_clim(
  clim_std,
  mean_vars = c("temp", "VPD", "RH"),
  sum_vars  = c("prec"),
  lag_vars  = c("temp", "VPD", "RH"),
  roll_hours = c(1, 3, 6, 24),
  lag_hours  = c(1, 3, 6, 24)
)

# attach daily climate to daily statistics
DD_clim <- dm_add_climate(
  dd,
  clim_hourly,
  scale = "daily",
  mean_vars = c("temp", "VPD", "RH"),
  max_vars  = c("temp", "VPD"),
  sum_vars  = c("prec")
)


# attach phase-window climate to ZG cycle output
ZG_clim <- dm_add_climate(
  zg,
  clim_hourly,
  scale = "phase",
  mean_vars = c("temp", "VPD", "RH"),
  max_vars  = c("temp", "VPD"),
  sum_vars  = c("prec")
)

# attach point-level subdaily climate features to SC phase output
SC_clim <- dm_add_climate(
  sc,
  clim_hourly,
  scale = "subdaily",
  sub_mean_vars = c("temp", "VPD", "RH"),
  sub_sum_vars  = c("prec"),
  sub_lag_vars  = c("temp", "VPD", "RH"),
  roll_hours = c(1, 3, 6, 24),
  lag_hours  = c(1, 3, 6, 24)
)

# examples of climate plotting
plot(ZG_clim,
   climate_var = "VPD_mean_phase",
   scale = "cycle", type = "boxplot")
plot(ZG_clim, scale = "cycle", type = "cor_heatmap",
   numeric_vars = c("Duration_h", "max.twd", "ABr.value",
                    "temp_mean_phase", "VPD_mean_phase",
                    "RH_mean_phase", "prec_sum_phase"))

# export climate-augmented outputs for further analyses
write.csv(DD_clim, "daily_dendrometer_climate.csv", row.names = FALSE)
write.csv(ZG_clim$ZG_cycle, "ZG_cycle_climate.csv", row.names = FALSE)
write.csv(SC_clim$SC_phase, "SC_phase_subdaily_climate.csv", row.names = FALSE)


# ---- 2.7. Event-based and adverse-period analyses --------------------------

twd_out <- clim.twd(
  df = dm_na_fill,
  Clim = clim_day[, c("DATE", "prec_sum")],
  dailyValue = "max",
  thresholdClim = "<0.1",
  thresholdDays = ">3",
  showPlot = FALSE)

twd_stats <- clim.twd.stats(
  x = twd_out,
  response = "full_period_change",
  group_by = "tree",
  center = "median",
  conf_level = 0.95,
  doy_window = c(1, 60))
plot(
  twd_stats,
  type = "id_metric",
  metric = "lag_to_return_zero",
  facet_by = "IDs")

evt_zg <- dm_event_climate(
  zg,
  clim_hourly,
  event = "phase_start",
  phase = "all",
  windows = c(0, 1, 3, 6, 12, 24),
  mean_vars = c("temp", "VPD", "RH"),
  max_vars  = c("temp", "VPD"),
  sum_vars  = c("prec")
)

head(evt_zg)

# summarize and test event-based climate
evt_sum <- dm_event_climate_summary(
  evt_zg,
  climate_var = "VPD_mean_prev_6h",
  group_var = "Phase",
  by = "month_of_year"
)

evt_test <- dm_event_climate_test(
  evt_zg,
  climate_var = "VPD_mean_prev_6h",
  group_var = "Phase",
  by = "month_of_year",
  method = "auto"
)

# illustrative structure for epoch analysis
ev <- dm_event_times(zg, event = "TWD_start")

ep <- dm_epoch_extract(events = ev, clim = clim_hourly,
                       vars = c("temp", "VPD", "prec"),
                       lag_before = 24, lag_after = 24,
                       unit = "hours")

ep_test <- dm_epoch_test(ep, statistic = "mean", null = "same_month")
plot(ep_test, type = "composite", show_ci = TRUE)
plot(ep_test, type = "difference")


# ---- 2.8. Seasonal growth fitting, detrending, and standardization ---------

# single-curve fit
fit1 <- dm.growth.fit(
  df = dm_na_fill,
  TreeNum = 1:2,
  method = "gompertz",
  year_mode = "yearly",
  verbose = FALSE
)

plot(fit1, type = "fit")
plot(fit1, type = "timing")

# bimodal fit
fit2 <- dm.growth.fit.double(
  df = dm_na_fill,
  TreeNum = 1,
  method = "gompertz",
  year_mode = "yearly",
  verbose = FALSE
)

det1 <- dm.detrend.fit(fit1)
head(det1$detrended_data)
plot(det1)
plot(det1, type = "detrended")

m_det <- mean_detrended.dm(det1)
head(m_det)

ev_fit <- dm.growth.evaluate(
  df = dm_na_fill,
  TreeNum = 1:2,
  methods = c("gompertz", "richards", "loess", "gam"),
  year_mode = "yearly",
  verbose = FALSE
)

head(ev_fit)
plot(ev_fit, metric = "rmse", type = "boxplot")
plot(ev_fit, metric = "r2", type = "mean")


# ---- 2.9. Running correlations, spectral analyses, and exploratory methods ---

mc <- mov.cor.dm(
  df = dm_na_fill,
  Clim = clim_day,
  TreeNum = 1,
  win_size = 21,
  dm_stat = "amplitude",
  clim_vars = c("temp_mean", "VPD_mean", "prec_sum"),
  clim_fun = c(temp_mean = "raw", VPD_mean = "raw", prec_sum = "sum"),
  lag_days = c(temp_mean = 0, VPD_mean = 0, prec_sum = 1),
  accum_days = c(temp_mean = 1, VPD_mean = 1, prec_sum = 7)
)

plot(mc, type = "heatmap")
plot(mc, type = "facet")

wv <- dm_wavelet(
  x = dm_na_fill,
  TreeNum = 1,
  source = "first_diff",
  make_pval = TRUE,
  method = "AR",
  n_sim = 1000,
  n_cores = 4,
  verbose = FALSE
)

plot(wv)

# extract or remove a diurnal band
rec_extract <- dm_wavelet_reconstruct(
  wv,
  mode = "extract",
  lower_hours = 20,
  upper_hours = 28,
  only_sig = TRUE
)

rec_remove <- dm_wavelet_reconstruct(
  wv,
  mode = "remove",
  lower_hours = 20,
  upper_hours = 28,
  only_sig = TRUE
)

wc <- dm_wavelet_coherence(
  dm = dm_na_fill,
  clim = clim_hourly,
  TreeNum = 1,
  clim_vars = "temp",
  source = "first_diff",
  dm_fun = "mean",
  clim_funs = c(temp = "mean"),
  loess_span = 0,
  upperPeriod = 720,
  make.pval = TRUE,
  method = "AR",
  n.sim = 1000,
  n_cores = 4,
  verbose = FALSE
)

plot(wc)
plot(wc, type = "cross_power")
plot(wc, type = "average_coherence")
plot(wc, type = "phase")


# ---- 2.11. Interactive Shiny application -----------------------------------

# install the optional packages required for the application (once)
# install.packages(c("shiny", "bslib", "DT", "shinyFiles"))  # [run interactively]
# launch the application
# dendroanalyst(working_dir = "path/to/dendrometer_project")  # [run interactively]

