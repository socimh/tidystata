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
      
      # merge() [base]: Merge two data frames (base R)
        Related Stata: merge
      
      # 9 more examples. To see them all: findit("merge 1:1 id, keep(match)") |> print(n = Inf)

---

    Code
      print(findit(reshape))
    Output
      # Wide to long [tidyr]
      Stata: reshape long var, i(id) j(year)
      R:     pivot_longer(data, starts_with("var"), names_to = "year", names_prefix = "var", values_to = "var")
      
      # Long to wide [tidyr]
      Stata: reshape wide var, i(id) j(year)
      R:     pivot_wider(data, names_from = year, values_from = var, names_prefix = "var")

# closest entries print under their own heading

    Code
      print(findit("how do I remove duplicate rows"), n = 2)
    Output
      # Closest entries for "how do I remove duplicate rows"
      
      # Drop rows that duplicate an earlier row [tidystata]
      Stata: duplicates drop
      R:     duplicates_drop(data)
      
      # Keep the first row for each key [tidystata]
      Stata: duplicates drop x1 x2, force
      R:     duplicates_drop(data, x1, x2, .force = TRUE)
      
      # 8 more examples. To see them all: findit("how do I remove duplicate rows") |> print(n = Inf)

---

    Code
      print(findit("count how many people in each category"), n = 2)
    Output
      # Closest entries for "count how many people in each category"
      
      # Frequency table by group [tidystata]
      Stata: bysort g: tabulate x
      R:     tab(data, x, .by = g)
      
      # Frequencies with frequency weights [tidystata]
      Stata: tabulate x [fweight = n]
      R:     tab(data, x, .wt = n)
      
      # count() [dplyr]: Count rows in each group
      
      # 10 more examples. To see them all: findit("count how many people in each category") |> print(n = Inf)

# printing colours headings, Stata code and R code

    Code
      print(findit("merge 1:1 id, keep(match)"))
    Output
      [1m# Keep matched rows only[22m[90m [dplyr][39m
      [34m[1mStata: [22mmerge 1:1 id using data2, keep(match)[39m
      [32m[1mR:     [22minner_join(data1, data2, by = "id")[39m
      
      [36m[1m# merge() [base]: Merge two data frames (base R)[22m[39m
        Related Stata: merge
      
      # 9 more examples. To see them all: findit("merge 1:1 id, keep(match)") |> print(n = Inf)

