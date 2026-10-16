# summ and tabstat acceptance review

Verified 2026-10-16 for version 0.2.0.9000 on Windows R 4.6.0.
**Assessment: both functions are locally accepted release candidates.**
Package publication still requires minimum-R and other-platform validation and
maintainer approval. No push, merge or release is included.

## Defects corrected

- SPSS discrete/range user-missing values are excluded consistently from counts,
  unique values and statistics before conversion removes missing-value metadata.
- Reserved grouping keys use unique dot-prefixed names with a message; original
  values and input data are preserved. Explicit .by overrides existing groups.
- Columns named .data or .env are evaluated as actual columns; tabstat vector
  input works and retains the caller's variable name.
- Compact datetime spreads round fractional seconds instead of failing.
- .keep_all retains counts/unique values for character and list columns, with
  numeric statistics NA, including character-only inputs. This was explicitly
  chosen by the maintainer; numeric-looking strings are not parsed.
- Single-variable .name=FALSE works for zero-row grouped output. Logical
  controls reject missing, nonscalar and nonlogical arguments clearly.
- Matrix/data-frame columns fail with an actionable diagnostic.
- Integer64 conversion precision warnings remain visible. Mixed-type notices
  no longer append a spurious FALSE suffix.

## Verification

| Scope | Blocks | Passing expectations | Failures | Errors | Warnings | Skips |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Full package | 1468 | 5922 | 0 | 0 | 27 | 1 |
| All summary tests | 142 | 454 | 0 | 0 | 0 | 0 |
| Standalone acceptance | 86 | 388 | 0 | 0 | 0 | 0 |

The standalone runner completes in 6.56 seconds, with a 100% passing
scenario rate. It includes 29 explicitly named summ scenarios and
30 tabstat scenarios, plus shared contract scenarios. The
independent numerical references cover ordinary/logical/asymmetric vectors,
missing data, SD/SE, quantiles, MAD/IQR, sums and the retained moment formulas.

| Area | Checks |
| --- | --- |
| Numerical/missing values | Base-R references, SPSS discrete/range and all-missing codes, within-group masks, input preservation |
| Input/output contracts | Vector input, type families, list/table output, grouped empty schemas, single/multiple measured variables |
| Selection and names | Existing groups, explicit override, missing group keys, reserved/dotted names, data-mask pronoun names |
| Argument boundaries | Statistic aliases/unsupported statistics, invalid logical flags, unsupported matrix columns, precision warnings |
| Nonnumeric retention | Character-only and mixed data, repeated list identities, counts without text parsing |
| Calendar output | Percentile aliases, empty inputs, mixed tables, compact sub-second spread, explicit calendar sum rejection |

Fresh native installation and source build pass. R CMD check --no-manual reports
**Status: OK**, with no check errors, warnings or notes. All retained summary
tests now capture expected warnings explicitly; the legacy unnamed-matrix
fixture was corrected without removing coverage. The remaining package warnings
and empty cut_length skip are outside these two functions.

Independent QA and final read-only package review found no remaining material
defects. Additional probes checked units/difftime, tagged missing values,
grouped special names, list NULL/NA identities, mixed empty schemas and
base-data.frame/data.table class restoration.

Raw evidence: [full suite](../results/summ-acceptance-clean.csv),
[warning details](../results/summ-acceptance-clean-details.csv),
[package check](../results/summ-acceptance-clean-check.log),
[acceptance scenarios](../results/summ-acceptance-clean-scenarios.csv), and
[actual output log](../results/summ-acceptance-examples-clean.log).

An initial new message assertion failed because it excluded the message's
normal trailing newline; its pattern was corrected and the full clean run
supersedes that diagnostic run. Earlier failed outputs remain local and ignored.

## Actual output

These examples use df = tibble(g = c("A", "A", "B", NA),
x = c(1, 3, NA_real_, 8)); other examples show their inputs directly.
Warnings for labelled/nonnumeric input and the grouping rename notice are
intentional and retained in the raw output log.

```text
Numeric summary
summ(df, x)
# A tibble: 1 x 8
  name  type      n unique   min  mean    sd   max
  <chr> <chr> <int>  <int> <dbl> <dbl> <dbl> <dbl>
1 x     dbl       3      3     1     4  3.61     8

Default tabstat
tabstat(df, x)
# A tibble: 1 x 3
  name  type   mean
  <chr> <chr> <dbl>
1 x     dbl       4

Grouped aliases and sum
summ(df, x, .by = g, .stat = c("n", "missing", "p50", "sum"))
# A tibble: 3 x 7
  g     name  type      n missing   p50   sum
  <chr> <chr> <chr> <int>   <int> <dbl> <dbl>
1 A     x     dbl       2       0     2     4
2 B     x     dbl       0       1    NA    NA
3 <NA>  x     dbl       1       0     8     8

tabstat removes only missing grouping keys
tabstat(df, x, .by = g, .na.rm = TRUE, .stat = c("n", "missing",
    "mean"))
# A tibble: 2 x 6
  g     name  type      n missing  mean
  <chr> <chr> <chr> <int>   <int> <dbl>
1 A     x     dbl       2       0     2
2 B     x     dbl       0       1    NA

Zero rows
summ(tibble::tibble(x = numeric()), .detail = TRUE)
# A tibble: 1 x 19
  name  type      n unique miss_n valid_pct   min    q1 median  mean   mad    sd    q3   max   iqr  skew kurtosis    se
  <chr> <chr> <int>  <int>  <int>     <dbl> <dbl> <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>    <dbl> <dbl>
1 x     dbl       0      0      0        NA    NA    NA     NA    NA    NA    NA    NA    NA    NA    NA       NA    NA
# i 1 more variable: sum <dbl>

SPSS user-missing codes
summ(tibble::tibble(x = haven::labelled_spss(c(1, 2, 99, NA),
    na_values = 99)), .stat = c("n", "missing", "unique", "mean",
    "sum"))
# A tibble: 1 x 7
  name  type        n missing unique  mean   sum
  <chr> <chr>   <int>   <int>  <int> <dbl> <dbl>
1 *x    dbl+lbl     2       2      2   1.5     3

Counts-only text
tabstat(tibble::tibble(text = c("10", "20", "20", NA)), .keep_all = TRUE,
    .stat = c("n", "unique", "mean", "sum"))
# A tibble: 1 x 6
  name    type      n unique  mean   sum
  <chr>   <chr> <int>  <int> <dbl> <dbl>
1 ***text chr       3      2    NA    NA

Reserved group name
summ(tibble::tibble(name = c("A", "A", "B"), x = c(1, 3, 8)),
    x, .by = name, .stat = c("n", "mean"))
# A tibble: 2 x 5
  .name name  type      n  mean
  <chr> <chr> <chr> <int> <dbl>
1 A     x     dbl       2     2
2 B     x     dbl       1     8

Compact datetime spread
summ(tibble::tibble(t = as.POSIXct("2024-01-01", tz = "UTC") +
    c(0, 1)), .stat = c("mean", "sd", "se"), .duration_format = "compact")
# A tibble: 1 x 5
  name  type  mean             sd    se
  <chr> <chr> <chr>            <chr> <chr>
1 t     dttm  2024-01-01 00:00 1s    0s

Mixed calendar table
tabstat(tibble::tibble(x = c(1, 3), date = as.Date("2024-01-01") +
    0:1), .mode = "table", .stat = c("n", "p50", "mean"))
# A tibble: 2 x 5
  name  type      n p50        mean
  <chr> <chr> <int> <chr>      <chr>
1 x     dbl       2 2          2
2 date  date      2 2024-01-01 2024-01-01
```

## Published contract limits

- Missing measured values are always omitted; .na.rm controls missing grouping
  keys only. valid_pct is a fraction from zero to one.
- Factors use level codes with a warning; units/difftime retain original units.
  Numeric calculations use doubles, so large integer64 values can lose precision
  and warn. Exact arbitrary-precision summaries are not provided.
- SD is sample SD; quantiles use type 7. Skewness and excess kurtosis standardize
  central moments by sample SD; exact Stata equivalence is not claimed.
  Undefined singleton/constant moments may be NA or NaN.
- Calendar locations/spreads are formatted strings in both modes. Dates omit
  fractional days, datetimes use UTC to minute precision, and spreads are
  rounded for display. Calendar sum/skew/kurtosis are unsupported.
- List mode returns a single table for one type family and a named list for
  mixed families. Table mode combines them with compatible text statistics.
- Scope remains 0.2.0.9000, 13 Imports and 40 exports. No dependencies, exports,
  datasets, native source/artifacts or unrelated function behavior changed.

## Reproduction

Run the protected fresh full check first, then use the library path recorded
in its paths JSON for the standalone runner. Save the runner's combined stdout/stderr
as UTF-8 to .opencode/results/summ-acceptance-examples-clean.log, including the
protected launcher's exit line, before generating the report:

```powershell
python .opencode/workflows/verify_package.py --check --prefix .opencode/results/summ-acceptance-clean
python C:/Users/socimh/.codex/scripts/run_r_safe.py -- Rscript .opencode/tests/verify_summ_tabstat.R <fresh-library> .opencode/results/summ-acceptance-clean
python .opencode/workflows/summarize_summ_acceptance.py
```

Source help, NEWS and MIGRATION document the accepted behavior; man/summ.Rd was
regenerated. README examples were unchanged. Continue with the tabulation family
next; minimum-R/multi-platform validation remains a package publication gate.
