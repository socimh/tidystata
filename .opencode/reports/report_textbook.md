# Function contracts: textbook alignment

**Version:** 0.2.0.9000 | **Generated:** 2026-10-19 01:02:44 | **Status:** PASS

## Example 1: Valid interval counts retain their results

```r
cut_length(1:8, n = 2)
```

```
[1] [1,4.5] [1,4.5] [1,4.5] [1,4.5] (4.5,8] (4.5,8] (4.5,8] (4.5,8]
Levels: [1,4.5] < (4.5,8]
```

## Example 2: Invalid counts explain the contract

```
n = 0 : `n` must be a single positive integer.
n = -1 : `n` must be a single positive integer.
n = 1.5 : `n` must be a single positive integer.
n = NA : `n` must be a single positive integer.
n = Inf : `n` must be a single positive integer.
n = 2,3 : `n` must be a single positive integer.
```

## Example 3: Pattern diagnostics

```
`string` must be a character string.
[1] 1 2
```

## Example 4: Container and row-name contracts

```
[1] "data.frame"
[1] "tbl_df"     "tbl"        "data.frame"
[1] "1" "2" "3" "4"
[1] "a" "b" "g" "h"
```

## Example 5: Combined numeric-range patterns select every match

```
[1] "x1" "x2" "y"
[1] "x1" "x2" "y"
```

## Example 6: Scalar breaks specify one interior cutpoint

```
[1] 1 1 1 1 2 2 2 2
```
