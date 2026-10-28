# Evaluate an expression without stopping on an error

`capture()` evaluates an expression once and returns its result. If the
expression errors, it reports why evaluation did not complete and
returns `NULL` invisibly. Use `quiet = TRUE` to suppress the failure
message.

## Usage

``` r
capture(x, quiet = FALSE)
```

## Arguments

- x:

  An expression to evaluate once.

- quiet:

  If `TRUE`, suppress warnings and messages from `x` and the failure
  message from `capture()`. Printed output and the returned value are
  unchanged. Defaults to `FALSE`.

## Value

The expression's result, preserving its visibility, class and
attributes. On error, `NULL` invisibly.

## Details

Like Stata's `capture`, this lets a script continue after an error.
Unlike Stata's command, it returns the successful value, keeps printed
output and reports a caught error as a message by default. The failure
notice is not a formal R warning and does not become an error under
`options(warn = 2)`. Warnings and messages from `x` propagate unless
`quiet = TRUE`; suppressing them does not stop evaluation. With
`options(warn = 2)`, an unsuppressed warning from `x` becomes an error
and is caught. User interrupts are not caught.

A successful `FALSE`, `NA`, `NULL` or object inheriting from `try-error`
is returned unchanged. A successful `NULL` and a caught error have the
same value. Use [`tryCatch()`](https://rdrr.io/r/base/conditions.html)
when you need to distinguish them programmatically or retain the error
object. The return value is not a success/failure flag and cannot
reliably serve as the condition in `if (capture(...))`.

When updating an existing object, put the assignment inside `capture()`:
`capture(data <- update(data))`. Writing `data <- capture(update(data))`
overwrites `data` with `NULL` if the update fails.

An assignment inside `capture()` updates its target only after the
right-hand side succeeds. A successful `NULL` is still assigned. A block
of separate assignments retains the last completed update and skips
steps after the first error, as Stata's capture blocks do. A single
assignment around a pipeline retains its original target on error;
intermediate pipeline results are not saved.

`capture()` is not all-or-nothing: earlier effects are not rolled back.
In particular, changes by reference (such as data.table updates or
modified environments), files written and printed output before an error
remain. Invalid `quiet` values raise an error before `x` is evaluated.

## See also

Other utility functions:
[`set_seed()`](https://socimh.github.io/tidystata/reference/set_seed.md),
[`timer()`](https://socimh.github.io/tidystata/reference/timer.md)

## Examples

``` r
# Keep a successful result
capture(mean(1:10))
#> [1] 5.5

# Suppress warnings and messages
capture({
  message("Calculating")
  mean(1:10)
}, quiet = TRUE)
#> [1] 5.5

# A new object receives NULL on error, with a failure message
result <- capture(stop("Cannot calculate"))
#> Captured expression did not complete.
#> ℹ Changes made before the error may persist.
#> Caused by error:
#> ! Cannot calculate

result
#> NULL

# A failed assignment leaves the original data unchanged
data <- tibble::tibble(x = 1:3)
capture(data <- dplyr::mutate(data, y = missing_var * 2))
#> Captured expression did not complete.
#> ℹ Changes made before the error may persist.
#> Caused by error in `dplyr::mutate()`:
#> ℹ In argument: `y = missing_var * 2`.
#> Caused by error:
#> ! object 'missing_var' not found
data  # Still contains only x
#> # A tibble: 3 × 1
#>       x
#>   <int>
#> 1     1
#> 2     2
#> 3     3

# Successful assignments are preserved before an error
capture({
  data <- dplyr::mutate(data, y = x * 2)
  data <- dplyr::mutate(data, z = missing_var * 2)
})
#> Captured expression did not complete.
#> ℹ Changes made before the error may persist.
#> Caused by error in `dplyr::mutate()`:
#> ℹ In argument: `z = missing_var * 2`.
#> Caused by error:
#> ! object 'missing_var' not found
data  # Contains x and y
#> # A tibble: 3 × 2
#>       x     y
#>   <int> <dbl>
#> 1     1     2
#> 2     2     4
#> 3     3     6

# A pipeline updates the data only if all steps succeed
capture(
  data <- data |>
    dplyr::mutate(z = x + 1) |>
    dplyr::mutate(w = missing_var * 2)
)
#> Captured expression did not complete.
#> ℹ Changes made before the error may persist.
#> Caused by error in `dplyr::mutate()`:
#> ℹ In argument: `w = missing_var * 2`.
#> Caused by error:
#> ! object 'missing_var' not found
data  # Still contains x and y
#> # A tibble: 3 × 2
#>       x     y
#>   <int> <dbl>
#> 1     1     2
#> 2     2     4
#> 3     3     6
```
