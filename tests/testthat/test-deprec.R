test_that("s_match() is deprecated and gives identical results", {
  data <- tibble::tibble(x1 = 1, x2 = 2, y = 3)
  lifecycle::expect_deprecated(old <- s_match("x*", vars = names(data)))
  expect_identical(old, varlist("x*", vars = names(data)))
  withr::local_options(lifecycle_verbosity = "quiet")
  expect_identical(ds(data, s_match("x*")), ds(data, varlist("x*")))
})

test_that("s_type() and s_unit() are deprecated and give identical results", {
  lifecycle::expect_deprecated(old_type <- s_type(1L, abbr = TRUE))
  expect_identical(old_type, var_type(1L, abbr = TRUE))
  lifecycle::expect_deprecated(
    old_unit <- s_unit(as.difftime(1, units = "secs"))
  )
  expect_identical(old_unit, var_unit(as.difftime(1, units = "secs")))
})

test_that("earlier names are quiet aliases or current names", {
  data <- tibble::tibble(x1 = 1, x2 = 2, y = 3)
  cross <- tibble::tibble(a = c("p", "q"), b = c("u", "u"))
  expect_silent(cut_quantile(1:8, 2))
  expect_silent(s_try(stop("x")))
  expect_silent(names_as_column(data))
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
    names(s_select(data, varlist("x*"), z = y * 2)),
    c("x1", "x2", "z")
  )
})

test_that("aliases are exported and identical to their primary functions", {
  same <- list(
    xtab = "tab2",
    cut_quantile = "xtile",
    s_try = "capture",
    names_as_column = "ds_as_column",
    pct = "pc",
    s_tag = "is_first",
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

test_that("wrapper aliases give the same results as their primary functions", {
  x <- c(1, -98, -99, NA)
  expect_identical(na_if_value(x, -99), mvdecode(x, -99))
  expect_identical(value_if_na(x, 0), mvencode(x, 0))
  labelled <- haven::labelled(c(1, 2, NA), c(Low = 1, High = 2))
  expect_identical(destring(c("1,000", "2.5")), as_numeric(c("1,000", "2.5")))
  expect_identical(decode(labelled), as_character(labelled))
  data <- tibble::tibble(a = 1, b = 2)
  expect_identical(ds(data, .type = "table"), ds_as_column(data))
  expect_identical(ds(data, b, .type = "table"), names_as_column(data, b))
  expect_identical(ds(data, .type = "vector"), ds(data))
  rows <- list(c(1, 1, NA), c(2, 1, NA), c(NA, 1, 3))
  expect_identical(
    row_nvals(rows[[1]], rows[[2]], rows[[3]], .missing = TRUE),
    row_unique(rows[[1]], rows[[2]], rows[[3]])
  )
})

test_that("renamed arguments still work with a deprecation warning", {
  d <- tibble::tibble(g = c("a", NA), x = 1:2)
  people <- tibble::tibble(id = 1:2, age = c(30, 41))
  income <- tibble::tibble(id = 2:3, income = c(10, 20))
  merge_args <- list(people, income, "1:1", by = "id")
  # Each renamed argument warns once and gives the new argument's result.
  expect_renamed <- function(old, new) {
    lifecycle::expect_deprecated(out <- old)
    expect_identical(out, new)
  }
  expect_renamed(destring(.x = "1"), destring("1"))
  expect_renamed(decode(.x = 1), decode(1))
  expect_renamed(var_type(.x = 1L), var_type(1L))
  expect_renamed(var_type(1L, .abbr = TRUE), var_type(1L, abbr = TRUE))
  expect_renamed(var_unit(.x = 1), var_unit(1))
  expect_renamed(na_if_value(.x = c(1, 9), 9), na_if_value(c(1, 9), 9))
  expect_renamed(var_type(.x = 1L, TRUE), var_type(1L, TRUE))
  expect_renamed(na_if_value(c(1, 9), .value = 9), na_if_value(c(1, 9), 9))
  expect_renamed(value_if_na(.x = c(1, NA), 0), value_if_na(c(1, NA), 0))
  expect_renamed(value_if_na(c(1, NA), .value = 0), value_if_na(c(1, NA), 0))
  lifecycle::expect_deprecated(expect_message(timer(.x = 1), "Time spent"))
  lifecycle::expect_deprecated(expect_message(timer(1, .on_error = TRUE)))
  lifecycle::expect_deprecated(expect_false(capture(.fn = stop("x"))))
  expect_renamed(
    set_seed(.fn = stats::runif(1), seed = 1),
    set_seed(stats::runif(1), 1)
  )
  expect_renamed(
    varlist("X*", ignore.case = FALSE, vars = c("x1", "X2")),
    varlist("X*", ignore_case = FALSE, vars = c("x1", "X2"))
  )
  quiet <- c(merge_args, report = FALSE)
  expect_renamed(
    do.call(s_merge, c(quiet, .keep = "match")),
    do.call(s_merge, c(quiet, keep = "match"))
  )
  expect_renamed(
    do.call(s_merge, c(quiet, .generate = "m")),
    do.call(s_merge, c(quiet, generate = "m"))
  )
  expect_renamed(
    do.call(s_merge, c(merge_args, .report = FALSE)),
    do.call(s_merge, quiet)
  )
  expect_error(
    lifecycle::expect_deprecated(do.call(s_merge, c(quiet, .assert = "match"))),
    "Merge assertion failed"
  )
  expect_renamed(
    summ(d, x, .by = g, .na.rm = TRUE),
    summ(d, x, .by = g, .missing = FALSE)
  )
  expect_renamed(tabstat(d, x, .mode = "table"), tabstat(d, x, .type = "table"))
})
