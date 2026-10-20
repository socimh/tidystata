test_that("historical units and labelled metadata remain usable", {
  if (requireNamespace("units", quietly = TRUE)) {
    area <- units::set_units(c(1, 2, 3), "m^2")
    expect_no_warning(result <- summ(tibble::tibble(area = area)))
    expect_equal(result$mean, 2)
    expect_equal(result$sd, 1)
  }
  survey <- haven::labelled(c(1, 2, NA), labels = c(Yes = 1, No = 2))
  attr(survey, "label") <- "Survey response"
  expect_no_warning(book <- codebook(tibble::tibble(survey = survey)))
  expect_identical(book$label, "Survey response")
  expect_equal(book$n, 2)
  filled <- value_if_na(survey, 1)
  expect_s3_class(filled, "haven_labelled")
  expect_equal(as.numeric(filled), c(1, 2, 1))
  expect_identical(attr(filled, "labels"), attr(survey, "labels"))
  categories <- haven::as_factor(survey)
  expect_identical(
    as.character(value_if_na(categories, "Yes")),
    c("Yes", "No", "Yes")
  )
  spss <- haven::labelled_spss(
    c(1, 99, NA),
    labels = c(Yes = 1),
    na_values = 99
  )
  expect_identical(is.na(spss), c(FALSE, TRUE, TRUE))
  expect_identical(is.na(haven::zap_missing(spss)), c(FALSE, TRUE, TRUE))
})

test_that("PROBLEMS2 missing value replacement arguments explain valid calls", {
  expect_error(value_if_na(4), ".value.*value_if_na", fixed = FALSE)
  expect_error(value_if_na(), ".x.*value_if_na", fixed = FALSE)
  expect_error(value_if_na(.value = 4), ".x.*value_if_na", fixed = FALSE)
  expect_identical(value_if_na(c(1L, NA_integer_), 2L), c(1L, 2L))
  expect_error(value_if_na(c(1L, NA_integer_), "bad"))
})

test_that("PROBLEMS2 value replacement follows SPSS user-missing values", {
  spss <- haven::labelled_spss(
    c(1, 2, NA, 99),
    labels = c(Yes = 1, Refused = 99),
    na_values = 99
  )
  filled <- value_if_na(spss, 2)
  expect_identical(as.numeric(unclass(filled)), c(1, 2, 2, 2))
  expect_s3_class(filled, "haven_labelled_spss")
  expect_identical(attr(filled, "labels"), attr(spss, "labels"))
  ranged <- haven::labelled_spss(c(5, -9, NA), na_range = c(-9, -1))
  expect_identical(as.numeric(unclass(value_if_na(ranged, 0))), c(5, 0, 0))
  expect_error(value_if_na(spss, "text"))
})

test_that("missing replacement arguments have actionable diagnostics", {
  expect_error(na_if_value(4), "Missing `.value`.*na_if_value", fixed = FALSE)
  expect_error(
    na_if_value(.value = 4),
    "Missing `.x`.*na_if_value",
    fixed = FALSE
  )
  expect_identical(na_if_value(c(1, 4, NA), 4), c(1, NA_real_, NA_real_))
})

test_that("mvdecode() treats several codes as a set and mvencode() fills", {
  expect_identical(mvdecode(c(1, -98, -99, NA), c(-98, -99)), c(1, NA, NA, NA))
  expect_identical(mvdecode(c(a = 1L, b = 2L), 2L), c(a = 1L, b = NA))
  expect_identical(mvdecode(1:3, integer()), 1:3)
  expect_error(mvdecode(1:3, 1.5), class = "vctrs_error_cast_lossy")
  expect_error(mvdecode(1), "Missing `mv`. Use mvdecode(x, mv)", fixed = TRUE)
  expect_error(mvencode(), "Missing `x`. Use mvencode(x, mv)", fixed = TRUE)
  labelled <- haven::labelled(c(1, -99, 2), c(Yes = 1, No = 2))
  decoded <- mvdecode(labelled, -99)
  expect_s3_class(decoded, "haven_labelled")
  expect_identical(as.numeric(unclass(decoded)), c(1, NA, 2))
  spss <- haven::labelled_spss(c(1, 9, NA), c(Yes = 1), na_values = 9)
  filled <- mvencode(spss, 0)
  expect_identical(as.numeric(unclass(filled)), c(1, 0, 0))
  expect_identical(
    dplyr::mutate(
      tibble::tibble(x = c(1, -99), y = c(-99, 2)),
      dplyr::across(c(x, y), \(v) mvdecode(v, -99))
    ),
    tibble::tibble(x = c(1, NA), y = c(NA, 2))
  )
})
