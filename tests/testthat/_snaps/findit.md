# findit() reports an invalid query

    Code
      findit(1 + 1)
    Condition
      Error in `findit()`:
      ! `command` must be one Stata word, an R function name or a quoted string, as in `findit(reg)`, `findit(left_join)` or `findit("merge 1:1 id")`.

# closest entries print under their own heading

    Code
      print(findit("how do I remove duplicate rows"), n = 2)
    Output
      # Stata to R: 10 entries
      
      ## Closest entries for "how do I remove duplicate rows"
      duplicates drop               # Drop rows that duplicate an earlier row [tidystata]
        duplicates_drop(data)
      duplicates drop x1 x2, force  # Keep the first row for each key [tidystata]
        duplicates_drop(data, x1, x2, .force = TRUE)
      
      # ... and 8 more. Use `print(n = Inf)` to see all, or `View()`.

---

    Code
      print(findit("count how many people in each category"), n = 2)
    Output
      # Stata to R: 12 entries
      # "count" is a Stata command and an R function.
      
      ## Closest entries for "count how many people in each category"
      bysort g: tabulate x      # Frequency table by group [tidystata]
        tab(data, x, .by = g)
      tabulate x [fweight = n]  # Frequencies with frequency weights [tidystata]
        tab(data, x, .wt = n)
      
      ## R function: count() [dplyr]: Count rows in each group
        Used in the entries above.
      
      # ... and 10 more. Use `print(n = Inf)` to see all, or `View()`.

