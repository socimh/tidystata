library(testthat)
library(statart)
library(tibble)

empty_cases <- list(
  numeric_missing = rep(NA_real_, 3),
  integer_missing = rep(NA_integer_, 3),
  logical_missing = rep(NA, 3),
  zero_rows = numeric()
)
for (case_name in names(empty_cases)) {
  for (detail in c(FALSE, TRUE)) {
    local({
      x <- empty_cases[[case_name]]
      detailed <- detail
      test_that(paste("summary empty observations", case_name, detailed), {
        out <- suppressWarnings(summ(tibble(x = x), .detail = detailed))
        expect_equal(nrow(out), 1L)
        expect_equal(out$n, 0)
        expect_equal(out$unique, 0)
        moments <- intersect(
          names(out),
          c(
            "min",
            "mean",
            "sd",
            "max",
            "q1",
            "median",
            "q3",
            "mad",
            "iqr",
            "skew",
            "kurtosis",
            "se",
            "sum"
          )
        )
        expect_true(all(is.na(unlist(out[moments]))))
        expect_false(any(is.nan(unlist(out[moments]))))
        if (detailed) expect_equal(out$miss_n, length(x))
      })
    })
  }
}

for (alias in c("missing", "p25", "p50", "p75")) {
  local({
    requested <- alias
    test_that(paste("summary alias", requested), {
      x <- c(1, 3, 5, 7, NA)
      expected <- switch(requested, missing = 1, p25 = 2.5, p50 = 4, p75 = 5.5)
      out <- summ(tibble(x = x), .stat = requested)
      expect_named(out, c("name", "type", requested))
      expect_equal(out[[requested]], expected)
    })
  })
}

test_that("summary aliases coexist with canonical names and preserve request order", {
  out <- summ(
    tibble(x = c(1, 3, NA)),
    .stat = c("p50", "median", "missing", "miss_n", "sum")
  )
  expect_named(
    out,
    c("name", "type", "p50", "median", "missing", "miss_n", "sum")
  )
  expect_equal(unlist(out[3:7], use.names = FALSE), c(2, 2, 1, 1, 4))
})

test_that("tabstat supports sum with missing values", {
  out <- tabstat(
    tibble(x = c(-3, 5, NA), y = c(1, 2, 3)),
    .stat = c("sum", "mean")
  )
  expect_equal(out$sum, c(2, 6))
  expect_equal(out$mean, c(1, 2))
})

test_that("sum is missing when there are no observed values", {
  out <- suppressWarnings(tabstat(
    tibble(x = c(NA_real_, NA_real_)),
    .stat = c("n", "sum")
  ))
  expect_equal(out$n, 0)
  expect_identical(out$sum, NA_real_)
})

test_that("grouped summaries retain all-missing groups and missing keys", {
  df <- tibble(g = c("a", "a", "b", NA), x = c(NA_real_, NA_real_, 4, NA_real_))
  out <- suppressWarnings(summ(
    df,
    x,
    .by = g,
    .stat = c("n", "missing", "sum", "p50")
  ))
  expect_equal(nrow(out), 3L)
  expect_equal(out$n, c(0, 1, 0))
  expect_equal(out$missing, c(2, 0, 1))
  expect_equal(out$sum, c(NA, 4, NA))
  expect_true(anyNA(out$g))
})

test_that("zero-row summaries retain one row per numeric column", {
  out <- summ(tibble(x = numeric(), y = integer()))
  expect_equal(out$name, c("x", "y"))
  expect_equal(out$n, c(0, 0))
  expect_true(all(is.na(out$mean)))
})

test_that("zero-row grouped summaries do not invent groups", {
  out <- summ(tibble(g = character(), x = numeric()), x, .by = g)
  expect_equal(nrow(out), 0L)
  expect_true(all(c("g", "name", "n", "mean") %in% names(out)))
})

test_that("summary rejects unknown statistic names clearly", {
  expect_error(
    summ(tibble(x = 1:3), .stat = "variance_typo"),
    "Unsupported statistic"
  )
})

test_that("summary rejects missing statistic names clearly", {
  expect_error(summ(tibble(x = 1:3), .stat = NA_character_), "stat.*character")
})

test_that("date summaries support percentile aliases without numeric epoch output", {
  out <- summ(
    tibble(x = as.Date("2024-01-01") + 0:4),
    .stat = c("p25", "p50", "p75")
  )
  expect_equal(out$p25, "2024-01-02")
  expect_equal(out$p50, "2024-01-03")
  expect_equal(out$p75, "2024-01-04")
})

test_that("empty date summaries retain formatted missing values", {
  out <- summ(tibble(x = as.Date(character())))
  expect_equal(out$n, 0)
  expect_identical(out$mean, NA_character_)
})

test_that("sum on calendar dates is rejected explicitly", {
  expect_error(
    summ(tibble(x = as.Date("2024-01-01") + 0:2), .stat = "sum"),
    "sum.*date"
  )
})

test_that("all-missing numeric summaries preserve input", {
  df <- tibble(x = c(NA_real_, NA_real_))
  before <- df
  suppressWarnings(summ(df, .detail = TRUE))
  expect_identical(df, before)
})


test_that("mixed table summaries retain missing numeric rows alongside dates", {
  df <- tibble(x = c(NA_real_, NA_real_), d = as.Date("2024-01-01") + 0:1)
  out <- suppressWarnings(summ(df, .mode = "table"))
  expect_equal(out$name, c("x", "d"))
  expect_equal(out$n, c(0, 2))
  expect_identical(out$mean, c(NA_character_, "2024-01-01"))
})

test_that("zero-row mixed table summaries keep numeric and date rows", {
  out <- summ(tibble(x = numeric(), d = as.Date(character())), .mode = "table")
  expect_equal(out$name, c("x", "d"))
  expect_equal(out$n, c(0, 0))
  expect_identical(out$min, c(NA_character_, NA_character_))
})

test_that("mixed observed table summaries use compatible formatted statistics", {
  out <- summ(
    tibble(x = c(1, 3), d = as.Date("2024-01-01") + 0:1),
    .mode = "table"
  )
  expect_equal(out$n, c(2, 2))
  expect_identical(out$mean, c("2", "2024-01-01"))
})

test_that("list mode keeps numeric statistics numeric alongside dates", {
  out <- suppressWarnings(summ(tibble(
    x = c(NA_real_, NA_real_),
    d = as.Date("2024-01-01") + 0:1
  )))
  expect_type(out$numeric$mean, "double")
  expect_identical(out$numeric$mean, NA_real_)
  expect_type(out$date$mean, "character")
})
