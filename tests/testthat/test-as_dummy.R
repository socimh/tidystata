dummy_data <- tibble::tibble(
  id = 1:5,
  sex = c("m", "f", NA, "m", "f"),
  size = factor(c("s", "l", "s", NA, "s"), levels = c("s", "m", "l")),
  score = c(1, 2, 3, 4, 5)
)

test_that("as_dummy() adds 0/1 columns after the source, like tab, gen()", {
  out <- as_dummy(dummy_data, sex)
  expect_named(out, c("id", "sex", "sex_f", "sex_m", "size", "score"))
  expect_identical(
    out$sex_m,
    structure(c(1L, 0L, NA, 1L, 0L), label = "sex==m")
  )
  expect_identical(attr(out$sex_f, "label"), "sex==f")
  # Missing source values give missing indicators.
  expect_true(is.na(out$sex_f[[3]]))
  # Rows with an observed value have exactly one 1.
  observed <- !is.na(dummy_data$sex)
  expect_true(all(out$sex_f[observed] + out$sex_m[observed] == 1L))
})

test_that("as_dummy() follows factor levels and supports index names", {
  out <- as_dummy(dummy_data, size)
  # Unused levels are skipped; level order is kept.
  expect_identical(
    names(out),
    c("id", "sex", "size", "size_s", "size_l", "score")
  )
  index <- as_dummy(dummy_data, sex, size, .names = "index", .remove = TRUE)
  expect_named(
    index,
    c("id", "sex_1", "sex_2", "size_1", "size_2", "score")
  )
  expect_identical(attr(index$size_2, "label"), "size==l")
  logical <- as_dummy(tibble::tibble(flag = c(TRUE, FALSE)), flag)
  expect_named(logical, c("flag", "flag_FALSE", "flag_TRUE"))
})

test_that("as_dummy() labels labelled codes with their value labels", {
  out <- as_dummy(lifeexp, region)
  expect_identical(
    names(out)[1:4],
    c("region", "region_1", "region_2", "region_3")
  )
  expect_identical(attr(out$region_1, "label"), "region==Europe & C. Asia")
  expect_identical(
    sum(out$region_2),
    sum(vctrs::vec_data(lifeexp$region) == 2)
  )
})

test_that("as_dummy() treats SPSS user-missing codes as missing", {
  data <- tibble::tibble(
    answer = haven::labelled_spss(
      c(1, 2, 99, 1, 97),
      labels = c(yes = 1, no = 2, refused = 99),
      na_values = 99,
      na_range = c(97, 98)
    )
  )
  out <- as_dummy(data, answer)
  expect_named(out, c("answer", "answer_1", "answer_2"))
  expect_identical(as.vector(out$answer_1), c(1L, 0L, NA, 1L, NA))
  expect_identical(as.vector(out$answer_2), c(0L, 1L, NA, 0L, NA))
})

test_that("as_dummy() keeps containers and validates input", {
  grouped <- as_dummy(dplyr::group_by(dummy_data, sex), size)
  expect_identical(dplyr::group_vars(grouped), "sex")
  expect_error(
    as_dummy(dplyr::group_by(dummy_data, sex), sex, .remove = TRUE),
    "cannot be removed"
  )
  base <- as_dummy(as.data.frame(dummy_data), sex)
  expect_false(inherits(base, "tbl_df"))
  skip_if_not_installed("data.table")
  table <- data.table::as.data.table(dummy_data)
  out <- as_dummy(table, sex, .remove = TRUE)
  expect_s3_class(out, "data.table")
  expect_named(out, c("id", "sex_f", "sex_m", "size", "score"))
  # The input data.table is not modified by reference.
  expect_named(table, names(dummy_data))

  expect_error(as_dummy(dummy_data), "at least one variable")
  expect_error(as_dummy(1:3, x), "must be a data frame")
  expect_error(
    as_dummy(tibble::tibble(x = 1:2, x_1 = 3:4), x),
    "`x_1` already exists"
  )
  expect_error(
    as_dummy(tibble::tibble(x = list(1, 2)), x),
    "cannot be expanded"
  )
  expect_error(
    as_dummy(dummy_data, sex, .remove = NA),
    "must be `TRUE` or `FALSE`"
  )
})

test_that("as_dummy() keeps sf geometry", {
  skip_if_not_installed("sf")
  points <- sf::st_as_sf(
    tibble::tibble(k = c("a", "b"), x = 1:2, y = 1:2),
    coords = c("x", "y")
  )
  out <- as_dummy(points, k, .remove = TRUE)
  expect_s3_class(out, "sf")
  expect_identical(names(out), c("k_a", "k_b", "geometry"))
})

test_that("as_dummy() reports invalid input", {
  d <- tibble::tibble(sex = c("m", "f"), sex_f = 1:2)
  expect_snapshot(error = TRUE, {
    as_dummy(1:3)
    as_dummy(d, sex, .remove = NA)
    as_dummy(d, tidyselect::starts_with("none"))
    as_dummy(d, sex)
    as_dummy(dplyr::group_by(d, sex), sex, .remove = TRUE)
  })
})

test_that("columns without observed values add no indicators", {
  data <- tibble::tibble(id = 1:2, x = c(NA, NA))
  expect_identical(as_dummy(data, x), data)
  expect_named(as_dummy(data, x, .remove = TRUE), "id")
  expect_identical(as_dummy(data[0, ], x, .names = "index"), data[0, ])
})

test_that("values that format alike name the collision", {
  data <- tibble::tibble(x = c(0.3, 0.1 + 0.2))
  expect_error(
    as_dummy(data, x),
    "Several values would create the same column `x_0.3`"
  )
  expect_named(as_dummy(data, x, .names = "index"), c("x", "x_1", "x_2"))
})

test_that("removed source names can be reused by indicators", {
  inputs <- list(
    data.frame(x = 1:2, x_1 = c(3, 4)),
    tibble::tibble(x = 1:2, x_1 = c(3, 4))
  )
  if (requireNamespace("data.table", quietly = TRUE)) {
    inputs <- c(inputs, list(data.table::as.data.table(inputs[[1L]])))
  }
  expected <- list(
    x_1 = structure(c(1L, 0L), label = "x==1"),
    x_2 = structure(c(0L, 1L), label = "x==2"),
    x_1_3 = structure(c(1L, 0L), label = "x_1==3"),
    x_1_4 = structure(c(0L, 1L), label = "x_1==4")
  )
  for (data in inputs) {
    before <- if (inherits(data, "data.table")) data.table::copy(data) else data
    out <- as_dummy(data, x, x_1, .remove = TRUE)
    expect_identical(class(out), class(data))
    expect_identical(as.list(out), expected)
    expect_identical(data, before)
    expect_error(as_dummy(data, x, .remove = TRUE), "already exists")
  }
})

test_that("data.table results cannot silently lose rows with no columns", {
  skip_if_not_installed("data.table")
  data <- data.table::data.table(x = c(NA, NA))
  before <- data.table::copy(data)
  expect_error(
    as_dummy(data, x, .remove = TRUE),
    "retain.*source|identifier"
  )
  expect_identical(data, before)
  expect_identical(as_dummy(data, x), data)
  empty <- as_dummy(data[0, ], x, .remove = TRUE)
  expect_s3_class(empty, "data.table")
  expect_identical(dim(empty), c(0L, 0L))
  with_id <- data.table::data.table(id = 1:2, x = c(NA, NA))
  expect_identical(
    as_dummy(with_id, x, .remove = TRUE),
    data.table::data.table(id = 1:2)
  )
  # A temporary absence of columns is safe when indicators supply the result.
  observed <- as_dummy(data.table::data.table(x = 1:2), x, .remove = TRUE)
  expect_identical(dim(observed), c(2L, 2L))
})
