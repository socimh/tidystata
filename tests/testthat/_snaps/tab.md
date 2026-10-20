# tabulation reports invalid input

    Code
      tab(d, a, .total = NA)
    Condition
      Error in `tab()`:
      ! `.total` must be `TRUE` or `FALSE`, not `NA`.
    Code
      tab(list(1, 2))
    Condition
      Error in `tab()`:
      ! `.data` must be a data frame or an atomic vector, not a list.
    Code
      tab(1:3, a)
    Condition
      Error in `tab()`:
      ! For vector input, omit selectors in `...`.
    Code
      tab2(d, a)
    Condition
      Error in `tab2()`:
      ! Only 1 variable is input.
      i Provide two variables for cross-tabulation, or more for every pairwise table.
    Code
      fre2(d, a)
    Condition
      Error in `fre2()`:
      ! Only 1 variable is input.
      i Provide two variables for cross-tabulation, or more for every pairwise table.
    Code
      tab2(d, a, b, .by = a)
    Condition
      Error in `tab2()`:
      ! `.by` is not supported by `tab2()`; cross-tabulations have no groups or category sorting.
      i Use `tab()` or `fre()` with `.by`, or filter the data first.
    Code
      tab2(d, a, b, .wt = w, .wt_type = "analytic", .chi2 = TRUE)
    Condition
      Error in `tab2()`:
      ! `.chi2` is not available with analytic weights, whose counts are not observation counts.
      i For sampling weights, use `survey::svychisq()`.
    Code
      tab(d, a, .wt = c(1, 2, 3))
    Condition
      Error in `tab()`:
      ! `.wt` must have one value per row (2), not 3.
    Code
      tab(d, a, .wt = c(-1, 2))
    Condition
      Error in `tab()`:
      ! `.wt` must not be negative.

---

    Code
      out <- tab(tibble::tibble(n = 1:2), n)
    Message
      `n` renamed to `.n` because `tab()` output uses `n`.
      i Rename the input column before calling `tab()` to choose another name.

