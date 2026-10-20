# Generate one stable set of current actual-output reports.
index_only <- "--index-only" %in% commandArgs(trailingOnly = TRUE)
if (!index_only && !nzchar(Sys.getenv("STATART_DEMO_SOURCE"))) {
  status <- system2(
    "python",
    c(
      ".opencode/workflows/verify_package.py",
      "--demos",
      "--prefix",
      ".opencode/results/demos"
    )
  )
  quit(status = status)
}
reports_dir <- Sys.getenv("STATART_REPORT_DIR", ".opencode/reports")
if (!index_only) {
  library_path <- Sys.getenv("STATART_DEMO_LIBRARY")
  if (!nzchar(library_path)) {
    stop(
      "Run demos through verify_package.py --demos to use a fresh installation."
    )
  }
  library(statart, lib.loc = library_path)
}
dir.create(reports_dir, recursive = TRUE, showWarnings = FALSE)
version <- read.dcf("DESCRIPTION")[1, "Version"]
demo_files <- list.files(
  ".opencode/demos",
  pattern = "^demo_.*[.]R$",
  full.names = TRUE
)
func_descriptions <- c(
  browse = "Browse data",
  codebook = "Variable metadata",
  cut = "Numeric bins",
  conversion = "Conversion and missing-value preparation",
  findit = "Stata command lookup",
  fre = "Frequencies and totals",
  keys = "Key checks, duplicates and merges",
  checks = "Assertions, first-row flags and full listings",
  panel = "Gap-aware panel lags, leads and differences",
  dummy = "Standardising, percentages and indicator variables",
  misstable = "Missing-value summaries and patterns",
  pwcorr = "Pairwise correlations and chi-square tests",
  weights = "Frequency and analytic weights",
  row_egen = "Row calculations",
  special_print = "Persistent table previews",
  s_select = "Selection and expressions",
  summ = "Summary statistics",
  tab = "Frequency tables",
  tab1 = "Separate frequency tables",
  timer = "Timing",
  textbook = "Textbook alignment contracts",
  problems2 = "Historical problem repairs and examples",
  readiness = "Remaining-issue triage and small repairs",
  containers = "Table container preservation"
)
all_reports <- list()
for (file in demo_files) {
  name <- sub("[.]R$", "", sub("^demo_", "", basename(file)))
  if (index_only) {
    report_file <- sprintf("report_%s.md", name)
    text <- readLines(file.path(reports_dir, report_file), encoding = "UTF-8")
    status_line <- grep("Status:.*(PASS|FAIL)", text, value = TRUE)
    if (length(status_line) != 1L) {
      stop("Missing or ambiguous demo status: ", report_file)
    }
    all_reports[[name]] <- list(
      file = report_file,
      status = if (grepl("Status:.*PASS", status_line)) "PASS" else "FAIL",
      examples = sum(grepl("^## Example", text))
    )
    next
  }
  failure <- NULL
  output <- capture.output({
    tryCatch(
      withCallingHandlers(
        {
          source(file, local = TRUE, encoding = "UTF-8")
        },
        message = function(m) {
          cat(conditionMessage(m), "\n")
          invokeRestart("muffleMessage")
        },
        warning = function(w) {
          cat("Warning: ", conditionMessage(w), "\n", sep = "")
          invokeRestart("muffleWarning")
        }
      ),
      error = function(e) {
        failure <<- conditionMessage(e)
        cat("ERROR: ", failure, "\n", sep = "")
      }
    )
  })
  if (sum(grepl("^```", output)) %% 2L) {
    output <- c(output, "```")
  }
  output <- sub("[[:blank:]]+$", "", output)
  report_file <- sprintf("report_%s.md", name)
  status <- if (is.null(failure)) "PASS" else "FAIL"
  writeLines(
    enc2utf8(c(
      if (name == "textbook") {
        "# Function contracts: textbook alignment"
      } else if (name == "problems2") {
        "# Historical problems: repaired examples"
      } else {
        sprintf("# Function: %s()", name)
      },
      "",
      sprintf(
        "**Version:** %s | **Generated:** %s | **Status:** %s",
        version,
        format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        status
      ),
      "",
      output
    )),
    file.path(reports_dir, report_file),
    useBytes = TRUE
  )
  all_reports[[name]] <- list(
    file = report_file,
    status = status,
    examples = sum(grepl("^## Example", output))
  )
  cat(name, status, "\n")
}
index <- c(
  "# Function Reports Index",
  "",
  sprintf(
    "Current development version: %s. Reports contain actual console output.",
    version
  ),
  "A passing demo is not a passing full package test suite.",
  "",
  "| Function | Description | Examples | Status | Report |",
  "| --- | --- | ---: | --- | --- |"
)
for (name in names(all_reports)) {
  item <- all_reports[[name]]
  description <- func_descriptions[[name]]
  index <- c(
    index,
    sprintf(
      "| %s | %s | %s | %s | [View](%s) |",
      name,
      description,
      item$examples,
      item$status,
      item$file
    )
  )
}
index <- c(
  index,
  "",
  "## Regeneration",
  "",
  "Run `make demo-reports` from the project root.",
  "The workflow builds native code in a fresh temporary copy and refreshes the current reports."
)
writeLines(enc2utf8(index), file.path(reports_dir, "INDEX.md"), useBytes = TRUE)
if (any(vapply(all_reports, function(x) x$status == "FAIL", logical(1)))) {
  quit(status = 1L)
}
