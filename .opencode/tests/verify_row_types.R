# Verify installed type contracts and show selective research-facing output.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) {
  stop("Supply the fresh installed library path.")
}
.libPaths(c(args[[1L]], .libPaths()))
library(statart)
tests <- testthat::test_file(
  "tests/testthat/test-row-types.R",
  env = new.env(parent = asNamespace("statart")),
  reporter = "summary",
  stop_on_failure = TRUE
)
summary <- as.data.frame(tests)
stopifnot(
  !any(summary$failed),
  !any(summary$error),
  !any(summary$warning),
  !any(summary$skipped)
)
cat("\nVerified type-contract blocks:", nrow(summary), "\n")
cat("Passing expectations:", sum(summary$passed), "\n")

cat("\nLogical row maximum preserves the original meaning:\n")
flags <- tibble::tibble(a = c(TRUE, FALSE, NA), b = c(FALSE, NA, NA))
print(dplyr::mutate(
  flags,
  any_flag = row_max(a, b),
  true_count = row_sum(a, b)
))
cat("Maximum type:", typeof(row_max(flags)), "\n")

cat("\nDates remain dates in a subsequent research pipeline:\n")
dates <- tibble::tibble(
  interview = as.Date(c("2024-01-01", NA)),
  follow_up = as.Date(c("2024-01-03", "2024-01-05"))
)
print(dplyr::mutate(dates, latest = row_max(interview, follow_up)))

cat("\nCompatible duration units are normalized before addition:\n")
durations <- tibble::tibble(
  first = as.difftime(1, units = "hours"),
  second = as.difftime(60, units = "mins")
)
print(row_sum(durations))

cat("\nLarge offsets no longer cause negative sample variance:\n")
print(row_var(tibble::tibble(a = 1e12, b = 1e12 + 1)))
cat("PASS: all type contracts and selective outputs verified.\n")
