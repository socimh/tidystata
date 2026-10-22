# Plain scripts for trying statart

For a source checkout, open `statart.Rproj` in RStudio and restart R before
installing. Start with `00_install.R`:

```r
devtools::install(".", upgrade = "never", build_vignettes = FALSE)
```

Restart R, open any numbered script, and run its lines with Ctrl+Enter. Each
script starts with `library(statart)`, creates its own small dataset, and calls
the package functions directly. Objects stay in your workspace for inspection.
There are no custom setup functions, test wrappers, or PASS/FAIL machinery.

After loading, run `packageVersion("statart")` and `find.package("statart")` to
confirm the version and location. Opening the source folder does not update an
older installed copy. Install again after changing package source.

`devtools::install()` installs the package from a local project directory.
Here `"."` means the current statart project. This follows the
[installation and plain usage workflow in R Packages](https://r-pkgs.org/whole-game.html#install).

If you already installed the version you want to try, skip `00_install.R`.
The scripts are also included in the installed package. Locate a script with
`system.file()` and open it in your editor, or run it directly:

```r
system.file("examples", "01_inspect_and_select.R", package = "statart")
source(system.file("examples", "02_frequency_tables.R", package = "statart"),
       echo = TRUE)
```

Run individual installed scripts this way from any working directory.
`run_all.R` is a convenience for the source checkout and assumes its project
root. The complete migration guide is at
`system.file("MIGRATION.md", package = "statart")`.

| Script | Contents |
| --- | --- |
| `00_install.R` | Install the local package, then load it and inspect its version/path. |
| `01_inspect_and_select.R` | Codebook, variable names/labels, searching, wildcards, selection and computed columns. |
| `02_frequency_tables.R` | Counts, valid percentages, cross-tabs, totals, grouped tables and labelled categories. |
| `03_summary_statistics.R` | Custom statistics, grouping, missing keys, dates, list/table output and factor cautions. |
| `04_prepare_and_calculate.R` | Conversion, parsing, row calculations, bins, reproducibility and timing. |
| `05_robustness_and_consistency.R` | Container classes, empty/all-missing inputs, lists, special missing values, previews and base R comparisons. |
| `06_data_table_optional.R` | Optional data.table containers, native syntax and preview copy/reference behavior. |

Comments explain what to look for. Some ordinary calls deliberately emit
warnings. The error-producing examples at the bottom of script 05 are commented
out; uncomment and run them individually when you want to inspect their errors.
The viewer and rich-formatting calls are also optional commented lines.

If you prefer to run the ordinary examples together, from the project root:

```r
source("inst/examples/run_all.R", echo = TRUE)
```

This does not install anything. Script 06 is separate because data.table is
optional. The scripts use whichever installed statart your R session loads;
use `find.package("statart")` if the results appear to come from an older version.
