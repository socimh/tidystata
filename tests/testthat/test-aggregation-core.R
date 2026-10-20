test_that("weighted requests do not evaluate unrequested quantiles", {
  testthat::local_mocked_bindings(
    weighted_quantile = function(...) stop("Unrequested weighted quantile"),
    .package = "statart"
  )
  data <- data.frame(g = c(2, 1, 2, 1), x = c(1, 3, 5, NA), w = c(1, 2, 3, 4))
  expect_equal(summ(data, x, .wt = w, .stat = "mean")$mean, 22 / 6)
  expect_equal(summ(data, x, .wt = w, .stat = "n")$n, 6)
  expect_equal(tabstat(data, x, .by = g, .wt = w)$mean, c(3, 4))
})

test_that("weighted type-only summaries retain one row per variable and group", {
  data <- data.frame(g = c(2, 1, 2), x = 1:3, w = c(1, 0, 2))
  expect_identical(summ(data, x, .wt = w, .stat = "type")$type, "int")
  expect_identical(
    summ(data, x, .by = g, .wt = w, .stat = "type")$type,
    c("int", "int")
  )
})

test_that("frequency cumulative values are isolated within groups", {
  data <- data.frame(
    g = rep(1:3, each = 3),
    x = rep(c(1, 2, NA), 3),
    w = c(0, 0, 0, 1e16, 1, 2, 1, 2, 1)
  )
  out <- tab(data, x, .by = g, .wt = w)
  expect_true(all(is.nan(out$cum[1:3])))
  expect_equal(out$cum[7:9], c(25, 75, 100))
  expect_equal(out$valid_cum[7:8], c(100 / 3, 100))
  expect_true(is.na(out$valid_cum[[9]]))
})

test_that("cross tabulation fills native counts and preserves identity", {
  data <- data.frame(
    a = c("z", "a", "z", "a"),
    b = factor(c("b", "c", "b", "b"), levels = c("c", "b")),
    w = c(0.5, 2, 1, 3)
  )
  out <- xtab(data, a, b, .wt = w)
  expect_named(out, c("a \\ b", "c", "b"))
  expect_identical(out[[1]], c("a", "z"))
  expect_equal(out$c, c(2, 0))
  expect_equal(out$b, c(3, 1.5))
  expect_type(xtab(data, a, b)$b, "integer")
})

test_that("weighted counts skip numeric conversion and preserve row counts", {
  testthat::local_mocked_bindings(
    as_numeric = function(...) stop("Unrequested numeric conversion"),
    .package = "statart"
  )
  data <- data.frame(
    g = c(1, 1, 2, 2),
    x = c(5, NA, 5, 6),
    w = c(0, 3, 0.5, 1.5)
  )
  stats <- c("n", "unique", "miss_n", "valid_pct")
  out <- summ(data, x, .by = g, .wt = w, .stat = stats)
  expect_equal(out$n, c(0, 2))
  expect_identical(out$unique, c(1L, 2L))
  expect_identical(out$miss_n, c(1L, 0L))
  expect_equal(out$valid_pct, c(0.5, 1))
})

test_that("prepared weights stay aligned after missing-key and weight filtering", {
  data <- data.frame(
    g = c(NA, 2, 1, 2, 1),
    x = c(100, 4, 8, 10, 12),
    w = c(99, NA, 0.5, 1.5, 2)
  )
  before <- data
  expect_message(
    out <- summ(
      data,
      x,
      .by = g,
      .na.rm = TRUE,
      .wt = 2 * w,
      .stat = c("n", "mean")
    ),
    "Excluded 1 row"
  )
  expect_equal(out$n, c(5, 3))
  expect_equal(out$mean, c(11.2, 10))
  expect_message(counts <- tab(data, x, .by = g, .wt = w), "Excluded 1 row")
  expect_equal(counts$n, c(0.5, 2, 1.5, 99))
  expect_identical(data, before)
})

test_that("shared summary groups retain calendar and nonnumeric families", {
  data <- tibble::tibble(
    g = c(2, 1, 2),
    x = c(1, 3, 5),
    day = as.Date("2024-01-01") + c(0, 2, 4),
    text = c("a", "b", "a"),
    w = c(1, 2, 3)
  )
  before <- data
  expect_warning(
    out <- suppressMessages(summ(
      data,
      x,
      day,
      text,
      .keep_all = TRUE,
      .by = g,
      .wt = w,
      .stat = c("mean", "unique")
    )),
    "non-numeric"
  )
  expect_equal(out$numeric$mean, c(3, NA, 4, NA))
  expect_identical(out$numeric$unique, c(1L, 1L, 2L, 1L))
  expect_identical(out$date$mean, c("2024-01-03", "2024-01-04"))
  expect_identical(data, before)
})

test_that("excluded custom columns do not evaluate missingness methods", {
  registry <- get(".__S3MethodsTable__.", envir = asNamespace("base"))
  registerS3method(
    "is.na",
    "statart_aggregation_opaque",
    function(x) stop("Excluded missingness evaluated"),
    envir = asNamespace("base")
  )
  withr::defer(rm("is.na.statart_aggregation_opaque", envir = registry))
  data <- tibble::tibble(
    x = 1:3,
    opaque = structure(letters[1:3], class = "statart_aggregation_opaque")
  )
  expect_warning(
    out <- summ(data, .stat = "mean"),
    "opaque is non-numeric and thus removed"
  )
  expect_equal(out$mean, 2)
})

test_that("analytic frequency grouping matches separately scaled groups", {
  data <- data.frame(
    g = c(2, NA, NaN, 2, NA, NaN),
    x = c("a", "b", "a", "b", "a", "b"),
    w = c(0, 0.5, 0, 1.5, 2, 0)
  )
  grouped <- tab(data, x, .by = g, .wt = w, .wt_type = "analytic", .desc = TRUE)
  for (loc in list(c(1L, 4L), c(2L, 5L), c(3L, 6L))) {
    key <- data$g[loc[[1]]]
    rows <- if (is.nan(key)) {
      is.nan(grouped$g)
    } else if (is.na(key)) {
      is.na(grouped$g) & !is.nan(grouped$g)
    } else {
      !is.na(grouped$g) & grouped$g == key
    }
    expected <- tab(
      data[loc, ],
      x,
      .wt = w,
      .wt_type = "analytic",
      .desc = TRUE
    )
    expect_equal(as.list(grouped[rows, names(expected)]), as.list(expected))
  }
})

test_that("weighted percentile preparation preserves ties and zero weights", {
  data <- data.frame(x = c(1, 3, 9, 1000, NA), w = c(0.5, 0.5, 1, 0, 4))
  out <- summ(
    data,
    x,
    .wt = w,
    .stat = c("n", "unique", "q1", "median", "q3", "mad", "p0", "p100")
  )
  expect_equal(out$n, 2)
  expect_identical(out$unique, 4L)
  expect_equal(
    unlist(out[c("q1", "median", "q3")], use.names = FALSE),
    c(2, 6, 9)
  )
  expect_equal(out$mad, 1.4826 * 3)
  expect_equal(out$p0, 1)
  expect_equal(out$p100, 9)
  analytic <- summ(
    data,
    x,
    .wt = w,
    .wt_type = "analytic",
    .stat = c("n", "q1", "median", "q3")
  )
  expect_equal(analytic$n, 4)
  expect_equal(analytic[c("q1", "median", "q3")], out[c("q1", "median", "q3")])
})

test_that("weighted empty and missing inputs retain their established shape", {
  data <- data.frame(g = integer(), x = double(), w = double())
  out <- summ(data, x, .by = g, .wt = w, .stat = c("n", "mean", "median"))
  expect_equal(nrow(out), 0L)
  expect_type(out$n, "double")
  expect_equal(nrow(xtab(data, g, x, .wt = w)), 0L)
  missing <- data.frame(x = c(NA_real_, NA_real_), w = c(0, 2))
  expect_warning(
    out <- summ(missing, x, .wt = w, .stat = c("n", "mean", "sd", "median")),
    "entirely missing"
  )
  expect_equal(out$n, 0)
  expect_true(all(is.na(unlist(out[c("mean", "sd", "median")]))))
})

test_that("matrix column headers retain the pivot boundary diagnostic", {
  data <- tibble::tibble(a = 1:3, b = matrix(1:6, 3))
  expect_error(xtab(data, a, b), "Can't recycle")
})
