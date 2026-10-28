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

A vector with the length and order of `x`, using the common integer or
double type of the input, codes, and `.default`. Integer input stays
integer when every code and `.default` is a whole number within integer
range, so `1:5 ~ 1` does not promote it to double. Double input stays
double. Fractions, out-of-range numbers, infinities, `NaN`, and tagged
missing codes or defaults require double output; ordinary `NA` does not
promote integer input. Named rules produce a
[`haven::labelled()`](https://haven.tidyverse.org/reference/labelled.html)
vector; otherwise the result is numeric without value labels. Names and
the variable label are kept; previous value labels, SPSS missing-value
metadata, and other input attributes are dropped.

## Details

**Matching**

The left side of each rule is read before evaluation:

- `a:b` selects the closed range `a <= x <= b`, including decimals, like
  Stata's `a/b`. Thus `1:5` matches `4.5`, rather than enumerating
  integers. Bounds must be single non-missing numbers, with the lower
  bound no greater than the upper bound. `lo:hi` uses the formula's
  environment.

- `c(...)` combines values and ranges, for example `c(1, 3:5)`.

- Other expressions are evaluated as value sets. Non-missing values
  match exactly; a missing value in a set matches every missing type, as
  below.

Rules match the input before any replacements, after SPSS missing-value
conversion. The first matching rule wins, so `1 ~ 2, 2 ~ 1` swaps the
codes. Supply `.default` to replace all unmatched elements, including
missing ones.

On the left side, bare `min` and `max` mean `-Inf` and `Inf`. Unlike
Stata's keywords, they do not refer to observed extrema: `min:min` does
not select the smallest observed code. Calls such as `min(x)` still
evaluate normally. Bounds, like value sets, must be ordinary integer or
double numbers; convert classed numbers such as `integer64` explicitly.

**Missing values and labels**

`NA ~ code` matches `NA`, `NaN`, and all tagged missing values, like
Stata's `missing` keyword. The same applies to any missing selector: for
example, `haven::tagged_na("a") ~ 0` also replaces other tags and
ordinary `NA`. Individual missing types cannot be selected separately.
Unmatched tagged missing values keep their tags when `.default` is
omitted.

SPSS user-missing codes and ranges become `NA` before matching, so their
stored codes cannot be selected as ordinary numbers. Old value labels
are removed even when no values change. Named rules supply new labels,
which are kept even if their codes are unobserved. A code cannot have
two labels, a label cannot name two codes, and a missing code cannot be
labelled.

**Stata and other R functions**

Use
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
to replace a variable or create a new one, as with Stata's `generate()`
option. Use
[`dplyr::across()`](https://dplyr.tidyverse.org/reference/across.html)
to apply rules to several variables. Common rule translations are:

|                   |                    |
|-------------------|--------------------|
| Stata rule        | R rule or argument |
| `(1/5 = 1)`       | `1:5 ~ 1`          |
| `(1 3 7 = 0)`     | `c(1, 3, 7) ~ 0`   |
| `(9 = .)`         | `9 ~ NA`           |
| `(missing = 0)`   | `NA ~ 0`           |
| `(else = .)`      | `.default = NA`    |
| `(1/5 = 1 "Low")` | `Low = 1:5 ~ 1`    |

Like Stata's `recode`, these functions operate on numeric values. For
text, use
[`dplyr::recode_values()`](https://dplyr.tidyverse.org/reference/recode-and-replace-values.html)
or
[`dplyr::replace_values()`](https://dplyr.tidyverse.org/reference/recode-and-replace-values.html)
in dplyr 1.2.0 and later, or
[`dplyr::case_match()`](https://dplyr.tidyverse.org/reference/case_match.html)
with older versions. For factors, use
[`forcats::fct_recode()`](https://forcats.tidyverse.org/reference/fct_recode.html)
or
[`forcats::fct_collapse()`](https://forcats.tidyverse.org/reference/fct_collapse.html).

The alias `recode()` shares its name with
[`dplyr::recode()`](https://dplyr.tidyverse.org/reference/recode.html).
Whichever package is attached last masks the other. Prefer
`stata_recode()` or an explicit namespace to avoid attach-order
ambiguity.

## See also

Other variable generation functions:
[`as_dummy()`](https://socimh.github.io/tidystata/reference/as_dummy.md),
[`cut`](https://socimh.github.io/tidystata/reference/cut.md),
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
    function(v) stata_recode(v, 1:5 ~ 1, 6:10 ~ 2),
    .names = "r_{.col}"
  )
)
#>   item1 item2 r_item1 r_item2
#> 1     1     3       1       1
#> 2     7     8       2       2
#> 3     9    12       2      12
```
