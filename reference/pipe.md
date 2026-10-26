# Pass a value through a pipeline

See `magrittr::%>%` for details.

## Usage

``` r
lhs %>% rhs
```

## Arguments

- lhs:

  A value or the magrittr placeholder.

- rhs:

  A function call using the magrittr semantics.

## Value

The result of evaluating `rhs` with `lhs` inserted according to
magrittr's pipe and placeholder rules.
