# Protected-launcher entry point; first argument is a fresh installed library.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) >= 1L, dir.exists(args[[1]]))
.libPaths(c(normalizePath(args[[1]]), .libPaths()))
library(statart)
prefix <- if (length(args) >= 2L) args[[2]] else ".opencode/results/tabulation-acceptance"
filter <- if (length(args) >= 3L) args[[3]] else "^(tab|fre)"
env <- new.env(parent = asNamespace("statart"))
for (file in c("R/tab.R", "R/tab-helpers.R", "R/type_conversion.R",
               list.files("tests/testthat", pattern = "^test-tab-(coverage-|labelled-conversion)", full.names = TRUE))) {
  parse(file = file, encoding = "UTF-8")
}
cat("Touched R sources parsed successfully\n")
started <- proc.time()[["elapsed"]]
results <- testthat::test_dir("tests/testthat", filter = filter, env = env,
                              reporter = "silent", stop_on_failure = FALSE,
                              stop_on_warning = FALSE, load_package = "none")
summary <- as.data.frame(results)
write.csv(summary[setdiff(names(summary), "result")], paste0(prefix, "-scenarios.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
saveRDS(results, paste0(prefix, "-scenarios.rds"))
for (i in seq_len(nrow(summary))) {
  status <- if (summary$failed[[i]] || summary$error[[i]] || summary$warning[[i]] || summary$skipped[[i]]) "FAIL" else "PASS"
  cat(status, "|", summary$test[[i]], "\n")
  if (status == "FAIL") print(results[[i]]$results)
}
if (identical(filter, "^(tab|fre)")) for (function_name in c("tab", "fre", "tab1", "fre1", "tab2", "fre2")) {
  tests <- summary$test[startsWith(summary$test, paste(function_name, "coverage"))]
  ids <- as.integer(sub(".* coverage ([0-9]{3}).*", "\\1", tests))
  stopifnot(length(ids) == 100L, identical(sort(ids), seq_len(100L)))
  cat("NUMBERED COVERAGE", function_name, length(ids), "scenarios\n")
}
cat("SCENARIOS", nrow(summary), "ELAPSED", proc.time()[["elapsed"]] - started, "seconds\n")
print(colSums(summary[c("passed", "failed", "error", "warning", "skipped")]))
if (any(summary$failed > 0L | summary$error | summary$warning > 0L | summary$skipped)) quit(status = 1L)
if (!identical(filter, "^(tab|fre)")) quit(status = 0L)
cat("\nBEGIN ACTUAL OUTPUT\n")
options(width = 120, tibble.width = 120)
show <- function(label, expression) {
  cat("\n", label, "\n", sep = "")
  cat(paste(deparse(substitute(expression)), collapse = "\n"), "\n")
  print(force(expression))
}
d <- tibble::tibble(g = c("A", "A", "A", NA), x = c(1, 2, NA, 2), y = c("a", "b", "a", "b"))
show("Joint counts", tab(d, x, y))
show("Joint frequency totals", fre(d, x, y))
show("One-way tables", tab1(d, x, y))
show("Grouped one-way frequencies", fre1(d, x, .by = g, .type = "tibble"))
show("Cross table", tab2(d, x, y))
show("Cross table with margins", fre2(d, x, y))
show("Explicit grouping overrides inherited group", tab(dplyr::group_by(d, y), x, .by = g))
show("Empty selection", fre(d, tidyselect::starts_with("absent")))
cat("END ACTUAL OUTPUT\n")
