library(statart)
library(dplyr)

survey <- tibble(
  group = c("A", "A", "A", "B", "B", "B", NA, NA),
  sex = factor(c("f", "m", NA, "f", "m", "m", "f", NA))
)
survey

# Three f, three m, and two missing values.
# percent uses all eight rows; valid excludes missing sex values.
tab(survey, sex)
tab(survey, sex, .desc = TRUE)

# Save a result and continue manipulating it.
counts <- tab(survey, sex)
class(counts)
counts$n
sum(counts$n) # 8
sum(counts$percent) # 100
sum(counts$valid, na.rm = TRUE) # 100
filter(counts, !is.na(sex))
mutate(counts, proportion = percent / 100)

# Joint frequencies, separate one-way tables, and a stacked result.
tab(survey, group, sex)
tab1(survey, group, sex)
tab1(survey, group, sex, .type = "tibble")

# Cross-tabulations, with either variable in the rows.
tab2(survey, group, sex)
tab2(survey, group, sex, .flip = TRUE)

# Add totals explicitly.
fre(survey, sex)
fre1(survey, group, sex)
fre2(survey, group, sex)

# Percentages are calculated within each group, including the missing group.
tab(survey, sex, .by = group)
survey |> group_by(group) |> tab(sex)
fre(survey, sex, .by = group)

# The package also includes a real example dataset.
data("lifeexp", package = "statart")
codebook(lifeexp)
tab(lifeexp, region)
fre(lifeexp, region) # Displays the value labels.

# Optional rich output: install flextable first, then run this line.
fre(survey, sex, .type = "flextable")
