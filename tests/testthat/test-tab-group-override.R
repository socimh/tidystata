# Explicit zero-column .by disables inherited grouping; NULL inherits it.
for (.fn_name in c("tab", "fre", "tab1", "fre1")) local({
  function_name <- .fn_name
  test_that(paste(function_name, "explicit empty by removes inherited grouping"), {
    d <- tibble::tibble(g = c("a", "b", "a", "b"), x = c(1, 1, 2, 2))
    grouped <- dplyr::group_by(d, g)
    before <- grouped
    fn <- getExportedValue("statart", function_name)
    expect_identical(fn(grouped, x, .by = character()), fn(d, x))
    expect_identical(fn(grouped, x, .by = NULL), fn(d, x, .by = g))
    expect_identical(grouped, before)
  })
})
