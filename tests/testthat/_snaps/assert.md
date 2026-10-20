# assert() reports invalid input and failed conditions

    Code
      assert(1:3, TRUE)
    Condition
      Error in `assert()`:
      ! `.data` must be a data frame, not an integer vector.
    Code
      assert(d)
    Condition
      Error in `assert()`:
      ! Supply at least one condition to check.
    Code
      assert(d, x)
    Condition
      Error in `assert()`:
      ! Condition `x` must give `TRUE` or `FALSE`, not a double vector.
    Code
      assert(d, x > 0, !is.na(x))
    Condition
      Error in `assert()`:
      ! Assertion failed:
      * `x > 0`: 2 contradictions (1 missing) in 3 rows; rows 2, 3
      * `!is.na(x)`: 1 contradiction in 3 rows; row 3

