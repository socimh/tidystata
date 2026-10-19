test_that("historical tab1 selections and expressions stay supported", {
  d <- tibble::tibble(temp = c(26, 39, NA), text = c("a", "b", NA))
  expect_equal(tab1(d), tab1(d, tidyselect::everything()))
  result <- tab1(d, t1 = temp == 26, t2 = temp == 39)
  expect_named(result, c("t1", "t2"))
  expect_equal(result$t1$n, c(1L, 1L, 1L))
  expect_equal(result$t2$n, c(1L, 1L, 1L))
  expect_error(s_select(d, wrong_column), "wrong_column")
})

test_that("summary historical missingness and type cases stay supported", {
  d <- tibble::tibble(type = c("a", "a", NA), x = c(1, NA, 3))
  expect_message(out <- summ(d, x, .by = type), "type")
  expect_equal(out$n, c(1, 1))
  expect_message(clean <- summ(d, x, .by = type, .na.rm = TRUE), "type")
  expect_equal(clean$n, 1)
  result <- summ(c(-Inf, 1, 2, Inf))
  expect_equal(result$n, 4)
  expect_identical(result$min, -Inf)
  expect_identical(result$max, Inf)
  expect_true(is.nan(result$mean))
  expect_equal(summ(c(1, NA, 2), .stat = "sum")$sum, 3)
  expect_false("name" %in% names(summ(1:3, .name = FALSE)))
  dates <- as.POSIXct(c("2024-01-01", "2024-01-02"), tz = "UTC")
  calendar <- summ(dates)
  expect_match(calendar$mean, "2024-01-01 12:00")
  expect_identical(units(calendar$sd), "hours")
  grouped <- dplyr::group_by(tibble::tibble(g = c("b", "a"), x = 1:2), g)
  expect_message(summ(grouped, x), NA)
})

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

test_that("historical previews and repeated timers preserve complete values", {
  d <- tibble::tibble(id = 1:25, x = letters[1:25])
  expect_output(returned <- print_interval(d, n = Inf, width = Inf), "25")
  expect_identical(returned, d)
  preview <- preview_table(d, "interval", n = 5)
  changed <- dplyr::mutate(preview, id = id + 1L)
  expect_s3_class(changed, "statart_preview")
  expect_identical(unpreview_table(changed)$id, 2:26)
  expect_identical(
    statart:::duration_to_chr(as.difftime(61, units = "secs")),
    "1m1s"
  )
  calls <- 0L
  messages <- character()
  result <- withCallingHandlers(
    {
      value <- timer({
        calls <- calls + 1L
        1:5
      })
      timer(sum(value))
    },
    message = function(condition) {
      messages <<- c(messages, conditionMessage(condition))
      invokeRestart("muffleMessage")
    }
  )
  expect_identical(calls, 1L)
  expect_equal(result, 15)
  expect_length(messages, 2L)
})

test_that("missing categories and row missing counts retain their positions", {
  d <- tibble::tibble(g = c("a", "a", "b", "b"), x = c(1, NA, 2, NA))
  out <- tab(d, x, .by = g)
  expect_identical(out$g, c("a", "a", "b", "b"))
  expect_identical(is.na(out$x), c(FALSE, TRUE, FALSE, TRUE))
  expect_equal(out$cum, c(50, 100, 50, 100))
  counts <- dplyr::mutate(d, observed = row_non_miss(x))
  expect_identical(counts$observed, c(1L, 0L, 1L, 0L))
  expect_equal(row_max(d["x"]), d$x)
})

test_that("named constants are computed and grouping keys are never measured", {
  tb <- tibble::tibble(
    girl = c(0, 1, 0, 1),
    ca3_2 = c("a", "a", "b", "b"),
    score = c(10, 20, 30, 40)
  )
  out <- summ(tb, one = 1, .by = c(girl, ca3_2))
  expect_identical(out$mean, rep(1, 4))
  expect_identical(out$n, rep(1L, 4))
  expect_identical(nrow(tab(tb, constant = "x")), 1L)
  expect_identical(tab(tb, constant = "x")$n, 4L)
  expect_identical(names(s_select(tb, one = 1)), "one")
  expect_identical(s_select(tb, one = 1)$one, rep(1, 4))
  expect_error(summ(tb, other = girl, .by = girl), "Grouping column `girl`")
  expect_error(tab(tb, other = girl, .by = girl), "Grouping column `girl`")
  kept <- summ(tb, tidyselect::where(is.numeric), .by = girl, .name = TRUE)
  expect_identical(kept$name, c("score", "score"))
})

test_that("misspelled selections are reported instead of evaluated", {
  d <- tibble::tibble(height = c(1, 2, 2), mass = 3:5)
  mas <- 99
  expect_error(summ(d, mas), "`mas`")
  expect_error(tab(d, "heigth"), "`heigth`")
  expect_error(summ(d, 4), "position 4")
  expect_error(s_select(d, a1, a2, a3), "`a1`, `a2`, `a3`")
  expect_identical(names(tab(d, height > 1))[1], "height > 1")
  expect_identical(s_select(d, ratio = mass / height)$ratio, d$mass / d$height)
  expect_identical(
    tab(d, half = mass / height)$half,
    sort(unique(d$mass / d$height))
  )
  mixed <- s_select(d, tidyselect::starts_with("h"), heavy = mass > 3)
  expect_named(mixed, c("height", "heavy"))
})
