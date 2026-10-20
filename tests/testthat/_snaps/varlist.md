# varlist() reports invalid patterns

    Code
      varlist(1, vars = "x1")
    Condition
      Error in `varlist()`:
      ! `string` must be a character vector, not the number 1.
    Code
      varlist("x[1-2][3-4]", vars = "x1")
    Condition
      Error in `varlist()`:
      ! Only one range is allowed.
    Code
      varlist("x[3-1]", vars = "x1")
    Condition
      Error in `varlist()`:
      ! The number range should start with a smaller number.

