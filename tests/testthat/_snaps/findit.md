# findit() reports an invalid query

    Code
      findit(1 + 1)
    Condition
      Error in `findit()`:
      ! `command` must be one Stata word, an R function name or a quoted string, as in `findit(reg)`, `findit(left_join)` or `findit("merge 1:1 id")`.

# printing shows the single best entry or the first five

    Code
      print(best)
    Output
      # Stata to R: 10 entries
      # "merge" is a Stata command and an R function.
      
      ## Stata command
      
      # Keep matched rows only [dplyr]
      Stata: merge 1:1 id using data2, keep(match)
      R:     inner_join(data1, data2, by = "id")
      
      ## R function: merge() [base]: Merge two data frames (base R)
        Related Stata: merge
      
      # ... and 9 more. Use `print(n = Inf)` to see all, or `View()`.

---

    Code
      print(findit(reshape))
    Output
      # Stata to R: 2 entries
      
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
      # Stata to R: 10 entries
      
      ## Closest entries for "how do I remove duplicate rows"
      
      # Drop rows that duplicate an earlier row [tidystata]
      Stata: duplicates drop
      R:     duplicates_drop(data)
      
      # Keep the first row for each key [tidystata]
      Stata: duplicates drop x1 x2, force
      R:     duplicates_drop(data, x1, x2, .force = TRUE)
      
      # ... and 8 more. Use `print(n = Inf)` to see all, or `View()`.

---

    Code
      print(findit("count how many people in each category"), n = 2)
    Output
      # Stata to R: 12 entries
      # "count" is a Stata command and an R function.
      
      ## Closest entries for "count how many people in each category"
      
      # Frequency table by group [tidystata]
      Stata: bysort g: tabulate x
      R:     tab(data, x, .by = g)
      
      # Frequencies with frequency weights [tidystata]
      Stata: tabulate x [fweight = n]
      R:     tab(data, x, .wt = n)
      
      ## R function: count() [dplyr]: Count rows in each group
        Used in the entries above.
      
      # ... and 10 more. Use `print(n = Inf)` to see all, or `View()`.

