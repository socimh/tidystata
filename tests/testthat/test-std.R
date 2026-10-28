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

test_that("pc() is exported and the retired pct() is absent", {
  expect_true("pc" %in% getNamespaceExports("tidystata"))
  expect_false("pct" %in% getNamespaceExports("tidystata"))
  expect_false(exists(
    "pct",
    envir = asNamespace("tidystata"),
    inherits = FALSE
  ))
})

test_that("pc() scales to a percentage of the total like egen pc()", {
  expect_equal(pc(c(2, 3, 5)), c(20, 30, 50))
  expect_equal(pc(c(2, 3, 5, NA), prop = TRUE), c(0.2, 0.3, 0.5, NA))
  expect_equal(pc(c(TRUE, FALSE, TRUE)), c(50, 0, 50))
  expect_identical(pc(c(0, 0)), c(NA_real_, NA_real_))
  expect_identical(pc(c(NA_real_, NA_real_)), c(NA_real_, NA_real_))
})

test_that("std() and pc() use each group in grouped mutate()", {
  data <- tibble::tibble(g = c("a", "a", "b", "b", "b"), x = c(1, 3, 1, 2, 7))
  out <- dplyr::mutate(data, z = std(x), share = pc(x), .by = g)
  expect_equal(
    out$z,
    c(as.vector(scale(c(1, 3))), as.vector(scale(c(1, 2, 7))))
  )
  expect_equal(out$share, c(25, 75, 10, 20, 70))
  grouped <- dplyr::mutate(dplyr::group_by(data, g), z = std(x))
  expect_equal(grouped$z, out$z)
})

test_that("std() and pc() report invalid inputs", {
  expect_snapshot(error = TRUE, {
    std(letters)
    std(factor("a"))
    std(1:3, mean = "a")
    std(1:3, sd = c(1, 2))
    pc(1:3, prop = NA)
    pc(as.Date("2020-01-01"))
  })
})

test_that("std() and pc() treat SPSS user-missing values as missing", {
  coded <- haven::labelled_spss(
    c(1, 2, 99),
    labels = c(dk = 99),
    na_values = 99
  )
  expect_equal(std(coded), c(as.vector(scale(c(1, 2))), NA))
  expect_equal(pc(coded), c(100 / 3, 200 / 3, NA))

  ranged <- haven::labelled_spss(c(1, 3, 97, 98), na_range = c(90, 100))
  expect_equal(std(ranged), c(as.vector(scale(c(1, 3))), NA, NA))
  expect_equal(pc(ranged, prop = TRUE), c(0.25, 0.75, NA, NA))

  data <- tibble::tibble(
    g = c("a", "a", "a", "b", "b"),
    x = haven::labelled_spss(c(1, 3, 99, 2, 6), na_values = 99)
  )
  out <- dplyr::mutate(data, z = std(x), share = pc(x), .by = g)
  expect_equal(
    out$z,
    c(as.vector(scale(c(1, 3))), NA, as.vector(scale(c(2, 6))))
  )
  expect_equal(out$share, c(25, 75, NA, 25, 75))
})

test_that("pc() is missing when the total is infinite", {
  expect_identical(pc(c(1, Inf)), c(NA_real_, NA_real_))
})


test_that("std() uses a signed scale multiplier", {
  out <- std(c(1, 2, 3, NA), mean = 10, sd = -2)
  expect_equal(out, c(12, 10, 8, NA))
  expect_equal(mean(out, na.rm = TRUE), 10)
  expect_equal(stats::sd(out, na.rm = TRUE), 2)
  expect_equal(std(c(1, 2, 3, NA), mean = 10, sd = 0), c(10, 10, 10, NA))
})
