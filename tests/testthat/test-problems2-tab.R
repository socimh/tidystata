test_that("blank cross-tab categories have collision-safe headers", {
  data <- tibble::tibble(
    x = c("a", "a", "b", "b"),
    y = c("", "b", "<empty>", "<empty>1")
  )
  out <- xtab(data, x, y)
  expect_equal(out[["<empty>2"]], c(1L, 0L))
  expect_equal(out[["<empty>"]], c(0L, 1L))
  expect_equal(out[["<empty>1"]], c(0L, 1L))
  expect_equal(rowSums(as.data.frame(out[-1])), c(2, 2))
  expect_equal(tail(xtab(data, x, y, .total = TRUE)$total, 1), 4)
  expect_equal(xtab(data, y, x, .flip = TRUE), out)

  missing <- tibble::tibble(x = c("a", "a", "b"), y = c("", NA, ""))
  out <- xtab(missing, x, y)
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
  out <- xtab(data, x, y)
  expect_identical(names(out)[-1], c("FALSE", "TRUE", "NA"))
  expect_identical(out[[1]], c(FALSE, TRUE, NA))
  expect_identical(
    names(xtab(data, x, y, .total = TRUE))[-1],
    c("FALSE", "TRUE", "NA", "total")
  )
  expect_identical(
    names(xtab(data, x, y, .flip = TRUE))[-1],
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
  expect_error(tab(data, .group_order = "bad"), "arg")
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
  expect_identical(names(xtab(numbers, x, y))[-1], c("1", "2", "3", "10"))
  text <- tibble::tibble(x = c("a", "b", "b"), y = c("z", NA, "m"))
  expect_identical(names(xtab(text, x, y))[-1], c("m", "z", "NA"))
  expect_identical(
    names(xtab(text, x, y, .total = TRUE))[-1],
    c("m", "z", "NA", "total")
  )
  levels <- tibble::tibble(
    x = c("a", "b"),
    y = factor(c("lo", "hi"), levels = c("hi", "lo"))
  )
  expect_identical(names(xtab(levels, x, y))[-1], c("hi", "lo"))
  blank <- tibble::tibble(x = c("a", "b", "b"), y = c("z", "", "a"))
  expect_identical(names(xtab(blank, x, y))[-1], c("<empty>", "a", "z"))
  out <- xtab(numbers, x, y)
  expect_equal(out[["10"]], c(0L, 0L, 1L))
  expect_equal(out[["1"]], c(0L, 1L, 0L))
})

test_that("cross-tabs reject one-way and grouping controls", {
  d <- tibble::tibble(g = c("a", "b", "b"), x = c("p", "q", "q"))
  expect_error(xtab(d, x, g, .desc = TRUE), "`.desc`.*tab2")
  expect_error(xtab(d, x, .by = g), "`.by`.*tab2")
  expect_error(
    xtab(d, x, g, .group_order = "frequency", .total = TRUE),
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
