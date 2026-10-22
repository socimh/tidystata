# Renamed functions

These functions were renamed in tidystata 0.3.0. The old names still
work and give identical results with a lifecycle deprecation warning.
They will be removed in a future release.

|  |  |
|----|----|
| Old name | New name |
| `s_match()` | [`varlist()`](https://socimh.github.io/tidystata/reference/varlist.md) |
| `s_type()` | [`var_type()`](https://socimh.github.io/tidystata/reference/var_type.md) |
| `s_unit()` | [`var_unit()`](https://socimh.github.io/tidystata/reference/var_type.md) |

Quiet aliases such as
[`cut_quantile()`](https://socimh.github.io/tidystata/reference/cut.md),
[`s_try()`](https://socimh.github.io/tidystata/reference/capture.md),
[`names_as_column()`](https://socimh.github.io/tidystata/reference/names.md),
[`xtab()`](https://socimh.github.io/tidystata/reference/tab.md) and
[`pct()`](https://socimh.github.io/tidystata/reference/std.md) are
documented with their primary functions and give no notice.

## Usage

``` r
s_match(...)

s_type(...)

s_unit(...)
```

## Arguments

- ...:

  Arguments passed to the new function.

## Value

The result of the new function.
