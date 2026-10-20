# std() and pct() report invalid inputs

    Code
      std(letters)
    Condition
      Error in `std()`:
      ! `x` must be a numeric or logical vector, not a character vector.
    Code
      std(factor("a"))
    Condition
      Error in `std()`:
      ! `x` must be a numeric or logical vector, not a <factor> object.
    Code
      std(1:3, mean = "a")
    Condition
      Error in `std()`:
      ! `mean` must be a finite number, not a string.
    Code
      std(1:3, sd = c(1, 2))
    Condition
      Error in `std()`:
      ! `sd` must be a finite number, not a double vector.
    Code
      pct(1:3, prop = NA)
    Condition
      Error in `pct()`:
      ! `prop` must be `TRUE` or `FALSE`, not `NA`.
    Code
      pct(as.Date("2020-01-01"))
    Condition
      Error in `pct()`:
      ! `x` must be a numeric or logical vector, not a <Date> object.

