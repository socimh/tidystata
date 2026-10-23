test_that("aliases are quiet", {
  cross <- tibble::tibble(a = c("p", "q"), b = c("u", "u"))
  expect_silent(cut_quantile(1:8, 2))
  expect_silent(tab2(cross, a, b))
  expect_silent(fre2(cross, a, b))
  expect_identical(
    fre2(cross, a, b, .flip = TRUE),
    tab2(cross, a, b, .flip = TRUE, .total = TRUE)
  )
})

test_that("varlist() is recognised as a selection inside computed selections", {
  data <- tibble::tibble(x1 = 1:2, x2 = 3:4, y = 5:6)
  expect_identical(
    names(select_or_mutate(data, varlist("x*"), z = y * 2)),
    c("x1", "x2", "z")
  )
})

test_that("aliases are exported and identical to their primary functions", {
  same <- list(
    cut_quantile = "xtile",
    as_numeric = "destring",
    as_character = "decode",
    pct = "pc",
    tab_gen = "as_dummy"
  )
  exports <- getNamespaceExports("tidystata")
  for (alias in names(same)) {
    expect_true(alias %in% exports, info = alias)
    expect_identical(
      getExportedValue("tidystata", alias),
      getExportedValue("tidystata", same[[alias]]),
      info = alias
    )
  }
  expect_false(any(c("search", "describe", "lookfor") %in% exports))
})

test_that("retired names are not exported", {
  retired <- c(
    "s_match",
    "s_type",
    "s_unit",
    "s_try",
    "s_tag",
    "s_print",
    "s_select",
    "s_merge",
    "s_lag",
    "s_lead",
    "s_diff",
    "ds_as_column",
    "names_as_column",
    "xtab"
  )
  exports <- getNamespaceExports("tidystata")
  expect_identical(intersect(retired, exports), character())
})

test_that("wrapper aliases give the same results as their primary functions", {
  x <- c(1, -98, -99, NA)
  expect_identical(na_if_value(x, -99), mvdecode(x, -99))
  expect_identical(value_if_na(x, 0), mvencode(x, 0))
  labelled <- haven::labelled(c(1, 2, NA), c(Low = 1, High = 2))
  expect_identical(destring(c("1,000", "2.5")), as_numeric(c("1,000", "2.5")))
  expect_identical(decode(labelled), as_character(labelled))
  data <- tibble::tibble(a = 1, b = 2)
  expect_identical(ds(data, .type = "vector"), ds(data))
  rows <- list(c(1, 1, NA), c(2, 1, NA), c(NA, 1, 3))
  expect_identical(
    row_nvals(rows[[1]], rows[[2]], rows[[3]], .missing = TRUE),
    row_unique(rows[[1]], rows[[2]], rows[[3]])
  )
})
