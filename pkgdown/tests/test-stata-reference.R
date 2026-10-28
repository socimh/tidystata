# Run from the package root after sourcing pkgdown/build-stata-reference.R.
testthat::test_that("chapter planning retains IDs and splits at command boundaries", {
  rows <- data.frame(
    id = paste0("id", 1:7),
    section = "Data management",
    section_zh = "\u6570\u636e\u7ba1\u7406",
    command = c("a", "a", "b", "b", "c", "c", "c"),
    stata = paste("command", 1:7),
    stringsAsFactors = FALSE
  )
  pages <- stata_reference_plan(rows, setNames(1:7, rows$id), max_examples = 4L)
  testthat::expect_equal(length(pages), 2L)
  testthat::expect_equal(pages[[1L]]$ids, rows$id[1:4])
  testthat::expect_equal(pages[[2L]]$ids, rows$id[5:7])
  testthat::expect_setequal(unlist(lapply(pages, `[[`, "ids")), rows$id)
  testthat::expect_identical(pages[[1L]]$slug, "data-management")
  testthat::expect_identical(pages[[2L]]$slug, "data-management-2")
  # An unusually large command is split rather than bypassing the page limit.
  rows$command <- "a"
  pages <- stata_reference_plan(rows, setNames(1:7, rows$id), max_examples = 4L)
  testthat::expect_equal(lengths(lapply(pages, `[[`, "ids")), c(4L, 3L))
  rows$id[2] <- rows$id[1]
  testthat::expect_error(
    stata_reference_plan(rows, setNames(1:7, rows$id)),
    "unique"
  )
})

testthat::test_that("examples retain literal code and qualifications in both languages", {
  row <- data.frame(
    id = "quoted",
    command = "display",
    package = "base",
    stata = "display `\"<label> & `x'\"'",
    r = "paste0(\"\u4e2d\u6587 <x> & \", x)",
    task = "Show a label",
    task_zh = "\u663e\u793a\u6807\u7b7e",
    detail = "Check <values> & labels.",
    detail_zh = "\u68c0\u67e5\u6570\u503c\u4e0e\u6807\u7b7e\u3002",
    equivalence = "qualified",
    source = "https://www.stata.com/?x=1&y=2",
    r_source = "https://rdrr.io/"
  )
  for (lang in c("en", "zh")) {
    body <- stata_reference_example(row, lang)
    testthat::expect_match(body, row$stata, fixed = TRUE)
    testthat::expect_match(body, row$r, fixed = TRUE)
    testthat::expect_match(body, 'data-example-id="quoted"', fixed = TRUE)
    testthat::expect_match(body, "example-labels", fixed = TRUE)
    testthat::expect_match(
      body,
      "https://www.stata.com/?x=1&amp;y=2",
      fixed = TRUE
    )
  }
})

testthat::test_that("page budgets reject collapsed content and oversized downloads", {
  tmp <- tempfile()
  dir.create(tmp)
  page <- file.path(tmp, "page.html")
  writeLines(
    paste0(
      "<html><body><details>",
      strrep("<i>x</i>", 10001),
      "</details></body></html>"
    ),
    page,
    useBytes = TRUE
  )
  testthat::expect_error(stata_reference_page_size(page), "elements")
  writeLines(
    paste0("<html><body>", strrep("x", 512L * 1024L), "</body></html>"),
    page,
    useBytes = TRUE
  )
  testthat::expect_error(stata_reference_page_size(page), "512 KiB")
})

testthat::test_that("navigation round trips as UTF-8 in a C locale", {
  page <- list(
    slug = "test",
    title = "Test",
    title_zh = "\u4e2d\u6587",
    ids = "a"
  )
  body <- stata_reference_frame("Text", list(page), "test", "en")
  tmp <- tempfile()
  writeLines(enc2utf8(body), tmp, useBytes = TRUE)
  text <- paste(
    readr::read_lines(tmp, locale = readr::locale(encoding = "UTF-8")),
    collapse = "\n"
  )
  testthat::expect_match(text, "\u00b7", fixed = TRUE)
  testthat::expect_match(text, "\u4e2d\u6587", fixed = TRUE)
})

testthat::test_that("obsolete generated files stop the build without deletion", {
  testthat::expect_error(
    stata_reference_check_stale(
      c("stata-current.Rmd", "stata-old.Rmd"),
      "stata-current.Rmd"
    ),
    "obsolete"
  )
  testthat::expect_silent(stata_reference_check_stale(
    "stata-current.Rmd",
    "stata-current.Rmd"
  ))
})

testthat::test_that("finished guides declare their language and link to tracked source", {
  pkg <- tempfile()
  output <- file.path(pkg, "site")
  dir.create(
    file.path(pkg, "pkgdown/stata-reference-generated"),
    recursive = TRUE
  )
  dir.create(file.path(output, "articles"), recursive = TRUE)
  saveRDS(
    list(pages = list(list(slug = "test"))),
    file.path(pkg, "pkgdown/stata-reference-generated/manifest.rds")
  )
  for (lang in c("en", "zh")) {
    for (filename in c(
      stata_reference_home(lang),
      stata_reference_filename(c("test", "command-index", "r-index"), lang)
    )) {
      writeLines(
        paste0(
          '<html lang="en"><body><a href="https://github.com/socimh/tidystata/blob/HEAD/',
          'vignettes/articles/stata-test.Rmd">Source</a></body></html>'
        ),
        file.path(output, "articles", filename)
      )
    }
  }
  finalize_stata_reference(pkg, output)
  html <- readLines(file.path(output, "articles/stata-zh-test.html"))
  testthat::expect_match(html, '<html lang="zh">', fixed = TRUE)
  testthat::expect_match(
    html,
    'blob/HEAD/pkgdown/build-stata-reference.R',
    fixed = TRUE
  )
  testthat::expect_false(grepl('vignettes/articles/stata-', html, fixed = TRUE))
})

testthat::test_that("Pandoc preserves multiplication and punctuation in catalogue notes", {
  row <- data.frame(
    id = "math",
    command = "model",
    package = "nlme",
    stata = "model y x ",
    r = "model(y, x)",
    task = "Fit a model",
    task_zh = "Fit",
    detail = "SD is exp(theta*z), variance is 2*theta. RStudio's x_y ... a--b.",
    detail_zh = "SD",
    equivalence = "equivalent",
    source = "https://www.stata.com/",
    r_source = "https://rdrr.io/"
  )
  input <- tempfile(fileext = ".md")
  output <- tempfile(fileext = ".html")
  writeLines(stata_reference_example(row, "en"), input)
  rmarkdown::pandoc_convert(
    input,
    from = "markdown",
    to = "html",
    output = output,
    options = "--wrap=none"
  )
  doc <- xml2::read_html(output, encoding = "UTF-8")
  note <- xml2::xml_text(xml2::xml_find_first(
    doc,
    './/*[@class="example-note"]'
  ))
  testthat::expect_identical(trimws(note), row$detail)
  code <- xml2::xml_text(xml2::xml_find_all(doc, ".//pre/code"))
  testthat::expect_identical(code[1L], row$stata)
})

testthat::test_that("unchanged chapter sources do not force another render", {
  file <- tempfile()
  stata_reference_write(c("Header", "Body\nLine"), file)
  Sys.setFileTime(file, Sys.time() - 60)
  before <- file.info(file)$mtime
  stata_reference_write(c("Header", "Body\nLine"), file)
  testthat::expect_identical(file.info(file)$mtime, before)
  stata_reference_write(c("Header", "Changed"), file)
  testthat::expect_identical(readLines(file), c("Header", "Changed"))
})

testthat::test_that("finalization restores only terminal spaces lost by highlighting", {
  html <- '<div data-example-id="a"><pre><code><span>display x</span></code></pre><pre><code>x</code></pre></div>'
  rows <- data.frame(id = "a", stata = "display x ", r = "x")
  restored <- stata_reference_restore_spaces(html, rows)
  doc <- xml2::read_html(restored)
  testthat::expect_identical(
    xml2::xml_text(xml2::xml_find_all(doc, ".//pre/code")),
    c("display x ", "x")
  )
  testthat::expect_match(restored, "<span>display x </span>", fixed = TRUE)
  rows$stata <- "display y"
  testthat::expect_identical(stata_reference_restore_spaces(html, rows), html)
  repeated <- paste0(
    html,
    sub('data-example-id="a"', 'data-example-id="b"', html, fixed = TRUE)
  )
  repeated <- gsub(
    'data-example-id="([ab])"',
    'id="example-\\1" data-example-id="\\1"',
    repeated
  )
  rows <- data.frame(id = c("a", "b"), stata = "display x", r = c("x", "x "))
  doc <- xml2::read_html(stata_reference_restore_spaces(repeated, rows))
  testthat::expect_identical(
    xml2::xml_text(xml2::xml_find_all(
      doc,
      './/*[@data-example-id="b"]//pre/code'
    )),
    c("display x", "x ")
  )
})
