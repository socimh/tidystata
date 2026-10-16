# Run through run_r_safe.py; pass a fresh installed library and result prefix.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) >= 1L, dir.exists(args[[1]]))
.libPaths(c(normalizePath(args[[1]]), .libPaths()))
library(statart)
prefix <- if (length(args) >= 2L) args[[2]] else ".opencode/results/inspection-accepted"
filter <- if (length(args) >= 3L) args[[3]] else "^(inspection|names)$|^inspection-"
for (file in c("R/names.R", "R/variables.R", "R/s_match.R",
               list.files("tests/testthat", pattern = "^test-inspection.*[.]R$", full.names = TRUE))) {
  parse(file = file, encoding = "UTF-8")
}
cat("Touched R sources parsed successfully\n")
started <- proc.time()[["elapsed"]]
results <- testthat::test_dir("tests/testthat", filter = filter,
                              env = new.env(parent = asNamespace("statart")),
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
if (length(args) < 3L) for (function_name in c("ds", "ds_as_column", "names_as_column", "variables", "variables_search")) {
  tests <- summary$test[startsWith(summary$test, paste(function_name, "coverage"))]
  ids <- as.integer(sub(".* coverage ([0-9]{3}).*", "\\1", tests))
  stopifnot(length(ids) == 100L, identical(sort(ids), seq_len(100L)))
  cat("NUMBERED COVERAGE", function_name, length(ids), "scenarios\n")
}
cat("SCENARIOS", nrow(summary), "ELAPSED", proc.time()[["elapsed"]] - started, "seconds\n")
print(colSums(summary[c("passed", "failed", "error", "warning", "skipped")]))
if (any(summary$failed > 0L | summary$error | summary$warning > 0L | summary$skipped)) quit(status = 1L)
if (length(args) >= 3L) quit(status = 0L)
cat("\nBEGIN ACTUAL OUTPUT\n")
options(width = 88, tibble.width = 88, cli.unicode = FALSE, crayon.enabled = FALSE)
show <- function(label, expression) {
  cat("\n", label, "\n", sep = "")
  cat(paste(deparse(substitute(expression)), collapse = "\n"), "\n")
  print(force(expression))
}
d <- tibble::tibble(id = 1:3, income = c(32, 48, NA), income_net = c(28, 42, NA),
                    age = c(24, 31, 45), region = c("North", "South", "North"))
attr(d$income, "label") <- "Annual household income"
attr(d$age, "label") <- "Respondent age in years"
show("Select variable names", ds(d, tidyselect::starts_with("income")))
show("Names as a table", names_as_column(d, age, income))
show("Alias with column selection", ds_as_column(d, region, id))
show("Variable list and labels", variables(d))
show("Search labels, ignoring case", variables_search(d, "HOUSEHOLD"))
show("Substring default", variables_search(d, "income"))
show("Explicit complete-name match", variables_search(d, "^income$"))
show("Renamed variable retains its label", variables(d, earnings = income))
show("Feed a discovered varlist into a later summary", summ(d, tidyselect::all_of(ds(d, income, income_net))))
cat("END ACTUAL OUTPUT\n")
