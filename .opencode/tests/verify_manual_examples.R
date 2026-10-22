# Internal verification of the plain user-facing scripts; not needed to run them.
args <- commandArgs(trailingOnly = TRUE)
if (!length(args) || !dir.exists(args[[1L]])) {
  stop(
    "Supply a fresh installed package library and optional output directory."
  )
}
.libPaths(c(normalizePath(args[[1L]]), .libPaths()))
library(tidystata, lib.loc = args[[1L]])
output_dir <- if (nzchar(Sys.getenv("TIDYSTATA_EXAMPLE_OUTPUT"))) {
  Sys.getenv("TIDYSTATA_EXAMPLE_OUTPUT")
} else if (length(args) >= 2L) {
  args[[2L]]
} else {
  ".opencode/results/manual-examples"
}
example_dir <- system.file("examples", package = "tidystata", mustWork = TRUE)
parse(file.path(example_dir, "00_install.R"), encoding = "UTF-8")
scripts <- c(
  "01_inspect_and_select.R",
  "02_frequency_tables.R",
  "03_summary_statistics.R",
  "04_prepare_and_calculate.R",
  "05_robustness_and_consistency.R"
)
if (requireNamespace("data.table", quietly = TRUE)) {
  scripts <- c(scripts, "06_data_table_optional.R")
}
patterns <- c(
  "03_summary_statistics.R" = "non-numeric|factor",
  "04_prepare_and_calculate.R" = "parsing failure|collapsed quantile",
  "05_robustness_and_consistency.R" = "entirely missing|labelled"
)
console <- character()
results <- list()
for (script in scripts) {
  script_env <- new.env(parent = globalenv())
  warning_count <- 0L
  output <- capture.output(withCallingHandlers(
    source(file.path(example_dir, script), local = script_env, echo = TRUE),
    warning = function(w) {
      pattern <- patterns[script]
      if (is.na(pattern) || !grepl(pattern, conditionMessage(w))) {
        stop("Unexpected warning: ", conditionMessage(w))
      }
      warning_count <<- warning_count + 1L
      cat("WARNING: ", conditionMessage(w), "\n", sep = "")
      invokeRestart("muffleWarning")
    },
    message = function(m) {
      cat("MESSAGE: ", conditionMessage(m), "\n", sep = "")
      invokeRestart("muffleMessage")
    }
  ))
  if (script == "01_inspect_and_select.R") {
    stopifnot(codebook(script_env$survey)$n[4] == 5L)
  } else if (script == "02_frequency_tables.R") {
    stopifnot(identical(script_env$counts$n, c(3L, 3L, 2L)))
  } else if (script == "03_summary_statistics.R") {
    stopifnot(
      nrow(script_env$combined) == 2,
      is.character(script_env$combined$mean)
    )
  } else if (script == "04_prepare_and_calculate.R") {
    stopifnot(identical(row_mean(script_env$scores), c(11, 20, NA, 31, NA)))
  } else if (script == "05_robustness_and_consistency.R") {
    stopifnot(
      nrow(script_env$preview) == 20,
      identical(class(tab(script_env$frame, group)), "data.frame")
    )
  } else if (script == "06_data_table_optional.R") {
    stopifnot(
      identical(script_env$dt$x, c(1, 3, 5)),
      all(script_env$wrapped$x == 99)
    )
  }
  console <- c(console, paste("SCRIPT:", script), output, "")
  results[[script]] <- data.frame(
    script = script,
    status = "PASS",
    expected_warnings = warning_count
  )
}
results <- do.call(rbind, results)
rownames(results) <- NULL
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
writeLines(
  enc2utf8(console),
  file.path(output_dir, "console.log"),
  useBytes = TRUE
)
utils::write.csv(
  results,
  file.path(output_dir, "scripts.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
report <- c(
  "# Plain manual examples: verification",
  "",
  paste("Generated:", Sys.Date()),
  "",
  "The user-facing scripts contain only package loading, visible data and direct",
  "function calls. Each was sourced independently, with ordinary printed results.",
  "",
  "| Script | Status | Expected warnings |",
  "| --- | --- | ---: |",
  sprintf(
    "| %s | %s | %s |",
    results$script,
    results$status,
    results$expected_warnings
  ),
  "",
  "Warnings are checked by this internal verification script; no testing helpers",
  "or assertions are present in the user-facing examples. Invalid calls and GUI",
  "examples are commented out for the user to execute individually. Installation",
  "instructions were checked against R Packages; the installer script was parsed",
  "but not executed, since the verified local package is already installed.",
  "",
  "[Actual expressions and console output](console.log)",
  "",
  "User-facing guide: `inst/examples/README.md` in the repository.",
  "",
  "No package implementation changed. Previous package-check evidence remains",
  "separate from this example-only verification."
)
writeLines(
  enc2utf8(report),
  file.path(output_dir, "report.md"),
  useBytes = TRUE
)
print(results, row.names = FALSE)
