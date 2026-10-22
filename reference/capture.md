# Capture an error and report success

`capture()` works like Stata's `capture`: it evaluates an expression,
suppresses any error, and returns `TRUE` if the expression succeeded and
`FALSE` if it failed. `s_try()` is an alias of `capture()`.

## Usage

``` r
capture(x, .fn = lifecycle::deprecated())

s_try(x, .fn = lifecycle::deprecated())
```

## Arguments

- x:

  An expression to evaluate once.

- .fn:

  **\[deprecated\]** Use `x` instead.

## Value

A single logical value.

## Details

Errors are caught without printing their messages; warnings and messages
propagate normally. For compatibility with
[`try()`](https://rdrr.io/r/base/try.html), a successful expression that
returns an object inheriting from `try-error` also yields `FALSE`.

## See also

Other utility functions:
[`set_seed()`](https://socimh.github.io/tidystata/reference/set_seed.md),
[`timer()`](https://socimh.github.io/tidystata/reference/timer.md)

## Examples

``` r
capture(mean(1:10))
#> [1] TRUE

# This gives a warning, but it is still working, so capture() returns TRUE
capture(mean(letters[1:10]))
#> Warning: argument is not numeric or logical: returning NA
#> [1] TRUE

# This throws an error, so capture() returns FALSE
capture(means(1:10))
#> [1] FALSE

# Check a key without stopping the script
capture(isid(dplyr::starwars, name))
#> [1] TRUE
```
