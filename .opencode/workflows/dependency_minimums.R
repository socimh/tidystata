# CI-only isolated floor installation/checking. Every R process starts afresh.
floor_dependencies <- function(description) {
  text <- paste(
    unlist(description[c("Depends", "Imports", "LinkingTo")]),
    collapse = ","
  )
  entries <- strsplit(text, ",", fixed = TRUE)[[1]]
  lapply(entries[nzchar(trimws(entries))], function(entry) {
    entry <- trimws(gsub("[\r\n]+", " ", entry))
    parts <- regmatches(
      entry,
      regexec(
        "^\\s*([[:alnum:].]+)\\s*(?:\\((>=|<=|==|>|<)\\s*([^)]+)\\))?\\s*$",
        entry,
        perl = TRUE
      )
    )[[1]]
    if (!length(parts)) {
      stop("Unrecognised dependency: ", entry)
    }
    list(package = parts[[2]], operator = parts[[3]], version = parts[[4]])
  })
}

floor_satisfies <- function(actual, operator, expected) {
  comparison <- utils::compareVersion(actual, expected)
  switch(
    operator,
    ">=" = comparison >= 0,
    "<=" = comparison <= 0,
    "==" = comparison == 0,
    ">" = comparison > 0,
    "<" = comparison < 0,
    stop("Unknown dependency operator: ", operator)
  )
}

floor_audit <- function(case, include_tidystata = TRUE) {
  pending <- unique(c(
    names(case$pins),
    "rcmdcheck",
    "knitr",
    "rmarkdown",
    "withr",
    "bit64",
    "data.table",
    if (include_tidystata) "tidystata"
  ))
  records <- list()
  while (length(pending)) {
    package <- pending[[1]]
    pending <- pending[-1]
    if (package %in% names(records)) {
      next
    }
    path <- find.package(package)
    description <- as.list(read.dcf(file.path(path, "DESCRIPTION"))[1, ])
    actual <- description$Version
    if (package %in% names(case$pins)) {
      stopifnot(floor_satisfies(actual, "==", case$pins[[package]]))
    }
    loaded <- if (package %in% loadedNamespaces()) {
      as.character(getNamespaceVersion(package))
    } else {
      NULL
    }
    if (!is.null(loaded) && !floor_satisfies(loaded, "==", actual)) {
      stop("Loaded/installed version mismatch for ", package)
    }
    records[[package]] <- list(version = actual, path = path, loaded = loaded)
    for (dependency in floor_dependencies(description)) {
      name <- dependency$package
      installed <- if (name == "R") {
        as.character(getRversion())
      } else {
        as.character(utils::packageVersion(name))
      }
      if (
        nzchar(dependency$operator) &&
          !floor_satisfies(
            installed,
            dependency$operator,
            dependency$version
          )
      ) {
        stop(
          package,
          " requires ",
          name,
          " ",
          dependency$operator,
          dependency$version,
          "; selected ",
          installed
        )
      }
      if (name != "R") pending <- unique(c(pending, name))
    }
  }
  records
}

dependency_floor_receipt <- function(
  case_file,
  results = NULL,
  phase = "before"
) {
  case <- jsonlite::read_json(case_file, simplifyVector = FALSE)
  records <- floor_audit(case)
  totals <- skips <- NULL
  skip_reasons <- list()
  if (!is.null(results)) {
    table <- as.data.frame(results)
    totals <- colSums(table[c(
      "passed",
      "failed",
      "error",
      "warning",
      "skipped"
    )])
    skips <- table[table$skipped > 0, c("file", "test", "skipped")]
    for (block in results) {
      for (expectation in block$results) {
        if (inherits(expectation, "expectation_skip")) {
          skip_reasons[[length(skip_reasons) + 1L]] <- list(
            file = block$file,
            test = block$test,
            reason = conditionMessage(expectation)
          )
        }
      }
    }
  }
  destination <- Sys.getenv("TIDYSTATA_FLOOR_RESULTS")
  dir.create(destination, recursive = TRUE, showWarnings = FALSE)
  receipt <- list(
    candidate = case,
    run_id = Sys.getenv("TIDYSTATA_FLOOR_RUN_ID"),
    phase = phase,
    R = R.version.string,
    libraries = .libPaths(),
    packages = records,
    totals = if (is.null(totals)) NULL else as.list(totals),
    skips = skips,
    skip_reasons = skip_reasons
  )
  jsonlite::write_json(
    receipt,
    file.path(destination, paste0(phase, ".json")),
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null"
  )
  cat(
    "\nDependency floor checking-session receipt:",
    case$package,
    "declared",
    case$declared,
    "actual",
    records[[case$package]]$version,
    "\n"
  )
  if (!is.null(totals)) {
    print(totals)
    print(skips)
    stopifnot(!any(totals[c("failed", "error", "warning")] > 0))
  }
  invisible(receipt)
}

floor_run_directory <- function(base) {
  dir.create(base, recursive = TRUE, showWarnings = FALSE)
  run <- tempfile("run-", tmpdir = base)
  if (!dir.create(run)) {
    stop("Cannot reserve a fresh floor result directory")
  }
  normalizePath(run, winslash = "/", mustWork = TRUE)
}

floor_check_complete <- function(result, log_path, destination, run_id) {
  if (
    length(result$status) != 1L ||
      !is.numeric(result$status) ||
      is.na(result$status) ||
      result$status != 0 ||
      !identical(result$timeout, FALSE)
  ) {
    stop("Dependency-floor check did not exit normally with status zero")
  }
  if (length(result$errors) || length(result$warnings)) {
    stop("Dependency-floor check reported errors or warnings")
  }
  if (!file.exists(log_path)) {
    stop("Dependency-floor check log is missing")
  }
  log <- readLines(log_path, encoding = "UTF-8", warn = FALSE)
  done <- grep("^\\* DONE\\s*$", log)
  status <- grep("^Status: (OK|[0-9]+ NOTEs?)\\s*$", log)
  summaries <- grep("^Status:", log)
  tests <- grep("^\\* checking tests \\.\\.\\.", log)
  if (
    length(done) != 1L ||
      length(status) != 1L ||
      !identical(status, summaries) ||
      status <= done ||
      length(tests) != 1L ||
      tests >= done
  ) {
    stop("Dependency-floor check log is incomplete or unsuccessful")
  }
  next_section <- grep("^\\* ", log)
  next_section <- next_section[next_section > tests][[1]]
  test_log <- log[seq.int(tests, next_section - 1L)]
  if (
    !any(grepl("Running.*testthat[.]R", test_log)) ||
      !any(grepl("(^| )OK\\s*$", test_log))
  ) {
    stop("Dependency-floor check did not complete testthat.R successfully")
  }
  receipts <- lapply(c("before", "after"), function(phase) {
    path <- file.path(destination, paste0(phase, ".json"))
    if (!file.exists(path)) {
      stop("Current-run floor receipt is missing: ", phase)
    }
    receipt <- jsonlite::read_json(path, simplifyVector = TRUE)
    if (
      !identical(receipt$run_id, run_id) || !identical(receipt$phase, phase)
    ) {
      stop("Floor receipt belongs to another run or phase")
    }
    receipt
  })
  totals <- receipts[[2]]$totals
  if (
    !all(c("passed", "failed", "error", "warning") %in% names(totals)) ||
      !is.numeric(totals$passed) ||
      length(totals$passed) != 1L ||
      !is.finite(totals$passed) ||
      totals$passed < 1 ||
      any(vapply(
        totals[c("failed", "error", "warning")],
        function(x) {
          !is.numeric(x) || length(x) != 1L || !is.finite(x) || x != 0
        },
        logical(1)
      ))
  ) {
    stop("Floor receipt does not establish passing, warning-free tests")
  }
  invisible(TRUE)
}

dependency_floor_main <- function(args) {
  stopifnot(length(args) == 2, args[[1]] %in% c("install", "check"))
  case_file <- normalizePath(args[[2]], winslash = "/", mustWork = TRUE)
  case <- jsonlite::read_json(case_file, simplifyVector = FALSE)
  library <- normalizePath(
    Sys.getenv("TIDYSTATA_FLOOR_LIBRARY"),
    winslash = "/"
  )
  .libPaths(c(library, .libPaths()))
  if (args[[1]] == "install") {
    for (package in unlist(case$install_order)) {
      remotes::install_version(
        package,
        version = case$pins[[package]],
        lib = library,
        upgrade = "never",
        dependencies = NA
      )
      stopifnot(floor_satisfies(
        as.character(utils::packageVersion(package)),
        "==",
        case$pins[[package]]
      ))
    }
    floor_audit(case, include_tidystata = FALSE)
  } else {
    root <- normalizePath(".", winslash = "/")
    script <- normalizePath(
      ".opencode/workflows/dependency_minimums.R",
      winslash = "/"
    )
    destination <- floor_run_directory(Sys.getenv("TIDYSTATA_FLOOR_RESULTS"))
    run_id <- basename(destination)
    Sys.setenv(
      TIDYSTATA_FLOOR_RESULTS = destination,
      TIDYSTATA_FLOOR_RUN_ID = run_id,
      TIDYSTATA_FLOOR_CASE = case_file,
      TIDYSTATA_FLOOR_SCRIPT = script,
      `_R_CHECK_FORCE_SUGGESTS_` = "false",
      R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep)
    )
    scratch <- tempfile("tidystata-floor-")
    dir.create(scratch)
    bundle <- pkgbuild::build(
      root,
      dest_path = scratch,
      vignettes = FALSE,
      manual = FALSE,
      quiet = FALSE
    )
    utils::untar(bundle, exdir = scratch)
    source <- file.path(scratch, "tidystata")
    entrypoint <- file.path(source, "tests", "testthat.R")
    original <- readLines(entrypoint, encoding = "UTF-8")
    # The receipt runs inside R CMD check's installed-package test process.
    # This instrumentation affects only the temporary floor-check source.
    writeLines(
      c(
        "source(Sys.getenv('TIDYSTATA_FLOOR_SCRIPT'))",
        "library(tidystata)",
        "dependency_floor_receipt(Sys.getenv('TIDYSTATA_FLOOR_CASE'))",
        "floor_results <- local({",
        original,
        "})",
        "dependency_floor_receipt(Sys.getenv('TIDYSTATA_FLOOR_CASE'), floor_results, 'after')"
      ),
      entrypoint,
      useBytes = TRUE
    )
    result <- rcmdcheck::rcmdcheck(
      source,
      args = "--no-manual",
      check_dir = file.path(destination, "check"),
      error_on = "never",
      libpath = .libPaths(),
      quiet = FALSE
    )
    saveRDS(result, file.path(destination, "check-result.rds"))
    floor_check_complete(
      result,
      file.path(destination, "check", "tidystata.Rcheck", "00check.log"),
      destination,
      run_id
    )
  }
}

if (sys.nframe() == 0L) {
  dependency_floor_main(commandArgs(trailingOnly = TRUE))
}
