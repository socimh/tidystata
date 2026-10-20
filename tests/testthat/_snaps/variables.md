# variables_search() reports an invalid query

    Code
      variables_search(d, c("a", "b"))
    Condition
      Error in `variables_search()`:
      ! `string` must be a single string, not a character vector.
    Code
      variables_search(d, NA_character_)
    Condition
      Error in `variables_search()`:
      ! `string` must be a single string, not a character `NA`.

