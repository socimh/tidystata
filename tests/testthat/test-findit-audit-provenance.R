test_that("legacy sources identify the command rather than a whole manual", {
  entries <- findit_entries()
  legacy <- entries[entries$validation == "legacy", ]
  expect_false(any(legacy$source == "https://www.stata.com/manuals/u.pdf"))
  expect_false(any(grepl("R-release/", legacy$r_source, fixed = TRUE)))
  expected <- c(
    "legacy-0057" = "rttest.pdf",
    "legacy-0127" = "dpctile.pdf",
    "legacy-0334" = "rregresspostestimation.pdf",
    "legacy-0358" = "u11.pdf",
    "legacy-0386" = "g-2graphtwowayscatter.pdf"
  )
  for (id in names(expected)) {
    expect_match(legacy$source[legacy$id == id], expected[[id]], fixed = TRUE)
  }
})

test_that("legacy equivalence distinguishes core parity from qualifications", {
  entries <- findit_entries()
  expected <- c(
    "legacy-0004" = "workflow",
    "legacy-0057" = "qualified",
    "legacy-0087" = "equivalent",
    "legacy-0127" = "equivalent",
    "legacy-0168" = "qualified",
    "legacy-0373" = "qualified"
  )
  for (id in names(expected)) {
    row <- entries[entries$id == id, ]
    expect_identical(row$equivalence, unname(expected[[id]]))
    expect_identical(row$validation, "legacy")
  }
})

test_that("every qualified example states its material caveat bilingually", {
  entries <- findit_entries()
  qualified <- entries[entries$equivalence == "qualified", ]
  expect_true(all(nzchar(trimws(qualified$detail))))
  expect_true(all(nzchar(trimws(qualified$detail_zh))))
  expect_true(all(grepl("[\u3400-\u9fff]", qualified$detail_zh, perl = TRUE)))
  expect_true(all(grepl("[\u3400-\u9fff]", qualified$detail_zh, perl = TRUE)))
  for (id in c("legacy-0057", "legacy-0168", "legacy-0373")) {
    row <- entries[entries$id == id, ]
    expect_match(
      row$detail,
      switch(
        id,
        "legacy-0057" = "Welch",
        "legacy-0168" = "halves to even",
        "legacy-0373" = "ties"
      ),
      fixed = TRUE
    )
  }
})
