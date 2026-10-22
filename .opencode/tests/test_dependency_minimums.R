# Offline checks of the checking-session audit, using temporary metadata only.
source(".opencode/workflows/dependency_minimums.R")

stopifnot(floor_satisfies("1.0-0", "==", "1.0.0"))
requirements <- floor_dependencies(list(
  Imports = "first (>= 2.0), second\r\n",
  LinkingTo = "third (== 1.0)"
))
stopifnot(
  length(requirements) == 3L,
  requirements[[1]]$operator == ">=",
  requirements[[2]]$operator == ""
)

temporary <- tempfile("tidystata-floor-audit-")
dir.create(temporary)
packages <- c(
  "auditfixture",
  "fixturedep",
  "rcmdcheck",
  "knitr",
  "rmarkdown",
  "withr",
  "bit64",
  "data.table"
)
for (package in packages) {
  directory <- file.path(temporary, package)
  dir.create(directory)
  writeLines(
    c(
      paste0("Package: ", package),
      "Version: 1.0",
      if (package == "auditfixture") "Imports: fixturedep (>= 2.0)"
    ),
    file.path(directory, "DESCRIPTION"),
    useBytes = TRUE
  )
}
.libPaths(c(temporary, .libPaths()))
case <- list(pins = list(auditfixture = "1.0"))
error <- tryCatch(
  floor_audit(case, include_tidystata = FALSE),
  error = identity
)
stopifnot(
  inherits(error, "error"),
  grepl(
    "auditfixture requires fixturedep >=2.0; selected 1.0",
    conditionMessage(error),
    fixed = TRUE
  )
)
writeLines(
  c("Package: fixturedep", "Version: 2.0"),
  file.path(temporary, "fixturedep", "DESCRIPTION"),
  useBytes = TRUE
)
records <- floor_audit(case, include_tidystata = FALSE)
stopifnot(
  length(records) == length(packages),
  identical(records$fixturedep$version, "2.0")
)
case$pins$auditfixture <- "1.1"
error <- tryCatch(
  floor_audit(case, include_tidystata = FALSE),
  error = identity
)
stopifnot(inherits(error, "error"))
cat("Dependency constraints and exact candidate auditing passed.\n")

base <- tempfile("tidystata-floor-completion-")
dir.create(base)
run <- floor_run_directory(base)
id <- basename(run)
log_path <- file.path(run, "00check.log")
complete <- c(
  "* checking tests ...",
  "  Running 'testthat.R'",
  " OK",
  "* DONE",
  "Status: OK"
)
writeLines(complete, log_path)
good <- list(
  errors = character(),
  warnings = character(),
  status = 0L,
  timeout = FALSE
)
write_receipt <- function(phase, run_id = id, passed = 1L) {
  jsonlite::write_json(
    list(
      run_id = run_id,
      phase = phase,
      totals = list(passed = passed, failed = 0L, error = 0L, warning = 0L)
    ),
    file.path(run, paste0(phase, ".json")),
    auto_unbox = TRUE
  )
}
write_receipt("before")
write_receipt("after")
stopifnot(floor_check_complete(good, log_path, run, id))
rejects <- function(
  result = good,
  path = log_path,
  directory = run,
  run_id = id
) {
  inherits(
    tryCatch(
      floor_check_complete(result, path, directory, run_id),
      error = identity
    ),
    "error"
  )
}
bad <- good
bad$status <- 1L
stopifnot(rejects(bad))
bad <- good
bad$timeout <- TRUE
stopifnot(rejects(bad))
bad <- good
bad$status <- NULL
stopifnot(rejects(bad))
writeLines(complete[1:3], log_path)
stopifnot(rejects())
writeLines(c("* DONE", "Status: OK"), log_path)
stopifnot(rejects())
writeLines(c("* checking tests ... SKIPPED", "* DONE", "Status: OK"), log_path)
stopifnot(rejects())
writeLines(complete, log_path)
write_receipt("after", run_id = "old-run")
stopifnot(rejects())
write_receipt("after", passed = 0L)
stopifnot(rejects())
write_receipt("after")
# Earlier receipts cannot satisfy completion for a new reserved directory.
fresh <- floor_run_directory(base)
stopifnot(
  !identical(fresh, run),
  file.exists(file.path(run, "after.json")),
  rejects(directory = fresh, run_id = basename(fresh))
)
stopifnot(floor_check_complete(good, log_path, run, id))
cat("Floor completion rejects failed, timed-out, incomplete and stale runs.\n")
