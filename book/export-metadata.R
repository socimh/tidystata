# Export selection annotations from current source, never a stale installed copy.
args <- commandArgs(trailingOnly = TRUE)
root <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
development_library <- file.path(root, ".opencode", "tools", "library")
if (dir.exists(development_library)) {
  .libPaths(c(development_library, .libPaths()))
}
pkgload::load_all(
  root,
  compile = FALSE,
  helpers = FALSE,
  attach_testthat = FALSE,
  quiet = TRUE,
  export_all = FALSE
)
entries <- tidystata:::findit_entries()
templates <- tidystata:::findit_templates()
preferred <- unlist(
  lapply(unique(entries$command), function(command) {
    found <- do.call(tidystata::findit, list(command = command))
    attr(found, "entry_ids")[attr(found, "default_rows")]
  }),
  use.names = FALSE
)
metadata <- data.frame(
  id = entries$id,
  priority = vapply(templates[entries$id], function(x) x$priority, integer(1)),
  meaning = vapply(templates[entries$id], function(x) x$meaning, character(1)),
  preferred = entries$id %in% preferred
)
readr::write_csv(metadata, args[[2L]])
