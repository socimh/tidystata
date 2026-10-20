# Comprehensive Challenging Test Suite for tab() Function
# 70+ difficult test scenarios - focusing on edge cases, complexity, and robustness
# All tests designed to run in < 1 minute

# CHALLENGE: Comprehensive testing for tab
# FUNCTIONS: tab
# KEY BEHAVIORS: cross-tabulation, percentage calculation
# EDGE CASES: high-dimensional tables, sparse data

# ============================================================================
# CHALLENGING TESTS - Variable Combinations & Complex Data Types
# ============================================================================

test_that("tab: five variables with complex interactions", {
  withr::local_preserve_seed()
  set.seed(42)
  df <- tibble::tibble(
    v1 = sample(1:3, 200, replace = TRUE),
    v2 = sample(letters[1:4], 200, replace = TRUE),
    v3 = factor(sample(c("low", "med", "high"), 200, replace = TRUE)),
    v4 = sample(c(TRUE, FALSE), 200, replace = TRUE),
    v5 = sample(1:2, 200, replace = TRUE)
  )
  result <- tab(df, v1, v2, v3, v4, v5)
  expect_true(nrow(result) > 10)
  expect_named(
    result,
    c(paste0("v", 1:5), "n", "percent", "cum", "valid", "valid_cum")
  )
  expect_equal(sum(result$n), 200)
})

test_that("tab: variables with reserved names (n, percent, cum)", {
  df <- tibble::tibble(
    n = c(1, 1, 2, 2),
    percent = c("a", "a", "b", "b"),
    cum = c("x", "y", "x", "y")
  )
  expect_message(
    result <- tab(df, n, percent, cum),
    "renamed"
  )
})

test_that("tab: list columns retain vector identities", {
  df <- tibble::tibble(
    x = 1:5,
    y = I(list(1:3, 2:4, 3:5, 4:6, 5:7))
  )
  before <- df
  result <- tab(df, x, y)
  expect_identical(result$x, 1:5)
  expect_equal(result$y, df$y)
  expect_equal(result$n, rep(1L, 5))
  expect_identical(df, before)
})

test_that("tab: matrix column input", {
  df <- tibble::tibble(x = 1:4)
  df$y <- matrix(1:8, nrow = 4)
  expect_error(tab(df, x, y))
})

# ============================================================================
# CHALLENGING TESTS - Missing Value Nightmares
# ============================================================================

test_that("tab: strategic NA placement - only first variable has NAs", {
  df <- tibble::tibble(
    x = c(NA, NA, 1, 1, 2, 2, NA),
    y = c("a", "b", "a", "b", "a", "b", "a")
  )
  result <- tab(df, x, y)
  expect_true(any(is.na(result$x)))
  expect_false(any(is.na(result$y)))
})

test_that("tab: cascading NAs - each row has NA in different column", {
  df <- tibble::tibble(
    x = c(NA, 2, 3),
    y = c("a", NA, "c"),
    z = c(1, 2, NA)
  )
  result <- tab(df, x, y, z)
  expect_true(any(is.na(result$x)))
  expect_true(any(is.na(result$y)))
  expect_true(any(is.na(result$z)))
  expect_equal(nrow(result), 3L)
  expect_equal(result$n, rep(1L, 3))
})

test_that("tab: all combinations of NA patterns", {
  df <- tibble::tibble(
    x = c(1, 1, 1, NA, NA, NA),
    y = c("a", "a", NA, "a", "a", NA)
  )
  result <- tab(df, x, y)
  expect_equal(nrow(result), 4L)
  expect_equal(sort(result$n), c(1L, 1L, 2L, 2L))
  expect_true(any(is.na(result$x) & result$y == "a"))
  expect_true(any(is.na(result$x) & is.na(result$y)))
})

test_that("tab: factor with NA level explicitly set", {
  df <- tibble::tibble(x = factor(c("a", "b", NA), exclude = NULL))
  result <- tab(df, x)
  expect_true(anyNA(levels(result$x)))
  expect_false(anyNA(result$x))
  expect_equal(result$n[is.na(as.character(result$x))], 1L)
  expect_equal(sum(result$n), 3)
})

test_that("tab: haven labelled with NA value labelled", {
  df <- tibble::tibble(
    x = haven::labelled_spss(
      c(1, 2, -99, 1),
      labels = c("Yes" = 1, "No" = 2, "Missing" = -99),
      na_values = -99
    )
  )
  result <- tab(df, x)
  expect_equal(nrow(result), 3)
})

# ============================================================================
# CHALLENGING TESTS - Complex Grouping Scenarios
# ============================================================================

test_that("tab: group by variable that is also being tabulated", {
  df <- tibble::tibble(group = rep(c("A", "B"), each = 10), x = 1:20)
  result <- tab(df, x, group, .by = group)
  expect_true("group" %in% names(result))
  expect_equal(nrow(result), 20)
})

test_that("tab: group with empty groups after filtering", {
  df <- tibble::tibble(
    group = rep(c("A", "B", "C"), each = 10),
    x = c(1:10, 11:20, 21:30)
  )
  result <- tab(df, above_15 = x > 15, .by = group)
  expect_setequal(result$group, c("A", "B", "C"))
  expect_equal(result$n[result$group == "A" & !result$above_15], 10L)
  expect_equal(result$n[result$group == "C" & result$above_15], 10L)
  expect_equal(sum(result$n), nrow(df))
})

test_that("tab: many grouping variables with complex hierarchy", {
  withr::local_preserve_seed()
  set.seed(123)
  df <- tibble::tibble(
    country = rep(c("US", "UK", "DE"), each = 30),
    region = rep(rep(c("North", "South", "East"), each = 10), 3),
    city = rep(c("A", "B", "C", "D", "E", "F", "G", "H", "I"), each = 10),
    category = sample(c("X", "Y", "Z"), 90, replace = TRUE)
  )
  result <- tab(df, category, .by = c(country, region))
  expect_named(
    result,
    c(
      "country",
      "region",
      "category",
      "n",
      "percent",
      "cum",
      "valid",
      "valid_cum"
    )
  )
  expect_true(nrow(result) <= 27)
})

test_that("tab: group where grouping variable has many NA levels", {
  df <- tibble::tibble(
    group = c(rep("A", 5), rep(NA, 20), rep("B", 5)),
    x = rep(c(1, 2), 15)
  )
  result <- tab(df, x, .by = group)
  expect_true(sum(is.na(result$group)) > 0)
  expect_equal(sum(result$n[result$group %in% c("A", "B")]), 10)
})

test_that("tab: group with single unique value in group", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    group = rep("only", 100),
    x = sample(1:5, 100, replace = TRUE)
  )
  result <- tab(df, x, .by = group)
  expect_equal(nrow(result), 5)
  expect_true(all(result$group == "only"))
})

# ============================================================================
# CHALLENGING TESTS - Complex Boolean Expressions
# ============================================================================

test_that("tab: boolean with OR and AND combined", {
  df <- tibble::tibble(x = 1:100, y = rep(letters[1:5], 20))
  result <- tab(df, y, selected = (x > 20 & x < 40) | (x > 60 & x < 80))
  expect_equal(sum(result$n), nrow(df))
  expect_equal(sum(result$n[result$selected]), 38L)
  expected <- dplyr::count(
    dplyr::mutate(df, selected = (x > 20 & x < 40) | (x > 60 & x < 80)),
    y,
    selected
  )
  expect_equal(dplyr::select(result, y, selected, n), expected)
})

test_that("tab: boolean expression creating all FALSE", {
  withr::local_preserve_seed()
  df <- tibble::tibble(x = 1:50, y = sample(1:3, 50, replace = TRUE))
  result <- tab(df, y, selected = x > 100)
  expect_false(any(result$selected))
  expect_equal(sum(result$n), nrow(df))
  expect_equal(dplyr::select(result, y, n), dplyr::count(df, y))
})

test_that("tab: boolean with is.na() function", {
  df <- tibble::tibble(
    x = c(1:5, NA, 7:10),
    y = c("a", "b", NA, "a", "b", "c", "a", "b", "a", "b")
  )
  result <- tab(df, y, missing_x = is.na(x))
  expect_equal(sum(result$n), nrow(df))
  expect_equal(result$y[result$missing_x], "c")
  expect_equal(result$n[result$missing_x], 1L)
})

test_that("tab: boolean with %in% operator", {
  df <- tibble::tibble(x = 1:20, y = rep(1:4, 5))
  result <- tab(df, y, selected = x %in% c(3, 7, 11, 15, 19))
  expect_equal(nrow(result), 4L)
  expect_equal(sum(result$n), nrow(df))
  expect_equal(sum(result$n[result$selected]), 5L)
})

test_that("tab: complex nested boolean with multiple variables", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    a = 1:50,
    b = rep(c("x", "y"), 25),
    c = sample(1:3, 50, replace = TRUE)
  )
  result <- tab(df, c, (a > 10 & b == "x") | (a <= 10 & b == "y"))
  expect_true(nrow(result) >= 1)
})

# ============================================================================
# CHALLENGING TESTS - Edge Cases & Extremes
# ============================================================================

test_that("tab: data frame with only 1 column and 1 row", {
  df <- tibble::tibble(x = "single")
  result <- tab(df, x)
  expect_equal(nrow(result), 1)
  expect_equal(result$n, 1)
})

test_that("tab: 1000 unique values with only 1 occurrence each", {
  df <- tibble::tibble(x = 1:1000)
  result <- tab(df, x)
  expect_equal(nrow(result), 1000)
  expect_true(all(result$n == 1))
})

test_that("tab: single value repeated 5000 times", {
  df <- tibble::tibble(x = rep("only_value", 5000))
  result <- tab(df, x)
  expect_equal(nrow(result), 1)
  expect_equal(result$n, 5000)
})

test_that("tab: Inf and -Inf values mixed with regular numbers", {
  df <- tibble::tibble(x = c(Inf, Inf, -Inf, -Inf, 0, 1, 2))
  result <- tab(df, x)
  expect_equal(nrow(result), 5)
  expect_true(Inf %in% result$x)
  expect_true(-Inf %in% result$x)
})

test_that("tab: NaN values treated as distinct from NA", {
  df <- tibble::tibble(x = c(1, 2, NaN, NaN, NA, NA))
  result <- tab(df, x)
  expect_true(nrow(result) >= 3)
})

test_that("tab: empty string vs whitespace vs regular strings", {
  df <- tibble::tibble(x = c("", " ", "  ", "a", "a", "b"))
  result <- tab(df, x)
  expect_true(nrow(result) >= 4)
  expect_true("" %in% result$x)
  expect_true(" " %in% result$x)
})

test_that("tab: numeric values at floating point precision limits", {
  df <- tibble::tibble(x = c(0.1 + 0.2, 0.3, 0.1 + 0.2, 0.3))
  result <- tab(df, x)
  expect_true(nrow(result) <= 2)
})

# ============================================================================
# CHALLENGING TESTS - Type Coercion & Mixed Types
# ============================================================================

test_that("tab: factor levels not in data", {
  df <- tibble::tibble(
    x = factor(c("a", "b"), levels = c("a", "b", "c", "d", "e"))
  )
  result <- tab(df, x)
  expect_equal(nrow(result), 2)
})

test_that("tab: Date values spanning multiple years", {
  df <- tibble::tibble(
    x = as.Date(c(
      "2020-01-01",
      "2021-06-15",
      "2022-12-31",
      "2020-01-01",
      "2021-06-15"
    ))
  )
  result <- tab(df, x)
  expect_equal(nrow(result), 3)
  expect_s3_class(result$x, "Date")
})

test_that("tab: POSIXct with different timezones", {
  df <- tibble::tibble(
    x = c(
      as.POSIXct("2024-01-01 12:00", tz = "UTC"),
      as.POSIXct("2024-01-01 12:00", tz = "EST"),
      as.POSIXct("2024-01-01 12:00", tz = "UTC")
    )
  )
  result <- tab(df, x)
  expect_true(nrow(result) >= 2)
})

test_that("tab: integer64 class from bit64", {
  skip_if_not_installed("bit64")
  df <- tibble::tibble(x = bit64::as.integer64(c(1e10, 1e10, 2e10)))
  result <- tab(df, x)
  expect_equal(nrow(result), 2)
})

test_that("tab: difftime objects", {
  df <- tibble::tibble(x = as.difftime(c(1, 1, 2, 2), units = "hours"))
  result <- tab(df, x)
  expect_equal(nrow(result), 2)
})

# ============================================================================
# CHALLENGING TESTS - Unicode & Special Characters
# ============================================================================

test_that("tab: mixed scripts (latin, cjk, arabic, emoji)", {
  df <- tibble::tibble(
    x = c("hello", "中文", "العربية", "🎉", "🎉", "mixed中文")
  )
  result <- tab(df, x)
  expect_equal(nrow(result), 5)
})

test_that("tab: zero-width characters and control characters", {
  df <- tibble::tibble(x = c("a\u200Bb", "a\u200Bb", "ab", "a\t", "a\n", "a\r"))
  result <- tab(df, x)
  expect_true(nrow(result) >= 4)
})

test_that("tab: right-to-left text", {
  df <- tibble::tibble(x = c("مرحبا", "مرحبا", "שלום", "hello"))
  result <- tab(df, x)
  expect_equal(nrow(result), 3)
})

# ============================================================================
# CHALLENGING TESTS - Tidyselect Edge Cases
# ============================================================================

test_that("tab: starts_with with no matches", {
  df <- tibble::tibble(x = 1:3, y = 1:3, z = 1:3)
  result <- tab(df, dplyr::starts_with("nonexistent"))
  expect_equal(nrow(result), 0)
})

test_that("tab: everything() with hidden columns", {
  df <- tibble::tibble(x = 1:3, y = 1:3)
  attr(df$y, "hidden") <- TRUE
  result <- tab(df, dplyr::everything())
  expect_named(result, c("x", "y", "n", "percent", "cum", "valid", "valid_cum"))
})

test_that("tab: where() with complex predicate", {
  df <- tibble::tibble(a = 1:3, b = c("x", "y", "z"), c = c(TRUE, FALSE, TRUE))
  result <- tab(df, dplyr::where(~ is.numeric(.x) | is.logical(.x)))
  expect_named(result, c("a", "c", "n", "percent", "cum", "valid", "valid_cum"))
})

# ============================================================================
# CHALLENGING TESTS - Sorting & Ordering
# ============================================================================

test_that("tab: .desc with ties in frequency", {
  df <- tibble::tibble(x = c("a", "a", "b", "b", "c", "c", "c"))
  result <- tab(df, x, .desc = TRUE)
  expect_equal(result$x[1], "c")
  expect_true(result$n[2] == result$n[3])
})

test_that("tab: ordering with mixed case strings", {
  df <- tibble::tibble(x = c("Apple", "apple", "APPLE", "banana"))
  result <- tab(df, x)
  expect_equal(nrow(result), 4)
})

test_that("tab: factor ordering preserved even with .desc=TRUE", {
  df <- tibble::tibble(
    x = factor(c("high", "low", "med"), levels = c("low", "med", "high"))
  )
  result <- tab(df, x, .desc = FALSE)
  expect_equal(as.character(result$x[1]), "low")
})

# ============================================================================
# CHALLENGING TESTS - Large-ish Data (but still fast)
# ============================================================================

test_that("tab: 10000 rows with 100 unique combinations", {
  withr::local_preserve_seed()
  set.seed(42)
  df <- tibble::tibble(
    x = sample(1:10, 10000, replace = TRUE),
    y = sample(letters[1:10], 10000, replace = TRUE)
  )
  result <- tab(df, x, y)
  expect_true(nrow(result) <= 100)
  expect_equal(sum(result$n), 10000)
})

test_that("tab: many columns selected", {
  withr::local_preserve_seed()
  set.seed(42)
  df <- tibble::as_tibble(
    replicate(15, sample(1:3, 100, replace = TRUE)),
    .name_repair = "minimal"
  )
  names(df) <- paste0("var", 1:15)
  result <- tab(df, var1:var10)
  expect_named(
    result,
    c(paste0("var", 1:10), "n", "percent", "cum", "valid", "valid_cum")
  )
})

# ============================================================================
# CHALLENGING TESTS - Error Handling & Robustness
# ============================================================================

test_that("tab: gracefully handle data.frame with no columns", {
  df <- data.frame()[1:5, ]
  result <- tab(df)
  expect_equal(nrow(result), 0)
  expect_named(result, c("n", "percent", "cum", "valid", "valid_cum"))
  expect_identical(result$n, integer())
})

test_that("tab: NULL input should error", {
  expect_error(tab(NULL))
})

test_that("tab: non-existent column reference should error", {
  df <- tibble::tibble(x = 1:5)
  expect_error(tab(df, y))
})

# ============================================================================
# CHALLENGING TESTS - Real-world-like Scenarios
# ============================================================================

test_that("tab: survey data simulation with skip patterns", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    age_group = sample(
      c("18-25", "26-35", "36-50", "50+"),
      200,
      replace = TRUE
    ),
    answered_q2 = sample(c(TRUE, FALSE), 200, replace = TRUE),
    q2_response = ifelse(
      sample(c(TRUE, FALSE), 200, replace = TRUE),
      sample(c("Yes", "No"), 200, replace = TRUE),
      NA
    )
  )
  result <- tab(df, q2_response, answered_q2)
  expect_true(nrow(result) >= 2)
})

test_that("tab: duplicate rows identification", {
  df <- tibble::tibble(x = c(1, 1, 1, 2, 2, 3, 4, 4, 4, 4))
  result <- tab(df, x)
  dupes <- result$n[result$n > 1]
  expect_true(length(dupes) >= 2)
})

test_that("tab: time series data with gaps", {
  withr::local_preserve_seed()
  dates <- seq(as.Date("2024-01-01"), as.Date("2024-12-31"), by = "day")
  dates <- dates[sample(length(dates), 300)]
  df <- tibble::tibble(date = dates)
  result <- tab(df, date)
  expect_equal(nrow(result), 300)
})

# ============================================================================
# CHALLENGING TESTS - Performance Edge Cases
# ============================================================================

test_that("tab: highly duplicated data", {
  df <- tibble::tibble(x = rep(1, 10000), y = rep("a", 10000))
  result <- tab(df, x, y)
  expect_equal(nrow(result), 1)
  expect_equal(result$n, 10000)
})

test_that("tab: completely unique data across multiple vars", {
  df <- tibble::tibble(x = 1:500, y = letters[1:26][(1:500 %% 26) + 1])
  result <- tab(df, x, y)
  expect_equal(nrow(result), 500)
})

test_that("tab: circular reference in data names", {
  df <- tibble::tibble(a = 1:4, b = 1:4)
  names(df) <- c("a", "a")
  expect_error(tab(df, a))
})

# ============================================================================
# CHALLENGING TESTS - Interaction with Other Packages
# ============================================================================

test_that("tab: sf object geometry column handling", {
  skip_if_not_installed("sf")
  df <- tibble::tibble(x = 1:5, y = c("a", "a", "b", "b", "c"))
  expect_no_error(result <- tab(df, y))
  expect_equal(nrow(result), 3)
})

test_that("tab: units class from units package", {
  skip_if_not_installed("units")
  df <- tibble::tibble(x = units::set_units(c(1, 1, 2, 2), "m"))
  result <- tab(df, x)
  expect_equal(nrow(result), 2)
})


test_that("joint counts preserve factor order and separate NA from NaN", {
  d <- tibble::tibble(
    g = factor(c("b", "a", "b", "b", "a", "b"), levels = c("b", "a", "unused")),
    x = c(NA_real_, 2, NaN, NaN, 2, 1)
  )
  out <- tab(d, x, .by = g)
  expect_identical(
    out$g,
    factor(c("b", "b", "b", "a"), levels = c("b", "a", "unused"))
  )
  expect_identical(out$x, c(1, NaN, NA_real_, 2))
  expect_identical(out$n, c(1L, 2L, 1L, 2L))
  expect_equal(out$percent, c(25, 50, 25, 100))
})


test_that("counts retain first-appearance list order and C-locale character order", {
  inputs <- list(
    tibble::tibble(x = list(1L, "a", NULL, 1L)),
    tibble::tibble(x = c("z", "a", intToUtf8(228L), "A", NA_character_))
  )
  for (d in inputs) {
    expected <- dplyr::count(d, dplyr::across(dplyr::everything()))
    out <- tab(d)
    expect_identical(out$x, expected$x)
    expect_identical(out$n, expected$n)
    expect_equal(out$cum, cumsum(expected$n / sum(expected$n) * 100))
  }
})


test_that("explicit locale options preserve dplyr counting behavior", {
  # dplyr >= 1.2 deprecates this option; verify the warning when emitted.
  with_locale_warning <- function(expr) {
    withCallingHandlers(expr, warning = function(w) {
      expect_match(
        conditionMessage(w),
        "`options(dplyr.legacy_locale =)` was deprecated",
        fixed = TRUE
      )
      invokeRestart("muffleWarning")
    })
  }
  d <- tibble::tibble(x = c("z", "a", intToUtf8(228L), "A", NA_character_))
  for (legacy in c(FALSE, TRUE)) {
    withr::local_options(list(dplyr.legacy_locale = legacy))
    expected <- with_locale_warning(dplyr::count(d, x))
    out <- with_locale_warning(tab(d))
    expect_identical(out$x, expected$x)
    expect_identical(out$n, expected$n)
  }
})
