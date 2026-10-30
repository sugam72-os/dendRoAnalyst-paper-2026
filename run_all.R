# =============================================================================
# Reproduce all code and figures of the manuscript
# Run from the repository root, e.g. source("run_all.R") or Rscript run_all.R
# =============================================================================
if (packageVersion("dendRoAnalyst") < "2.0.1") {
  stop("Please install dendRoAnalyst 2.0.1: ",
       "install.packages(\"package/dendRoAnalyst_2.0.1.tar.gz\", repos = NULL, type = \"source\")")
}
for (p in c("cowplot", "ragg")) if (!requireNamespace(p, quietly = TRUE)) stop("Please install the package '", p, "'.")

t0 <- Sys.time()
step <- function(f, quick = FALSE) {
  cat("\n=====", f, "=====\n")
  code <- readLines(f, encoding = "UTF-8")
  # the printed wavelet examples use 1000 simulations; here they are run with
  # 100 simulations to save time (their p-values are not reported in the paper)
  if (quick) code <- sub("n_sim = 1000", "n_sim = 100", sub("n.sim = 1000", "n.sim = 100", code, fixed = TRUE), fixed = TRUE)
  eval(parse(text = code, encoding = "UTF-8"), envir = new.env())
  cat(sprintf("----- finished %s after %.1f min\n", f, as.numeric(difftime(Sys.time(), t0, units = "mins"))))
}
step("R/01_manuscript_code.R", quick = TRUE)  # code printed in the paper (package example data)
step("R/02_prepare_tennenlohe.R")             # Tennenlohe data: preprocessing and analysis objects
step("R/03_figures.R")                        # Figures 2, 4-8, S1, S2, and S4-S8
step("R/04_figures_ABr_beta.R")               # Figures 3 and S3
writeLines(capture.output(sessionInfo()), "output/sessionInfo.txt")
cat("\nAll done. Figures are in output/figures/\n")
