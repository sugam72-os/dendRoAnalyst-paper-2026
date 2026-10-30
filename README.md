# dendRoAnalyst 2.0 – data and code for the manuscript

This repository contains the data and R code to reproduce the code examples and figures of

> Aryal, S., Grießinger, J., Häusser, M., Fan, Z.-X., Bräuning, A. (submitted). dendRoAnalyst 2.0: an expanded R package for preprocessing, integrating, modeling, and analyzing dendrometer data with climate time series. *Dendrochronologia*.

The code requires version 2.0.1 of the R package **dendRoAnalyst**. Version 2.0.0 is available on CRAN (<https://cran.r-project.org/package=dendRoAnalyst>). Version 2.0.1 will be submitted to CRAN once the minimum interval between CRAN updates has passed; until then, its source package is included in this repository (`package/dendRoAnalyst_2.0.1.tar.gz`).

## Contents

| Folder / file | Content |
|---|---|
| `data/tennenlohe_dendrometer_T1-T4.csv` | Raw dendrometer records of four *Pinus sylvestris* trees (T1–T4) at Tennenlohe, Germany, measured with band dendrometers (stem circumference), 30-min resolution, 30 January 2022 – 19 October 2023. The records contain the artificial jumps that are corrected in the manuscript. |
| `data/dwd_nuremberg_3668_hourly.csv` | Hourly climate data of the DWD station Nuremberg (station ID 3668), 1 December 2021 – 31 December 2023. |
| `R/01_manuscript_code.R` | All code blocks printed in the manuscript, in their order of appearance. They use the example datasets included in the package (`nepa17`, `gf_nepa17`, `ktm_clim_hourly`). |
| `R/02_prepare_tennenlohe.R` | Import, jump correction, gap filling, and all analyses of the Tennenlohe data used for the figures. |
| `R/03_figures.R` | Figures 2, 4–8 of the manuscript and Figures S1, S2, and S4–S8 of the Supplementary Material (400 dpi, PNG and TIFF). |
| `R/04_figures_ABr_beta.R` | Figure 3 and Supplementary Figure S3 (ABr.value and the duration exponent β); prints the statistics given in the text. |
| `run_all.R` | Runs all scripts in the correct order. |
| `package/dendRoAnalyst_2.0.1.tar.gz` | Source package of dendRoAnalyst 2.0.1 (passes `R CMD check --as-cran`). |
| `vignette/dendRoAnalyst_vignettes.html` | Package vignette (also available on CRAN). |
| `output/` | Created by the scripts (analysis objects, figures, session information). |

Figure 1 (workflow flowchart) is a drawing and is not created with R.

## How to run

1. Clone or download this repository and set the working directory to the repository root.

2. Install R (≥ 4.1.0), the CRAN version of dendRoAnalyst (which also installs all its dependencies), and the packages used for the figures. Then install version 2.0.1 from the source package in this repository:

   ```r
   install.packages(c("dendRoAnalyst", "cowplot", "ragg"))
   install.packages("package/dendRoAnalyst_2.0.1.tar.gz", repos = NULL, type = "source")
   packageVersion("dendRoAnalyst")   # should be 2.0.1
   ```

   Once version 2.0.1 is available on CRAN, the second line is no longer needed.

3. Run all scripts:

   ```r
   source("run_all.R")
   ```

   The figures are written to `output/figures/`. Most of the run time is spent on the significance tests of the two wavelet analyses (1000 Monte Carlo simulations each). They run in parallel on all but one of the available processor cores; with seven cores, the complete run takes several hours. For a quick test, reduce `n_sim` and `n.sim` in `R/02_prepare_tennenlohe.R`.

Some figures contain random elements: jittered points (Figures 5, S1, and S6), null distributions from randomly sampled times (Figure 6), and simulated significance tests (Figures 8 and S8). The scripts use a fixed random seed, but the positions of jittered points and the exact extent of the simulated significance regions can differ slightly from the published figures. All other results, including all statistics reported in the manuscript, are reproduced exactly.

The code blocks in `R/01_manuscript_code.R` use the package datasets. Therefore, the numbers they print differ from those shown in the figures, which are based on the Tennenlohe data. Lines in the manuscript that require a user's own file path are commented out and marked with `# [user file]`.

## Data description

**Dendrometer data** (`;`-separated): `DATE` (dd.mm.yyyy), `TIME` (hh:mm:ss, UTC without daylight saving time), and `T1`–`T4`, the dendrometer readings (mm) of the four trees. The trees were measured with high-resolution band dendrometers (DRL26, EMS Brno, Czech Republic), so the readings refer to stem circumference. The data were previously used in Debel et al. (2024) and Foroozan et al. (2026) and were provided by the BayTreeNet project.

**Climate data** (`,`-separated): `TIME` (yyyy-mm-dd hh:mm:ss, UTC; values at midnight are given as date only), `Rain` (precipitation, mm h⁻¹; `-999` = missing), `RH` (relative humidity, %), `temp` (air temperature, °C), and `vpd` (vapor pressure deficit, hPa). In the scripts, `Rain` is renamed to `prec`, and `vpd` is converted to kPa and renamed to `VPD`.

Source of the climate data: Deutscher Wetterdienst (DWD), Climate Data Center (CDC), <https://opendata.dwd.de/climate_environment/CDC/observations_germany/>.

## Version history

- **V1.2** (2026): updated to dendRoAnalyst 2.0.1 for the third revision of the manuscript. Wavelet analyses of first-differenced series with a red-noise null model and 1000 simulations, ABr shares calculated from `ABr.value.raw`, z-score detrending shown in Figure S5, new figure numbering (eight figures in the main text and eight in the Supplementary Material), and stem circumference in the axis labels.
- **V1.1** (2026): incomplete upload of V1.2, in which the updated R scripts and the source package of dendRoAnalyst 2.0.1 are missing. Please use V1.2.
- **V1.0** (2026): version for the second revision of the manuscript (dendRoAnalyst 2.0.0).

## References

- Debel, A., Foroozan, Z., Häusser, M., Raspe, S., Bräuning, A., 2024. Assessing intra-annual growth dynamics in climatically contrasting years, sites, and tree species using dendrometers and wood anatomical data. *Front. For. Glob. Change* 7, 1342413. https://doi.org/10.3389/ffgc.2024.1342413
- Foroozan, Z.P., Aryal, S., Häusser, M., Debel, A., Raspe, S., Bräuning, A., 2026. Growing through dry spells: Unveiling tolerance thresholds in three major tree species during soil water scarcity in Central Europe. *Agric. For. Meteorol.* 385, 111199. https://doi.org/10.1016/j.agrformet.2026.111199
- Aryal, S., Häusser, M., Grießinger, J., Fan, Z., Bräuning, A., 2020. "dendRoAnalyst": A tool for processing and analysing dendrometer data. *Dendrochronologia*, 125772. https://doi.org/10.1016/j.dendro.2020.125772

## License

See `LICENSE.md`. Code: GPL-3. Dendrometer data: CC BY 4.0. Climate data: DWD open-data terms of use (attribution required).

## Contact

Sugam Aryal, Institut für Geographie, Friedrich-Alexander-Universität Erlangen-Nürnberg (sugam.aryal@fau.de)
