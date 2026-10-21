# Demo: frequency and analytic weights, like Stata's [fw] and [aw].
# Runs against the fresh installation selected by the demo workflow.
library(statart)

survey <- tibble::tibble(
  region = c("north", "north", "north", "south", "south"),
  edu = c("low", "high", "high", "low", "high"),
  income = c(10, 20, 40, 5, 8),
  w = c(3, 1, 1, 2, 2)
)
replicated <- survey[rep(seq_len(nrow(survey)), survey$w), ]

cat("## Example 1: frequency weights count each row w times\n\n```\n")
weighted <- tab(survey, edu, .wt = w)
print(weighted)
stopifnot(all.equal(weighted$n, as.double(tab(replicated, edu)$n)))

cat("```\n\n## Example 2: analytic weights keep the sample scale\n\n```\n")
analytic <- tab(survey, edu, .by = region, .wt = w, .wt_type = "analytic")
print(analytic)
stopifnot(all.equal(sum(analytic$n), nrow(survey)))

cat("```\n\n## Example 3: weighted cross-tabulation with totals\n\n```\n")
print(tab2(survey, region, edu, .wt = w, .total = TRUE))

cat("```\n\n## Example 4: weighted summaries\n\n```\n")
stats <- c("n", "mean", "sd", "p50")
by_region <- summ(survey, income, .by = region, .wt = w, .stat = stats)
print(by_region)
stopifnot(all.equal(
  by_region$mean,
  summ(replicated, income, .by = region, .stat = "mean")$mean
))
print(summ(survey, income, .wt = w, .wt_type = "analytic", .stat = stats))

cat("```\n\n## Example 5: weighted quantile groups\n\n```\n")
print(xtile(survey$income, 2, wt = survey$w))
cat("```\n\n## Example 6: analytic weights keep their scale safely\n\n```\n")
large <- tibble::tibble(edu = c("low", "high", "high"), w = rep(1e308, 3))
stable <- tab(large, edu, .wt = w, .wt_type = "analytic")
print(stable)
stopifnot(isTRUE(all.equal(stable$n, c(2, 1))))
cat("```\n")
