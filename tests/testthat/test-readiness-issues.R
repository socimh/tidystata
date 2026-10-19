test_that("calendar summaries distinguish infinite extrema from missing values", {
  day <- as.Date(c(-Inf, 0, Inf, NA), origin = "1970-01-01")
  out <- summ(day, .stat = c("n", "miss_n", "min", "max"))
  expect_identical(out$n, 3L)
  expect_identical(out$miss_n, 1L)
  expect_identical(out$min, "-Inf")
  expect_identical(out$max, "Inf")
  finite <- summ(as.Date(c(0, 1), origin = "1970-01-01"), .stat = "min")
  expect_identical(finite$min, "1970-01-01")
})

test_that("missing replacement arguments have actionable diagnostics", {
  expect_error(na_if_value(4), "Missing `.value`.*na_if_value", fixed = FALSE)
  expect_error(
    na_if_value(.value = 4),
    "Missing `.x`.*na_if_value",
    fixed = FALSE
  )
  expect_identical(na_if_value(c(1, 4, NA), 4), c(1, NA_real_, NA_real_))
})

test_that("mixed calendar tables retain documented shared-column types", {
  input <- tibble::tibble(x = c(1, 3), day = as.Date("2024-01-01") + 0:1)
  out <- summ(input, .mode = "table", .stat = c("n", "mean"))
  expect_identical(out$mean, c("2", "2024-01-01"))
  expect_identical(out$n, c(2L, 2L))
  separate <- summ(input, .mode = "list", .stat = "mean")
  expect_identical(separate$numeric$mean, 2)
  piped <- 1:3 %>% summ(.name = TRUE, .stat = "mean")
  # Magrittr placeholders are named `value` (see test-problems2-low.R).
  expect_identical(piped$name, "value")
  expect_identical(piped$mean, 2)
})
