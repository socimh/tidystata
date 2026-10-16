# Collect every result, then return failure status for failed expectations/errors.
args <- commandArgs(trailingOnly = TRUE)
package_path <- if (length(args) >= 1L) args[[1]] else "."
prefix <- if (length(args) >= 2L) args[[2]] else ".opencode/results/current"
filter <- if (length(args) >= 3L && nzchar(args[[3]])) args[[3]] else NULL
dir.create(dirname(prefix), recursive = TRUE, showWarnings = FALSE)
pkgload::load_all(package_path, compile = FALSE, quiet = TRUE)
results <- testthat::test_dir(
  file.path(package_path, "tests", "testthat"),
  filter = filter,
  reporter = "silent",
  stop_on_failure = FALSE,
  stop_on_warning = FALSE,
  load_package = "none"
)
summary <- as.data.frame(results)
write.csv(
  summary[setdiff(names(summary), "result")],
  paste0(prefix, ".csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
saveRDS(results, paste0(prefix, ".rds"))
details <- list()
for (block in results) {
  for (expectation in block$results) {
    if (
      inherits(
        expectation,
        c(
          "expectation_failure",
          "expectation_error",
          "expectation_warning",
          "expectation_skip"
        )
      )
    ) {
      details[[length(details) + 1L]] <- data.frame(
        file = block$file,
        test = block$test,
        type = class(expectation)[[1]],
        message = conditionMessage(expectation),
        stringsAsFactors = FALSE
      )
    }
  }
}
detail_table <- if (length(details)) {
  do.call(rbind, details)
} else {
  data.frame(
    file = character(),
    test = character(),
    type = character(),
    message = character()
  )
}
write.csv(
  detail_table,
  paste0(prefix, "-details.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
totals <- colSums(summary[c("passed", "failed", "error", "warning", "skipped")])
print(totals)
cat("Test blocks:", nrow(summary), "\n")
cat("Results:", prefix, "\n")
if (totals[["failed"]] > 0L || totals[["error"]] > 0L) {
  quit(status = 1L)
}
