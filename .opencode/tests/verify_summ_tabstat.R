# Run from the package root via the protected launcher. Pass a fresh library
# path produced by verify_package.py, then an optional distinct result prefix.
args <- commandArgs(trailingOnly = TRUE)
if (!length(args) || !dir.exists(args[[1]])) {
  stop("Pass the fresh installed library path from the verification paths JSON.")
}
.libPaths(c(normalizePath(args[[1]]), .libPaths()))
library(statart)
prefix <- if (length(args) > 1L) args[[2]] else ".opencode/results/summ-acceptance"
started <- proc.time()[["elapsed"]]
results <- testthat::test_dir(
  "tests/testthat", filter = "^summ-(acceptance|missing-statistics|contracts)$",
  reporter = "silent", stop_on_failure = FALSE, stop_on_warning = FALSE,
  load_package = "none"
)
summary <- as.data.frame(results)
write.csv(summary[setdiff(names(summary), "result")], paste0(prefix, "-scenarios.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
for (i in seq_len(nrow(summary))) {
  status <- if (summary$failed[[i]] || summary$error[[i]] || summary$warning[[i]] ||
                summary$skipped[[i]]) "FAIL" else "PASS"
  cat(status, "|", summary$test[[i]], "\n")
}
cat("SCENARIOS", nrow(summary), "ELAPSED", proc.time()[["elapsed"]] - started, "seconds\n")
print(colSums(summary[c("passed", "failed", "error", "warning", "skipped")]))
if (any(summary$failed > 0L | summary$error | summary$warning > 0L | summary$skipped)) {
  quit(status = 1L)
}

cat("\nBEGIN ACTUAL OUTPUT\n")
options(width = 120, tibble.width = 120)
show <- function(label, expression) {
  cat("\n", label, "\n", sep = "")
  cat(paste(deparse(substitute(expression)), collapse = "\n"), "\n")
  print(force(expression))
}
df <- tibble::tibble(g = c("A", "A", "B", NA), x = c(1, 3, NA_real_, 8))
show("Numeric summary", summ(df, x))
show("Default tabstat", tabstat(df, x))
show("Grouped aliases and sum", summ(df, x, .by = g, .stat = c("n", "missing", "p50", "sum")))
show("tabstat removes only missing grouping keys", tabstat(df, x, .by = g, .na.rm = TRUE,
                                                         .stat = c("n", "missing", "mean")))
show("Zero rows", summ(tibble::tibble(x = numeric()), .detail = TRUE))
show("SPSS user-missing codes", summ(tibble::tibble(x = haven::labelled_spss(c(1, 2, 99, NA),
                                                                            na_values = 99)),
                                    .stat = c("n", "missing", "unique", "mean", "sum")))
show("Counts-only text", tabstat(tibble::tibble(text = c("10", "20", "20", NA)),
                                .keep_all = TRUE, .stat = c("n", "unique", "mean", "sum")))
show("Reserved group name", summ(tibble::tibble(name = c("A", "A", "B"), x = c(1, 3, 8)),
                                x, .by = name, .stat = c("n", "mean")))
show("Compact datetime spread", summ(tibble::tibble(t = as.POSIXct("2024-01-01", tz = "UTC") + c(0, 1)),
                                    .stat = c("mean", "sd", "se"), .duration_format = "compact"))
show("Mixed calendar table", tabstat(tibble::tibble(x = c(1, 3), date = as.Date("2024-01-01") + 0:1),
                                    .mode = "table", .stat = c("n", "p50", "mean")))
cat("END ACTUAL OUTPUT\n")
