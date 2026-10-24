# Comprehensive Test Suite for select_or_transmute() Function
# Enhanced select with data-masking support

# CHALLENGE: Comprehensive testing for select_or_transmute
# FUNCTIONS: select_or_transmute
# KEY BEHAVIORS: enhanced select, data-masking
# EDGE CASES: complex expressions, tidyselect integration

# ============================================================================
# CHALLENGING TESTS - Basic Select Operations
# ============================================================================

test_that("select_or_transmute: basic column selection", {
  df <- tibble::tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- select_or_transmute(df, x, y)
  expect_identical(result, df[c("x", "y")])
})

test_that("select_or_transmute: select all columns with empty call", {
  df <- tibble::tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- select_or_transmute(df)
  expect_identical(result, df)
})

test_that("select_or_transmute: single column selection", {
  df <- tibble::tibble(x = 1:5, y = 6:10)
  result <- select_or_transmute(df, x)
  expect_identical(result, df["x"])
})

test_that("select_or_transmute: column reordering", {
  df <- tibble::tibble(a = 1:5, b = 6:10, c = 11:15)
  result <- select_or_transmute(df, c, a, b)
  expect_identical(result, df[c("c", "a", "b")])
})

# ============================================================================
# CHALLENGING TESTS - Data-Masking (Expression Selection)
# ============================================================================

test_that("select_or_transmute: select with boolean expression", {
  df <- tibble::tibble(x = c(1, 2, 3, 4, 5), y = c(10, 20, 30, 40, 50))
  result <- select_or_transmute(df, x > 3)
  expect_equal(ncol(result), 1)
  expect_equal(names(result), "x > 3")
  expect_equal(result[[1]], c(FALSE, FALSE, FALSE, TRUE, TRUE))
})

test_that("select_or_transmute: select with arithmetic expression", {
  df <- tibble::tibble(x = 1:5, y = 6:10)
  result <- select_or_transmute(df, x + y)
  expect_equal(ncol(result), 1)
  expect_equal(result[[1]], c(7, 9, 11, 13, 15))
})

test_that("select_or_transmute: multiple computed columns", {
  df <- tibble::tibble(x = 1:5, y = 6:10)
  result <- select_or_transmute(df, sum_xy = x + y, diff_xy = y - x)
  expect_equal(ncol(result), 2)
  expect_equal(result$sum_xy, c(7, 9, 11, 13, 15))
  expect_equal(result$diff_xy, c(5, 5, 5, 5, 5))
})

test_that("select_or_transmute: complex expressions", {
  df <- tibble::tibble(a = 1:10, b = 11:20, c = 21:30)
  result <- select_or_transmute(
    df,
    weighted = a * 0.5 + b * 0.3 + c * 0.2,
    ratio = (b - a) / c
  )
  expect_equal(ncol(result), 2)
  expect_type(result$weighted, "double")
  expect_type(result$ratio, "double")
})

test_that("select_or_transmute: expression using functions", {
  df <- tibble::tibble(x = c(1, 4, 9, 16, 25))
  result <- select_or_transmute(df, sqrt_x = sqrt(x))
  expect_equal(result$sqrt_x, c(1, 2, 3, 4, 5))
})

# ============================================================================
# CHALLENGING TESTS - Tidyselect Helpers
# ============================================================================

test_that("select_or_transmute: starts_with selection", {
  df <- tibble::tibble(temp_1 = 1:5, temp_2 = 6:10, pressure = 11:15)
  result <- select_or_transmute(df, dplyr::starts_with("temp"))
  expect_identical(result, df[c("temp_1", "temp_2")])
})

test_that("select_or_transmute: ends_with selection", {
  df <- tibble::tibble(var_a_test = 1:5, var_b_test = 6:10, var_c_prod = 11:15)
  result <- select_or_transmute(df, dplyr::ends_with("_test"))
  expect_identical(result, df[c("var_a_test", "var_b_test")])
})

test_that("select_or_transmute: contains selection", {
  df <- tibble::tibble(
    temp_morning = 1:5,
    temp_evening = 6:10,
    pressure_temp = 11:15
  )
  result <- select_or_transmute(df, dplyr::contains("temp"))
  expect_identical(result, df)
})

test_that("select_or_transmute: where() with is.numeric", {
  df <- tibble::tibble(
    num1 = 1:5,
    num2 = 6:10,
    char = letters[1:5],
    logi = c(TRUE, FALSE, TRUE, FALSE, TRUE)
  )
  result <- select_or_transmute(df, dplyr::where(is.numeric))
  expect_identical(result, df[c("num1", "num2")])
})

test_that("select_or_transmute: where() with complex predicate", {
  df <- tibble::tibble(
    a = 1:5,
    b = c("x", "y", "z", "x", "y"),
    c = c(TRUE, FALSE, TRUE, FALSE, TRUE),
    d = 6:10
  )
  result <- select_or_transmute(
    df,
    dplyr::where(~ is.numeric(.x) | is.logical(.x))
  )
  expect_identical(result, df[c("a", "c", "d")])
})

test_that("select_or_transmute: numeric column indices", {
  df <- tibble::tibble(a = 1:5, b = 6:10, c = 11:15, d = 16:20, e = 21:25)
  result <- select_or_transmute(df, 1, 3, 5)
  expect_identical(result, df[c("a", "c", "e")])
})

test_that("select_or_transmute: column range with :", {
  df <- tibble::tibble(a = 1:5, b = 6:10, c = 11:15, d = 16:20)
  result <- select_or_transmute(df, b:d)
  expect_identical(result, df[c("b", "c", "d")])
})

test_that("select_or_transmute: everything()", {
  df <- tibble::tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- select_or_transmute(df, dplyr::everything())
  expect_identical(result, df)
})

# ============================================================================
# CHALLENGING TESTS - Mixed Selection Types
# ============================================================================

test_that("select_or_transmute: mix of named columns and expressions", {
  df <- tibble::tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- select_or_transmute(df, x, doubled_y = y * 2)
  expect_equal(ncol(result), 2)
  expect_equal(names(result), c("x", "doubled_y"))
  expect_equal(result$doubled_y, c(12, 14, 16, 18, 20))
})

test_that("select_or_transmute: mix of selection and computed columns", {
  df <- tibble::tibble(
    temp_1 = 1:5,
    temp_2 = 6:10,
    pressure_1 = 11:15,
    pressure_2 = 16:20
  )
  # First select temp columns, then add computed column in separate step
  result <- df |>
    select_or_transmute(dplyr::starts_with("temp")) |>
    dplyr::mutate(total_pressure = df$pressure_1 + df$pressure_2)
  expect_equal(ncol(result), 3)
})

# ============================================================================
# CHALLENGING TESTS - Error Handling
# ============================================================================

test_that("select_or_transmute: non-existent column gives informative error", {
  df <- tibble::tibble(x = 1:5, y = 6:10)
  expect_error(select_or_transmute(df, z), "don't exist: `z`")
})

test_that("select_or_transmute: invalid expression gives informative error", {
  df <- tibble::tibble(x = 1:5, y = 6:10)
  expect_error(
    select_or_transmute(df, nonexistent_func(x)),
    "Neither.*select.*mutate"
  )
})

test_that("select_or_transmute: NULL data frame errors", {
  expect_error(select_or_transmute(NULL, x))
})

test_that("select_or_transmute: empty selection after filtering gives empty result", {
  df <- tibble::tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- select_or_transmute(df, dplyr::starts_with("nonexistent"))
  expect_equal(ncol(result), 0)
  expect_equal(nrow(result), 5)
})

# ============================================================================
# CHALLENGING TESTS - Edge Cases
# ============================================================================

test_that("select_or_transmute: single row data frame", {
  df <- tibble::tibble(x = 1, y = 2, z = 3)
  result <- select_or_transmute(df, x, z)
  expect_equal(nrow(result), 1)
  expect_equal(ncol(result), 2)
})

test_that("select_or_transmute: zero row data frame", {
  df <- tibble::tibble(x = numeric(0), y = numeric(0))
  result <- select_or_transmute(df, x)
  expect_equal(nrow(result), 0)
  expect_equal(ncol(result), 1)
})

test_that("select_or_transmute: many columns", {
  df <- tibble::as_tibble(replicate(100, 1:10), .name_repair = "minimal")
  names(df) <- paste0("var", 1:100)
  result <- select_or_transmute(df, var1, var50, var100)
  expect_equal(ncol(result), 3)
})

test_that("select_or_transmute: special characters in column names", {
  df <- tibble::tibble(
    `var with spaces` = 1:5,
    `var.with.dots` = 6:10,
    `var_with_underscores` = 11:15
  )
  result <- select_or_transmute(df, `var with spaces`)
  expect_equal(ncol(result), 1)
})

test_that("select_or_transmute: selecting same column multiple times", {
  df <- tibble::tibble(x = 1:5, y = 6:10)
  result <- select_or_transmute(df, x, x, y)
  # dplyr allows duplicate selections
  expect_true(ncol(result) >= 2)
})

# ============================================================================
# CHALLENGING TESTS - Data Type Handling
# ============================================================================

test_that("select_or_transmute: preserves data types", {
  df <- tibble::tibble(
    int_col = 1:5,
    dbl_col = c(1.5, 2.5, 3.5, 4.5, 5.5),
    chr_col = letters[1:5],
    fct_col = factor(letters[1:5]),
    logi_col = c(TRUE, FALSE, TRUE, FALSE, TRUE),
    date_col = seq(as.Date("2024-01-01"), by = "day", length.out = 5)
  )
  result <- select_or_transmute(df, dplyr::everything())
  expect_type(result$int_col, "integer")
  expect_type(result$dbl_col, "double")
  expect_type(result$chr_col, "character")
  expect_s3_class(result$fct_col, "factor")
  expect_type(result$logi_col, "logical")
  expect_s3_class(result$date_col, "Date")
})

test_that("select_or_transmute: handles list columns", {
  df <- tibble::tibble(
    x = 1:3,
    y = I(list(1:2, 3:4, 5:6))
  )
  result <- select_or_transmute(df, y)
  expect_equal(ncol(result), 1)
  expect_type(result$y, "list")
})

test_that("select_or_transmute: handles matrix columns", {
  df <- tibble::tibble(x = 1:3)
  df$y <- matrix(1:6, nrow = 3)
  result <- select_or_transmute(df, y)
  expect_equal(ncol(result), 1)
  expect_true(is.matrix(result$y))
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("select_or_transmute: survey data variable selection", {
  withr::local_preserve_seed()
  survey <- tibble::tibble(
    respondent_id = 1:100,
    q1_satisfaction = sample(1:5, 100, replace = TRUE),
    q2_recommend = sample(c("Yes", "No", "Maybe"), 100, replace = TRUE),
    q3_age_group = sample(
      c("18-25", "26-35", "36-50", "50+"),
      100,
      replace = TRUE
    ),
    completion_time = runif(100, 1, 10)
  )

  # Select only question columns
  questions <- select_or_transmute(survey, dplyr::starts_with("q"))
  expect_equal(ncol(questions), 3)

  # Calculate satisfaction score
  satisfaction_with_id <- select_or_transmute(
    survey,
    respondent_id,
    is_satisfied = q1_satisfaction >= 4
  )
  expect_equal(ncol(satisfaction_with_id), 2)
  expect_type(satisfaction_with_id$is_satisfied, "logical")
})

test_that("select_or_transmute: financial data analysis", {
  withr::local_preserve_seed()
  financial <- tibble::tibble(
    date = seq(as.Date("2024-01-01"), by = "day", length.out = 30),
    open_price = cumsum(rnorm(30, 0.1, 1)) + 100,
    close_price = cumsum(rnorm(30, 0.1, 1)) + 101,
    volume = sample(1000000:10000000, 30)
  )

  result <- select_or_transmute(
    financial,
    date,
    price_range = close_price - open_price,
    volume_millions = volume / 1e6
  )

  expect_equal(ncol(result), 3)
  expect_equal(result$price_range, financial$close_price - financial$open_price)
})

test_that("select_or_transmute: feature engineering for modeling", {
  withr::local_preserve_seed()
  data <- tibble::tibble(
    x1 = rnorm(100),
    x2 = rnorm(100),
    x3 = rnorm(100),
    target = rnorm(100)
  )

  features <- select_or_transmute(
    data,
    x1,
    x2,
    x3,
    x1_sq = x1^2,
    x2_sq = x2^2,
    interaction = x1 * x2,
    target
  )

  expect_equal(ncol(features), 7)
  expect_equal(features$x1_sq, data$x1^2)
  expect_equal(features$interaction, data$x1 * data$x2)
})

# ============================================================================
# CHALLENGING TESTS - data.table Compatibility
# ============================================================================

test_that("select_or_transmute: works with data.table input", {
  skip_if_not_installed("data.table")
  dt <- data.table::data.table(x = 1:5, y = 6:10, z = 11:15)
  result <- select_or_transmute(dt, x, z)
  expect_s3_class(result, "data.table")
  expect_equal(ncol(result), 2)
})

# ============================================================================
# CHALLENGING TESTS - Wide inputs
# ============================================================================

test_that("select_or_transmute: selects the expected columns of a wide data frame", {
  withr::local_preserve_seed()
  df <- tibble::as_tibble(replicate(1000, rnorm(100)), .name_repair = "minimal")
  names(df) <- paste0("var", 1:1000)

  result <- select_or_transmute(df, dplyr::where(~ mean(.x) > 0))

  expect_s3_class(result, "tbl_df")
  expected <- names(df)[colMeans(as.matrix(df)) > 0]
  expect_identical(names(result), expected)
  expect_equal(result, df[expected])
})

test_that("misspelled selections are reported instead of evaluated", {
  d <- tibble::tibble(height = c(1, 2, 2), mass = 3:5)
  mas <- 99
  expect_error(summ(d, mas), "`mas`")
  expect_error(tab(d, "heigth"), "`heigth`")
  expect_error(summ(d, 4), "position 4")
  expect_error(select_or_transmute(d, a1, a2, a3), "`a1`, `a2`, `a3`")
  expect_identical(names(tab(d, height > 1))[1], "height > 1")
  expect_identical(
    select_or_transmute(d, ratio = mass / height)$ratio,
    d$mass / d$height
  )
  expect_identical(
    tab(d, half = mass / height)$half,
    sort(unique(d$mass / d$height))
  )
  mixed <- select_or_transmute(
    d,
    tidyselect::starts_with("h"),
    heavy = mass > 3
  )
  expect_named(mixed, c("height", "heavy"))
})

test_that("spatial inspection and selection keep their geometry", {
  skip_if_not_installed("sf")
  d <- sf::st_as_sf(
    data.frame(x = 1:2, lon = 1:2, lat = 3:4),
    coords = c("lon", "lat")
  )
  expect_true("geometry" %in% ds(d))
  expect_s3_class(select_or_transmute(d, x), "sf")
  expect_identical(
    sf::st_geometry(d),
    sf::st_geometry(select_or_transmute(d, x))
  )
})

test_that("select_or_transmute forces its data promise once and preserves selected attributes", {
  calls <- 0L
  x <- structure(1:3, label = "Observed score")
  data <- tibble::tibble(x = x, y = 4:6)
  out <- select_or_transmute(
    {
      calls <- calls + 1L
      data
    },
    x
  )
  expect_identical(calls, 1L)
  expect_identical(out$x, x)
  expect_identical(data, tibble::tibble(x = x, y = 4:6))
})

test_that("select_or_transmute no-argument return preserves grouping and object identity", {
  data <- dplyr::group_by(tibble::tibble(g = c("a", "b"), x = 1:2), g)
  out <- withVisible(select_or_transmute(data))
  expect_identical(out$value, data)
  expect_true(out$visible)
  expect_identical(select_or_transmute(data, tidyselect::everything()), data)
})

test_that("select_or_transmute evaluates selection predicates once per column", {
  calls <- 0L
  predicate <- function(x) {
    calls <<- calls + 1L
    is.numeric(x)
  }
  data <- tibble::tibble(x = 1:2, y = c("a", "b"), z = c(TRUE, FALSE))
  expect_identical(
    select_or_transmute(data, tidyselect::where(predicate)),
    data["x"]
  )
  expect_identical(calls, 3L)
})

test_that("select_or_transmute preserves successful warning conditions and their order", {
  first <- structure(
    list(message = "first selector warning", call = NULL),
    class = c("selector_warning", "warning", "condition")
  )
  second <- simpleWarning("second selector warning")
  choose <- function() {
    warning(first)
    warning(second)
    "x"
  }
  observed <- list()
  out <- withCallingHandlers(
    select_or_transmute(tibble::tibble(x = 1:2), tidyselect::all_of(choose())),
    warning = function(w) {
      observed[[length(observed) + 1L]] <<- w
      invokeRestart("muffleWarning")
    }
  )
  expect_identical(observed, list(first, second))
  expect_identical(out, tibble::tibble(x = 1:2))
})

test_that("select_or_transmute reports both failed branches without replaying their warnings", {
  compute <- function() {
    warning("discarded branch warning")
    stop("branch failure")
  }
  observed <- character()
  err <- withCallingHandlers(
    tryCatch(
      select_or_transmute(tibble::tibble(x = 1:2), compute()),
      error = identity
    ),
    warning = function(w) {
      observed <<- c(observed, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  expect_length(observed, 0L)
  expect_s3_class(err, "error")
  expect_match(conditionMessage(err), "select\\(\\) error:")
  expect_match(conditionMessage(err), "mutate\\(\\) error:")
  expect_match(conditionMessage(err), "branch failure", fixed = TRUE)
})

test_that("select_or_transmute evaluates computed expressions exactly once", {
  local({
    old <- get0(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    on.exit(
      if (is.null(old)) {
        rm(".Random.seed", envir = .GlobalEnv)
      } else {
        assign(".Random.seed", old, envir = .GlobalEnv)
      }
    )
    set.seed(731)
    stats::runif(1)
    expected_state <- .Random.seed
    set.seed(731)
    calls <- 0L
    compute <- function(x) {
      calls <<- calls + 1L
      stats::runif(1)
      force(x)
      x * 2
    }
    out <- select_or_transmute(tibble::tibble(x = 1:3), z = compute(x))
    expect_identical(out, tibble::tibble(z = c(2, 4, 6)))
    expect_identical(calls, 1L)
    expect_identical(.Random.seed, expected_state)
  })
})

test_that("select_or_transmute emits successful selector warnings exactly once", {
  d <- tibble::tibble(x = 1:3, y = 4:6)
  choose <- function() {
    warning("successful-selector-warning")
    "x"
  }
  warnings <- character()
  out <- withCallingHandlers(
    select_or_transmute(d, tidyselect::all_of(choose())),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  expect_identical(warnings, "successful-selector-warning")
  expect_identical(out, d["x"])
})

test_that("select_or_transmute discards failed-probe warnings and retains successful fallback warning", {
  d <- tibble::tibble(x = 1:3)
  compute <- function(x) {
    warning("branch-warning")
    force(x)
    x * 2
  }
  warnings <- character()
  out <- withCallingHandlers(
    select_or_transmute(d, z = compute(x)),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  expect_length(warnings, 1L)
  expect_match(warnings, "branch-warning", fixed = TRUE)
  expect_identical(out, tibble::tibble(z = c(2, 4, 6)))
})

test_that("select_or_transmute() reports unmatched and unrecognised input", {
  d <- tibble::tibble(height = c(1, 2), mass = c(3, 4))
  expect_snapshot(error = TRUE, {
    select_or_transmute(d, heigth, mas)
    select_or_transmute(d, 4)
    select_or_transmute(d, ratio = mass / missing_column)
  })
})
