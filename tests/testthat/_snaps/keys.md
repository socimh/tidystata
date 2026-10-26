# key checks report invalid input and repeated keys

    Code
      isid(d, id, .missing = NA)
    Condition
      Error in `isid()`:
      ! `.missing` must be `TRUE` or `FALSE`, not `NA`.
    Code
      isid(d, id)
    Condition
      Error in `isid()`:
      ! `id` should never be missing to identify rows.
      i Use `.missing = TRUE` to allow missing key values.
    Code
      isid(d, id, .missing = TRUE)
    Condition
      Error in `isid()`:
      ! Variable `id` does not uniquely identify the rows: 1 value appears more than once (2 rows).
      i See them with `duplicates_list()`.
    Code
      duplicates_tag(d, id, .name = "")
    Condition
      Error in `duplicates_tag()`:
      ! `.name` must be a non-empty string, not `""`.
    Code
      duplicates_tag(d, id, .name = "x")
    Condition
      Error in `duplicates_tag()`:
      ! Column `x` already exists; choose another `.name`.
    Code
      duplicates_drop(d, id)
    Condition
      Error in `duplicates_drop()`:
      ! Rows sharing variable `id` differ in other columns, so dropping them loses data.
      i Use `.force = TRUE` to keep the first row of each set anyway.
    Code
      isid(1:3)
    Condition
      Error in `isid()`:
      ! `.data` must be a data frame, not an integer vector.

# isid() success messages name the checked keys

    Code
      isid(tibble::tibble(id = 1:2), id)
    Message
      Variable `id` uniquely identifies the rows.
    Code
      isid(dplyr::distinct(panel), id, wave)
    Message
      Variables `id`, `wave` together uniquely identify the rows.
    Code
      isid(panel[0, ], id, wave)
    Message
      No rows to check.

