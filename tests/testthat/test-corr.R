test_that("corr() uses one complete-case sample for every pair", {
  data <- tibble::tibble(
    x = c(1, 2, 3, 4, 5),
    y = c(2, 4, 1, 8, NA),
    z = c(5, NA, 3, 2, 1)
  )
  out <- corr(data, x, y, z)
  expect_named(out, c("var1", "var2", "r", "n"))
  expect_identical(out$var1, c("x", "x", "y"))
  expect_identical(out$var2, c("y", "z", "z"))
  expect_identical(out$n, rep(3L, 3))
  expected <- stats::cor(as.matrix(data[c(1, 3, 4), ]))
  expect_equal(out$r, expected[upper.tri(expected)])
  expect_identical(pwcorr(data)$n, c(4L, 4L, 3L))
  expect_equal(corr(data, x, y)$r, pwcorr(data, x, y)$r)
  expect_identical(data$y, c(2, 4, 1, 8, NA))
})

test_that("corr() supports selectors, computed columns and group overrides", {
  data <- tibble::tibble(
    g = c("a", "a", "a", "b", "b", "b"),
    h = rep("all", 6),
    x = c(1, 2, 3, 4, 5, 6),
    y = c(2, NA, 4, 8, 5, 9),
    z = c(1, 3, 2, NA, 6, 4)
  )
  before <- data
  out <- corr(data, x, y, z, .by = g)
  expect_identical(out$n, rep(2L, 6))
  expect_identical(out$g, rep(c("a", "b"), each = 3))
  expect_equal(corr(dplyr::group_by(data, g), x, y, z), out)
  expect_equal(
    corr(dplyr::group_by(data, h), x, y, z, .by = g),
    out
  )
  expected <- dplyr::mutate(data, scaled = z / 10)
  expect_equal(
    corr(data, x, scaled = z / 10, .by = g),
    corr(expected, x, scaled, .by = g)
  )
  expect_equal(corr(data, dplyr::all_of(c("x", "y", "z"))), corr(data, x, y, z))
  expect_identical(data, before)
  expect_error(corr(data, x, y, .by = x > 1), "must select existing columns")
})

test_that("corr() converts labelled missing values before listwise deletion", {
  data <- tibble::tibble(
    x = 1:5,
    y = haven::labelled_spss(c(1, 99, 4, 3, 5), na_values = 99),
    z = c(5, 4, haven::tagged_na("a"), 2, 1)
  )
  out <- corr(data)
  expect_identical(out$n, rep(3L, 3))
  expected <- stats::cor(cbind(c(1, 4, 5), c(1, 3, 5), c(5, 2, 1)))
  expect_equal(out$r, expected[upper.tri(expected)])
})

test_that("corr() weights use the same complete sample for every pair", {
  data <- tibble::tibble(
    x = c(1, 2, 3, 4, 1e200),
    y = c(2, 4, NA, 3, 1e200),
    z = c(4, 2, 3, 1, 1e200),
    w = c(2, 1, 3, 2, 0)
  )
  replicated <- data[rep(c(1L, 2L, 4L), c(2, 1, 2)), ]
  out <- corr(data, x, y, z, .wt = w)
  expected <- stats::cor(as.matrix(replicated[c("x", "y", "z")]))
  expect_equal(out$r, expected[upper.tri(expected)])
  expect_equal(out$n, rep(5, 3))
  analytic <- corr(data, x, y, z, .wt = w, .wt_type = "analytic")
  expect_equal(analytic$r, out$r)
  expect_identical(analytic$n, rep(3L, 3))
  expect_equal(corr(data, .wt = w), out)
  expect_error(corr(data, x, y, .wt = -1), "must not be negative")
})

test_that("corr() wide, empty, constant and invalid inputs have stable contracts", {
  data <- tibble::tibble(x = c(1, 2, NA), y = c(3, 2, 1), z = c(5, NA, 1))
  wide <- corr(data, x, y, .wide = TRUE)
  expect_named(wide, c("variable", "x", "y"))
  expect_identical(wide$variable, c("x", "y"))
  expect_equal(wide$x, c(1, -1))
  expect_equal(wide$y, c(NA, 1))
  expect_true(all(is.na(corr(data)$r)))
  expect_identical(corr(data)$n, rep(1L, 3))
  none <- tibble::tibble(x = c(1, NA), y = c(NA, 2))
  expect_true(is.na(corr(none)$r))
  expect_identical(corr(none)$n, 0L)
  expect_named(corr(none[0, ]), c("var1", "var2", "r", "n"))
  grouped <- dplyr::group_by(
    tibble::tibble(g = character(), x = double(), y = double()),
    g
  )
  expect_equal(nrow(corr(grouped)), 0L)
  expect_named(corr(grouped), c("g", "var1", "var2", "r", "n"))
  constant <- tibble::tibble(x = 1:3, y = rep(1, 3))
  expect_true(is.na(corr(constant)$r))
  expect_error(corr(data, x), "at least two numeric variables")
  expect_error(corr(data, nonexistent), "don't exist")
  expect_error(corr(data, x, y, .wide = NA), "must be `TRUE` or `FALSE`")
  expect_error(corr(1:3), "must be a data frame")
  p_group <- tibble::tibble(p = "a", x = 1:3, y = c(3, 1, 2))
  expect_named(corr(p_group, x, y, .by = p), c("p", "var1", "var2", "r", "n"))
})

test_that("findit() maps Stata corr to complete-case correlations", {
  out <- findit(corr)
  expect_identical(out$package[[1L]], "tidystata")
  expect_identical(out$r[[1L]], "corr(data, x1, x2, x3)")
  expect_identical(
    findit(corr, income, spending)$r[[1L]],
    "corr(data, income, spending)"
  )
})
