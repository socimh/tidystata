# Reference metadata stays internal; findit() retains its five public columns.
findit_gaps <- function() {
  if (is.null(findit_cache$gaps)) {
    findit_cache$gaps <- findit_read("findit-gaps.csv")
  }
  findit_cache$gaps
}

findit_keyword <- function(query, entries) {
  text <- tolower(trimws(query))
  haystack <- tolower(paste(
    entries$stata,
    entries$r,
    entries$task,
    entries$task_zh,
    sep = "\r"
  ))
  if (grepl("^[a-z][a-z0-9_]*$", text)) {
    prefix <- nchar(text) >= 3L & startsWith(entries$command, text)
    prefix |
      grepl(
        paste0("(?<![a-z0-9_])", text, "(?![a-z0-9_])"),
        haystack,
        perl = TRUE
      )
  } else {
    grepl(text, haystack, fixed = TRUE)
  }
}

findit_namespace_hit <- function(namespace, name, entries) {
  code <- gsub('"(?:[^"\\\\]|\\\\.)*"', '""', entries$r, perl = TRUE)
  pattern <- paste0(
    "(?<![A-Za-z0-9_.:])(?:[A-Za-z][A-Za-z0-9.]*::)?",
    "[A-Za-z_.][A-Za-z0-9_.]*(?=[(])"
  )
  calls <- regmatches(code, gregexpr(pattern, code, perl = TRUE))
  dictionary <- findit_functions()
  owned <- intersect(
    name,
    dictionary$`function`[dictionary$package == namespace]
  )
  ambiguous <- owned[vapply(
    owned,
    function(fn) {
      length(unique(dictionary$package[dictionary$`function` == fn])) > 1L
    },
    logical(1)
  )]
  vapply(
    seq_along(calls),
    function(i) {
      unqualified <- setdiff(
        owned,
        if (entries$package[i] != namespace) ambiguous
      )
      any(paste0(namespace, "::", name) %in% calls[[i]]) ||
        any(unqualified %in% calls[[i]])
    },
    logical(1)
  )
}

findit_metadata <- function(x) {
  reference <- attr(x, "reference")
  key <- function(stata, r) paste(stata, r, sep = "\r")
  rows <- match(key(x$stata, x$r), key(reference$stata, reference$r))
  ids <- attr(x, "entry_ids")
  if (length(ids) == nrow(x)) {
    identified <- match(ids, reference$id)
    same <- !is.na(identified) &
      key(x$stata, x$r) ==
        key(reference$stata[identified], reference$r[identified])
    rows[which(same)] <- identified[which(same)]
  }
  result <- reference[rows, , drop = FALSE]
  for (name in names(result)) {
    result[[name]][is.na(result[[name]])] <- ""
  }
  result
}

#' @export
`[.tidystata_findit` <- function(x, i, j, drop = FALSE, ...) {
  column_subset <- (nargs() - as.integer(!missing(drop))) < 3L
  rows <- if (column_subset || missing(i)) {
    seq_len(nrow(x))
  } else {
    seq_len(nrow(x))[i]
  }
  out <- NextMethod("[")
  if (!inherits(out, "tidystata_findit")) {
    return(out)
  }
  if (!all(c("match", "stata", "r", "package", "task") %in% names(out))) {
    class(out) <- setdiff(class(out), "tidystata_findit")
    return(out)
  }
  attr(out, "entry_ids") <- attr(x, "entry_ids")[rows]
  attr(out, "reference") <- findit_metadata(x)[rows, , drop = FALSE]
  customized <- attr(x, "customized")
  if (!is.null(customized)) {
    attr(out, "customized") <- customized[rows]
  }
  for (name in c("default_rows", "query_rows")) {
    selected <- match(attr(x, name), rows)
    selected <- selected[!is.na(selected)]
    if (!length(selected) && nrow(out)) {
      selected <- 1L
    }
    attr(out, name) <- selected
  }
  attr(out, "show") <- length(attr(out, "default_rows"))
  out
}

#' @exportS3Method dplyr::dplyr_row_slice
dplyr_row_slice.tidystata_findit <- function(data, i, ...) {
  data[i, , drop = FALSE]
}

# Only option names are compared. This deliberately does not parse Stata code
# or claim to understand the contents of option arguments or macros.
findit_options <- function(query) {
  query <- sub("^by(s|so|sor|sort)? [^:]*: *", "", query, ignore.case = TRUE)
  text <- gsub('"(?:[^"\\\\]|\\\\.)*"', "", query, perl = TRUE)
  repeat {
    next_text <- gsub("\\([^()]*\\)", "", text)
    if (identical(next_text, text)) {
      break
    }
    text <- next_text
  }
  if (!grepl(",", text, fixed = TRUE)) {
    return(character())
  }
  text <- sub("^[^,]*,", "", text)
  text <- sub(":.*$", "", text)
  words <- tolower(strsplit(trimws(text), "[ ,]+")[[1L]])
  unique(words[grepl("^[a-z][a-z0-9_]*$", words)])
}

findit_reference_counts <- function() {
  entries <- findit_entries()
  list(
    commands = length(unique(entries$command[entries$kind == "command"])),
    functions = length(unique(entries$command[entries$kind == "function"])),
    operators = length(unique(entries$command[entries$kind == "operator"])),
    prefixes = length(unique(entries$command[entries$kind == "prefix"])),
    stata_examples = length(unique(entries$stata)),
    examples = nrow(entries),
    verified = sum(entries$validation == "executed"),
    r_functions = nrow(findit_functions())
  )
}

# ASCII HTML entities preserve code and Chinese text in non-UTF-8 render locales.
findit_html_escape <- function(x) {
  vapply(
    x,
    function(text) {
      codes <- utf8ToInt(text)
      encode <- codes %in% c(33:47, 58:64, 91:96, 123:126) | codes > 127L
      chars <- vapply(codes, intToUtf8, character(1))
      chars[encode] <- paste0("&#", codes[encode], ";")
      paste(chars, collapse = "")
    },
    character(1),
    USE.NAMES = FALSE
  )
}

findit_reference_html <- function(chinese = FALSE) {
  entries <- findit_entries()
  templates <- findit_templates()
  priority <- vapply(templates, function(x) x$priority, integer(1))
  sections <- unique(entries$section)
  entries <- entries[
    order(
      match(entries$section, sections),
      entries$command,
      priority[match(entries$id, names(templates))],
      entries$stata,
      entries$approach
    ),
  ]
  tr <- function(en, zh) findit_html_escape(if (chinese) zh else en)
  escape <- findit_html_escape
  heading <- function(en, zh, level = 2L) {
    paste0("<h", level, ">", tr(en, zh), "</h", level, ">")
  }
  commands <- sort(unique(entries$command))
  ids <- entries$id[match(commands, entries$command)]
  html <- c(
    heading(
      "Alphabetical command index",
      "\u547d\u4ee4\u5b57\u6bcd\u7d22\u5f15"
    ),
    "<p>",
    paste0(
      '<a href="#example-',
      ids,
      '">',
      escape(commands),
      "</a>",
      collapse = " &#183; "
    ),
    "</p>"
  )
  for (section in sections) {
    rows <- entries[entries$section == section, ]
    name <- if (chinese) rows$section_zh[1L] else section
    html <- c(html, paste0("<h2>", escape(name), "</h2>"))
    task <- if (chinese) rows$task_zh else rows$task
    detail <- if (chinese) rows$detail_zh else rows$detail
    # Only qualified examples are flagged, matching the reference book.
    caveat <- ifelse(
      rows$equivalence == "qualified",
      paste0(
        "<strong>",
        tr("Differs from Stata:", "\u4e0e Stata \u6709\u5dee\u5f02\uff1a"),
        "</strong> "
      ),
      ""
    )
    notes <- paste0(
      escape(task),
      ifelse(nzchar(detail), paste0("<br>", caveat, escape(detail)), ""),
      "<br>",
      '<a href="',
      rows$source,
      '">',
      tr("Stata reference", "Stata \u53c2\u8003"),
      '</a> &#183; <a href="',
      rows$r_source,
      '">',
      tr("R reference", "R \u53c2\u8003"),
      "</a>"
    )
    html <- c(
      html,
      '<table class="table"><thead><tr><th>Stata</th><th>R</th><th>',
      tr(
        "Purpose, qualifications and sources",
        "\u7528\u9014\u3001\u5dee\u5f02\u53ca\u6765\u6e90"
      ),
      "</th></tr></thead><tbody>",
      paste0(
        '<tr id="example-',
        rows$id,
        '"><td><pre><code>',
        escape(rows$stata),
        "</code></pre></td><td><pre><code>",
        escape(rows$r),
        "</code></pre><small>",
        escape(rows$package),
        "</small></td><td>",
        notes,
        "</td></tr>"
      ),
      "</tbody></table>"
    )
  }
  functions <- findit_functions()
  functions <- functions[order(functions$package, functions$`function`), ]
  description <- if (chinese) {
    functions$description_zh
  } else {
    functions$description
  }
  c(
    html,
    heading(
      "R functions by package",
      "\u6309\u5305\u67e5\u9605 R \u51fd\u6570"
    ),
    '<table class="table"><thead><tr><th>R</th><th>',
    tr("Package", "\u5305"),
    "</th><th>Stata</th><th>",
    tr("Description", "\u8bf4\u660e"),
    "</th></tr></thead><tbody>",
    paste0(
      "<tr><td><code>",
      escape(functions$`function`),
      "()</code></td><td>",
      escape(functions$package),
      "</td><td>",
      escape(functions$stata),
      "</td><td>",
      escape(description),
      "</td></tr>"
    ),
    "</tbody></table>"
  )
}
