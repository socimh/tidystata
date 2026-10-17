# Verify the installed preview contract independently of source loading.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) {
  stop("Supply the fresh installed library path.")
}
.libPaths(c(args[[1L]], .libPaths()))
library(statart)

results <- testthat::test_file(
  "tests/testthat/test-special-print.R",
  env = new.env(parent = asNamespace("statart")),
  reporter = "summary",
  stop_on_failure = TRUE
)
summary <- as.data.frame(results)
stopifnot(
  !any(summary$failed),
  !any(summary$error),
  !any(summary$warning),
  !any(summary$skipped)
)
cat("\nVerified preview blocks:", nrow(summary), "\n")
cat("Passing expectations:", sum(summary$passed), "\n")

cat("\nComplete data, first five and last five rows:\n")
x <- preview_table(tibble::tibble(id = 1:30, value = (1:30)^2))
print(x)
stopifnot(nrow(x) == 30L, sum(x$value) == sum((1:30)^2))
cat("\nAfter filtering and sorting, positions belong to the new result:\n")
print(dplyr::arrange(dplyr::filter(x, id > 10), dplyr::desc(value)))
cat("\nThe same data with five evenly spaced positions:\n")
print(preview_table(x, "interval", n = 5))
cat("PASS: installed preview contracts and selective output verified.\n")
