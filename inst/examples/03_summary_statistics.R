library(statart)
library(dplyr)

survey <- tibble(
  group = c("A", "A", "A", "B", "B", "B", NA, NA),
  income = c(1000, 2000, NA, 3000, 4000, 5000, NA, 8000),
  hours = c(20, 30, 40, NA, 35, 45, 25, NA),
  day = as.Date("2024-01-01") + 0:7
)
survey

# Standard and detailed summaries. Measured missing values are omitted.
summ(survey, income, hours)
summ(survey, income, .detail = TRUE)
tabstat(survey, income, hours) # Means by default.
tabstat(survey, income, .stat = c("n", "missing", "mean", "p50"))

# Compare with familiar base R calculations.
mean(survey$income, na.rm = TRUE) # 3833.333
median(survey$income, na.rm = TRUE) # 3500
sd(survey$income, na.rm = TRUE)

# Group means: A = 1500, B = 4000, missing group = 8000.
summ(survey, income, .by = group)
survey |> group_by(group) |> summ(income)

# This removes missing GROUP KEYS, rather than changing measured-value handling.
summ(survey, income, .by = group, .missing = FALSE)

# An explicit .by replaces existing grouping.
survey |> group_by(hours) |> summ(income, .by = group)

# Numeric and calendar summaries: compare the returned objects and column types.
separate <- summ(survey, income, day, .type = "list")
separate
class(separate)
separate$numeric
separate$date

combined <- summ(survey, income, day, .type = "table")
combined
str(combined) # Shared calendar/numeric locations are formatted as character.

# A vector keeps its expression as the variable name.
amounts <- c(10, 20, 30, NA)
summ(amounts)

# Keeping a text variable gives counts, rather than a numeric mean.
notes <- tibble(note = c("yes", "no", "yes", NA))
summ(notes, .keep_all = TRUE) # A nonnumeric-variable warning is expected.

# Factors are summarised by their level codes, with a warning.
categories <- tibble(response = factor(c("yes", "no", "yes", NA)))
summ(categories) # This mean is a mean of codes, not a meaningful survey score.
