# Demo: gap-aware panel lags, leads and differences, like Stata's L., F. and
# D. after xtset. Runs against the fresh installation selected by the demo
# workflow.
library(tidystata)

panel <- tibble::tibble(
  id = c(1, 1, 1, 1, 2, 2, 2),
  year = c(2002, 2001, 2005, 2004, 2003, 2001, 2002),
  x = c(12, 10, 18, 15, 33, 31, 32)
)

cat("## Example 1: lags follow time, not row order\n\n```\n")
out <- dplyr::mutate(
  panel,
  lag_x = s_lag(x, time = year),
  lead_x = s_lead(x, time = year),
  d_x = s_diff(x, time = year),
  .by = id
)
print(dplyr::arrange(out, id, year))
# 2004 has no 2003 in panel 1, so its lag is missing, as in Stata.
stopifnot(is.na(out$lag_x[out$id == 1 & out$year == 2004]))

cat("```\n\n## Example 2: dplyr::lag() shifts rows across the gap\n\n```\n")
print(dplyr::mutate(
  dplyr::arrange(panel, id, year),
  row_lag = dplyr::lag(x),
  time_lag = s_lag(x, time = year),
  .by = id
))

cat("```\n\n## Example 3: monthly dates compare whole months\n\n```\n")
sales <- tibble::tibble(
  month = as.Date(c("2024-01-31", "2024-02-29", "2024-04-30")),
  amount = c(5, 7, 4)
)
print(dplyr::mutate(
  sales,
  previous = s_lag(amount, time = month, unit = "month")
))
cat("```\n")
