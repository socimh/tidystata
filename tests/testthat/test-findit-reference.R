test_that("catalogue examples have stable identities independent of Stata text", {
  entries <- findit_entries()
  expect_true("id" %in% names(entries))
  expect_identical(anyDuplicated(entries$id), 0L)
  expect_true(all(nzchar(entries$id)))
  expect_identical(names(findit_templates()), entries$id)
})

test_that("alternative R approaches share syntax without sharing templates", {
  entries <- findit_entries()[rep(1L, 2L), ]
  entries$id <- c("test-preferred", "test-alternative")
  entries$stata <- rep("tabulate x", 2L)
  entries$r <- c("tab(data, x)", "table(data$x)")
  entries$match <- rep("stata", 2L)
  specs <- list(
    list(variables = "x", meaning = "tabulate", priority = 0L),
    list(variables = "x", meaning = "tabulate", priority = 1L)
  )
  names(specs) <- entries$id
  local_mocked_bindings(
    findit_entries = function() entries,
    findit_template_specs = function() specs,
    findit_cache = new.env(parent = emptyenv())
  )
  templates <- findit_templates()
  expect_identical(names(templates), entries$id)
  expect_identical(findit_defaults(entries), 1L)
  expect_identical(findit_render(templates[[2L]], "sex")$r, "table(data$sex)")
})

test_that("single words do not match unrelated word fragments", {
  entries <- findit_entries()[1L, ]
  entries$stata <- "notes x: Collected in wave 2"
  entries$r <- "comment(data$x) <- 'Collected in wave 2'"
  entries$task <- "Store a variable note"
  entries$task_zh <- "记录变量说明"
  expect_false(any(findit_keyword("collect", entries)))
  expect_true(any(findit_keyword("Collected", entries)))
  expect_true(any(findit_keyword("变量", entries)))
})

test_that("known gaps give an explicit explanation and an empty result", {
  local_mocked_bindings(findit_gaps = function() {
    data.frame(
      query = "unsupportedtest",
      detail = "No reviewed equivalent is available.",
      detail_zh = "暂无经过核验的对应实现。"
    )
  })
  expect_message(
    result <- withVisible(findit("unsupportedtest")),
    "No curated R equivalent"
  )
  expect_false(result$visible)
  expect_named(result$value, c("match", "stata", "r", "package", "task"))
  expect_equal(nrow(result$value), 0L)
})

test_that("package qualification constrains R function matches", {
  expect_equal(nrow(suppressMessages(findit("notapackage::left_join"))), 0L)
  expect_identical(
    findit(dplyr::left_join)$r,
    findit(left_join)$r
  )
  for (query in c("stats::mean", "stats::c", "dplyr::is.na")) {
    expect_equal(nrow(suppressMessages(findit(!!query))), 0L)
  }
  expect_identical(findit("survival::surv")$r, findit("survival::Surv")$r)
})

test_that("reference metadata follows examples through customization", {
  x <- findit_customize(findit_lookup("tab"), rlang::exprs(sex))
  metadata <- findit_metadata(x)
  expect_identical(metadata$id, attr(x, "entry_ids"))
  expect_identical(metadata$stata, x$stata)
  expect_identical(metadata$r, x$r)
  expect_true(all(c("source", "r_source", "equivalence") %in% names(metadata)))
  selected <- x[2L, ]
  expect_identical(findit_metadata(selected)$id, metadata$id[2L])
  dropped <- findit_customize(findit_lookup("drop"), rlang::exprs("one", "two"))
  expect_identical(findit_metadata(dropped)$id, attr(dropped, "entry_ids"))
  index <- which(attr(dropped, "entry_ids") == "legacy-0184")
  expect_identical(findit_metadata(dropped[index, ])$id, "legacy-0184")
  filtered <- dplyr::slice(dropped, index)
  expect_identical(findit_metadata(filtered)$id, "legacy-0184")
})

test_that("unrepresented options are not presented as implemented", {
  expect_message(
    x <- findit("regress y x, definitelyunsupported"),
    "not represented"
  )
  expect_true(nrow(x) > 0L)
  expect_true(isTRUE(attr(x, "unrepresented_options")))
})

test_that("expanded printing includes sources and material qualifications", {
  x <- findit(tab)
  reference <- attr(x, "reference")
  reference$validation[1L] <- "executed"
  reference$equivalence[1L] <- "qualified"
  reference$detail[1L] <- "Check whether missing values should be retained."
  attr(x, "reference") <- reference
  compact <- capture.output(print(x))
  expect_true(any(grepl("Check whether missing", compact, fixed = TRUE)))
  expect_false(any(grepl("# Source:", compact, fixed = TRUE)))
  expanded <- capture.output(print(x, n = 1L))
  expect_true(any(grepl("# Source:", expanded, fixed = TRUE)))
})

test_that("qualified matches do not leak another explicit namespace", {
  entries <- data.frame(
    r = c("dplyr::filter(data, x > 0)", "filter(data, x > 0)"),
    package = rep("stats", 2L)
  )
  expect_identical(
    findit_namespace_hit("stats", "filter", entries),
    c(FALSE, TRUE)
  )
})

test_that("coverage counts distinguish commands, functions and examples", {
  entries <- findit_entries()
  counts <- findit_reference_counts()
  expect_identical(counts$examples, nrow(entries))
  expect_identical(
    counts$commands,
    length(unique(
      entries$command[entries$kind == "command"]
    ))
  )
  expect_lt(counts$commands, length(unique(entries$command)))
  expect_identical(counts$stata_examples, length(unique(entries$stata)))
  expect_identical(counts$verified, sum(entries$validation == "executed"))
})

test_that("the bilingual reference shares catalogue IDs and source links", {
  english <- paste(findit_reference_html(), collapse = "\n")
  chinese <- paste(findit_reference_html(TRUE), collapse = "\n")
  first <- findit_entries()$id[1L]
  expect_match(english, paste0('id="example-', first, '"'), fixed = TRUE)
  expect_match(english, "Alphabetical command index", fixed = TRUE)
  expect_match(english, "https://www.stata.com/manuals/dsave.pdf", fixed = TRUE)
  expect_match(english, "R functions by package", fixed = TRUE)
  expect_false(identical(english, chinese))
  expect_match(chinese, "&#", fixed = TRUE)
  entries <- findit_entries()
  expect_false(grepl("<small>(equivalent|qualified|workflow)", english))
  flagged <- sum(entries$equivalence == "qualified" & nzchar(entries$detail))
  expect_identical(
    lengths(regmatches(
      english,
      gregexpr("Differs from Stata&#58;", english, fixed = TRUE)
    )),
    flagged
  )
})

test_that("editing a returned code cell cannot attach stale qualifications", {
  x <- findit(tab)
  x$r[1L] <- "user_defined_example()"
  expect_output(print(x), "user_defined_example()", fixed = TRUE)
  expect_output(print(x, n = 1L), "user_defined_example()", fixed = TRUE)
  expect_identical(findit_metadata(x)$source[1L], "")
})

test_that("executed examples have matching reproducible fixtures", {
  entries <- findit_entries()
  rows <- entries$validation == "executed"
  fixtures <- utils::read.csv(
    test_path("fixtures", "findit", "reference.csv"),
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8"
  )
  expect_identical(fixtures$id, entries$id[rows])
  expect_identical(fixtures$code, entries$r[rows])
  expect_type(fixtures$setup, "character")
  expect_true(all(nzchar(fixtures$check)))
  for (column in c("task_zh", "section_zh")) {
    expect_true(all(grepl("[\u3400-\u9fff]", entries[[column]], perl = TRUE)))
    expect_false(any(grepl(
      "[[:cntrl:]]|\ufffd",
      entries[[column]],
      perl = TRUE
    )))
  }
  descriptions <- findit_functions()$description_zh
  expect_true(all(grepl("[\u3400-\u9fff]", descriptions, perl = TRUE)))
  expect_false(any(grepl("<U+", descriptions, fixed = TRUE)))
})

test_that("workflow-local helpers are not advertised as package functions", {
  code <- "helper <- function(x) mean(x); helper(data$x)"
  expect_identical(findit_calls(code), list("mean"))
  code <- "survival::coxph(Surv(time, event) ~ x + tt(z), data = data)"
  expect_identical(findit_calls(code), list(c("coxph", "Surv")))
})

test_that("known unsupported commands cannot fall through to prose matches", {
  expect_message(x <- findit(collect), "No curated R equivalent")
  expect_equal(nrow(x), 0L)
  expect_message(x <- findit("gmm y x"), "No curated R equivalent")
  expect_equal(nrow(x), 0L)
  expect_message(x <- findit(bayesmh), NA)
  expect_gt(nrow(x), 0L)
})

test_that("capitalized Stata distribution functions match their canonical key", {
  rows <- findit_entries()
  expected <- rows$stata[rows$command == "F"]
  expect_gt(length(expected), 0L)
  expect_identical(findit("F")$stata, expected)
  expect_identical(findit("f")$stata, expected)
})

test_that("categorical regression examples convert numeric category codes", {
  entries <- findit_entries()
  row <- which(entries$stata == "regress y i.g c.x")
  scope <- new.env(parent = globalenv())
  scope$data <- transform(mtcars, y = mpg, x = wt, g = cyl)
  fit <- eval(parse(text = entries$r[row]), scope)
  expect_length(stats::coef(fit), 4L)
})

test_that("axis-label customization preserves fixed ggplot argument names", {
  skip_if_not_installed("ggplot2")
  entries <- findit_entries()
  templates <- findit_templates()
  row <- which(entries$stata == 'scatter y x, xtitle("Age")')
  rendered <- findit_render(templates[[entries$id[row]]], c("outcome", "score"))
  scope <- new.env(parent = globalenv())
  scope$data <- data.frame(outcome = 1:4, score = 4:1)
  plot <- eval(parse(text = rendered$r), scope)
  expect_identical(ggplot2::get_labs(plot)$x, "Age")
})

test_that("egen summaries keep all-missing inputs missing", {
  entries <- findit_entries()
  examples <- c("egen z = min(x)", "egen z = max(x)", "egen z = lastnm(x)")
  # Every alternative for these commands, base and tidyverse alike.
  for (row in which(entries$stata %in% examples)) {
    scope <- new.env(parent = globalenv())
    scope$data <- data.frame(x = rep(NA_real_, 3L))
    expect_warning(eval(parse(text = entries$r[row]), scope), NA)
    expect_identical(scope$data$z, rep(NA_real_, 3L), info = entries$r[row])
  }
  expect_setequal(entries$stata[entries$stata %in% examples], examples)
})
