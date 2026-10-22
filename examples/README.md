# Plain scripts for trying tidystata

For a source checkout, open `tidystata.Rproj` in RStudio and restart R before
installing. Start with `00_install.R`, whose install line is commented out so
that sourcing it never installs anything. Run it by hand:

```r
devtools::install(".", upgrade = "never", build_vignettes = FALSE)
```

Restart R, open any numbered script, and run its lines with Ctrl+Enter. Each
script starts with `library(tidystata)`, creates its own small dataset, and calls
the package functions directly. Objects stay in your workspace for inspection.
There are no custom setup functions, test wrappers, or PASS/FAIL machinery.

After loading, run `packageVersion("tidystata")` and `find.package("tidystata")` to
confirm the version and location. Opening the source folder does not update an
older installed copy. Install again after changing package source.

`devtools::install()` installs the package from a local project directory.
Here `"."` means the current tidystata project. This follows the
[installation and plain usage workflow in R Packages](https://r-pkgs.org/whole-game.html#install).

If you already installed the version you want to try, skip `00_install.R`.
The scripts live in the source repository's `examples/` folder and are not
part of the installed package. Open one in your editor, or run it from the
project root:

```r
source("examples/02_frequency_tables.R", echo = TRUE)
```

The complete migration guide is the
[Migration guide](https://socimh.github.io/tidystata/articles/migration.html)
article on the website.

| Script | Contents |
| --- | --- |
| `00_install.R` | Install the local package (commented-out line, run by hand), then load it and inspect its version/path. |
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
source("examples/run_all.R", echo = TRUE)
```

This does not install anything. Script 06 is separate because data.table is
optional. The scripts use whichever installed tidystata your R session loads;
use `find.package("tidystata")` if the results appear to come from an older version.
