# row helpers report invalid input

    Code
      row_mean(d$a, na.rm = NA)
    Condition
      Error in `row_mean()`:
      ! `na.rm` must be `TRUE` or `FALSE`, not `NA`.
    Code
      row_unique(d$a, na.rm = TRUE)
    Condition
      Error in `row_unique()`:
      ! `na.rm` is not an argument of `row_unique()`; it counts values across all selected columns.
    Code
      row_nvals(d$a, na.rm = TRUE)
    Condition
      Error in `row_nvals()`:
      ! `na.rm` is not an argument of `row_nvals()`; it counts values across all selected columns.
    Code
      row_mean(d$a, d$b)
    Condition
      Error in `row_mean()`:
      ! Numeric row calculations require compatible supported numeric or logical columns; integer64 and other classes require explicit conversion.
    Code
      row_sum(d$d, d$d + 1)
    Condition
      Error in `row_sum()`:
      ! Calendar Date/POSIXct columns support mean and median, not sums or dispersion; convert explicitly first.
    Code
      row_max(d$a, .values = list(1:3))
    Condition
      Error in `row_max()`:
      ! Each vector in `.values` must have length one or the input row count (2).
    Code
      row_max(d$a, factor(c("u", "v")))
    Condition
      Error in `row_max()`:
      ! Row extrema require supported ordered columns; unordered factors, lists and complex columns have no supported ordering: factor(c("u", "v"))
    Code
      dplyr::mutate(d, m = row_mean(tidyselect::where(is.list)))
    Condition
      Error in `dplyr::mutate()`:
      i In argument: `m = row_mean(tidyselect::where(is.list))`.
      Caused by error in `row_mean()`:
      ! Select at least one column; `NULL` and zero columns are not supported.

