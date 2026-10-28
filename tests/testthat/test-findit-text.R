test_that("Stata text shares comma-argument customization", {
  sex <- region <- row <- stop
  plain <- findit(tab, sex, region)
  rows <- findit(tab, sex, region, row)
  expect_identical(findit(`tab sex region`)$r, plain$r)
  expect_identical(findit("tab sex region")$stata, plain$stata)
  expect_identical(findit(`tab sex region`, row)$r, rows$r)
  expect_identical(findit(`tab sex region, row`)$r, rows$r)
  expect_identical(findit("  ta\tsex region , row  ")$r, rows$r)
  expect_true(all(grepl("sex", rows$r, fixed = TRUE)))
  expect_true(all(grepl("region", rows$r, fixed = TRUE)))
  found <- findit(`tab sex region`)
  expect_identical(attr(found, "input"), "findit(`tab sex region`)")
  expect_identical(eval(parse(text = attr(found, "input")))$r, found$r)
})

test_that("text options do not consume variable names or lose query syntax", {
  expect_identical(findit("tab gen")$r, findit(tab, "gen")$r)
  expect_identical(findit("tab row region")$r, findit(tab, "row", region)$r)
  expect_identical(
    findit("tab sex region, chi2")$r,
    findit(tab, sex, region, chi2)$r
  )
  expect_identical(
    findit("reg robust", income, age)$r[1],
    'fixest::feols(income ~ age, data = data, vcov = "hetero")'
  )
  expect_identical(
    findit("merge 1:1 person using data2, keep(match)")$r[1],
    'inner_join(data1, data2, by = "person")'
  )
  expect_identical(
    findit("egen score = rowmean(a b)")$r[1],
    "mutate(data, score = row_mean(a, b))"
  )
})

test_that("unrecognized Stata syntax stays generic and is never evaluated", {
  text <- 'tab sex region if country == "US, North", row'
  out <- findit(!!text)
  expect_false(any(grepl('"US North"', out$r, fixed = TRUE)))
  expect_match(
    paste(capture.output(print(out)), collapse = "\n"),
    "generic|original placeholders"
  )
  out <- findit(!!text, row)
  expect_match(paste(capture.output(print(out)), collapse = "\n"), "generic")
  ran <- FALSE
  text <- "tab sex region; ran <- TRUE"
  expect_no_error(suppressMessages(findit(!!text)))
  expect_false(ran)
  expect_identical(
    findit(`tab sex region, unknown_option`)$r,
    findit("tab sex region, unknown_option")$r
  )
  expect_identical(
    findit("how do I remove duplicate rows")$match,
    rep("nearest", nrow(findit("how do I remove duplicate rows")))
  )
})

test_that("selection and clipboard helpers print the shared result once", {
  text <- "tab sex region, row"
  local_mocked_bindings(
    findit_editor_selection = function() text,
    findit_clipboard_text = function() text
  )
  expected <- findit(!!text)
  for (helper in list(findit_selection, findit_clip)) {
    output <- capture.output(result <- withVisible(helper()))
    expect_false(result$visible)
    expect_identical(result$value$r, expected$r)
    expect_identical(output, capture.output(print(expected)))
    expect_identical(
      attr(result$value, "input"),
      'findit("tab sex region, row")'
    )
  }
  expect_identical(text, "tab sex region, row")
})

test_that("helper input validation requires one nonempty command", {
  for (text in list(
    NULL,
    character(),
    NA_character_,
    "",
    " \t\n",
    c("tab sex", "tab region"),
    "tab sex\ntab region"
  )) {
    local_mocked_bindings(
      findit_editor_selection = function() text,
      findit_clipboard_text = function() text
    )
    expect_error(findit_selection(), "one nonempty Stata command")
    expect_error(findit_clip(), "one nonempty Stata command")
  }
})

test_that("helpers explain missing optional dependencies", {
  local_mocked_bindings(
    requireNamespace = function(...) FALSE,
    .package = "base"
  )
  expect_error(findit_selection(), "Install.*rstudioapi")
  expect_error(findit_clip(), "Install.*clipr")
})

test_that("source selection requires a supported editor and one selection", {
  skip_if_not_installed("rstudioapi")
  local_mocked_bindings(hasFun = function(...) FALSE, .package = "rstudioapi")
  expect_error(findit_selection(), "source-editor selection")
  local_mocked_bindings(
    hasFun = function(...) TRUE,
    getSourceEditorContext = function() list(selection = list()),
    .package = "rstudioapi"
  )
  expect_error(findit_selection(), "one nonempty Stata command")
  local_mocked_bindings(
    getSourceEditorContext = function() stop("editor unavailable"),
    .package = "rstudioapi"
  )
  expect_error(findit_selection(), "editor unavailable")
})

test_that("clipboard read failures are actionable", {
  skip_if_not_installed("clipr")
  local_mocked_bindings(
    read_clip = function(...) stop("clipboard locked"),
    .package = "clipr"
  )
  expect_error(findit_clip(), "clipboard.*clipboard locked")
})

test_that("editor and clipboard adapters read text without writing it", {
  skip_if_not_installed("rstudioapi")
  skip_if_not_installed("clipr")
  text <- "tab sex region, row"
  local_mocked_bindings(
    hasFun = function(...) TRUE,
    getSourceEditorContext = function() {
      list(selection = list(list(text = text)))
    },
    .package = "rstudioapi"
  )
  local_mocked_bindings(read_clip = function(...) text, .package = "clipr")
  expect_identical(findit_editor_selection(), text)
  expect_identical(findit_clipboard_text(), text)
  for (helper in list(findit_selection, findit_clip)) {
    capture.output(value <- helper())
    expect_identical(value$r, findit(tab, sex, region, row)$r)
  }
  expect_identical(text, "tab sex region, row")
  capture.output(value <- findit_text_result('tab sex if note == "a;b"'))
  expect_s3_class(value, "tidystata_findit")
})

test_that("the installed addin binds the exported selection helper", {
  path <- system.file("rstudio", "addins.dcf", package = "tidystata")
  expect_true(nzchar(path))
  addin <- read.dcf(path)
  expect_identical(unname(addin[1, "Binding"]), "findit_selection")
  expect_identical(unname(addin[1, "Interactive"]), "true")
})

test_that("plain-language lookup keeps its established interpretations", {
  for (query in c(
    "drop duplicate rows",
    "keep complete cases",
    "drop missing observations",
    "sort the data by date",
    "drop rows with missing data",
    "describe all variables",
    "describe the variables"
  )) {
    expected <- findit_select(findit_lookup(query), query)
    actual <- findit(!!query)
    expect_identical(actual$r, expected$r, info = query)
    expect_null(attr(actual, "customized"), info = query)
  }
  expect_identical(findit("drop duplicate rows")$r[1], "duplicates_drop(data)")
})

test_that("qualifiers cannot be captured as variable-list columns", {
  for (query in c(
    "summ income if eligible",
    "reg income age if eligible",
    "reg income age if eligible, robust",
    "summ income in first"
  )) {
    result <- findit(!!query)
    expect_true(isTRUE(attr(result, "generic_text")), info = query)
    expect_null(attr(result, "customized"), info = query)
    expect_false(any(grepl("`if`|`in`", result$r)), info = query)
  }
})
