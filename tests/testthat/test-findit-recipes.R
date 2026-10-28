findit_recipe_eval <- function(id, data) {
  entries <- findit_entries()
  row <- entries[entries$id == id, , drop = FALSE]
  stopifnot(nrow(row) == 1L)
  scope <- new.env(parent = asNamespace("tidystata"))
  scope$data <- data
  scope$mutate <- dplyr::mutate
  value <- eval(parse(text = row$r, encoding = "UTF-8"), scope)
  list(row = row, value = value, data = scope$data)
}

test_that("moving-average lookups retain partial and nonmissing windows", {
  skip_if_not_installed("zoo")
  queries <- c(
    "tssmooth ma smooth = y, window(2 1 2)",
    "tssmooth ma smooth = y, window(3 1 0)"
  )
  inputs <- list(
    c(2, 7, 1, 8, 3, 6, 4),
    c(2, 7, NA, 8, 3, 6, 4),
    rep(NA_real_, 7),
    rep(1000000000L, 7),
    c(2, 7),
    numeric()
  )
  for (i in seq_along(queries)) {
    found <- findit(!!queries[i])
    expect_identical(found$package[1], "zoo")
    for (y in inputs) {
      data <- data.frame(y = y, t = seq_along(y))
      original <- data
      result <- findit_recipe_eval(attr(found, "entry_ids")[1], data)$value
      expected <- vapply(
        seq_along(y),
        function(j) {
          positions <- if (i == 1L) (j - 2L):(j + 2L) else (j - 3L):j
          positions <- positions[positions >= 1L & positions <= length(y)]
          values <- y[positions]
          if (all(is.na(values))) {
            NA_real_
          } else {
            mean(values, na.rm = TRUE)
          }
        },
        numeric(1)
      )
      expect_equal(result$smooth, expected)
      expect_identical(result$y, y)
      expect_identical(result$t, data$t)
      expect_identical(data, original)
    }
  }
  bandpass <- findit(
    "tsfilter bk cycle = y, minperiod(6) maxperiod(32) smaorder(12)"
  )
  expect_true(any(grepl("stats::filter(", bandpass$r, fixed = TRUE)))
  expect_true(any(grepl(
    "stats::filter(",
    capture.output(print(bandpass)),
    fixed = TRUE
  )))
})

test_that("encode recipes retain value labels and use the package helper", {
  cases <- list(
    list(id = "legacy-0103", input = "str_x", output = "x"),
    list(id = "ref-6a9067808b1b3f86", input = "s", output = "code")
  )
  for (case in cases) {
    data <- stats::setNames(data.frame(c("beta", "alpha", "", NA)), case$input)
    result <- findit_recipe_eval(case$id, data)
    expect_identical(result$row$package, "tidystata")
    expect_match(result$row$r, "encode(", fixed = TRUE)
    expect_identical(
      result$value[[case$output]],
      haven::labelled(c(2L, 1L, NA, NA), c(alpha = 1L, beta = 2L))
    )
  }
  expect_true(all(findit(encode)$package == "tidystata"))
  expect_identical(attr(findit(as_character), "r_functions")$stata, "tostring")
})

test_that("egen row recipes use available helpers with Stata missing rules", {
  data <- data.frame(x = c(1, NA, NA, -2), y = c(3, 4, NA, 2))
  ids <- c(
    "ref-038e8cc6375ff627",
    "ref-9ced89f8da86feb5",
    "ref-e3fdfca719ea1d2e",
    "ref-7735c1a2733e8be5",
    "ref-b50bc182f37f5862",
    "ref-5641b7f81ce6212c",
    "ref-7af87a24fcf6bea1"
  )
  expected <- list(
    c(2, 4, NA, 0),
    c(4, 4, 0, 0),
    c(4, 4, NA, 0),
    c(0L, 1L, 2L, 0L),
    c(2L, 1L, 0L, 2L),
    c(1, 4, NA, -2),
    c(3, 4, NA, 2)
  )
  for (i in seq_along(ids)) {
    result <- findit_recipe_eval(ids[[i]], data)
    expect_identical(result$row$package, "tidystata", info = ids[[i]])
    expect_identical(result$value$z, expected[[i]], info = ids[[i]])
    expect_identical(result$data, data, info = ids[[i]])
  }
})

test_that("recode recipes retain values outside stated closed ranges", {
  data <- data.frame(x = c(-1, 1, 1.5, 2, 2.5, 3, 6, 7, NA))
  result <- findit_recipe_eval("ref-d0dd21fae1a3453f", data)
  expect_identical(result$row$package, "tidystata")
  expect_identical(result$data$binary, c(-1, 0, 0, 0, 2.5, 1, 1, 7, NA))
  result <- findit_recipe_eval("legacy-0121", data)
  expect_identical(result$row$package, "tidystata")
  expect_identical(result$value$x3g, c(NA, 1, 1, 1, 1, 1, 2, 2, NA))
})

test_that("conversion recipes use helpers without losing missing observations", {
  result <- findit_recipe_eval(
    "ref-dc44522916cd0a0d",
    data.frame(s = c("1.5", "", ".", NA))
  )
  expect_identical(result$row$package, "tidystata")
  expect_identical(result$data$x, c(1.5, NA, NA, NA))
  result <- findit_recipe_eval(
    "ref-d73e59a68b9dd053",
    data.frame(s = c("1,200", "", NA))
  )
  expect_identical(result$row$package, "tidystata")
  expect_identical(result$data$x, c(1200, NA, NA))
})

test_that("duplicates report recipes include ordinary missing keys", {
  data <- data.frame(id = c(1, 1, 2, NA, NA), x = 1:5)
  result <- findit_recipe_eval("ref-95785554b623cb63", data)
  expect_identical(result$row$package, "tidystata")
  expect_identical(result$value$copies, c(1L, 2L))
  expect_identical(result$value$observations, c(1L, 4L))
  expect_identical(result$value$surplus, c(0L, 2L))
})

test_that("alpha mappings do not replace reliability estimation with row means", {
  expect_false("ref-6e3973ff3ac031d5" %in% findit_entries()$id)
})

test_that("percentile-rank recipes retain missing values and minimum ties", {
  entries <- findit_entries()
  rows <- entries[grepl("dplyr::percent_rank(", entries$r, fixed = TRUE), ]
  expect_identical(nrow(rows), 2L)
  for (i in seq_len(nrow(rows))) {
    percent <- grepl("100 *", rows$r[[i]], fixed = TRUE)
    scale <- if (percent) 100 else 1
    inputs <- list(
      c(2, 3, 5, NA),
      c(2, 3, 3, 5, NA),
      c(2, 5, 5, NA),
      c(2, NA),
      c(NA_real_, NA_real_)
    )
    expected <- list(
      c(0, 0.5, 1, NA),
      c(0, 1 / 3, 1 / 3, 1, NA),
      c(0, 0.5, 0.5, NA),
      c(NaN, NA),
      c(NA_real_, NA_real_)
    )
    for (j in seq_along(inputs)) {
      x <- inputs[[j]]
      result <- findit_recipe_eval(rows$id[[i]], data.frame(x = x))
      expect_equal(result$value$p, expected[[j]] * scale)
      expect_identical(result$value$x, x)
    }
  }
})

test_that("percentile-rank lookups customize names without reserving columns", {
  for (output in c("position", "income_rank", "income_n")) {
    found <- findit(dplyr::percent_rank, !!output, income)
    expect_identical(nrow(found), 2L)
    for (i in seq_len(nrow(found))) {
      expect_match(found$stata[[i]], "tempvar x_rank x_n", fixed = TRUE)
      expect_match(
        found$stata[[i]],
        "egen `x_rank' = rank(income)",
        fixed = TRUE
      )
      expect_match(
        found$stata[[i]],
        "egen `x_n' = count(income)",
        fixed = TRUE
      )
      scope <- new.env(parent = globalenv())
      scope$data <- data.frame(income = c(2, 3, 5, NA))
      result <- eval(parse(text = found$r[[i]]), scope)
      expected <- if (grepl("100 *", found$r[[i]], fixed = TRUE)) {
        c(0, 50, 100, NA)
      } else {
        c(0, 0.5, 1, NA)
      }
      expect_equal(result[[output]], expected)
      expect_identical(result$income, c(2, 3, 5, NA))
    }
  }
})
