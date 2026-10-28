# Recode numeric values with Stata-style rules

Recode individual values, sets, or closed numeric ranges using ordered
rules.

- `stata_recode()` (`recode()`): Keep unmatched values unless `.default`
  replaces them, and use named rules to assign value labels.

## Usage

``` r
stata_recode(x, ..., .default = x)

recode(x, ..., .default = x)
```

## Arguments

- x:

  An integer or double vector, optionally a numeric
  [`haven::labelled()`](https://haven.tidyverse.org/reference/labelled.html)
  vector. Convert `integer64` input explicitly before recoding.

- ...:

  Two-sided formulas `values ~ code`, applied in order. Each `code` is a
  single number or `NA`; name a rule to label its code. Expressions use
  the formula's environment, and stored formulas can be spliced with
  `!!!`.

- .default:

  Replacement for unmatched elements: a single number, `NA`, or a vector
  as long as `x`. By default, keep the input values after SPSS
  user-missing codes have been converted to `NA`.

## Value

An integer or double vector with the length and order of `x`. Named
rules produce a
[`haven::labelled()`](https://haven.tidyverse.org/reference/labelled.html)
vector; otherwise the result is numeric without value labels. Names and
the variable label are kept; previous value labels, SPSS missing-value
metadata, and other input attributes are dropped. See Details for
integer preservation.

## Details

**Matching rules**

Rules apply to the original input, after SPSS missing-value conversion.
The first match wins: `1 ~ 2, 2 ~ 1` swaps the codes. Unmatched values
stay unchanged unless `.default` replaces them, including unmatched
missing values.

The left side of a rule accepts:

- `a:b`: A closed range, including decimals. Like Stata's `a/b`, `1:5`
  matches 4.5. Bounds must be single non-missing numbers in increasing
  order (equal bounds are allowed); `lo:hi` reads them from the
  formula's environment.

- `c(...)`: A combination of values and ranges, such as `c(1, 3:5)`.

- Other expressions: An evaluated set of values to match exactly.
  Missing selectors match all missing types, as described below.

Bare `min` and `max` on the left mean `-Inf` and `Inf`, not observed
extrema: `min:min` does not select the smallest observed value. Calls
such as `min(x)` evaluate normally. Bounds and value sets must use
ordinary integer or double numbers; convert classed numbers such as
`integer64` explicitly.

**Missing values and labels**

Any missing selector matches `NA`, `NaN` and every tagged missing value.
Thus `NA ~ 0` and `haven::tagged_na("a") ~ 0` both replace all missing
types; individual tags cannot be selected separately. Unmatched tags
survive when `.default` is omitted. SPSS user-missing codes and ranges
become `NA` before matching, so their stored codes cannot be matched as
ordinary numbers.

Old value labels are removed even if no values change. Named rules
create new labels, including for unobserved codes. Labels and codes must
correspond one-to-one, and missing codes cannot be labelled.

**Output type**

Integer input stays integer if all replacement codes and defaults are
whole numbers within integer range: `1:5 ~ 1` does not force double
output. Fractions, out-of-range values, infinities, `NaN` and tagged
missing values require doubles; ordinary `NA` does not. Double input
stays double, and the input is never modified.

**Stata and other R functions**

Use
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
to replace or create a variable (Stata's `generate()`), and
[`dplyr::across()`](https://dplyr.tidyverse.org/reference/across.html)
to recode several columns. Common translations are:

|                   |                    |
|-------------------|--------------------|
| Stata rule        | R rule or argument |
| `(1/5 = 1)`       | `1:5 ~ 1`          |
| `(1 3 7 = 0)`     | `c(1, 3, 7) ~ 0`   |
| `(9 = .)`         | `9 ~ NA`           |
| `(missing = 0)`   | `NA ~ 0`           |
| `(else = .)`      | `.default = NA`    |
| `(1/5 = 1 "Low")` | `Low = 1:5 ~ 1`    |

These functions recode numeric values. For text, use
[`dplyr::recode_values()`](https://dplyr.tidyverse.org/reference/recode-and-replace-values.html)
or
[`dplyr::replace_values()`](https://dplyr.tidyverse.org/reference/recode-and-replace-values.html)
in dplyr 1.2.0 or later, or
[`dplyr::case_match()`](https://dplyr.tidyverse.org/reference/case_match.html)
in older versions. For factors, use
[`forcats::fct_recode()`](https://forcats.tidyverse.org/reference/fct_recode.html)
or
[`forcats::fct_collapse()`](https://forcats.tidyverse.org/reference/fct_collapse.html).

The alias `recode()` conflicts with
[`dplyr::recode()`](https://dplyr.tidyverse.org/reference/recode.html).
Use `stata_recode()` or an explicit namespace to avoid depending on
which package was attached last.

## See also

Other variable generation functions:
[`as_dummy()`](https://socimh.github.io/tidystata/reference/as_dummy.md),
[`cut_quantile()`](https://socimh.github.io/tidystata/reference/cut.md),
[`panel`](https://socimh.github.io/tidystata/reference/panel.md),
[`row_egen`](https://socimh.github.io/tidystata/reference/row_egen.md),
[`std()`](https://socimh.github.io/tidystata/reference/std.md)

## Examples

``` r
# Keep unmatched values
x <- c(1, 4.5, 6, 9, 12, NA)
stata_recode(x, 1:5 ~ 1, 6:10 ~ 2)
#> [1]  1  1  2  2 12 NA

# Replace unmatched values with missing
stata_recode(x, 1:5 ~ 1, 6:10 ~ 2, .default = NA)
#> [1]  1  1  2  2 NA NA

# Unbounded intervals and missing values
stata_recode(x, min:5 ~ 0, 6:max ~ 1, NA ~ 9)
#> [1] 0 0 1 1 1 9

# Swap codes without cascading replacements
stata_recode(c(1, 2, 3), 1 ~ 2, 2 ~ 1)
#> [1] 2 1 3

# Assign new value labels
stata_recode(x, Low = 1:5 ~ 1, High = 6:max ~ 2)
#> <labelled<double>[6]>
#> [1]  1  1  2  2  2 NA
#> 
#> Labels:
#>  value label
#>      1   Low
#>      2  High

# Create a new variable
d <- data.frame(score = c(2, 7, 11))
dplyr::mutate(
  d,
  group = stata_recode(score, 1:5 ~ 1, 6:10 ~ 2, .default = NA)
)
#>   score group
#> 1     2     1
#> 2     7     2
#> 3    11    NA

# Apply rules to several variables and prefix the new names
items <- data.frame(item1 = c(1, 7, 9), item2 = c(3, 8, 12))
dplyr::mutate(
  items,
  dplyr::across(
    dplyr::everything(),
    function(v) stata_recode(v, 1:5 ~ 1, 6:10 ~ 2, 11:15 ~ 3),
    .names = "r_{.col}"
  )
)
#>   item1 item2 r_item1 r_item2
#> 1     1     3       1       1
#> 2     7     8       2       2
#> 3     9    12       2       3
```
