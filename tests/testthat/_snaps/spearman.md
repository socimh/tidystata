# spearman() reports invalid input

    Code
      spearman(d, x, y, .pairwise = NA)
    Condition
      Error in `spearman()`:
      ! `.pairwise` must be `TRUE` or `FALSE`, not `NA`.
    Code
      spearman(d, x, s)
    Condition
      Error in `spearman()`:
      ! `s` must be numeric or logical to be correlated.
    Code
      spearman(d, x, y, .wide = TRUE, .adjust = "bonferroni")
    Condition
      Error in `spearman()`:
      ! `.adjust` needs p-values, which `.wide = TRUE` omits.
    Code
      spearman(d, x, y, .adjust = "holm")
    Condition
      Error in `spearman()`:
      ! `.adjust` must be one of "none", "bonferroni", or "sidak", not "holm".

