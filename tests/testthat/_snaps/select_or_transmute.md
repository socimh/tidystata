# select_or_transmute() reports unmatched and unrecognised input

    Code
      select_or_transmute(d, heigth, mas)
    Condition
      Error in `select_or_transmute()`:
      ! Can't select columns that don't exist: `heigth`, `mas` (the data have 2 columns).
      i Check the spelling, or name a computed value, e.g. `new = expression`.
    Code
      select_or_transmute(d, 4)
    Condition
      Error in `select_or_transmute()`:
      ! Can't select columns that don't exist: position 4 (the data have 2 columns).
      i Check the spelling, or name a computed value, e.g. `new = expression`.
    Code
      select_or_transmute(d, ratio = mass / missing_column)
    Condition
      Error in `select_or_transmute()`:
      ! Neither <tidy-select> nor <data-masking> recognised the input.
        select() error: the expression is not a column selection.
        mutate() error: i In argument: `ratio = mass/missing_column`. Caused by error: ! object 'missing_column' not found

