# Demo: Persistent table previews and explicit row subsets
# Uses an installed tidystata package from a fresh verified build.

library(tidystata)

survey <- tibble::tibble(
  respondent_id = seq_len(36),
  region = rep(c("North", "South", "West"), each = 12),
  employed = rep(c("Yes", "No", "Student"), 12),
  age = 22 + seq_len(36),
  income_k = 32 + (seq_len(36) %% 11) * 3.5
)
survey$income_k[c(7, 19)] <- NA_real_

cat(
  "## Shared input\n",
  "\n",
  "```r\n",
  "library(tidystata)\n",
  "survey <- tibble::tibble(\n",
  "  respondent_id = seq_len(36),\n",
  "  region = rep(c(\"North\", \"South\", \"West\"), each = 12),\n",
  "  employed = rep(c(\"Yes\", \"No\", \"Student\"), 12),\n",
  "  age = 22 + seq_len(36),\n",
  "  income_k = 32 + (seq_len(36) %% 11) * 3.5\n",
  ")\n",
  "survey$income_k[c(7, 19)] <- NA_real_\n",
  "```\n",
  "\n",
  sep = ""
)

cat("## Example 1: Keep every respondent behind a head/tail preview\n\n")
cat(
  "```r\n",
  "prepared <- survey |>\n",
  "  preview_table(n = 5) |>\n",
  "  dplyr::mutate(income_log = log(income_k))\n",
  "print(prepared)\n",
  "```\n",
  "\n",
  "**Output:**\n",
  "\n",
  "```text\n",
  sep = ""
)
prepared <- survey |>
  preview_table(n = 5) |>
  dplyr::mutate(income_log = log(income_k))
print(prepared)
cat("```\n\n")
stopifnot(
  nrow(prepared) == 36L,
  inherits(prepared, "tidystata_preview"),
  identical(prepared$respondent_id, survey$respondent_id)
)

cat("\n## Example 2: Review positions along a sorted income distribution\n\n")
cat(
  "```r\n",
  "sorted <- prepared |>\n",
  "  dplyr::arrange(income_k, respondent_id) |>\n",
  "  preview_table(style = \"interval\", n = 6)\n",
  "print(sorted)\n",
  "```\n",
  "\n",
  "**Output:**\n",
  "\n",
  "```text\n",
  sep = ""
)
sorted <- prepared |>
  dplyr::arrange(income_k, respondent_id) |>
  preview_table(style = "interval", n = 6)
print(sorted)
cat("```\n\n")
stopifnot(nrow(sorted) == 36L, inherits(sorted, "tidystata_preview"))

cat("\n## Example 3: One-off print helpers retain the complete input\n\n")
cat(
  "```r\n",
  "headtail_result <- withVisible(print_headtail(survey, n = 5, width = 90))\n",
  "interval_result <- withVisible(print_interval(survey, n = 5, width = 90))\n",
  "```\n",
  "\n",
  "**Output:**\n",
  "\n",
  "```text\n",
  sep = ""
)
headtail_result <- withVisible(print_headtail(survey, n = 5, width = 90))
interval_result <- withVisible(print_interval(survey, n = 5, width = 90))
cat("```\n\n")
stopifnot(
  identical(headtail_result, list(value = survey, visible = FALSE)),
  identical(interval_result, list(value = survey, visible = FALSE))
)

cat(
  "\n## Example 4: Slice helpers deliberately produce smaller research samples\n\n"
)
cat(
  "```r\n",
  "ends <- slice_headtail(survey, n = 5)\n",
  "spaced <- slice_interval(survey, n = 5)\n",
  "print(ends)\n",
  "print(spaced)\n",
  "```\n",
  "\n",
  "**Output:**\n",
  "\n",
  "```text\n",
  sep = ""
)
ends <- slice_headtail(survey, n = 5)
spaced <- slice_interval(survey, n = 5)
print(ends)
print(spaced)
cat("```\n\n")
stopifnot(
  nrow(ends) == 5L,
  nrow(spaced) == 5L,
  identical(ends$respondent_id, c(1L, 2L, 3L, 35L, 36L)),
  !anyDuplicated(spaced$respondent_id)
)

cat(
  "\n## Example 5: Compact frequencies retain every category and respondent\n\n"
)
cat(
  "```r\n",
  "frequencies <- survey |>\n",
  "  tab(region, employed) |>\n",
  "  preview_table(n = 4) |>\n",
  "  dplyr::mutate(proportion = n / sum(n))\n",
  "print(frequencies)\n",
  "```\n",
  "\n",
  "**Output:**\n",
  "\n",
  "```text\n",
  sep = ""
)
frequencies <- survey |>
  tab(region, employed) |>
  preview_table(n = 4) |>
  dplyr::mutate(proportion = n / sum(n))
print(frequencies)
cat("```\n\n")
stopifnot(
  nrow(frequencies) == 9L,
  sum(frequencies$n) == nrow(survey),
  inherits(frequencies, "tidystata_preview")
)

cat(
  "\n## Example 6: Summary output remains available for subsequent analysis\n\n"
)
cat(
  "```r\n",
  "summary <- survey |>\n",
  "  summ(age, income_k, .by = region, .stat = c(\"n\", \"mean\", \"sd\")) |>\n",
  "  preview_table(n = 4)\n",
  "print(summary)\n",
  "```\n",
  "\n",
  "**Output:**\n",
  "\n",
  "```text\n",
  sep = ""
)
summary <- survey |>
  summ(age, income_k, .by = region, .stat = c("n", "mean", "sd")) |>
  preview_table(n = 4)
print(summary)
cat("```\n\n")
stopifnot(nrow(summary) == 6L, inherits(summary, "tidystata_preview"))

cat(
  "\n## Example 7: Grouped summaries and a long research table retain the style\n\n"
)
cat(
  "```r\n",
  "grouped <- prepared |>\n",
  "  dplyr::group_by(region)\n",
  "group_summary <- grouped |>\n",
  "  dplyr::summarise(\n",
  "    respondents = dplyr::n(),\n",
  "    mean_income_k = mean(income_k, na.rm = TRUE),\n",
  "    .groups = \"drop\"\n",
  "  )\n",
  "long_summary <- group_summary |>\n",
  "  tidyr::pivot_longer(\n",
  "    c(respondents, mean_income_k),\n",
  "    names_to = \"measure\",\n",
  "    values_to = \"value\"\n",
  "  )\n",
  "print(long_summary)\n",
  "```\n",
  "\n",
  "**Output:**\n",
  "\n",
  "```text\n",
  sep = ""
)
grouped <- prepared |>
  dplyr::group_by(region)
group_summary <- grouped |>
  dplyr::summarise(
    respondents = dplyr::n(),
    mean_income_k = mean(income_k, na.rm = TRUE),
    .groups = "drop"
  )
long_summary <- group_summary |>
  tidyr::pivot_longer(
    c(respondents, mean_income_k),
    names_to = "measure",
    values_to = "value"
  )
print(long_summary)
cat("```\n\n")
stopifnot(
  inherits(grouped, "tidystata_preview"),
  inherits(group_summary, "tidystata_preview"),
  inherits(long_summary, "tidystata_preview"),
  nrow(long_summary) == 6L
)

cat("\n## Example 8: Remove the preview before sharing an ordinary table\n\n")
cat(
  "```r\n",
  "ordinary <- unpreview_table(prepared)\n",
  "print(dplyr::slice_head(ordinary, n = 3))\n",
  "```\n",
  "\n",
  "**Output:**\n",
  "\n",
  "```text\n",
  sep = ""
)
ordinary <- unpreview_table(prepared)
print(dplyr::slice_head(ordinary, n = 3))
cat("```\n")
stopifnot(
  nrow(ordinary) == 36L,
  !inherits(ordinary, "tidystata_preview"),
  !inherits(tibble::as_tibble(prepared), "tidystata_preview"),
  !inherits(as.data.frame(prepared), "tidystata_preview"),
  identical(ordinary$income_log, prepared$income_log)
)
