# Native R CMD check can exit zero even when its report contains warnings.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 3L)
check_log <- args[[1]]
native_exit <- suppressWarnings(as.numeric(args[[2]]))
output <- args[[3]]
diagnostics <- character()
errors <- warnings <- notes <- character()
complete <- FALSE
if (!file.exists(check_log)) {
  diagnostics <- c(diagnostics, "Check log does not exist.")
} else {
  lines <- readLines(check_log, warn = FALSE, encoding = "UTF-8")
  done <- which(grepl("^\\* DONE[[:space:]]*$", lines))
  status <- which(grepl("^Status: ", lines))
  complete <- length(done) > 0L &&
    length(status) > 0L &&
    tail(status, 1) > tail(done, 1)
  if (!complete) {
    diagnostics <- c(
      diagnostics,
      "Check log is incomplete: missing DONE or final Status."
    )
  }
  parsed <- tryCatch(
    rcmdcheck::parse_check(file = check_log),
    error = function(e) {
      diagnostics <<- c(
        diagnostics,
        paste("Cannot parse check log:", conditionMessage(e))
      )
      NULL
    }
  )
  if (!is.null(parsed)) {
    errors <- parsed$errors
    warnings <- parsed$warnings
    notes <- parsed$notes
  }
  if (complete) {
    final_status <- lines[[tail(status, 1)]]
    expected_counts <- vapply(
      c("ERROR", "WARNING", "NOTE"),
      function(kind) {
        match <- regexec(paste0("([0-9]+) ", kind), final_status)
        value <- regmatches(final_status, match)[[1]]
        if (length(value)) as.integer(value[[2]]) else 0L
      },
      integer(1)
    )
    if (
      !identical(
        unname(expected_counts),
        c(length(errors), length(warnings), length(notes))
      ) ||
        (!identical(final_status, "Status: OK") && !any(expected_counts > 0L))
    ) {
      diagnostics <- c(
        diagnostics,
        "Parsed conditions disagree with the final Status."
      )
    }
  }
}
if (is.na(native_exit) || native_exit != 0L) {
  diagnostics <- c(
    diagnostics,
    "Native check process did not exit successfully."
  )
}
passed <- complete &&
  length(diagnostics) == 0L &&
  length(errors) == 0L &&
  length(warnings) == 0L
result <- list(
  check_log = normalizePath(check_log, winslash = "/", mustWork = FALSE),
  native_exit = native_exit,
  complete = complete,
  verification_passed = passed,
  # Dataset rights and platform validation are separate publication gates.
  check_conditions_clear = passed && length(notes) == 0L,
  counts = list(
    errors = length(errors),
    warnings = length(warnings),
    notes = length(notes)
  ),
  errors = as.list(errors),
  warnings = as.list(warnings),
  notes = as.list(notes),
  diagnostics = as.list(diagnostics)
)
dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
jsonlite::write_json(
  result,
  output,
  auto_unbox = TRUE,
  pretty = TRUE,
  na = "null"
)
cat(
  "Check conditions:",
  length(errors),
  "errors,",
  length(warnings),
  "warnings,",
  length(notes),
  "notes. Verification passed:",
  passed,
  "\n"
)
quit(status = if (passed) 0L else 1L)
