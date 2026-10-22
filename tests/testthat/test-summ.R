# Comprehensive Challenging Test Suite for summ() and tabstat() Functions
# 70+ difficult test scenarios - focusing on edge cases, complexity, and robustness
# All tests designed to run in < 1 minute

# CHALLENGE: Comprehensive testing for summ, tabstat
# FUNCTIONS: summ, tabstat
# KEY BEHAVIORS: summary statistics, group analysis
# EDGE CASES: empty groups, all-NA columns

# ============================================================================
# CHALLENGING TESTS - Output Mode Variations
# ============================================================================

test_that("summ: list mode with multiple variable types", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    numeric_var = rnorm(100),
    date_var = seq(as.Date("2024-01-01"), by = "day", length.out = 100),
    datetime_var = seq(as.POSIXct("2024-01-01"), by = "hour", length.out = 100),
    char_var = sample(letters[1:5], 100, replace = TRUE)
  )
  expect_warning(result <- summ(df, .type = "list"), "char_var.*non-numeric")
  expect_type(result, "list")
})

test_that("summ: table mode with date variables", {
  df <- tibble::tibble(
    x = 1:50,
    start_date = seq(as.Date("2024-01-01"), by = "day", length.out = 50),
    end_date = seq(as.Date("2024-03-01"), by = "day", length.out = 50)
  )
  result <- summ(df, start_date, end_date, .type = "table")
  expect_s3_class(result, "data.frame")
})

test_that("summ: duration format long vs compact", {
  df <- tibble::tibble(
    dates = seq(as.Date("2024-01-01"), by = "day", length.out = 100)
  )
  result_long <- summ(df, dates, .type = "table", .duration_format = "long")
  result_compact <- summ(
    df,
    dates,
    .type = "table",
    .duration_format = "compact"
  )
  expect_s3_class(result_long, "data.frame")
  expect_s3_class(result_compact, "data.frame")
})

# ============================================================================
# CHALLENGING TESTS - .stat Parameter Variations
# ============================================================================

test_that("summ: single statistic selection", {
  withr::local_preserve_seed()
  df <- tibble::tibble(x = rnorm(100), y = rnorm(100))
  result <- summ(df, .stat = "mean")
  expect_true(all(c("mean") %in% names(result)))
})

test_that("summ: multiple statistics selection", {
  withr::local_preserve_seed()
  df <- tibble::tibble(x = rnorm(100), y = rnorm(100))
  result <- summ(df, .stat = c("mean", "sd", "min", "max"))
  expect_true(all(c("mean", "sd", "min", "max") %in% names(result)))
})

test_that("summ: all available statistics", {
  withr::local_preserve_seed()
  df <- tibble::tibble(x = rnorm(100))
  result <- summ(
    df,
    .stat = c("n", "missing", "mean", "sd", "min", "p25", "p50", "p75", "max")
  )
  expect_true(ncol(result) >= 9)
})

test_that("tabstat: default mean statistic", {
  withr::local_preserve_seed()
  df <- tibble::tibble(x = rnorm(100), y = rnorm(100))
  result <- tabstat(df, x, y)
  expect_true("mean" %in% names(result))
})

test_that("tabstat: custom statistics", {
  df <- tibble::tibble(x = 1:100, y = 101:200)
  result <- tabstat(df, x, y, .stat = c("sum", "mean", "sd"))
  expect_true(all(c("sum", "mean", "sd") %in% names(result)))
})

# ============================================================================
# CHALLENGING TESTS - Grouping with .by
# ============================================================================

test_that("summ: group by single variable", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    group = rep(c("A", "B", "C"), each = 33)[1:99],
    x = rnorm(99),
    y = rnorm(99)
  )
  result <- summ(df, x, y, .by = group)
  expect_true("group" %in% names(result))
  expect_equal(dplyr::n_distinct(result$group), 3)
})

test_that("summ: group by multiple variables", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    g1 = rep(c("X", "Y"), 50),
    g2 = rep(c("A", "B", "C", "D"), 25),
    value = rnorm(100)
  )
  result <- summ(df, value, .by = c(g1, g2))
  expect_true(all(c("g1", "g2") %in% names(result)))
})

test_that("summ: group with many groups", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    group = rep(1:50, each = 2),
    x = rnorm(100)
  )
  result <- summ(df, x, .by = group)
  expect_equal(nrow(result), 50)
})

test_that("summ: group with NA in grouping variable", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    group = c(rep("A", 30), rep(NA, 40), rep("B", 30)),
    x = rnorm(100)
  )
  result <- summ(df, x, .by = group)
  expect_true(any(is.na(result$group)))
})

test_that("summ: .na.rm=TRUE removes NA groups", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    group = c(rep("A", 50), rep(NA, 50)),
    x = rnorm(100)
  )
  result <- summ(df, x, .by = group, .missing = FALSE)
  expect_false(any(is.na(result$group)))
  expect_equal(nrow(result), 1)
})

test_that("summ: group where some groups have 1 observation", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    group = 1:100,
    x = rnorm(100)
  )
  result <- summ(df, x, .by = group)
  expect_equal(nrow(result), 100)
  expect_true(all(result$n == 1))
})

# ============================================================================
# CHALLENGING TESTS - .detail Mode
# ============================================================================

test_that("summ: detail mode with numeric variables", {
  withr::local_preserve_seed()
  df <- tibble::tibble(x = rnorm(100), y = rnorm(100))
  result <- summ(df, .detail = TRUE)
  expect_true("detail" %in% names(result) || ncol(result) > 5)
})

test_that("summ: detail mode with dates", {
  df <- tibble::tibble(
    dates = seq(as.Date("2024-01-01"), by = "day", length.out = 365)
  )
  result <- summ(df, dates, .detail = TRUE)
  expect_s3_class(result, "data.frame")
})

test_that("summ: detail mode with grouped data", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    group = rep(c("A", "B"), each = 50),
    x = rnorm(100)
  )
  result <- summ(df, x, .by = group, .detail = TRUE)
  expect_equal(nrow(result), 2)
})

# ============================================================================
# CHALLENGING TESTS - Missing Value Handling
# ============================================================================

test_that("summ: variables with varying missing percentages", {
  df <- tibble::tibble(
    complete = 1:100,
    ten_pct = c(1:90, rep(NA, 10)),
    fifty_pct = c(1:50, rep(NA, 50)),
    ninety_pct = c(1:10, rep(NA, 90)),
    all_missing = rep(NA, 100)
  )
  expect_warning(result <- summ(df), "all_missing.*entirely missing")
  expect_true("missing" %in% names(result) || "n" %in% names(result))
})

test_that("summ: all NA variable handling", {
  df <- tibble::tibble(x = rep(NA, 100))
  expect_warning(result <- summ(df), "x.*entirely missing")
  expect_equal(nrow(result), 1)
})

test_that("summ: NaN vs NA handling", {
  df <- tibble::tibble(x = c(1, 2, NaN, NaN, NA, NA, 3, 4))
  result <- summ(df)
  expect_true("missing" %in% names(result) || "n" %in% names(result))
})

test_that("summ: Inf values in calculations", {
  df <- tibble::tibble(x = c(1, 2, 3, Inf, -Inf))
  result <- summ(df)
  expect_true("mean" %in% names(result) || "min" %in% names(result))
})

# ============================================================================
# CHALLENGING TESTS - Special Numeric Values
# ============================================================================

test_that("summ: extreme numeric values", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    normal = rnorm(100),
    large = c(.Machine$double.xmax / 1e10, rep(1e100, 99)),
    small = c(.Machine$double.xmin * 1e10, rep(1e-100, 99))
  )
  result <- summ(df)
  expect_equal(nrow(result), 3)
})

test_that("summ: integer overflow edge case", {
  df <- tibble::tibble(
    x = c(.Machine$integer.max, .Machine$integer.max - 1, 1, 2)
  )
  result <- summ(df)
  expect_true("max" %in% names(result))
})

test_that("summ: very small variance dataset", {
  df <- tibble::tibble(x = c(1, 1.0000001, 0.9999999, 1.0000002, 0.9999998))
  result <- summ(df)
  expect_true("sd" %in% names(result))
})

test_that("summ: dataset with exact zero variance", {
  df <- tibble::tibble(x = rep(5, 100))
  result <- summ(df)
  if ("sd" %in% names(result)) {
    expect_equal(result$sd, 0)
  }
})

# ============================================================================
# CHALLENGING TESTS - Variable Selection
# ============================================================================

test_that("summ: starts_with selection", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    temp_1 = rnorm(50),
    temp_2 = rnorm(50),
    pressure_1 = rnorm(50),
    pressure_2 = rnorm(50)
  )
  result <- summ(df, dplyr::starts_with("temp_"))
  expect_equal(nrow(result), 2)
})

test_that("summ: ends_with selection", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    var_a_test = rnorm(50),
    var_b_test = rnorm(50),
    var_c_prod = rnorm(50)
  )
  result <- summ(df, dplyr::ends_with("_test"))
  expect_equal(nrow(result), 2)
})

test_that("summ: contains selection", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    temp_morning = rnorm(50),
    temp_evening = rnorm(50),
    pressure_temp = rnorm(50),
    humidity = rnorm(50)
  )
  result <- summ(df, dplyr::contains("temp"))
  expect_equal(nrow(result), 3)
})

test_that("summ: where() with is.numeric", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    num1 = rnorm(50),
    num2 = rnorm(50),
    char = sample(letters, 50, replace = TRUE),
    logi = sample(c(TRUE, FALSE), 50, replace = TRUE)
  )
  result <- summ(df, dplyr::where(is.numeric))
  expect_equal(nrow(result), 2)
})

test_that("summ: numeric column indices", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    a = rnorm(50),
    b = rnorm(50),
    c = rnorm(50),
    d = rnorm(50),
    e = rnorm(50)
  )
  result <- summ(df, 1, 3, 5)
  expect_equal(nrow(result), 3)
})

# ============================================================================
# CHALLENGING TESTS - Date and Time Variables
# ============================================================================

test_that("summ: Date variables spanning years", {
  df <- tibble::tibble(
    dates = seq(as.Date("2020-01-01"), as.Date("2024-12-31"), by = "day")
  )
  result <- summ(df, dates)
  expect_s3_class(result, "data.frame")
})

test_that("summ: POSIXct with different timezones", {
  df <- tibble::tibble(
    utc_time = as.POSIXct("2024-01-01 12:00", tz = "UTC"),
    est_time = as.POSIXct("2024-01-01 07:00", tz = "EST")
  )
  result <- summ(df)
  expect_s3_class(result, "data.frame")
})

test_that("summ: datetime variables in list mode", {
  df <- tibble::tibble(
    timestamps = seq(as.POSIXct("2024-01-01"), by = "hour", length.out = 100)
  )
  result <- summ(df, .type = "list")
  expect_type(result, "list")
})

test_that("summ: difftime objects", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    duration = as.difftime(rnorm(100, mean = 24, sd = 5), units = "hours")
  )
  result <- summ(df)
  expect_s3_class(result, "data.frame")
})

# ============================================================================
# CHALLENGING TESTS - Data Type Variations
# ============================================================================

test_that("summ: haven labelled numeric", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    x = haven::labelled(rnorm(100), labels = c("Low" = -1, "High" = 1))
  )
  expect_warning(result <- summ(df, x), "x.*labelled variable")
  expect_s3_class(result, "data.frame")
})

test_that("summ: integer vs double distinction", {
  df <- tibble::tibble(
    int_col = as.integer(1:100),
    dbl_col = as.double(1:100) + 0.5
  )
  result <- summ(df)
  expect_equal(nrow(result), 2)
})

test_that("summ: logical variables converted to numeric", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    bool = sample(c(TRUE, FALSE), 100, replace = TRUE)
  )
  result <- summ(df)
  expect_s3_class(result, "data.frame")
})

# ============================================================================
# CHALLENGING TESTS - Vector Input
# ============================================================================

test_that("summ: numeric vector input", {
  withr::local_preserve_seed()
  x <- rnorm(100)
  result <- summ(x)
  expect_s3_class(result, "data.frame")
})

test_that("summ: integer vector input", {
  x <- as.integer(1:100)
  result <- summ(x)
  expect_s3_class(result, "data.frame")
})

test_that("summ: Date vector input", {
  x <- seq(as.Date("2024-01-01"), by = "day", length.out = 100)
  result <- summ(x)
  expect_s3_class(result, "data.frame")
})

# ============================================================================
# CHALLENGING TESTS - Large-ish Datasets
# ============================================================================

test_that("summ: multiple variables retain identities and statistics", {
  df <- tibble::tibble(x = 1:3, y = c(2, NA, 6), z = c(-1, 0, 1))
  result <- summ(df, .stat = c("n", "mean", "sum"))
  expect_identical(result$name, c("x", "y", "z"))
  expect_equal(result$n, c(3, 2, 3))
  expect_equal(result$mean, c(2, 4, 0))
  expect_equal(result$sum, c(6, 8, 0))
})

test_that("summ: many variables (50+)", {
  df <- tibble::as_tibble(replicate(50, 1:3), .name_repair = "minimal")
  names(df) <- paste0("var", 1:50)
  result <- summ(df)
  expect_identical(result$name, names(df))
  expect_equal(result$n, rep(3, 50))
  expect_equal(result$mean, rep(2, 50))
})

test_that("summ: grouped data with many groups", {
  df <- tibble::tibble(group = rep(1:100, each = 2), x = rep(c(1, 3), 100))
  result <- summ(df, x, .by = group)
  expect_identical(result$group, 1:100)
  expect_equal(result$n, rep(2, 100))
  expect_equal(result$mean, rep(2, 100))
})

# ============================================================================
# CHALLENGING TESTS - Error Handling
# ============================================================================

test_that("summ: empty data frame with columns", {
  df <- tibble::tibble(x = numeric(0), y = numeric(0))
  result <- summ(df)
  expect_s3_class(result, "data.frame")
})

test_that("summ: NULL input should error", {
  expect_error(summ(NULL))
})

test_that("summ: character only data frame should error or skip", {
  df <- tibble::tibble(x = letters[1:10], y = letters[11:20])
  expect_warning(expect_error(summ(df)), "non-numeric")
})

test_that("summ: non-existent column should error", {
  withr::local_preserve_seed()
  df <- tibble::tibble(x = rnorm(10))
  expect_error(summ(df, y))
})

# ============================================================================
# CHALLENGING TESTS - .name Parameter
# ============================================================================

test_that("summ: .name=FALSE with single variable", {
  withr::local_preserve_seed()
  df <- tibble::tibble(x = rnorm(100))
  result <- summ(df, .name = FALSE)
  expect_false("name" %in% names(result))
})

test_that("summ: .name=TRUE with single variable", {
  withr::local_preserve_seed()
  df <- tibble::tibble(x = rnorm(100))
  result <- summ(df, .name = TRUE)
  expect_true("name" %in% names(result))
})

test_that("summ: .name=FALSE with multiple variables", {
  withr::local_preserve_seed()
  df <- tibble::tibble(x = rnorm(100), y = rnorm(100))
  result <- summ(df, .name = FALSE)
  expect_true("name" %in% names(result))
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("summ: clinical measurements", {
  withr::local_preserve_seed()
  set.seed(42)
  df <- tibble::tibble(
    patient_id = 1:200,
    age = sample(18:90, 200, replace = TRUE),
    systolic_bp = rnorm(200, mean = 120, sd = 15),
    diastolic_bp = rnorm(200, mean = 80, sd = 10),
    heart_rate = rnorm(200, mean = 72, sd = 12),
    cholesterol = rnorm(200, mean = 200, sd = 40),
    treatment = sample(c("Drug", "Placebo"), 200, replace = TRUE)
  )
  result <- summ(df, age:cholesterol, .by = treatment)
  expect_true("treatment" %in% names(result))
  expect_true(nrow(result) >= 10)
})

test_that("summ: financial time series", {
  withr::local_preserve_seed()
  set.seed(123)
  df <- tibble::tibble(
    date = seq(as.Date("2024-01-01"), by = "day", length.out = 252),
    open_price = cumsum(rnorm(252, mean = 0.1, sd = 2)) + 100,
    high_price = cumsum(rnorm(252, mean = 0.1, sd = 2)) + 102,
    low_price = cumsum(rnorm(252, mean = 0.1, sd = 2)) + 98,
    close_price = cumsum(rnorm(252, mean = 0.1, sd = 2)) + 101,
    volume = sample(1e6:1e9, 252, replace = TRUE)
  )
  result <- summ(df, open_price:volume)
  expect_equal(nrow(result), 5)
})

test_that("summ: survey data with grouping", {
  withr::local_preserve_seed()
  set.seed(456)
  df <- tibble::tibble(
    region = sample(c("North", "South", "East", "West"), 1000, replace = TRUE),
    age = sample(18:80, 1000, replace = TRUE),
    income = rnorm(1000, mean = 50000, sd = 20000),
    satisfaction = sample(1:10, 1000, replace = TRUE),
    spending = rnorm(1000, mean = 2000, sd = 800)
  )
  result <- summ(df, age:spending, .by = region, .stat = c("mean", "sd"))
  expect_equal(dplyr::n_distinct(result$region), 4)
})

test_that("summ: quality control data", {
  withr::local_preserve_seed()
  set.seed(789)
  df <- tibble::tibble(
    batch_id = rep(1:20, each = 50),
    measurement_1 = rnorm(1000, mean = 100, sd = 5),
    measurement_2 = rnorm(1000, mean = 50, sd = 3),
    defect_rate = runif(1000, 0, 0.1)
  )
  result <- summ(df, measurement_1:defect_rate, .by = batch_id)
  expect_equal(nrow(result), 60)
})

# ============================================================================
# CHALLENGING TESTS - data.table Input
# ============================================================================

test_that("summ: data.table input conversion", {
  withr::local_preserve_seed()
  skip_if_not_installed("data.table")
  df <- data.table::data.table(
    x = rnorm(100),
    y = rnorm(100),
    group = rep(c("A", "B"), 50)
  )
  result <- summ(df, x, y, .by = group)
  expect_s3_class(result, "data.frame")
})

test_that("summ: data.table input with table mode", {
  withr::local_preserve_seed()
  skip_if_not_installed("data.table")
  df <- data.table::data.table(
    x = rnorm(100),
    y = rnorm(100)
  )
  result <- summ(df, x, y, .type = "table")
  expect_s3_class(result, "data.frame")
})

test_that("summary historical missingness and type cases stay supported", {
  d <- tibble::tibble(type = c("a", "a", NA), x = c(1, NA, 3))
  expect_message(out <- summ(d, x, .by = type), "type")
  expect_equal(out$n, c(1, 1))
  expect_message(clean <- summ(d, x, .by = type, .missing = FALSE), "type")
  expect_equal(clean$n, 1)
  result <- summ(c(-Inf, 1, 2, Inf))
  expect_equal(result$n, 4)
  expect_identical(result$min, -Inf)
  expect_identical(result$max, Inf)
  expect_true(is.nan(result$mean))
  expect_equal(summ(c(1, NA, 2), .stat = "sum")$sum, 3)
  expect_false("name" %in% names(summ(1:3, .name = FALSE)))
  dates <- as.POSIXct(c("2024-01-01", "2024-01-02"), tz = "UTC")
  calendar <- summ(dates)
  expect_match(calendar$mean, "2024-01-01 12:00")
  expect_identical(units(calendar$sd), "hours")
  grouped <- dplyr::group_by(tibble::tibble(g = c("b", "a"), x = 1:2), g)
  expect_message(summ(grouped, x), NA)
})

test_that("named constants are computed and grouping keys are never measured", {
  tb <- tibble::tibble(
    girl = c(0, 1, 0, 1),
    ca3_2 = c("a", "a", "b", "b"),
    score = c(10, 20, 30, 40)
  )
  out <- summ(tb, one = 1, .by = c(girl, ca3_2))
  expect_identical(out$mean, rep(1, 4))
  expect_identical(out$n, rep(1L, 4))
  expect_identical(nrow(tab(tb, constant = "x")), 1L)
  expect_identical(tab(tb, constant = "x")$n, 4L)
  expect_identical(names(s_select(tb, one = 1)), "one")
  expect_identical(s_select(tb, one = 1)$one, rep(1, 4))
  expect_error(summ(tb, other = girl, .by = girl), "Grouping column `girl`")
  expect_error(tab(tb, other = girl, .by = girl), "Grouping column `girl`")
  kept <- summ(tb, tidyselect::where(is.numeric), .by = girl, .name = TRUE)
  expect_identical(kept$name, c("score", "score"))
})

test_that("calendar spreads are difftime columns with one unit per column", {
  day <- tibble::tibble(
    g = c(1, 1, 2, 2, 2),
    day = as.Date("2024-01-01") + c(0, 1, 0, 3, 9)
  )
  out <- summ(day, .by = g, .stat = c("sd", "se", "iqr", "mad"))
  for (statistic in c("sd", "se", "iqr", "mad")) {
    expect_s3_class(out[[statistic]], "difftime")
    expect_identical(units(out[[statistic]]), "days")
  }
  expect_equal(as.numeric(out$sd), c(sd(0:1), sd(c(0, 3, 9))))
  # A sub-day spread keeps its value instead of rounding to "0d".
  expect_equal(
    as.numeric(out$se, units = "hours")[[1L]],
    sd(0:1) / sqrt(2) * 24
  )

  stamp <- tibble::tibble(
    g = c(1, 1, 2, 2),
    tm = as.POSIXct("2024-01-01 09:00", tz = "UTC") + c(0, 7200, 0, 3600)
  )
  spread <- summ(stamp, .by = g, .stat = "sd")
  expect_identical(units(spread$sd), "hours")
  expect_equal(
    as.numeric(spread$sd, units = "secs"),
    c(sd(c(0, 7200)), sd(c(0, 3600)))
  )
})

test_that("hms times of day summarise as clock times", {
  skip_if_not_installed("hms")
  clock <- hms::as_hms(c(3600, 5400, 7200, NA))
  out <- summ(clock, .stat = c("n", "mean", "min", "max", "sd"))
  expect_identical(out$type, "time")
  expect_identical(out$mean, "01:30:00")
  expect_identical(out$min, "01:00:00")
  expect_identical(out$max, "02:00:00")
  expect_identical(units(out$sd), "mins")
  expect_equal(as.numeric(out$sd), 30)
  mixed <- summ(tibble::tibble(x = 1:2, clock = hms::as_hms(c(60, 120))))
  expect_named(mixed, c("numeric", "time"))
})

test_that("table mode keeps numeric spreads and records their unit", {
  input <- tibble::tibble(
    x = c(1, 2.123456789, 3),
    day = as.Date("2024-01-01") + 0:2
  )
  out <- summ(input, .type = "table", .stat = c("mean", "sd"))
  expect_type(out$sd, "double")
  expect_identical(out$type, c("dbl", "date [days]"))
  expect_equal(out$sd, c(sd(input$x), 1))
  expect_identical(out$mean[[1L]], "2.041152")
})

test_that("a vector piped with magrittr is named value", {
  piped <- c(1, 2, 3) %>% summ(.name = TRUE, .stat = "mean")
  expect_identical(piped$name, "value")
  native <- c(1, 2, 3) |> summ(.name = TRUE, .stat = "mean")
  expect_identical(native$name, "c(1, 2, 3)")
  expect_identical(summ(c(1, 2), .name = TRUE)$name, "c(1, 2)")
})

test_that(".by expressions give an actionable error", {
  input <- tibble::tibble(x = 1:3, y = 4:6)
  expect_error(summ(input, y, .by = x > 1), "Create the grouping column first")
  expect_error(tab(input, y, .by = x > 1), "must select existing columns")
  expect_no_error(summ(input, y, .by = c(x)))
})

test_that("aggregation excludes alternate and additional geometry columns", {
  skip_if_not_installed("sf")
  d <- sf::st_as_sf(
    tibble::tibble(x = c(1, 3, 5), g = c("b", "a", "b"), lon = 1:3, lat = 4:6),
    coords = c("lon", "lat"),
    sf_column_name = "shape"
  )
  d$extra_geometry <- sf::st_geometry(d)
  attributes_only <- tibble::tibble(x = d$x, g = d$g)
  expect_equal(summ(d, x, .by = g), summ(attributes_only, x, .by = g))
  expect_equal(tab(d, x, .by = g), tab(attributes_only, x, .by = g))
  expect_equal(tab1(d), tab1(attributes_only))
  expect_warning(spatial_summary <- summ(d), "g is non-numeric")
  expect_warning(attribute_summary <- summ(attributes_only), "g is non-numeric")
  expect_equal(spatial_summary, attribute_summary)
  expect_error(tab(d, shape), "shape")
  expect_error(summ(d, x, .by = shape), "shape")
  grouped <- dplyr::group_by(d, g)
  expect_equal(tab(grouped, x), tab(dplyr::group_by(attributes_only, g), x))
  expect_equal(summ(grouped, x), summ(dplyr::group_by(attributes_only, g), x))
})

test_that("summary requests avoid unrequested expensive statistics", {
  testthat::local_mocked_bindings(
    quantile = function(...) stop("Unrequested quantile calculation"),
    sd = function(...) stop("Unrequested SD calculation"),
    .package = "stats"
  )
  testthat::local_mocked_bindings(
    skew = function(...) stop("Unrequested skew calculation"),
    kurtosis = function(...) stop("Unrequested kurtosis calculation"),
    .package = "tidystata"
  )
  expect_equal(summ(1:100, .stat = "mean")$mean, 50.5)
  expect_equal(summ(1:100, .stat = "n")$n, 100)
  day <- as.Date("2024-01-01") + 0:2
  expect_equal(summ(day, .stat = "mean")$mean, "2024-01-02")
  moment <- as.POSIXct("2024-01-01", tz = "UTC") + c(0, 120)
  expect_equal(summ(moment, .stat = "mean")$mean, "2024-01-01 00:01")
})

test_that("summary percentile names retain requested order and type-7 values", {
  x <- c(-9, 0, 3, 8, 24, NA_real_)
  requested <- c("p97.5", "p0", "p2.5", "q1", "p25", "p100", "p97.5")
  out <- summ(x, .stat = requested, .name = TRUE)
  expect_named(out, c("name", "type", unique(requested)))
  expect_equal(
    unlist(out[unique(requested)], use.names = FALSE),
    unname(stats::quantile(x, c(.975, 0, .025, .25, .25, 1), na.rm = TRUE))
  )
  day <- as.Date("2024-01-01") + c(0, 10)
  expect_equal(summ(day, .stat = "p2.5")$p2.5, "2024-01-01")
  moment <- as.POSIXct("2024-01-01", tz = "UTC") + c(0, 3600)
  expect_equal(summ(moment, .stat = "p2.5")$p2.5, "2024-01-01 00:01")
  labelled <- haven::labelled_spss(c(0, 100, 999), na_values = 999)
  expect_warning(
    observed <- summ(labelled, .stat = c("p2.5", "p97.5")),
    "labelled"
  )
  expect_equal(observed$p2.5, 2.5)
  expect_equal(observed$p97.5, 97.5)
  collision <- tibble::tibble(p2.5 = c("b", "a"), x = c(0, 10))
  expect_message(
    by_percentile <- summ(
      collision,
      x,
      .by = p2.5,
      .stat = "p2.5",
      .name = TRUE
    ),
    "Grouping column.*renamed"
  )
  expect_named(by_percentile, c(".p2.5", "name", "type", "p2.5"))
  # Groups are sorted by key by default: "a" (x = 10) before "b" (x = 0).
  expect_equal(by_percentile$.p2.5, c("a", "b"))
  expect_equal(by_percentile$p2.5, c(10, 0))
  for (invalid in c("p-1", "p101", "pNaN", "p2.5.1")) {
    expect_error(summ(x, .stat = invalid), "Unsupported statistic")
  }
})

test_that("sorted mixed summaries preserve selection order across type families", {
  input <- tibble::tibble(
    g = c("b", "a"),
    x = 1:2,
    day = as.Date("2024-01-01") + 0:1
  )
  out <- summ(input, day, x, .by = g, .type = "table", .sort = TRUE)
  expect_equal(out$g, c("a", "a", "b", "b"))
  expect_equal(out$name, c("day", "x", "day", "x"))
  grouped <- dplyr::group_by(input, g)
  expect_equal(summ(grouped, x, .sort = TRUE)$g, c("a", "b"))
  zero <- summ(input[0, ], .by = g, .sort = TRUE, .drop_empty = TRUE)
  expect_equal(nrow(zero$numeric), 0L)
  expect_equal(nrow(zero$date), 0L)
})

test_that("summary sorting uses key values and preserves measured-variable order", {
  input <- tibble::tibble(
    g = factor(c("low", "high", "low", NA), levels = c("high", "low")),
    h = c(2, 1, 1, 0),
    x = 1:4,
    y = 5:8
  )
  for (fn in list(summ, tabstat)) {
    out <- fn(input, y, x, .by = c(g, h), .sort = TRUE, .stat = "mean")
    expect_equal(
      as.character(out$g),
      rep(c("high", "low", "low", NA), each = 2)
    )
    expect_equal(out$h, rep(c(1, 1, 2, 0), each = 2))
    expect_equal(out$name, rep(c("y", "x"), 4))
    expect_equal(
      fn(input, x, .by = g, .stat = "n", .sort = FALSE)$g,
      input$g[c(1, 2, 4)]
    )
    expect_equal(
      fn(input, x, .by = g, .stat = "n")$g,
      factor(c("high", "low", NA), levels = c("high", "low"))
    )
    expect_error(fn(input, .sort = NA), "must be `TRUE` or `FALSE`")
  }
})

test_that("summary empty-row removal is independent of missing-key removal", {
  input <- tibble::tibble(
    g = c("b", "a", NA),
    x = c(NA_real_, 2, 3),
    day = as.Date(c("2024-01-01", NA, "2024-01-03"))
  )
  for (fn in list(summ, tabstat)) {
    out <- fn(input, .by = g, .drop_empty = TRUE, .stat = "mean")
    expect_equal(out$numeric$g, c("a", NA))
    expect_equal(out$date$g, c("b", NA))
    expect_false("n" %in% names(out$numeric))
    combined <- fn(
      input,
      .by = g,
      .drop_empty = TRUE,
      .missing = FALSE,
      .type = "table",
      .stat = "mean",
      .sort = TRUE
    )
    expect_equal(combined$g, c("a", "b"))
    expect_equal(combined$name, c("x", "day"))
    expect_error(fn(input, .drop_empty = 1), "must be `TRUE` or `FALSE`")
  }
  expect_warning(
    empty <- summ(c(NA_real_, NA_real_), .drop_empty = TRUE, .stat = "mean"),
    "entirely missing"
  )
  expect_equal(nrow(empty), 0L)
  expect_named(empty, c("type", "mean"))
})

test_that("summary defaults sort groups like tab and hide a single name", {
  levels <- c("low", "middle", "high")
  d <- tibble::tibble(
    edu = factor(c("high", "middle", NA, "low", "high"), levels = levels),
    x = 1:5
  )
  out <- summ(d, x, .by = "edu")
  expect_identical(as.character(out$edu), c(levels, NA))
  expect_identical(
    as.character(out$edu),
    as.character(unique(tab(d, x, .by = edu)$edu))
  )
  expect_identical(
    as.character(summ(dplyr::group_by(d, edu), x)$edu),
    c(levels, NA)
  )
  expect_false("name" %in% names(out))
  expect_true("name" %in% names(summ(d, x, .by = edu, .name = TRUE)))
  expect_true("name" %in% names(summ(dplyr::mutate(d, y = x), .by = edu)))
  expect_identical(
    as.character(summ(d, x, .by = edu, .sort = FALSE)$edu),
    c("high", "middle", NA, "low")
  )
})

test_that("tabstat detail, calendar skips and datetime zones", {
  expect_true(all(
    c("median", "sd", "sum") %in% names(tabstat(1:5, .detail = TRUE))
  ))
  expect_identical(names(tabstat(1:5)), c("type", "mean"))
  mixed <- tibble::tibble(x = 1:2, day = as.Date("2024-01-01") + 0:1)
  expect_warning(total <- summ(mixed, .stat = "sum"), "skipped: day")
  expect_identical(total$sum, 3)
  expect_error(summ(mixed["day"], .stat = "sum"), "sum.*date")
  hk <- as.POSIXct(
    c("2024-03-01 09:00", "2024-03-02 09:00"),
    tz = "Asia/Hong_Kong"
  )
  zoned <- summ(hk)
  expect_identical(zoned$min, "2024-03-01 09:00")
  expect_identical(zoned$max, "2024-03-02 09:00")
})

test_that("calendar summaries distinguish infinite extrema from missing values", {
  day <- as.Date(c(-Inf, 0, Inf, NA), origin = "1970-01-01")
  out <- summ(day, .stat = c("n", "miss_n", "min", "max"))
  expect_identical(out$n, 3L)
  expect_identical(out$miss_n, 1L)
  expect_identical(out$min, "-Inf")
  expect_identical(out$max, "Inf")
  finite <- summ(as.Date(c(0, 1), origin = "1970-01-01"), .stat = "min")
  expect_identical(finite$min, "1970-01-01")
})

test_that("mixed calendar tables retain documented shared-column types", {
  input <- tibble::tibble(x = c(1, 3), day = as.Date("2024-01-01") + 0:1)
  out <- summ(input, .type = "table", .stat = c("n", "mean"))
  expect_identical(out$mean, c("2", "2024-01-01"))
  expect_identical(out$n, c(2L, 2L))
  separate <- summ(input, .type = "list", .stat = "mean")
  expect_identical(separate$numeric$mean, 2)
  piped <- 1:3 %>% summ(.name = TRUE, .stat = "mean")
  # Magrittr placeholders are named `value` (see test-problems2-low.R).
  expect_identical(piped$name, "value")
  expect_identical(piped$mean, 2)
})

test_that("summ() and tabstat() report invalid input", {
  d <- tibble::tibble(
    g = c("a", "b"),
    x = c(1, 2),
    when = as.Date("2020-01-01") + 0:1
  )
  expect_snapshot(error = TRUE, {
    summ(d, x, .sort = NA)
    tabstat(d, x, .keep_all = 1)
    summ(d, x, .stat = NA)
    summ(d, x, .stat = c("mean", "middle"))
    summ(d, when, .stat = "sum")
    summ(d, x, .by = toupper(g))
    summ(d, g)
  })
  expect_snapshot(out <- summ(d, x, when, .stat = c("mean", "skew")))
})
