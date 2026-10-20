test_that("aliases are exported and identical to their primary functions", {
  same <- list(
    xtab = "tab2",
    cut_quantile = "xtile",
    s_try = "capture",
    names_as_column = "ds_as_column",
    pct = "pc",
    s_tag = "is_first",
    tab_gen = "as_dummy",
    var_type = "s_type",
    var_unit = "s_unit"
  )
  exports <- getNamespaceExports("statart")
  for (alias in names(same)) {
    expect_true(alias %in% exports, info = alias)
    expect_identical(
      getExportedValue("statart", alias),
      getExportedValue("statart", same[[alias]]),
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

test_that("mvdecode() treats several codes as a set and mvencode() fills", {
  expect_identical(mvdecode(c(1, -98, -99, NA), c(-98, -99)), c(1, NA, NA, NA))
  expect_identical(mvdecode(c(a = 1L, b = 2L), 2L), c(a = 1L, b = NA))
  expect_identical(mvdecode(1:3, integer()), 1:3)
  expect_error(mvdecode(1:3, 1.5), class = "vctrs_error_cast_lossy")
  expect_error(mvdecode(1), "Missing `mv`. Use mvdecode(x, mv)", fixed = TRUE)
  expect_error(mvencode(), "Missing `x`. Use mvencode(x, mv)", fixed = TRUE)
  labelled <- haven::labelled(c(1, -99, 2), c(Yes = 1, No = 2))
  decoded <- mvdecode(labelled, -99)
  expect_s3_class(decoded, "haven_labelled")
  expect_identical(as.numeric(unclass(decoded)), c(1, NA, 2))
  spss <- haven::labelled_spss(c(1, 9, NA), c(Yes = 1), na_values = 9)
  filled <- mvencode(spss, 0)
  expect_identical(as.numeric(unclass(filled)), c(1, 0, 0))
  expect_identical(
    dplyr::mutate(
      tibble::tibble(x = c(1, -99), y = c(-99, 2)),
      dplyr::across(c(x, y), \(v) mvdecode(v, -99))
    ),
    tibble::tibble(x = c(1, NA), y = c(NA, 2))
  )
})

test_that("tostring() gives codes as text, ignoring value labels", {
  labelled <- haven::labelled(c(1, 2, NA), c(Low = 1, High = 2))
  expect_identical(tostring(labelled), c("1", "2", NA))
  expect_identical(decode(labelled), c("Low", "High", NA))
  expect_identical(tostring(factor(c("b", "a", NA))), c("2", "1", NA))
  expect_identical(tostring(c("x", NA)), c("x", NA))
  expect_identical(tostring(c(0.5, NA, NaN)), c("0.5", NA, NA))
  expect_identical(tostring(c(TRUE, NA)), c("TRUE", NA))
  expect_identical(tostring(as.Date("2024-01-31")), "2024-01-31")
  expect_identical(tostring(haven::tagged_na("a")), NA_character_)
  expect_identical(tostring(integer()), character())
})

test_that("row_nvals() ignores missing values like egenmore's rownvals()", {
  a <- c(1, 1, NA, NA)
  b <- c(2, 1, NA, 4)
  c <- c(NA, 1, 3, 4)
  expect_identical(row_nvals(a, b, c), c(2L, 1L, 1L, 1L))
  expect_identical(row_unique(a, b, c), c(3L, 1L, 2L, 2L))
  data <- tibble::tibble(a, b, c)
  expect_identical(
    dplyr::mutate(data, n = row_nvals(a:c))$n,
    row_nvals(a, b, c)
  )
  expect_error(row_nvals(a, b, .missing = NA), ".missing")
})

test_that("tab2() returns every pairwise table for three or more variables", {
  d <- tibble::tibble(
    a = c(1, 1, 2, 2),
    b = c("x", "y", "y", "x"),
    c = c(TRUE, FALSE, TRUE, TRUE),
    w = c(1, 2, 1, 3)
  )
  out <- tab2(d, a, b, c)
  expect_type(out, "list")
  expect_named(out, c("a x b", "a x c", "b x c"))
  expect_identical(out[["a x c"]], tab2(d, a, c))
  totals <- fre2(d, a, b, c, .wt = w)
  expect_identical(totals[["b x c"]], tab2(d, b, c, .total = TRUE, .wt = w))
  messages <- capture_messages(tested <- tab2(d, a, b, c, .chi2 = TRUE))
  expect_identical(
    grep("^-> ", messages, value = TRUE),
    paste0("-> tabulation of ", c("a by b", "a by c", "b by c"), "\n")
  )
  expect_identical(
    attr(tested[["b x c"]], "chi2"),
    attr(suppressMessages(tab2(d, b, c, .chi2 = TRUE)), "chi2")
  )
  expect_error(tab2(d, a), "Please provide two variables")
  dt <- data.table::as.data.table(d)
  expect_s3_class(tab2(dt, a, b, c)[[1]], "data.table")
})

test_that("set_seed() works in a pipeline and alone", {
  set_seed(20261020)
  first <- stats::runif(2)
  set.seed(20261020)
  expect_identical(first, stats::runif(2))
  expect_invisible(set_seed(1))
  expect_null(set_seed(seed = 1))
  set_seed(seed = 7)
  first <- stats::runif(1)
  set.seed(7)
  expect_identical(first, stats::runif(1))
  piped <- sample(1:10, 3) %>% set_seed(123)
  set.seed(123)
  expect_identical(piped, sample(1:10, 3))
  expect_error(set_seed(), "Supply a seed")
  expect_error(set_seed("a"), "needs one number as the seed")
  expect_error(set_seed(c(1, 2)), "needs one number as the seed")
  expect_error(set_seed(NA_real_), "needs one number as the seed")
})

test_that("s_print() matches the print helpers for each style", {
  data <- tibble::tibble(i = 1:30, sq = (1:30)^2)
  expect_identical(
    capture.output(s_print(data)),
    capture.output(print_headtail(data))
  )
  expect_identical(
    capture.output(s_print(data, "interval", n = 4)),
    capture.output(print_interval(data, n = 4))
  )
  expect_identical(
    capture.output(s_print(data, "all")),
    capture.output(print_all(data))
  )
  expect_invisible(s_print(data, "interval"))
  expect_identical(withVisible(s_print(data))$value, data)
  expect_error(s_print(data, "middle"))
})
