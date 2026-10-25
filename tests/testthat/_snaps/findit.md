# findit() reports an invalid query

    Code
      findit(1 + 1)
    Condition
      Error in `findit()`:
      ! `command` must be one Stata word, an R function name or a quoted string, as in `findit(reg)`, `findit(left_join)` or `findit("merge 1:1 id")`.

# printing shows clear defaults and offers remaining entries

    Code
      print(best)
    Output
      # Keep matched rows only [dplyr]
      Stata: merge 1:1 id using data2, keep(match)
      R:     inner_join(data1, data2, by = "id")
      # Note: dplyr retains overlapping non-key columns with suffixes instead of Stata master values, creates no _merge, and does not enforce a declared 1:1 key constraint.
      
      # merge() [base]: Merge two data frames (base R)
        Related Stata: merge
      
      # 17 more examples. To see them all: findit("merge 1:1 id, keep(match)") |> print(n = Inf)

---

    Code
      print(findit(reshape))
    Output
      # Wide to long [tidyr]
      Stata: reshape long var, i(id) j(year)
      R:     tidyr::pivot_longer(data, tidyselect::starts_with("var"), names_to = "year", names_prefix = "var", names_transform = list(year = as.integer), values_to = "var")
      # Note: Converts numeric suffixes to integer year values, matching reshape long without string. pivot_longer() returns a text year without names_transform and does not enforce reshape i()/j() uniqueness constraints.
      
      # Long to wide [tidyr]
      Stata: reshape wide var, i(id) j(year)
      R:     pivot_wider(data, names_from = year, values_from = var, names_prefix = "var")
      # Note: Duplicate keys can create list-columns in pivot_wider(); Stata reshape wide rejects duplicate i()/j() combinations. Validate keys first.
      
      # reshape() [stats]: Reshape Grouped Data
        Related Stata: icc
      
      # 7 more examples. To see them all: findit(reshape) |> print(n = Inf)

# closest entries print under their own heading

    Code
      print(findit("how do I remove duplicate rows"), n = 2)
    Output
      # Closest entries for "how do I remove duplicate rows"
      
      # Drop rows that duplicate an earlier row [tidystata]
      Stata: duplicates drop
      R:     duplicates_drop(data)
      # Source: https://www.stata.com/manuals/dduplicates.pdf
      # R reference: https://socimh.github.io/tidystata/reference/
      
      # Keep the first row for each key [tidystata]
      Stata: duplicates drop x1 x2, force
      R:     duplicates_drop(data, x1, x2, .force = TRUE)
      # Note: distinct(data, x1, x2, .keep_all = TRUE) is the dplyr version.
      # Source: https://www.stata.com/manuals/dduplicates.pdf
      # R reference: https://socimh.github.io/tidystata/reference/
      
      # 8 more examples. To see them all: findit("how do I remove duplicate rows") |> print(n = Inf)

---

    Code
      print(findit("count how many people in each category"), n = 2)
    Output
      # Closest entries for "count how many people in each category"
      
      # Replace observations with category frequencies [dplyr]
      Stata: contract g, freq(n)
      R:     data <- dplyr::count(data,g,name='n')
      # Source: https://www.stata.com/manuals/dcontract.pdf
      # R reference: https://dplyr.tidyverse.org/reference/index.html
      
      # Create category frequencies and percentages [dplyr]
      Stata: contract g, freq(n) percent(p)
      R:     data <- dplyr::count(data,g,name='n'); data$p <- 100*data$n/sum(data$n)
      # Source: https://www.stata.com/manuals/dcontract.pdf
      # R reference: https://dplyr.tidyverse.org/reference/index.html
      
      # 20 more examples. To see them all: findit("count how many people in each category") |> print(n = Inf)

# printing colours headings, Stata code and R code

    Code
      print(findit("merge 1:1 id, keep(match)"))
    Output
      [1m# Keep matched rows only[22m[90m [dplyr][39m
      [34m[1mStata: [22mmerge 1:1 id using data2, keep(match)[39m
      [32m[1mR:     [22minner_join(data1, data2, by = "id")[39m
      # Note: dplyr retains overlapping non-key columns with suffixes instead of Stata master values, creates no _merge, and does not enforce a declared 1:1 key constraint.
      
      [36m[1m# merge() [base]: Merge two data frames (base R)[22m[39m
        Related Stata: merge
      
      # 17 more examples. To see them all: findit("merge 1:1 id, keep(match)") |> print(n = Inf)

