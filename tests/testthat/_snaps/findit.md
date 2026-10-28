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
      
      # 12 broader merge examples. Browse the family: findit(merge)

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
      
      # Convert a wide measurement stub to long rows [tidyr]
      Stata: reshape long x, i(id) j(wave)
      R:     data <- tidyr::pivot_longer(data,cols=c(x1,x2),names_to='wave',names_prefix='x',names_transform=list(wave=as.integer),values_to='x')
      # Note: Fixed x1/x2 stub example; source names, stub and output names must be changed together.
      
      # Convert unique long measurements to wide columns [tidyr]
      Stata: reshape wide x, i(id) j(wave)
      R:     data <- tidyr::pivot_wider(data,id_cols=id,names_from=wave,values_from=x,names_prefix='x')
      # Note: Requires unique id-wave pairs; duplicates must be resolved explicitly rather than silently aggregated.
      
      # Reshape multiple parallel measurement stubs [tidyr]
      Stata: reshape long x y, i(id) j(wave)
      R:     data <- tidyr::pivot_longer(data,cols=c(x1,x2,y1,y2),names_to=c('.value','wave'),names_pattern='([xy])([12])',names_transform=list(wave=as.integer))
      # Note: Fixed two-stub example; all name patterns and source names must be changed together.
      
      # reshape() [stats]: Reshape Grouped Data
        Related Stata: icc
      
      # 4 more relevant examples. To see them all: findit(reshape) |> print(n = Inf)

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
      
      # Retain the first observation per duplicated key [tidystata]
      Stata: duplicates drop id, force
      R:     data <- tidystata::duplicates_drop(data, id, .force = TRUE)
      # Source: https://www.stata.com/manuals/d.pdf
      # R reference: https://socimh.github.io/tidystata/reference/keys.html
      
      # 8 more relevant examples. To see them all: findit("how do I remove duplicate rows") |> print(n = Inf)
      # Only the 10 best candidates are retained; refine the query for a closer match.

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
      
      # 8 more relevant examples. To see them all: findit("count how many people in each category") |> print(n = Inf)
      # Only the 10 best candidates are retained; refine the query for a closer match.
      # 10 broader count examples. Browse the family: findit(count)

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
      
      # 12 broader merge examples. Browse the family: findit(merge)

