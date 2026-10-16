library(testthat)
library(statart)

# Independent references for the documented R statistic conventions. Skewness
# and excess kurtosis use central moments standardized by the sample SD.
summary_reference <- function(x) {
  values <- as.numeric(x[!is.na(x)])
  n <- length(values)
  spread <- stats::sd(values)
  c(
    n = n, unique = length(unique(values)), miss_n = sum(is.na(x)),
    valid_pct = n / length(x), min = min(values),
    q1 = unname(stats::quantile(values, 0.25)),
    median = stats::median(values), mean = mean(values),
    mad = stats::mad(values), sd = spread,
    q3 = unname(stats::quantile(values, 0.75)), max = max(values),
    iqr = stats::IQR(values),
    skew = sum((values - mean(values))^3) / (n * spread^3),
    kurtosis = sum((values - mean(values))^4) / (n * spread^4) - 3,
    se = spread / sqrt(n), sum = sum(values)
  )
}

for (function_name in c("summ", "tabstat")) {
  local({
    fn_name <- function_name
    fn <- get(fn_name, envir = asNamespace("statart"))

    test_that(paste(fn_name, "matches independent numerical references"), {
      cases <- list(
        asymmetric = c(-4, 0, 0, 1, 20, NA_real_, NaN),
        large_offset = c(1e12 + 1:10, NA_real_),
        logical = c(TRUE, FALSE, TRUE, NA),
        negative = c(-10, -4, -2, -1, NA_real_)
      )
      for (x in cases) {
        input <- tibble::tibble(x = x)
        before <- input
        expected <- summary_reference(x)
        out <- fn(input, .stat = names(expected))
        expect_equal(
          unlist(out[names(expected)], use.names = FALSE),
          unname(expected), tolerance = 1e-12
        )
        expect_identical(input, before)
      }
    })

    test_that(paste(fn_name, "excludes SPSS discrete user-missing values"), {
      x <- haven::labelled_spss(c(1, 2, 99, NA_real_), na_values = 99)
      input <- tibble::tibble(x = x)
      before <- input
      expected <- summary_reference(c(1, 2, NA_real_, NA_real_))
      out <- suppressWarnings(fn(input, .stat = names(expected)))
      expect_equal(
        unlist(out[names(expected)], use.names = FALSE),
        unname(expected), tolerance = 1e-12
      )
      expect_identical(input, before)
    })

    test_that(paste(fn_name, "excludes SPSS missing ranges"), {
      x <- haven::labelled_spss(
        c(1, 2, 97, 98, 99, NA_real_), na_range = c(97, 99)
      )
      out <- suppressWarnings(fn(
        tibble::tibble(x = x),
        .stat = c("n", "unique", "missing", "valid_pct", "mean", "sum")
      ))
      expect_equal(out$n, 2)
      expect_equal(out$unique, 2)
      expect_equal(out$missing, 4)
      expect_equal(out$valid_pct, 1 / 3)
      expect_equal(out$mean, 1.5)
      expect_equal(out$sum, 3)
    })

    test_that(paste(fn_name, "retains all-user-missing SPSS rows as missing"), {
      x <- haven::labelled_spss(c(99, 99, NA_real_), na_values = 99)
      out <- suppressWarnings(fn(
        tibble::tibble(x = x), .detail = TRUE, .stat = character()
      ))
      expect_equal(out$n, 0)
      expect_equal(out$unique, 0)
      expect_equal(out$miss_n, 3)
      expect_equal(out$valid_pct, 0)
      moments <- setdiff(names(out), c("name", "type", "n", "unique", "miss_n", "valid_pct"))
      values <- unlist(out[moments], use.names = FALSE)
      expect_true(all(is.na(values)))
      expect_false(any(is.nan(values)))
    })

    test_that(paste(fn_name, "uses consistent missing masks within SPSS groups"), {
      input <- tibble::tibble(
        g = c("observed", "observed", "missing", "missing"),
        x = haven::labelled_spss(c(1, 99, 99, NA_real_), na_values = 99)
      )
      out <- suppressWarnings(fn(
        input, x, .by = g,
        .stat = c("n", "unique", "missing", "mean", "sum")
      ))
      expect_equal(out$g, c("observed", "missing"))
      expect_equal(out$n, c(1, 0))
      expect_equal(out$unique, c(1, 0))
      expect_equal(out$missing, c(1, 2))
      expect_equal(out$mean, c(1, NA_real_))
      expect_equal(out$sum, c(1, NA_real_))
    })
  })
}
