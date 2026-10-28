test_that("documented minimum Stata abbreviations resolve their commands", {
  commands <- c(
    sa = "save",
    pr = "program",
    q = "query",
    e = "exit",
    conf = "confirm",
    pres = "preserve",
    sca = "scalar",
    ap = "append",
    on = "oneway",
    fac = "factor",
    ty = "type",
    ou = "outfile",
    token = "tokenize",
    cret = "creturn",
    rot = "rotate",
    datasig = "datasignature"
  )
  entries <- findit_entries()
  for (short in names(commands)) {
    result <- findit(!!short)
    metadata <- findit_metadata(result)
    expect_true(
      any(entries$command[match(metadata$id, entries$id)] == commands[[short]]),
      info = short
    )
    expect_identical(result$match[1L], "stata", info = short)
  }
})

test_that("unreviewed dictionary command references explain their limits", {
  for (command in c("xtnbreg", "tsspell", "spmap")) {
    expect_message(result <- findit(!!command), "No curated R equivalent")
    expect_equal(nrow(result), 0L)
  }
})

test_that("former dictionary gaps now resolve to curated examples", {
  expected <- c(
    cumul = "row_number",
    xi = "as_dummy",
    savespss = "write_sav"
  )
  for (command in names(expected)) {
    result <- findit(!!command)
    expect_identical(result$match[1L], "stata", info = command)
    expect_match(
      result$r[1L],
      expected[[command]],
      fixed = TRUE,
      info = command
    )
  }
})

test_that("xi examples omit the lowest category without assuming code one", {
  original <- data.frame(id = 1:4, g = c(2, 4, NA, 2), x = c(9, 8, 7, 6))
  scope <- list2env(list(data = original), parent = globalenv())
  eval(parse(text = findit("xi")$r[1L]), scope)
  expect_identical(scope$data$id, original$id)
  expect_identical(scope$data$g, original$g)
  expect_identical(scope$data$x, original$x)
  expect_false("g_1" %in% names(scope$data))
  expect_identical(as.integer(scope$data$g_2), c(0L, 1L, NA_integer_, 0L))
})
