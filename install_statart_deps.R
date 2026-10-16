# install_statart_deps.R
# Run this script in R to install all dependencies needed for statart and its tests
# If a package fails to install, run the script again - it will skip already installed packages

# Set CRAN mirror
options(repos = c(CRAN = "https://cloud.r-project.org"))

# Function to safely install packages
safe_install <- function(pkgs) {
  for (pkg in pkgs) {
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
      message(paste0("Installing ", pkg, "..."))
      tryCatch({
        install.packages(pkg, dependencies = TRUE)
        if (require(pkg, character.only = TRUE, quietly = TRUE)) {
          message(paste0("✓ ", pkg, " installed successfully"))
        } else {
          message(paste0("✗ ", pkg, " installation may have failed"))
        }
      }, error = function(e) {
        message(paste0("✗ Error installing ", pkg, ": ", e$message))
      })
    } else {
      message(paste0("✓ ", pkg, " already installed"))
    }
  }
}

# Core packages (most important)
message("=== Installing Core Tidyverse Packages ===")
safe_install(c("magrittr", "tidyselect", "dplyr", "tidyr", "tibble",
               "stringr", "vctrs", "rlang", "purrr", "ggplot2", "pillar"))

# Data handling
message("\n=== Installing Data Handling Packages ===")
safe_install(c("haven", "hms", "datawizard", "readr", "readxl", 
               "vroom", "arrow", "jsonlite"))

# Table/Output packages
message("\n=== Installing Table/Output Packages ===")
safe_install(c("flextable", "htmlTable", "officer", "kableExtra", "openxlsx"))

# Statistics packages
message("\n=== Installing Statistics Packages ===")
safe_install(c("Hmisc", "Rfast", "broom", "broom.mixed", "lme4", "nnet", "ordinal"))

# Other packages
message("\n=== Installing Other Packages ===")
safe_install(c("rvest", "lifecycle", "testthat", "data.table"))

# Optional packages
message("\n=== Installing Optional Packages ===")
safe_install(c("bit64", "units", "sf"))

message("\n=== Installation Complete ===")
message("If any packages failed, close all R sessions and run this script again.")
