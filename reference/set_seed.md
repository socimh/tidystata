# Set the random seed, in a pipeline or alone

Attach a seed to one expression at the end of a pipeline, as in
`sample(x, 5) |> set_seed(123)`, or set it alone like Stata's
`set seed 123` with `set_seed(123)`.

## Usage

``` r
set_seed(x, seed)
```

## Arguments

- x:

  An expression evaluated after setting the seed. When `seed` is
  omitted, `x` is the seed itself, as in `set_seed(123)`.

- seed:

  An integer for reproducibility.

## Value

The expression's result, preserving its visibility. Used alone,
`set_seed()` returns `NULL` invisibly.

## Details

Calls [`set.seed()`](https://rdrr.io/r/base/Random.html) before
evaluating `x` once. The global random-number state is changed and is
not restored, including when `x` fails. Subsequent random draws continue
from the state left by `x`.

With only one argument, that argument is the seed and must be a single
finite number. A pipeline that forgets the seed therefore errors, unless
its result happens to be a single number, which is then used as the
seed.

## See also

Other utility functions:
[`capture()`](https://socimh.github.io/tidystata/reference/capture.md),
[`timer()`](https://socimh.github.io/tidystata/reference/timer.md)

## Examples

``` r
sample(1:10, 8) |>
  set_seed(123)
#> [1]  3 10  2  8  6  9  1  7

# Repeating the seed reproduces the result
sample(1:10, 8) |>
  set_seed(123)
#> [1]  3 10  2  8  6  9  1  7

# Alone, like Stata's set seed 123
set_seed(123)
sample(1:10, 8)
#> [1]  3 10  2  8  6  9  1  7
```
