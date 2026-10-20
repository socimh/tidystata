library(statart)
library(dplyr)

# Convert labels and formatted numbers; replace a special missing code.
survey <- tibble(
  response = haven::labelled(c(1, 2, NA), c(Yes = 1, No = 2)),
  amount = c("$1,200", "$900", ""),
  quality = c(1L, 99L, 2L)
)
survey
mutate(
  survey,
  response = mvencode(decode(response), "Unknown"),
  amount = destring(amount),
  quality = mvdecode(quality, 99L)
)

# Parsing keeps the position of an invalid value and issues a warning.
parsed <- destring(c("10", "bad", "30"))
parsed # 10, NA, 30
readr::problems(parsed)

# Factors: compare labels with numeric LEVEL CODES.
response <- factor(c("yes", "no", NA), levels = c("no", "yes"))
decode(response)
destring(response) # 2, 1, NA

# Row calculations omit missing values. All-missing row sums are zero.
scores <- tibble(
  score1 = c(10, 20, NA, 30, NA),
  score2 = c(12, NA, NA, 32, NA)
)
scores
row_mean(scores) # 11, 20, NA, 31, NA
row_sum(scores) # 22, 20, 0, 62, 0
row_min(scores)
row_max(scores)
row_median(scores)
row_sd(scores)
row_var(scores)
row_miss(scores)
row_non_miss(scores)
row_unique(scores) # A missing value counts as one distinct category.

# The same helpers can be used directly in mutate().
mutate(
  scores,
  average = row_mean(pick(score1, score2)),
  total = row_sum(pick(score1, score2)),
  observed = row_non_miss(pick(score1, score2))
)

# Check that logical/integer extrema retain their types.
flags <- tibble(a = c(TRUE, FALSE, NA), b = c(FALSE, NA, NA))
row_max(flags)
typeof(row_max(flags)) # logical
integers <- tibble(a = c(1L, 4L), b = c(3L, 2L))
row_min(integers)
typeof(row_min(integers)) # integer

# Quantile groups, equal-width groups, and your own cut point.
amounts <- c(1:8, NA)
xtile(amounts, n = 2)
cut_length(amounts, n = 2)
cut_breaks(amounts, breaks = 4)

# Ties stay together; fewer than four intervals and a warning are expected.
tied <- c(rep(1, 8), 2, 3)
xtile(tied, n = 4)

# Repeat random draws and time an expression.
set_seed(runif(4), 2026)
set_seed(runif(4), 2026) # The same four values.
timer(sum(seq_len(100000)))
