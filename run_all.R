# =============================================================================
# Reproduce all code and figures of the manuscript
# Run from the repository root, e.g. source("run_all.R") or Rscript run_all.R
# =============================================================================
if (packageVersion("dendRoAnalyst") < "2.0.0") stop("Please install dendRoAnalyst >= 2.0.0 from CRAN.")
for (p in c("cowplot", "ragg")) if (!requireNamespace(p, quietly = TRUE)) stop("Please install the package '", p, "'.")

t0 <- Sys.time()
step <- function(f) {
  cat("\n=====", f, "=====\n")
  source(f, local = new.env(), echo = FALSE)
  cat(sprintf("----- finished %s after %.1f min\n", f, as.numeric(difftime(Sys.time(), t0, units = "mins"))))
}
step("R/01_manuscript_code.R")      # code printed in the paper (package example data)
step("R/02_prepare_tennenlohe.R")   # Tennenlohe data: preprocessing and analysis objects
step("R/03_figures.R")              # Figures 2-4 and 7-16
step("R/04_figures_ABr_beta.R")     # Figures 5, 6, and S1
writeLines(capture.output(sessionInfo()), "output/sessionInfo.txt")
cat("\nAll done. Figures are in output/figures/\n")
