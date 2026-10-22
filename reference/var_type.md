# Report an object's type or unit

Report an object's type or unit

## Usage

``` r
var_type(
  x,
  abbr = FALSE,
  .x = lifecycle::deprecated(),
  .abbr = lifecycle::deprecated()
)

var_unit(x, .x = lifecycle::deprecated())
```

## Arguments

- x:

  An object.

- abbr:

  A single `TRUE` or `FALSE`. If `TRUE`, the abbreviation of the type is
  returned.

- .x, .abbr:

  **\[deprecated\]** Use `x` and `abbr` instead.

## Value

A character. `var_type()` returns `"units"` for measured vectors in
either abbreviation mode. `var_unit()` returns the unit string for
measured or duration vectors, including empty or all-missing measured
vectors, and `NA_character_` for vectors without units.

## Details

Types describe storage and class metadata, not the observed values:
empty and all-missing vectors retain their type. Known scalar
abbreviations are expanded exactly, including `int64` to `integer64`.
Haven-labelled vectors append `+lbl` in abbreviation mode and `+label`
otherwise.

Plain matrices and arrays retain their element-type description, and
data frames retain their container name without dimensions. Other
classed objects use their pillar type description, preserving
punctuation and structured labels such as `I<int>` and `list<int>` in
both modes. An empty or missing custom description falls back to the
first class name; errors in custom methods are propagated. Custom labels
that merely start with a numeric abbreviation do not make a class
suitable for numeric summaries. Haven-label conversion requires an
actual haven-labelled class.

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
var_type(letters)
#> [1] "character"
```
