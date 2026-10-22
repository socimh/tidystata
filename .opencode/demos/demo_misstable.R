# Demo: missing-value summaries and patterns, like Stata's misstable.
# Runs against the fresh installation selected by the demo workflow.
library(tidystata)

cat("## Example 1: missing values by variable\n\n```\n")
summary <- misstable(starwars)
print(summary)
stopifnot(all(summary$miss_n > 0L))

cat("```\n\n## Example 2: every variable, by group\n\n```\n")
print(misstable(starwars, height, mass, .by = sex, .all = TRUE))

cat(
  "```\n\n## Example 3: missing patterns (1 = observed, 0 = missing)\n\n```\n"
)
patterns <- misstable(starwars, height, mass, birth_year, .patterns = TRUE)
print(patterns)
stopifnot(sum(patterns$n) == nrow(starwars))
cat("```\n")
