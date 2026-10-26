# Arguments shared across tidystata functions

Functions that take these arguments inherit their documentation from
this page with `@inheritParams tidystata_args`, so the wording stays
consistent.

## Arguments

- .data:

  A data frame, tibble, or data.table.

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping variables. Grouped data use their groups unless
  `.by` is supplied. Select existing columns only; create new grouping
  columns with
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
  first.
