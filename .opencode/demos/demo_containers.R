# Demo: table containers, pipelines and reference isolation.
# Runs against the fresh installation selected by the demo workflow.
library(statart)

fixture <- data.frame(g = c("a", "a", "b"), x = c(1, 3, 5))
inputs <- list(data.frame = fixture, tibble = tibble::as_tibble(fixture))
if (requireNamespace("data.table", quietly = TRUE)) {
  inputs$data.table <- data.table::as.data.table(fixture)
}
calls <- list(
  tab = function(x) tab(x, g),
  tab1 = function(x) tab1(x, g)[[1]],
  tab2 = function(x) xtab(x, g, x),
  fre = function(x) fre(x, g),
  fre1 = function(x) fre1(x, g)[[1]],
  fre2 = function(x) xtab(x, g, x, .total = TRUE),
  summ = function(x) summ(x, x),
  tabstat = function(x) tabstat(x, x),
  codebook = function(x) codebook(x),
  ds_as_column = function(x) ds_as_column(x),
  ds_as_column = function(x) ds_as_column(x),
  variables = function(x) variables(x),
  variables_search = function(x) variables_search(x, "g"),
  slice_headtail = function(x) slice_headtail(x, n = 2),
  slice_interval = function(x) slice_interval(x, n = 2),
  preview_round_trip = function(x) unpreview_table(preview_table(x))
)

cat("## Example: container preservation and downstream operations\n\n```text\n")
local({
  cat(
    "Installed statart:",
    as.character(utils::packageVersion("statart")),
    "\n"
  )
  cat("Container checks (list functions show their first table):\n")
  for (kind in names(inputs)) {
    input <- inputs[[kind]]
    for (name in names(calls)) {
      result <- calls[[name]](input)
      stopifnot(identical(class(result), class(input)))
      cat(kind, name, paste(class(result), collapse = "/"), "PASS\n")
    }
  }
  cat("\nCounts and downstream mutation:\n")
  counts <- tab(fixture, g) |> dplyr::mutate(twice = n * 2)
  stopifnot(identical(counts$twice, c(4, 2)))
  print(counts)
  cat("\nSummary:\n")
  print(summ(fixture, x))
  cat("\nExplicit tibble override:\n")
  print(class(fre(fixture, g, .type = "tibble")))
  stopifnot(tibble::is_tibble(fre(fixture, g, .type = "tibble")))
  cat("\nBase-frame preview and unchanged round trip:\n")
  wrapped <- preview_table(fixture, n = 2)
  print(class(wrapped))
  print(wrapped)
  stopifnot(identical(unpreview_table(wrapped), fixture))
  if ("data.table" %in% names(inputs)) {
    cat("\nNative data.table preview mutation leaves original unchanged:\n")
    original <- inputs$data.table
    wrapped <- preview_table(original)
    wrapped[, x := x * 2]
    stopifnot(identical(original$x, c(1, 3, 5)))
    stopifnot(identical(wrapped$x, c(2, 6, 10)))
    print(wrapped[, list(total = sum(x)), by = g])
  }
  cat("\nAll container and demonstration assertions passed.\n")
})
cat("```\n")
