test_that("PROBLEMS2 row sums consume na.rm rather than adding it", {
  data <- tibble::tibble(a = c(1, NA, NA), b = c(NA, 2, NA))
  expect_identical(row_sum(data, na.rm = TRUE), c(1, 2, 0))
  expect_identical(row_sum(data, na.rm = FALSE), rep(NA_real_, 3))
  expect_identical(row_sum(data), c(1, 2, 0))
  out <- dplyr::mutate(data, sum = row_sum(a, b, na.rm = FALSE))
  expect_identical(out$sum, rep(NA_real_, 3))
  expect_identical(row_sum(data[FALSE, ], na.rm = FALSE), numeric())
  for (bad in list(NA, 1, logical(), c(TRUE, FALSE))) {
    expect_error(row_sum(data, na.rm = bad), "na.rm")
  }
})

test_that("PROBLEMS2 row sums respect original labelled missing masks", {
  data <- tibble::tibble(
    a = haven::labelled_spss(c(1, 99, 3), na_values = 99),
    b = c(4, 5, haven::tagged_na("a"))
  )
  expect_identical(row_sum(data, na.rm = TRUE), c(5, 5, 3))
  expect_identical(row_sum(data, na.rm = FALSE), c(5, NA_real_, NA_real_))
})

test_that("PROBLEMS2 extrema accept explicit constants without changing selectors", {
  data <- tibble::tibble(x = c(1, 4, NA), y = c(3, 2, NA))
  # Constants never fill rows whose selected values are all missing (as pmin).
  expect_identical(row_min(data, .values = 0.5), c(0.5, 0.5, NA))
  expect_identical(row_max(data, .values = list(2, c(5, 1, NA))), c(5, 4, NA))
  out <- dplyr::mutate(
    data,
    cap = row_min(x, .values = 0.5),
    positional = row_min(c(1, 2)),
    multiple = row_max(x, .values = list(2, c(5, 1, NA)))
  )
  expect_identical(out$cap, c(0.5, 0.5, NA))
  expect_identical(out$positional, c(1, 2, NA_real_))
  expect_identical(out$multiple, c(5, 4, NA))
  expect_error(row_min(data, .values = 1:2), "length")
  expect_error(row_min(data, .values = list(NULL)), "length")
  expect_error(row_min(data, .values = list(list(1))), "one-dimensional")
  expect_error(row_min(data, .values = 1 + 1i), "ordering")
})

test_that("PROBLEMS2 explicit extrema values retain classes and group sizes", {
  dates <- as.Date(c("2024-01-01", "2024-01-03"))
  data <- tibble::tibble(x = dates)
  expect_identical(row_max(data, .values = dates[2]), rep(dates[2], 2))
  expect_identical(row_min(data[FALSE, ], .values = dates[1]), dates[FALSE])
  expect_identical(row_min(tibble::tibble(x = 1:2), .values = 0L), c(0L, 0L))
  grouped <- tibble::tibble(g = c(1, 1, 2), x = c(1, 3, 2)) |>
    dplyr::group_by(g) |>
    dplyr::mutate(value = row_max(x, .values = seq_len(dplyr::n())))
  expect_identical(grouped$value, c(1, 3, 2))
  expect_error(row_min(data, .values = 1), "incompatible")
  missing <- haven::labelled_spss(c(99, 2), na_values = 99)
  expect_identical(
    as.double(row_min(tibble::tibble(x = missing), .values = missing[2])),
    c(NA, 2)
  )
  expect_identical(row_min(tibble::tibble(x = 1:2), .values = list()), 1:2)
})

test_that("PROBLEMS2 timer reports failures optionally and preserves the error", {
  original <- structure(
    list(message = "test failure", call = quote(original_call())),
    class = c("problems2_error", "error", "condition")
  )
  count <- 0L
  messages <- character()
  error <- withCallingHandlers(
    tryCatch(
      timer(
        {
          count <- count + 1L
          stop(original)
        },
        .on_error = TRUE
      ),
      error = identity
    ),
    message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  expect_identical(error, original)
  expect_identical(count, 1L)
  expect_length(messages, 1)
  expect_match(messages, "[Ff]ailed.*[Tt]ime|[Tt]ime.*[Ff]ailed")
  messages <- character()
  withCallingHandlers(
    tryCatch(timer(stop(original), .on_error = FALSE), error = identity),
    message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  expect_length(messages, 0)
  # Failed elapsed time is reported by default; the error call is not rewritten.
  messages <- character()
  failure <- withCallingHandlers(
    tryCatch(timer(stop("plain failure")), error = identity),
    message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  expect_length(messages, 1)
  expect_match(messages, "Failed execution")
  expect_identical(conditionMessage(failure), "plain failure")
  expect_false(grepl("withCallingHandlers", deparse(conditionCall(failure))[1]))
  expect_false(
    suppressMessages(withVisible(timer(42, .on_error = TRUE)))$visible
  )
  expect_identical(
    statart:::duration_to_chr(as.difftime(61, units = "secs")),
    "1m1s"
  )
  for (bad in list(NA, 1, logical(), c(TRUE, FALSE))) {
    expect_error(timer(42, .on_error = bad), ".on_error", fixed = TRUE)
  }
})

test_that("PROBLEMS2 failure timing keeps warnings and nested timing intact", {
  result <- NULL
  expect_warning(
    suppressMessages(
      result <- timer(
        {
          warning("original warning")
          42
        },
        .on_error = TRUE
      )
    ),
    "original warning"
  )
  expect_identical(result, 42)
  count <- 0L
  messages <- character()
  withCallingHandlers(
    result <- timer(
      timer(
        {
          count <- count + 1L
          42
        },
        .on_error = TRUE
      ),
      .on_error = TRUE
    ),
    message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  expect_identical(result, 42)
  expect_identical(count, 1L)
  expect_length(messages, 2)
})

test_that("PROBLEMS2 ds reuses character name inventories", {
  data <- tibble::tibble(x1 = 1, x2 = "a", other = TRUE)
  inventory <- ds(data)
  expect_identical(ds(inventory), c("x1", "x2", "other"))
  expect_identical(ds(inventory, dplyr::starts_with("x")), c("x1", "x2"))
  expect_identical(ds(inventory, 3, 1), c("other", "x1"))
  expect_identical(ds(inventory, renamed = x2), "renamed")
  expect_identical(ds(stats::setNames(inventory, letters[1:3])), inventory)
  expect_identical(ds(character()), character())
  expect_identical(ds(character(), dplyr::everything()), character())
  expect_error(ds(inventory, dplyr::where(is.character)), "predicate")
  expect_error(ds(inventory, absent), "absent")
  for (bad in list(c("x", "x"), c("x", NA), c("x", ""), " ")) {
    expect_error(ds(bad), "unique|nonempty|missing")
  }
  expect_identical(ds(data, dplyr::where(is.character)), "x2")
})

test_that("PROBLEMS2 missing value replacement arguments explain valid calls", {
  expect_error(value_if_na(4), ".value.*value_if_na", fixed = FALSE)
  expect_error(value_if_na(), ".x.*value_if_na", fixed = FALSE)
  expect_error(value_if_na(.value = 4), ".x.*value_if_na", fixed = FALSE)
  expect_identical(value_if_na(c(1L, NA_integer_), 2L), c(1L, 2L))
  expect_error(value_if_na(c(1L, NA_integer_), "bad"))
})

test_that("PROBLEMS2 value replacement follows SPSS user-missing values", {
  spss <- haven::labelled_spss(
    c(1, 2, NA, 99),
    labels = c(Yes = 1, Refused = 99),
    na_values = 99
  )
  filled <- value_if_na(spss, 2)
  expect_identical(as.numeric(unclass(filled)), c(1, 2, 2, 2))
  expect_s3_class(filled, "haven_labelled_spss")
  expect_identical(attr(filled, "labels"), attr(spss, "labels"))
  ranged <- haven::labelled_spss(c(5, -9, NA), na_range = c(-9, -1))
  expect_identical(as.numeric(unclass(value_if_na(ranged, 0))), c(5, 0, 0))
  expect_error(value_if_na(spss, "text"))
})

test_that("PROBLEMS2 extrema treat numeric literals as values like pmin", {
  wide <- tibble::as_tibble(stats::setNames(as.list(1:12), paste0("v", 1:12)))
  wide <- wide[c(1, 1), ]
  wide$v10 <- c(10, 50)
  wide$x <- c(3, 30)
  expect_identical(dplyr::mutate(wide, y = row_min(x, 10))$y, pmin(wide$x, 10))
  expect_identical(dplyr::mutate(wide, y = row_max(x, 10))$y, pmax(wide$x, 10))
  d <- tibble::tibble(id = 1:3, p = c(.2, .7, NA))
  expect_identical(dplyr::mutate(d, y = row_min(p, .5))$y, pmin(d$p, .5))
  expect_identical(dplyr::mutate(d, y = row_min(p, 1))$y, pmin(d$p, 1))
  expect_identical(dplyr::mutate(d, y = row_max(p, -1))$y, pmax(d$p, -1))
  cap <- .5
  expect_identical(dplyr::mutate(d, y = row_min(p, cap))$y, pmin(d$p, .5))
  expect_identical(row_min(d$p, .5), pmin(d$p, .5))
  grouped <- dplyr::mutate(dplyr::group_by(d, id > 1), y = row_min(p, .5))
  expect_identical(grouped$y, pmin(d$p, .5))
  floor0 <- function(v) row_max(v, .values = 0)
  three <- tibble::tibble(a = c(1, 2, 1), b = c(10, 20, 30), c = 1:3)
  expect_identical(dplyr::mutate(three, z = floor0(a))$z, c(1, 2, 1))
  expect_identical(dplyr::mutate(three, z = row_min(a, b))$z, c(1, 2, 1))
})

test_that("PROBLEMS2 row helpers consume na.rm instead of adding a column", {
  d <- tibble::tibble(a = c(1, NA, NA), b = c(3, 2, NA))
  expect_identical(row_mean(d, na.rm = FALSE), c(2, NA, NA))
  expect_identical(row_mean(d, na.rm = TRUE), row_mean(d))
  expect_identical(row_max(d, na.rm = FALSE), c(3, NA, NA))
  expect_identical(row_min(d, na.rm = FALSE), c(1, NA, NA))
  expect_identical(row_median(d, na.rm = FALSE), c(2, NA, NA))
  expect_identical(row_sd(d, na.rm = FALSE), c(stats::sd(c(1, 3)), NA, NA))
  expect_identical(row_var(d, na.rm = FALSE), c(stats::var(c(1, 3)), NA, NA))
  expect_identical(
    dplyr::mutate(d, m = row_mean(a, b, na.rm = FALSE))$m,
    c(2, NA, NA)
  )
  for (fun in list(row_unique, row_miss, row_non_miss)) {
    expect_error(fun(d, na.rm = TRUE), "na.rm")
  }
  expect_error(row_mean(d, na.rm = NA), "na.rm")
})
