test_that("quoted column roles customize both reference languages", {
  original <- findit(misstable)
  found <- findit(misstable, income, age)
  row <- match("ref-5c6d7a53c0b5459e", attr(found, "entry_ids"))
  expect_identical(found$stata[row], "misstable summarize income age")
  expect_identical(found$r[row], 'colSums(is.na(data[c("income","age")]))')
  data <- data.frame(income = c(NA, 2, NA), age = c(1, 2, NA))
  preserved <- data
  expect_identical(eval(parse(text = found$r[row])), c(income = 2, age = 1))
  expect_identical(data, preserved)
  expect_identical(findit(misstable), original)
  expect_identical(findit_metadata(found)$r, found$r)

  found <- findit("list", a, b, grp)
  row <- match("ref-735c01b835874d96", attr(found, "entry_ids"))
  expect_identical(found$r[row], 'data[data$grp==2,c("a","b"),drop=FALSE]')
  found <- findit(alpha, item_a, item_b, item_c)
  row <- match("ref-3350ec12cf1b42cc", attr(found, "entry_ids"))
  expect_identical(
    found$r[row],
    'psych::alpha(data[c("item_a","item_b","item_c")],check.keys=FALSE)'
  )
})

test_that("group row and size idioms retain case when ranked", {
  expect_silent(row <- findit("by g, sort: gen n = _n"))
  expect_match(row$stata[1L], "_n", fixed = TRUE)
  expect_false(grepl("_N", row$stata[1L], fixed = TRUE))
  expect_null(attr(row, "unrepresented_options"))
  size <- findit("by g, sort: gen n = _N")
  expect_match(size$stata[1L], "_N", fixed = TRUE)
  expect_false(grepl("_n", size$stata[1L], fixed = TRUE))
})

test_that("first-row syntax outranks lag syntax regardless of spacing", {
  for (query in c(
    "bysort id (year): gen first = _n == 1",
    "bysort id (year): gen first=_n==1"
  )) {
    found <- findit(!!query)
    expect_match(found$stata[1L], "first\\s*=\\s*_n\\s*==\\s*1")
    expect_identical(nrow(found), 1L)
    data <- data.frame(
      id = c(2, 1, 2, NA, 1, NA),
      year = c(2003, 2001, 2001, 2001, 2001, 2000)
    )
    result <- eval(parse(text = found$r[1L]), list2env(list(data = data)))
    expect_identical(
      as.logical(result$first),
      c(TRUE, FALSE, TRUE, FALSE, TRUE, FALSE)
    )
  }
})

test_that("short ranking operands cannot match word fragments", {
  entries <- findit_entries()[1:2, ]
  entries$stata <- c("generate z = exp(y)", "generate z = x")
  ranked <- findit_rank(entries, "x", "stata")
  expect_identical(ranked$stata[1L], "generate z = x")
  expect_identical(ranked$.score, c(1, 0))
})

test_that("ranking retains merge cardinality direction", {
  for (cardinality in c("1:1", "m:1", "1:m")) {
    found <- findit(!!paste("merge", cardinality))
    expect_match(found$stata[1L], paste("merge", cardinality), fixed = TRUE)
  }
})

test_that("by-prefix options are distinct from command options", {
  expect_silent(findit("by g, sort: summarize x"))
  expect_message(
    found <- findit("by g, sort: regress y x, definitelyunsupported"),
    "not represented"
  )
  expect_true(isTRUE(attr(found, "unrepresented_options")))
})

test_that("Chinese plot and reshape questions reach indexed meanings", {
  found <- findit("如何画图")
  expect_gt(nrow(found), 0L)
  expect_true(any(grepl("ggplot|graphics::plot", found$r)))
  for (query in c("转成长格式", "转成宽格式")) {
    found <- findit(!!query)
    expect_gt(nrow(found), 0L)
    expect_true(any(grepl("pivot_longer|pivot_wider|reshape", found$r)))
  }
})

test_that("Stata option names survive variable customization", {
  found <- findit(mds, a, b, c, d, person)
  expect_true(any(grepl("id(", found$stata, fixed = TRUE)))
  expect_false(any(grepl("person(person)", found$stata, fixed = TRUE)))
  found <- findit(poisson, outcome, age, education, years)
  row <- match("ref-b9d67f3ca3ee46f5", attr(found, "entry_ids"))
  expect_identical(
    found$stata[row],
    "poisson outcome age education, exposure(years)"
  )
  expect_match(found$r[row], "offset(log(years))", fixed = TRUE)
})

test_that("compact printing includes legacy qualification notes", {
  withr::local_envvar(LANGUAGE = "en")
  found <- findit(destring)
  row <- match("legacy-0125", attr(found, "entry_ids"))
  note <- findit_metadata(found)$detail[row]
  expect_true(nzchar(note))
  expect_output(print(found[row, ]), note, fixed = TRUE)
  expect_false(any(grepl("# Source:", capture.output(print(found[row, ])))))
  reference <- attr(found, "reference")
  reference$equivalence[row] <- "equivalent"
  attr(found, "reference") <- reference
  expect_output(print(found[row, ]), note, fixed = TRUE)
})

test_that("fixture-bound workflows do not claim to customize unused roles", {
  examples <- list(
    list(query = "marginsplot", variables = "income", id = "legacy-0339"),
    list(
      query = "bootstrap",
      variables = c("income", "age"),
      id = "legacy-0327"
    ),
    list(query = "pctile", variables = c("cut", "income"), id = "legacy-0163")
  )
  for (example in examples) {
    original <- findit(!!example$query)
    call <- rlang::call2("findit", example$query, !!!as.list(example$variables))
    customized <- eval(call)
    row <- match(example$id, attr(customized, "entry_ids"))
    source <- match(example$id, attr(original, "entry_ids"))
    expect_identical(customized$stata[row], original$stata[source])
    expect_identical(customized$r[row], original$r[source])
    expect_false(attr(customized, "customized")[row])
  }
})
