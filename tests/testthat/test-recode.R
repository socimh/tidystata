test_that("ranges are closed and continuous, with open ends", {
  x <- c(0.5, 1, 4.5, 5, 5.5, 10, NA)
  expect_identical(stata_recode(x, 1:5 ~ 1), c(0.5, 1, 1, 1, 5.5, 10, NA))
  expect_identical(
    stata_recode(x, min:1 ~ 0, 5.5:max ~ 9),
    c(0, 0, 4.5, 5, 9, 9, NA)
  )
  expect_identical(stata_recode(c(-5, -1, 0), -5:-1 ~ 1), c(1, 1, 0))
  expect_identical(stata_recode(x, (1:5) ~ 1), stata_recode(x, 1:5 ~ 1))
})

test_that("sets, nested unions and missing values are selected", {
  x <- c(1, 2, 3, 4, 7, NA, NaN)
  expect_identical(stata_recode(x, c(1, 7) ~ 0), c(0, 2, 3, 4, 0, NA, NaN))
  expect_identical(
    stata_recode(x, c(1, c(3:4, NA)) ~ 0),
    c(0, 2, 0, 0, 7, 0, 0)
  )
  expect_identical(stata_recode(x, NA ~ -1), c(1, 2, 3, 4, 7, -1, -1))
  expect_identical(stata_recode(x, seq(1, 3) ~ 0), c(0, 0, 0, 4, 7, NA, NaN))
  expect_identical(stata_recode(x, NULL ~ 0), x)
})

test_that("the first matching rule wins and rules see the original values", {
  x <- c(1, 2, 3)
  expect_identical(stata_recode(x, 1 ~ 2, 2 ~ 1), c(2, 1, 3))
  expect_identical(stata_recode(x, 1:3 ~ 0, 2 ~ 9), c(0, 0, 0))
  expect_identical(stata_recode(x, 2 ~ 9, 1:3 ~ 0), c(0, 9, 0))
})

test_that(".default keeps or replaces unmatched values", {
  x <- c(1, 2, 3, NA)
  expect_identical(stata_recode(x, 1 ~ 0), c(0, 2, 3, NA))
  expect_identical(stata_recode(x, 1 ~ 0, .default = NA), c(0, NA, NA, NA))
  expect_identical(stata_recode(x, 1 ~ 0, .default = -1), c(0, -1, -1, -1))
  expect_identical(
    stata_recode(x, 1 ~ 0, .default = c(10, 20, 30, 40)),
    c(0, 20, 30, 40)
  )
  expect_identical(stata_recode(x, 1 ~ 0, .default = x * 2), c(0, 4, 6, NA))
  expect_error(stata_recode(x, 1 ~ 0, .default = 1:2), ".default")
  expect_error(stata_recode(x, 1 ~ 0, .default = "a"), ".default")
})

test_that("the output type is the common integer or double type", {
  expect_identical(stata_recode(1:3, 1L ~ 0L), c(0L, 2L, 3L))
  expect_identical(stata_recode(1:3, 1L ~ NA), c(NA, 2L, 3L))
  expect_identical(stata_recode(c(1.5, 2), 2 ~ 0L), c(1.5, 0))
  expect_identical(stata_recode(numeric(), 1 ~ 2), numeric())
  expect_identical(
    stata_recode(c(NA_real_, NA_real_), 1 ~ 2),
    c(NA_real_, NA_real_)
  )
})

test_that("integer input stays integer when double codes are whole numbers", {
  x <- c(1L, 4L, 7L, NA)
  expect_identical(stata_recode(x, 1:5 ~ 1, NA ~ 9), c(1L, 1L, 7L, 9L))
  expect_identical(stata_recode(x, 1 ~ 0, .default = NA), c(0L, NA, NA, NA))
  expect_identical(stata_recode(x, 1 ~ 0, .default = x * 2), c(0L, 8L, 14L, NA))
  expect_identical(stata_recode(x, 1 ~ NA_real_), c(NA, 4L, 7L, NA))
  expect_identical(stata_recode(x, 1 ~ 0.5), c(0.5, 4, 7, NA))
  expect_identical(stata_recode(x, 1 ~ 0, .default = 0.5), c(0, 0.5, 0.5, 0.5))
  expect_identical(stata_recode(x, 1 ~ 2^31), c(2^31, 4, 7, NA))
  expect_identical(stata_recode(x, 1 ~ NaN), c(NaN, 4, 7, NA))
  expect_true(haven::is_tagged_na(stata_recode(x, 1 ~ haven::tagged_na("a"))[
    1
  ]))
  labelled <- haven::labelled(x, labels = c(One = 1L))
  expect_identical(stata_recode(labelled, 1 ~ 0), c(0L, 4L, 7L, NA))
  relabelled <- stata_recode(x, Low = 1:5 ~ 1)
  expect_identical(attr(relabelled, "labels"), c(Low = 1L))
  expect_identical(stata_recode(c(1, 2), 1 ~ 0), c(0, 2))
})

test_that("native matching retains integer and double storage for the same values", {
  integer_x <- c(a = 2L, b = 3L, c = 8L, d = NA_integer_)
  double_x <- c(a = 2, b = 3, c = 8, d = NA_real_)
  expect_identical(
    stata_recode(integer_x, 2 ~ 3, 3 ~ 2, .default = c(90, 91, 92, 93)),
    c(a = 3L, b = 2L, c = 92L, d = 93L)
  )
  expect_identical(
    stata_recode(double_x, 2L ~ 3L, 3L ~ 2L, .default = c(90L, 91L, 92L, 93L)),
    c(a = 3, b = 2, c = 92, d = 93)
  )
})

test_that("empty and all-missing vectors keep their storage types", {
  expect_identical(stata_recode(integer(), 1 ~ 2), integer())
  expect_identical(stata_recode(numeric(), 1L ~ 2L), numeric())
  expect_identical(stata_recode(rep(NA_integer_, 2), NA ~ 0), c(0L, 0L))
  expect_identical(stata_recode(rep(NA_real_, 2), NA ~ 0L), c(0, 0))
  labelled <- stata_recode(integer(), New = 1 ~ 2)
  expect_identical(
    labelled,
    haven::labelled(integer(), labels = c(New = 2L))
  )
})

test_that("label restoration retains native storage for SPSS inputs", {
  integer_x <- haven::labelled_spss(
    c(a = 2L, b = 99L, c = 3L),
    na_values = 99L,
    label = "Codes"
  )
  double_x <- haven::labelled_spss(
    c(a = 2, b = 99, c = 3),
    na_values = 99,
    label = "Codes"
  )
  expect_identical(
    stata_recode(integer_x, Swap = 2 ~ 3, Missing = NA ~ 0, .default = 9),
    haven::labelled(
      c(a = 3L, b = 0L, c = 9L),
      labels = c(Swap = 3L, Missing = 0L),
      label = "Codes"
    )
  )
  expect_identical(
    stata_recode(double_x, Swap = 2L ~ 3L, Missing = NA ~ 0L, .default = 9L),
    haven::labelled(
      c(a = 3, b = 0, c = 9),
      labels = c(Swap = 3, Missing = 0),
      label = "Codes"
    )
  )
})

test_that("the reserved integer missing code is never narrowed from double", {
  expect_identical(stata_recode(c(1L, 2L), 1 ~ -(2^31)), c(-(2^31), 2))
  expect_identical(
    stata_recode(c(1L, 2L), 1 ~ 0, .default = -(2^31)),
    c(0, -(2^31))
  )
  expect_identical(stata_recode(c(1L, 2L), 1 ~ Inf), c(Inf, 2))
})

test_that("names and the variable label are kept, value labels dropped", {
  x <- haven::labelled(
    c(a = 1, b = 2, c = 3),
    labels = c(One = 1, Two = 2),
    label = "Score"
  )
  out <- stata_recode(x, 1 ~ 0)
  expect_false(inherits(out, "haven_labelled"))
  expect_identical(names(out), c("a", "b", "c"))
  expect_identical(attr(out, "label"), "Score")
  expect_null(attr(out, "labels"))
  expect_identical(unname(as.numeric(out)), c(0, 2, 3))
  expect_identical(stata_recode(c(a = 1, b = 2), 1 ~ 0), c(a = 0, b = 2))
})

test_that("named rules create value labels", {
  x <- c(1, 4, 8, NA)
  out <- stata_recode(x, Low = 1:5 ~ 1, High = 6:max ~ 2, Unused = 99 ~ 3)
  expect_s3_class(out, "haven_labelled")
  expect_identical(as.numeric(out), c(1, 1, 2, NA))
  expect_identical(attr(out, "labels"), c(Low = 1, High = 2, Unused = 3))
  partial <- stata_recode(x, Low = 1 ~ 1, 4 ~ 2)
  expect_identical(attr(partial, "labels"), c(Low = 1))
  repeated <- stata_recode(x, Low = 1 ~ 1, Low = 4 ~ 1)
  expect_identical(attr(repeated, "labels"), c(Low = 1))
  int <- stata_recode(1:3, A = 1L ~ 0L)
  expect_identical(attr(int, "labels"), c(A = 0L))
  labelled <- haven::labelled(c(1, 2), labels = c(Old = 1), label = "Var")
  relabelled <- stata_recode(labelled, New = 1 ~ 5)
  expect_identical(attr(relabelled, "labels"), c(New = 5))
  expect_identical(attr(relabelled, "label"), "Var")
})

test_that("conflicting labels are rejected", {
  x <- c(1, 2)
  expect_error(stata_recode(x, A = 1 ~ 1, B = 2 ~ 1), "more than one label")
  expect_error(stata_recode(x, A = 1 ~ 1, A = 2 ~ 2), "more than one code")
  expect_error(stata_recode(x, A = 1 ~ NA), "Missing codes cannot be labelled")
})

test_that("tagged and SPSS missing values are handled", {
  x <- c(1, haven::tagged_na("a"), NA, 3)
  expect_identical(haven::na_tag(stata_recode(x, 1 ~ 0)), c(NA, "a", NA, NA))
  expect_identical(stata_recode(x, NA ~ 9), c(1, 9, 9, 3))
  spss <- haven::labelled_spss(
    c(1, 99, -9, 3),
    labels = c(Yes = 1, Refused = 99),
    na_values = 99,
    na_range = c(-9, -1)
  )
  out <- stata_recode(spss, 1 ~ 0)
  expect_false(inherits(out, "haven_labelled"))
  expect_null(attr(out, "na_values"))
  expect_identical(as.numeric(out), c(0, NA, NA, 3))
  expect_identical(as.numeric(stata_recode(spss, NA ~ 5)), c(1, 5, 5, 3))
})

test_that("bounds and stored rules come from the calling environment", {
  lo <- 2
  hi <- 4
  expect_identical(stata_recode(c(1, 2, 3, 4, 5), lo:hi ~ 0), c(1, 0, 0, 0, 5))
  codes <- c(1, 5)
  expect_identical(stata_recode(c(1, 2, 3, 4, 5), codes ~ 0), c(0, 2, 3, 4, 0))
  rules <- list(1 ~ 10, Two = 2 ~ 20)
  out <- stata_recode(c(1, 2, 3), !!!rules)
  expect_identical(as.numeric(out), c(10, 20, 3))
  expect_identical(attr(out, "labels"), c(Two = 20))
  make_rule <- function(value) {
    local_value <- value
    local_value ~ 0
  }
  expect_identical(stata_recode(c(1, 2), make_rule(2)), c(1, 0))
  expect_identical(stata_recode(c(1, 5), min(3, 4):max ~ 0), c(1, 0))
})

test_that("malformed rules and inputs give informative errors", {
  x <- c(1, 2)
  expect_error(stata_recode(), "Missing `x`")
  expect_error(stata_recode(x), "at least one rule")
  expect_error(stata_recode(x, 1), "two-sided formula")
  expect_error(stata_recode(x, ~1), "two-sided formula")
  expect_error(stata_recode(x, 5:1 ~ 1), "low to high")
  expect_error(stata_recode(x, NA:3 ~ 1), "single non-missing numbers")
  expect_error(stata_recode(x, c(1, 2):3 ~ 1), "single non-missing numbers")
  expect_error(stata_recode(x, 1 ~ "a"), "single number")
  expect_error(stata_recode(x, 1 ~ c(1, 2)), "single number")
  expect_error(stata_recode(x, "a" ~ 1), "numeric")
  expect_error(stata_recode(letters, 1 ~ 2), "dplyr::replace_values")
  expect_error(stata_recode(letters, 1 ~ 2), "dplyr::case_match")
  expect_error(stata_recode(factor("a"), 1 ~ 2), "forcats::fct_recode")
  expect_error(stata_recode(c(TRUE, FALSE), TRUE ~ 0), "numeric vector")
  expect_error(stata_recode(Sys.Date(), 1 ~ 2), "numeric vector")
  expect_snapshot(stata_recode(x, 5:1 ~ 1), error = TRUE)
  expect_snapshot(stata_recode(x, 1 ~ "a"), error = TRUE)
})

test_that("classed numeric bounds and values are rejected", {
  skip_if_not_installed("bit64")
  x <- c(1, 2)
  big <- bit64::as.integer64(3)
  expect_error(stata_recode(x, 0:big ~ 1), "single non-missing numbers")
  expect_error(stata_recode(x, big ~ 1), "numeric")
})

test_that("stata_recode() works in grouped mutate() and across()", {
  d <- tibble::tibble(g = c(1, 1, 2), a = c(1, 2, 3), b = c(2, 2, 1))
  out <- dplyr::mutate(
    dplyr::group_by(d, g),
    dplyr::across(
      c(a, b),
      function(v) stata_recode(v, 1 ~ 0),
      .names = "r_{.col}"
    )
  )
  expect_identical(out$r_a, c(0, 2, 3))
  expect_identical(out$r_b, c(2, 2, 0))
  out <- dplyr::mutate(
    d,
    a = stata_recode(a, Low = 1:2 ~ 1, .default = 2),
    .by = g
  )
  expect_s3_class(out$a, "haven_labelled")
  expect_identical(as.numeric(out$a), c(1, 1, 2))
})

test_that("recode() is an alias of stata_recode()", {
  expect_identical(recode, stata_recode)
  expect_identical(
    recode(c(1, 4.5, 7), 1:5 ~ 1, Low = 6:10 ~ 2),
    stata_recode(c(1, 4.5, 7), 1:5 ~ 1, Low = 6:10 ~ 2)
  )
})

test_that("swaps preserve shared inputs and vector defaults", {
  x <- c(a = 2L, b = 3L, c = 8L, d = NA_integer_)
  shared <- x
  default <- c(90L, 91L, 92L, 93L)
  before <- serialize(list(x, shared, default), NULL)
  out <- stata_recode(x, 2L ~ 3L, 3L ~ 2L, .default = default)
  expect_identical(out, c(a = 3L, b = 2L, c = 92L, d = 93L))
  expect_identical(serialize(list(x, shared, default), NULL), before)
})

test_that("SPSS input and defaults normalize independently", {
  x <- haven::labelled_spss(
    c(2L, 99L, -9L, NA_integer_),
    na_values = 99L,
    na_range = c(-9L, -1L),
    label = "Original"
  )
  default <- haven::labelled_spss(
    c(99L, 8L, -9L, 6L),
    na_values = 99L,
    na_range = c(-9L, -1L),
    label = "Default"
  )
  before <- serialize(list(x, default), NULL)
  out <- stata_recode(x, 2L ~ 3L, 99L ~ 7L, .default = default)
  expect_identical(as.numeric(out), c(3, 8, NA, 6))
  expect_type(out, "integer")
  expect_identical(attr(out, "label"), "Original")
  expect_null(attr(out, "na_values"))
  expect_identical(
    as.numeric(stata_recode(x, NA ~ 0L)),
    c(2, 0, 0, 0)
  )
  scalar <- haven::labelled_spss(99L, na_values = 99L)
  expect_identical(
    stata_recode(c(2L, 8L), 2L ~ 3L, .default = scalar),
    c(3L, NA_integer_)
  )
  expect_identical(serialize(list(x, default), NULL), before)
})

test_that("missing payloads survive defaults and replacement codes", {
  tag_a <- haven::tagged_na("a")
  tag_z <- haven::tagged_na("z")
  x <- c(2, NA_real_, NaN, tag_a, -Inf, Inf)
  expected <- c(tag_z, NA_real_, NaN, tag_a, -Inf, Inf)
  out <- stata_recode(x, 2 ~ tag_z)
  expect_identical(writeBin(out, raw()), writeBin(expected, raw()))
  default <- c(8, NaN, tag_z, tag_a, -0, Inf)
  out <- stata_recode(x, 2 ~ 3, .default = default)
  expect_identical(writeBin(out, raw()), writeBin(c(3, default[-1]), raw()))
  expect_identical(stata_recode(x, tag_z ~ 9), c(2, 9, 9, 9, -Inf, Inf))
})

test_that("exact sets and unions handle signed zero and infinite endpoints", {
  codes <- c(seq_len(2048), 0, -0, -Inf, Inf, NA_real_)
  x <- c(-Inf, -0, 1, 2048, 2049, 2.5, Inf, NA_real_, NaN)
  expect_identical(
    stata_recode(x, codes ~ 7),
    c(7, 7, 7, 7, 2049, 2.5, 7, 7, 7)
  )
  expect_identical(
    stata_recode(x, c(c(), NULL, -Inf:-Inf, 2:3, Inf, NA) ~ 8),
    c(8, 0, 1, 2048, 2049, 8, 8, 8, 8)
  )
  expect_identical(stata_recode(x, c() ~ 8), x)
})

test_that("rule expressions evaluate once in their original order", {
  seen <- character()
  mark <- function(name, value) {
    seen <<- c(seen, name)
    value
  }
  out <- stata_recode(
    c(1, 2, 3),
    c(mark("left1", 1), mark("lower", 2):mark("upper", 2)) ~ mark("right1", 4),
    mark("left2", 3) ~ mark("right2", 5),
    .default = mark("default", 9)
  )
  expect_identical(out, c(4, 4, 5))
  expect_identical(
    seen,
    c("right1", "left1", "lower", "upper", "right2", "left2", "default")
  )
})

test_that("compact sequences and empty defaults retain numeric contracts", {
  expect_identical(
    stata_recode(1:12, 2:4 ~ 7L, 10:12 ~ 0L),
    c(1L, 7L, 7L, 7L, 5L, 6L, 7L, 8L, 9L, 0L, 0L, 0L)
  )
  expect_identical(
    stata_recode(integer(), 1L ~ 2L, .default = integer()),
    integer()
  )
  expect_identical(stata_recode(integer(), 1L ~ 2L, .default = NA), integer())
  expect_identical(
    stata_recode(c(1L, 2L), 1L ~ 3L, .default = c(NA, NA)),
    c(3L, NA_integer_)
  )
  expect_error(stata_recode(1:2, 1L ~ 0L, .default = numeric()), ".default")
})

test_that("integer extremes survive swaps without overflow", {
  high <- .Machine$integer.max
  low <- -high
  x <- c(high, low, 0L, NA_integer_)
  expect_identical(
    stata_recode(x, high ~ low, low ~ high),
    c(low, high, 0L, NA_integer_)
  )
  expect_identical(stata_recode(x, high ~ Inf), c(Inf, low, 0, NA_real_))
})

test_that("complex values cannot enter the integer/double engine", {
  expect_error(stata_recode(1 + 1i, 1L ~ 0L), "numeric vector")
  expect_error(stata_recode(1L, (1 + 1i) ~ 0L), "values in rule")
  expect_error(stata_recode(1L, 1L ~ (1 + 1i)), "code in rule")
  expect_error(stata_recode(1L, 1L ~ 0L, .default = 1 + 1i), ".default")
  expect_error(stata_recode(1L, 0:(1 + 1i) ~ 0L), "Range bounds")
})

test_that("uncast plain defaults retain their non-label attributes", {
  default <- structure(c(8, 9), note = "kept", label = "Default")
  x <- structure(c(1, 2), label = "Input")
  expect_identical(
    stata_recode(x, 1 ~ 3, .default = default),
    structure(c(3, 9), note = "kept", label = "Input")
  )
  expect_identical(
    stata_recode(numeric(), 1 ~ 3, .default = structure(8, note = "kept")),
    structure(numeric(), note = "kept")
  )
})

test_that("default metadata follows casting and label restoration", {
  default <- structure(c(8L, 9L), note = "kept", names = c("u", "v"))
  expect_identical(
    stata_recode(c(a = 1L, b = 2L), 1L ~ 3L, .default = default),
    structure(c(a = 3L, b = 9L), note = "kept")
  )
  expect_identical(
    stata_recode(c(a = 1, b = 2), 1 ~ 3, .default = default),
    c(a = 3, b = 9)
  )
  out <- stata_recode(c(1L, 2L), New = 1L ~ 3L, .default = default)
  expect_null(attr(out, "note"))
  expect_identical(attr(out, "labels"), c(New = 3L))
  labelled <- haven::labelled(default, label = "Default")
  expect_identical(
    stata_recode(c(1L, 2L), 1L ~ 3L, .default = labelled),
    c(3L, 9L)
  )
})
