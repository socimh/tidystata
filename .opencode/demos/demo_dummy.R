# Demo: std(), pc() and as_dummy(), like Stata's egen std(), egen pc() and
# tabulate, generate(). Runs against the fresh installation selected by the
# demo workflow.
library(tidystata)

cat("## Example 1: standardise and scale within groups\n\n```\n")
scaled <- dplyr::mutate(
  lifeexp,
  z = std(lexp),
  share = pc(popgrowth),
  .by = region
)
print(dplyr::select(scaled, region, country, lexp, z, popgrowth, share))
totals <- tapply(scaled$share, vctrs::vec_data(scaled$region), sum)
stopifnot(all(abs(totals - 100) < 1e-8))

cat("```\n\n## Example 2: indicator columns after their source\n\n```\n")
dummies <- as_dummy(starwars, sex)
print(dplyr::select(dummies, name, dplyr::starts_with("sex")))
print(attr(dummies$sex_male, "label"))

cat("```\n\n## Example 3: Stata-style numbered columns\n\n```\n")
print(as_dummy(lifeexp, region, .names = "index", .remove = TRUE))
cat("```\n")
