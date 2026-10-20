# s_merge() reports invalid input and failed assertions

    Code
      s_merge(people, 1:3, "1:1", by = "id")
    Condition
      Error in `s_merge()`:
      ! `.data` and `using` must be data frames.
    Code
      s_merge(people, income)
    Condition
      Error in `s_merge()`:
      ! Specify the key `relationship`: "1:1", "m:1" or "1:m".
    Code
      s_merge(people, income, "1:1", by = 1)
    Condition
      Error in `s_merge()`:
      ! `by` must be a character vector of key columns.
    Code
      s_merge(people, income, "1:1", by = "id", keep = "both")
    Condition
      Error in `s_merge()`:
      ! `keep` must contain "master", "using" and/or "match".
    Code
      s_merge(people, income, "1:1", by = "missing_key")
    Condition
      Error in `s_merge()`:
      ! Key column(s) not found in `.data`: `missing_key`.
    Code
      s_merge(people, income, "1:1", by = "id", generate = "age")
    Condition
      Error in `s_merge()`:
      ! Column `age` already exists; choose another `generate` name.
    Code
      s_merge(tibble::tibble(id = c(1, 1)), income, "1:1", by = "id", report = FALSE)
    Condition
      Error in `s_merge()`:
      ! Variable `id` does not uniquely identify rows in the master data (`.data`) (2 rows share a key).
      i Check the relationship, or see the rows with `duplicates_list()`.
    Code
      s_merge(people, income, "1:1", by = "id", assert = "match")
    Message
      Result                            Rows
      --------------------------------------
      Not matched                          2
          from master                      1  (.merge == "master only")
          from using                       1  (.merge == "using only")
      
      Matched                              2  (.merge == "matched")
      --------------------------------------
    Condition
      Error in `s_merge()`:
      ! Merge assertion failed: found 1 master only row(s) and 1 using only row(s); `assert` allows only matched.

