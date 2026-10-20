cat("## Example 1: Valid interval counts retain their results\n\n```r\n")
cat("cut_length(1:8, n = 2)\n```\n\n```\n")
print(cut_length(1:8, n = 2))
cat("```\n\n## Example 2: Invalid counts explain the contract\n\n```\n")
for (n in list(0, -1, 1.5, NA_real_, Inf, c(2, 3))) {
  diagnostic <- tryCatch(cut_length(1:8, n), error = conditionMessage)
  stopifnot(
    is.character(diagnostic),
    grepl("whole number larger than or equal to 1", diagnostic)
  )
  cat("n =", paste(n, collapse = ","), ":", diagnostic, "\n")
}
cat("```\n\n## Example 3: Pattern diagnostics\n\n```\n")
diagnostic <- tryCatch(
  varlist(12, vars = c("x1", "x2")),
  error = conditionMessage
)
stopifnot(grepl("character vector", diagnostic))
cat(diagnostic, "\n")
print(varlist("x*", vars = c("x1", "x2", "y")))
cat("```\n\n## Example 4: Container and row-name contracts\n\n```\n")
base <- data.frame(x = 1:8)
print(class(tab(base, x)))
print(class(tab(tibble::as_tibble(base), x)))
print(rownames(slice_headtail(base, n = 4)))
rownames(base) <- letters[1:8]
print(rownames(slice_headtail(base, n = 4)))
cat("```\n")

cat(
  "\n## Example 5: Combined numeric-range patterns select every match\n\n```\n"
)
available <- c("x1", "x2", "y", "prefix_x1", "x2_suffix")
print(available[varlist("x[1-2] y", vars = available)])
print(available[varlist("y x[1-2]", vars = available)])
stopifnot(identical(varlist("x[1-2] y", vars = available), 1:3))
cat("```\n\n## Example 6: Scalar breaks specify one interior cutpoint\n\n```\n")
cutpoint <- cut_breaks(1:8, breaks = 4, labels = FALSE)
print(cutpoint)
stopifnot(identical(cutpoint, c(1L, 1L, 1L, 1L, 2L, 2L, 2L, 2L)))
cat("```\n")
