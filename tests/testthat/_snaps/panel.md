# panel operators report invalid input

    Code
      s_lag(1:3)
    Condition
      Error in `s_lag()`:
      ! `time` must be supplied, such as `time = year`; it plays the role of the time variable in Stata's `xtset`.
    Code
      s_lag(1:3, n = -1, time = 1:3)
    Condition
      Error in `s_lag()`:
      ! `n` must be a whole number larger than or equal to 0, not the number -1.
    Code
      s_lag(1:3, time = 1:2)
    Condition
      Error in `s_lag()`:
      ! `time` must have the same length as `x`.
    Code
      s_lag(1:3, time = 1:3, delta = 0)
    Condition
      Error in `s_lag()`:
      ! `delta` must be positive.
    Code
      s_lag(1:3, time = c(1, 1, 2))
    Condition
      Error in `s_lag()`:
      ! Repeated time values within panel, such as 1.
      i Supply the panel identifier, such as `.by = id`, and check it with `isid(data, id, time)`.
    Code
      s_lag(1:3, time = c("a", "b", "c"))
    Condition
      Error in `s_lag()`:
      ! `time` must be numeric, a date, a date-time or a period, not a character vector.
      i Convert it first, such as `as.numeric(year)`, `as.Date(date)` or `factor(wave, levels = ..., ordered = TRUE)`.
    Code
      s_lag(1:3, time = factor(c("a", "b", "c")))
    Condition
      Error in `s_lag()`:
      ! `time` must be numeric, a date, a date-time or a period, not a <factor> object.
      i Its levels need not be in time order. Use `factor(wave, levels = ..., ordered = TRUE)`, or `as.numeric(as.character(year))` for numeric labels.
    Code
      s_lag(1:3, time = 1:3, unit = "day")
    Condition
      Error in `s_lag()`:
      ! `unit` applies to dates and date-times only.
    Code
      s_diff(letters[1:3], time = 1:3)
    Condition
      Error in `s_diff()`:
      ! `x` must be a numeric or logical vector, not a character vector.

