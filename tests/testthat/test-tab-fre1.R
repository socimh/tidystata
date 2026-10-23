# Comprehensive Challenging Test Suite for fre1() Function
# 70+ difficult test scenarios - focusing on edge cases, complexity, and robustness
# All tests designed to run in < 1 minute

# CHALLENGE: Comprehensive testing for fre1
# FUNCTIONS: fre1
# KEY BEHAVIORS: single variable frequency
# EDGE CASES: edge cases in univariate analysis

# ============================================================================
# CHALLENGING TESTS - Output Type Variations
# ============================================================================

test_that("fre1: list output (default)", {
  df <- tibble::tibble(x = c("a", "a", "b", "b", "c"), y = c(1, 1, 2, 2, 3))
  result <- fre1(df, x, y)
  expect_type(result, "list")
})

test_that("fre1: tibble output", {
  df <- tibble::tibble(x = c("a", "a", "b", "b", "c"), y = c(1, 1, 2, 2, 3))
  result <- fre1(df, x, y, .type = "tibble")
  expect_s3_class(result, "tbl_df")
  expect_true("variable" %in% names(result))
  expect_true(any(grepl("Total", result$value)))
})

test_that("fre1: list output", {
  df <- tibble::tibble(x = c("a", "a", "b"), y = c(1, 1, 2))
  result <- fre1(df, x, y, .type = "list")
  expect_type(result, "list")
  expect_equal(length(result), 2)
})

test_that("fre1: many variables with tibble output", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    v1 = sample(1:3, 50, replace = TRUE),
    v2 = sample(letters[1:4], 50, replace = TRUE),
    v3 = factor(sample(c("x", "y"), 50, replace = TRUE))
  )
  result <- fre1(df, v1:v3, .type = "tibble")
  expect_s3_class(result, "tbl_df")
  expect_true(any(grepl("Total", result$value)))
})

# ============================================================================
# CHALLENGING TESTS - Total Row Functionality per Variable
# ============================================================================

test_that("fre1: each variable has its own Total row", {
  df <- tibble::tibble(x = c("a", "a", "b"), y = c(1, 1, 2))
  result <- fre1(df, x, y, .type = "list")
  expect_true(any(grepl("Total", result$x$value)))
  expect_true(any(grepl("Total", result$y$value)))
})

test_that("fre1: Total counts are correct per variable", {
  df <- tibble::tibble(x = c("a", "a", "b", "c"), y = c(1, 1, 2, 3))
  result <- fre1(df, x, y, .type = "list")
  x_total <- result$x[grepl("Total", result$x$value, ignore.case = TRUE), ]
  y_total <- result$y[grepl("Total", result$y$value, ignore.case = TRUE), ]
  expect_equal(x_total$n, 4)
  expect_equal(y_total$n, 4)
})

test_that("fre1: tibble output with multiple Total rows", {
  df <- tibble::tibble(x = c("a", "a", "b"), y = c(1, 1, 2))
  result <- fre1(df, x, y, .type = "tibble")
  total_count <- sum(grepl("Total", result$value, ignore.case = TRUE))
  expect_equal(total_count, 2)
})

test_that("fre1: list output structure with Total", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    var1 = sample(1:3, 100, replace = TRUE),
    var2 = sample(letters[1:5], 100, replace = TRUE)
  )
  result <- fre1(df, var1, var2, .type = "list")
  for (.x in result) {
    expect_true(any(grepl("Total", .x$value, ignore.case = TRUE)))
  }
})

# ============================================================================
# CHALLENGING TESTS - Grouping with .by
# ============================================================================

test_that("fre1: group by with list output", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    group = rep(c("A", "B"), each = 10),
    x = sample(1:3, 20, replace = TRUE),
    y = sample(letters[1:3], 20, replace = TRUE)
  )
  result <- fre1(df, x, y, .by = group, .type = "list")
  expect_type(result, "list")
  expect_equal(length(result), 2)
})

test_that("fre1: group by with tibble output", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    group = rep(c("A", "B"), each = 10),
    x = sample(1:3, 20, replace = TRUE),
    y = sample(letters[1:3], 20, replace = TRUE)
  )
  result <- fre1(df, x, y, .by = group, .type = "tibble")
  expect_true("group" %in% names(result))
  expect_true("variable" %in% names(result))
})

test_that("fre1: group by with flextable output", {
  withr::local_preserve_seed()
  skip_if_not_installed("flextable")
  df <- tibble::tibble(
    group = rep(c("A", "B"), each = 10),
    x = sample(1:3, 20, replace = TRUE)
  )
  result <- fre1(df, x, .by = group, .type = "flextable")
  expect_s3_class(result, "flextable")
})

test_that("fre1: group with NA in grouping variable", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    group = c(rep("A", 10), rep(NA, 10), rep("B", 10)),
    x = sample(1:3, 30, replace = TRUE)
  )
  result <- fre1(df, x, .by = group, .type = "list")
  expect_true(any(is.na(result$x$group)))
})

test_that("fre1: complex multi-level grouping", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    g1 = rep(c("X", "Y"), 20),
    g2 = rep(c("A", "B", "C", "D"), 10),
    x = sample(1:3, 40, replace = TRUE),
    y = sample(letters[1:3], 40, replace = TRUE)
  )
  result <- fre1(df, x, y, .by = c(g1, g2), .type = "tibble")
  expect_true(all(c("g1", "g2", "variable") %in% names(result)))
})

# ============================================================================
# CHALLENGING TESTS - Missing Value Patterns
# ============================================================================

test_that("fre1: variables with varying NA percentages", {
  df <- tibble::tibble(
    no_na = 1:50,
    ten_pct = c(1:45, rep(NA, 5)),
    fifty_pct = c(1:25, rep(NA, 25))
  )
  result <- fre1(df, no_na:fifty_pct, .type = "list")
  expect_equal(length(result), 3)
  for (.x in result) {
    expect_true(any(grepl("Total", .x$value, ignore.case = TRUE)))
  }
})

test_that("fre1: all NA variable with Total", {
  df <- tibble::tibble(
    normal = c("a", "b", "a"),
    all_na = rep(NA, 3)
  )
  result <- fre1(df, normal, all_na, .type = "list")
  expect_equal(length(result), 2)
  expect_true(any(grepl("Total", result$normal$value)))
})

test_that("fre1: factor with NA level in list output", {
  df <- tibble::tibble(
    x = factor(c("a", "b", NA), exclude = NULL),
    y = c(1, 2, 3)
  )
  result <- fre1(df, x, y, .type = "list")
  expect_true(any(is.na(result$x$value)))
  expect_true(any(grepl("Total", result$x$value, ignore.case = TRUE)))
})

# ============================================================================
# CHALLENGING TESTS - Boolean Expressions
# ============================================================================

test_that("fre1: boolean expressions as computed variables", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    x = 1:30,
    y = sample(letters[1:3], 30, replace = TRUE)
  )
  result <- fre1(df, x > 15, y == "a", .type = "list")
  expect_type(result, "list")
  expect_equal(length(result), 2)
})

test_that("fre1: complex boolean in tibble output", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    a = 1:50,
    b = sample(letters[1:3], 50, replace = TRUE),
    c = sample(c(TRUE, FALSE), 50, replace = TRUE)
  )
  result <- fre1(df, b, a > 20 & c, .type = "tibble")
  expect_s3_class(result, "tbl_df")
  expect_true("variable" %in% names(result))
})

# ============================================================================
# CHALLENGING TESTS - Sorting with .desc
# ============================================================================

test_that("fre1: .desc applied to all variables in list", {
  df <- tibble::tibble(
    x = c("z", "z", "a", "a", "m"),
    y = c(3, 3, 1, 1, 2)
  )
  result <- fre1(df, x, y, .desc = TRUE, .type = "list")
  non_total_x <- result$x[!grepl("Total", result$x$value, ignore.case = TRUE), ]
  expect_equal(non_total_x$n, c(2, 2, 1))
  expect_setequal(non_total_x$value[1:2], c("a", "z"))
})

test_that("fre1: .desc=FALSE preserves factor order", {
  df <- tibble::tibble(
    x = factor(c("high", "low", "med"), levels = c("low", "med", "high"))
  )
  result <- fre1(df, x, .desc = FALSE, .type = "list")
  non_total <- result$x[!grepl("Total", result$x$value, ignore.case = TRUE), ]
  expect_equal(as.character(non_total$value[1]), "low")
})

# ============================================================================
# CHALLENGING TESTS - Special Data Types
# ============================================================================

test_that("fre1: Date variables with Total", {
  df <- tibble::tibble(
    d1 = as.Date(c("2024-01-01", "2024-01-01", "2024-01-02")),
    d2 = as.Date(c("2024-06-01", "2024-06-01", "2024-06-02"))
  )
  result <- fre1(df, d1, d2, .type = "list")
  expect_type(result$d1$value, "character")
  expect_setequal(result$d1$value, c(as.character(unique(df$d1)), "Total"))
  expect_true(any(grepl("Total", result$d1$value, ignore.case = TRUE)))
})

test_that("fre1: POSIXct datetime with Total", {
  df <- tibble::tibble(
    t1 = as.POSIXct(c(
      "2024-01-01 10:00",
      "2024-01-01 10:00",
      "2024-01-02 12:00"
    )),
    t2 = as.POSIXct(c(
      "2024-06-01 08:00",
      "2024-06-01 08:00",
      "2024-06-02 08:00"
    ))
  )
  result <- fre1(df, t1, t2, .type = "list")
  expect_type(result$t1$value, "character")
  expect_setequal(result$t1$value, c(as.character(unique(df$t1)), "Total"))
  expect_equal(result$t1$n[result$t1$value == "Total"], nrow(df))
})

test_that("fre1: logical variables with Total", {
  df <- tibble::tibble(
    flag1 = c(TRUE, TRUE, FALSE),
    flag2 = c(FALSE, FALSE, TRUE)
  )
  result <- fre1(df, flag1, flag2, .type = "list")
  expect_true(any(result$flag1$value == TRUE))
  expect_true(any(grepl("Total", result$flag1$value, ignore.case = TRUE)))
})

test_that("fre1: haven labelled variables", {
  df <- tibble::tibble(
    x = haven::labelled(c(1, 1, 2), labels = c("A" = 1, "B" = 2)),
    y = haven::labelled(c(3, 3, 4), labels = c("X" = 3, "Y" = 4))
  )
  result <- fre1(df, x, y, .type = "list")
  expect_type(result, "list")
  expect_named(result, c("x", "y"))
  expect_setequal(result$x$value, c("A", "B", "Total"))
  expect_setequal(result$y$value, c("X", "Y", "Total"))
})

# ============================================================================
# CHALLENGING TESTS - Variable Selection
# ============================================================================

test_that("fre1: starts_with selection", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    temp_1 = sample(1:3, 50, replace = TRUE),
    temp_2 = sample(1:3, 50, replace = TRUE),
    pressure_1 = sample(1:3, 50, replace = TRUE)
  )
  result <- fre1(df, dplyr::starts_with("temp_"), .type = "list")
  expect_equal(length(result), 2)
})

test_that("fre1: ends_with selection", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    var_a_test = sample(letters[1:3], 50, replace = TRUE),
    var_b_test = sample(letters[1:3], 50, replace = TRUE),
    var_c_prod = sample(letters[1:3], 50, replace = TRUE)
  )
  result <- fre1(df, dplyr::ends_with("_test"), .type = "list")
  expect_equal(length(result), 2)
})

test_that("fre1: where() selection", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    num1 = 1:50,
    num2 = 51:100,
    char = sample(letters, 50, replace = TRUE),
    logi = sample(c(TRUE, FALSE), 50, replace = TRUE)
  )
  result <- fre1(df, dplyr::where(is.numeric), .type = "list")
  expect_equal(length(result), 2)
})

test_that("fre1: many variables (20+) with list output", {
  withr::local_preserve_seed()
  df <- tibble::as_tibble(
    replicate(20, sample(1:3, 50, replace = TRUE)),
    .name_repair = "minimal"
  )
  names(df) <- paste0("var", 1:20)
  result <- fre1(df, dplyr::everything(), .type = "list")
  expect_equal(length(result), 20)
})

# ============================================================================
# CHALLENGING TESTS - Edge Cases
# ============================================================================

test_that("fre1: single row dataset", {
  df <- tibble::tibble(x = "only", y = 1, z = TRUE)
  result <- fre1(df, x:z, .type = "list")
  expect_equal(length(result), 3)
  for (.x in result) {
    expect_equal(nrow(.x), 2) # value + Total
  }
})

test_that("fre1: all identical values in each variable", {
  df <- tibble::tibble(
    x = rep("same", 100),
    y = rep(42, 100),
    z = rep(TRUE, 100)
  )
  result <- fre1(df, x:z, .type = "list")
  for (.x in result) {
    expect_equal(nrow(.x), 2) # same + Total
    total_row <- .x[grepl("Total", .x$value, ignore.case = TRUE), ]
    expect_equal(total_row$n, 100)
  }
})

test_that("fre1: extreme cardinality differences", {
  df <- tibble::tibble(
    low_card = rep(1:2, 250),
    high_card = 1:500
  )
  result <- fre1(df, low_card, high_card, .type = "list")
  expect_equal(nrow(result$low_card), 3) # 1, 2, Total
  expect_equal(nrow(result$high_card), 501) # 500 unique + Total
})

test_that("fre1: empty data frame", {
  df <- tibble::tibble(x = numeric(0), y = character(0))
  result <- fre1(df, x, y, .type = "list")
  expect_equal(length(result), 2)
  for (.x in result) {
    expect_equal(nrow(.x), 0)
  }
})

# ============================================================================
# CHALLENGING TESTS - Unicode & Special Characters
# ============================================================================

test_that("fre1: unicode in multiple variables", {
  df <- tibble::tibble(
    cjk = c("中文", "日本語", "中文"),
    arabic = c("مرحبا", "مرحبا", "سلام"),
    emoji = c("🎉", "🎊", "🎉")
  )
  result <- fre1(df, cjk, arabic, emoji, .type = "list")
  expect_equal(length(result), 3)
  for (.x in result) {
    expect_equal(nrow(.x), 3)
  } # 2 unique + Total
})

# ============================================================================
# CHALLENGING TESTS - Reserved Names
# ============================================================================

test_that("fre1: variables named n, percent, cum, total", {
  df <- tibble::tibble(
    n = c(1, 1, 2),
    percent = c("a", "a", "b"),
    total = c("x", "y", "x")
  )
  # Measured names are list names, not columns, so they are not renamed.
  expect_no_message(result <- fre1(df, n, percent, total, .type = "list"))
  expect_named(result, c("n", "percent", "total"))
})

# ============================================================================
# CHALLENGING TESTS - Large-ish Data
# ============================================================================

test_that("fre1: moderate size dataset with list output", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    a = sample(1:5, 5000, replace = TRUE),
    b = sample(letters[1:5], 5000, replace = TRUE),
    c = sample(c(TRUE, FALSE), 5000, replace = TRUE)
  )
  result <- fre1(df, a:c, .type = "list")
  expect_equal(length(result), 3)
  for (.x in result) {
    expect_true(any(grepl("Total", .x$value)))
  }
})

test_that("fre1: fifteen variables stack into one tibble", {
  withr::local_preserve_seed()
  df <- tibble::as_tibble(
    replicate(15, sample(1:3, 100, replace = TRUE)),
    .name_repair = "minimal"
  )
  names(df) <- paste0("var", 1:15)
  result <- fre1(df, dplyr::everything(), .type = "tibble")
  expect_s3_class(result, "tbl_df")
  expect_true("variable" %in% names(result))
})

# ============================================================================
# CHALLENGING TESTS - Error Handling
# ============================================================================

test_that("fre1: NULL input should error", {
  expect_error(fre1(NULL))
})

test_that("fre1: non-existent column should error", {
  df <- tibble::tibble(x = 1:5)
  expect_error(fre1(df, y))
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("fre1: survey data with multiple questions", {
  withr::local_preserve_seed()
  set.seed(42)
  df <- tibble::tibble(
    q1_satisfaction = sample(1:5, 200, replace = TRUE),
    q2_recommend = sample(c("Yes", "No", "Maybe"), 200, replace = TRUE),
    q3_age_group = sample(
      c("18-25", "26-35", "36-50", "50+"),
      200,
      replace = TRUE
    ),
    q4_gender = sample(c("M", "F", "Other"), 200, replace = TRUE)
  )
  result <- fre1(df, q1_satisfaction:q4_gender, .type = "list")
  expect_equal(length(result), 4)
  for (.x in result) {
    expect_true(any(grepl("Total", .x$value)))
  }
})

test_that("fre1: demographic frequencies with grouping", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    country = sample(c("US", "UK", "DE"), 300, replace = TRUE),
    age_group = sample(
      c("18-25", "26-35", "36-50", "50+"),
      300,
      replace = TRUE
    ),
    gender = sample(c("Male", "Female"), 300, replace = TRUE)
  )
  result <- fre1(df, age_group, gender, .by = country, .type = "tibble")
  expect_true("country" %in% names(result))
  expect_true("variable" %in% names(result))
})

test_that("fre1: quality control multiple metrics", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    batch_id = rep(1:10, each = 20),
    pass_visual = sample(
      c(TRUE, FALSE),
      200,
      replace = TRUE,
      prob = c(0.95, 0.05)
    ),
    pass_measurement = sample(
      c(TRUE, FALSE),
      200,
      replace = TRUE,
      prob = c(0.90, 0.10)
    ),
    pass_functional = sample(
      c(TRUE, FALSE),
      200,
      replace = TRUE,
      prob = c(0.98, 0.02)
    )
  )
  result <- fre1(
    df,
    pass_visual:pass_functional,
    .by = batch_id,
    .type = "list"
  )
  expect_equal(length(result), 3)
})

test_that("milestone fre1 adds totals within each retained group", {
  d <- tibble::tibble(g = c("A", "A", "B", NA_character_), x = c(1, 2, 1, 2))
  out <- fre1(d, x, .by = g, .type = "list")$x
  totals <- out[!is.na(out$value) & out$value == "Total", ]
  expect_equal(
    totals$n[match(c("A", "B", NA_character_), totals$g)],
    c(2, 1, 1)
  )
  expect_equal(totals$percent, rep(100, 3))
})
