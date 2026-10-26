# Capture an error and report success

`capture()` works like Stata's `capture`: it evaluates an expression,
suppresses any error, and returns `TRUE` if the expression succeeded and
`FALSE` if it failed.

## Usage

``` r
capture(x)
```

## Arguments

- x:

  An expression to evaluate once.

## Value

A single logical value: `TRUE` on success, `FALSE` on error or when the
expression returns an object inheriting from `try-error`.

## Details

Errors are caught without printing their messages; warnings and messages
propagate normally. The `try-error` exception follows
[`try()`](https://rdrr.io/r/base/try.html) compatibility.

## See also

Other utility functions:
[`set_seed()`](https://socimh.github.io/tidystata/reference/set_seed.md),
[`timer()`](https://socimh.github.io/tidystata/reference/timer.md)

## Examples

``` r
capture(mean(1:10))
#> [1] TRUE

# Warnings do not count as errors
capture(mean(letters[1:10]))
#> Warning: argument is not numeric or logical: returning NA
#> [1] TRUE

# Errors return FALSE
capture(means(1:10))
#> [1] FALSE

# Check a key without stopping the script
capture(isid(lifeexp, country))
#> [1] TRUE
```
