test_that("std() standardises like egen std() and scale()", {
  x <- c(1, 2, 3, NA, 10)
  out <- std(x)
  expect_type(out, "double")
  expect_null(dim(out))
  expect_equal(out, as.vector(scale(x)))
  expect_true(is.na(out[[4]]))
  expect_equal(std(x, mean = 50, sd = 10), as.vector(scale(x)) * 10 + 50)
  expect_equal(std(c(TRUE, FALSE)), c(1, -1) / sqrt(2))
  expect_equal(std(haven::labelled(c(1, 2, 3), c(low = 1))), c(-1, 0, 1))
  # Zero or undefined spread gives missing values, as in Stata.
  expect_identical(std(c(5, 5, NA)), rep(NA_real_, 3))
  expect_identical(std(c(5, NA)), c(NA_real_, NA_real_))
  expect_identical(std(numeric()), numeric())
})

test_that("pct() scales to a percentage of the total like egen pc()", {
  expect_equal(pct(c(2, 3, 5)), c(20, 30, 50))
  expect_equal(pct(c(2, 3, 5, NA), prop = TRUE), c(0.2, 0.3, 0.5, NA))
  expect_equal(pct(c(TRUE, FALSE, TRUE)), c(50, 0, 50))
  expect_identical(pct(c(0, 0)), c(NA_real_, NA_real_))
  expect_identical(pct(c(NA_real_, NA_real_)), c(NA_real_, NA_real_))
})

test_that("std() and pct() use each group in grouped mutate()", {
  data <- tibble::tibble(g = c("a", "a", "b", "b", "b"), x = c(1, 3, 1, 2, 7))
  out <- dplyr::mutate(data, z = std(x), share = pct(x), .by = g)
  expect_equal(
    out$z,
    c(as.vector(scale(c(1, 3))), as.vector(scale(c(1, 2, 7))))
  )
  expect_equal(out$share, c(25, 75, 10, 20, 70))
  grouped <- dplyr::mutate(dplyr::group_by(data, g), z = std(x))
  expect_equal(grouped$z, out$z)
})

test_that("std() and pct() report invalid inputs", {
  expect_snapshot(error = TRUE, {
    std(letters)
    std(factor("a"))
    std(1:3, mean = "a")
    std(1:3, sd = c(1, 2))
    pct(1:3, prop = NA)
    pct(as.Date("2020-01-01"))
  })
})
