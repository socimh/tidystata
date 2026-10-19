# Called by check_style.py; on Windows the protected launcher is mandatory.
args <- commandArgs(trailingOnly = TRUE)
local_library <- Sys.getenv(
  "STATART_STYLE_LIBRARY",
  ".opencode/tools/style-tools/library"
)
if (dir.exists(local_library)) {
  .libPaths(c(normalizePath(local_library), .libPaths()))
}
scope <- jsonlite::fromJSON(args[[1L]])
if (as.character(utils::packageVersion("lintr")) != scope$lintr_version) {
  stop("Install the pinned lintr version: ", scope$lintr_version)
}
issues <- list()
for (path in scope$files) {
  parse(path, keep.source = FALSE)
  linters <- list(namespace = lintr::namespace_linter())
  if (startsWith(path, "R/")) {
    linters$package_side_effects <- lintr::undesirable_function_linter(
      fun = c(
        "library" = "Use namespace qualification in package code.",
        "require" = "Use requireNamespace() for optional dependencies.",
        "attach" = "Do not attach data to the search path.",
        "setwd" = "Do not change the user's working directory.",
        "install.packages" = "Do not install dependencies in package code."
      )
    )
  }
  result <- lintr::lint(path, linters = linters, cache = FALSE)
  # Explicit stats/utils qualification remains useful when readers attach other
  # packages. Keep this narrow exception; missing packages/exports still fail.
  redundant_import <- vapply(
    result,
    function(item) {
      grepl(
        "^Don't use `::` to access .+, which is already imported from (stats|utils)[.]$",
        item$message
      )
    },
    logical(1)
  )
  result <- result[!redundant_import]
  if (length(result)) {
    print(result)
    issues <- c(issues, result)
  }
}
cat(
  "Parsed and linted",
  length(scope$files),
  "R sources; findings:",
  length(issues),
  "\n"
)
if (length(issues)) {
  quit(status = 1L)
}
