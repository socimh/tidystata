# Report an object's type or unit

Inspect an object's type and measurement metadata:

- `var_type()`: Describe the object's storage type or class, optionally
  using an abbreviation.

- `var_unit()`: Report the measurement or duration unit, or
  `NA_character_` when the object has no unit.

## Usage

``` r
var_type(x, abbr = FALSE)

var_unit(x)
```

## Arguments

- x:

  An object.

- abbr:

  For `var_type()`, if `TRUE`, return an abbreviated type. Defaults to
  `FALSE`: expand known abbreviations and use full class names for
  default class abbreviations. Custom display labels are preserved.

## Value

- `var_type()`: One character string describing the type, including
  `"units"` for measured vectors in either abbreviation mode.

- `var_unit()`: The unit string for measured or duration vectors,
  including empty or all-missing measured vectors, or `NA_character_`
  when no unit is available.

## Details

### Comparison with other type inspectors

`var_type()` gives one readable label per object, useful for column
audits with `vapply(data, var_type, character(1))` or
`dplyr::summarise(data, dplyr::across(dplyr::everything(), var_type))`.
It combines storage and class information in a display label:

- [`typeof()`](https://rdrr.io/r/base/typeof.html) reports the internal
  storage type. Factors are `"integer"`, while ordinary double vectors,
  POSIXct date-times and double-backed haven-labelled vectors are all
  `"double"`. `var_type()` distinguishes `"factor"`, `"double"`,
  `"datetime"` and `"double+label"`.

- [`class()`](https://rdrr.io/r/base/class.html) reports the class names
  used for method dispatch and may return several strings, such as
  `c("ordered", "factor")`. `var_type()` reduces this to one label,
  `"ordered"`. Use [`class()`](https://rdrr.io/r/base/class.html) to
  inspect the full class vector and
  [`inherits()`](https://rdrr.io/r/base/class.html) to test class
  membership in program logic.

- [`mode()`](https://rdrr.io/r/base/mode.html) reports a broader
  category: both integer and double vectors have mode `"numeric"`.
  `var_type()` keeps that storage distinction.

- [`utils::str()`](https://rdrr.io/r/utils/str.html) displays structure
  and example values. `var_type()` returns a character string that can
  be collected into an audit table.

- [`pillar::type_sum()`](https://pillar.r-lib.org/reference/type_sum.html)
  supplies compact display labels for classed objects. `var_type()`
  builds on those labels, expands recognized abbreviations by default,
  marks haven value labels and omits container dimensions.

Custom classes can provide a
[`pillar::type_sum()`](https://pillar.r-lib.org/reference/type_sum.html)
method to control their display label without changes to `var_type()`.

Use `var_type()` for reporting; use storage or class inspectors when
exact R type information is needed. Its display label does not retain
the full class hierarchy, attributes or structure.

### Type and unit metadata

Types describe storage and class metadata, not the observed values:
empty and all-missing vectors retain their type. Known scalar
abbreviations expand exactly, including `int64` to `integer64`.
Haven-labelled vectors append `+lbl` in abbreviation mode and `+label`
otherwise.

Plain matrices and arrays retain their element-type description, and
data frames retain their container name without dimensions. Other
classed objects use their pillar type description. With `abbr = FALSE`,
a default class-name abbreviation is replaced by the full primary class
name, for example `"dgCMatrix"` for a sparse matrix of that class.
Registered or inherited display methods and explicit pillar labels take
precedence. Custom labels, including punctuation and structured
descriptions such as `I<int>` and `list<int>`, are preserved in both
modes. An empty or missing custom description falls back to the first
class name; errors in custom methods are propagated. A numeric-looking
type description does not imply support for numeric summaries.

`var_unit()` reads actual units/difftime metadata (including hms times),
and retains custom unit methods for classes describing themselves as
`units`, `drtn` or `time`. Other objects return `NA_character_`.

## See also

Other inspection functions:
[`browse()`](https://socimh.github.io/tidystata/reference/browse.md),
[`codebook()`](https://socimh.github.io/tidystata/reference/codebook.md),
[`misstable()`](https://socimh.github.io/tidystata/reference/misstable.md),
[`names`](https://socimh.github.io/tidystata/reference/names.md),
[`variables()`](https://socimh.github.io/tidystata/reference/variables.md)

## Examples

``` r
var_type(1:10)
#> [1] "integer"

var_type(1:10, abbr = TRUE)
#> [1] "int"

var_type(letters)
#> [1] "character"

# Compare storage, dispatch classes and readable type labels
objects <- list(
  score = 1.5,
  grade = ordered(c("low", "high"), levels = c("low", "high")),
  recorded = as.POSIXct("2026-01-01", tz = "UTC"),
  answer = haven::labelled(c(1, 2), labels = c(Yes = 1, No = 2))
)

lapply(objects, function(x) {
  tibble::tibble(
    typeof = typeof(x),
    class = paste(class(x), collapse = ", "),
    var_type = var_type(x)
  )
}) |>
  dplyr::bind_rows(.id = "variable")
#> # A tibble: 4 × 4
#>   variable typeof  class                              var_type    
#>   <chr>    <chr>   <chr>                              <chr>       
#> 1 score    double  numeric                            double      
#> 2 grade    integer ordered, factor                    ordered     
#> 3 recorded double  POSIXct, POSIXt                    datetime    
#> 4 answer   double  haven_labelled, vctrs_vctr, double double+label

# Type and unit describe different properties of the same object
elapsed <- as.difftime(c(1, 2, 3), units = "hours")
elapsed
#> Time differences in hours
#> [1] 1 2 3

var_type(elapsed)
#> [1] "duration"

var_unit(elapsed)
#> [1] "hours"
```
