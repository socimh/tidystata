# Execute the exact distributed snippets with controlled developer fixtures.
# Run through run_r_safe.py on Windows. No packages are installed by this script.
args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[[1L]] else "."
output <- if (length(args) >= 2L) args[[2L]] else tempfile(fileext = ".csv")
if (length(args) >= 3L) {
  .libPaths(c(args[[3L]], .libPaths()))
  namespace <- loadNamespace("tidystata", lib.loc = args[[3L]])
  expected <- normalizePath(file.path(args[[3L]], "tidystata"), winslash = "/")
  actual <- normalizePath(getNamespaceInfo(namespace, "path"), winslash = "/")
  stopifnot(identical(actual, expected))
}
fixtures <- as.data.frame(readr::read_csv(
  file.path(root, "tests/testthat/fixtures/findit/reference.csv"),
  col_types = readr::cols(.default = readr::col_character()),
  na = character(),
  locale = readr::locale(encoding = "UTF-8"),
  progress = FALSE
))
if (!nrow(fixtures)) {
  stop("There are no reference fixtures.")
}
run <- function(row) {
  scope <- new.env(parent = globalenv())
  directory <- tempfile("findit-reference-")
  dir.create(directory)
  previous <- setwd(directory)
  on.exit(setwd(previous), add = TRUE)
  grDevices::pdf(file.path(directory, "plots.pdf"))
  on.exit(grDevices::dev.off(), add = TRUE)
  eval(parse(text = row$setup, encoding = "UTF-8"), scope)
  scope$.result <- eval(parse(text = row$code, encoding = "UTF-8"), scope)
  eval(parse(text = row$check, encoding = "UTF-8"), scope)
  invisible(NULL)
}
results <- lapply(seq_len(nrow(fixtures)), function(i) {
  row <- fixtures[i, ]
  warning_text <- character()
  error <- tryCatch(
    {
      withCallingHandlers(run(row), warning = function(warning) {
        warning_text <<- c(warning_text, conditionMessage(warning))
        invokeRestart("muffleWarning")
      })
      ""
    },
    error = conditionMessage
  )
  expected <- if (nzchar(row$expected_warning)) {
    grepl(row$expected_warning, warning_text, perl = TRUE)
  } else {
    rep(FALSE, length(warning_text))
  }
  data.frame(
    id = row$id,
    error = error,
    warnings = paste(warning_text[!expected], collapse = " | "),
    expected_warnings = paste(warning_text[expected], collapse = " | "),
    stringsAsFactors = FALSE
  )
})
results <- do.call(rbind, results)
write.csv(results, output, row.names = FALSE, fileEncoding = "UTF-8")
failed <- nzchar(results$error) | nzchar(results$warnings)
cat(
  nrow(results),
  "examples;",
  sum(failed),
  "errors or unexpected warning rows.\n"
)
cat(
  sum(nzchar(results$expected_warnings)),
  "documented startup-warning rows.\n"
)
if (any(failed)) {
  print(results[failed, ], row.names = FALSE)
  quit(status = 1L)
}
