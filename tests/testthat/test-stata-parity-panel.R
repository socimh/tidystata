# stata_lag(), stata_lead() and stata_diff() against Stata's L., F. and D.
# after xtset (data-raw/stata-parity/panel.do).
panel_like_stata <- function(data, time, delta = 1, unit = NULL) {
  dplyr::mutate(
    data,
    l1 = stata_lag(x, time = {{ time }}, delta = delta, unit = unit),
    l2 = stata_lag(x, 2, time = {{ time }}, delta = delta, unit = unit),
    f1 = stata_lead(x, time = {{ time }}, delta = delta, unit = unit),
    f2 = stata_lead(x, 2, time = {{ time }}, delta = delta, unit = unit),
    d1 = stata_diff(x, time = {{ time }}, delta = delta, unit = unit),
    d2 = stata_diff(x, 2, time = {{ time }}, delta = delta, unit = unit),
    .by = id
  )
}

expect_panel_stata <- function(out, reference) {
  for (column in c("l1", "l2", "f1", "f2", "d1", "d2")) {
    expect_identical(
      as.numeric(out[[column]]),
      as.numeric(reference[[column]]),
      label = column
    )
  }
}

test_that("annual panels with gaps match L., F. and D.", {
  reference <- stata_fixture("panel-annual")
  expect_panel_stata(panel_like_stata(reference, year), reference)
})

test_that("delta matches xtset, delta(5)", {
  reference <- stata_fixture("panel-delta5")
  expect_panel_stata(panel_like_stata(reference, year, delta = 5), reference)
})

test_that("Date weeks, months and quarters match %tw, %tm and %tq", {
  units <- c(w = "week", m = "month", q = "quarter")
  for (code in names(units)) {
    # Each file holds the rows Stata kept: one per period within each panel.
    reference <- stata_fixture(paste0("panel-", code))
    reference$day <- as.Date(reference$day)
    expect_panel_stata(
      panel_like_stata(reference, day, unit = units[[code]]),
      reference
    )
  }
  # 2025-01-05 and 2025-01-07 share Stata's first week of 2025.
  days <- as.Date(c("2025-01-05", "2025-01-07"))
  expect_error(stata_lag(1:2, time = days, unit = "week"), "Repeated time")
})
