# as_dummy() reports invalid input

    Code
      as_dummy(1:3)
    Condition
      Error in `as_dummy()`:
      ! `.data` must be a data frame, not an integer vector.
    Code
      as_dummy(d, sex, .remove = NA)
    Condition
      Error in `as_dummy()`:
      ! `.remove` must be `TRUE` or `FALSE`, not `NA`.
    Code
      as_dummy(d, tidyselect::starts_with("none"))
    Condition
      Error in `as_dummy()`:
      ! Select at least one variable to expand.
    Code
      as_dummy(d, sex)
    Condition
      Error in `as_dummy()`:
      ! Column `sex_f` already exists; rename it first.
    Code
      as_dummy(dplyr::group_by(d, sex), sex, .remove = TRUE)
    Condition
      Error in `as_dummy()`:
      ! Grouping key `sex` cannot be removed; ungroup first or use `.remove = FALSE`.

