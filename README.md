# dendRoAnalyst 2.0 – data and code for the manuscript

This repository contains the data and R code to reproduce the code examples and figures of

> Aryal, S., Grießinger, J., Häusser, M., Fan, Z.-X., Bräuning, A. (submitted). dendRoAnalyst 2.0: an expanded R package for preprocessing, integrating, modeling, and analyzing dendrometer with climate time series. *Dendrochronologia*.

The R package **dendRoAnalyst** (version 2.0.0 or later) is available on CRAN: <https://cran.r-project.org/package=dendRoAnalyst>.

## Contents

| Folder / file | Content |
|---|---|
| `data/tennenlohe_dendrometer_T1-T4.csv` | Raw dendrometer records of four *Pinus sylvestris* trees (T1–T4) at Tennenlohe, Germany, 30-min resolution, 30 January 2022 – 19 October 2023. The records contain the artificial jumps that are corrected in the manuscript. |
| `data/dwd_nuremberg_3668_hourly.csv` | Hourly climate data of the DWD station Nuremberg (station ID 3668), 1 December 2021 – 31 December 2023. |
| `R/01_manuscript_code.R` | All code blocks printed in the manuscript, in their order of appearance. They use the example datasets included in the package (`nepa17`, `gf_nepa17`, `ktm_clim_hourly`). |
| `R/02_prepare_tennenlohe.R` | Import, jump correction, gap filling, and all analyses of the Tennenlohe data used for the figures. |
| `R/03_figures.R` | Figures 2–4 and 7–16 (400 dpi, PNG and TIFF). |
| `R/04_figures_ABr_beta.R` | Figures 5 and 6 and Supplementary Figure S1 (ABr.value and the duration exponent β). |
| `run_all.R` | Runs all scripts in the correct order. |
| `vignette/dendRoAnalyst_vignettes.html` | Package vignette (also available on CRAN). |
| `output/` | Created by the scripts (analysis objects, figures, session information). |

Figure 1 (workflow flowchart) is a drawing and is not created with R.

## How to run

1. Install R (≥ 4.1.0) and the required packages:

   ```r
   install.packages(c("dendRoAnalyst", "cowplot", "ragg"))
   ```

2. Clone or download this repository and set the working directory to the repository root.

3. Run all scripts:

   ```r
   source("run_all.R")
   ```

   The complete run takes about 10–20 minutes on a desktop computer. The figures are written to `output/figures/`.

The code blocks in `R/01_manuscript_code.R` use the package datasets. Therefore, the numbers they print differ from those shown in the figures, which are based on the Tennenlohe data. Lines in the manuscript that require a user's own file path are commented out and marked with `# [user file]`.

## Data description

**Dendrometer data** (`;`-separated): `DATE` (dd.mm.yyyy), `TIME` (hh:mm:ss, UTC), and `T1`–`T4`, the dendrometer readings (mm) of the four trees. The data were previously used in Debel et al. (2024) and Foroozan et al. (2026) and were provided by the BayTreeNet project.

**Climate data** (`,`-separated): `TIME` (yyyy-mm-dd hh:mm:ss; values at midnight are given as date only), `Rain` (precipitation, mm h⁻¹; `-999` = missing), `RH` (relative humidity, %), `temp` (air temperature, °C), and `vpd` (vapor pressure deficit, hPa). In the scripts, `Rain` is renamed to `prec`, and `vpd` is converted to kPa and renamed to `VPD`.

Source of the climate data: Deutscher Wetterdienst (DWD), Climate Data Center (CDC), <https://opendata.dwd.de/climate_environment/CDC/observations_germany/>.

## References

- Debel, A., Foroozan, Z., Häusser, M., Raspe, S., Bräuning, A., 2024. Assessing intra-annual growth dynamics in climatically contrasting years, sites, and tree species using dendrometers and wood anatomical data. *Front. For. Glob. Change* 7, 1342413. https://doi.org/10.3389/ffgc.2024.1342413
- Foroozan, Z.P., Aryal, S., Häusser, M., Debel, A., Raspe, S., Bräuning, A., 2026. Growing through dry spells: Unveiling tolerance thresholds in three major tree species during soil water scarcity in Central Europe. *Agric. For. Meteorol.* 385, 111199. https://doi.org/10.1016/j.agrformet.2026.111199
- Aryal, S., Häusser, M., Grießinger, J., Fan, Z., Bräuning, A., 2020. "dendRoAnalyst": A tool for processing and analysing dendrometer data. *Dendrochronologia*, 125772. https://doi.org/10.1016/j.dendro.2020.125772

## License

See `LICENSE.md`. Code: GPL-3. Dendrometer data: CC BY 4.0. Climate data: DWD open-data terms of use (attribution required).

## Contact

Sugam Aryal, Institut für Geographie, Friedrich-Alexander-Universität Erlangen-Nürnberg (sugam.aryal@fau.de)
