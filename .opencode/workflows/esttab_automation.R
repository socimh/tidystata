#!/usr/bin/env Rscript
#' Automated Testing Workflow for esttab Function
#' 
#' This script runs 25 comprehensive test scenarios, captures errors,
#' generates reports, and updates PROBLEMS.md automatically.
#'
#' Usage:
#'   source(".opencode/workflows/esttab_automation.R")
#' 
#' Or from command line:
#'   Rscript .opencode/workflows/esttab_automation.R

message("╔══════════════════════════════════════════════════════════════╗")
message("║  Automated esttab Testing Workflow                         ║")
message("║  25 Comprehensive Scenarios                                  ║")
message("╚══════════════════════════════════════════════════════════════╝")

# --- Load Required Libraries ---
required_packages <- c("jsonlite", "digest", "dplyr", "lme4", "broom", "broom.mixed")
missing_packages <- required_packages[!(required_packages %in% installed.packages()[, "Package"])]

if (length(missing_packages) > 0) {
  message("Installing missing packages: ", paste(missing_packages, collapse = ", "))
  install.packages(missing_packages, repos = "https://cloud.r-project.org/")
}

for (pkg in required_packages) {
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

# --- Load Workflow Libraries ---
workflow_dir <- ".opencode/workflows"
if (!dir.exists(workflow_dir)) {
  workflow_dir <- "D:/R/statart/.opencode/workflows"
}

source(file.path(workflow_dir, "lib/test_runner.R"))
source(file.path(workflow_dir, "lib/error_handler.R"))
source(file.path(workflow_dir, "lib/problem_updater.R"))

# --- Load Test Scenarios ---
test_script <- ".opencode/tests/test_esttab_automated.R"
if (!file.exists(test_script)) {
  test_script <- "D:/R/statart/.opencode/tests/test_esttab_automated.R"
}

source(test_script)

# --- Source Package Functions ---
tryCatch({
  source("R/s_try.R")
  source("R/esttab.R")
  message("✓ Loaded package functions from R/ directory")
}, error = function(e) {
  tryCatch({
    source("D:/R/statart/R/s_try.R")
    source("D:/R/statart/R/esttab.R")
    message("✓ Loaded package functions from D:/R/statart/R/")
  }, error = function(e2) {
    stop("Could not load package functions. Error: ", e2$message)
  })
})

# --- Load Scenarios ---
scenarios <- define_test_scenarios()
message(sprintf("✓ Loaded %d test scenarios\n", length(scenarios)))

# --- Run Test Suite ---
start_time <- Sys.time()
results <- run_test_suite(scenarios, verbose = TRUE)
end_time <- Sys.time()
total_time <- as.numeric(end_time - start_time, units = "secs")

# --- Generate Summary Statistics ---
passes <- sum(sapply(results, function(r) grepl("PASS", r$status)))
fails <- sum(sapply(results, function(r) r$status == "FAIL"))
warnings <- sum(sapply(results, function(r) r$status == "WARNING"))
failed_tests <- Filter(function(r) r$status == "FAIL", results)

# --- Log Errors ---
message("\n--- Processing Errors ---")
if (length(failed_tests) > 0) {
  error_log <- log_errors(results)
} else {
  message("✓ No errors to log")
}

# --- Update PROBLEMS.md ---
message("\n--- Updating PROBLEMS.md ---")
new_issues <- update_problems_md()

# --- Generate Report ---
message("\n--- Generating Report ---")

generate_report <- function(results, output_file = ".opencode/reports/report_esttab_latest.md") {
  
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  
  # Header
  report <- c(
    "# Automated Verification Report: esttab",
    "",
    sprintf("**Date**: %s", timestamp),
    sprintf("**Total Scenarios**: %d", length(results)),
    sprintf("**Execution Time**: %.2f seconds", total_time),
    "",
    "## Summary",
    "",
    sprintf("- **PASS**: %d", passes),
    sprintf("- **FAIL**: %d", fails),
    sprintf("- **WARNING**: %d", warnings),
    sprintf("- **Success Rate**: %.1f%%", 100 * passes / length(results)),
    "",
    "## Results by Category",
    ""
  )
  
  # Group by category
  categories <- unique(sapply(results, function(r) r$category))
  
  for (cat in categories) {
    cat_results <- Filter(function(r) r$category == cat, results)
    cat_pass <- sum(sapply(cat_results, function(r) grepl("PASS", r$status)))
    cat_fail <- sum(sapply(cat_results, function(r) r$status == "FAIL"))
    
    report <- c(report, 
      sprintf("### %s", tools::toTitleCase(cat)),
      "",
      sprintf("- Total: %d", length(cat_results)),
      sprintf("- Pass: %d", cat_pass),
      sprintf("- Fail: %d", cat_fail),
      "",
      "| ID | Description | Status | Time (s) |",
      "|---|---|---|---|"
    )
    
    for (r in cat_results) {
      status_icon <- switch(r$status,
        "PASS" = "✓ PASS",
        "FAIL" = "✗ FAIL",
        "WARNING" = "⚠ WARNING",
        r$status
      )
      report <- c(report, sprintf("| %s | %s | %s | %.3f |", 
        r$id, r$description, status_icon, r$execution_time))
    }
    report <- c(report, "")
  }
  
  # Failed Tests Details
  if (length(failed_tests) > 0) {
    report <- c(report,
      "## Failed Tests Details",
      ""
    )
    
    for (r in failed_tests) {
      cat_error <- categorize_error(r$error, r$id)
      
      report <- c(report,
        sprintf("### %s: %s", r$id, r$description),
        "",
        sprintf("**Category**: %s", cat_error$category),
        sprintf("**Severity**: %s", cat_error$severity),
        sprintf("**Error Signature**: `%s`", cat_error$signature),
        "",
        "**Error Message**:",
        "```",
        r$error$message,
        "```",
        "",
        "**Test Code**:",
        "```r",
        r$test_code,
        "```",
        "",
        "**Stack Trace**:",
        "```",
        paste(r$error$trace, collapse = "\n"),
        "```",
        ""
      )
    }
  }
  
  # Write report
  writeLines(report, output_file)
  message(sprintf("✓ Report written to: %s", output_file))
}

generate_report(results)

# --- Final Summary ---
message("\n╔══════════════════════════════════════════════════════════════╗")
message(sprintf("║  Test Suite Complete                                         ║"))
message(sprintf("║  Time: %.2f seconds                                          ║", total_time))
message(sprintf("║  Results: %d PASS, %d FAIL, %d WARNING                        ║", 
  passes, fails, warnings))
if (new_issues > 0) {
  message(sprintf("║  New Issues Added to PROBLEMS.md: %d                          ║", new_issues))
}
message("╚══════════════════════════════════════════════════════════════╝")

# Return results invisibly for programmatic use
invisible(list(
  results = results,
  summary = list(
    total = length(results),
    pass = passes,
    fail = fails,
    warning = warnings,
    new_issues = new_issues,
    execution_time = total_time
  )
))
