# Explicit contracts for no measured variables and unflattened list values.

for (.function_name in c("tab", "fre")) {
  test_that(paste(.function_name, "returns a typed empty table for no selected variables"), {
    fn <- get(.function_name, mode = "function")
    d <- tibble::tibble(x = 1:3, y = letters[1:3])
    before <- d
    expected <- tibble::tibble(
      n = integer(), percent = double(), cum = double(),
      valid = double(), valid_cum = double()
    )
    expect_identical(fn(d, tidyselect::starts_with("absent")), expected)
    expect_identical(fn(d, -tidyselect::everything()), expected)
    expect_identical(fn(d[, FALSE]), expected)
    expect_identical(d, before)
  })

  test_that(paste(.function_name, "retains typed empty grouping keys without measured variables"), {
    fn <- get(.function_name, mode = "function")
    d <- tibble::tibble(
      g = factor(c("A", NA, "B"), levels = c("A", "B", "unused")),
      day = as.Date("2024-01-01") + 0:2, x = 1:3
    )
    before <- d
    out <- fn(d, tidyselect::starts_with("absent"), .by = c(g, day))
    expect_named(out, c("g", "day", "n", "percent", "cum", "valid", "valid_cum"))
    expect_equal(nrow(out), 0)
    expect_identical(out$g, d$g[0])
    expect_identical(out$day, d$day[0])
    expect_identical(out$n, integer())
    grouped <- dplyr::group_by(d, g, day)
    expect_identical(fn(grouped, tidyselect::starts_with("absent")), out)
    expect_identical(d, before)
  })
}

for (.function_name in c("tab1", "fre1")) {
  test_that(paste(.function_name, "preserves empty list and table output containers"), {
    fn <- get(.function_name, mode = "function")
    d <- tibble::tibble(g = factor(c("A", "B")), x = 1:2)
    before <- d
    out <- fn(d, tidyselect::starts_with("absent"))
    expect_type(out, "list")
    expect_length(out, 0)
    expect_length(fn(d[, FALSE]), 0)
    table <- fn(d, tidyselect::starts_with("absent"), .type = "tibble")
    expect_s3_class(table, "tbl_df")
    expect_equal(nrow(table), 0)
    expect_named(table, c("variable", "value", "n", "percent", "cum", "valid", "valid_cum"))
    grouped <- fn(d, tidyselect::starts_with("absent"), .by = g, .type = "tibble")
    expect_named(grouped, c("g", names(table)))
    expect_identical(grouped$g, d$g[0])
    expect_identical(grouped[-1], table)
    expect_length(fn(d, tidyselect::starts_with("absent"), .by = g), 0)
    expect_identical(d, before)
  })
}

for (.function_name in c("tab2", "fre2")) {
  test_that(paste(.function_name, "returns an empty tibble only when zero variables are selected"), {
    fn <- get(.function_name, mode = "function")
    d <- tibble::tibble(x = 1:3, y = letters[1:3], z = 3:1)
    before <- d
    for (flip in c(FALSE, TRUE)) {
      expect_identical(fn(d, tidyselect::starts_with("absent"), .flip = flip), tibble::tibble())
      expect_identical(fn(d[, FALSE], .flip = flip), tibble::tibble())
    }
    expect_error(fn(d, x), "Please provide two variables")
    expect_error(fn(d, x, y, z), "Please provide only two variables")
    expect_identical(d, before)
  })
}

test_that("tab counts repeated nested list identities without flattening", {
  first <- list(values = 1:3, detail = list(flag = TRUE, values = c(4, 5)))
  second <- list(values = 3:1, detail = list(flag = TRUE, values = c(4, 5)))
  d <- tibble::tibble(value = list(first, second, first, first, second))
  before <- d
  out <- tab(d, value)
  expect_type(out$value, "list")
  expect_equal(nrow(out), 2)
  first_row <- vapply(out$value, identical, logical(1), first)
  second_row <- vapply(out$value, identical, logical(1), second)
  expect_equal(sum(first_row), 1)
  expect_equal(sum(second_row), 1)
  expect_equal(out$n[first_row], 3L)
  expect_equal(out$n[second_row], 2L)
  expect_equal(out$percent[first_row], 60)
  expect_equal(out$percent[second_row], 40)
  expect_identical(d, before)
})
