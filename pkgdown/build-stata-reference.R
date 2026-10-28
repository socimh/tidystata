# Website-only tooling. Sources and assets are generated before pkgdown inventories
# articles; none of these generated files belong in the R package or Git.
stata_reference_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub('"', "&quot;", x, fixed = TRUE)
}

stata_reference_write <- function(lines, path) {
  text <- paste(enc2utf8(lines), collapse = "\n")
  if (
    file.exists(path) &&
      identical(
        paste(
          readLines(path, encoding = "UTF-8", warn = FALSE),
          collapse = "\n"
        ),
        text
      )
  ) {
    return(invisible(FALSE))
  }
  writeLines(text, path, useBytes = TRUE)
  invisible(TRUE)
}

stata_reference_tr <- function(lang, en, zh) {
  if (lang == "zh") zh else en
}

stata_reference_filename <- function(slug, lang) {
  paste0("stata-", if (lang == "zh") "zh-", slug, ".html")
}

stata_reference_home <- function(lang) {
  paste0("coming-from-stata", if (lang == "zh") "-zh", ".html")
}

stata_reference_check_stale <- function(existing, expected) {
  obsolete <- setdiff(existing, expected)
  if (length(obsolete)) {
    stop(
      "Found obsolete generated reference files; use a fresh build directory: ",
      paste(obsolete, collapse = ", ")
    )
  }
  invisible(NULL)
}

stata_reference_literal <- function(x) {
  # Catalogue prose is literal text. Entity-encode punctuation so Pandoc cannot
  # reinterpret multiplication signs as emphasis, or underscores as markup.
  vapply(
    x,
    function(text) {
      codes <- utf8ToInt(text)
      punctuation <- codes %in% c(33:47, 58:64, 91:96, 123:126)
      chars <- vapply(codes, intToUtf8, character(1))
      chars[punctuation] <- paste0("&#", codes[punctuation], ";")
      paste0(chars, collapse = "")
    },
    character(1),
    USE.NAMES = FALSE
  )
}

stata_reference_prose <- function(text) {
  # Compare visible prose, allowing only HTML white-space transformations.
  text <- gsub("\u00a0", " ", text, fixed = TRUE)
  text <- gsub("[[:space:]]+", " ", text)
  # HTML source wrapping between two CJK characters has no visible space.
  gsub("([\u3000-\u9fff]) +(?=[\u3000-\u9fff])", "\\1", text, perl = TRUE)
}

stata_reference_plan <- function(entries, priority, max_examples = 60L) {
  if (anyDuplicated(entries$id) || any(!nzchar(entries$id))) {
    stop("Reference example IDs must be nonempty and unique.")
  }
  if (!all(entries$id %in% names(priority))) {
    stop("Reference priorities must cover every example ID.")
  }
  pages <- list()
  for (section in sort(unique(entries$section), method = "radix")) {
    rows <- entries[entries$section == section, ]
    rows <- rows[
      order(
        rows$command,
        priority[rows$id],
        rows$stata,
        rows$id,
        method = "radix"
      ),
    ]
    groups <- lapply(unique(rows$command), function(command) {
      ids <- rows$id[rows$command == command]
      split(ids, ceiling(seq_along(ids) / max_examples))
    })
    groups <- unlist(groups, recursive = FALSE)
    chunks <- list()
    current <- character()
    for (ids in groups) {
      if (length(current) + length(ids) > max_examples) {
        chunks[[length(chunks) + 1L]] <- current
        current <- character()
      }
      current <- c(current, ids)
    }
    if (length(current)) {
      chunks[[length(chunks) + 1L]] <- current
    }
    slug <- gsub("^-|-$", "", gsub("[^a-z0-9]+", "-", tolower(section)))
    if (!nzchar(slug)) {
      stop("A subject needs an ASCII slug: ", section)
    }
    for (i in seq_along(chunks)) {
      suffix <- if (length(chunks) > 1L) {
        paste0(" (", i, "/", length(chunks), ")")
      } else {
        ""
      }
      pages[[length(pages) + 1L]] <- list(
        slug = paste0(slug, if (i > 1L) paste0("-", i)),
        title = paste0(section, suffix),
        title_zh = paste0(rows$section_zh[1L], suffix),
        section = section,
        ids = unname(chunks[[i]])
      )
    }
  }
  slugs <- vapply(pages, `[[`, character(1), "slug")
  if (anyDuplicated(c(slugs, "command-index", "r-index"))) {
    stop("Reference page slug collision.")
  }
  pages
}

stata_reference_code <- function(code, language) {
  ticks <- regmatches(code, gregexpr("`+", code))[[1L]]
  fence <- strrep("`", max(3L, nchar(ticks) + 1L))
  paste0(fence, language, "\n", code, "\n", fence, "\n")
}

stata_reference_example <- function(row, lang) {
  tr <- function(en, zh) stata_reference_tr(lang, en, zh)
  esc <- stata_reference_escape
  task <- if (lang == "zh") row$task_zh else row$task
  detail <- if (lang == "zh") row$detail_zh else row$detail
  lines <- c(
    paste0(
      '::: {#example-',
      row$id,
      ' .reference-example data-example-id="',
      row$id,
      '"}'
    ),
    "",
    paste0('<p class="example-task">', stata_reference_literal(task), "</p>"),
    "",
    "::: {.comparison}",
    "",
    "::: {.comparison-stata}",
    "",
    '<p class="col-label">Stata</p>',
    "",
    stata_reference_code(row$stata, "stata"),
    ":::",
    "",
    "::: {.comparison-r}",
    "",
    paste0('<p class="col-label">R <code>', esc(row$package), "</code></p>"),
    "",
    stata_reference_code(row$r, "r"),
    ":::",
    "",
    ":::",
    ""
  )
  if (nzchar(detail)) {
    caveat <- if (row$equivalence == "qualified") {
      paste0(
        '<a class="caveat-tag" href="',
        stata_reference_home(lang),
        '#example-labels">',
        tr("Differs from Stata", "\u4e0e Stata \u6709\u5dee\u5f02"),
        "</a> "
      )
    } else {
      ""
    }
    lines <- c(
      lines,
      paste0(
        '<p class="example-note">',
        caveat,
        stata_reference_literal(detail),
        "</p>"
      ),
      ""
    )
  }
  c(
    lines,
    paste0(
      '<p class="example-sources"><a href="',
      esc(row$source),
      '">',
      tr("Stata reference", "Stata \u53c2\u8003"),
      '</a> \u00b7 <a href="',
      esc(row$r_source),
      '">',
      tr("R reference", "R \u53c2\u8003"),
      "</a></p>"
    ),
    "",
    ":::",
    ""
  ) |>
    paste(collapse = "\n")
}

stata_reference_navigation <- function(pages, current, lang) {
  tr <- function(en, zh) stata_reference_tr(lang, en, zh)
  esc <- stata_reference_escape
  links <- vapply(
    pages,
    function(page) {
      title <- if (lang == "zh") page$title_zh else page$title
      paste0(
        '<li><a href="',
        stata_reference_filename(page$slug, lang),
        '"',
        if (page$slug == current) ' aria-current="page"',
        ">",
        esc(title),
        "</a></li>"
      )
    },
    character(1)
  )
  c(
    '<details class="stata-chapters dont-index" open>',
    paste0("<summary>", tr("Chapters", "\u7ae0\u8282"), "</summary>"),
    paste0(
      '<nav aria-label="',
      tr("Stata to R chapters", "Stata \u8f6c R \u7ae0\u8282"),
      '">'
    ),
    paste0(
      '<a href="',
      stata_reference_home(lang),
      '">',
      tr("Start here", "\u4ece\u8fd9\u91cc\u5f00\u59cb"),
      "</a>"
    ),
    "<ul>",
    links,
    "</ul>",
    "</nav>",
    "</details>",
    ""
  )
}

stata_reference_frame <- function(body, pages, slug, lang) {
  tr <- function(en, zh) stata_reference_tr(lang, en, zh)
  other <- if (lang == "en") "zh" else "en"
  sequence <- c(
    vapply(pages, `[[`, character(1), "slug"),
    "command-index",
    "r-index"
  )
  position <- match(slug, sequence)
  previous <- if (position == 1L) {
    stata_reference_home(lang)
  } else {
    stata_reference_filename(sequence[position - 1L], lang)
  }
  following <- if (position == length(sequence)) {
    stata_reference_home(lang)
  } else {
    stata_reference_filename(sequence[position + 1L], lang)
  }
  c(
    paste0(
      '::: {.stata-reference data-language="',
      lang,
      '" data-link-map="../stata-reference-links.json"}'
    ),
    "",
    stata_reference_navigation(pages, slug, lang),
    "::: {.stata-reference-content}",
    "",
    paste0(
      '<nav class="stata-tools dont-index" aria-label="',
      tr("Reference tools", "\u53c2\u8003\u5de5\u5177"),
      '">',
      '<a href="',
      stata_reference_home(lang),
      '">',
      tr("Contents", "\u76ee\u5f55"),
      "</a> \u00b7 ",
      '<a href="',
      stata_reference_filename("command-index", lang),
      '">',
      tr("Stata index", "Stata \u7d22\u5f15"),
      "</a> \u00b7 ",
      '<a href="',
      stata_reference_filename("r-index", lang),
      '">',
      tr("R index", "R \u7d22\u5f15"),
      "</a> \u00b7 ",
      '<a id="stata-language-toggle" href="',
      stata_reference_filename(slug, other),
      '" hreflang="',
      other,
      '">',
      tr("\u4e2d\u6587", "English"),
      "</a></nav>"
    ),
    "",
    body,
    "",
    paste0(
      '<nav class="stata-page-navigation dont-index" aria-label="',
      tr("Page navigation", "\u9875\u9762\u5bfc\u822a"),
      '">',
      '<a rel="prev" href="',
      previous,
      '">\u2190 ',
      tr("Previous", "\u4e0a\u4e00\u9875"),
      "</a>",
      '<a rel="next" href="',
      following,
      '">',
      tr("Next", "\u4e0b\u4e00\u9875"),
      " \u2192</a></nav>"
    ),
    "",
    ":::",
    "",
    ":::"
  )
}

stata_reference_chapter <- function(page, entries, preferred, lang) {
  rows <- entries[match(page$ids, entries$id), ]
  body <- c(
    stata_reference_tr(
      lang,
      "Start with the expanded examples. Open further examples for options and alternative R approaches.",
      "\u5148\u67e5\u770b\u5c55\u5f00\u7684\u793a\u4f8b\uff0c\u518d\u6309\u9700\u5c55\u5f00\u5176\u4ed6\u9009\u9879\u53ca R \u5b9e\u73b0\u3002"
    ),
    ""
  )
  commands <- unique(rows$command)
  for (i in seq_along(commands)) {
    group <- rows[rows$command == commands[i], ]
    show <- group$id %in% preferred
    if (!any(show)) {
      show[1L] <- TRUE
    }
    body <- c(
      body,
      paste0("## ", "`` ", commands[i], " `` {#command-", i, "}"),
      ""
    )
    body <- c(
      body,
      vapply(
        which(show),
        function(j) {
          stata_reference_example(group[j, ], lang)
        },
        character(1)
      )
    )
    if (any(!show)) {
      body <- c(
        body,
        '<details class="reference-variants">',
        paste0(
          "<summary>",
          stata_reference_tr(
            lang,
            paste(sum(!show), "more examples and alternatives"),
            paste0(
              "\u53e6\u6709 ",
              sum(!show),
              " \u4e2a\u793a\u4f8b\u53ca\u66ff\u4ee3\u5b9e\u73b0"
            )
          ),
          "</summary>"
        ),
        "",
        vapply(
          which(!show),
          function(j) stata_reference_example(group[j, ], lang),
          character(1)
        ),
        "</details>",
        ""
      )
    }
  }
  body
}

stata_reference_indexes <- function(
  entries,
  functions,
  locations,
  preferred,
  lang
) {
  tr <- function(en, zh) stata_reference_tr(lang, en, zh)
  esc <- stata_reference_escape
  commands <- sort(unique(entries$command), method = "radix")
  targets <- setNames(
    vapply(
      commands,
      function(command) {
        rows <- entries[entries$command == command, ]
        candidates <- which(rows$id %in% preferred)
        row <- rows[if (length(candidates)) candidates[1L] else 1L, ]
        paste0(
          stata_reference_filename(locations[[row$id]], lang),
          "#example-",
          row$id
        )
      },
      character(1)
    ),
    commands
  )
  command_index <- c(
    tr(
      "Choose a command, function, operator or prefix to open its examples.",
      "\u9009\u62e9\u547d\u4ee4\u3001\u51fd\u6570\u3001\u8fd0\u7b97\u7b26\u6216\u524d\u7f00\uff0c\u6253\u5f00\u5bf9\u5e94\u793a\u4f8b\u3002"
    ),
    ""
  )
  kinds <- c(
    command = tr("Commands", "\u547d\u4ee4"),
    `function` = tr("Functions", "\u51fd\u6570"),
    operator = tr("Operators", "\u8fd0\u7b97\u7b26"),
    prefix = tr("Prefixes", "\u524d\u7f00")
  )
  for (kind in names(kinds)) {
    command_index <- c(
      command_index,
      paste0("## ", kinds[[kind]], " {#", kind, "}"),
      "",
      "<ul>"
    )
    for (command in commands) {
      rows <- entries[entries$command == command & entries$kind == kind, ]
      if (!nrow(rows)) {
        next
      }
      task <- if (lang == "zh") rows$task_zh[1L] else rows$task[1L]
      command_index <- c(
        command_index,
        paste0(
          '<li><a href="',
          targets[[command]],
          '"><code>',
          esc(command),
          "</code></a> \u2014 ",
          stata_reference_literal(task),
          "</li>"
        )
      )
    }
    command_index <- c(command_index, "</ul>", "")
  }
  r_index <- c(
    tr(
      "Functions are grouped by package. Linked Stata names open paired examples; this is not an installation list.",
      "R \u51fd\u6570\u6309\u5305\u5206\u7ec4\u3002\u5df2\u5173\u8054\u7684 Stata \u540d\u79f0\u94fe\u63a5\u5230\u914d\u5bf9\u793a\u4f8b\uff0c\u8fd9\u91cc\u5e76\u975e\u9700\u8981\u5b89\u88c5\u7684\u5305\u6e05\u5355\u3002"
    ),
    ""
  )
  for (package in sort(unique(functions$package), method = "radix")) {
    rows <- functions[functions$package == package, ]
    rows <- rows[order(rows$`function`, method = "radix"), ]
    r_index <- c(r_index, paste0("## ", package), "", "<ul>")
    for (i in seq_len(nrow(rows))) {
      description <- if (lang == "zh") {
        rows$description_zh[i]
      } else {
        rows$description[i]
      }
      stata <- rows$stata[i]
      link <- if (stata %in% names(targets)) {
        paste0(
          ' <a href="',
          targets[[stata]],
          '">Stata: <code>',
          esc(stata),
          "</code></a>"
        )
      } else if (nzchar(stata)) {
        paste0(" Stata: <code>", esc(stata), "</code>")
      } else {
        ""
      }
      r_index <- c(
        r_index,
        paste0(
          "<li><code>",
          esc(rows$`function`[i]),
          "()</code> \u2014 ",
          stata_reference_literal(description),
          link,
          "</li>"
        )
      )
    }
    r_index <- c(r_index, "</ul>", "")
  }
  list(`command-index` = command_index, `r-index` = r_index)
}

build_stata_reference <- function(pkg = ".") {
  pkg <- normalizePath(pkg, winslash = "/", mustWork = TRUE)
  entries <- tidystata:::findit_entries()
  templates <- tidystata:::findit_templates()
  functions <- tidystata:::findit_functions()
  priority <- vapply(templates, function(x) x$priority, integer(1))
  # Require the freshly installed catalogue, not a stale default installation.
  disk <- readr::read_csv(
    file.path(pkg, "inst/extdata/stata-to-r.csv"),
    col_types = readr::cols(.default = readr::col_character()),
    na = character(),
    locale = readr::locale(encoding = "UTF-8"),
    progress = FALSE
  )
  if (
    !identical(entries$id, disk$id) ||
      !identical(entries$r, disk$r) ||
      !identical(entries$stata, disk$stata)
  ) {
    stop("Install the current source before generating reference articles.")
  }
  pages <- stata_reference_plan(entries, priority)
  slugs <- c(
    vapply(pages, `[[`, character(1), "slug"),
    "command-index",
    "r-index"
  )
  expected <- sub(
    "[.]html$",
    ".Rmd",
    c(
      stata_reference_filename(slugs, "en"),
      stata_reference_filename(slugs, "zh")
    )
  )
  stata_reference_check_stale(
    list.files(
      file.path(pkg, "vignettes/articles"),
      pattern = "^stata-.*[.]Rmd$"
    ),
    expected
  )
  locations <- setNames(
    unlist(
      lapply(pages, function(page) {
        rep(page$slug, length(page$ids))
      }),
      use.names = FALSE
    ),
    unlist(lapply(pages, `[[`, "ids"), use.names = FALSE)
  )
  preferred <- unique(unlist(
    lapply(unique(entries$command), function(command) {
      found <- do.call(tidystata::findit, list(command = command))
      attr(found, "entry_ids")[attr(found, "default_rows")]
    }),
    use.names = FALSE
  ))
  generated <- file.path(pkg, "pkgdown/stata-reference-generated")
  assets <- file.path(pkg, "pkgdown/assets")
  dir.create(generated, recursive = TRUE, showWarnings = FALSE)
  dir.create(assets, recursive = TRUE, showWarnings = FALSE)
  article_dir <- file.path(pkg, "vignettes/articles")
  write_page <- function(slug, title, body, lang) {
    filename <- sub("[.]html$", ".Rmd", stata_reference_filename(slug, lang))
    # JSON strings are valid YAML scalar strings and preserve non-ASCII titles.
    header <- c(
      "---",
      paste0("title: ", jsonlite::toJSON(title, auto_unbox = TRUE)),
      "---",
      "",
      "<!-- Generated by pkgdown/build-stata-reference.R; do not edit. -->",
      ""
    )
    stata_reference_write(
      c(header, stata_reference_frame(body, pages, slug, lang)),
      file.path(article_dir, filename)
    )
  }
  for (lang in c("en", "zh")) {
    tr <- function(en, zh) stata_reference_tr(lang, en, zh)
    for (page in pages) {
      title <- if (lang == "zh") page$title_zh else page$title
      write_page(
        page$slug,
        title,
        stata_reference_chapter(page, entries, preferred, lang),
        lang
      )
    }
    indexes <- stata_reference_indexes(
      entries,
      functions,
      locations,
      preferred,
      lang
    )
    write_page(
      "command-index",
      tr("Stata index", "Stata \u7d22\u5f15"),
      indexes[["command-index"]],
      lang
    )
    write_page(
      "r-index",
      tr("R function index", "R \u51fd\u6570\u7d22\u5f15"),
      indexes[["r-index"]],
      lang
    )
    contents <- c(
      paste0(
        '<div class="stata-reference-home" data-language="',
        lang,
        '" data-link-map="../stata-reference-links.json">'
      ),
      paste0(
        '<p><a href="',
        stata_reference_filename("command-index", lang),
        '">',
        tr("Stata index", "Stata \u7d22\u5f15"),
        '</a> \u00b7 <a href="',
        stata_reference_filename("r-index", lang),
        '">',
        tr("R function index", "R \u51fd\u6570\u7d22\u5f15"),
        "</a></p>"
      ),
      '<ul class="stata-subjects">',
      vapply(
        pages,
        function(page) {
          title <- if (lang == "zh") page$title_zh else page$title
          paste0(
            '<li><a href="',
            stata_reference_filename(page$slug, lang),
            '">',
            stata_reference_escape(title),
            "</a></li>"
          )
        },
        character(1)
      ),
      "</ul></div>"
    )
    writeLines(
      enc2utf8(contents),
      file.path(generated, paste0("contents-", lang, ".html")),
      useBytes = TRUE
    )
  }
  writeLines(
    jsonlite::toJSON(as.list(locations), auto_unbox = TRUE),
    file.path(assets, "stata-reference-links.json"),
    useBytes = TRUE
  )
  manifest <- list(
    pages = pages,
    locations = locations,
    examples = entries[, c(
      "id",
      "stata",
      "r",
      "task",
      "task_zh",
      "detail",
      "detail_zh",
      "source",
      "r_source"
    )]
  )
  saveRDS(manifest, file.path(generated, "manifest.rds"))
  message(
    "Generated ",
    length(pages),
    " subject pages per language; ",
    nrow(entries),
    " examples per edition."
  )
  invisible(manifest)
}

stata_reference_page_size <- function(path) {
  bytes <- file.info(path)$size
  if (bytes > 512L * 1024L) {
    stop("Reference page exceeds 512 KiB: ", basename(path))
  }
  document <- xml2::read_html(path, encoding = "UTF-8")
  elements <- length(xml2::xml_find_all(document, ".//*"))
  if (elements > 10000L) {
    stop("Reference page exceeds 10,000 elements: ", basename(path))
  }
  list(
    bytes = unname(bytes),
    elements = elements,
    gzip_bytes = length(memCompress(readBin(path, "raw", n = bytes), "gzip"))
  )
}

stata_reference_restore_spaces <- function(html, examples) {
  if (is.null(examples) || !nrow(examples)) {
    return(html)
  }
  doc <- xml2::read_html(html, encoding = "UTF-8")
  for (example in xml2::xml_find_all(doc, ".//*[@data-example-id]")) {
    id <- xml2::xml_attr(example, "data-example-id")
    before <- as.character(example, options = character())
    row <- examples[match(id, examples$id), ]
    nodes <- xml2::xml_find_all(example, ".//pre/code")
    expected <- c(row$stata, row$r)
    for (i in seq_along(nodes)) {
      actual <- sub("\n+$", "", xml2::xml_text(nodes[[i]]))
      target <- sub("\n+$", "", expected[i])
      if (identical(actual, target) || !startsWith(target, actual)) {
        next
      }
      suffix <- substring(target, nchar(actual) + 1L)
      if (!grepl("^[ \t]+$", suffix)) {
        next
      }
      # pkgdown's second highlighting pass drops terminal spaces. Restore only
      # that exact suffix, preserving the original highlighted markup and code.
      last <- tail(xml2::xml_find_all(nodes[[i]], ".//text()"), 1L)
      xml2::xml_text(last) <- paste0(
        sub("\n+$", "", xml2::xml_text(last)),
        suffix
      )
    }
    after <- as.character(example, options = character())
    if (!identical(before, after)) {
      if (!grepl(before, html, fixed = TRUE)) {
        stop("Cannot preserve code spacing: ", id)
      }
      html <- sub(before, after, html, fixed = TRUE)
    }
  }
  html
}

finalize_stata_reference <- function(
  pkg = ".",
  destination = file.path(pkg, "docs")
) {
  manifest <- readRDS(file.path(
    pkg,
    "pkgdown/stata-reference-generated/manifest.rds"
  ))
  slugs <- c(
    vapply(manifest$pages, `[[`, character(1), "slug"),
    "command-index",
    "r-index"
  )
  for (lang in c("en", "zh")) {
    for (filename in c(
      stata_reference_home(lang),
      stata_reference_filename(slugs, lang)
    )) {
      path <- file.path(destination, "articles", filename)
      html <- readLines(path, encoding = "UTF-8", warn = FALSE)
      html <- sub('<html lang="[^"]*"', paste0('<html lang="', lang, '"'), html)
      # Generated Rmd files are deliberately absent from Git. The native Source
      # link should open their tracked generator rather than a nonexistent file.
      html <- gsub(
        'vignettes/articles/stata-[^"#<>]*[.]Rmd',
        'pkgdown/build-stata-reference.R',
        html
      )
      html <- stata_reference_restore_spaces(
        paste(html, collapse = "\n"),
        manifest$examples
      )
      writeLines(enc2utf8(html), path, useBytes = TRUE)
    }
  }
  invisible(NULL)
}

check_stata_reference <- function(
  pkg = ".",
  destination = file.path(pkg, "docs")
) {
  manifest <- readRDS(file.path(
    pkg,
    "pkgdown/stata-reference-generated/manifest.rds"
  ))
  slugs <- c(
    vapply(manifest$pages, `[[`, character(1), "slug"),
    "command-index",
    "r-index"
  )
  sizes <- list()
  expected <- c(
    stata_reference_filename(slugs, "en"),
    stata_reference_filename(slugs, "zh")
  )
  stata_reference_check_stale(
    list.files(
      file.path(destination, "articles"),
      pattern = "^stata-.*[.]html$"
    ),
    expected
  )
  documents <- new.env(parent = emptyenv())
  read_page <- function(path) {
    key <- normalizePath(path, winslash = "/", mustWork = TRUE)
    if (!exists(key, envir = documents, inherits = FALSE)) {
      documents[[key]] <- xml2::read_html(path, encoding = "UTF-8")
    }
    documents[[key]]
  }
  normalize_code <- function(x) {
    sub("\n+$", "", gsub("\r\n", "\n", x, fixed = TRUE))
  }
  for (lang in c("en", "zh")) {
    filenames <- c(
      stata_reference_home(lang),
      stata_reference_filename(slugs, lang)
    )
    collected <- character()
    for (filename in filenames) {
      path <- file.path(destination, "articles", filename)
      if (!file.exists(path)) {
        stop("Missing reference page: ", filename)
      }
      sizes[[filename]] <- stata_reference_page_size(path)
      doc <- read_page(path)
      if (
        !identical(
          xml2::xml_attr(xml2::xml_find_first(doc, "//html"), "lang"),
          lang
        )
      ) {
        stop("Wrong document language: ", filename)
      }
      main <- xml2::xml_find_first(doc, "//main")
      ids <- xml2::xml_attr(xml2::xml_find_all(doc, "//*[@id]"), "id")
      if (anyDuplicated(ids)) {
        stop("Duplicate page anchors: ", filename)
      }
      examples <- xml2::xml_find_all(main, ".//*[@data-example-id]")
      collected <- c(collected, xml2::xml_attr(examples, "data-example-id"))
      for (example in examples) {
        id <- xml2::xml_attr(example, "data-example-id")
        if (
          !identical(
            filename,
            stata_reference_filename(manifest$locations[[id]], lang)
          )
        ) {
          stop("Example appears on the wrong chapter page: ", id)
        }
        row <- manifest$examples[match(id, manifest$examples$id), ]
        code <- xml2::xml_text(xml2::xml_find_all(example, ".//pre/code"))
        if (
          !identical(normalize_code(code), normalize_code(c(row$stata, row$r)))
        ) {
          stop("Changed example code: ", filename, "#example-", id)
        }
        descriptions <- c(
          if (lang == "zh") row$task_zh else row$task,
          if (lang == "zh") row$detail_zh else row$detail
        )
        # Pandoc wraps prose in HTML; browsers collapse this white space. Code
        # blocks above retain their exact comparison.
        descriptions <- stata_reference_prose(descriptions)
        text <- stata_reference_prose(xml2::xml_text(example))
        if (
          !all(vapply(
            descriptions,
            function(description) grepl(description, text, fixed = TRUE),
            logical(1)
          ))
        ) {
          stop("Missing example description: ", id)
        }
        hrefs <- xml2::xml_attr(
          xml2::xml_find_all(example, ".//a[@href]"),
          "href"
        )
        if (!all(c(row$source, row$r_source) %in% hrefs)) {
          stop("Missing example sources: ", id)
        }
      }
      # All guide navigation is relative to this pkgdown site; external sources
      # remain ordinary references rather than alternative guide destinations.
      hrefs <- xml2::xml_attr(xml2::xml_find_all(main, ".//a[@href]"), "href")
      local <- hrefs[!grepl("^([a-zA-Z][a-zA-Z0-9+.-]*:|//)", hrefs)]
      for (href in local) {
        filename_part <- sub("[?#].*$", "", href)
        target <- if (!nzchar(filename_part)) {
          path
        } else {
          file.path(dirname(path), filename_part)
        }
        if (!file.exists(target)) {
          stop("Broken reference link: ", filename, " -> ", href)
        }
        if (grepl("#", href, fixed = TRUE)) {
          anchor <- utils::URLdecode(sub("^[^#]*#", "", href))
          target_doc <- if (identical(target, path)) {
            doc
          } else {
            read_page(target)
          }
          target_ids <- xml2::xml_attr(
            xml2::xml_find_all(target_doc, "//*[@id]"),
            "id"
          )
          if (nzchar(anchor) && !anchor %in% target_ids) {
            stop("Broken reference anchor: ", href)
          }
        }
      }
      if (filename != stata_reference_home(lang)) {
        other <- if (lang == "en") "zh" else "en"
        slug <- slugs[match(filename, stata_reference_filename(slugs, lang))]
        toggle <- xml2::xml_find_first(
          main,
          './/a[@id="stata-language-toggle"]'
        )
        if (
          !identical(
            xml2::xml_attr(toggle, "href"),
            stata_reference_filename(slug, other)
          )
        ) {
          stop("Wrong language target: ", filename)
        }
      }
    }
    if (
      anyDuplicated(collected) || !setequal(collected, manifest$examples$id)
    ) {
      stop("Missing or duplicated examples in ", lang, " reference.")
    }
  }
  shared <- file.path(
    destination,
    c("extra.css", "extra.js", "stata-reference-links.json", "search.json")
  )
  if (!all(file.exists(shared))) {
    stop("Missing shared reference/search assets.")
  }
  links <- unlist(jsonlite::fromJSON(file.path(
    destination,
    "stata-reference-links.json"
  )))
  if (
    !identical(
      links[sort(names(links))],
      manifest$locations[sort(names(manifest$locations))]
    )
  ) {
    stop("Old example links do not match the current chapter map.")
  }
  # Native pkgdown also emits Markdown companions for LLM/documentation tools.
  # Count those downloads as well as HTML, the entire search index and assets.
  companions <- file.path(
    destination,
    "articles",
    sub("[.]html$", ".md", names(sizes))
  )
  companions <- companions[file.exists(companions)]
  stata_reference_check_stale(
    list.files(file.path(destination, "articles"), pattern = "^stata-.*[.]md$"),
    sub("[.]html$", ".md", expected)
  )
  total <- sum(vapply(sizes, `[[`, numeric(1), "bytes")) +
    sum(file.info(shared)$size) +
    sum(file.info(companions)$size)
  if (total > 20 * 1024^2) {
    stop("Bilingual reference exceeds 20 MiB including shared assets/search.")
  }
  search <- jsonlite::fromJSON(file.path(destination, "search.json"))
  search_paths <- basename(unlist(search$path, use.names = FALSE))
  if (
    !all(stata_reference_filename(slugs, "en") %in% search_paths) ||
      !all(stata_reference_filename(slugs, "zh") %in% search_paths)
  ) {
    stop("Reference chapters are missing from pkgdown search.")
  }
  report <- list(
    examples_per_language = nrow(manifest$examples),
    subject_pages_per_language = length(manifest$pages),
    total_bytes = total,
    markdown_bytes = sum(file.info(companions)$size),
    pages = sizes
  )
  writeLines(
    jsonlite::toJSON(report, auto_unbox = TRUE, pretty = TRUE),
    file.path(pkg, "pkgdown/stata-reference-generated/audit.json"),
    useBytes = TRUE
  )
  message(
    "Reference audit passes: ",
    nrow(manifest$examples),
    " exact examples per language; ",
    round(total / 1024^2, 2),
    " MiB including search and custom assets."
  )
  invisible(report)
}
