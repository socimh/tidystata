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

**Reading types and units**

`var_type()` returns one display label per object, useful for column
audits such as `vapply(data, var_type, character(1))`. It describes
storage and class metadata, so empty and all-missing vectors retain
their type. Haven-labelled vectors add `+lbl` in abbreviation mode and
`+label` otherwise.

Plain matrices and arrays report their element type; data frames report
their container name. Dimensions are omitted. `var_unit()` reads units
or duration metadata, including hms times, and returns `NA_character_`
otherwise. It also respects custom unit methods for classes described as
`units`, `drtn` or `time`.

**Choosing an inspector**

Use `var_type()` for readable reports. For exact type information in
code:

- [`typeof()`](https://rdrr.io/r/base/typeof.html) gives storage type:
  factors, for example, are `"integer"`. `var_type()` distinguishes
  doubles, date-times and labelled doubles even though all three can
  have `"double"` storage.

- [`class()`](https://rdrr.io/r/base/class.html) gives the full class
  vector; [`inherits()`](https://rdrr.io/r/base/class.html) tests
  membership. `var_type()` reduces `c("ordered", "factor")` to
  `"ordered"`.

- [`mode()`](https://rdrr.io/r/base/mode.html) combines integers and
  doubles as `"numeric"`; `var_type()` keeps them distinct.
  [`utils::str()`](https://rdrr.io/r/utils/str.html) shows structure and
  example values rather than returning a single label.

A display label does not retain full classes, attributes or structure. A
numeric-looking label alone does not imply support for numeric
summaries.

**Custom classes**

Classed objects use
[`pillar::type_sum()`](https://pillar.r-lib.org/reference/type_sum.html)
labels. With `abbr = FALSE`, known abbreviations expand exactly (`int64`
becomes `integer64`), and default class abbreviations become full
primary class names, such as `"dgCMatrix"`. Registered or inherited
display methods and explicit pillar labels take precedence. Custom
labels, including `I<int>`, `list<int>` and punctuation, are preserved
in both modes.

A custom
[`pillar::type_sum()`](https://pillar.r-lib.org/reference/type_sum.html)
method can control the label. An empty or missing description falls back
to the first class name; method errors propagate.

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
