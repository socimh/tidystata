test_that("conversion drops vector metadata without modifying inputs", {
  x <- structure(c(a = 1, b = NA_real_), label = "Measurement")
  original <- x

  expect_identical(as_character(x), c("1", NA_character_))
  expect_identical(as_numeric(x), c(1, NA_real_))
  expect_identical(x, original)
})

test_that("conversion flattens matrices in column order", {
  x <- matrix(c(1, NA, 2, 3), nrow = 2, dimnames = list(c("a", "b"), c("x", "y")))
  original <- x

  expect_identical(as_character(x), c("1", NA_character_, "2", "3"))
  expect_identical(as_numeric(x), c(1, NA_real_, 2, 3))
  expect_identical(as_numeric(matrix(c("1", "2", "3", "4"), 2)), c(1, 2, 3, 4))
  expect_identical(x, original)
})

test_that("conversion returns typed empty vectors", {
  inputs <- list(NULL, numeric(), character(), logical(), factor(), list(), matrix(numeric(), 0, 2))

  for (x in inputs) {
    expect_identical(as_character(x), character())
    expect_identical(as_numeric(x), numeric())
  }
})

test_that("conversion distinguishes numeric missing values from their text", {
  x <- c(NA_real_, NaN, Inf, -Inf)

  expect_identical(as_character(x), c(NA_character_, "NaN", "Inf", "-Inf"))
  expect_identical(as_numeric(x), x)
  expect_identical(as_numeric(c("NaN", " NaN ", "NA", "", NA)), c(NaN, NaN, NA, NA, NA))
})

test_that("number parsing retains exact diagnostic rows and positions", {
  x <- c("$12.50", "bad", NA, "NaN", "4 kg", "invalid")
  original <- x

  expect_warning(result <- as_numeric(x), "parsing failure")
  expect_identical(as.vector(result), c(12.5, NA, NA, NaN, 4, NA))
  problems <- readr::problems(result)
  expect_identical(problems$row, c(2L, 6L))
  expect_identical(problems$actual, c("bad", "invalid"))
  expect_identical(problems$expected, rep("a number", 2))
  expect_identical(x, original)
})

test_that("factor conversion uses level text and level codes", {
  x <- ordered(c("20", "10", NA, "20"), levels = c("20", "10", "unused"))

  expect_identical(as_character(x), c("20", "10", NA_character_, "20"))
  expect_identical(as_numeric(x), c(1, 2, NA_real_, 1))
})

test_that("labelled conversion preserves raw values and partial labels", {
  x <- haven::labelled(c(1, 99, NA), labels = c(Yes = 1), label = "Question")
  original <- x

  expect_identical(as_character(x), c("Yes", "99", NA_character_))
  expect_identical(as_numeric(x), c(1, 99, NA_real_))
  expect_identical(x, original)
})

test_that("tagged missing labels are displayed while numeric tags survive", {
  missing <- haven::tagged_na("a")
  x <- haven::labelled(c(1, missing, NA), c(Yes = 1, Refused = missing))

  expect_identical(as_character(x), c("Yes", "Refused", NA_character_))
  result <- as_numeric(x)
  expect_identical(result[1], 1)
  expect_identical(haven::na_tag(result), c(NA_character_, "a", NA_character_))
  expect_identical(haven::is_tagged_na(result), c(FALSE, TRUE, FALSE))
})

test_that("tagged missing values without labels use ordinary character coercion", {
  x <- haven::labelled(c(1, haven::tagged_na("b"), NA_real_))

  expect_identical(as_character(x), c("1", NA_character_, NA_character_))
  expect_identical(haven::na_tag(as_numeric(x)), c(NA_character_, "b", NA_character_))
})

test_that("SPSS user missing codes remain values during conversion", {
  x <- haven::labelled_spss(
    c(1, 99, 95, NA), labels = c(Yes = 1, Missing = 99),
    na_values = 99, na_range = c(90, 100)
  )
  original <- x

  expect_identical(as_character(x), c("Yes", "Missing", "95", NA_character_))
  expect_identical(as_numeric(x), c(1, 99, 95, NA_real_))
  expect_identical(is.na(x), c(FALSE, TRUE, TRUE, TRUE))
  expect_identical(x, original)
})

test_that("labelled character numeric values use ordinary numeric coercion", {
  x <- haven::labelled(c("10", "20", NA), c(Ten = "10"))

  expect_identical(as_character(x), c("Ten", "20", NA_character_))
  expect_identical(as_numeric(x), c(10, 20, NA_real_))
  expect_warning(
    result <- as_numeric(haven::labelled(c("10 kg", "bad"), c(Ten = "10 kg"))),
    "NAs introduced by coercion"
  )
  expect_identical(result, c(NA_real_, NA_real_))
})

test_that("lists and unsupported numeric inputs retain element count", {
  x <- list(1, NA_real_, NULL, c(2, 3))

  expect_identical(as_character(x), c("1", "NA", "NULL", "c(2, 3)"))
  expect_identical(as_numeric(x), rep(NA_real_, 4))
  expect_identical(as_numeric(as.raw(c(1, 2))), rep(NA_real_, 2))
  expect_identical(as_numeric(c(1 + 2i, NA_complex_)), rep(NA_real_, 2))
})

test_that("calendar conversion uses days and UTC seconds", {
  dates <- as.Date(c("1970-01-01", "1970-01-02", NA))
  times <- as.POSIXct(c("1970-01-01 00:00:00", "1970-01-02 00:00:00", NA), tz = "UTC")

  expect_identical(as_numeric(dates), c(0, 1, NA_real_))
  expect_identical(as_numeric(times), c(0, 86400, NA_real_))
  expect_identical(as_character(dates), c("1970-01-01", "1970-01-02", NA_character_))
  expect_identical(as_character(times), c("1970-01-01", "1970-01-02", NA_character_))
})

test_that("duration conversion retains its stated units", {
  x <- as.difftime(c(1, NA, 3), units = "hours")

  expect_identical(as_numeric(x), c(1, NA_real_, 3))
  expect_identical(as_character(x), c("1", NA_character_, "3"))
  expect_identical(units(x), "hours")
})

test_that("measured conversion drops units without changing values", {
  skip_if_not_installed("units")
  x <- units::set_units(c(1, NA, 3), "m")
  original <- x

  expect_identical(as_character(x), c("1", NA_character_, "3"))
  expect_identical(as_numeric(x), c(1, NA_real_, 3))
  expect_identical(x, original)
})

test_that("integer64 conversion retains character precision and warns on numeric loss", {
  skip_if_not_installed("bit64")
  x <- bit64::as.integer64(c("9007199254740993", NA))
  original <- x

  expect_identical(as_character(x), c("9007199254740993", NA_character_))
  expect_warning(result <- as_numeric(x), "precision lost")
  expect_identical(result, c(9007199254740992, NA_real_))
  expect_identical(x, original)
})

test_that("missing replacement preserves vector type and names", {
  x <- c(a = 1L, b = NA_integer_, c = 3L)
  original <- x

  expect_identical(na_if_value(x, 1L), c(a = NA_integer_, b = NA_integer_, c = 3L))
  expect_identical(value_if_na(x, 2L), c(a = 1L, b = 2L, c = 3L))
  expect_identical(x, original)
})

test_that("missing replacement supports vector comparisons and NaN", {
  expect_identical(na_if_value(c(1, 2, 3), c(1, 9, 3)), c(NA_real_, 2, NA_real_))
  expect_identical(na_if_value(c(1, NaN, NA_real_), NaN), c(1, NA_real_, NA_real_))
  expect_identical(value_if_na(c(1, NaN, NA_real_), 0), c(1, 0, 0))
})

test_that("missing replacement preserves categorical and date classes", {
  x <- factor(c("a", NA, "b"), levels = c("a", "b", "unused"))
  dates <- as.Date(c("2024-01-01", NA))

  expect_identical(na_if_value(x, "a"), factor(c(NA, NA, "b"), levels = levels(x)))
  expect_identical(value_if_na(x, "b"), factor(c("a", "b", "b"), levels = levels(x)))
  expect_identical(value_if_na(dates, as.Date("2024-01-02")), as.Date(c("2024-01-01", "2024-01-02")))
})

test_that("missing replacement returns typed empty inputs", {
  expect_identical(na_if_value(integer(), 1L), integer())
  expect_identical(value_if_na(integer(), 1L), integer())
  expect_identical(na_if_value(character(), "missing"), character())
  expect_identical(value_if_na(character(), "missing"), character())
})

test_that("missing replacement reports incompatible sizes and lossy casts", {
  expect_error(na_if_value(1:3, 1:2), class = "vctrs_error_incompatible_size")
  expect_error(na_if_value(1:3, 1.5), class = "vctrs_error_cast_lossy")
  expect_error(value_if_na(c(1L, NA_integer_), 1.5), class = "vctrs_error_cast_lossy")
  expect_error(value_if_na(c(1, NA_real_), c(2, 3)))
})

test_that("conversion composes in research preparation without mutating source", {
  survey <- tibble::tibble(
    response = haven::labelled(c(1, 2, NA), c(Yes = 1, No = 2)),
    income = c("$1,200", "", "$900"),
    code = c(1L, 99L, 2L)
  )
  original <- survey
  result <- survey |>
    dplyr::mutate(
      response_text = as_character(response),
      income_numeric = as_numeric(income),
      code = na_if_value(code, 99L),
      response_text = value_if_na(response_text, "Unknown")
    )

  expect_identical(result$response_text, c("Yes", "No", "Unknown"))
  expect_identical(result$income_numeric, c(1200, NA_real_, 900))
  expect_identical(result$code, c(1L, NA_integer_, 2L))
  expect_identical(survey, original)
})
