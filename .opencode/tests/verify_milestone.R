# Standalone verification/report entry point. Launch with run_r_safe.py.
prefix <- ".opencode/results/milestone-contracts"
started <- Sys.time()
status <- system2(
  "python",
  c(
    ".opencode/workflows/verify_package.py",
    "--filter",
    "milestone",
    "--prefix",
    prefix
  )
)
if (!file.exists(paste0(prefix, ".csv"))) {
  quit(status = max(1L, status))
}
results <- read.csv(
  paste0(prefix, ".csv"),
  check.names = FALSE,
  fileEncoding = "UTF-8",
  stringsAsFactors = FALSE
)
outcome <- ifelse(
  results$error | results$failed > 0L,
  "FAIL",
  ifelse(results$skipped, "SKIP", "PASS")
)
elapsed <- round(as.numeric(difftime(Sys.time(), started, units = "secs")), 2)
console <- sprintf("[%s] %s", outcome, results$test)
writeLines(
  enc2utf8(console),
  ".opencode/tests/verification_milestone.txt",
  useBytes = TRUE
)
report <- c(
  "# Verification: smaller statart core",
  "",
  paste0("**Version:** ", read.dcf("DESCRIPTION")[1, "Version"]),
  paste0("**Generated:** ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "**Source:** `.opencode/tests/verify_milestone.R` and the milestone test files.",
  "",
  "## Summary",
  "",
  "| Measure | Count |",
  "| --- | ---: |",
  paste0("| Scenarios | ", nrow(results), " |"),
  paste0("| Passing scenarios | ", sum(outcome == "PASS"), " |"),
  paste0("| Failing scenarios | ", sum(outcome == "FAIL"), " |"),
  paste0("| Skipped scenarios | ", sum(outcome == "SKIP"), " |"),
  paste0("| Passing expectations | ", sum(results$passed), " |"),
  paste0("| Failed expectations | ", sum(results$failed), " |"),
  paste0("| Error blocks | ", sum(results$error), " |"),
  paste0("| Warnings | ", sum(results$warning), " |"),
  paste0("| Elapsed seconds including fresh native build | ", elapsed, " |"),
  "",
  "## Contracts exercised",
  "",
  "Character parsing and length; column labels and label search; grouped tabulations",
  "and totals; data output defaults and explicit optional formatting; quantile",
  "ties and validation; all ten row helpers with direct, selected, nested, empty,",
  "missing, non-finite, and unsupported inputs. Cases include independent base-R",
  "references and input-preservation checks, with at least 20 scenarios for each",
  "changed public function. Review regressions cover reserved grouping keys and",
  "general dataframe expressions evaluated once inside mutate().",
  "",
  "Historical behavior changes: four wrappers retired; formatting defaults",
  "changed; tied quantile values stay together; row outputs are atomic vectors.",
  "See [migration guide](../../MIGRATION.md). This focused report does not claim",
  "that the entire retained package test suite passes.",
  "",
  "## Scenario results",
  "",
  "| Scenario | Result |",
  "| --- | --- |",
  sprintf("| %s | %s |", gsub("|", " / ", results$test, fixed = TRUE), outcome),
  "",
  "## Actual output examples",
  "",
  "Versioned demo reports in this directory record real console output for",
  "tabulation, summaries, codebooks, row calculations, binning, selection, and",
  "utilities. Historical reports are preserved; use INDEX.md for current links."
)
writeLines(
  enc2utf8(report),
  ".opencode/reports/milestone_contracts_0.2.0.9000.md",
  useBytes = TRUE
)
cat(
  sum(outcome == "PASS"),
  "PASS;",
  sum(outcome == "FAIL"),
  "FAIL;",
  sum(outcome == "SKIP"),
  "SKIP across",
  nrow(results),
  "scenarios.\n"
)
if (status != 0L || any(outcome == "FAIL")) {
  quit(status = max(1L, status))
}
