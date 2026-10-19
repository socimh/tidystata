# Collect every result, then fail for errors, failures or unexpected warnings.
args <- commandArgs(trailingOnly = TRUE)
package_path <- if (length(args) >= 1L) args[[1]] else "."
prefix <- if (length(args) >= 2L) args[[2]] else ".opencode/results/current"
filter <- if (length(args) >= 3L && nzchar(args[[3]])) args[[3]] else NULL
shuffle <- length(args) >= 4L && nzchar(args[[4]])
seed <- if (shuffle) as.integer(args[[4]]) else NULL
if (shuffle && (is.na(seed) || as.character(seed) != args[[4]])) {
  stop("The optional shuffle seed must be a single integer.")
}
dir.create(dirname(prefix), recursive = TRUE, showWarnings = FALSE)
package_path <- normalizePath(package_path, winslash = "/")
pkgload::load_all(package_path, compile = FALSE, quiet = TRUE)
test_path <- file.path(package_path, "tests", "testthat")
file_map <- character()
test_group_order <- list()
if (shuffle) {
  set.seed(seed)
  # Raw testthat shuffling also moves fixture declarations after their uses.
  # Reorder independent execution groups, keeping setup in its original order.
  contains_test <- function(expression) {
    if (missing(expression) || !is.call(expression)) {
      return(FALSE)
    }
    if (identical(expression[[1]], as.name("function"))) {
      return(FALSE)
    }
    if (
      identical(expression[[1]], as.name("test_that")) ||
        identical(expression[[1]], quote(testthat::test_that))
    ) {
      return(TRUE)
    }
    any(vapply(as.list(expression)[-1], contains_test, logical(1)))
  }
  staged_path <- tempfile("statart-shuffled-tests-")
  dir.create(staged_path)
  stopifnot(file.copy(
    file.path(package_path, "tests"),
    staged_path,
    recursive = TRUE
  ))
  stopifnot(file.copy(file.path(package_path, "DESCRIPTION"), staged_path))
  test_path <- file.path(staged_path, "tests", "testthat")
  files <- list.files(test_path, "^test-.*[.][rR]$")
  selected <- if (is.null(filter)) {
    rep(TRUE, length(files))
  } else {
    grepl(filter, sub("[.][rR]$", "", sub("^test-", "", files)))
  }
  selected_files <- files[selected]
  permutation <- sample.int(length(selected_files))
  ordered_files <- selected_files[permutation]
  for (file in ordered_files) {
    path <- file.path(test_path, file)
    expressions <- as.list(parse(path, keep.source = FALSE, encoding = "UTF-8"))
    groups <- which(vapply(expressions, contains_test, logical(1)))
    setup <- setdiff(seq_along(expressions), groups)
    permuted <- groups[sample.int(length(groups))]
    # Deparsing under the C locale can replace Unicode literals with <U+...>.
    # Serialize expressions so their original strings and encodings survive.
    serialized <- file.path(test_path, paste0(".", file, ".expressions.rds"))
    saveRDS(as.expression(expressions[c(setup, permuted)]), serialized)
    escaped_path <- paste0(
      sprintf("\\U%08x", utf8ToInt(enc2utf8(serialized))),
      collapse = ""
    )
    writeLines(
      c(
        "local({",
        paste0('  .statart_order_expressions <- readRDS("', escaped_path, '")'),
        "  for (.statart_order_expression in .statart_order_expressions) {",
        "    eval(.statart_order_expression, envir = environment())",
        "  }",
        "})"
      ),
      path,
      useBytes = TRUE
    )
    test_group_order[[file]] <- list(
      expression_count = length(expressions),
      setup_indices = as.list(setup),
      original_group_indices = as.list(groups),
      permuted_group_indices = as.list(permuted),
      group_count = length(groups)
    )
  }
  renamed <- sprintf(
    "test-%05d-%s",
    seq_along(ordered_files),
    sub("^test-", "", ordered_files)
  )
  file_map <- stats::setNames(ordered_files, renamed)
  stopifnot(all(file.rename(
    file.path(test_path, ordered_files),
    file.path(test_path, renamed)
  )))
  unselected <- files[!selected]
  if (length(unselected)) {
    stopifnot(all(file.rename(
      file.path(test_path, unselected),
      file.path(test_path, paste0("fixture-unselected-", unselected))
    )))
  }
  filter <- NULL
}
results <- testthat::test_dir(
  test_path,
  filter = filter,
  reporter = "silent",
  stop_on_failure = FALSE,
  stop_on_warning = FALSE,
  load_package = "none",
  shuffle = FALSE
)
if (shuffle) {
  for (i in seq_along(results)) {
    results[[i]]$file <- unname(file_map[results[[i]]$file])
  }
}
summary <- as.data.frame(results)
if (shuffle) {
  for (file in names(test_group_order)) {
    test_group_order[[file]]$observed_test_blocks <- sum(summary$file == file)
  }
}
summary$execution_index <- seq_len(nrow(summary))
write.csv(
  summary[c("execution_index", "file", "test")],
  paste0(prefix, "-order.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
source_files <- c(
  "DESCRIPTION",
  "NAMESPACE",
  unlist(lapply(
    c("R", "src", "tests"),
    function(folder) {
      file.path(
        folder,
        list.files(
          file.path(package_path, folder),
          pattern = "[.](R|r|cpp|h|hpp)$",
          recursive = TRUE
        )
      )
    }
  ))
)
source_files <- sort(source_files[file.exists(file.path(
  package_path,
  source_files
))])
source_hashes <- stats::setNames(
  unname(tools::md5sum(file.path(package_path, source_files))),
  source_files
)
jsonlite::write_json(
  list(
    shuffle = shuffle,
    seed = seed,
    shuffle_scope = if (shuffle) c("files", "test_groups") else character(),
    test_group_order = test_group_order,
    file_order = unique(summary$file),
    r_version = R.version.string,
    platform = R.version$platform,
    tool_versions = lapply(
      c("testthat", "pkgload", "jsonlite"),
      function(package) {
        as.character(utils::packageVersion(package))
      }
    ) |>
      stats::setNames(c("testthat", "pkgload", "jsonlite")),
    library_paths = .libPaths(),
    source = package_path,
    source_fingerprints = as.list(source_hashes)
  ),
  paste0(prefix, "-metadata.json"),
  auto_unbox = TRUE,
  null = "null",
  pretty = TRUE
)
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
if (any(totals[c("failed", "error", "warning")] > 0L)) {
  quit(status = 1L)
}
