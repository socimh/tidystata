# Demo: Stata-style key checks and duplicate handling.
# Runs against the fresh installation selected by the demo workflow.
library(tidystata)

panel <- tibble::tibble(
  id = c(1, 1, 2, 2, 3),
  wave = c(1, 2, 1, 1, 1),
  score = c(5, 6, 7, 7, 8)
)

cat("## Example 1: isid() asserts a key inside a pipeline\n\n```\n")
print(tryCatch(isid(panel, id, wave), error = conditionMessage))
stopifnot(isTRUE(capture(isid(panel[-4, ], id, wave))))
stopifnot(!capture(isid(panel, id)))

cat("```\n\n## Example 2: duplicates report, tag and list\n\n```\n")
print(duplicates_report(panel, id))
print(duplicates_tag(panel, id, wave))
listed <- duplicates_list(panel, id, wave)
print(listed)
stopifnot(identical(listed$.row, c(3L, 4L)))

cat(
  "```\n\n## Example 3: dropping duplicates guards against data loss\n\n```\n"
)
print(tryCatch(duplicates_drop(panel, id), error = conditionMessage))
kept <- duplicates_drop(panel)
print(kept)
stopifnot(identical(nrow(kept), 4L))

cat("```\n\n## Example 4: renamed functions\n\n```\n")
print(xtile(c(0, 0, 0, 1, 1), 2))
print(ds(panel, varlist("i* w?ve")))
stopifnot(identical(ds(panel, varlist("i* w?ve")), c("id", "wave")))

cat("```\n\n## Example 5: s_merge() reports matches like Stata\n\n```\n")
people <- tibble::tibble(id = 1:3, age = c(30, 41, 25))
income <- tibble::tibble(id = c(2L, 3L, 4L), income = c(10, 20, 30))
merged <- s_merge(people, income, "1:1", by = "id")
print(merged)
stopifnot(identical(
  as.character(merged$.merge),
  c("master only", "matched", "matched", "using only")
))
print(tryCatch(
  s_merge(people, income, "1:1", by = "id", assert = "match"),
  error = conditionMessage
))

cat(
  "```\n\n## Example 6: tab2() cross-tabulates, optionally with totals\n\n```\n"
)
print(tab2(starwars, sex, gender))
print(tab2(starwars, sex, gender, .total = TRUE))
cat("```\n\n## Example 7: duplicate metadata is safe for grouped data\n\n```\n")
grouped <- dplyr::group_by(panel, id)
listed <- duplicates_list(grouped, id, wave)
print(listed)
stopifnot(identical(dplyr::group_vars(listed), "id"))
collision <- dplyr::mutate(panel, .row = seq_len(nrow(panel)))
print(tryCatch(duplicates_list(collision, id), error = conditionMessage))
stopifnot(identical(collision$.row, seq_len(nrow(panel))))
cat("```\n")
