# Run these lines one at a time in RStudio.
library(statart)
library(dplyr)

# A small survey, including missing values and a variable label.
survey <- tibble(
  id = 1:6,
  group = c("A", "A", "B", "B", NA, "B"),
  age = c(22, 35, 40, NA, 28, 51),
  income = c(1000, 2000, 3000, NA, 1500, 5000),
  score1 = c(10, 20, NA, 30, 40, NA),
  score2 = c(12, NA, NA, 32, 42, NA)
)
attr(survey$income, "label") <- "Monthly earnings"
survey

# One row per variable: type, nonmissing count, unique count, and label.
codebook(survey)
codebook(survey, age, income)

# List variables and search either their names or their labels.
variables(survey)
variables_search(survey, "score")
variables_search(survey, "earn") # Finds income through its label.
variables_search(survey, "absent") # An empty table is expected.

# Names as a character vector or as a one-column table.
ds(survey)
ds(survey, age:income)
ds(survey, varlist("score?"))
ds(survey, starts_with("score"), .type = "table")
ds(survey, age, income, .type = "table")

# Select, rename, or calculate columns.
s_select(survey, id, age, income)
s_select(survey, person = id, income)
s_select(survey, income, annual_income = income * 12)

# Grouping affects selection; codebook still describes the whole input.
grouped <- group_by(survey, group)
ds(grouped, income) # The grouping column can be reinserted.
ds(ungroup(grouped), income)
codebook(grouped, income) # Five observed income values overall.

# Column names containing spaces are supported with backticks.
unusual <- data.frame(check.names = FALSE, "annual income" = c(100, 200, NA))
codebook(unusual)
s_select(unusual, `annual income`)

# Optional: run this line yourself to open RStudio's data viewer.
# browse(survey, id, age, income)
