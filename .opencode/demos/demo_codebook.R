# Demo: codebook() function
# Shows actual output of codebook() for variable documentation

library(dplyr)

library(statart)

cat("## Example 1: Basic codebook\n\n")
cat("```r\n")
cat("codebook(mtcars)\n")
cat("```\n\n")
cat("**Output:**\n\n")
cat("```\n")
print(codebook(mtcars))
cat("```\n\n")

cat("## Example 2: With starwars data\n\n")
cat("```r\n")
cat("codebook(starwars)\n")
cat("```\n\n")
cat("**Output:**\n\n")
cat("```\n")
print(codebook(starwars))
cat("```\n\n")

cat("## Example 3: Select specific columns\n\n")
cat("```r\n")
cat("codebook(mtcars, mpg, hp, wt)\n")
cat("```\n\n")
cat("**Output:**\n\n")
cat("```\n")
print(codebook(mtcars, mpg, hp, wt))
cat("```\n\n")

cat("## Example 4: With tidyselect\n\n")
cat("```r\n")
cat("codebook(starwars, ends_with('color'))\n")
cat("```\n\n")
cat("**Output:**\n\n")
cat("```\n")
print(codebook(starwars, ends_with("color")))
cat("```\n\n")

cat("## Example 5: Numeric variables only\n\n")
cat("```r\n")
cat("codebook(starwars, where(is.numeric))\n")
cat("```\n\n")
cat("**Output:**\n\n")
cat("```\n")
print(codebook(starwars, where(is.numeric)))
cat("```\n\n")

cat("## Example 6: With expressions\n\n")
cat("```r\n")
cat("codebook(starwars, height > 0)\n")
cat("```\n\n")
cat("**Output:**\n\n")
cat("```\n")
print(codebook(starwars, height > 0))
cat("```\n\n")


cat("## Example 7: Structured and custom type descriptions\n\n")
cat("```r\n")
cat("metadata_examples <- tibble::tibble(\n")
cat("  wrapped = I(c(1L, 2L, NA_integer_)),\n")
cat("  pieces = vctrs::list_of(1:2, 1:2, integer()),\n")
cat("  custom = structure(c(1, 2, NA), class = 'interval')\n")
cat(")\ncodebook(metadata_examples)\n")
cat("```\n\n**Output:**\n\n```\n")
metadata_examples <- tibble::tibble(
  wrapped = I(c(1L, 2L, NA_integer_)),
  pieces = vctrs::list_of(1:2, 1:2, integer()),
  custom = structure(c(1, 2, NA), class = "interval")
)
print(codebook(metadata_examples))
cat("```\n\n")
