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

