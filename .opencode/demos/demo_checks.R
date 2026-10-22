# Demo: assert(), is_first() and print_all(), like Stata's assert, egen tag()
# and list. Runs against the fresh installation selected by the demo workflow.
library(statart)

cat("## Example 1: assertions inside a pipeline\n\n```\n")
checked <- lifeexp |>
  assert(lexp > 0, popgrowth < 10) |>
  summ(lexp)
print(checked)
message_text <- tryCatch(
  assert(lifeexp, safewater > 50, popgrowth < 1),
  error = conditionMessage
)
cat(message_text, "\n")
stopifnot(grepl("contradictions", message_text))

cat("```\n\n## Example 2: flag one row per group\n\n```\n")
panel <- tibble::tibble(
  id = c(1, 1, 2, 2, 2, NA),
  year = c(2001, 2002, 2001, 2002, 2003, 2001)
)
flagged <- dplyr::mutate(panel, first = is_first(id))
print(flagged)
stopifnot(sum(flagged$first) == 2L)

cat("```\n\n## Example 3: list every row and column\n\n```\n")
print_all(head(lifeexp, 12))
cat("```\n")
