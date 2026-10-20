# Actual outputs for repaired historical problems and supported alternatives.
cat("## Example 1: Blank cross-tab categories remain distinct\n\n```\n")
d <- tibble::tibble(x = c("a", "a", "b"), y = c("", "<empty>", "z"))
print(xtab(d, x, y))
stopifnot(sum(as.matrix(xtab(d, x, y)[-1])) == 3)
cat("```\n\n## Example 2: Different ordered factors combine\n\n```\n")
factors <- tibble::tibble(
  a = ordered(c("a", "b")),
  b = ordered(c("x", "y"))
)
print(tab1(factors, .type = "tibble"))
cat("```\n\n## Example 3: Row missingness and explicit constants\n\n```\n")
rows <- tibble::tibble(a = c(1, NA, 12), b = c(NA, 2, 4))
print(dplyr::mutate(
  rows,
  observed_sum = row_sum(a, b, na.rm = TRUE),
  complete_sum = row_sum(a, b, na.rm = FALSE),
  capped = row_min(a, .values = 5)
))
stopifnot(identical(row_sum(rows, na.rm = TRUE), c(1, 2, 16)))
cat("```\n\n## Example 4: Summary controls and arbitrary percentiles\n\n```\n")
survey <- tibble::tibble(
  g = factor(c("high", "low", "low", NA), levels = c("low", "high")),
  x = c(10, 1, 3, NA)
)
print(summ(survey, x, .by = g, .sort = TRUE, .drop_empty = TRUE))
print(tabstat(survey, x, .stat = c("mean", "p2.5", "p97.5")))
print(tab(survey, x, .by = g, .group_order = "frequency", .desc = TRUE))
cat("```\n\n## Example 5: Balanced bins explicitly permit split ties\n\n```\n")
tied <- c(rep(0, 9), 1)
rank_bins <- xtile(tied, n = 5, labels = FALSE, method = "rank")
print(data.frame(value = tied, bin = rank_bins))
print(table(rank_bins))
stopifnot(identical(as.integer(table(rank_bins)), rep(2L, 5)))
cat("```\n\n## Example 6: Vectors and reusable name inventories\n\n```\n")
print(tab(c(1, 1, 2)))
print(ds(ds(rows), dplyr::starts_with("a")))
cat("```\n\n## Example 7: Failed expressions retain the true error\n\n```\n")
diagnostic <- tryCatch(
  timer(stop("original fitting error"), .on_error = TRUE),
  error = conditionMessage
)
print(diagnostic)
stopifnot(identical(diagnostic, "original fitting error"))
cat(
  "```\n\n## Example 8: Labelled replacements have explicit representations\n\n```\n"
)
response <- haven::labelled(c(1, 2, NA), labels = c(Yes = 1, No = 2))
print(value_if_na(response, 1))
print(value_if_na(haven::as_factor(response), "Yes"))
cat("```\n\n## Example 9: Spatial aggregation ignores geometries\n\n```\n")
if (requireNamespace("sf", quietly = TRUE)) {
  points <- sf::st_as_sf(
    data.frame(x = c(1, 1, 2), lon = 1:3, lat = 4:6),
    coords = c("lon", "lat")
  )
  print(tab(points, x))
  print(summ(points, x))
  stopifnot(identical(tab(points, x)$n, c(2L, 1L)))
} else {
  cat("Optional sf is unavailable; spatial scenario not executed.\n")
}
cat(
  "```\n\n## Example 10: Logical axes have consistent category order\n\n```\n"
)
flags <- tibble::tibble(a = c(FALSE, TRUE, NA), b = c(TRUE, FALSE, NA))
print(xtab(flags, a, b))
stopifnot(identical(names(xtab(flags, a, b))[-1], c("FALSE", "TRUE", "NA")))
cat(
  "```\n\n## Example 11: Missing replacement arguments explain the call\n\n```\n"
)
diagnostic <- tryCatch(value_if_na(4), error = conditionMessage)
print(diagnostic)
stopifnot(grepl(".value", diagnostic, fixed = TRUE))
cat("```\n\n## Example 12: Constants cap values like pmin()\n\n```\n")
shares <- tibble::tibble(id = 1:3, pct = c(0.2, 0.7, NA))
capped <- dplyr::mutate(shares, capped = row_min(pct, 0.5))
print(capped)
stopifnot(identical(capped$capped, pmin(shares$pct, 0.5)))
cat(
  "```\n\n## Example 13: Summaries sort groups and compute named constants\n\n```\n"
)
education <- tibble::tibble(
  edu = factor(
    c("high", "low", NA, "middle"),
    levels = c("low", "middle", "high")
  ),
  girl = c(0, 1, 0, 1),
  score = c(5, 7, 6, 8)
)
by_education <- summ(education, score, .by = edu)
print(by_education)
print(summ(education, one = 1, .by = girl))
stopifnot(identical(
  as.character(by_education$edu),
  c("low", "middle", "high", NA)
))
cat("```\n\n## Example 14: Quantile cuts keep a dummy in two groups\n\n```\n")
dummy <- rep(0:1, c(7, 3))
print(table(xtile(dummy, 2)))
stopifnot(identical(nlevels(xtile(dummy, 2)), 2L))
cat("```\n")
