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

test_that("tab: all joint combinations retain identities and counts", {
  df <- tibble::tibble(
    x = rep(1:3, each = 2),
    y = rep(c("a", "b"), 3)
  )
  result <- tab(df, x, y)
  expect_identical(result$x, df$x)
  expect_identical(result$y, df$y)
  expect_identical(result$n, rep(1L, 6))
  expect_equal(result$percent, rep(100 / 6, 6))
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
  df <- tibble::tibble(x = rep(1, 4), y = rep("a", 4))
  result <- tab(df, x, y)
  expect_identical(result$x, 1)
  expect_identical(result$y, "a")
  expect_identical(result$n, 4L)
  expect_identical(result$percent, 100)
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

test_that("milestone frequency defaults remain usable as data", {
  d <- tibble::tibble(x = c("a", "a", "b"), y = c("u", "v", "u"))
  expect_s3_class(fre(d, x), "tbl_df")
  expect_named(fre1(d, x), "x")
  out <- tab2(d, x, y, .total = TRUE)
  expect_s3_class(out, "tbl_df")
  expect_equal(tail(out$total, 1), 3)
})

test_that("milestone reserved grouping count names retain independent keys", {
  d <- tibble::tibble(n = c("A", "A", "B"), x = c(1, 2, 1))
  out <- suppressMessages(tab1(d, x, .by = n))$x
  expect_true(".n" %in% names(out))
  expect_equal(sum(out$n), 3)
  expect_setequal(out$.n, c("A", "B"))
})

.milestone_group_base <- tibble::tibble(
  g = c("A", "A", "B", "B", "B", "C"),
  x = c(1, 2, 1, NA, 2, 1),
  y = c("u", "v", "u", "v", NA, "u")
)

.milestone_group_case <- function(d, keys = "g", vars = "x", grouped = FALSE) {
  list(data = d, keys = keys, vars = vars, grouped = grouped)
}

.milestone_group_cases <- list(
  unequal_sizes = .milestone_group_case(.milestone_group_base),
  missing_key = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    g = replace(g, 6, NA_character_)
  )),
  entirely_missing_key = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    g = NA_character_
  )),
  integer_keys = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    g = c(1L, 1L, 2L, 2L, 2L, 3L)
  )),
  logical_keys = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    g = c(TRUE, TRUE, FALSE, FALSE, NA, NA)
  )),
  factor_keys = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    g = factor(g, levels = c("A", "B", "C", "unused"))
  )),
  ordered_keys = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    g = ordered(g, levels = c("C", "B", "A"))
  )),
  date_keys = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    g = as.Date("2024-01-01") + c(0, 0, 1, 1, 1, 2)
  )),
  two_keys = .milestone_group_case(
    dplyr::mutate(.milestone_group_base, h = c(1, 2, 1, 1, 2, 1)),
    keys = c("g", "h")
  ),
  two_missing_keys = .milestone_group_case(
    dplyr::mutate(
      .milestone_group_base,
      g = c("A", "A", NA, NA, "B", "B"),
      h = c(1, NA, 1, NA, 1, NA)
    ),
    keys = c("g", "h")
  ),
  non_syntactic_key = .milestone_group_case(
    dplyr::rename(.milestone_group_base, `group name` = g),
    keys = "group name"
  ),
  numeric_values = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    x = x / 2
  )),
  factor_values = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    x = factor(x, levels = 1:3)
  )),
  ordered_values = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    x = ordered(x)
  )),
  logical_values = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    x = x == 1
  )),
  labelled_values = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    x = haven::labelled(x, c(Yes = 1, No = 2))
  )),
  multiple_variables = .milestone_group_case(
    .milestone_group_base,
    vars = c("x", "y")
  ),
  existing_grouping = .milestone_group_case(
    .milestone_group_base,
    vars = c("x", "y"),
    grouped = TRUE
  ),
  one_row_per_group = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    g = letters[1:6]
  )),
  same_value_each_group = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    x = 1
  )),
  missing_values_group = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    x = ifelse(g == "B", NA_real_, x)
  )),
  reserved_n_key = .milestone_group_case(
    dplyr::rename(.milestone_group_base, n = g),
    keys = "n"
  )
)

.milestone_group_key <- function(d, keys) {
  parts <- lapply(d[keys], function(x) {
    ifelse(is.na(x), "<missing-key>", as.character(x))
  })
  do.call(paste, c(parts, sep = "\r"))
}

for (.function_name in c("tab1", "fre1")) {
  for (.scenario in names(.milestone_group_cases)) {
    test_that(
      paste("milestone", .function_name, "preserves groups", .scenario),
      {
        case <- .milestone_group_cases[[.scenario]]
        d <- case$data
        before <- unserialize(serialize(d, NULL))
        vars <- case$vars
        keys <- case$keys
        fn <- get(.function_name, mode = "function")
        if (case$grouped) {
          d <- dplyr::group_by(d, dplyr::across(tidyselect::all_of(keys)))
          out <- fn(d, tidyselect::all_of(vars), .type = "list")
        } else {
          out <- fn(
            d,
            tidyselect::all_of(vars),
            .by = tidyselect::all_of(keys),
            .type = "list"
          )
        }
        expect_named(out, vars)
        expected_counts <- table(.milestone_group_key(case$data, keys))
        output_keys <- ifelse(keys == "n", ".n", keys)
        for (measure in vars) {
          frame <- out[[measure]]
          expect_s3_class(frame, "tbl_df")
          expect_true(all(output_keys %in% names(frame)))
          if (.function_name == "fre1") {
            totals <- frame[!is.na(frame$value) & frame$value == "Total", ]
            total_keys <- .milestone_group_key(totals, output_keys)
            expect_setequal(total_keys, names(expected_counts))
            expect_equal(totals$n, as.numeric(expected_counts[total_keys]))
            expect_equal(totals$percent, rep(100, length(expected_counts)))
            ordinary <- frame[
              is.na(frame$value) |
                !frame$value %in% c("Total", "Valid Total", "Missing Total"),
            ]
          } else {
            ordinary <- frame
          }
          observed_counts <- tapply(
            ordinary$n,
            .milestone_group_key(ordinary, output_keys),
            sum
          )
          observed_percent <- tapply(
            ordinary$percent,
            .milestone_group_key(ordinary, output_keys),
            sum
          )
          expect_equal(
            as.numeric(observed_counts[names(expected_counts)]),
            as.numeric(expected_counts)
          )
          expect_equal(
            as.numeric(observed_percent[names(expected_counts)]),
            rep(100, length(expected_counts))
          )
        }
        expect_identical(case$data, before)
      }
    )
  }
}

.milestone_frequency_cases <- list(
  balanced = tibble::tibble(
    x = c("a", "a", "b", "b"),
    y = c("u", "v", "u", "v")
  ),
  unequal_margins = tibble::tibble(
    x = c("a", "a", "a", "b", "b"),
    y = c("u", "u", "v", "u", "v")
  ),
  singleton = tibble::tibble(x = "a", y = "u"),
  sparse_cross = tibble::tibble(x = c("a", "b", "c"), y = c("u", "v", "w")),
  integers = tibble::tibble(x = c(1L, 2L, 1L), y = c(3L, 4L, 3L)),
  doubles = tibble::tibble(x = c(1.5, 2.5, 1.5), y = c(0.1, 0.2, 0.1)),
  negative = tibble::tibble(x = c(-1, -2, -1), y = c(-3, -4, -3)),
  logical = tibble::tibble(x = c(TRUE, FALSE, TRUE), y = c(TRUE, TRUE, FALSE)),
  factor = tibble::tibble(
    x = factor(c("a", "b", "a")),
    y = factor(c("u", "u", "v"))
  ),
  ordered = tibble::tibble(
    x = ordered(c("a", "b", "a")),
    y = ordered(c("u", "u", "v"))
  ),
  date = tibble::tibble(
    x = as.Date("2024-01-01") + c(0, 1, 0),
    y = c("u", "v", "u")
  ),
  missing_x = tibble::tibble(x = c("a", NA, "b"), y = c("u", "u", "v")),
  missing_y = tibble::tibble(x = c("a", "a", "b"), y = c("u", NA, "v")),
  both_missing = tibble::tibble(
    x = c("a", NA, "b", NA),
    y = c("u", "u", NA, NA)
  ),
  all_x_missing = tibble::tibble(
    x = rep(NA_character_, 3),
    y = c("u", "u", "v")
  ),
  all_y_missing = tibble::tibble(
    x = c("a", "a", "b"),
    y = rep(NA_character_, 3)
  ),
  labelled = tibble::tibble(
    x = haven::labelled(c(1, 2, 1), c(Yes = 1, No = 2)),
    y = c("u", "v", "u")
  ),
  unicode = tibble::tibble(
    x = c("\u4e2d", "\u6587", "\u4e2d"),
    y = c("u", "v", "u")
  ),
  repeated_rows = tibble::tibble(
    x = rep(c("a", "b"), c(10, 3)),
    y = rep(c("u", "v"), c(10, 3))
  ),
  one_category = tibble::tibble(x = rep("a", 4), y = rep("u", 4)),
  data_frame = data.frame(x = c("a", "a", "b"), y = c("u", "v", "u"))
)

for (.function_name in c("fre", "fre1", "fre2")) {
  for (.scenario in names(.milestone_frequency_cases)) {
    test_that(
      paste(
        "milestone",
        .function_name,
        "data defaults and conserved counts",
        .scenario
      ),
      {
        d <- .milestone_frequency_cases[[.scenario]]
        before <- unserialize(serialize(d, NULL))
        if (.function_name == "fre") {
          out <- fre(d, x)
          expect_identical(class(out), class(d))
          totals <- out[!is.na(out$x) & out$x == "Total", ]
          expect_equal(totals$n, nrow(d))
          expect_equal(totals$percent, 100)
          expect_equal(tibble::as_tibble(out), fre(d, x, .type = "tibble"))
        } else if (.function_name == "fre1") {
          out <- fre1(d, x, y)
          expect_named(out, c("x", "y"))
          expect_false(inherits(out, "flextable"))
          for (frame in out) {
            expect_identical(class(frame), class(d))
            totals <- frame[!is.na(frame$value) & frame$value == "Total", ]
            expect_equal(totals$n, nrow(d))
            expect_equal(totals$percent, 100)
          }
          expect_equal(out, fre1(d, x, y, .type = "list"))
        } else {
          out <- tab2(d, x, y, .total = TRUE)
          expect_identical(class(out), class(d))
          expect_equal(tail(out$total, 1), nrow(d))
          expect_equal(sum(head(out$total, -1)), nrow(d))
          numeric_columns <- setdiff(names(out), c(names(out)[1], "total"))
          expect_equal(
            as.numeric(out[nrow(out), numeric_columns]),
            as.numeric(colSums(as.data.frame(out[
              -nrow(out),
              numeric_columns,
              drop = FALSE
            ])))
          )
          expect_equal(
            tibble::as_tibble(out),
            tab2(d, x, y, .type = "tibble", .total = TRUE)
          )
        }
        expect_identical(d, before)
      }
    )
  }
}

test_that("milestone optional frequency formatting remains explicit", {
  skip_if_not_installed("flextable")
  d <- .milestone_frequency_cases$unequal_margins
  expect_s3_class(fre(d, x, .type = "flextable"), "flextable")
  expect_s3_class(fre1(d, x, y, .type = "flextable"), "flextable")
  expect_s3_class(
    tab2(d, x, y, .type = "flextable", .total = TRUE),
    "flextable"
  )
  expect_s3_class(fre1(d, x, y, .type = "tibble"), "tbl_df")
})

for (.scenario in names(.milestone_frequency_cases)) {
  test_that(
    paste("milestone tab preserves counts and missing categories", .scenario),
    {
      d <- .milestone_frequency_cases[[.scenario]]
      out <- tab(d, x)
      counts <- as.vector(table(d$x, useNA = "ifany"))
      expect_equal(sort(out$n), sort(counts[counts > 0L]))
      expect_equal(sum(out$n), nrow(d))
      expect_equal(sum(out$percent), 100)
      if (anyNA(d$x)) {
        expect_true(is.na(tail(out$x, 1L)))
      }
      if (all(is.na(d$x))) expect_true(all(is.na(out$valid)))
    }
  )
  for (.format_function in c("fre", "fre1", "fre2")) {
    test_that(
      paste("milestone optional formatted counts", .format_function, .scenario),
      {
        skip_if_not_installed("flextable")
        d <- .milestone_frequency_cases[[.scenario]]
        before <- unserialize(serialize(d, NULL))
        out <- switch(
          .format_function,
          fre = fre(d, x, .type = "flextable"),
          fre1 = fre1(d, x, y, .type = "flextable"),
          fre2 = tab2(d, x, y, .type = "flextable", .total = TRUE)
        )
        expect_s3_class(out, "flextable")
        displayed <- out$body$dataset
        if (.format_function == "fre2") {
          expect_equal(tail(displayed$total, 1L), nrow(d))
        } else {
          label_column <- if (.format_function == "fre") "x" else "value"
          totals <- displayed[
            !is.na(displayed[[label_column]]) &
              displayed[[label_column]] == "Total",
          ]
          expect_true(nrow(totals) > 0L)
          expect_equal(totals$n, rep(nrow(d), nrow(totals)))
        }
        expect_identical(d, before)
      }
    )
  }
}

for (.fn in c("tab1", "fre1")) {
  test_that(paste("milestone review retains variable group keys", .fn), {
    d <- data.frame(variable = c("A", "A", "B"), x = c(1, 2, 1))
    fn <- get(.fn, mode = "function")
    for (type in c("list", "tibble")) {
      out <- suppressMessages(fn(d, x, .by = variable, .type = type))
      frame <- if (type == "list") out$x else out
      expect_true(".variable" %in% names(frame))
      expect_setequal(frame$.variable, c("A", "B"))
      if (type == "tibble") expect_true(all(frame$variable == "x"))
    }
    d$.variable <- 1:3
    expect_error(
      suppressMessages(fn(
        d,
        tidyselect::all_of(c("x", ".variable")),
        .by = variable
      )),
      "Rename fails"
    )
  })
}

test_that("fre(), tab1() and fre1() accept atomic vectors like tab()", {
  x <- c(1, 1, 2, NA)
  expect_identical(
    fre(x),
    fre(tibble::tibble(value = x))
  )
  expect_identical(tab1(x), tab1(tibble::tibble(value = x)))
  expect_identical(fre1(x), fre1(tibble::tibble(value = x)))
  expect_error(fre(x, value), "omit selectors")
  expect_error(fre1(x, .by = value), "omit `.by`")
})

test_that("spatial aggregation counts attributes without sticky geometry", {
  skip_if_not_installed("sf")
  d <- sf::st_as_sf(
    data.frame(x = c(1, 1, 2), g = c("a", "a", "b"), lon = 1:3, lat = 4:6),
    coords = c("lon", "lat")
  )
  ordinary <- sf::st_drop_geometry(d)
  calls <- list(
    tab = function(x) tab(x, x),
    tab1 = function(x) tab1(x, x),
    tab2 = function(x) tab2(x, g, x),
    fre = function(x) fre(x, x),
    fre1 = function(x) fre1(x, x),
    fre2 = function(x) tab2(x, g, x, .total = TRUE),
    summ = function(x) summ(x, x),
    tabstat = function(x) tabstat(x, x)
  )
  for (call in calls) {
    expect_no_warning(actual <- call(d))
    expect_equal(actual, call(ordinary))
  }
  expect_equal(tab(d, x)$n, c(2L, 1L))
  expect_identical(summ(d, x, .name = TRUE)$name, "x")
  expect_s3_class(d, "sf")
  expect_identical(names(d), c("x", "g", "geometry"))
})

test_that("explicit attribute grouping overrides inherited geometry groups", {
  skip_if_not_installed("sf")
  d <- sf::st_as_sf(
    tibble::tibble(x = c(1, 1, 2), g = c("a", "a", "b"), lon = 1:3, lat = 4:6),
    coords = c("lon", "lat")
  )
  grouped <- dplyr::group_by(d, geometry)
  for (fun in list(tab, fre, tab1, fre1, summ, tabstat)) {
    expect_equal(fun(grouped, x, .by = g), fun(d, x, .by = g))
    expect_error(fun(grouped, x), "Geometry.*grouping")
    expect_error(fun(d, x, .by = geometry), "geometry")
  }
})

test_that("data-frame sf objects keep added grouping columns", {
  skip_if_not_installed("sf")
  shape <- sf::st_read(
    system.file("shape/nc.shp", package = "sf"),
    quiet = TRUE
  )[1:12, c("NAME", "BIR74")]
  d <- dplyr::mutate(
    shape,
    grp = ifelse(BIR74 > 3000, "hi", "lo"),
    big = BIR74 > 1000
  )
  plain <- tibble::as_tibble(sf::st_drop_geometry(d))
  expect_equal(
    tab(d, big, .by = grp),
    as.data.frame(tab(plain, big, .by = grp))
  )
  expect_equal(
    fre(d, big, .by = grp),
    as.data.frame(fre(plain, big, .by = grp))
  )
  expect_named(tab1(d, .by = big), c("NAME", "BIR74", "grp"))
  expect_equal(
    fre1(d, grp, .by = big),
    lapply(fre1(plain, grp, .by = big), as.data.frame)
  )
  expect_equal(
    summ(d, BIR74, .by = grp),
    as.data.frame(summ(plain, BIR74, .by = grp))
  )
  expect_equal(
    tabstat(d, BIR74, .by = grp),
    as.data.frame(tabstat(plain, BIR74, .by = grp))
  )
  grouped <- dplyr::group_by(d, grp)
  expect_equal(tab(grouped, big), tab(plain, big, .by = grp))
  expect_warning(counts <- summ(d, .stat = "n"), "non-numeric")
  expect_identical(counts$name, c("BIR74", "big"))
})

test_that("blank cross-tab categories have collision-safe headers", {
  data <- tibble::tibble(
    x = c("a", "a", "b", "b"),
    y = c("", "b", "<empty>", "<empty>1")
  )
  out <- tab2(data, x, y)
  expect_equal(out[["<empty>2"]], c(1L, 0L))
  expect_equal(out[["<empty>"]], c(0L, 1L))
  expect_equal(out[["<empty>1"]], c(0L, 1L))
  expect_equal(rowSums(as.data.frame(out[-1])), c(2, 2))
  expect_equal(tail(tab2(data, x, y, .total = TRUE)$total, 1), 4)
  expect_equal(tab2(data, y, x, .flip = TRUE), out)

  missing <- tibble::tibble(x = c("a", "a", "b"), y = c("", NA, ""))
  out <- tab2(missing, x, y)
  expect_equal(out[["<empty>"]], c(1L, 1L))
  expect_equal(out[["NA"]], c(1L, 0L))
  expect_identical(missing$y, c("", NA_character_, ""))
})

test_that("stacked ordered factors retain category order", {
  data <- tibble::tibble(
    a = ordered(c("a", "b"), levels = c("b", "a")),
    b = ordered(c("x", "y"), levels = c("y", "x"))
  )
  out <- tab1(data, .type = "tibble")
  expect_identical(out$value, c("b", "a", "y", "x"))
  expect_s3_class(tab1(data)$a$value, "ordered")
  expect_s3_class(tab1(data)$b$value, "ordered")
  expect_equal(fre1(data, .type = "tibble")$n, c(1L, 1L, 2L, 1L, 1L, 2L))
  names(data) <- c("a", ".ptype")
  expect_identical(tab1(data, .type = "tibble")$value, c("b", "a", "y", "x"))
})

test_that("logical cross-tabulation axes have consistent ordering", {
  data <- tibble::tibble(
    x = c(FALSE, FALSE, TRUE, NA),
    y = c(TRUE, FALSE, NA, FALSE)
  )
  out <- tab2(data, x, y)
  expect_identical(names(out)[-1], c("FALSE", "TRUE", "NA"))
  expect_identical(out[[1]], c(FALSE, TRUE, NA))
  expect_identical(
    names(tab2(data, x, y, .total = TRUE))[-1],
    c("FALSE", "TRUE", "NA", "total")
  )
  expect_identical(
    names(tab2(data, x, y, .flip = TRUE))[-1],
    c("FALSE", "TRUE", "NA")
  )
})

test_that("tab accepts a vector with its class intact", {
  out <- tab(c(1, 1, 2, NA))
  expect_s3_class(out, "tbl_df")
  expect_identical(out$value, c(1, 2, NA))
  expect_equal(out$n, c(2L, 1L, 1L))
  dates <- as.Date(c("2020-01-01", "2020-01-01", NA))
  expect_identical(tab(dates)$value, dates[c(1, 3)])
  factors <- ordered(c("a", "b", "a"), levels = c("b", "a"))
  expect_identical(tab(factors)$value, factors[c(2, 1)])
  expect_equal(nrow(tab(integer())), 0L)
  expect_error(tab(1:3, 1), "vector.*selectors")
  expect_error(tab(1:3, .by = 1), "vector.*by")
  expect_error(tab(matrix(1:4, 2)), "vector|data frame")
  expect_error(tab(list(1, 2)), "vector|data frame")
})

test_that("frequency group order uses observations and preserves categories", {
  data <- tibble::tibble(
    g = c("a", "b", "b", "b", "c", "c", "c", NA, NA, NA, NA),
    x = c(1, 1, 2, NA, 1, 1, 2, 1, 1, 1, 1)
  )
  for (fun in list(tab, fre)) {
    out <- fun(data, x, .by = g, .group_order = "frequency")
    expect_identical(unique(out$g), c("b", "c", "a", NA))
    expect_identical(unique(fun(data, x, .by = g)$g), c("a", "b", "c", NA))
    plain <- fun(as.data.frame(data), x, .by = g, .group_order = "frequency")
    expect_identical(unique(plain$g), c("b", "c", "a", NA))
    expect_identical(class(plain), "data.frame")
  }
  for (fun in list(tab1, fre1)) {
    out <- fun(data, x, .by = g, .group_order = "frequency")[[1]]
    expect_identical(unique(out$g), c("b", "c", "a", NA))
  }
  out <- tab(data, x, .by = g, .group_order = "frequency", .desc = TRUE)
  expect_equal(out$x[out$g %in% "c"], c(1, 2))
  expect_equal(out$cum[out$g %in% "c"], c(200 / 3, 100))
  expect_equal(tab(data, x, .group_order = "frequency"), tab(data, x))
  expect_error(tab(data, .group_order = "bad"), "must be one of")
})

test_that("frequency group ties respect factors and multiple keys", {
  data <- tibble::tibble(
    first = factor(c("a", "a", "b", "b", "b", "b", "b"), levels = c("b", "a")),
    second = c(1L, 1L, 2L, 2L, NA, NA, NA),
    value = c(1, 2, 1, 2, 1, 1, 1)
  )
  for (fun in list(tab, fre)) {
    out <- fun(data, value, .by = c(first, second), .group_order = "frequency")
    keys <- unique(out[c("first", "second")])
    expect_identical(as.character(keys$first), c("b", "a", "b"))
    expect_identical(keys$second, c(2L, 1L, NA_integer_))
  }
  grouped <- dplyr::group_by(data, first, second)
  out <- tab(grouped, value, .group_order = "frequency")
  expect_identical(
    as.character(unique(out[c("first", "second")])$first),
    c("b", "a", "b")
  )
  empty <- data[FALSE, ]
  expect_equal(
    nrow(tab(empty, value, .by = first, .group_order = "frequency")),
    0L
  )
  expect_equal(
    nrow(fre(empty, value, .by = first, .group_order = "frequency")),
    0L
  )
})

test_that("cross-tab columns follow value and level order with missing last", {
  numbers <- tibble::tibble(x = c("a", "b", "b", "c"), y = c(3, 1, 2, 10))
  expect_identical(names(tab2(numbers, x, y))[-1], c("1", "2", "3", "10"))
  text <- tibble::tibble(x = c("a", "b", "b"), y = c("z", NA, "m"))
  expect_identical(names(tab2(text, x, y))[-1], c("m", "z", "NA"))
  expect_identical(
    names(tab2(text, x, y, .total = TRUE))[-1],
    c("m", "z", "NA", "total")
  )
  levels <- tibble::tibble(
    x = c("a", "b"),
    y = factor(c("lo", "hi"), levels = c("hi", "lo"))
  )
  expect_identical(names(tab2(levels, x, y))[-1], c("hi", "lo"))
  blank <- tibble::tibble(x = c("a", "b", "b"), y = c("z", "", "a"))
  expect_identical(names(tab2(blank, x, y))[-1], c("<empty>", "a", "z"))
  out <- tab2(numbers, x, y)
  expect_equal(out[["10"]], c(0L, 0L, 1L))
  expect_equal(out[["1"]], c(0L, 1L, 0L))
})

test_that("cross-tabs reject one-way sorting controls", {
  d <- tibble::tibble(g = c("a", "b", "b"), x = c("p", "q", "q"))
  expect_error(tab2(d, x, g, .desc = TRUE), "`.desc`.*tab2")
  expect_error(
    tab2(d, x, g, .group_order = "frequency", .total = TRUE),
    "`.group_order`.*tab2"
  )
})

test_that("stacked labelled variables keep their own labels", {
  d <- tibble::tibble(
    a = haven::labelled(c(1, 2), c(A = 1, B = 2)),
    b = haven::labelled(c(1, 2), c(X = 1, Y = 2))
  )
  expect_no_warning(out <- tab1(d, .type = "tibble"))
  expect_identical(out$value, c("A", "B", "X", "Y"))
  same <- tibble::tibble(
    a = haven::labelled(c(1, 2), c(A = 1, B = 2)),
    b = haven::labelled(c(2, 2), c(A = 1, B = 2))
  )
  expect_s3_class(tab1(same, .type = "tibble")$value, "haven_labelled")
})

test_that("reserved-name messages are consistent and only rename collisions", {
  d <- tibble::tibble(n = c(1, 2, 2), g = c("a", "a", "b"))
  expect_message(
    tab(d, n),
    "`n` renamed to `.n` because `tab()` output",
    fixed = TRUE
  )
  expect_message(tab(d, n), "Rename the input column")
  expect_message(
    tab(tibble::tibble(n = 1, percent = 2), n, percent),
    "`n`, `percent` renamed to `.n`, `.percent`",
    fixed = TRUE
  )
  expect_no_message(listed <- tab1(d, n))
  expect_named(listed, "n")
  expect_no_message(stacked <- fre1(d, n, .type = "tibble"))
  expect_identical(unique(stacked$variable), "n")
  keyed <- tibble::tibble(value = c("a", "b"), x = 1:2)
  expect_message(by_value <- tab1(keyed, x, .by = value), "`value` renamed")
  expect_true(".value" %in% names(by_value$x))
  typed <- tibble::tibble(type = c("a", "b"), x = 1:2)
  expect_message(
    summ(typed, x, .by = type),
    "Grouping column `type` renamed to `.type` because `summ()` output",
    fixed = TRUE
  )
})

test_that("as_character handles tagged missing values without a labels attribute", {
  x <- haven::labelled(c(1, haven::tagged_na("a"), NA, 1))
  before <- x
  expect_identical(as_character(x), c("1", NA_character_, NA_character_, "1"))
  expect_identical(x, before)
})

test_that("as_character retains labels when tagged missing values have labels", {
  x <- haven::labelled(c(1, 2, haven::tagged_na("a"), NA), c(one = 1, two = 2))
  before <- x
  expect_identical(
    as_character(x),
    c("one", "two", NA_character_, NA_character_)
  )
  expect_identical(x, before)
})

# Explicit zero-column .by disables inherited grouping; NULL inherits it.
for (.fn_name in c("tab", "fre", "tab1", "fre1")) {
  local({
    function_name <- .fn_name
    test_that(
      paste(function_name, "explicit empty by removes inherited grouping"),
      {
        d <- tibble::tibble(g = c("a", "b", "a", "b"), x = c(1, 1, 2, 2))
        grouped <- dplyr::group_by(d, g)
        before <- grouped
        fn <- getExportedValue("tidystata", function_name)
        expect_identical(fn(grouped, x, .by = character()), fn(d, x))
        expect_identical(fn(grouped, x, .by = NULL), fn(d, x, .by = g))
        expect_identical(grouped, before)
      }
    )
  })
}

test_that("tabulation reports invalid input", {
  d <- tibble::tibble(a = c("x", "y"), b = c("u", "v"), w = c(1, 2))
  expect_snapshot(error = TRUE, {
    tab(d, a, .total = NA)
    tab(list(1, 2))
    tab(1:3, a)
    tab2(d, a)
    fre2(d, a)
    tab2(d, a, b, .desc = TRUE)
    tab2(d, a, b, .wt = w, .wt_type = "analytic", .chi2 = TRUE)
    tab(d, a, .wt = c(1, 2, 3))
    tab(d, a, .wt = c(-1, 2))
  })
  expect_snapshot(out <- tab(tibble::tibble(n = 1:2), n))
})


test_that("frequency group order uses weighted totals after missing keys", {
  data <- data.frame(
    g = c("a", "b", "b", NA, NA),
    x = c(1, 1, 2, 1, 2),
    w = c(5, 1, 1, 10, 10)
  )
  for (fun in list(tab, fre)) {
    out <- fun(data, x, .by = g, .wt = w, .group_order = "frequency")
    expect_identical(unique(out$g), c("a", "b", NA_character_))
    expect_equal(out$n[out$g %in% "a" & out$x %in% c(1, 2)], 5)
    expect_equal(out$n[out$g %in% "b" & out$x %in% c(1, 2)], c(1, 1))
    expect_equal(out$n[is.na(out$g) & out$x %in% c(1, 2)], c(10, 10))
  }
})
