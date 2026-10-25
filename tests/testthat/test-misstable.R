missing_data <- tibble::tibble(
  g = c("a", "a", "a", "b", "b"),
  x = c(1, NA, 3, NA, 5),
  y = c("p", NA, NA, "q", "r"),
  z = c(1, 2, 3, 4, 5)
)

test_that("misstable() counts missing values by variable", {
  out <- misstable(missing_data)
  expect_named(out, c("variable", "miss_n", "miss_pct", "valid_n"))
  expect_identical(out$variable, c("x", "y"))
  expect_identical(out$miss_n, c(2L, 2L))
  expect_equal(out$miss_pct, c(40, 40))
  expect_identical(out$valid_n, c(3L, 3L))

  all <- misstable(missing_data, .all = TRUE)
  expect_identical(all$variable, c("g", "x", "y", "z"))
  expect_identical(all$miss_n, c(0L, 2L, 2L, 0L))

  expect_message(
    none <- misstable(missing_data, z),
    "No missing values"
  )
  expect_identical(nrow(none), 0L)
  expect_named(none, names(out))
})

test_that("misstable() counts by group", {
  out <- misstable(missing_data, x, y, .by = g)
  expect_named(out, c("g", "variable", "miss_n", "miss_pct", "valid_n"))
  expect_identical(out$g, c("a", "a", "b", "b"))
  expect_identical(out$miss_n, c(1L, 2L, 1L, 0L))
  expect_equal(out$miss_pct, c(100 / 3, 200 / 3, 50, 0))
  expect_identical(
    misstable(dplyr::group_by(missing_data, g), x, y),
    out
  )
  # Grouping keys are not checked as variables.
  expect_false("g" %in% misstable(missing_data, .by = g, .all = TRUE)$variable)
})

test_that("misstable(.patterns = TRUE) tabulates missing patterns", {
  out <- misstable(missing_data, .patterns = TRUE)
  expect_named(out, c("x", "y", "n", "percent"))
  # Stata's convention: 1 = observed, 0 = missing; most frequent first.
  expect_identical(out$x, c(1L, 1L, 0L, 0L))
  expect_identical(out$y, c(1L, 0L, 1L, 0L))
  expect_identical(out$n, c(2L, 1L, 1L, 1L))
  expect_equal(out$percent, c(40, 20, 20, 20))
  expect_equal(sum(out$n), nrow(missing_data))

  grouped <- misstable(missing_data, x, y, .by = g, .patterns = TRUE)
  expect_named(grouped, c("g", "x", "y", "n", "percent"))
  expect_equal(sum(grouped$percent[grouped$g == "b"]), 100)

  complete <- suppressMessages(misstable(missing_data, z, .patterns = TRUE))
  expect_named(complete, c("n", "percent"))
  expect_identical(complete$n, 5L)
  all <- misstable(missing_data, z, .patterns = TRUE, .all = TRUE)
  expect_identical(all$z, 1L)

  clash <- tibble::tibble(n = c(1, NA))
  expect_error(misstable(clash, .patterns = TRUE), "rename it first")
})

test_that("misstable() handles special missing values and empty data", {
  data <- tibble::tibble(
    nan = c(NaN, 1),
    tagged = c(haven::tagged_na("a"), 1),
    blank = c("", "a"),
    list = list(NULL, NA)
  )
  out <- misstable(data, .all = TRUE)
  expect_identical(out$miss_n, c(1L, 1L, 0L, 1L))
  expect_identical(
    misstable(tibble::tibble(l = list(NULL, 1)), .all = TRUE)$miss_n,
    0L
  )

  empty <- misstable(missing_data[0, ], x, .all = TRUE)
  expect_identical(empty$miss_n, 0L)
  expect_true(is.na(empty$miss_pct))
  expect_identical(
    nrow(misstable(missing_data[0, ], x, .patterns = TRUE, .all = TRUE)),
    0L
  )
  expect_error(misstable(1:3), "must be a data frame")
  expect_error(
    misstable(missing_data, .all = "yes"),
    "must be `TRUE` or `FALSE`"
  )
})

test_that("misstable() reports invalid input", {
  expect_snapshot(error = TRUE, {
    misstable(1:3)
    misstable(tibble::tibble(x = NA), .all = "yes")
    misstable(tibble::tibble(n = c(1, NA)), .patterns = TRUE)
  })
})

test_that("misstable() counts SPSS user-missing codes and ranges", {
  data <- tibble::tibble(
    g = c("a", "a", "b", "b"),
    coded = haven::labelled_spss(c(1, 99, NA, 2), na_values = 99),
    ranged = haven::labelled_spss(c(97, 1, 2, 98), na_range = c(90, 100))
  )
  out <- misstable(data, coded, ranged)
  expect_identical(out$miss_n, c(2L, 2L))
  expect_identical(out$valid_n, c(2L, 2L))

  grouped <- misstable(data, coded, ranged, .by = g)
  expect_identical(grouped$miss_n, c(1L, 1L, 1L, 1L))

  patterns <- misstable(data, coded, ranged, .patterns = TRUE)
  expect_identical(sum(patterns$n), 4L)
  expect_identical(nrow(patterns), 2L)
})

test_that("misstable() rejects grouping names that collide with result columns", {
  data <- tibble::tibble(variable = c("a", "a"), n = c("a", "a"), x = c(1, NA))
  expect_error(misstable(data, x, .by = variable), "rename it first")
  expect_error(misstable(data, x, .by = n, .patterns = TRUE), "rename it first")
  expect_named(
    misstable(data, x, .by = n),
    c("n", "variable", "miss_n", "miss_pct", "valid_n")
  )
})
