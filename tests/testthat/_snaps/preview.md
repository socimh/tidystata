# previews report invalid input

    Code
      preview(1:3)
    Condition
      Error in `preview()`:
      ! `.data` must be an in-memory data frame, data.table, sf data frame, or ordinary/grouped/rowwise tibble.
      i Collect lazy tables and convert other subclasses explicitly with `tibble::as_tibble()`; apply the wrapper to each table in a list.
    Code
      preview(tibble::tibble(x = 1), n = 0)
    Condition
      Error in `preview()`:
      ! `n` must be a single positive whole number or `Inf`.
    Code
      preview_headtail(tibble::tibble(x = 1), n = 2.5)
    Condition
      Error in `preview()`:
      ! `n` must be a single positive whole number or `Inf`.

