test_that("specific lookups return the relevant operation rather than its family", {
  mean <- findit("egen rowmean")
  expect_identical(nrow(mean), 1L)
  expect_identical(mean$package, "tidystata")
  expect_true(all(grepl("row_mean(", mean$r, fixed = TRUE)))
  expect_identical(findit(egen, rowmean)$r, mean$r)
  family <- findit(egen)
  expect_identical(
    attr(mean, "broader")$count,
    sum(!grepl("rowmean", family$stata, fixed = TRUE))
  )
  one <- findit("egen rowmean", score, "value")
  expect_true(any(grepl("row_mean(value)", one$r, fixed = TRUE)))
  expect_identical(nrow(findit("merge 1:1 id, keep(match)")), 1L)
  expect_true(all(grepl("rowmean", findit("egen rowmean")$stata)))
})

test_that("family browsing keeps all mappings and shows five operations", {
  family <- findit(egen)
  catalogue <- findit_entries()
  expect_setequal(
    attr(family, "entry_ids"),
    catalogue$id[catalogue$command == "egen"]
  )
  out <- capture.output(print(family))
  for (query in c(" egen", "egen ", "\tegen\n")) {
    expect_identical(findit(!!query)$stata, family$stata)
  }
  expect_identical(sum(startsWith(out, "Stata: ")), 5L)
  expect_identical(
    sum(startsWith(capture.output(print(family, n = Inf)), "Stata: ")),
    nrow(family)
  )
})

test_that("specific candidates are bounded after hints and customization", {
  found <- findit(egen, score, a, b, rowmean)
  expect_identical(nrow(found), 1L)
  expect_true(grepl("row_mean(a, b)", found$r, fixed = TRUE))
  expect_true(grepl("score", found$r, fixed = TRUE))
  for (query in c("mutate", "dummy", "how do I remove duplicate rows")) {
    found <- findit(!!query)
    expect_lte(nrow(found), 10L)
    expect_lte(
      sum(startsWith(capture.output(print(found)), "Stata: ")),
      5L
    )
  }
  expect_match(findit("reg y x, robust")$r[1], "coeftest", fixed = TRUE)
  explicit <- findit("base::merge")
  expect_true(all(vapply(
    findit_calls(explicit$r),
    function(x) "merge" %in% x,
    logical(1)
  )))
})

test_that("footers distinguish relevant candidates from broader family operations", {
  withr::local_envvar(LANGUAGE = "en")
  out <- capture.output(print(findit("egen rowmean")))
  expect_false(any(grepl("more examples", out, fixed = TRUE)))
  expect_true(any(grepl("broader egen examples", out, fixed = TRUE)))
  expect_true(any(grepl("findit(egen)", out, fixed = TRUE)))
  family <- findit(egen)
  out <- capture.output(print(family, n = nrow(family) - 1L))
  expect_true(any(grepl("1 more relevant example.", out, fixed = TRUE)))
  expect_false(any(grepl(
    "more relevant",
    capture.output(print(family, n = Inf)),
    fixed = TRUE
  )))
  candidates <- findit(mutate)
  expect_identical(nrow(candidates), 10L)
  expect_true(any(grepl(
    "Only the 10 best candidates",
    capture.output(print(candidates)),
    fixed = TRUE
  )))
  nearest <- findit("how do I remove duplicate rows")
  expect_identical(nrow(nearest), 10L)
  expect_true(any(grepl(
    "Only the 10 best candidates",
    capture.output(print(nearest)),
    fixed = TRUE
  )))
})

test_that("package preference breaks ties within a relevant operation", {
  found <- findit_entries()[rep(1L, 4L), ]
  found$id <- letters[1:4]
  found$stata <- c(
    "egen z = rowmean(x y)",
    "egen z = rowmean(x y)",
    "egen z = rowmean(x y)",
    "egen z = rowtotal(x y)"
  )
  found$package <- c("base", "dplyr", "tidystata", "tidystata")
  ranked <- findit_rank(found, "rowmean", "stata")
  expect_identical(ranked$id, c("c", "b", "a", "d"))
})

test_that("an option hint retains different option arguments", {
  found <- findit(merge, keep)
  expect_gt(nrow(found), 1L)
  expect_lte(nrow(found), 10L)
  expect_true(any(grepl("keep(master match)", found$stata, fixed = TRUE)))
  expect_true(any(grepl("keep(using match)", found$stata, fixed = TRUE)))
  expect_gt(nrow(findit("merge keep")), 1L)
  expect_identical(nrow(findit(egen, rowmean)), 1L)
  expect_identical(nrow(findit(egen, rowtotal, missing)), 1L)
})

test_that("package preference preserves grouping context and direct helper meanings", {
  found <- findit("egen z = total(x)")
  expect_false(startsWith(found$stata[1L], "bysort"))
  for (query in c("row_mean", "tidystata::row_mean")) {
    out <- capture.output(print(findit(!!query)))
    expect_true(grepl("rowmean(", out[2L], fixed = TRUE))
  }
})

test_that("lookup separates z-scores, total shares and percentile ranks", {
  withr::local_envvar(LANGUAGE = "en")
  std <- capture.output(print(findit(std)))
  expect_true(any(grepl("(x - mean(x", std, fixed = TRUE)))
  pc <- capture.output(print(findit(pc)))
  expect_true(any(grepl("100 * x / sum(x", pc, fixed = TRUE)))
  ranks <- findit(dplyr::percent_rank)
  expect_true(any(grepl("percent_rank(", ranks$r, fixed = TRUE)))
  expect_false(any(grepl("pc(", ranks$r, fixed = TRUE)))
  for (query in c("percentile rank", "percent rank")) {
    found <- findit(!!query)
    expect_true(
      any(grepl(
        "percent_rank(",
        utils::head(found$r, 3L),
        fixed = TRUE
      )),
      info = query
    )
  }
  retired <- capture.output(print(findit(pct)))
  expect_true(any(grepl("[Rr]emoved", retired)))
  expect_true(any(grepl("pc()", retired, fixed = TRUE)))
  expect_true(any(grepl("percent_rank()", retired, fixed = TRUE)))
})

test_that("specific syntax prefers tidystata, then tidyverse, over base R", {
  first <- function(query) suppressMessages(findit(!!query))[1L, ]
  for (query in c(
    "tabstat x, statistics(sd)",
    "isid id",
    "misstable patterns x y",
    "ds, has(type numeric)",
    "tabulate g, missing",
    "missings tag x y, generate(nmiss)"
  )) {
    expect_identical(first(query)$package, "tidystata", info = query)
  }
  for (query in c("sort x", "keep id x", "rename (x y) (income hours)")) {
    expect_identical(first(query)$package, "dplyr", info = query)
  }
  expect_match(first("drop if x == 1")$r, "filter_out(", fixed = TRUE)
  expect_match(first("drop if g == 2")$r, "filter_out(", fixed = TRUE)
  expect_match(
    first("replace x = y if missing(x)")$r,
    "coalesce(",
    fixed = TRUE
  )
  # The base alternative remains available beside the preferred recipe.
  expect_true("base" %in% findit(sort)$package)
  expect_identical(
    findit_package_priority(c("tidystata", "readxl", "broom", "stats")),
    c(0L, 1L, 1L, 2L)
  )
})

test_that("negated conditions are not traded for package preference", {
  kept <- findit("keep if missing(x)")
  expect_false(any(grepl("!is.na(x)", kept$r, fixed = TRUE)))
  expect_match(kept$r[1], "is.na(x)", fixed = TRUE)
  expect_match(findit("keep if !missing(x)")$r[1], "!is.na(x)", fixed = TRUE)
  expect_identical(
    findit_rank_tokens("keep if !missing(x) & x != 1")[[1L]],
    c("keep", "if", "!", "missing", "x", "x", "!=", "1")
  )
})
