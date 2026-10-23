# destring() points dates to date functions

    Code
      out <- destring(c("2020-01-05", "bad", "x", "y"))
    Condition
      Warning in `destring()`:
      4 values are not numbers and became `NA`, such as "2020-01-05", "bad", and "x".
      i Use `ignore` to remove other characters first, as in `destring(x, ignore = "kg")`.
      i Dates need `as.Date()` or `lubridate::ymd()`, not `destring()`.

