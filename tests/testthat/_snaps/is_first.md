# is_first() reports invalid input

    Code
      is_first(1:2, .missing = NA)
    Condition
      Error in `is_first()`:
      ! `.missing` must be `TRUE` or `FALSE`, not `NA`.
    Code
      is_first()
    Condition
      Error in `is_first()`:
      ! Supply the variables that define the groups, or call `is_first()` inside a grouped `dplyr::mutate()`.
    Code
      is_first(1:2, 1:3)
    Condition
      Error in `is_first()`:
      ! All arguments to `is_first()` must have the same length.

