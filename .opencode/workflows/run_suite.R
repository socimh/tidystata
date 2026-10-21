# Collect every result, then fail for errors, failures or unexpected warnings.
args <- commandArgs(trailingOnly = TRUE)
package_path <- if (length(args) >= 1L) args[[1]] else "."
prefix <- if (length(args) >= 2L) args[[2]] else ".opencode/results/current"
filter <- if (length(args) >= 3L && nzchar(args[[3]])) args[[3]] else NULL
mode <- if (length(args) >= 5L) args[[5L]] else "all"
if (!mode %in% c("all", "snapshots")) {
  stop("Unknown suite mode.")
}
shuffle <- length(args) >= 4L && nzchar(args[[4]])
seed <- if (shuffle) as.integer(args[[4]]) else NULL
if (shuffle && (is.na(seed) || as.character(seed) != args[[4]])) {
  stop("The optional shuffle seed must be a single integer.")
}
dir.create(dirname(prefix), recursive = TRUE, showWarnings = FALSE)
package_path <- normalizePath(package_path, winslash = "/")
candidate_library <- Sys.getenv("STATART_TEST_LIBRARY")
installed <- nzchar(candidate_library)
if (installed) {
  package <- read.dcf(file.path(package_path, "DESCRIPTION"))[1L, "Package"]
  expected <- normalizePath(
    file.path(candidate_library, package),
    winslash = "/"
  )
  namespace <- loadNamespace(package, lib.loc = candidate_library)
  actual <- normalizePath(getNamespaceInfo(namespace, "path"), winslash = "/")
  if (!identical(expected, actual)) {
    stop("Loaded namespace is not the candidate.")
  }
} else {
  pkgload::load_all(package_path, compile = FALSE, quiet = TRUE)
}
test_path <- file.path(package_path, "tests", "testthat")
file_map <- character()
test_group_order <- list()
selection <- list()
if (shuffle || mode == "snapshots") {
  if (mode == "snapshots") {
    runner <- sub(
      "^--file=",
      "",
      grep("^--file=", commandArgs(), value = TRUE)[[1L]]
    )
    source(file.path(dirname(runner), "select_snapshot_tests.R"), local = TRUE)
    auxiliary_files <- list.files(test_path, "[.][rR]$", full.names = TRUE)
    auxiliary_files <- auxiliary_files[
      !grepl("^test-", basename(auxiliary_files))
    ]
    for (file in auxiliary_files) {
      select_snapshot_tests(
        as.list(parse(file, keep.source = FALSE, encoding = "UTF-8")),
        auxiliary = TRUE
      )
    }
  }
  if (shuffle) {
    set.seed(seed)
  }
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
  permutation <- if (shuffle) {
    sample.int(length(selected_files))
  } else {
    seq_along(selected_files)
  }
  ordered_files <- selected_files[permutation]
  for (file in ordered_files) {
    path <- file.path(test_path, file)
    expressions <- as.list(parse(path, keep.source = FALSE, encoding = "UTF-8"))
    if (mode == "snapshots") {
      selected_expressions <- select_snapshot_tests(expressions)
      selection[[file]] <- selected_expressions$count
      expressions <- selected_expressions$expressions
    }
    groups <- which(vapply(expressions, contains_test, logical(1)))
    setup <- setdiff(seq_along(expressions), groups)
    permuted <- if (shuffle) groups[sample.int(length(groups))] else groups
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
  renamed <- if (!shuffle) {
    ordered_files
  } else {
    sprintf(
      "test-%05d-%s",
      seq_along(ordered_files),
      sub("^test-", "", ordered_files)
    )
  }
  file_map <- stats::setNames(ordered_files, renamed)
  if (shuffle) {
    stopifnot(all(file.rename(
      file.path(test_path, ordered_files),
      file.path(test_path, renamed)
    )))
  }
  # Snapshots are keyed by file name; give each staged file its snapshots.
  snapshot_name <- function(file) {
    file.path(
      test_path,
      "_snaps",
      sub("[.][rR]$", ".md", sub("^test-", "", file))
    )
  }
  has_snapshot <- file.exists(snapshot_name(ordered_files))
  if (shuffle) {
    stopifnot(all(file.copy(
      snapshot_name(ordered_files)[has_snapshot],
      snapshot_name(renamed)[has_snapshot]
    )))
  }
  unselected <- files[!selected]
  if (length(unselected)) {
    stopifnot(all(file.rename(
      file.path(test_path, unselected),
      file.path(test_path, paste0("fixture-unselected-", unselected))
    )))
  }
  filter <- NULL
}
if (mode == "snapshots" && sum(unlist(selection)) == 0L) {
  stop("No snapshot-bearing test blocks were selected.")
}
results <- testthat::test_dir(
  test_path,
  filter = filter,
  reporter = "silent",
  stop_on_failure = FALSE,
  stop_on_warning = FALSE,
  load_package = if (installed) "installed" else "none",
  package = if (installed) package else NULL,
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
legacy_source_hashes <- stats::setNames(
  unname(tools::md5sum(file.path(package_path, source_files))),
  source_files
)
identity_path <- Sys.getenv("STATART_SOURCE_IDENTITY")
source_identity <- if (nzchar(identity_path)) {
  jsonlite::read_json(identity_path)
} else {
  list(source_fingerprints = as.list(legacy_source_hashes))
}
jsonlite::write_json(
  list(
    mode = mode,
    snapshot_selection = selection,
    run_id = Sys.getenv("STATART_RUN_ID"),
    source_sha256 = Sys.getenv("STATART_SOURCE_SHA256"),
    candidate_library = candidate_library,
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
    source_fingerprints = source_identity$source_fingerprints
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
if (
  mode == "snapshots" &&
    any(vapply(
      names(selection),
      function(file) {
        sum(summary$file == file) != selection[[file]]
      },
      logical(1)
    ))
) {
  stop(
    "Snapshot selection was incomplete: observed blocks differ from selection."
  )
}
totals <- colSums(summary[c("passed", "failed", "error", "warning", "skipped")])
print(totals)
cat("Test blocks:", nrow(summary), "\n")
cat("Results:", prefix, "\n")
if (
  any(totals[c("failed", "error", "warning")] > 0L) ||
    (mode == "snapshots" && totals[["skipped"]] > 0L)
) {
  quit(status = 1L)
}
