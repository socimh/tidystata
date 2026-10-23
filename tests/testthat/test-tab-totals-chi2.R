test_that(".total gives the fre() results from tab() and tab1()", {
  data <- tibble::tibble(g = c("a", "a", "b", NA), x = c(1, 2, 2, 2))
  expect_identical(tab(data, x, .total = TRUE), fre(data, x))
  expect_identical(
    tab(data, x, .by = g, .desc = TRUE, .total = TRUE),
    fre(data, x, .by = g, .desc = TRUE)
  )
  expect_identical(tab(c(1, 1, 2), .total = TRUE), fre(c(1, 1, 2)))
  expect_identical(tab1(data, x, g, .total = TRUE), fre1(data, x, g))
  expect_identical(
    tab1(data, x, .type = "tibble", .total = TRUE),
    fre1(data, x, .type = "tibble")
  )
  expect_error(tab(data, x, .total = NA), "must be `TRUE` or `FALSE`")
})

test_that("tab2() cross-tabulates with optional totals", {
  data <- tibble::tibble(a = c("p", "p", "q"), b = c("u", "v", "v"))
  counts <- tab2(data, a, b)
  expect_identical(names(counts), c("a \\ b", "u", "v"))
  expect_identical(counts$u, c(1L, 0L))
  totals <- tab2(data, a, b, .total = TRUE)
  expect_true("total" %in% names(totals))
  expect_identical(totals$total, c(2L, 1L, 3L))
  expect_identical(names(tab2(data, a, b, .flip = TRUE))[[1]], "b \\ a")
  expect_error(
    tab2(data, a, b, .type = "flextable"),
    "requires `.total = TRUE`"
  )
  expect_error(tab2(data, a, b, .total = "yes"), "must be `TRUE` or `FALSE`")
})

test_that("tab2(.chi2 = TRUE) matches chisq.test() and Stata's signed V", {
  data <- tibble::tibble(
    a = c(1, 1, 2, 2, 2, 3, 3, 1),
    b = c("x", "y", "x", "x", "y", "y", "y", NA)
  )
  expect_message(
    out <- tab2(data, a, b, .chi2 = TRUE),
    "Pearson chi2\\(4\\) = .*Cramer's V"
  )
  test <- attr(out, "chi2")
  expect_named(test, c("statistic", "df", "p_value", "cramers_v", "n"))
  # Missing categories shown in the table are tested, as with useNA.
  reference <- suppressWarnings(chisq.test(
    table(data$a, data$b, useNA = "ifany"),
    correct = FALSE
  ))
  expect_equal(test$statistic, unname(reference$statistic))
  expect_identical(test$df, 4L)
  expect_equal(test$p_value, reference$p.value)
  expect_equal(test$cramers_v, sqrt(test$statistic / (8 * 2)))
  expect_identical(test$n, 8L)
  # The table itself is unchanged.
  attr(out, "chi2") <- NULL
  expect_identical(out, tab2(data, a, b))

  # 2 x 2: V is the signed phi coefficient.
  two <- tibble::tibble(a = c(1, 1, 2, 2, 2), b = c("x", "y", "x", "x", "y"))
  v <- attr(suppressMessages(tab2(two, a, b, .chi2 = TRUE)), "chi2")$cramers_v
  expect_equal(v, (1 * 1 - 1 * 2) / sqrt(2 * 3 * 3 * 2))
  flipped <- suppressMessages(tab2(two, a, b, .chi2 = TRUE, .flip = TRUE))
  expect_equal(attr(flipped, "chi2")$cramers_v, v)
})

test_that("tab2(.chi2 = TRUE) handles weights, totals and degenerate tables", {
  data <- tibble::tibble(a = c(1, 1, 2, 2), b = c("x", "y", "x", "y"))
  w <- c(3, 1, 1, 2)
  weighted <- attr(
    suppressMessages(tab2(data, a, b, .wt = w, .chi2 = TRUE)),
    "chi2"
  )
  replicated <- data[rep(seq_len(nrow(data)), w), ]
  expect_equal(
    weighted,
    attr(suppressMessages(tab2(replicated, a, b, .chi2 = TRUE)), "chi2")
  )
  expect_error(
    tab2(data, a, b, .wt = w, .wt_type = "analytic", .chi2 = TRUE),
    "svychisq"
  )
  totals <- suppressMessages(tab2(data, a, b, .total = TRUE, .chi2 = TRUE))
  expect_equal(attr(totals, "chi2")$df, 1L)
  expect_identical(attr(totals, "chi2")$n, 4L)
  expect_null(attr(tab2(data, a, b), "chi2"))

  constant <- dplyr::mutate(data, b = "x")
  expect_message(
    out <- tab2(constant, a, b, .chi2 = TRUE),
    "not computed"
  )
  expect_true(is.na(attr(out, "chi2")$statistic))
  expect_error(tab2(data, a, b, .chi2 = NA), "must be `TRUE` or `FALSE`")
  skip_if_not_installed("flextable")
  table <- suppressMessages(
    tab2(data, a, b, .total = TRUE, .type = "flextable", .chi2 = TRUE)
  )
  expect_s3_class(table, "flextable")
  plain <- tab2(data, a, b, .total = TRUE, .type = "flextable")
  expect_identical(
    flextable::nrow_part(table, "footer"),
    flextable::nrow_part(plain, "footer") + 2L
  )
})
