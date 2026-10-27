# Extrema select values: logical inputs must not become numeric indicators.
test_that("row extrema preserve logical values and typed missingness", {
  data <- tibble::tibble(
    a = c(TRUE, FALSE, NA, NA, TRUE, FALSE),
    b = c(FALSE, FALSE, TRUE, NA, NA, NA)
  )
  before <- serialize(data, NULL)
  expect_identical(row_max(data), c(TRUE, FALSE, TRUE, NA, TRUE, FALSE))
  expect_identical(row_min(data), c(FALSE, FALSE, TRUE, NA, TRUE, FALSE))
  expect_identical(serialize(data, NULL), before)
})

test_that("row logical extrema preserve empty and single-column types", {
  expect_identical(row_max(tibble::tibble(a = logical())), logical())
  expect_identical(row_min(tibble::tibble(a = logical())), logical())
  data <- tibble::tibble(a = c(TRUE, FALSE, NA))
  expect_identical(row_max(data), data$a)
  expect_identical(row_min(data), data$a)
})

test_that("row logical extrema work with explicit and bare grouped selectors", {
  data <- tibble::tibble(
    g = c("b", "a", "b"),
    a = c(TRUE, NA, FALSE),
    b = c(FALSE, NA, FALSE)
  )
  result <- dplyr::mutate(
    dplyr::group_by(data, g),
    any = row_max(a, b),
    all = row_min(dplyr::pick(a, b))
  )
  expect_identical(result$any, c(TRUE, NA, FALSE))
  expect_identical(result$all, c(FALSE, NA, FALSE))
  expect_identical(dplyr::group_vars(result), "g")
})

test_that("logical arithmetic and counts retain operation-specific results", {
  data <- tibble::tibble(a = c(TRUE, NA, FALSE), b = c(FALSE, NA, FALSE))
  expect_identical(row_sum(data), c(1, 0, 0))
  expect_identical(row_mean(data), c(0.5, NA_real_, 0))
  expect_identical(row_median(data), c(0.5, NA_real_, 0))
  expect_identical(row_var(data), c(0.5, NA_real_, 0))
  expect_identical(row_sd(data), c(sqrt(0.5), NA_real_, 0))
  expect_identical(row_unique(data), c(2L, 1L, 1L))
  expect_identical(row_miss(data), c(0L, 2L, 0L))
  expect_identical(row_non_miss(data), c(2L, 0L, 2L))
})

test_that("row extrema use the common logical integer double type", {
  integers <- tibble::tibble(a = c(1L, NA_integer_), b = c(2L, NA_integer_))
  expect_identical(row_max(integers), c(2L, NA_integer_))
  expect_identical(row_min(integers), c(1L, NA_integer_))
  expect_identical(row_max(tibble::tibble(a = TRUE, b = 2L)), 2L)
  expect_identical(row_min(tibble::tibble(a = FALSE, b = 2)), 0)
  expect_identical(row_max(integers[FALSE, ]), integer())
  expect_identical(
    row_sum(tibble::tibble(a = .Machine$integer.max, b = 1L)),
    2147483648
  )
})

test_that("calendar extrema mean and median preserve their class", {
  dates <- tibble::tibble(
    a = as.Date(c("2020-01-01", NA, NA)),
    b = as.Date(c("2020-01-03", "2020-01-05", NA))
  )
  expect_identical(row_min(dates), as.Date(c("2020-01-01", "2020-01-05", NA)))
  expect_identical(row_max(dates), dates$b)
  expected <- as.Date(c("2020-01-02", "2020-01-05", NA))
  expect_identical(row_mean(dates), expected)
  expect_identical(row_median(dates), expected)
  expect_identical(row_max(dates[FALSE, ]), as.Date(character()))
  expect_error(row_sum(dates), "calendar|Date")
  expect_error(row_sd(dates), "calendar|Date")
  expect_error(row_var(dates), "calendar|Date")
})

test_that("datetime extrema preserve timezone and missingness", {
  a <- as.POSIXct(c("2020-01-01 12:00:00", NA), tz = "UTC")
  b <- a + c(7200, NA)
  data <- tibble::tibble(a = a, b = b)
  expect_identical(row_max(data), b)
  expect_identical(row_min(data), a)
  expect_identical(row_mean(data), a + c(3600, NA))
  expect_identical(row_median(data), a + c(3600, NA))
  expect_identical(row_min(data[FALSE, ]), a[FALSE])
  expect_error(row_sum(data), "calendar|POSIXct")
})

test_that("duration calculations normalize units before aggregating", {
  data <- tibble::tibble(
    a = as.difftime(c(1, NA, NA), units = "hours"),
    b = as.difftime(c(60, 30, NA), units = "mins")
  )
  expect_equal(row_min(data), as.difftime(c(3600, 1800, NA), units = "secs"))
  expect_equal(row_max(data), as.difftime(c(3600, 1800, NA), units = "secs"))
  expect_identical(row_sum(data), as.difftime(c(7200, 1800, 0), units = "secs"))
  expect_identical(
    row_mean(data),
    as.difftime(c(3600, 1800, NA), units = "secs")
  )
  expect_identical(
    row_median(data),
    as.difftime(c(3600, 1800, NA), units = "secs")
  )
  expect_identical(row_sd(data), as.difftime(c(0, NA, NA), units = "secs"))
  expect_error(row_var(data), "squared|duration")
})

test_that("unit-aware calculations retain compatible physical dimensions", {
  skip_if_not_installed("units")
  data <- tibble::tibble(
    a = units::set_units(c(1, NA, NA), "m"),
    b = units::set_units(c(100, 200, NA), "cm")
  )
  before <- serialize(data, NULL)
  expect_equal(row_max(data), units::set_units(c(1, 2, NA), "m"))
  expect_equal(row_min(data), units::set_units(c(1, 2, NA), "m"))
  expect_equal(row_sum(data), units::set_units(c(2, 2, 0), "m"))
  expect_equal(row_mean(data), units::set_units(c(1, 2, NA), "m"))
  expect_equal(row_median(data), units::set_units(c(1, 2, NA), "m"))
  expect_equal(row_sd(data), units::set_units(c(0, NA, NA), "m"))
  expect_equal(row_var(data), units::set_units(c(0, NA, NA), "m^2"))
  expect_identical(row_unique(data), c(1L, 2L, 1L))
  expect_identical(serialize(data, NULL), before)
  incompatible <- tibble::tibble(
    a = data$a,
    b = units::set_units(c(1, 2, NA), "s")
  )
  expect_error(row_max(incompatible), "convert|compatible|units")
  expect_error(row_sum(incompatible), "convert|compatible|units")
  expect_error(
    row_sum(tibble::tibble(a = data$a, b = c(1, 2, 3))),
    "compatible|supported|columns"
  )
})

test_that("integer64 extrema and unique counts never round adjacent large integers", {
  skip_if_not_installed("bit64")
  a <- bit64::as.integer64(c("9007199254740992", "9007199254740993", NA))
  b <- bit64::as.integer64(c("9007199254740993", "9007199254740992", NA))
  data <- tibble::tibble(a = a, b = b)
  expect_identical(
    row_max(data),
    bit64::as.integer64(c("9007199254740993", "9007199254740993", NA))
  )
  expect_identical(
    row_min(data),
    bit64::as.integer64(c("9007199254740992", "9007199254740992", NA))
  )
  expect_identical(row_unique(data), c(2L, 2L, 1L))
  expect_identical(row_miss(data), c(0L, 0L, 2L))
  expect_identical(row_max(data[FALSE, ]), bit64::integer64())
  for (fn in list(row_sum, row_mean, row_median, row_var, row_sd)) {
    expect_error(fn(data), "integer64|explicit")
  }
})

test_that("ordered extrema retain levels while unordered arithmetic is rejected", {
  a <- ordered(c("low", NA, NA), levels = c("low", "medium", "high"))
  b <- ordered(c("high", "medium", NA), levels = levels(a))
  data <- tibble::tibble(a = a, b = b)
  expect_identical(row_max(data), b)
  expect_identical(
    row_min(data),
    ordered(c("low", "medium", NA), levels = levels(a))
  )
  expect_identical(row_max(data[FALSE, ]), a[FALSE])
  expect_identical(row_unique(data), c(2L, 2L, 1L))
  expect_error(
    row_max(tibble::tibble(a = factor("low"))),
    "ordered|unordered|factor"
  )
  expect_error(row_sum(data), "numeric|logical|supported")
  expect_error(
    row_max(tibble::tibble(a = a, b = ordered(b, levels = rev(levels(b))))),
    "compatible|combine|ordered"
  )
})

test_that("ordered factor extrema reject loss of their level ordering", {
  data <- tibble::tibble(
    a = ordered("high", levels = c("low", "high")),
    b = "low"
  )
  expect_error(row_max(data), "ordered|compatible")
  expect_error(row_min(data), "ordered|compatible")
})

test_that("character extrema use explicit lexical ordering without parsing", {
  data <- tibble::tibble(a = c("10", NA, NA), b = c("2", "a", NA))
  expect_identical(row_max(data), c("2", "a", NA_character_))
  expect_identical(row_min(data), c("10", "a", NA_character_))
  expect_identical(row_unique(data), c(2L, 2L, 1L))
  expect_identical(row_max(data[FALSE, ]), character())
  expect_error(row_mean(data), "numeric|logical|supported")
  expect_error(
    row_max(tibble::tibble(a = "1", b = 2)),
    "compatible|combine|columns"
  )
})

test_that("SPSS missing codes are excluded before any row calculation", {
  a <- haven::labelled_spss(c(1, 99, NA, 2), c(yes = 1), na_values = 99)
  b <- haven::labelled_spss(c(2, 99, NA, 99), c(yes = 1), na_values = 99)
  data <- tibble::tibble(a = a, b = b)
  before <- serialize(data, NULL)
  expect_identical(row_sum(data), c(3, 0, 0, 2))
  expect_identical(row_mean(data), c(1.5, NA, NA, 2))
  expect_identical(row_median(data), c(1.5, NA, NA, 2))
  expect_identical(row_var(data), c(0.5, NA, NA, NA))
  expect_identical(row_miss(data), c(0L, 2L, 2L, 1L))
  expect_identical(row_non_miss(data), c(2L, 0L, 0L, 1L))
  expect_identical(row_unique(data), c(2L, 1L, 1L, 2L))
  expected <- haven::labelled_spss(c(2, NA, NA, 2), c(yes = 1), na_values = 99)
  expect_identical(row_max(data), expected)
  expect_identical(serialize(data, NULL), before)
})

test_that("list and complex columns support counts without numeric reinterpretation", {
  data <- tibble::tibble(a = list(1:2, NA, NULL), b = list(1:2, NaN, numeric()))
  expect_identical(row_unique(data), c(1L, 1L, 2L))
  expect_identical(row_miss(data), c(0L, 2L, 0L))
  expect_identical(row_non_miss(data), c(2L, 0L, 2L))
  complex <- tibble::tibble(a = c(1 + 2i, NA_complex_), b = c(1 + 2i, 1 + 3i))
  expect_identical(row_unique(complex), c(1L, 2L))
  expect_identical(row_miss(complex), c(0L, 1L))
  expect_error(row_max(data), "supported|ordered|columns")
  expect_error(row_max(complex), "supported|ordered|columns")
  expect_error(row_sum(complex), "numeric|logical|supported")
})

test_that("row calculations reject structured columns instead of flattening cells", {
  data <- tibble::tibble(a = matrix(1:4, nrow = 2))
  for (fn in list(
    row_min,
    row_max,
    row_sum,
    row_mean,
    row_median,
    row_var,
    row_sd,
    row_unique,
    row_miss,
    row_non_miss
  )) {
    expect_error(fn(data), "one-dimensional|columns")
  }
})

test_that("common SPSS metadata cannot turn an observed value into missing", {
  data <- tibble::tibble(
    a = c(99, 1),
    b = haven::labelled_spss(c(2, 2), na_values = 99)
  )
  expect_error(row_max(data), "incompatible.*missing|missing.*definitions")
  expect_error(row_min(data), "incompatible.*missing|missing.*definitions")
  expect_error(row_unique(data), "incompatible.*missing|missing.*definitions")
  expect_identical(row_sum(data), c(101, 3))
  expect_identical(row_miss(data), c(0L, 0L))
})

test_that("numeric medians do not overflow when the true midpoint is finite", {
  x <- .Machine$double.xmax
  data <- tibble::tibble(a = c(x, -x, x, NA), b = c(x, -x, -x, NA))
  expect_identical(row_median(data), c(x, -x, 0, NA_real_))
})

test_that("sample dispersion is stable for large offsets and magnitudes", {
  data <- tibble::tibble(
    a = c(1e12, 1e200, -1e200),
    b = c(1e12 + 1, 1e200, 1e200)
  )
  expect_equal(row_var(data), c(0.5, 0, Inf))
  expect_equal(row_sd(data), c(sqrt(0.5), 0, sqrt(2) * 1e200))
  expect_identical(row_var(tibble::tibble(a = Inf, b = 1)), NaN)
})

test_that("affine units cannot disguise sums or dispersion as absolute scales", {
  skip_if_not_installed("units")
  data <- tibble::tibble(
    a = units::set_units(c(0, 10), "degC"),
    b = units::set_units(c(0, 20), "degC")
  )
  expect_equal(row_mean(data), units::set_units(c(0, 15), "degC"))
  expect_equal(row_median(data), units::set_units(c(0, 15), "degC"))
  for (fn in list(row_sum, row_sd, row_var)) {
    expect_error(fn(data), "offset|zero.origin|affine")
  }
  db <- tibble::tibble(
    a = units::set_units(0, "dB"),
    b = units::set_units(10, "dB")
  )
  expect_error(row_mean(db), "nonlinear|linear|scale")
})

test_that("compiled row statistics agree with independent base references", {
  withr::local_preserve_seed()
  set.seed(8102)
  for (offset in c(0, 1e12)) {
    data <- as.data.frame(matrix(rnorm(350) + offset, nrow = 50))
    data[seq(1, 50, 3), 2] <- NA_real_
    data[1, ] <- NA_real_
    data[2, -1] <- NA_real_
    before <- serialize(data, NULL)
    reference <- function(fn) {
      vapply(
        seq_len(nrow(data)),
        function(i) {
          values <- unlist(data[i, ], use.names = FALSE)
          if (all(is.na(values))) NA_real_ else fn(values, na.rm = TRUE)
        },
        numeric(1)
      )
    }
    expect_equal(row_median(data), reference(stats::median), tolerance = 1e-12)
    # Translate before the independent reference so rounding its large mean
    # does not obscure the variance of the represented input values.
    expect_equal(
      row_var(data),
      reference(function(x, na.rm) {
        stats::var(x - offset, na.rm = na.rm)
      }),
      tolerance = 1e-12
    )
    expect_equal(
      row_sd(data),
      reference(function(x, na.rm) {
        stats::sd(x - offset, na.rm = na.rm)
      }),
      tolerance = 1e-12
    )
    expect_identical(serialize(data, NULL), before)
  }
})

test_that("row type follows selected prototypes rather than observed values", {
  cases <- list(
    logical = list(x = c(TRUE, NA), missing = NA, empty = logical()),
    integer = list(
      x = c(1L, NA_integer_),
      missing = NA_integer_,
      empty = integer()
    ),
    double = list(x = c(1, NA_real_), missing = NA_real_, empty = numeric()),
    character = list(
      x = c("a", NA_character_),
      missing = NA_character_,
      empty = character()
    ),
    date = list(
      x = as.Date(c("2020-01-01", NA)),
      missing = as.Date(NA),
      empty = as.Date(character())
    ),
    ordered = list(
      x = ordered(c("a", NA)),
      missing = ordered(NA_character_, levels = "a"),
      empty = ordered(character(), levels = "a")
    )
  )
  for (case in cases) {
    data <- tibble::tibble(a = case$x, b = case$x)
    for (fn in list(row_min, row_max)) {
      expect_identical(fn(data), case$x)
      expect_identical(fn(data[2, ]), case$missing)
      expect_identical(fn(data[FALSE, ]), case$empty)
    }
  }
})

test_that("character ordering is locale-independent and preserves Unicode", {
  data <- tibble::tibble(a = c("A", "\u00e9", NA), b = c("a", "z", NA))
  expect_identical(row_max(data), c("a", "\u00e9", NA_character_))
  expect_identical(row_min(data), c("A", "z", NA_character_))
  expect_identical(row_max(data[c("b", "a")]), row_max(data))
})

test_that("unsupported numeric classes require explicit semantic conversion", {
  data <- tibble::tibble(a = structure(c(1, NA), class = "unknown_measure"))
  for (fn in list(
    row_min,
    row_max,
    row_sum,
    row_mean,
    row_median,
    row_var,
    row_sd
  )) {
    expect_error(fn(data), "supported|conversion")
  }
})

test_that("classed extrema preserve input metadata and run accepted expressions once", {
  data <- tibble::tibble(
    a = as.Date(c("2020-01-01", NA)),
    b = as.Date(c("2020-01-03", NA))
  )
  before <- serialize(data, NULL)
  calls <- 0L
  out <- dplyr::mutate(
    data,
    latest = row_max({
      calls <<- calls + 1L
      tibble::tibble(a = a, b = b)
    })
  )
  expect_identical(calls, 1L)
  expect_identical(out$latest, data$b)
  expect_identical(serialize(data, NULL), before)
})

test_that("large signed integer64 extrema retain exact order and identity", {
  skip_if_not_installed("bit64")
  data <- tibble::tibble(
    a = bit64::as.integer64(c("9223372036854775807", "-9223372036854775807")),
    b = bit64::as.integer64(c("9223372036854775806", "-9223372036854775806"))
  )
  before <- serialize(data, NULL)
  expect_identical(
    as.character(row_max(data)),
    c("9223372036854775807", "-9223372036854775806")
  )
  expect_identical(
    as.character(row_min(data)),
    c("9223372036854775806", "-9223372036854775807")
  )
  expect_identical(row_unique(data), c(2L, 2L))
  expect_identical(serialize(data, NULL), before)
})

test_that("the same vector can be passed more than once", {
  x <- c(1L, NA, 3L)
  y <- c(2L, 5L, NA)
  expect_identical(row_max(x, x), x)
  expect_identical(row_sum(x, x, y), c(4, 5, 6))
  expect_identical(row_miss(x, x), c(0L, 2L, 0L))
})
