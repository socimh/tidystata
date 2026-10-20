# missing-value conversion reports missing arguments

    Code
      mvdecode(1)
    Condition
      Error in `mvdecode()`:
      ! Missing `mv`. Use `mvdecode(x, mv)` or `x |> mvdecode(mv)`.
    Code
      mvencode()
    Condition
      Error in `mvencode()`:
      ! Missing `x`. Use `mvencode(x, mv)` or `x |> mvencode(mv)`.
    Code
      na_if_value(1)
    Condition
      Error in `na_if_value()`:
      ! Missing `.value`. Use `na_if_value(x, value)` or `x |> na_if_value(value)`.
    Code
      value_if_na(.value = 1)
    Condition
      Error in `value_if_na()`:
      ! Missing `.x`. Use `value_if_na(x, replacement)` or `x |> value_if_na(replacement)`.
    Code
      mvencode(haven::labelled_spss(c(1, NA), na_values = 9), c(1, 2))
    Condition
      Error in `mvencode()`:
      ! `mv` must be a single replacement value.

