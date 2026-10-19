library(statart)
library(dplyr)

# Compare a base data frame with an equivalent tibble.
frame <- data.frame(group = c("A", "A", "B"), x = c(1, 3, 5))
tbl <- as_tibble(frame)
class(frame)
class(tbl)
class(tab(frame, group)) # data.frame
class(tab(tbl, group)) # tbl_df, tbl, data.frame
class(summ(frame, x))
class(summ(tbl, x))
class(codebook(frame))
class(codebook(tbl))

# Inspect the classes inside a list result, too.
frame_tables <- tab1(frame, group, x)
tbl_tables <- tab1(tbl, group, x)
class(frame_tables$group)
class(tbl_tables$group)
class(fre(frame, group, .type = "tibble")) # Explicit override.

# Zero rows are different from selecting no columns.
empty <- tibble(group = character(), x = numeric())
tab(empty, x)
summ(empty, x) # One summary row, with n = 0.
summ(empty, x, .by = group) # No groups, so zero summary rows.
codebook(empty)
tab(tbl, starts_with("absent"))
tab1(tbl, starts_with("absent")) # An empty list.
codebook(tbl, starts_with("absent"))

# All values missing: inspect the warning, counts, and returned values.
missing <- tibble(x = c(NA_real_, NA_real_), y = c(NA_real_, NA_real_))
summ(missing) # Entirely-missing warnings are expected.
tab(missing, x)
row_mean(missing) # NA, NA
row_sum(missing) # 0, 0
row_miss(missing) # 2, 2
row_unique(missing) # 1, 1

# List elements are counted as complete values, rather than flattened.
lists <- tibble(value = list(1:2, 1:2, NULL, NA))
lists
codebook(lists)
tab(lists, value)

# SPSS special missing values and Stata tagged missing values.
imported <- tibble(
  answer = haven::labelled_spss(
    c(1, 2, 99, NA),
    labels = c(Yes = 1, No = 2, Refused = 99),
    na_values = 99
  ),
  score = c(10, haven::tagged_na("a"), NA, 20)
)
codebook(imported)
tab(imported, answer)
summ(imported) # A labelled-variable warning is expected.
as_numeric(imported$answer) # Raw 99 is preserved by conversion.
is.na(imported$answer) # FALSE, FALSE, TRUE, TRUE

# A preview changes printing, not the rows available for analysis.
long_table <- tibble(id = 1:20, value = (1:20)^2)
preview <- preview_table(long_table, n = 4)
preview
nrow(preview) # Still 20.
sum(preview$value) # Still uses all rows.
sum(long_table$value)
slice_headtail(long_table, n = 4) # Actually selects four rows.
slice_interval(long_table, n = 4)
print_headtail(long_table, n = 4) # Prints a subset but returns the original.
print_interval(long_table, n = 4)
unpreview_table(preview)

# Preview settings follow a normal analysis pipeline.
preview |> filter(id > 5) |> mutate(twice = value * 2)
class(preview_table(frame)) # Preview over a data.frame.

# Compare statart results with independent base R calculations.
checks <- tibble(group = c("A", "B", "A", NA), x = c(1, NA, 3, 8))
tab(checks, group)
table(checks$group, useNA = "ifany")
summ(checks, x)
mean(checks$x, na.rm = TRUE) # 4
sd(checks$x, na.rm = TRUE)

# Deliberately invalid calls: uncomment and run ONE at a time to see each error.
# tab2(tbl, group)                     # Needs two variables.
# summ(tbl, x, .stat = "not_a_stat")   # Unknown statistic.
# cut_quantile(rep(1, 5))              # Cannot split a constant vector.
# preview_table(tbl, n = 0)            # n must be positive.
# row_mean(select(tbl, starts_with("absent"))) # No columns selected.
