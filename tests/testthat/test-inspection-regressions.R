# Public-contract regressions, independent of implementation helpers.
for (.bad_query in list(
  character(),
  c("a", "b"),
  NA_character_,
  1,
  TRUE,
  list("a"),
  factor("a")
)) {
  local({
    bad <- .bad_query
    test_that(
      paste(
        "variables_search validates query",
        paste(capture.output(dput(bad)), collapse = "")
      ),
      {
        d <- tibble::tibble(a = 1:2, b = 3:4)
        before <- d
        expect_error(
          variables_search(d, bad),
          "single non-missing character string",
          fixed = TRUE
        )
        expect_error(
          variables_search(d[, FALSE], bad),
          "single non-missing character string",
          fixed = TRUE
        )
        expect_identical(d, before)
      }
    )
  })
}
test_that("variables_search preserves empty-string all-variable search", {
  d <- tibble::tibble(z = 1:2, a = 3:4)
  expect_identical(variables_search(d, "")$name, c("z", "a"))
})

test_that("variables_search accepts letter ranges without numeric-coercion warnings", {
  d <- tibble::tibble(item_a = 1:2, item_b = 3:4, item_c = 5:6, item_z = 7:8)
  before <- d
  expect_no_warning(out <- variables_search(d, "^item_[a-c]$"))
  expect_identical(out$name, c("item_a", "item_b", "item_c"))
  expect_identical(d, before)
})
test_that("letter range translation remains compatible with ds and s_match", {
  d <- tibble::tibble(xA = 1:2, xB = 3:4, xC = 5:6, xZ = 7:8)
  expect_no_warning(out <- ds(d, s_match("x[A-C]")))
  expect_identical(out, c("xA", "xB", "xC"))
})
