test_that("as_character is the code-to-text alias of tostring", {
  expect_identical(as_character, tostring)
  x <- haven::labelled(c(10, 20, 99, NA), c(No = 10, Yes = 20))
  expect_identical(as_character(x), c("10", "20", "99", NA_character_))
  expect_identical(decode(x), c("No", "Yes", "99", NA_character_))
  inputs <- list(
    factor(c("b", "a", NA)),
    c(1e15, 2e-7, NaN, Inf, haven::tagged_na("a")),
    structure(c(a = "x", b = NA_character_), label = "Text"),
    as.Date(c("2024-01-31", NA)),
    haven::labelled_spss(c(1, 99, NA), c(Yes = 1), na_values = 99)
  )
  for (input in inputs) {
    expect_identical(as_character(input), tostring(input))
  }
})

test_that("encode assigns sorted integer codes and retains the dictionary", {
  x <- c("beta", "alpha", "beta", "", NA_character_)
  before <- x
  out <- encode(x)
  expect_identical(
    out,
    haven::labelled(c(2L, 1L, 2L, NA, NA), c(alpha = 1L, beta = 2L))
  )
  expect_identical(decode(out), c("beta", "alpha", "beta", NA, NA))
  expect_identical(x, before)
  expect_identical(encode(x[c(2, 1, 3:5)]), out[c(2, 1, 3:5)])
})

test_that("encode treats numeric-looking strings as categories and retains spaces", {
  expect_identical(
    encode(c("20", "3", "10")),
    haven::labelled(c(2L, 3L, 1L), c("10" = 1L, "20" = 2L, "3" = 3L))
  )
  x <- c(" ", " a", "a", "a ", "NA", ".")
  expect_identical(decode(encode(x)), x)
  expect_identical(
    attr(encode(x), "labels"),
    stats::setNames(1:6, c(" ", " a", ".", "NA", "a", "a "))
  )
})

test_that("encode uses deterministic UTF-8 ordering", {
  x <- c("\u4e2d", "\u00e9", "z", "A", "a", "\u00e9")
  expect_identical(
    attr(encode(x), "labels"),
    stats::setNames(1:5, c("A", "a", "z", "\u00e9", "\u4e2d"))
  )
  expect_identical(decode(encode(x)), x)
})

test_that("encode preserves factor indices and unused levels", {
  for (ordered in c(FALSE, TRUE)) {
    x <- factor(
      c("Yes", "No", NA),
      levels = c("Unused", "No", "Yes"),
      ordered = ordered
    )
    before <- x
    out <- encode(x)
    expect_identical(
      out,
      haven::labelled(c(3L, 2L, NA), c(Unused = 1L, No = 2L, Yes = 3L))
    )
    expect_identical(decode(out), as.character(x))
    expect_identical(x, before)
    expect_identical(encode(x[1]), out[1])
  }
  x <- factor(c("10", "20"), levels = c("20", "10"))
  expect_identical(vctrs::vec_data(encode(x)), c(2L, 1L))
  expect_identical(attr(encode(x), "labels"), c("20" = 1L, "10" = 2L))
})

test_that("encode preserves an explicit empty-string factor level", {
  x <- factor(c("", "a", NA), levels = c("a", ""))
  out <- encode(x)
  expect_identical(vctrs::vec_data(out), c(2L, 1L, NA_integer_))
  expect_identical(attr(out, "labels"), stats::setNames(1:2, c("a", "")))
  expect_identical(decode(out), c("", "a", NA_character_))
})

test_that("encode returns typed empty and all-missing labelled vectors", {
  for (x in list(character(), factor())) {
    out <- encode(x)
    expect_s3_class(out, "haven_labelled")
    expect_identical(vctrs::vec_data(out), integer())
    expect_length(attr(out, "labels"), 0L)
  }
  out <- encode(factor(character(), levels = c("b", "a")))
  expect_identical(attr(out, "labels"), c(b = 1L, a = 2L))
  out <- encode(c(NA_character_, "", NA_character_))
  expect_s3_class(out, "haven_labelled")
  expect_identical(vctrs::vec_data(out), rep(NA_integer_, 3))
  expect_length(attr(out, "labels"), 0L)
})

test_that("encode retains an explicit NA factor level as a labelled index", {
  x <- factor(c("a", NA), exclude = NULL)
  out <- encode(x)
  expect_identical(vctrs::vec_data(out), c(1L, 2L))
  expect_identical(attr(out, "labels"), stats::setNames(1:2, c("a", NA)))
  expect_identical(decode(out), as.character(x))
})

test_that("encode reads stored character values rather than their value labels", {
  x <- haven::labelled(c("b", "a", NA), c(Other = "b"), label = "Question")
  expect_identical(
    encode(x),
    haven::labelled(c(2L, 1L, NA), c(a = 1L, b = 2L), label = "Question")
  )
})

test_that("encode does not reconstruct codes discarded by decode", {
  x <- haven::labelled(c(10, 20, 10), c(No = 10, Yes = 20))
  out <- encode(decode(x))
  expect_identical(out, haven::labelled(c(1L, 2L, 1L), c(No = 1L, Yes = 2L)))
  expect_identical(decode(out), decode(x))
})

test_that("encode validates its vector input with package errors", {
  inputs <- list(
    NULL,
    1:3,
    c(1, 2),
    TRUE,
    list("a"),
    data.frame(x = "a"),
    matrix("a")
  )
  for (x in inputs) {
    expect_error(encode(x), "character vector or factor", class = "rlang_error")
  }
  expect_error(encode(), "Missing `x`", class = "rlang_error")
})

test_that("encode works in mutate and across without changing grouping", {
  data <- tibble::tibble(g = c(1, 1, 2), x = c("b", "a", "b"))
  out <- dplyr::mutate(data, dplyr::across(x, encode))
  expect_identical(out$x, haven::labelled(c(2L, 1L, 2L), c(a = 1L, b = 2L)))
  grouped <- dplyr::group_by(dplyr::mutate(data, x = factor(x)), g)
  out <- dplyr::mutate(grouped, code = encode(x))
  expect_identical(dplyr::group_vars(out), "g")
  expect_identical(decode(out$code), data$x)
})
