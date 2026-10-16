# Moving to the smaller statart core

The `0.2.0.9000` development series prepares a breaking `0.3.0` release focused
on data exploration and preparation. Four wrappers have been retired:
`read_data()`, `write_data()`, `esttab()`, and `codebook_detail()`.

Their implementations and original help are preserved in `extra_functions/` in
the source repository. Dedicated tests and demos are archived there too. The
archive is excluded from package builds and active test/demo discovery; archived
functions are unsupported and may require packages outside statart's dependencies.
The retained exploration and preparation helpers remain available. The upstream
comparison below also records helpers archived before the four-wrapper milestone.

## Changes from the GitHub 0.2.0 baseline

Compared with upstream commit `12709f6`, 54 exported objects become 40:
15 exports are removed and `timer()` is added. This comparison includes local
changes made before the four-wrapper milestone described above.

| Previous upstream exports | Current destination or replacement |
| --- | --- |
| `s_time()` | Renamed to `timer()`; timing messages use compact duration text. |
| `read_data()`, `write_data()` | Archived under `extra_functions/R/import-export.R`; use format-specific packages directly. |
| `codebook_detail()` | Preserved in `extra_functions/legacy-codebook.R`; use `codebook()` or `datawizard::data_codebook()`. |
| `tidy_coef()` | Reworked locally as `esttab()`, then archived under `extra_functions/R/esttab.R`; use broom/broom.mixed directly. `esttab()` was not an export in this upstream revision. |
| `regress()`, `regress_data()`, `regress_coef()`, `regress_stat()` | Archived under `extra_functions/R/regress.R`; fit models and extract results directly. |
| `s_plot()`, `s_ggsave()` | Archived under `extra_functions/R/`; use ggplot2 functions directly. |
| `print_headtail()`, `print_interval()`, `slice_headtail()`, `slice_interval()` | Archived in `extra_functions/R/sepecial-print.R`; use explicit row selection and printing. |

The printing S3 registrations are also removed. Archives are unsupported and
excluded from package builds. Renamed/reworked files are not byte-identical
copies; the original upstream implementations remain in Git history.
No compatibility aliases are introduced by this documentation update.

## Import and export directly

Choose the package for the format you use. Install only that package and its
dependencies. For example:

```r
survey <- readr::read_csv("survey.csv")
readr::write_csv(survey, "survey-clean.csv")

survey <- haven::read_dta("survey.dta")
haven::write_dta(survey, "survey-clean.dta")

survey <- readxl::read_excel("survey.xlsx", sheet = 1)
openxlsx::write.xlsx(survey, "survey-clean.xlsx")

saveRDS(survey, "survey.rds")
survey <- readRDS("survey.rds")
```

Other direct alternatives include `haven::read_sav()`/`haven::write_sav()` for
SPSS, `haven::read_sas()` for SAS datasets, `haven::write_xpt()` for SAS transport
files, `arrow::read_feather()`/`arrow::write_feather()` for Feather, and
`jsonlite::fromJSON()`/`jsonlite::write_json()` for JSON. SAS transport output uses
an `.xpt` extension; it is not a `.sas7bdat` file.

## Extract model results directly

Use `broom` for coefficient and model summaries:

```r
fit <- lm(mpg ~ wt + hp, data = mtcars)
broom::tidy(fit, conf.int = TRUE)
broom::glance(fit)
```

For supported mixed models, use `broom.mixed::tidy()` and
`broom.mixed::glance()`. These return numeric results for subsequent formatting;
they do not reproduce the retired wrapper's combined coefficient strings or
significance stars.

## Detailed codebooks

Use `statart::codebook()` for the retained compact variable overview. For the
previous detailed codebook capability, call the underlying package directly:

```r
datawizard::data_codebook(mtcars)
```

## Frequency-table output

`fre()` and `fre2()` now return tibbles. `fre1()` returns a list of tibbles, like
`tab1()`. To request rich formatting, install `flextable` and specify the type:

```r
statart::fre(mtcars, cyl)
statart::fre1(mtcars, cyl, gear)
statart::fre(mtcars, cyl, .type = "flextable")
```

The default return type is independent of whether `flextable` is installed.
Requesting rich output without it installed produces an installation message.

## Quantile bins and row summaries

`cut_quantile()` uses type-7 quantiles and keeps equal values in the same group.
Ties may collapse duplicate cutpoints, producing fewer intervals and a warning.
Custom labels must match the effective interval count. Empty, all-missing,
constant, or invalid group-count inputs produce errors. These bins are not
promised to match Stata's `xtile` exactly.

Numeric row summaries ignore missing values. An all-missing row yields zero for
`row_sum()` and `NA` for the other numeric summaries. `row_var()` and `row_sd()`
use sample statistics and need at least two observed values. `row_unique()` counts
one missing category when a row contains missing values. Row helpers return
atomic vectors, including zero-length vectors for zero-row inputs.

R 4.1.0 or later is required. The existing native and `Rfast` backend remains in
use; this development milestone is not a release-readiness claim.
