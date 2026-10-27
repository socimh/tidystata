# pwcorr() reports invalid input

    Code
      pwcorr(d, x, y, .wide = NA)
    Condition
      Error in `pwcorr()`:
      ! `.wide` must be `TRUE` or `FALSE`, not `NA`.
    Code
      pwcorr(d, x, s)
    Condition
      Error in `pwcorr()`:
      ! `s` must be numeric or logical to be correlated.
    Code
      pwcorr(d, x)
    Condition
      Error in `pwcorr()`:
      ! Select at least two numeric variables to correlate.
    Code
      pwcorr(d, x, y, .wt = x, .method = "spearman")
    Condition
      Error in `pwcorr()`:
      ! `.wt` is supported for Pearson correlations only.

# pwcorr() validates .listwise and .adjust

    Code
      pwcorr(d, x, y, .listwise = "yes")
    Condition
      Error in `pwcorr()`:
      ! `.listwise` must be `TRUE` or `FALSE`, not a string.
    Code
      pwcorr(d, x, y, .adjust = "holm")
    Condition
      Error in `pwcorr()`:
      ! `.adjust` must be one of "none", "bonferroni", or "sidak", not "holm".
    Code
      pwcorr(d, x, y, .wide = TRUE, .adjust = "sidak")
    Condition
      Error in `pwcorr()`:
      ! `.adjust` needs p-values, which `.wide = TRUE` omits.

