# Install/load smoke check with optional packages absent from the library path.
args <- commandArgs(trailingOnly = TRUE)
installed_library <- args[[1L]]
minimal_library <- args[[2L]]
.libPaths(c(installed_library, .libPaths()))
ip <- installed.packages()
dependencies <- tools::package_dependencies(
  "statart",
  db = ip,
  which = c("Depends", "Imports", "LinkingTo"),
  recursive = TRUE
)[[1L]]
dependencies <- unique(c("statart", dependencies))
base_packages <- unique(rownames(ip)[!is.na(ip[, "Priority"])])
required_count <- length(setdiff(dependencies, c("R", base_packages)))
dependencies <- setdiff(unique(c(dependencies, base_packages)), "R")
dir.create(minimal_library, recursive = TRUE, showWarnings = FALSE)
for (package in dependencies) {
  path <- find.package(package)
  if (!file.copy(path, minimal_library, recursive = TRUE)) {
    stop("Could not prepare required dependency: ", package)
  }
}
.libPaths(c(minimal_library, .Library), include.site = FALSE)
# This machine installs optional packages in .Library itself. Restrict the
# process-local search path to the copied library, including base/recommended.
library_environment <- environment(.libPaths)
stopifnot(exists(".lib.loc", envir = library_environment, inherits = FALSE))
assign(
  ".lib.loc",
  normalizePath(minimal_library, winslash = "/"),
  envir = library_environment
)
stopifnot(!requireNamespace("flextable", quietly = TRUE))
library(statart)
stopifnot(length(getNamespaceExports("statart")) == 46L)
preview <- preview_table(tibble::tibble(id = 1:30), n = 4)
stopifnot(nrow(preview) == 30L, identical(preview$id, 1:30))
stopifnot(inherits(dplyr::mutate(preview, twice = id * 2), "statart_preview"))
stopifnot(length(capture.output(print(preview))) > 0L)
stopifnot(
  !any(
    c("read_data", "write_data", "esttab", "codebook_detail") %in%
      getNamespaceExports("statart")
  )
)
d <- data.frame(g = c("A", "A", NA), x = c(1, NA, 2), y = c(3, NA, 4))
stopifnot(
  identical(class(fre(d, x)), "data.frame"),
  is.list(fre1(d, x)),
  identical(class(fre2(d, x, y)), "data.frame"),
  identical(row_max(d[c("x", "y")]), c(3, NA_real_, 4)),
  identical(as_numeric(c("1", "2")), c(1, 2)),
  nrow(tab1(d, x, .by = g)$x) == 3L,
  nrow(codebook(d)) == 3L,
  nrow(summ(d, x, .mode = "table")) == 1L,
  length(cut_quantile(1:20)) == 20L
)
error <- tryCatch(fre(d, x, .type = "flextable"), error = function(e) {
  conditionMessage(e)
})
stopifnot(is.character(error), grepl("optional flextable", error))
stopifnot(!requireNamespace("data.table", quietly = TRUE))
serialized_table <- structure(d, class = c("data.table", "data.frame"))
for (operation in list(
  function() tab(serialized_table, x),
  function() preview_table(serialized_table),
  function() unpreview_table(serialized_table)
)) {
  diagnostic <- tryCatch(operation(), error = conditionMessage)
  stopifnot(is.character(diagnostic), grepl("Install.*data.table", diagnostic))
}
cat(
  "PASS: core load, exports, grouping, conversion, rows, summaries, bins,\n",
  "and actionable optional-formatting error with required dependencies only.\n"
)
cat(
  "Required non-base/recommended packages including statart:",
  required_count,
  "\n"
)
