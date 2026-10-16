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

One-way tabulation accepts list columns and counts their distinct values.
Matrix columns are unsupported. Selecting no variables returns an empty result:
`tab1()` and `fre1()` return empty lists by default, while tibble output has zero
rows. `tab2()` and `fre2()` return an empty tibble for a zero-column selection;
other selections must contain exactly two variables.

## Column summary statistics

`summ()` and `tabstat()` retain numeric and logical columns with no observed
values, including zero-row inputs. They return `n = 0`, `unique = 0`, and `NA`
for summary statistics, including `sum`. `miss_n` counts missing input rows.
Zero-row grouped inputs do not create artificial groups.

Select statistics through `.stat`. The aliases `missing`, `p25`, `p50`, and
`p75` select `miss_n`, `q1`, `median`, and `q3`, respectively. Requested names
and order are retained, and aliases can coexist with canonical names:

```r
statart::summ(mtcars, mpg, .stat = c("missing", "miss_n", "p50", "median", "sum"))
```

Unknown statistics produce an error. `sum` is supported for numeric summaries;
calendar dates and datetimes support neither `sum` nor `skew`/`kurtosis`.

When `.mode = "table"` combines numeric and calendar summaries, shared formatted
statistic columns become character so the rows can coexist. Count columns remain
numeric, and numeric-only summary tables retain numeric statistic columns.
Default `.mode = "list"` separates variable types and preserves numeric statistic
types in the numeric summary.

With `.keep_all = TRUE`, character/list columns retain observed counts,
missing counts and distinct observed values. Their numeric statistics are `NA`,
even for numeric-looking text. The default `.keep_all = FALSE` removes these
columns and errors if no supported columns remain. SPSS user-missing values and
ranges are excluded before computing counts or numeric statistics. `valid_pct`
is a fraction from zero to one, rather than a percentage from zero to 100.

An explicit `.by` overrides existing `group_by()` groups. A grouping key that
collides with summary metadata is renamed with leading dots until unique among
input names, with a message; input data remain unchanged. `.na.rm` removes
missing grouping keys only: numeric statistics always omit missing measured
values. `.name = FALSE` drops the variable-name column only for one measured
variable, including an empty grouped result.

List mode returns a single table for one type family, or named tables for mixed
`numeric`, `date` and `datetime` families. Calendar statistics are formatted text
in both modes. Dates display calendar days; datetimes display UTC to minute
precision, and compact sub-minute spreads round to whole seconds. Use the raw
input with base R statistics when full calendar precision is needed.

Numeric calculations use double precision; converting large `integer64` values
can lose precision and emits a warning.

Factors use level codes with a warning; numeric labelled vectors use underlying
values, excluding SPSS missing codes. Measured vectors and `difftime` retain
original numeric units. SD is sample SD, quantiles use type 7, and MAD uses R's
default scaling. Skewness and excess kurtosis standardize central moments by
sample SD; these are not claims of exact Stata equivalence. Undefined moments
for singleton or constant data may be `NA` or `NaN`. See `?summ` for details.

## Cross-tabulation category names

`tab2()` and `fre2()` preserve categories matching the original variable names,
`n`, or internal pivot names. A category matching the combined row-header name,
or a literal `"NA"` alongside a missing column category, cannot be represented
as unique output columns and produces a clear error.

The column category `"total"` is reserved for the marginal total in `fre2()`.
Recode that category or use `tab2()` to avoid silently replacing category counts.

## Measured vectors

`s_type()` identifies measured vectors as `"units"` in either abbreviation mode,
including compound units such as `m/s`. `s_unit()` returns the unit string even
for empty and all-missing measured vectors; ordinary vectors return
`NA_character_`.

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
