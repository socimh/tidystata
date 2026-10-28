# summ() and tabstat() report invalid input

    Code
      summ(d, x, .sort = NA)
    Condition
      Error in `summ()`:
      ! `.sort` must be `TRUE` or `FALSE`, not `NA`.
    Code
      tabstat(d, x, .keep_all = 1)
    Condition
      Error in `tabstat()`:
      ! `.keep_all` must be `TRUE` or `FALSE`, not the number 1.
    Code
      summ(d, x, .stat = NA)
    Condition
      Error in `summ()`:
      ! `.stat` must be a character vector of non-missing statistic names.
    Code
      summ(d, x, .stat = c("mean", "middle"))
    Condition
      Error in `summ()`:
      ! Unsupported statistic: middle. See `?summ` for supported names.
    Code
      summ(d, when, .stat = "sum")
    Condition
      Error in `summ()`:
      ! Unsupported statistic `sum`: not supported for date/datetime/time variables.
    Code
      summ(d, x, .by = toupper(g))
    Condition
      Error in `summ()`:
      ! `.by` must select existing columns, not compute `toupper(g)`.
      i Create the grouping column first, e.g. `mutate(group = toupper(g))`, then use `.by = group`.
    Code
      summ(d, g)
    Message
      g is non-numeric and thus removed.
    Condition
      Error in `summ()`:
      ! None of the provided variable(s) is suitable for `summ()`.

---

    Code
      out <- summ(d, x, when, .stat = c("mean", "skew"))
    Condition
      Warning:
      `skew` is not available for date/datetime/time variables; skipped: when.

