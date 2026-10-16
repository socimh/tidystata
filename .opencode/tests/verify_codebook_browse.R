# Run through run_r_safe.py; pass a fresh installed library and result prefix.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) >= 1L, dir.exists(args[[1]]))
.libPaths(c(normalizePath(args[[1]]), .libPaths()))
library(statart)
prefix <- if (length(args) >= 2L) {
  args[[2]]
} else {
  ".opencode/results/codebook-browse-accepted"
}
filter <- if (length(args) >= 3L) {
  args[[3]]
} else {
  "^codebook|^browse|^complex_tb$|^s_select$"
}
for (file in c(
  "R/codebook.R",
  "R/browse.R",
  "R/s_select.R",
  list.files(
    "tests/testthat",
    pattern = "^test-(codebook|browse).*?[.]R$",
    full.names = TRUE
  )
)) {
  parse(file = file, encoding = "UTF-8")
}
cat("Touched R sources parsed successfully\n")
started <- proc.time()[["elapsed"]]
results <- testthat::test_dir(
  "tests/testthat",
  filter = filter,
  env = new.env(parent = asNamespace("statart")),
  reporter = "silent",
  stop_on_failure = FALSE,
  stop_on_warning = FALSE,
  load_package = "none"
)
summary <- as.data.frame(results)
write.csv(
  summary[setdiff(names(summary), "result")],
  paste0(prefix, "-scenarios.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
saveRDS(results, paste0(prefix, "-scenarios.rds"))
for (i in seq_len(nrow(summary))) {
  status <- if (
    summary$failed[[i]] ||
      summary$error[[i]] ||
      summary$warning[[i]] ||
      summary$skipped[[i]]
  ) {
    "FAIL"
  } else {
    "PASS"
  }
  cat(status, "|", summary$test[[i]], "\n")
  if (status == "FAIL") print(results[[i]]$results)
}
if (length(args) < 3L) {
  for (function_name in c("codebook", "browse")) {
    tests <- summary$test[startsWith(
      summary$test,
      paste(function_name, "coverage")
    )]
    ids <- as.integer(sub(".* coverage ([0-9]{3}).*", "\\1", tests))
    stopifnot(length(ids) == 100L, identical(sort(ids), seq_len(100L)))
    cat("NUMBERED COVERAGE", function_name, length(ids), "scenarios\n")
  }
}
cat(
  "SCENARIOS",
  nrow(summary),
  "ELAPSED",
  proc.time()[["elapsed"]] - started,
  "seconds\n"
)
print(colSums(summary[c("passed", "failed", "error", "warning", "skipped")]))
if (
  any(
    summary$failed > 0L | summary$error | summary$warning > 0L | summary$skipped
  )
) {
  quit(status = 1L)
}
if (length(args) >= 3L) {
  quit(status = 0L)
}
cat("\nBEGIN ACTUAL OUTPUT\n")
options(
  width = 88,
  tibble.width = 88,
  cli.unicode = FALSE,
  crayon.enabled = FALSE
)
show <- function(label, expression) {
  cat("\n", label, "\n", sep = "")
  cat(paste(deparse(substitute(expression)), collapse = "\n"), "\n")
  print(force(expression))
}
d <- tibble::tibble(
  id = 1:4,
  region = c("North", "North", "South", "South"),
  age = c(24, 31, NA, 45),
  income = c(32, 48, 55, NA)
)
attr(d$income, "label") <- "Annual income in thousands"
show("Inventory and labels", codebook(d))
show("Selected and renamed variables", codebook(d, earnings = income, age))
show("Computed variables", codebook(d, high_income = income >= 50))
show(
  "Grouped input remains one global inventory",
  codebook(dplyr::group_by(d, region))
)
spss <- tibble::tibble(
  x = haven::labelled_spss(c(1, 1, 99, NA), na_values = 99)
)
show("SPSS user-missing values excluded", codebook(spss))
structured <- tibble::tibble(
  pair = matrix(c(1, 1, 2, 2, NA, 2, 2, 2), ncol = 2, byrow = TRUE)
)
show("Structured columns count complete rows", codebook(structured))
show(
  "Headless browse: explicitly print the returned data",
  browse(d, id, income)
)
# print() is explicit because browse itself returns invisibly; the viewer is
# unavailable in this noninteractive verification process.
show("Browse visibility", withVisible(browse(d, age))$visible)
show(
  "Browse in a downstream pipeline",
  dplyr::mutate(browse(d, id, income), scaled = income / 10)
)
cat("END ACTUAL OUTPUT\n")
