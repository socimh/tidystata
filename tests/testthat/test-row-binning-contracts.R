# Focused behavior contracts before row/binning style adoption.
# Numeric references use base R, with the documented all-missing exceptions.

row_contract_functions <- c(
  "row_mean",
  "row_sum",
  "row_min",
  "row_max",
  "row_median",
  "row_var",
  "row_sd",
  "row_unique",
  "row_miss",
  "row_non_miss"
)
row_contract_reference <- function(data, operation) {
  vapply(
    seq_len(nrow(data)),
    function(i) {
      values <- unlist(data[i, ], use.names = FALSE)
      observed <- values[!is.na(values)]
      switch(
        operation,
        row_mean = if (length(observed)) mean(observed) else NA_real_,
        row_sum = sum(observed),
        row_min = if (length(observed)) min(observed) else NA_real_,
        row_max = if (length(observed)) max(observed) else NA_real_,
        row_median = if (length(observed)) {
          stats::median(observed)
        } else {
          NA_real_
        },
        row_var = if (length(observed) > 1L) stats::var(observed) else NA_real_,
        row_sd = if (length(observed) > 1L) stats::sd(observed) else NA_real_,
        row_unique = length(unique(observed)) + as.integer(anyNA(values)),
        row_miss = sum(is.na(values)),
        row_non_miss = length(observed)
      )
    },
    numeric(1)
  )
}

test_that("row contracts: numeric backends agree with independent row references", {
  data <- tibble::tibble(
    a = c(1, NA, NA, -3, NaN),
    b = c(3, NA, 4, 0, 2),
    c = c(5, NaN, NA, 3, 2)
  )
  before <- serialize(data, NULL)
  for (name in row_contract_functions) {
    out <- get(name, mode = "function")(data)
    expect_true(is.atomic(out), info = name)
    expect_length(out, nrow(data))
    expect_equal(out, row_contract_reference(data, name), info = name)
  }
  expect_identical(serialize(data, NULL), before)
})

test_that("row contracts: typed zero-row inputs return plain empty vectors", {
  data <- tibble::tibble(a = numeric(), b = integer())
  for (name in row_contract_functions) {
    out <- get(name, mode = "function")(data)
    expect_true(is.atomic(out), info = name)
    expect_length(out, 0)
    expect_null(dim(out))
  }
})

test_that("row contracts: a single observed column has undefined sample variance", {
  data <- tibble::tibble(a = c(1, NA, 5))
  expect_equal(row_var(data), rep(NA_real_, 3))
  expect_equal(row_sd(data), rep(NA_real_, 3))
  expect_equal(row_sum(data), c(1, 0, 5))
  expect_equal(row_mean(data), c(1, NA_real_, 5))
})

test_that("row contracts: logical and integer inputs remain unmodified", {
  data <- tibble::tibble(
    a = structure(c(1L, 2L, NA_integer_), label = "First item"),
    b = c(TRUE, FALSE, NA)
  )
  before <- serialize(data, NULL)
  expect_equal(row_sum(data), c(2, 2, 0))
  expect_equal(row_var(data), c(0, 2, NA_real_))
  expect_identical(serialize(data, NULL), before)
})

test_that("row contracts: explicit pick and bare selectors agree in mutate", {
  data <- tibble::tibble(a = c(1, NA, 3), b = c(3, NA, 5), id = 1:3)
  for (name in row_contract_functions) {
    fn <- get(name, mode = "function")
    out <- dplyr::mutate(
      data,
      bare = fn(a, b),
      explicit = fn(dplyr::pick(a, b))
    )
    expect_equal(out$bare, row_contract_reference(data[c("a", "b")], name))
    expect_identical(out$explicit, out$bare)
  }
})

test_that("row contracts: grouped mutate preserves grouping and row order", {
  data <- dplyr::group_by(
    tibble::tibble(g = c("b", "a", "b"), a = c(1, NA, 3), b = c(3, 5, 5)),
    g
  )
  out <- dplyr::mutate(data, total = row_sum(a, b), variance = row_var(a, b))
  expect_identical(dplyr::group_vars(out), "g")
  expect_identical(out$g, data$g)
  expect_equal(out$total, c(4, 5, 8))
  expect_equal(out$variance, c(2, NA_real_, 2))
})

test_that("row contracts: an accepted data-frame expression runs once", {
  calls <- new.env(parent = emptyenv())
  calls$n <- 0L
  data <- tibble::tibble(a = c(1, NA), b = c(3, 5))
  out <- dplyr::mutate(
    data,
    total = row_sum({
      calls$n <- calls$n + 1L
      tibble::tibble(a = a, b = b)
    })
  )
  expect_identical(calls$n, 1L)
  expect_equal(out$total, c(4, 5))
})

test_that("row contracts: accepted data-frame warnings are replayed once", {
  calls <- new.env(parent = emptyenv())
  calls$n <- 0L
  warnings <- character()
  selected <- tibble::tibble(a = c(1, NA), b = c(3, 5))
  make_data <- function() {
    calls$n <- calls$n + 1L
    warning("intentional row input warning", call. = FALSE)
    selected
  }
  out <- withCallingHandlers(
    dplyr::mutate(selected, total = row_sum(make_data())),
    warning = function(condition) {
      warnings <<- c(warnings, conditionMessage(condition))
      invokeRestart("muffleWarning")
    }
  )
  expect_identical(calls$n, 1L)
  expect_length(warnings, 1)
  expect_match(warnings, "intentional row input warning")
  expect_equal(out$total, c(4, 5))
})

test_that("row contracts: counts accept nonnumeric columns and return integers", {
  data <- tibble::tibble(
    text = c("", NA, "x"),
    category = factor(c(NA, "a", "a")),
    nested = list(NULL, NA, 1:2)
  )
  expect_identical(row_miss(data), c(1L, 2L, 0L))
  expect_identical(row_non_miss(data), c(2L, 1L, 3L))
})

test_that("row contracts: arithmetic helpers reject character columns clearly", {
  data <- tibble::tibble(a = c("1", "2"))
  for (name in c("row_sum", "row_mean", "row_median", "row_var", "row_sd")) {
    expect_error(get(name, mode = "function")(data), "numeric or logical")
  }
})

test_that("binning contracts: quantile codes use type-7 boundaries", {
  x <- c(10, 0, 4, 1, 7, NA, 2, 9)
  breaks <- stats::quantile(x, c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE, type = 7)
  expected <- cut(x, breaks, include.lowest = TRUE, ordered_result = TRUE)
  expect_identical(cut_quantile(x), expected)
  expect_identical(cut_quantile(x, labels = FALSE), as.integer(expected))
})

test_that("binning contracts: collapsed quantile boundaries preserve all ties", {
  x <- c(rep(1, 4), rep(2, 4), NA)
  expect_warning(
    out <- cut_quantile(x, n = 4, labels = FALSE),
    "collapsed quantile cutpoints to 2 groups"
  )
  expect_identical(out, c(rep(1L, 4), rep(2L, 4), NA_integer_))
  expect_warning(
    labelled <- cut_quantile(x, n = 4, labels = c("Low", "High")),
    "collapsed quantile cutpoints to 2 groups"
  )
  expect_identical(levels(labelled), c("Low", "High"))
})

test_that("binning contracts: quantile permutation preserves value assignments", {
  x <- c(0, 1, 1, 2, 3, 5, 8, 13, NA)
  order <- c(9, 4, 7, 1, 3, 6, 2, 8, 5)
  expect_identical(
    cut_quantile(x[order], labels = FALSE),
    cut_quantile(x, labels = FALSE)[order]
  )
})

test_that("binning contracts: equal-width edges use right-closed intervals", {
  x <- c(0, 1, 2, 3, 4, 5, 6, 7, 8, NA)
  expect_identical(
    cut_length(x, n = 4, labels = FALSE),
    c(1L, 1L, 1L, 2L, 2L, 3L, 3L, 4L, 4L, NA_integer_)
  )
  expect_identical(
    levels(cut_length(x, n = 4)),
    c("[0,2]", "(2,4]", "(4,6]", "(6,8]")
  )
})

test_that("binning contracts: explicit boundaries respect either closure", {
  x <- c(0, 2, 4, 6, 8, NA)
  expect_identical(
    cut_breaks(x, breaks = c(2, 4, 6), labels = FALSE),
    c(1L, 1L, 2L, 3L, 4L, NA_integer_)
  )
  expect_identical(
    cut_breaks(x, breaks = c(2, 4, 6), labels = FALSE, right = FALSE),
    c(1L, 2L, 3L, 4L, 4L, NA_integer_)
  )
})

test_that("binning contracts: supplied breaks sort and deduplicate with endpoints", {
  x <- c(0, 2, 4, 8, NA)
  expect_identical(
    cut_breaks(x, breaks = c(6, 2, 2, 8), labels = FALSE),
    c(1L, 1L, 2L, 3L, NA_integer_)
  )
})

test_that("binning contracts: defaults and custom labels preserve ordering", {
  x <- c(0, 2, 4, 6, NA)
  expected <- ordered(
    c("Low", "Low", "High", "High", NA),
    levels = c("Low", "High")
  )
  expect_identical(cut_breaks(x, labels = c("Low", "High")), expected)
  expect_identical(cut_length(x, n = 2, labels = c("Low", "High")), expected)
})

test_that("binning contracts: binning does not mutate source values or labels", {
  x <- structure(c(0, 2, 4, 6, NA), label = "Income")
  before <- serialize(x, NULL)
  cut_quantile(x, n = 2)
  cut_length(x, n = 2)
  cut_breaks(x, breaks = 3)
  expect_identical(serialize(x, NULL), before)
})
