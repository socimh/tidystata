# misstable() reports invalid input

    Code
      misstable(1:3)
    Condition
      Error in `misstable()`:
      ! `.data` must be a data frame, not an integer vector.
    Code
      misstable(tibble::tibble(x = NA), .all = "yes")
    Condition
      Error in `misstable()`:
      ! `.all` must be `TRUE` or `FALSE`, not a string.
    Code
      misstable(tibble::tibble(n = c(1, NA)), .patterns = TRUE)
    Condition
      Error in `misstable()`:
      ! Variable `n` clashes with a pattern table column; rename it first.

