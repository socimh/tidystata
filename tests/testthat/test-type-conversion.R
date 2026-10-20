# ============================================================================
# CHALLENGING TESTS - as_character
# ============================================================================

test_that("as_character: basic numeric vector", {
  x <- 1:5
  result <- as_character(x)
  expect_type(result, "character")
  expect_equal(result, c("1", "2", "3", "4", "5"))
})

test_that("as_character: basic character vector (no change)", {
  x <- c("a", "b", "c")
  result <- as_character(x)
  expect_equal(result, c("a", "b", "c"))
})

test_that("as_character: factor to character", {
  x <- factor(c("apple", "banana", "cherry"))
  result <- as_character(x)
  expect_type(result, "character")
  expect_equal(result, c("apple", "banana", "cherry"))
})

test_that("as_character: ordered factor to character", {
  x <- ordered(c("low", "medium", "high"))
  result <- as_character(x)
  expect_type(result, "character")
  expect_equal(result, c("low", "medium", "high"))
})

test_that("as_character: haven labelled to character", {
  x <- haven::labelled(
    c(1, 2, 1, 3),
    labels = c(Yes = 1, No = 2, Maybe = 3)
  )
  result <- as_character(x)
  expect_type(result, "character")
  expect_equal(result, c("Yes", "No", "Yes", "Maybe"))
})

test_that("as_character: haven labelled with partial labels", {
  x <- haven::labelled(
    c(1, 2, 99, 1),
    labels = c(Yes = 1, No = 2)
  )
  result <- as_character(x)
  expect_type(result, "character")
  expect_identical(result, c("Yes", "No", "99", "Yes"))
})

test_that("as_character: logical to character", {
  x <- c(TRUE, FALSE, TRUE)
  result <- as_character(x)
  expect_type(result, "character")
  expect_equal(result, c("TRUE", "FALSE", "TRUE"))
})

test_that("as_character: Date to character", {
  x <- as.Date(c("2024-01-01", "2024-06-15"))
  result <- as_character(x)
  expect_identical(result, c("2024-01-01", "2024-06-15"))
})

test_that("as_character: POSIXct to character", {
  x <- as.POSIXct(c("2024-01-01 10:00:00", "2024-06-15 14:30:00"), tz = "UTC")
  result <- as_character(x)
  expect_identical(result, c("2024-01-01 10:00:00", "2024-06-15 14:30:00"))
})

test_that("as_character: NA handling", {
  x <- c(1, 2, NA, 4)
  result <- as_character(x)
  expect_equal(result, c("1", "2", NA, "4"))
})

test_that("as_character: empty vector", {
  x <- numeric(0)
  result <- as_character(x)
  expect_equal(length(result), 0)
  expect_type(result, "character")
})

test_that("as_character: within mutate context", {
  df <- tibble::tibble(
    num = 1:5,
    lbl = haven::labelled(c(1, 2, 1, 2, 1), labels = c(A = 1, B = 2))
  )
  result <- df %>%
    dplyr::mutate(num_chr = as_character(num), lbl_chr = as_character(lbl))
  expect_type(result$num_chr, "character")
  expect_type(result$lbl_chr, "character")
  expect_equal(result$lbl_chr, c("A", "B", "A", "B", "A"))
})

# ============================================================================
# CHALLENGING TESTS - as_numeric
# ============================================================================

test_that("as_numeric: basic numeric vector (no change)", {
  x <- c(1.5, 2.5, 3.5)
  result <- as_numeric(x)
  expect_type(result, "double")
  expect_equal(result, c(1.5, 2.5, 3.5))
})

test_that("as_numeric: integer to numeric", {
  x <- 1:5
  result <- as_numeric(x)
  expect_type(result, "double")
  expect_equal(result, as.double(1:5))
})

test_that("as_numeric: character numeric to numeric", {
  x <- c("1", "2.5", "3.14")
  result <- as_numeric(x)
  expect_type(result, "double")
  expect_equal(result, c(1, 2.5, 3.14), tolerance = 0.001)
})

test_that("as_numeric: character with non-numeric returns NA", {
  x <- c("a", "b", "c")
  expect_warning(result <- as_numeric(x), "parsing failure")
  expect_type(result, "double")
  expect_true(all(is.na(result)))
})

test_that("as_numeric: mixed character numeric", {
  x <- c("1", "abc", "3.14", "xyz")
  expect_warning(result <- as_numeric(x), "parsing failure")
  # readr preserves parsing diagnostics as an attribute on the numeric vector.
  expect_equal(as.vector(result), c(1, NA, 3.14, NA), tolerance = 0.001)
})

test_that("as_numeric: factor to numeric (level values)", {
  x <- factor(c(10, 20, 30, 20))
  result <- as_numeric(x)
  expect_type(result, "double")
  expect_equal(result, c(1, 2, 3, 2)) # Factor level indices
})

test_that("as_numeric: ordered factor to numeric", {
  x <- ordered(
    c("low", "medium", "high", "medium"),
    levels = c("low", "medium", "high")
  )
  result <- as_numeric(x)
  expect_type(result, "double")
  expect_equal(result, c(1, 2, 3, 2))
})

test_that("as_numeric: haven labelled to numeric", {
  x <- haven::labelled(
    c(10, 20, 10, 30),
    labels = c(Ten = 10, Twenty = 20, Thirty = 30)
  )
  result <- as_numeric(x)
  expect_type(result, "double")
  expect_equal(result, c(10, 20, 10, 30))
})

test_that("as_numeric: logical to numeric", {
  x <- c(TRUE, FALSE, TRUE, TRUE)
  result <- as_numeric(x)
  expect_type(result, "double")
  expect_equal(result, c(1, 0, 1, 1))
})

test_that("as_numeric: Date to numeric (days since epoch)", {
  x <- as.Date(c("2024-01-01", "1970-01-01"))
  result <- as_numeric(x)
  expect_type(result, "double")
  expect_equal(result[2], 0) # 1970-01-01 is epoch
})

test_that("as_numeric: POSIXct to numeric", {
  x <- as.POSIXct(c("2024-01-01 00:00:00", "1970-01-01 00:00:00"), tz = "UTC")
  result <- as_numeric(x)
  expect_type(result, "double")
  expect_equal(result[2], 0) # The UTC Unix epoch.
})

test_that("as_numeric: difftime to numeric", {
  x <- as.difftime(c(1, 2, 3), units = "hours")
  result <- as_numeric(x)
  expect_type(result, "double")
  expect_equal(result, c(1, 2, 3))
})

test_that("as_numeric: NA handling", {
  x <- c(1, NA, 3, NA, 5)
  result <- as_numeric(x)
  expect_equal(result, c(1, NA, 3, NA, 5))
})

test_that("as_numeric: Inf and -Inf handling", {
  x <- c(1, Inf, -Inf, 4)
  result <- as_numeric(x)
  expect_equal(result, c(1, Inf, -Inf, 4))
})

test_that("as_numeric: character with currency symbols", {
  x <- c("$1,234.56", "\u20ac500.00", "\u00a31,000")
  expect_identical(as_numeric(x), c(1234.56, 500, 1000))
})

test_that("as_numeric: within mutate context", {
  df <- tibble::tibble(
    chr = c("1", "2", "3"),
    fct = factor(c(10, 20, 30)),
    lbl = haven::labelled(c(100, 200, 100), labels = c(A = 100, B = 200))
  )
  result <- df %>%
    dplyr::mutate(
      chr_num = as_numeric(chr),
      fct_num = as_numeric(fct),
      lbl_num = as_numeric(lbl)
    )
  expect_type(result$chr_num, "double")
  expect_type(result$fct_num, "double")
  expect_type(result$lbl_num, "double")
  expect_equal(result$lbl_num, c(100, 200, 100))
})

# ============================================================================
# CHALLENGING TESTS - Complex Scenarios
# ============================================================================

test_that("type conversion: round-trip character -> numeric -> character", {
  original <- c("1", "2.5", "3.14")
  numeric_version <- as_numeric(original)
  character_version <- as_character(numeric_version)

  expect_equal(numeric_version, c(1, 2.5, 3.14))
  expect_identical(character_version, original)
})

test_that("type conversion: haven labelled preserves labels in character", {
  x <- haven::labelled(
    c(1, 2, 1, 3),
    labels = c(Yes = 1, No = 2, Maybe = 3)
  )

  char_result <- as_character(x)
  num_result <- as_numeric(x)

  expect_equal(char_result, c("Yes", "No", "Yes", "Maybe"))
  expect_equal(num_result, c(1, 2, 1, 3))
})

test_that("type conversion: data frame conversion workflow", {
  df <- tibble::tibble(
    id = haven::labelled(c(1, 2, 3), labels = c(A = 1, B = 2, C = 3)),
    score = c("85.5", "92.0", "78.5"),
    passed = factor(c("Yes", "Yes", "No"))
  )

  result <- df %>%
    dplyr::mutate(
      id_chr = as_character(id),
      score_num = as_numeric(score),
      passed_num = as_numeric(passed)
    )

  expect_type(result$id_chr, "character")
  expect_type(result$score_num, "double")
  expect_type(result$passed_num, "double")
  expect_equal(result$score_num, c(85.5, 92.0, 78.5))
})

test_that("type conversion: handles large numbers", {
  x <- c("1000000000", "999999999999")
  result <- as_numeric(x)
  expect_equal(result, c(1e9, 999999999999))
})

test_that("type conversion: handles small numbers", {
  x <- c("0.0000001", "0.000000001")
  result <- as_numeric(x)
  expect_equal(result, c(1e-7, 1e-9), tolerance = 1e-15)
})

test_that("type conversion: handles scientific notation", {
  x <- c("1e5", "2.5e-3", "3E10")
  result <- as_numeric(x)
  expect_equal(result, c(1e5, 2.5e-3, 3e10))
})

# ============================================================================
# CHALLENGING TESTS - Edge Cases
# ============================================================================

test_that("type conversion: empty vector handling", {
  empty_num <- numeric(0)
  empty_chr <- character(0)

  expect_equal(length(as_character(empty_num)), 0)
  expect_equal(length(as_numeric(empty_chr)), 0)
})

test_that("type conversion: single element handling", {
  expect_equal(as_character(42), "42")
  expect_equal(as_numeric("42"), 42)
})

test_that("type conversion: all NA handling", {
  x <- c(NA, NA, NA)
  expect_equal(as_character(x), rep(NA_character_, 3))
  expect_equal(as_numeric(x), c(NA_real_, NA_real_, NA_real_))
})

test_that("type conversion: NaN handling", {
  x <- c(1, NaN, 3)
  result <- as_character(x)
  expect_identical(result, c("1", "NaN", "3"))

  result_num <- as_numeric(c("1", "NaN", "3"))
  expect_true(is.nan(result_num[2]))
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("type conversion: survey data import workflow", {
  # Simulating data from SPSS/Stata import
  survey_data <- tibble::tibble(
    respondent_id = 1:5,
    gender = haven::labelled(
      c(1, 2, 1, 2, 1),
      labels = c(Male = 1, Female = 2)
    ),
    age_group = haven::labelled(
      c(1, 2, 3, 2, 1),
      labels = c("18-25" = 1, "26-35" = 2, "36+" = 3)
    ),
    satisfaction = c("4", "5", "3", "4", "5")
  )

  # Convert for analysis
  analysis_data <- survey_data %>%
    dplyr::mutate(
      gender_chr = as_character(gender),
      age_chr = as_character(age_group),
      satisfaction_num = as_numeric(satisfaction)
    )

  expect_type(analysis_data$gender_chr, "character")
  expect_equal(
    analysis_data$gender_chr,
    c("Male", "Female", "Male", "Female", "Male")
  )
  expect_identical(analysis_data$satisfaction_num, c(4, 5, 3, 4, 5))
  expect_identical(
    analysis_data$age_chr,
    c("18-25", "26-35", "36+", "26-35", "18-25")
  )
})

test_that("type conversion: financial data parsing", {
  financial_data <- tibble::tibble(
    transaction_id = 1:4,
    amount_chr = c("$1,234.56", "$500.00", "$2,000.00", "$750.50"),
    currency = c("USD", "USD", "EUR", "GBP")
  )

  result <- financial_data %>%
    dplyr::mutate(amount_num = as_numeric(amount_chr))

  expect_type(result$amount_num, "double")
  expect_identical(result$amount_num, c(1234.56, 500, 2000, 750.5))
})


test_that("custom type names containing lbl do not confer haven semantics", {
  x <- structure(c(1, 2), class = "lbl_currency", labels = c(one = 1))
  expect_identical(as_numeric(x), c(NA_real_, NA_real_))
  expect_identical(as_character(x), c("1", "2"))
})

# Regression contracts for the first maintenance milestone. Expectations use
# scalar base-R calculations and independent group counts, not package helpers.

test_that("milestone as_numeric parses character values without losing positions", {
  expect_equal(
    as_numeric(c("1", "$2,500.50", NA, "3e-2")),
    c(1, 2500.5, NA, 0.03)
  )
  expect_identical(as_numeric(character()), numeric())
})

# Character parsing must work for real imported columns, including sparse and
# empty ones. These fixtures also catch precision loss and row recycling.
.milestone_parse_cases <- list(
  integers = list(c("1", "2", "3"), c(1, 2, 3)),
  decimals = list(c("1.25", "2.50", "0.01"), c(1.25, 2.5, 0.01)),
  signs = list(c("-2", "+3", "-0.5"), c(-2, 3, -0.5)),
  exponent = list(c("1e5", "2.5e-3", "3E10"), c(1e5, 0.0025, 3e10)),
  dollars = list(c("$1,234.56", "$500.00"), c(1234.56, 500)),
  currency = list(c("\u20ac500.25", "\u00a31,000"), c(500.25, 1000)),
  spaces = list(c(" 1 ", "\t2.5", "3\n"), c(1, 2.5, 3)),
  negative_currency = list(c("$-12.50", "-1,000.25"), c(-12.5, -1000.25)),
  grouped_thousands = list(c("1,234,567", "12,345"), c(1234567, 12345)),
  embedded_units = list(c("10 kg", "20.5 km"), c(10, 20.5)),
  prefixes = list(c("USD 100.5", "EUR 20"), c(100.5, 20)),
  missing_middle = list(c("1", NA, "3"), c(1, NA, 3)),
  missing_edges = list(c(NA, "2", NA), c(NA, 2, NA)),
  entirely_missing = list(rep(NA_character_, 3), rep(NA_real_, 3)),
  empty = list(character(), numeric()),
  singleton = list("42", 42),
  nonnumeric = list(c("apple", "pear"), c(NA_real_, NA_real_)),
  mixed_nonnumeric = list(c("1", "bad", "3"), c(1, NA, 3)),
  blank_values = list(c("", " ", "4"), c(NA, NA, 4)),
  zeros = list(c("0", "-0", "0.000"), c(0, 0, 0)),
  leading_zeros = list(c("00012", "000.125"), c(12, 0.125)),
  small_numbers = list(c("0.000000001", "2e-12"), c(1e-9, 2e-12)),
  large_numbers = list(c("1000000000", "999999999999"), c(1e9, 999999999999))
)

for (.scenario in names(.milestone_parse_cases)) {
  test_that(paste("milestone as_numeric imported character", .scenario), {
    case <- .milestone_parse_cases[[.scenario]]
    before <- case[[1]]
    parsing_warning <- if (.scenario %in% c("nonnumeric", "mixed_nonnumeric")) {
      "parsing failure"
    } else {
      NA
    }
    expect_warning(out <- as_numeric(case[[1]]), parsing_warning)
    expect_type(out, "double")
    expect_length(out, length(case[[1]]))
    expect_equal(as.vector(out), case[[2]], tolerance = 1e-14)
    expect_identical(case[[1]], before)
    d <- tibble::tibble(raw = case[[1]])
    expect_warning(
      converted <- dplyr::mutate(d, value = as_numeric(raw)),
      parsing_warning
    )
    expect_equal(as.vector(converted$value), case[[2]], tolerance = 1e-14)
  })
}

test_that("tostring() gives codes as text, ignoring value labels", {
  labelled <- haven::labelled(c(1, 2, NA), c(Low = 1, High = 2))
  expect_identical(tostring(labelled), c("1", "2", NA))
  expect_identical(decode(labelled), c("Low", "High", NA))
  expect_identical(tostring(factor(c("b", "a", NA))), c("2", "1", NA))
  expect_identical(tostring(c("x", NA)), c("x", NA))
  expect_identical(tostring(c(0.5, NA, NaN)), c("0.5", NA, NA))
  expect_identical(tostring(c(TRUE, NA)), c("TRUE", NA))
  expect_identical(tostring(as.Date("2024-01-31")), "2024-01-31")
  expect_identical(tostring(haven::tagged_na("a")), NA_character_)
  expect_identical(tostring(integer()), character())
})
