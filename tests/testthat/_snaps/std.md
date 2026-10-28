# std() and pc() report invalid inputs

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
      pc(1:3, prop = NA)
    Condition
      Error in `pc()`:
      ! `prop` must be `TRUE` or `FALSE`, not `NA`.
    Code
      pc(as.Date("2020-01-01"))
    Condition
      Error in `pc()`:
      ! `x` must be a numeric or logical vector, not a <Date> object.

