entries <- findit()

test_that("findit() returns every entry when called without a command", {
  expect_s3_class(entries, "tidystata_findit")
  expect_s3_class(entries, "tbl_df")
  expect_named(entries, c("match", "stata", "r", "package", "task"))
  expect_true(all(entries$match == "all"))
  expect_gt(nrow(entries), 150)
  expect_identical(findit(NULL), entries)
})

test_that("findit() follows Stata's minimum abbreviations", {
  regress <- findit(reg)
  expect_true(all(startsWith(regress$stata, "regress")))
  expect_identical(findit(regr), regress, ignore_attr = "input")
  expect_identical(findit(regress), regress, ignore_attr = "input")
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
  # Only the call as typed, kept for the printed hint, differs.
  tab <- "not a command"
  expect_identical(findit(tab), findit("tab"), ignore_attr = "input")
  cmd <- "merge"
  expect_identical(findit(!!cmd), findit("merge"), ignore_attr = "input")
  expect_identical(findit(L.x)$r[1], findit("L.x")$r[1])
  expect_match(findit(L.x)$r[1], "stata_lag(x, time = year)", fixed = TRUE)
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
  expect_identical(
    findit("reg y x, robust")$r[1],
    paste0(
      "{ fit <- stats::lm(y~x+z,data=data); ",
      'lmtest::coeftest(fit, vcov.=sandwich::vcovHC(fit,type="HC1")) }'
    )
  )
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
  expect_true(all(joined$match == "r"))
  expect_match(joined$stata[1L], "keep(master match)", fixed = TRUE)
  expect_identical(attr(joined, "r_functions")$package, "dplyr")
  # Written as code, or with its package, it is the same lookup.
  expect_identical(findit(left_join()), joined, ignore_attr = "input")
  expect_identical(findit(dplyr::left_join), joined, ignore_attr = "input")
  expect_identical(findit("dplyr::left_join()"), joined, ignore_attr = "input")
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
  expect_identical(logs$match[1:2], c("stata", "r"))
  expect_identical(
    logs$r[1:2],
    c("sink(\"results.log\")", "mutate(data, y = log(x))")
  )
  out <- capture.output(print(logs))
  expect_false(any(grepl("is a Stata command|^##|^# Stata command", out)))
  expect_false(any(grepl("R function:|^# log\\(\\)", out)))
  expect_identical(sum(startsWith(out, "Stata: ")), 2L)
  # An entry is listed once, under the Stata command, even when it also uses
  # the R function of the same name.
  sums <- findit(summ)
  expect_identical(anyDuplicated(attr(sums, "entry_ids")), 0L)
  expect_true(all(c("stata", "r") %in% sums$match))
  # Plain Stata lookups print as before, without group headings.
  expect_false(any(grepl("^##", capture.output(print(findit(reshape))))))
})

test_that("R functions without entries show their description", {
  distinct <- findit(fct_relevel)
  expect_identical(nrow(distinct), 0L)
  expect_true(nzchar(attr(distinct, "r_functions")$stata))
  out <- capture.output(print(distinct))
  expect_true(any(startsWith(out, "# fct_relevel() [forcats]: ")))
  expect_true(any(startsWith(out, "  Related Stata: ")))
  # A base R function with a Stata name shows both meanings.
  merged <- findit(merge)
  expect_true(any(merged$match == "stata"))
  expect_identical(attr(merged, "r_functions")$package, "base")
})

test_that("findit() falls back to a text search, then to suggestions", {
  winsor <- findit(winsor)
  expect_gte(nrow(winsor), 1L)
  expect_true(any(grepl("datawizard::winsorize", winsor$r, fixed = TRUE)))
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
  expect_identical(out[1], "# Merge with a match report [tidystata]")
  expect_true(any(out == 'R:     stata_merge(data1, data2, "1:1", by = "id")'))
  # The hint repeats the call as typed, ready to run.
  long <- capture.output(print(entries, n = 2))
  expect_match(
    long[length(long)],
    "more examples. To see them all: findit() |> print(n = Inf)",
    fixed = TRUE
  )
  tab_out <- capture.output(print(findit(tab)))
  expect_match(
    tab_out,
    "findit(tab) |> print(n = Inf)",
    fixed = TRUE,
    all = FALSE
  )
  quoted <- capture.output(print(findit("merge 1:1 id"), n = 1))
  expect_match(
    quoted,
    "findit(\"merge 1:1 id\") |> print(n = Inf)",
    fixed = TRUE,
    all = FALSE
  )
  expect_match(capture.output(print(findit(winsor)))[1], "^# ")
  none <- suppressMessages(findit(zzqqxx))
  expect_identical(capture.output(print(none)), "# No matching entries.")
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
  expect_identical(anyDuplicated(data$id), 0L)
  one_line <- function(x) !grepl("[[:cntrl:]]", x)
  # Full workflows retain meaningful Stata line breaks; Unicode text is valid.
  expect_false(any(grepl("[\r\t]", data$stata)))
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
  # External functions without examples must point to a related Stata command.
  # Package helpers can be described without claiming a Stata equivalent.
  unused <- !described$`function` %in% used & described$package != "tidystata"
  expect_true(all(nzchar(described$stata[unused])))
  expect_identical(anyDuplicated(described[c("function", "package")]), 0L)
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
      !grepl("[[:cntrl:]]", x)
  }
  expect_true(all(one_line(described$description)))
  ours <- described$`function`[described$package == "tidystata"]
  expect_true(all(ours %in% getNamespaceExports("tidystata")))
  expect_setequal(ours, setdiff(getNamespaceExports("tidystata"), "%>%"))
})

test_that("tidystata entries call functions that tidystata exports", {
  data <- findit_entries()
  exports <- getNamespaceExports("tidystata")
  calls <- regmatches(
    data$r,
    gregexpr("[A-Za-z_][A-Za-z0-9._]*(?=\\()", data$r, perl = TRUE)
  )
  ours <- data$package == "tidystata"
  uses_export <- vapply(
    calls[ours],
    function(x) any(x %in% exports),
    logical(1)
  )
  expect_true(
    all(uses_export),
    info = paste(data$stata[ours][!uses_export], collapse = "; ")
  )
  # Entries use primary names, not aliases or deprecated names.
  aliases <- c(
    "cut_quantile",
    "na_if_value",
    "value_if_na",
    "pct",
    "tab_gen",
    "as_numeric",
    "as_character",
    "var_type",
    "var_unit"
  )
  used <- unlist(calls)
  expect_false(
    any(used %in% aliases),
    info = toString(intersect(used, aliases))
  )
})

test_that("findit() reports an invalid query", {
  expect_snapshot(error = TRUE, {
    findit(1 + 1)
  })
})

test_that("findit() shows Chinese text when R runs in Chinese", {
  data <- findit_entries()
  described <- findit_functions()
  withr::local_envvar(LANGUAGE = "zh_CN:en")
  expect_true(findit_chinese())
  merge <- findit(merge)
  expect_identical(merge$task, data$task_zh[match(merge$stata, data$stata)])
  expect_identical(
    attr(findit(left_join), "r_functions")$description,
    described$description_zh[described$`function` == "left_join"]
  )
  expect_named(merge, c("match", "stata", "r", "package", "task"))

  withr::local_envvar(LANGUAGE = "en")
  expect_false(findit_chinese())
  merge <- findit(merge)
  expect_identical(merge$task, data$task[match(merge$stata, data$stata)])
})

test_that("Chinese keywords are searched in any language", {
  withr::local_envvar(LANGUAGE = "en")
  found <- findit("\u5408\u5e76")
  expect_true(all(found$match == "keyword"))
  expect_true(any(startsWith(found$stata, "merge")))
})

test_that("plain questions find the closest entries", {
  withr::local_envvar(LANGUAGE = "en")
  zh <- function(...) intToUtf8(c(...))
  questions <- list(
    "how do I remove duplicate rows" = "duplicates drop",
    "average income by group" = "egen|collapse|summarize",
    "combine two datasets" = "merge|append",
    "count how many people in each category" = "tabulate|contract",
    "make a bar chart" = "graph bar",
    "keep only rows where age is over 30" = "keep if",
    "replace missing values with zero" = "mvencode|replace",
    "change a text column to numbers" = "destring|real",
    "run a regression with fixed effects" = "reghdfe|xtreg|areg",
    "sort the data by date" = "sort",
    "delete a column" = "drop",
    "open an excel spreadsheet" = "import excel",
    "turn wide data into long" = "reshape long",
    "summary statistics of all variables" = "summarize",
    "split data into quartiles" = "xtile|cut",
    "check if id is unique" = "isid"
  )
  questions[[zh(0x5220, 0x9664, 0x91cd, 0x590d, 0x7684, 0x89c2, 0x6d4b)]] <-
    "duplicates drop"
  questions[[zh(0x6309, 0x7ec4, 0x8ba1, 0x7b97, 0x5e73, 0x5747, 0x503c)]] <-
    "egen|mean"
  questions[[zh(0x753b, 0x4e00, 0x4e2a, 0x67f1, 0x72b6, 0x56fe)]] <- "graph bar"
  questions[[zh(0x53d8, 0x91cf, 0x6539, 0x540d)]] <- "rename"
  for (question in names(questions)) {
    found <- findit(!!question)
    expect_true(
      any(grepl(questions[[question]], utils::head(found$stata, 3))),
      info = question
    )
    expect_identical(found$match[1], "nearest", info = question)
    expect_lte(sum(found$match == "nearest"), 10L)
  }
})

test_that("plain questions leave exact lookups unchanged", {
  withr::local_envvar(LANGUAGE = "en")
  expect_false("nearest" %in% findit(reg)$match)
  expect_false("nearest" %in% findit("merge keep(match)")$match)
  expect_false("nearest" %in% findit("mutate egen")$match)
  expect_false("nearest" %in% findit(winsor)$match)
  expect_message(none <- findit("qwzx"), "No Stata command")
  expect_identical(nrow(none), 0L)
})

test_that("printing shows clear defaults and offers remaining entries", {
  withr::local_envvar(LANGUAGE = "en")
  # One entry answers the query: it alone is printed, all are returned.
  best <- findit("merge 1:1 id, keep(match)")
  expect_identical(nrow(best), nrow(findit(merge)))
  expect_identical(best$r[1], "inner_join(data1, data2, by = \"id\")")
  expect_identical(attr(best, "show"), 1L)
  out <- capture.output(print(best))
  expect_identical(sum(startsWith(out, "Stata: ")), 1L)
  expect_true(any(grepl(
    paste0(nrow(best) - 1L, " more examples"),
    out,
    fixed = TRUE
  )))
  # Among entries with every extra word, fewer further options rank first.
  expect_true(any(grepl("keepusing(id) nogenerate", best$stata, fixed = TRUE)))
  # Routine variations remain available through explicit expansion.
  expect_identical(
    sum(startsWith(capture.output(print(findit(tab))), "R: ")),
    1L
  )
  expect_identical(
    sum(startsWith(capture.output(print(findit(reg))), "R: ")),
    1L
  )
  expect_identical(
    sum(startsWith(capture.output(print(findit(tab), n = Inf)), "R: ")),
    nrow(findit(tab))
  )
  expect_snapshot(print(best))
  expect_snapshot(print(findit(reshape)))
})

test_that("closest entries print under their own heading", {
  withr::local_envvar(LANGUAGE = "en")
  expect_snapshot(print(findit("how do I remove duplicate rows"), n = 2))
  expect_snapshot(print(
    findit("count how many people in each category"),
    n = 2
  ))
})

test_that("printing colours headings, Stata code and R code", {
  withr::local_envvar(LANGUAGE = "en")
  local_reproducible_output(crayon = TRUE)
  expect_snapshot(print(findit("merge 1:1 id, keep(match)")))
})

test_that("printing preserves automatic console colours through internal capture", {
  withr::local_options(cli.num_colors = NULL)
  # The outer capture stands in for a colour-capable console. An additional
  # sink, opened by the printer, would normally disable automatic colours.
  console_sink <- sink.number() + 1L
  local_mocked_bindings(
    num_ansi_colors = function(stream = "auto") {
      configured <- getOption("cli.num_colors")
      if (!is.null(configured)) {
        return(as.integer(configured))
      }
      if (sink.number() > console_sink) 1L else 8L
    },
    .package = "cli"
  )
  out <- capture.output(print(findit(codebook)))
  expect_true(any(grepl("\033[34m", out, fixed = TRUE)))
  expect_true(any(grepl("\033[32m", out, fixed = TRUE)))
  expect_null(getOption("cli.num_colors"))
  withr::local_options(cli.num_colors = 1L)
  out <- capture.output(print(findit(codebook)))
  expect_false(any(grepl("\033[", out, fixed = TRUE)))
  expect_identical(getOption("cli.num_colors"), 1L)
})

test_that("codebook prints compact blocks without redundant function notes", {
  withr::local_envvar(LANGUAGE = "en")
  book <- findit("codebook")
  expect_identical(
    capture.output(print(book)),
    c(
      "# Describe every variable [tidystata]",
      "Stata: codebook",
      "R:     codebook(data)",
      "",
      paste0(
        '# ',
        nrow(book) - 1L,
        ' more examples. To see them all: findit("codebook") |> print(n = Inf)'
      )
    )
  )
  withr::local_envvar(LANGUAGE = "zh_CN")
  expect_identical(
    capture.output(print(findit("codebook"))),
    capture.output(cat(
      c(
        "# \u8be6\u7ec6\u63cf\u8ff0\u6bcf\u4e2a\u53d8\u91cf [tidystata]",
        "Stata: codebook",
        "R:     codebook(data)",
        "",
        paste0(
          '# ',
          nrow(book) - 1L,
          ' more examples. To see them all: findit("codebook") |> print(n = Inf)'
        )
      ),
      sep = "\n"
    ))
  )
})

test_that("tab omits a redundant function note and counts hidden examples", {
  for (language in c("en", "zh_CN")) {
    withr::local_envvar(LANGUAGE = language)
    found <- findit("tab")
    out <- capture.output(print(found))
    expect_identical(sum(startsWith(out, "Stata: ")), 1L)
    expect_false(any(grepl("R function:|^# tab\\(\\)", out)))
    expect_true(
      paste0(
        '# ',
        nrow(found) - 1L,
        ' more examples. To see them all: findit("tab") |> print(n = Inf)'
      ) %in%
        out
    )
    out <- capture.output(print(found, n = nrow(found) - 1L))
    expect_true(
      '# 1 more example. To see them all: findit("tab") |> print(n = Inf)' %in%
        out
    )
  }
})

test_that("remaining counts agree with the examples omitted across query types", {
  withr::local_envvar(LANGUAGE = "en")
  for (query in c(
    "tab",
    "summ",
    "mutate",
    "reg",
    "merge",
    "dummy",
    "log",
    "how do I remove duplicate rows",
    "n_distinct"
  )) {
    found <- findit(!!query)
    full <- capture.output(print(found, n = Inf))
    total <- sum(startsWith(full, "Stata: "))
    expect_identical(total, nrow(found), info = query)
    expect_false(any(grepl("more examples?\\.", full)), info = query)
    for (n in c(0, 1, 5, -1)) {
      out <- capture.output(print(found, n = n))
      displayed <- sum(startsWith(out, "Stata: "))
      hidden <- total - displayed
      footer <- grep("^# [0-9]+ more examples?\\.", out, value = TRUE)
      if (hidden > 0L) {
        expect_identical(length(footer), 1L, info = query)
        expect_identical(
          as.integer(sub("^# ([0-9]+).*", "\\1", footer)),
          hidden,
          info = query
        )
      } else {
        expect_identical(length(footer), 0L, info = query)
      }
    }
  }
})

test_that("function notes depend on displayed uses and retain distinct meanings", {
  withr::local_envvar(LANGUAGE = "en")
  book <- findit(codebook)
  expect_false(any(grepl(
    "R function:|Used in",
    capture.output(print(book, n = 1))
  )))
  # A hidden use must not suppress the description.
  out <- capture.output(print(book[2:1, ], n = 1))
  expect_true(any(startsWith(out, "# codebook() [tidystata]: ")))
  expect_false(any(grepl("Used in", out)))
  out <- capture.output(print(book, n = 0))
  expect_true(any(startsWith(out, "# codebook() [tidystata]: ")))
  expect_false(any(startsWith(out, "Stata: ")))
  for (query in c("merge", "fct_relevel")) {
    out <- capture.output(print(findit(!!query)))
    expect_true(any(startsWith(out, paste0("# ", query, "()"))))
  }
  for (query in c("log", "left_join", "summ", "tab")) {
    out <- capture.output(print(findit(!!query)))
    expect_false(any(startsWith(out, paste0("# ", query, "()"))))
  }
  for (query in c(
    "codebook",
    "log",
    "merge",
    "left_join",
    "n_distinct",
    "how do I remove duplicate rows",
    "count how many people in each category"
  )) {
    out <- capture.output(print(findit(!!query), n = 2))
    expect_false(any(grepl(
      "^##|^# Stata to R:|is a Stata command|R function:|Used in",
      out
    )))
    expect_true(nzchar(out[1]))
    expect_true(nzchar(out[length(out)]))
    expect_false(any(!nzchar(out[-1]) & !nzchar(out[-length(out)])))
  }
  out <- capture.output(print(findit("merge how to combine datasets"), n = Inf))
  expect_false(any(!nzchar(out[-1]) & !nzchar(out[-length(out)])))
})
