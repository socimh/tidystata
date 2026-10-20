# Demo: pairwise correlations and chi-square tests, like Stata's pwcorr and
# tab x y, chi2 V. Runs against the fresh installation selected by the demo
# workflow.
library(statart)

cat("## Example 1: pairwise correlations with n and p\n\n```\n")
pairs <- pwcorr(lifeexp, lexp, gnppc, safewater)
print(pairs)
reference <- cor.test(lifeexp$lexp, lifeexp$gnppc)
stopifnot(
  all.equal(pairs$r[1], unname(reference$estimate)),
  all.equal(pairs$p[1], reference$p.value)
)

cat("```\n\n## Example 2: the matrix as Stata prints it\n\n```\n")
print(pwcorr(lifeexp, lexp, gnppc, safewater, .wide = TRUE))

cat("```\n\n## Example 3: by group and with Spearman correlations\n\n```\n")
print(pwcorr(lifeexp, lexp, gnppc, .by = region))
print(pwcorr(lifeexp, lexp, gnppc, .method = "spearman"))

cat("```\n\n## Example 4: chi-square test with Cramer's V\n\n```\n")
crossed <- withCallingHandlers(
  xtab(starwars, sex, gender, .chi2 = TRUE),
  message = function(m) {
    cat(conditionMessage(m), "\n", sep = "")
    invokeRestart("muffleMessage")
  }
)
print(crossed)
print(attr(crossed, "chi2"))
cat("```\n")
