# Challenging Test Suite for codebook() and Other Functions
# Only difficult tests - removed simple/basic tests
# Focus on edge cases, complexity, and robustness

# CHALLENGE: Comprehensive testing for codebook, complex_tab
# FUNCTIONS: codebook, complex_tab
# KEY BEHAVIORS: variable metadata, type detection
# EDGE CASES: complex data types, nested structures

# ============================================================================
# CHALLENGING TESTS - codebook() Complex Scenarios
# ============================================================================

test_that("codebook: empty data frame with columns", {
  df <- tibble::tibble(x = numeric(0), y = character(0), z = logical(0))
  result <- codebook(df)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3)
  expect_true(all(result$n == 0))
})

test_that("codebook: single row dataset", {
  df <- tibble::tibble(
    num = 1,
    char = "only",
    logi = TRUE,
    fac = factor("single")
  )
  result <- codebook(df)
  expect_equal(nrow(result), 4)
  expect_true(all(result$n == 1))
  expect_true(all(result$unique == 1))
})

test_that("codebook: all identical values across types", {
  df <- tibble::tibble(
    num = rep(42, 100),
    char = rep("same", 100),
    logi = rep(TRUE, 100),
    fac = factor(rep("only", 100))
  )
  result <- codebook(df)
  expect_true(all(result$unique == 1))
})

test_that("codebook: all unique values (100% unique)", {
  df <- tibble::tibble(
    id = 1:500,
    uuid = paste0("ID", 1:500),
    timestamp = as.POSIXct(Sys.time() + 1:500)
  )
  result <- codebook(df)
  expect_true(all(result$unique == 500))
  expect_true(all(result$n == 500))
})

test_that("codebook: extreme missing value patterns", {
  df <- tibble::tibble(
    no_na = 1:100,
    ten_pct = c(1:90, rep(NA, 10)),
    fifty_pct = c(1:50, rep(NA, 50)),
    ninety_pct = c(1:10, rep(NA, 90)),
    all_na = rep(NA, 100)
  )
  result <- codebook(df)
  expect_equal(result$n[result$variable == "no_na"], 100)
  expect_equal(result$n[result$variable == "all_na"], 0)
})

test_that("codebook: haven labelled variables with complex labels", {
  df <- tibble::tibble(
    simple_label = haven::labelled(
      rep(1:3, length.out = 100),
      labels = c("A" = 1, "B" = 2, "C" = 3)
    ),
    with_na = haven::labelled_spss(
      rep(c(1, 1, 2, -99), length.out = 100),
      labels = c("Yes" = 1, "No" = 2, "Missing" = -99),
      na_values = -99
    ),
    extended = haven::labelled(
      rep(1:5, 20),
      labels = c(
        "Very Low" = 1,
        "Low" = 2,
        "Medium" = 3,
        "High" = 4,
        "Very High" = 5
      )
    )
  )
  result <- codebook(df)
  expect_s3_class(result, "tbl_df")
})

test_that("codebook: Date and POSIXct datetime variables", {
  df <- tibble::tibble(
    date_only = seq(as.Date("2020-01-01"), as.Date("2024-12-31"), by = "month"),
    datetime = seq(as.POSIXct("2020-01-01"), by = "hour", length.out = 60),
    datetime_tz = as.POSIXct(c("2024-01-01 10:00"), tz = "UTC")
  )
  result <- codebook(df)
  expect_equal(nrow(result), 3)
})

test_that("codebook: factor with many unused levels", {
  df <- tibble::tibble(
    x = factor(
      c("a", "b"),
      levels = c("a", "b", "c", "d", "e", "f", "g", "h", "i", "j")
    )
  )
  result <- codebook(df)
  expect_equal(result$unique, 2)
})

test_that("codebook: list column handling", {
  df <- tibble::tibble(
    normal = 1:5,
    list_col = I(list(1:3, 2:4, 3:5, 4:6, 5:7))
  )
  result <- codebook(df)
  expect_equal(nrow(result), 2)
})

test_that("codebook: matrix column handling", {
  df <- tibble::tibble(x = 1:4)
  df$y <- matrix(1:8, nrow = 4)
  result <- codebook(df)
  expect_equal(nrow(result), 2)
})

test_that("codebook: data frame with 50+ variables", {
  withr::local_preserve_seed()
  df <- tibble::as_tibble(
    replicate(50, sample(1:10, 100, replace = TRUE)),
    .name_repair = "minimal"
  )
  names(df) <- paste0("var", 1:50)
  result <- codebook(df)
  expect_equal(nrow(result), 50)
})

test_that("codebook: extreme numeric values", {
  df <- tibble::tibble(
    normal = 1:10,
    large = rep(
      c(.Machine$double.xmax, .Machine$double.xmax / 2),
      length.out = 10
    ),
    small = rep(
      c(.Machine$double.xmin, .Machine$double.xmin * 2),
      length.out = 10
    ),
    inf = rep(c(Inf, -Inf, Inf, -Inf), length.out = 10),
    nan = rep(c(NaN, NaN, 1, 2), length.out = 10)
  )
  result <- codebook(df)
  expect_equal(nrow(result), 5)
})

test_that("codebook: unicode and special characters in column names", {
  df <- tibble::tibble(
    `中文变量` = 1:10,
    `العربية` = 1:10,
    `with spaces` = 1:10,
    `with.dots` = 1:10,
    `with_underscores` = 1:10
  )
  result <- codebook(df)
  expect_equal(nrow(result), 5)
})

test_that("codebook: logical variables with NA", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    all_true = rep(TRUE, 100),
    all_false = rep(FALSE, 100),
    mixed = sample(c(TRUE, FALSE), 100, replace = TRUE),
    with_na = c(rep(TRUE, 25), rep(FALSE, 25), rep(NA, 50))
  )
  result <- codebook(df)
  expect_equal(nrow(result), 4)
  expect_true(all(result$type == "logical"))
})

test_that("codebook: difftime and hms time variables", {
  skip_if_not_installed("hms")
  df <- tibble::tibble(
    duration = as.difftime(c(1, 2, 3, 4, 5), units = "hours"),
    time_of_day = hms::as_hms(rep(
      c("08:00:00", "12:00:00", "18:00:00"),
      length.out = 5
    ))
  )
  result <- codebook(df)
  expect_equal(nrow(result), 2)
})

test_that("codebook: integer64 from bit64 package", {
  skip_if_not_installed("bit64")
  df <- tibble::tibble(
    big_int = bit64::as.integer64(c(1e15, 1e15, 2e15))
  )
  result <- codebook(df)
  expect_equal(nrow(result), 1)
})

test_that("codebook: data.table input", {
  skip_if_not_installed("data.table")
  df <- data.table::data.table(
    x = 1:10,
    y = letters[1:10]
  )
  result <- codebook(df)
  expect_identical(class(result), c("data.table", "data.frame"))
  expect_equal(nrow(result), 2)
})

# ============================================================================
# CHALLENGING TESTS - Complex Variable Selection
# ============================================================================

test_that("codebook: starts_with selection", {
  df <- tibble::tibble(
    pref_x_1 = 1:10,
    pref_x_2 = 1:10,
    pref_y_1 = 1:10,
    pref_y_2 = 1:10,
    other_z = 1:10
  )
  result <- codebook(df, dplyr::starts_with("pref_"))
  expect_equal(nrow(result), 4)
})

test_that("codebook: ends_with selection", {
  df <- tibble::tibble(
    var_a_test = 1:10,
    var_b_test = 1:10,
    var_c_prod = 1:10,
    var_d_prod = 1:10
  )
  result <- codebook(df, dplyr::ends_with("_test"))
  expect_equal(nrow(result), 2)
})

test_that("codebook: contains selection", {
  df <- tibble::tibble(
    temp_1 = 1:10,
    temp_2 = 1:10,
    pressure_temp = 1:10,
    humidity = 1:10
  )
  result <- codebook(df, dplyr::contains("temp"))
  expect_equal(nrow(result), 3)
})

test_that("codebook: where() with complex predicate", {
  df <- tibble::tibble(
    num1 = 1:10,
    num2 = 11:20,
    char = letters[1:10],
    logi = rep(c(TRUE, FALSE), length.out = 10),
    fac = factor(rep(1:2, 5))
  )
  result <- codebook(df, dplyr::where(is.numeric))
  expect_equal(nrow(result), 2)
})

test_that("codebook: numeric column indices", {
  df <- tibble::tibble(a = 1:5, b = 1:5, c = 1:5, d = 1:5, e = 1:5)
  result <- codebook(df, 1, 3, 5)
  expect_equal(result$variable, c("a", "c", "e"))
})

# ============================================================================
# CHALLENGING TESTS - Real-world Data Scenarios
# ============================================================================

test_that("codebook: survey data simulation", {
  withr::local_preserve_seed()
  set.seed(42)
  df <- tibble::tibble(
    respondent_id = 1:1000,
    age_group = sample(
      c("18-25", "26-35", "36-50", "50+"),
      1000,
      replace = TRUE
    ),
    gender = sample(
      c("Male", "Female", "Other", "Prefer not to say"),
      1000,
      replace = TRUE,
      prob = c(0.48, 0.48, 0.02, 0.02)
    ),
    satisfaction = sample(
      1:5,
      1000,
      replace = TRUE,
      prob = c(0.1, 0.15, 0.3, 0.3, 0.15)
    ),
    comments = ifelse(
      sample(c(TRUE, FALSE), 1000, replace = TRUE, prob = c(0.3, 0.7)),
      sample(c("Great!", "Needs work", "OK"), 1000, replace = TRUE),
      NA
    ),
    completed = sample(c(TRUE, FALSE), 1000, replace = TRUE, prob = c(0.9, 0.1))
  )
  result <- codebook(df)
  expect_equal(nrow(result), ncol(df))
  expect_setequal(result$variable, names(df))
  expect_equal(
    result$n[match(names(df), result$variable)],
    unname(vapply(df, function(x) sum(!is.na(x)), integer(1)))
  )
})

test_that("codebook: time series data", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    timestamp = seq(as.POSIXct("2024-01-01"), by = "hour", length.out = 168),
    value = rnorm(168),
    quality_flag = sample(
      c("Good", "Suspect", "Bad"),
      168,
      replace = TRUE,
      prob = c(0.85, 0.1, 0.05)
    ),
    sensor_id = rep(c("A1", "A2", "B1", "B2"), each = 42)
  )
  result <- codebook(df)
  expect_equal(nrow(result), 4)
})

test_that("codebook: clinical trial data", {
  withr::local_preserve_seed()
  set.seed(123)
  df <- tibble::tibble(
    subject_id = paste0("SUB", 1:200),
    site = sample(c("Site A", "Site B", "Site C"), 200, replace = TRUE),
    treatment = sample(c("Drug", "Placebo"), 200, replace = TRUE),
    age = sample(18:80, 200, replace = TRUE),
    baseline_score = sample(0:100, 200, replace = TRUE),
    followup_score = ifelse(
      sample(c(TRUE, FALSE), 200, replace = TRUE, prob = c(0.8, 0.2)),
      sample(0:100, 200, replace = TRUE),
      NA
    ),
    adverse_event = ifelse(
      sample(c(TRUE, FALSE), 200, replace = TRUE, prob = c(0.15, 0.85)),
      sample(c("Mild", "Moderate", "Severe"), 200, replace = TRUE),
      NA
    )
  )
  result <- codebook(df)
  expect_equal(nrow(result), ncol(df))
  expect_setequal(result$variable, names(df))
})

# ============================================================================
# CHALLENGING TESTS - Error Handling & Robustness
# ============================================================================

test_that("codebook: NULL input should error", {
  expect_error(codebook(NULL))
})

test_that("codebook: non-existent column selection should error", {
  df <- tibble::tibble(x = 1:5)
  expect_error(codebook(df, y))
})

test_that("codebook: empty selection should error or return empty", {
  df <- tibble::tibble(x = 1:5, y = 1:5)
  result <- codebook(df, dplyr::starts_with("zzz"))
  expect_equal(nrow(result), 0)
})

test_that("codebook inventories grouped data globally without modifying grouping", {
  d <- dplyr::group_by(tibble::tibble(g = c("a", "a", "b"), x = c(1, NA, 2)), g)
  before <- d
  out <- codebook(d)
  expect_identical(out$variable, c("g", "x"))
  expect_identical(out$n, c(3L, 2L))
  expect_identical(out$unique, c(2L, 2L))
  expect_identical(codebook(d, x)$variable, "x")
  expect_identical(d, before)
})

test_that("codebook excludes SPSS user missing values from unique counts", {
  d <- tibble::tibble(x = haven::labelled_spss(c(1, 1, 99, NA), na_values = 99))
  before <- d
  out <- codebook(d)
  expect_identical(out$n, 2L)
  expect_identical(out$unique, 1L)
  expect_identical(d, before)
})

test_that("codebook structured columns count complete rows rather than cells", {
  m <- matrix(c(1, 1, 2, 2, NA, 2, 2, 2), ncol = 2, byrow = TRUE)
  # Three complete rows: (1,1), (2,2), (2,2); one incomplete row.
  d <- tibble::tibble(m = m, nested = as.data.frame(m))
  before <- d
  out <- codebook(d)
  expect_identical(out$n, c(3L, 3L))
  expect_identical(out$unique, c(2L, 2L))
  expect_identical(d, before)
})

for (.name in c("codebook", "browse", "select_or_transmute")) {
  local({
    fn_name <- .name
    test_that(paste(fn_name, "does not evaluate an unused transmute branch"), {
      calls <- new.env(parent = emptyenv())
      calls$n <- 0L
      choose <- function() {
        calls$n <- calls$n + 1L
        "x"
      }
      d <- tibble::tibble(x = 1:3, y = 4:6)
      fn <- getExportedValue("tidystata", fn_name)
      out <- fn(d, tidyselect::all_of(choose()))
      expect_identical(calls$n, 1L)
      expect_true(
        if (fn_name == "codebook") {
          identical(out$variable, "x")
        } else {
          identical(names(out), "x")
        }
      )
    })
  })
}

for (.bad_names in list(c("same", "same"), c("a", ""), c("a", NA_character_))) {
  local({
    bad_names <- .bad_names
    test_that(
      paste(
        "codebook rejects ambiguous names",
        paste(bad_names, collapse = "/")
      ),
      {
        d <- data.frame(a = 1:2, b = 3:4)
        names(d) <- bad_names
        before <- serialize(d, NULL)
        expect_error(codebook(d), "unique|duplicat|empty|missing|NA")
        expect_identical(serialize(d, NULL), before)
      }
    )
  })
}
