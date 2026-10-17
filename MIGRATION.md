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

Compared with upstream commit `12709f6`, 54 exported objects become 46:
11 exports are removed, while `timer()`, `preview_table()`, and
`unpreview_table()` are added. This comparison includes local changes made
before the four-wrapper milestone and the restored printing/slicing helpers.

| Previous upstream exports | Current destination or replacement |
| --- | --- |
| `s_time()` | Renamed to `timer()`; timing messages use compact duration text. |
| `read_data()`, `write_data()` | Archived under `extra_functions/R/import-export.R`; use format-specific packages directly. |
| `codebook_detail()` | Preserved in `extra_functions/legacy-codebook.R`; use `codebook()` or `datawizard::data_codebook()`. |
| `tidy_coef()` | Reworked locally as `esttab()`, then archived under `extra_functions/R/esttab.R`; use broom/broom.mixed directly. `esttab()` was not an export in this upstream revision. |
| `regress()`, `regress_data()`, `regress_coef()`, `regress_stat()` | Archived under `extra_functions/R/regress.R`; fit models and extract results directly. |
| `s_plot()`, `s_ggsave()` | Archived under `extra_functions/R/`; use ggplot2 functions directly. |
| `print_headtail()`, `print_interval()`, `slice_headtail()`, `slice_interval()` | Restored as reviewed active functions. The original implementation remains in `extra_functions/R/sepecial-print.R`. Use `preview_table()` for a persistent display style that retains every row. |

The original printing classes and their S3 registrations remain retired. The
new `statart_preview` class operates on full tables; it does not pretend that a
row subset contains the full data. Archives are unsupported and excluded from
package builds. Restored and reworked files are not byte-identical copies; the
original upstream implementations remain in Git history.

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

For `tab()`, `tab1()`, `fre()` and `fre1()`, an explicit `.by` replaces existing
`group_by()` groups; the default `NULL` inherits them. Percentages `percent` and
`cum` use all observations within each group and range from zero to 100.
`valid` and `valid_cum` exclude observations with missing measured values, while
retaining missing grouping keys as ordinary groups. Cumulative percentages
follow displayed order.

Frequency tables append total rows. With up to five measured columns, the final
measured column becomes character to hold total labels; wider joint tables use
a separate label column. Value labels for distinct original values can look
identical, and observed categories can match total labels. Use `tab()` or
`tab1()` when original category values and types are needed. The final row of
`fre2()` is the marginal total even if an observed row category is also
`"total"`.

`as_character()` uses value labels only when the labelled vector has a nonempty
`labels` attribute. Vectors without value labels use ordinary character
conversion, including tagged missing values.

One-way tabulation accepts list columns and counts their distinct values.
Matrix columns are unsupported. Selecting no variables returns an empty result:
`tab1()` and `fre1()` return empty lists by default, while tibble output has zero
rows. `tab2()` and `fre2()` return an empty tibble for a zero-column selection;
other selections must contain exactly two variables.

## Persistent previews and explicit row subsets

Use `preview_table()` when a long table needs a compact console display while
all rows remain available to subsequent research steps:

```r
prepared <- survey |>
  dplyr::arrange(respondent_id) |>
  statart::preview_table(style = "headtail", n = 10) |>
  dplyr::mutate(income_log = log(income))

prepared # Prints selected rows; calculations still use the complete table.
```

The wrapper returns a full tibble with class `statart_preview`, preserving
supported grouped and rowwise metadata. Its style persists through supported
selection, filtering, arrangement, mutation, grouping, summaries/reframing, and
pivots. Joins inherit the left table's settings; `bind_rows()` inherits the
first input's settings. Supported ordinary data frames become tibbles. Other
containers and lazy tables require explicit conversion or collection first.
When a function returns a list of tables, wrap each member explicitly, for
example `purrr::map(result, statart::preview_table, n = 10)`.

`style = "headtail"` displays the first `ceiling(n / 2)` and final
`floor(n / 2)` rows. `style = "interval"` displays approximately evenly spaced
row positions, including both ends when `n >= 2`. Sort the table first when
these positions should cover a meaningful order. `n` is a total row budget,
not a count for each end: it must be a positive integer or `Inf`. A budget of
one selects the first row. If the table has at most `n` rows, every row appears
once; larger budgets never duplicate rows. Row positions refer to the entire
current table, including grouped tables, rather than sampling within each group.

```r
survey |>
  dplyr::arrange(income) |>
  statart::preview_table(style = "interval", n = 6)

ordinary <- statart::unpreview_table(prepared)
# tibble::as_tibble(prepared) and as.data.frame(prepared) also remove the preview.
```

`unpreview_table()` removes only the preview behavior, leaving all rows and
supported grouping intact. Ordinary tibble printing may still truncate its
console output according to tibble options.

For a single display, use `print_headtail()` or `print_interval()` with the
legacy argument names. They print selected rows and return the original input
invisibly, so a pipeline continues with the complete data. To intentionally
reduce the data, use `slice_headtail()` or `slice_interval()`; these return real
subsets. All four helpers use the same total-`n` selection rules above. They
replace the archived implementation's duplicate-row and odd-budget behavior.

## Variable names and metadata

`ds()` returns a character vector of selected names. `ds_as_column()` and
`names_as_column()` are equivalent and return a one-column tibble named `name`.
Use tidyselect in `...` to select or rename existing columns; it does not create
computed columns. Selection on grouped data retains grouping keys, following
`dplyr::select()`; ungroup first when these keys should not be included.

`variables()` returns a `name` column and adds `label` only when at least one
selected variable has a usable `label` attribute. Other labels are then `NA`.
It reads variable attributes, not value-label mappings. Selection and renaming
retain these attributes, and the input is not modified.

`variables_search()` searches names and variable labels, not cell values. Pass
one non-missing character string; vectors, `NA` and non-character queries now
produce a clear error. An empty query matches all selected variables. Matching
is case-insensitive and searches substrings by default. Use `^age$` for a
complete name or label, and `*`, `?` or `~` for zero or more, exactly one, or one
or more characters. One range such as `[a-h]` or `[1-12]` is supported. Numeric
ranges expand into alternatives; use unanchored patterns such as `item[1-12]`
for substring matching. Multiple ranges and arbitrary regular expressions are
outside the supported pattern language.

## Compact inventories and browsing

`codebook()` returns one row per selected variable for the complete input,
including grouped inputs. It ungroups before selection, so grouping keys are
included only if selected or if all columns are requested. Counts `n` and
`unique` exclude missing values using the original column's missingness rules,
including tagged and SPSS user-missing values. List elements are counted without
flattening: scalar missing elements are excluded, but `NULL` and empty elements
remain observed identities. Matrix and nested data-frame columns count complete
rows and omit rows containing any missing cell. Labels and units remain metadata;
a zero-column selection returns an empty inventory.

`browse()` opens the selected data through `tibble::view()` interactively and
returns those data invisibly. In a noninteractive script it returns the data
without opening a viewer. It returns data, rather than a vector of column names;
use `ds()` for names. Existing grouping follows `s_select()`.

`s_select()` first tries `dplyr::select()` and uses `dplyr::transmute()` only
when selection fails. A successful operation is no longer repeated, and its
warnings are visible. A failed selection can still evaluate user code before
fallback, so compute random draws and expressions with side effects in a prior
`mutate()` step, then select the resulting column names.

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

Row helpers now use operation-specific output types. `row_min()` and
`row_max()` preserve the compatible common input type: logical inputs return
logical values and integer inputs return integers, replacing the earlier
always-double extrema. Mixed logical/integer/double columns use their common
numeric type. Supported ordered values also include character vectors (C lexical
order, without parsing), ordered factors (level order), dates, date-times,
durations, measured vectors, labelled vectors, and `integer64`. Compatible
classes and metadata are retained, units are normalized, and labelled values
are compared by their underlying values. Ordered factors cannot be mixed with
non-ordered columns for extrema. Unordered factors, lists, complex values, and
incompatible combinations are rejected for extrema.

Arithmetic on plain logical, integer, double, and numeric labelled columns
returns doubles. Missingness is checked on the original values before stripping
labels, including tagged and SPSS user-missing values. Columns from the same
calendar family (`Date` or `POSIXct`) support class-preserving means and medians;
convert explicitly before requesting calendar sums or dispersion. Durations
support mean, median, sum, and standard deviation in a common `difftime` unit.
Convert duration values explicitly to one numeric unit before variance.
Compatible measured vectors on linear zero-origin scales normalize units before
arithmetic; variance has squared units, while mean, median, sum, and standard
deviation retain the common unit. Offset scales such as Celsius and Fahrenheit
support means and medians only. Explicitly convert to a zero-origin unit before
sums or dispersion. Nonlinear scales require explicit conversion to a linear
unit before any arithmetic. Measured arithmetic requires units >= 1.0.0 and uses
its public scale-conversion API. `integer64` arithmetic requires explicit
conversion, making any precision loss deliberate. Other incompatible arithmetic
combinations produce an error.

For example, logical extrema retain their meaning and dates retain their class:

```r
flags <- tibble::tibble(a = c(TRUE, FALSE, NA), b = c(FALSE, NA, NA))
statart::row_max(flags) # TRUE, FALSE, NA, with logical type

dates <- tibble::tibble(
  start = as.Date(c("2024-01-01", NA)),
  end = as.Date(c("2024-01-03", "2024-01-05"))
)
statart::row_min(dates)
statart::row_mean(dates)
```

`row_unique()` returns integer counts using compatible common types, preserving
value identities rather than converting values to doubles. Compatible factors,
calendar/measured vectors, labelled vectors, `integer64`, lists, and complex
vectors are supported. List elements remain whole values. All missing values
in a row count as one distinct category. `row_miss()` and `row_non_miss()` also
return integers and use each original column's `is.na()` result: scalar missing
list elements are missing, while `NULL` and empty elements remain observed.
For extrema and distinct counts, common-type conversion must preserve the
original missingness of every value. Conflicting SPSS missing-value definitions
that would turn an observed value into a missing value now produce an error;
harmonize those definitions explicitly before combining the columns.

Arithmetic and extrema omit missing values. An all-missing row yields a typed
`NA`, except `row_sum()` yields zero. `row_var()` and `row_sd()` use sample
statistics and need at least two observed values. Every helper requires
one-dimensional columns, rejects zero-column selections, and returns a typed
empty vector for zero-row inputs. Inputs remain unchanged.

R 4.1.0 or later is required. Extrema, distinct counts, medians, and stable
sample variance/standard deviation use native C++ kernels registered through
cpp11. Means and sums retain base R compiled row aggregations. `Rfast` is no
longer required, reducing current Imports to 12. This development milestone is
not a release-readiness claim.
