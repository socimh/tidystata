# binning reports invalid input

    Code
      xtile(letters)
    Condition
      Error in `xtile()`:
      ! `x` must be a numeric or logical vector, not a character vector.
    Code
      xtile(1:10, n = 0)
    Condition
      Error in `xtile()`:
      ! `n` must be a whole number larger than or equal to 1, not the number 0.
    Code
      xtile(1:10, n = 2.5)
    Condition
      Error in `xtile()`:
      ! `n` must be a whole number larger than or equal to 1, not the number 2.5.
    Code
      xtile(c(NA, NA))
    Condition
      Error in `xtile()`:
      ! `x` must contain non-missing observations.
    Code
      xtile(rep(1, 4))
    Condition
      Error in `xtile()`:
      ! Can't cut a vector with only one unique value.
    Code
      xtile(1:4, wt = 1:4, method = "rank")
    Condition
      Error in `xtile()`:
      ! `wt` is not supported with `method = "rank"`.
    Code
      xtile(1:4, wt = c(1, -1, 1, 1))
    Condition
      Error in `xtile()`:
      ! `wt` must not be negative.
    Code
      cut_length(1:10, n = "2")
    Condition
      Error in `cut_length()`:
      ! `n` must be a whole number larger than or equal to 1, not a string.

---

    Code
      xtile(1:2, n = 4, method = "rank")
    Condition
      Warning:
      Requested more groups than non-missing observations; using 2 groups.
    Output
      [1] 1 2
      Levels: 1 < 2

