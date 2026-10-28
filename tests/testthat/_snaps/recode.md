# malformed rules and inputs give informative errors

    Code
      stata_recode(x, 5:1 ~ 1)
    Condition
      Error in `stata_recode()`:
      ! The range in rule 1 must run from low to high.
      x `5:1` has a lower bound above its upper bound.

---

    Code
      stata_recode(x, 1 ~ "a")
    Condition
      Error in `stata_recode()`:
      ! The code in rule 1 must be a single number or `NA`.
      x `"a"` is a string.

