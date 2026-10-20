# Demo: findit() looks up the R equivalent of Stata commands.
# Runs against the fresh installation selected by the demo workflow.
library(statart)

cat("## Example 1: a bare Stata word, with Stata's abbreviations\n\n```\n")
regress <- findit(reg)
print(regress)
stopifnot(
  identical(findit(regress), regress),
  identical(findit(su)$r, findit(summarize)$r)
)

cat("```\n\n## Example 2: extra words put the closest idiom first\n\n```\n")
merged <- findit("merge 1:1 id, keep(match)")
print(merged, n = 3)
stopifnot(identical(merged$r[1], "inner_join(data1, data2, by = \"id\")"))
print(findit("bysort g: egen m = mean(x)"), n = 2)

cat("```\n\n## Example 3: packages beyond statart\n\n```\n")
print(findit(binscatter))
print(findit(winsor))
print(findit(svy))
print(findit(stcox))

cat("```\n\n## Example 4: R functions and words with both meanings\n\n```\n")
joined <- findit(left_join)
print(joined)
stopifnot(identical(joined$match, "r"), identical(findit(lm()), findit(lm)))
print(findit(log))

cat("```\n\n## Example 5: no match suggests similar commands\n\n```\n")
none <- withCallingHandlers(
  findit(regresss),
  message = function(m) {
    cat(conditionMessage(m), "\n", sep = "")
    invokeRestart("muffleMessage")
  }
)
stopifnot(nrow(none) == 0L)

cat("```\n\n## Example 6: the whole list\n\n```\n")
all_entries <- findit()
print(table(all_entries$package)[c("statart", "dplyr", "tidyr", "fixest")])
cat("Entries:", nrow(all_entries), "\n```\n")
