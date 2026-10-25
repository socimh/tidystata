# Time spent on a function

`timer()` works like the `timer` command in Stata.

## Usage

``` r
timer(x, on_error = TRUE)
```

## Arguments

- x:

  An expression to evaluate and time.

- on_error:

  A single `TRUE` or `FALSE`. If `TRUE` (the default), also report
  elapsed time when the expression fails, then let the original error
  propagate. Use `FALSE` to report elapsed time only on success.

## Value

The evaluated result, invisibly.

## Details

The expression is evaluated once. On success, elapsed time is emitted as
a message. Warnings and errors propagate normally. When the expression
fails (or is interrupted) and `on_error = TRUE`, a message marked as
failed execution reports the elapsed time while the error unwinds; the
original condition object, including its call, is not modified.

Nested or repeated timers each measure everything evaluated inside them,
so a later timer in a pipeline reports cumulative time from its own
start.

## See also

Other utility functions:
[`capture()`](https://socimh.github.io/tidystata/reference/capture.md),
[`set_seed()`](https://socimh.github.io/tidystata/reference/set_seed.md)

## Examples

``` r
x <- seq_len(1e6)
mean(x) |> timer()
#> Time spent: 0.007s
try(timer(stop("failure")))
#> Failed execution. Time spent: 0.000s
#> Error in timer(stop("failure")) : failure
```
