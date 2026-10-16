# Compare accepted outputs and public interfaces with the installed baseline.
args <- commandArgs(trailingOnly = TRUE)
library_path <- args[[1L]]
mode <- args[[2L]]
record_path <- args[[3L]]
.libPaths(c(library_path, .libPaths()))
suppressPackageStartupMessages(library(statart))

data <- tibble::tibble(
  group = c("A", "A", "B", "B"),
  x = c(1, 3, NA, 7),
  y = c(2, NA, 6, 8),
  category = factor(
    c("yes", "no", "yes", NA),
    levels = c("yes", "no", "unused")
  )
)
attr(data$x, "label") <- "Observed score"
grouped <- dplyr::group_by(data, group)
calls <- list(
  summary = quote(summ(data, x, y)),
  summary_grouped = quote(summ(grouped, x, y)),
  summary_table = quote(summ(data, x, y, .mode = "table")),
  tabstat = quote(tabstat(data, x, y, .stat = c("mean", "p50", "sum"))),
  tab = quote(tab(data, category)),
  tab1 = quote(tab1(data, x, category)),
  tab2 = quote(tab2(data, group, category)),
  fre = quote(fre(data, category)),
  fre1 = quote(fre1(data, x, category)),
  fre2 = quote(fre2(data, group, category)),
  codebook = quote(codebook(data)),
  grouped_codebook = quote(codebook(grouped, x, category)),
  structured_codebook = quote(codebook(tibble::tibble(x = list(NULL, NA, 1)))),
  browse = quote(browse(data, x, y)),
  ds = quote(ds(data, score = x, category)),
  names = quote(names_as_column(data, category, x)),
  ds_as_column = quote(ds_as_column(data, x)),
  variables = quote(variables(data, score = x, category)),
  search = quote(variables_search(data, "score")),
  anchored_search = quote(variables_search(data, "^category$")),
  empty_summary = quote(summ(data[FALSE, ], x, y)),
  empty_codebook = quote(codebook(data, tidyselect::any_of("absent"))),
  row_pipeline = quote(dplyr::mutate(data, total = row_sum(dplyr::pick(x, y)))),
  conversion = quote(as_character(haven::labelled(
    c(1, NA, 2),
    c(Yes = 1, No = 2)
  )))
)
capture <- function(call) {
  warnings <- messages <- character()
  visible <- withCallingHandlers(
    withVisible(eval(call, envir = .GlobalEnv)),
    warning = function(condition) {
      warnings <<- c(warnings, conditionMessage(condition))
      invokeRestart("muffleWarning")
    },
    message = function(condition) {
      messages <<- c(messages, conditionMessage(condition))
      invokeRestart("muffleMessage")
    }
  )
  list(
    value = visible$value,
    visible = visible$visible,
    warnings = warnings,
    messages = messages
  )
}
exports <- sort(getNamespaceExports("statart"))
interfaces <- lapply(exports, function(name) {
  object <- getExportedValue("statart", name)
  if (is.function(object)) formals(object) else class(object)
})
names(interfaces) <- exports
record <- list(interfaces = interfaces, outputs = lapply(calls, capture))
if (mode == "baseline") {
  saveRDS(record, record_path)
  cat(
    "Saved baseline:",
    length(exports),
    "exports and",
    length(calls),
    "outputs\n"
  )
} else {
  baseline <- readRDS(record_path)
  stopifnot(identical(record$interfaces, baseline$interfaces))
  for (name in names(calls)) {
    if (!identical(record$outputs[[name]], baseline$outputs[[name]])) {
      stop("Compatibility difference: ", name)
    }
    cat("PASS", name, "\n")
  }
  cat(
    "Verified unchanged:",
    length(exports),
    "public interfaces and",
    length(calls),
    "value/visibility/diagnostic records\n"
  )
}
