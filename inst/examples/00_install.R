# For a source checkout, open tidystata.Rproj in RStudio.
# Restart R before installing, then restart again before the other scripts.
# If you only have an installed package, skip this file and start with script 01.
# Reference: https://r-pkgs.org/whole-game.html#install

# If devtools is not installed yet, run this once:
# install.packages("devtools")

# Install this local package, rather than an older online version.
devtools::install(".", build_vignettes = FALSE)

# After restarting R:
library(tidystata)
packageVersion("tidystata")
find.package("tidystata")

# You can now open 01_inspect_and_select.R and run its lines with Ctrl+Enter.
