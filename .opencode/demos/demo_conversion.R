# Demo: Conversion helpers in survey preparation
# Uses the installed statart package; run against a fresh verified installation.

library(statart)

survey <- tibble::tibble(
  respondent = 1:4,
  response = haven::labelled(c(1, 2, 99, NA), c(Yes = 1, No = 2)),
  income = c("$1,200", "$900", "", "$1,450"),
  quality = c(1L, 99L, 2L, 1L)
)

cat("## Example 1: Imported survey data\n\n")
print(survey)

prepared <- survey |>
  dplyr::mutate(
    response = as_character(response),
    income = as_numeric(income),
    quality = na_if_value(quality, 99L),
    response = value_if_na(response, "Unknown")
  )

cat("\n## Example 2: Prepared research data\n\n")
print(prepared)
stopifnot(
  identical(prepared$response, c("Yes", "No", "99", "Unknown")),
  identical(prepared$income, c(1200, 900, NA_real_, 1450)),
  identical(prepared$quality, c(1L, NA_integer_, 2L, 1L))
)

cat("\n## Example 3: Factor labels and numeric codes\n\n")
response <- factor(c("Yes", "No", NA), levels = c("No", "Yes"))
print(tibble::tibble(
  response,
  text = as_character(response),
  code = as_numeric(response)
))

cat("\n## Example 4: SPSS missing codes remain explicit values\n\n")
imported <- haven::labelled_spss(
  c(1, 99, NA),
  labels = c(Yes = 1, Refused = 99),
  na_values = 99
)
print(tibble::tibble(
  text = as_character(imported),
  raw_value = as_numeric(imported)
))
stopifnot(identical(as_numeric(imported), c(1, 99, NA_real_)))
