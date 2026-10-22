cat("## Example 1: Calendar spreads as comparable difftime columns\n\n```\n")
spread <- summ(as.Date("2024-01-01") + c(0, 1), .stat = c("sd", "se"))
print(spread)
stopifnot(inherits(spread$sd, "difftime"), identical(units(spread$sd), "days"))

cat("```\n\n## Example 2: Shared numeric/calendar table columns\n\n```\n")
mixed <- tibble::tibble(x = c(1, 3), day = as.Date("2024-01-01") + 0:1)
combined <- summ(mixed, .type = "table", .stat = c("n", "mean"))
print(combined)
stopifnot(is.character(combined$mean), is.integer(combined$n))
print(summ(mixed, .type = "list", .stat = "mean"))

cat(
  "```\n\n## Example 3: Piped vector expression name and explicit-name workaround\n\n```\n"
)
print(1:3 |> summ(.name = TRUE, .stat = "mean"))
print(tibble::tibble(value = 1:3) |> summ(.name = TRUE, .stat = "mean"))

cat("```\n\n## Example 4: Infinite Date extrema\n\n```\n")
day <- as.Date(c(-Inf, 0, Inf, NA), origin = "1970-01-01")
calendar <- summ(day, .stat = c("n", "miss_n", "min", "max"))
print(calendar)
stopifnot(identical(calendar$min, "-Inf"), identical(calendar$max, "Inf"))

cat("```\n\n## Example 5: Vector tabulation\n\n```\n")
print(tab(c(1, 1, 2)))
print(fre(c(1, 1, 2)))
stopifnot(identical(fre(c(1, 1, 2)), fre(tibble::tibble(value = c(1, 1, 2)))))

cat("```\n\n## Example 6: Namespace-qualified datasets\n\n```\n")
print(c(tidystata = nrow(tidystata::starwars), dplyr = nrow(dplyr::starwars)))
print(find("starwars"))

cat("```\n\n## Example 7: Missing argument diagnostic\n\n```\n")
diagnostic <- tryCatch(na_if_value(4), error = conditionMessage)
print(diagnostic)
stopifnot(grepl("Missing `value`", diagnostic, fixed = TRUE))

cat("```\n\n## Example 8: Grouped quantile cuts return integer codes\n\n```\n")
grouped <- tibble::tibble(g = rep(c("a", "b"), each = 4), x = c(1:4, 11:14))
print(lapply(split(grouped$x, grouped$g), xtile, n = 2))
binned <- grouped |>
  dplyr::group_by(g) |>
  dplyr::mutate(bin = xtile(x, n = 2))
print(binned)
stopifnot(identical(binned$bin, rep(c(1L, 1L, 2L, 2L), 2)))

cat(
  "```\n\n## Example 9: Nested timers measure their complete expressions\n\n```\n"
)
result <- timer(timer(sum(1:3)))
stopifnot(identical(result, 6L))
cat(
  "No duration threshold is asserted. Each timer measures its own expression.\n"
)

cat("```\n")
