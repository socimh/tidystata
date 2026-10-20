entries <- findit()

test_that("findit() returns every entry when called without a command", {
  expect_s3_class(entries, "statart_findit")
  expect_s3_class(entries, "tbl_df")
  expect_named(entries, c("match", "stata", "r", "package", "task"))
  expect_true(all(entries$match == "all"))
  expect_gt(nrow(entries), 150)
  expect_identical(findit(NULL), entries)
})

test_that("findit() follows Stata's minimum abbreviations", {
  regress <- findit(reg)
  expect_true(all(startsWith(regress$stata, "regress")))
  expect_identical(findit(regr), regress)
  expect_identical(findit(regress), regress)
  expect_identical(findit(su)$r, findit(summarize)$r)
  expect_true("tab(data, x)" %in% findit(ta)$r)
  expect_true("browse(data)" %in% findit(br)$r)
  # Shorter than the minimum abbreviation, or not a prefix: no command match.
  data <- findit_entries()
  expect_false(any(findit_command_hit("re", data)))
  expect_false(any(findit_command_hit("tabs", data)))
  expect_false(any(findit_command_hit("tabulatex", data)))
  expect_identical(
    unique(data$command[findit_command_hit("tab1", data)]),
    "tab1"
  )
  # Unknown abbreviations still reach the entry through the text search.
  expect_true("tabstat" %in% sub(" .*", "", findit("tabs")$stata))
})

test_that("bare words and strings give the same result without evaluation", {
  tab <- "not a command"
  expect_identical(findit(tab), findit("tab"))
  cmd <- "merge"
  expect_identical(findit(!!cmd), findit("merge"))
  expect_identical(findit(L.x)$r[1], findit("L.x")$r[1])
  expect_match(findit(L.x)$r[1], "s_lag(x, time = year)", fixed = TRUE)
})

test_that("findit() rejects inputs that are not one word or one string", {
  message <- "must be one Stata word, an R function name or a quoted string"
  expect_error(findit(NA), message)
  expect_error(findit(1), message)
  expect_error(findit(""), message)
  expect_error(findit(f(x)), message)
  vector <- c("reg", "tab")
  expect_error(findit(!!vector), message)
})

test_that("extra words and by prefixes put the closest entries first", {
  merged <- findit("merge keep(match)")
  expect_identical(merged$r[1], "inner_join(data1, data2, by = \"id\")")
  expect_identical(nrow(merged), nrow(findit(merge)))
  expect_identical(findit("reg y x, robust")$r[1], findit(reg)$r[2])
  expect_identical(findit("bys g: sum x")$r[1], "summ(data, x, .by = group)")
  expect_identical(findit("svy: regress y x")$r[1], findit(svy)$r[3])
  expect_identical(
    findit("bysort id: egen m = mean(x)")$r[1],
    "mutate(data, x_avg = mean(x, na.rm = TRUE), .by = group)"
  )
})

test_that("findit() covers Stata functions and wider analysis commands", {
  expect_match(findit(collapse)$r[1], "summarise(", fixed = TRUE)
  expect_identical(findit(inlist)$r, "mutate(data, y = x %in% c(1, 3, 5))")
  expect_match(
    findit("svy, subpop(rural): mean x")$r[1],
    "filter(rural == 1)",
    fixed = TRUE
  )
  expect_match(findit(stcox)$r, "survival::coxph(", fixed = TRUE)
  expect_match(findit("if")$r, "if (x > 0)", fixed = TRUE)
  # Lag operators with a number are found through the text search.
  expect_match(findit("L2.x")$r, "lag(x, 2", fixed = TRUE)
  # sum() the function needs its full name; su still means summarize.
  expect_false(any(grepl("cumsum", findit(su)$r, fixed = TRUE)))
  expect_true(any(grepl("cumsum", findit(sum)$r, fixed = TRUE)))
})

test_that("R function names find the Stata idioms they replace", {
  joined <- findit(left_join)
  expect_identical(joined$match, "r")
  expect_match(joined$stata, "keep(master match)", fixed = TRUE)
  expect_identical(attr(joined, "r_functions")$package, "dplyr")
  # Written as code, or with its package, it is the same lookup.
  expect_identical(findit(left_join()), joined)
  expect_identical(findit(dplyr::left_join), joined)
  expect_identical(findit("dplyr::left_join()"), joined)
  # Whole names only: lm finds lm(), not glm() or lmer().
  calls <- findit_calls(findit(lm)$r)
  expect_true(all(vapply(calls, function(x) "lm" %in% x, logical(1))))
  # Exact case first, then ignoring case.
  expect_identical(findit(surv)$r, findit(Surv)$r)
  expect_true(all(grepl("Surv(", findit(Surv)$r, fixed = TRUE)))
  # Extra words narrow a widely used function.
  expect_match(findit("mutate egen")$stata[1], "^egen|egen ")
})

test_that("words that are both Stata commands and R functions show both", {
  logs <- findit(log)
  expect_identical(logs$match, c("stata", "r"))
  expect_identical(
    logs$r,
    c("sink(\"results.log\")", "mutate(data, y = log(x))")
  )
  out <- capture.output(print(logs))
  expect_true("# \"log\" is a Stata command and an R function." %in% out)
  expect_true("## Stata command" %in% out)
  expect_true(any(startsWith(out, "## R function: log() [base]: ")))
  # An entry is listed once, under the Stata command, even when it also uses
  # the R function of the same name.
  sums <- findit(summ)
  expect_identical(anyDuplicated(sums$stata), 0L)
  expect_true(all(c("stata", "r") %in% sums$match))
  # Plain Stata lookups print as before, without group headings.
  expect_false(any(grepl("^##", capture.output(print(findit(reshape))))))
})

test_that("R functions without entries show their description", {
  distinct <- findit(n_distinct)
  expect_identical(nrow(distinct), 0L)
  expect_identical(attr(distinct, "r_functions")$stata, "distinct")
  out <- capture.output(print(distinct))
  expect_true(any(startsWith(out, "## R function: n_distinct() [dplyr]: ")))
  expect_true("  Related Stata: distinct" %in% out)
  # A base R function with a Stata name shows both meanings.
  merged <- findit(merge)
  expect_true(all(merged$match == "stata"))
  expect_identical(attr(merged, "r_functions")$package, "base")
})

test_that("findit() falls back to a text search, then to suggestions", {
  winsor <- findit(winsor)
  expect_identical(nrow(winsor), 1L)
  expect_match(winsor$r, "datawizard::winsorize", fixed = TRUE)
  expect_true(nrow(findit(dummy)) >= 2L)
  expect_true(nrow(findit("_n")) >= 1L)

  expect_message(none <- withVisible(findit(regresss)), "Did you mean: regress")
  expect_false(none$visible)
  expect_identical(nrow(none$value), 0L)
  expect_named(none$value, names(entries))
  expect_message(
    findit(qwzx),
    "No Stata command, R function or keyword matches \"qwzx\""
  )
})

test_that("printing shows whole code lines and limits long results", {
  out <- capture.output(print(findit(merge)))
  expect_identical(out[1], "# Stata to R: 10 entries")
  expect_true(any(out == "  inner_join(data1, data2, by = \"id\")"))
  long <- capture.output(print(entries, n = 2))
  expect_match(long[length(long)], "more. Use `print(n = Inf)`", fixed = TRUE)
  expect_identical(
    capture.output(print(findit(winsor)))[1],
    "# Stata to R: 1 entry"
  )
  capture.output(shown <- withVisible(print(findit(reg))))
  expect_false(shown$visible)
})

test_that("the lookup data is complete and consistent", {
  data <- findit_entries()
  required <- c(
    "section",
    "section_zh",
    "command",
    "abbrev",
    "stata",
    "r",
    "package",
    "task"
  )
  expect_true(all(required %in% names(data)))
  for (column in setdiff(required, "section_zh")) {
    expect_true(all(nzchar(data[[column]])), info = column)
  }
  expect_true(all(startsWith(data$command, data$abbrev)))
  expect_identical(anyDuplicated(data$stata), 0L)
  one_line <- function(x) !grepl("\n", x, fixed = TRUE) & !grepl("[^ -~]", x)
  expect_true(all(one_line(data$stata)))
  expect_true(all(one_line(data$r)))
  expect_true(all(one_line(data$task)))
  parses <- vapply(
    data$r,
    function(code) {
      tryCatch(is.expression(parse(text = code)), error = function(e) FALSE)
    },
    logical(1)
  )
  expect_identical(data$r[!parses], character())
})

test_that("every R function in the entries has a description", {
  described <- findit_functions()
  used <- unique(unlist(findit_entries()$functions))
  expect_true(all(used %in% described$`function`))
  # Functions that no entry uses must point to a related Stata command.
  unused <- !described$`function` %in% used
  expect_true(all(nzchar(described$stata[unused])))
  expect_identical(anyDuplicated(described$`function`), 0L)
  for (column in setdiff(names(described), "stata")) {
    expect_true(all(nzchar(described[[column]])), info = column)
  }
  one_line <- function(x) {
    !grepl(
      "
",
      x,
      fixed = TRUE
    ) &
      !grepl("[^ -~]", x)
  }
  expect_true(all(one_line(described$description)))
  ours <- described$`function`[described$package == "statart"]
  expect_true(all(ours %in% getNamespaceExports("statart")))
})

test_that("statart entries call functions that statart exports", {
  data <- findit_entries()
  exports <- getNamespaceExports("statart")
  calls <- regmatches(
    data$r,
    gregexpr("[A-Za-z_][A-Za-z0-9._]*(?=\\()", data$r, perl = TRUE)
  )
  ours <- data$package == "statart"
  uses_export <- vapply(
    calls[ours],
    function(x) any(x %in% exports),
    logical(1)
  )
  expect_true(
    all(uses_export),
    info = paste(data$stata[ours][!uses_export], collapse = "; ")
  )
  deprecated <- c(
    "tab2",
    "fre2",
    "cut_quantile",
    "s_match",
    "s_try",
    "names_as_column"
  )
  expect_false(any(unlist(calls) %in% deprecated))
})
