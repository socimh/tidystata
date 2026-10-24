# Catalogue annotations, keyed by the unchanged Stata example.
# Variables follow Stata operand order. Only recorded variable locations are
# editable; quoted R column names and variable lists are declared separately.
findit_templates <- function() {
  if (is.null(findit_cache$templates)) {
    entries <- findit_entries()
    specs <- findit_template_specs()
    if (!identical(names(specs), entries$stata)) {
      cli::cli_abort(
        "The findit template annotations do not match the catalogue."
      )
    }
    findit_cache$templates <- lapply(seq_len(nrow(entries)), function(i) {
      spec <- specs[[i]]
      spec$stata <- entries$stata[i]
      spec$r <- entries$r[i]
      spec$default <- spec$priority == 0L
      spec$sites <- list(
        stata = findit_template_sites(spec$stata, spec, "stata"),
        r = findit_template_sites(spec$r, spec, "r")
      )
      if (
        !is.null(spec$varlist) &&
          !all(vapply(
            spec$sites,
            function(sites) {
              any(vapply(sites, function(s) s$kind == "list", logical(1)))
            },
            logical(1)
          ))
      ) {
        cli::cli_abort(
          "A variable-list site is missing from {.code {spec$stata}}."
        )
      }
      spec
    })
    names(findit_cache$templates) <- entries$stata
  }
  findit_cache$templates
}

# Selection is separate from returned rows: expansion never loses a match.
findit_defaults <- function(entries, described = character()) {
  if (!nrow(entries)) {
    return(integer())
  }
  relevance <- attr(entries, "relevance")
  if (length(relevance)) {
    candidates <- which(relevance == max(relevance))
  } else {
    candidates <- attr(entries, "leaders")
    if (is.null(candidates)) candidates <- seq_len(nrow(entries))
  }
  templates <- findit_templates()[match(
    entries$stata,
    names(findit_templates())
  )]
  priority <- vapply(templates, function(x) x$priority, integer(1))
  meaning <- vapply(templates, function(x) x$meaning, character(1))
  if (any(entries$match[candidates] == "stata")) {
    stata <- candidates[entries$match[candidates] == "stata"]
    primary <- stata[priority[stata] == min(priority[stata])]
    functions <- unlist(findit_calls(entries$r[primary]))
    r <- candidates[entries$match[candidates] == "r"]
    # A distinct R meaning such as log() is not an optional Stata variation.
    distinct <- length(described) && !any(described %in% functions)
    candidates <- c(primary, if (distinct) r)
  } else {
    preferred <- vapply(
      templates,
      function(t) any(described %in% t$r_default),
      logical(1)
    )
    if (any(preferred[candidates])) {
      candidates <- candidates[preferred[candidates]]
    }
    candidates <- candidates[priority[candidates] == min(priority[candidates])]
  }
  candidates <- candidates[!duplicated(meaning[candidates])]
  utils::head(candidates, 5L)
}

findit_check_arguments <- function(command, extra, call = rlang::caller_env()) {
  if (!length(extra)) {
    return(invisible(NULL))
  }
  if (is.null(command)) {
    cli::cli_abort(
      "A {.arg command} is required when additional arguments are supplied.",
      call = call
    )
  }
  if (any(nzchar(names(extra)))) {
    cli::cli_abort("Additional arguments must be unnamed.", call = call)
  }
  for (arg in extra) {
    if (rlang::is_missing(arg)) {
      cli::cli_abort("Additional arguments must not be missing.", call = call)
    }
    if (
      !rlang::is_symbol(arg) &&
        !(rlang::is_string(arg) && nzchar(trimws(arg)))
    ) {
      cli::cli_abort(
        "Each additional argument must be a bare name or a non-empty string.",
        call = call
      )
    }
  }
  invisible(NULL)
}

findit_customize <- function(x, arguments) {
  described <- attr(x, "r_functions")$`function`
  demonstrated <- unlist(findit_calls(x$r[x$match == "stata"]))
  attr(x, "resolved_functions") <- intersect(described, demonstrated)
  templates <- findit_templates()[match(x$stata, names(findit_templates()))]
  known <- unique(unlist(lapply(templates, function(t) t$hints)))
  hints <- list()
  variables <- character()
  for (arg in arguments) {
    word <- if (rlang::is_symbol(arg)) rlang::as_string(arg) else arg
    hits <- character()
    if (rlang::is_symbol(arg)) {
      hits <- known[tolower(known) == tolower(word)]
      if (!length(hits) && nchar(word) >= 3L) {
        hits <- known[startsWith(tolower(known), tolower(word))]
      }
    }
    if (length(hits)) {
      hints[[length(hints) + 1L]] <- hits
    } else {
      variables <- c(variables, word)
    }
  }
  score <- vapply(
    templates,
    function(t) {
      sum(vapply(hints, function(h) any(h %in% t$hints), logical(1)))
    },
    integer(1)
  )
  fits <- vapply(
    templates,
    findit_template_fits,
    logical(1),
    n = length(variables)
  )
  pool <- attr(x, "query_rows")
  if (is.null(pool)) {
    pool <- seq_len(nrow(x))
  }
  if (length(variables)) {
    customized <- rep(FALSE, nrow(x))
    for (i in which(fits)) {
      rendered <- findit_render(templates[[i]], variables)
      x$stata[i] <- rendered$stata
      x$r[i] <- rendered$r
      customized[i] <- TRUE
    }
    attr(x, "customized") <- customized
  }
  if (nrow(x) && (length(hints) || any(fits))) {
    candidates <- pool[score[pool] == max(score[pool])]
    if (length(variables) && any(fits[candidates])) {
      candidates <- candidates[fits[candidates]]
    }
    priority <- vapply(templates, function(t) t$priority, integer(1))
    meaning <- vapply(templates, function(t) t$meaning, character(1))
    interpretations <- rep("", length(candidates))
    if (any(lengths(hints) > 1L) || max(score[pool]) < length(hints)) {
      interpretations <- vapply(
        candidates,
        function(i) {
          paste(
            vapply(
              hints,
              function(h) {
                paste(intersect(h, templates[[i]]$hints), collapse = ",")
              },
              character(1)
            ),
            collapse = ";"
          )
        },
        character(1)
      )
    }
    selected <- unlist(
      lapply(unique(interpretations), function(key) {
        group <- candidates[interpretations == key]
        if (any(x$match[group] == "stata")) {
          group <- group[x$match[group] == "stata"]
        } else {
          described <- attr(x, "r_functions")$`function`
          preferred <- vapply(
            templates[group],
            function(t) any(described %in% t$r_default),
            logical(1)
          )
          if (any(preferred)) group <- group[preferred]
        }
        group <- group[priority[group] == min(priority[group])]
        group[!duplicated(meaning[group])]
      }),
      use.names = FALSE
    )
    selected <- utils::head(selected, 5L)
    order <- c(selected, setdiff(seq_len(nrow(x)), selected))
    customized <- attr(x, "customized")
    x <- x[order, ]
    if (!is.null(customized)) {
      attr(x, "customized") <- customized[order]
    }
    attr(x, "default_rows") <- seq_along(selected)
    attr(x, "show") <- length(selected)
  }
  attr(x, "unmatched_hints") <- length(hints) > 0L &&
    (!length(score) || max(score[pool]) < length(hints))
  x
}

findit_template_fits <- function(template, n) {
  count <- length(template$variables)
  if (is.null(template$varlist)) {
    n == count
  } else {
    n >= count - length(template$varlist$names) + 1L
  }
}

# Every editable token records its original source location. Replacing from
# right to left makes swaps safe and never reprocesses a supplied name as code.
findit_template_sites <- function(code, template, language) {
  sites <- list()
  add <- function(start, end, slot = 0L, kind = "name", text = "") {
    sites[[length(sites) + 1L]] <<- list(
      start = start,
      end = end,
      slot = slot,
      kind = kind,
      text = text
    )
  }
  if (language == "stata") {
    matches <- gregexpr(
      '"(?:[^"\\\\]|\\\\.)*"|[A-Za-z_][A-Za-z0-9_]*',
      code,
      perl = TRUE
    )[[1]]
    if (matches[1] != -1L) {
      ends <- matches + attr(matches, "match.length") - 1L
      for (j in seq_along(matches)) {
        token <- substr(code, matches[j], ends[j])
        slot <- match(token, template$variables)
        if (!is.na(slot)) {
          add(matches[j], ends[j], slot)
        }
        if (token %in% names(template$derived)) {
          source <- template$derived[[token]]
          add(
            matches[j],
            ends[j],
            match(source, template$variables),
            "derived",
            substring(token, nchar(source) + 1L)
          )
        }
      }
    }
  } else {
    tokens <- utils::getParseData(parse(text = code, keep.source = TRUE))
    tokens <- tokens[tokens$terminal, ]
    symbols <- tokens$token %in% c("SYMBOL", "SYMBOL_SUB", "SYMBOL_FORMALS")
    for (j in which(symbols)) {
      token <- tokens$text[j]
      if (token %in% names(template$aliases)) {
        token <- template$aliases[[token]]
      }
      slot <- match(token, template$variables)
      if (!is.na(slot)) {
        add(tokens$col1[j], tokens$col2[j], slot)
      }
      if (tokens$text[j] %in% names(template$derived)) {
        token <- tokens$text[j]
        source <- template$derived[[token]]
        add(
          tokens$col1[j],
          tokens$col2[j],
          match(source, template$variables),
          "derived",
          substring(token, nchar(source) + 1L)
        )
      }
    }
    for (j in which(tokens$token == "STR_CONST")) {
      value <- parse(text = tokens$text[j])[[1L]]
      if (value %in% c(template$strings, template$expressions)) {
        kind <- if (value %in% template$expressions) "expression" else "text"
        add(tokens$col1[j], tokens$col2[j], kind = kind, text = value)
      }
    }
  }
  # A new output can share its original spelling with an input, as in mdy().
  for (token in names(template$output_aliases)) {
    matching <- which(vapply(
      sites,
      function(s) {
        substr(code, s$start, s$end) == token
      },
      logical(1)
    ))
    if (length(matching)) {
      first <- matching[which.min(vapply(
        sites[matching],
        function(s) s$start,
        integer(1)
      ))]
      sites[[first]]$slot <- match(
        template$output_aliases[[token]],
        template$variables
      )
    }
  }
  protected <- if (language == "r") template$protect else character()
  for (text in protected) {
    spans <- findit_occurrences(code, text)
    sites <- Filter(
      function(site) !any(site$start >= spans$start & site$end <= spans$end),
      sites
    )
  }
  if (!is.null(template$varlist)) {
    text <- template$varlist[[language]]
    spans <- findit_occurrences(code, text, boundary = TRUE)
    for (j in seq_len(nrow(spans))) {
      start <- spans$start[j]
      end <- spans$end[j]
      # A scalar name inside a string is not a variable-list site.
      if (
        language == "r" &&
          template$varlist$style != "strings" &&
          any(
            tokens$token == "STR_CONST" &
              tokens$col1 <= start &
              tokens$col2 >= end
          )
      ) {
        next
      }
      sites <- Filter(function(s) !(s$start >= start && s$end <= end), sites)
      add(start, end, kind = "list")
    }
  }
  sites
}

findit_occurrences <- function(code, text, boundary = FALSE) {
  start <- gregexpr(text, code, fixed = TRUE)[[1]]
  if (start[1] == -1L) {
    return(data.frame(start = integer(), end = integer()))
  }
  end <- start + attr(start, "match.length") - 1L
  if (boundary) {
    before <- ifelse(
      start > 1L,
      substring(code, pmax(1L, start - 1L), pmax(1L, start - 1L)),
      ""
    )
    after <- substring(code, end + 1L, end + 1L)
    keep <- !grepl("[A-Za-z0-9_.]", before) & !grepl("[A-Za-z0-9_.]", after)
    start <- start[keep]
    end <- end[keep]
  }
  data.frame(start = as.integer(start), end = as.integer(end))
}

findit_render <- function(template, variables) {
  if (!findit_template_fits(template, length(variables))) {
    return(list(stata = template$stata, r = template$r))
  }
  values <- as.list(variables)
  many <- character()
  if (!is.null(template$varlist)) {
    positions <- match(template$varlist$names, template$variables)
    first <- min(positions)
    last <- max(positions)
    count <- length(variables) - length(template$variables) + length(positions)
    many <- variables[seq.int(first, length.out = count)]
    values <- vector("list", length(template$variables))
    before <- seq_len(first - 1L)
    after <- seq.int(last + 1L, length.out = length(values) - last)
    values[before] <- as.list(variables[before])
    values[positions] <- rep(list(many), length(positions))
    values[after] <- as.list(utils::tail(variables, length(after)))
  }
  names(values) <- template$variables
  result <- lapply(c("stata", "r"), function(language) {
    code <- template[[language]]
    sites <- template$sites[[language]]
    sites <- sites[order(
      vapply(sites, function(s) s$start, integer(1)),
      decreasing = TRUE
    )]
    for (site in sites) {
      replacement <- if (site$kind == "list") {
        findit_render_list(many, template$varlist$style, language)
      } else if (site$kind %in% c("text", "expression")) {
        text <- findit_render_text(site$text, values, site$kind)
        encodeString(text, quote = '"')
      } else if (site$kind == "derived") {
        findit_render_name(paste0(values[[site$slot]][1L], site$text))
      } else {
        findit_render_name(values[[site$slot]][1L])
      }
      code <- paste0(
        substr(code, 1L, site$start - 1L),
        replacement,
        substring(code, site$end + 1L)
      )
    }
    code
  })
  stats::setNames(result, c("stata", "r"))
}

findit_render_name <- function(name) {
  paste(deparse(as.name(name), backtick = TRUE), collapse = "")
}

findit_render_list <- function(variables, style, language) {
  if (language == "stata") {
    return(paste(
      vapply(variables, findit_render_name, character(1)),
      collapse = " "
    ))
  }
  if (style == "strings") {
    names <- encodeString(variables, quote = '"')
    if (length(names) == 1L) {
      names
    } else {
      paste0("c(", paste(names, collapse = ", "), ")")
    }
  } else {
    if (style == "reverse_args") {
      variables <- rev(variables)
    }
    names <- vapply(variables, findit_render_name, character(1))
    if (style == "formula") {
      return(paste(names, collapse = " + "))
    }
    joined <- paste(names, collapse = ", ")
    if (style == "exclude") {
      return(
        if (length(names) == 1L) {
          paste0("-", joined)
        } else {
          paste0("-c(", joined, ")")
        }
      )
    }
    if (style == "select" && length(names) > 1L) {
      paste0("c(", joined, ")")
    } else {
      joined
    }
  }
}

findit_render_text <- function(text, values, kind) {
  spec <- list(variables = names(values))
  sites <- findit_template_sites(
    text,
    spec,
    if (kind == "expression") "r" else "stata"
  )
  sites <- sites[order(
    vapply(sites, function(s) s$start, integer(1)),
    decreasing = TRUE
  )]
  for (site in sites) {
    name <- values[[site$slot]][1L]
    if (kind == "expression") {
      name <- findit_render_name(name)
    }
    text <- paste0(
      substr(text, 1L, site$start - 1L),
      name,
      substring(text, site$end + 1L)
    )
  }
  text
}

findit_template_specs <- function() {
  list(
    "findit command" = list(
      variables = c("command"),
      meaning = "findit",
      priority = 0L,
      hints = c("findit")
    ),
    "help command" = list(
      variables = c("command"),
      aliases = c(function_name = "command"),
      meaning = "help",
      priority = 0L,
      hints = c("help")
    ),
    "search keyword" = list(
      variables = c("keyword"),
      meaning = "search",
      priority = 0L,
      hints = c("search"),
      strings = c("keyword")
    ),
    "clear" = list(
      variables = character(),
      meaning = "clear",
      priority = 0L,
      hints = c("clear")
    ),
    "pwd" = list(
      variables = character(),
      meaning = "pwd",
      priority = 0L,
      hints = c("pwd")
    ),
    "cd \"path/to/folder\"" = list(
      variables = character(),
      meaning = "cd",
      priority = 0L,
      hints = c("cd")
    ),
    "dir" = list(
      variables = character(),
      meaning = "dir",
      priority = 0L,
      hints = c("dir")
    ),
    "global path \"path/to/folder\"" = list(
      variables = c("path"),
      meaning = "global",
      priority = 0L,
      hints = c("global")
    ),
    "display 2 + 2" = list(
      variables = character(),
      meaning = "display:0",
      priority = 0L,
      hints = c("display")
    ),
    "ssc install package" = list(
      variables = character(),
      meaning = "ssc",
      priority = 0L,
      hints = c("ssc")
    ),
    "net install package, from(url)" = list(
      variables = character(),
      meaning = "net",
      priority = 0L,
      hints = c("from", "net")
    ),
    "do analysis.do" = list(
      variables = character(),
      meaning = "do",
      priority = 0L,
      hints = c("do")
    ),
    "log using results.log" = list(
      variables = character(),
      meaning = "log",
      priority = 0L,
      hints = c("log")
    ),
    "sysuse auto" = list(
      variables = character(),
      meaning = "sysuse",
      priority = 0L,
      hints = c("sysuse")
    ),
    "use data.dta" = list(
      variables = character(),
      meaning = "use",
      priority = 0L,
      hints = c("use")
    ),
    "save data.dta, replace" = list(
      variables = character(),
      meaning = "save",
      priority = 0L,
      hints = c("replace", "save")
    ),
    "import delimited data.csv" = list(
      variables = character(),
      meaning = "import:0",
      priority = 0L,
      hints = c("delimited", "import")
    ),
    "import excel data.xlsx, firstrow" = list(
      variables = character(),
      meaning = "import:1",
      priority = 0L,
      hints = c("excel", "firstrow", "import")
    ),
    "import spss data.sav" = list(
      variables = character(),
      meaning = "import:2",
      priority = 0L,
      hints = c("import", "spss")
    ),
    "export delimited data.csv" = list(
      variables = character(),
      meaning = "export",
      priority = 0L,
      hints = c("delimited", "export")
    ),
    "export excel data.xlsx" = list(
      variables = character(),
      meaning = "export",
      priority = 0L,
      hints = c("excel", "export")
    ),
    "webuse nlswork" = list(
      variables = character(),
      meaning = "webuse",
      priority = 0L,
      hints = c("webuse")
    ),
    "import sas data.sas7bdat" = list(
      variables = character(),
      meaning = "import:3",
      priority = 0L,
      hints = c("import", "sas")
    ),
    "saveold data.dta, version(13)" = list(
      variables = character(),
      meaning = "saveold",
      priority = 0L,
      hints = c("saveold", "version")
    ),
    "browse" = list(
      variables = character(),
      meaning = "browse",
      priority = 0L,
      hints = c("browse")
    ),
    "browse x1 x3-x5" = list(
      variables = c("x1", "x3", "x5"),
      meaning = "browse",
      priority = 1L,
      hints = c("browse"),
      varlist = list(
        names = c("x1", "x3", "x5"),
        stata = "x1 x3-x5",
        r = "x1, x3:x5",
        style = "args"
      )
    ),
    "browse x* y*" = list(
      variables = c("x", "y"),
      meaning = "browse",
      priority = 2L,
      hints = c("browse"),
      strings = c("x* y*")
    ),
    "browse x*" = list(
      variables = c("x"),
      meaning = "browse",
      priority = 2L,
      hints = c("browse"),
      strings = c("x")
    ),
    "browse *x" = list(
      variables = c("x"),
      meaning = "browse",
      priority = 2L,
      hints = c("browse"),
      strings = c("x")
    ),
    "browse *x*" = list(
      variables = c("x"),
      meaning = "browse",
      priority = 2L,
      hints = c("browse"),
      strings = c("x")
    ),
    "browse in 1/10" = list(
      variables = character(),
      meaning = "browse",
      priority = 2L,
      hints = c("browse", "in")
    ),
    "browse in 7/12" = list(
      variables = character(),
      meaning = "browse",
      priority = 2L,
      hints = c("browse", "in")
    ),
    "browse in -10/-1" = list(
      variables = character(),
      meaning = "browse",
      priority = 2L,
      hints = c("browse", "in")
    ),
    "browse if x1 == 1 & x2 == 2" = list(
      variables = c("x1", "x2"),
      meaning = "browse",
      priority = 2L,
      hints = c("browse", "if")
    ),
    "list" = list(
      variables = character(),
      meaning = "list",
      priority = 0L,
      hints = c("list")
    ),
    "list x" = list(
      variables = c("x"),
      meaning = "list",
      priority = 1L,
      hints = c("list")
    ),
    "describe" = list(
      variables = character(),
      meaning = "describe",
      priority = 0L,
      hints = c("describe")
    ),
    "ds" = list(
      variables = character(),
      meaning = "ds",
      priority = 0L,
      hints = c("ds")
    ),
    "codebook" = list(
      variables = character(),
      meaning = "codebook",
      priority = 0L,
      hints = c("codebook")
    ),
    "lookfor income" = list(
      variables = c("income"),
      meaning = "lookfor",
      priority = 0L,
      hints = c("lookfor"),
      strings = c("income")
    ),
    "tabulate x" = list(
      variables = c("x"),
      meaning = "tabulate",
      priority = 0L,
      hints = c("tabulate")
    ),
    "fre x" = list(
      variables = c("x"),
      meaning = "fre",
      priority = 0L,
      hints = c("fre"),
      varlist = list(names = c("x"), stata = "x", r = "x", style = "args")
    ),
    "tabulate x1 x2" = list(
      variables = c("x1", "x2"),
      meaning = "tabulate",
      priority = 1L,
      hints = c("tabulate")
    ),
    "tabulate x [fweight = n]" = list(
      variables = c("x", "n"),
      meaning = "tabulate",
      priority = 2L,
      hints = c("fweight", "tabulate")
    ),
    "tabulate x [aweight = w]" = list(
      variables = c("x", "w"),
      meaning = "tabulate",
      priority = 2L,
      hints = c("aweight", "tabulate")
    ),
    "tab1 x1 x2 x3" = list(
      variables = c("x1", "x2", "x3"),
      meaning = "tab1",
      priority = 0L,
      hints = c("tab1"),
      varlist = list(
        names = c("x1", "x2", "x3"),
        stata = "x1 x2 x3",
        r = "x1, x2, x3",
        style = "args"
      )
    ),
    "tab2 x1 x2" = list(
      variables = c("x1", "x2"),
      meaning = "tab2",
      priority = 0L,
      hints = c("tab2")
    ),
    "table x1 x2 x3" = list(
      variables = c("x1", "x2", "x3"),
      meaning = "table",
      priority = 0L,
      hints = c("table"),
      varlist = list(
        names = c("x1", "x2", "x3"),
        stata = "x1 x2 x3",
        r = "x1, x2, x3",
        style = "args"
      )
    ),
    "summarize" = list(
      variables = character(),
      meaning = "summarize",
      priority = 0L,
      hints = c("summarize")
    ),
    "summarize x" = list(
      variables = c("x"),
      meaning = "summarize",
      priority = 1L,
      hints = c("summarize"),
      varlist = list(names = c("x"), stata = "x", r = "x", style = "args")
    ),
    "summarize x, detail" = list(
      variables = c("x"),
      meaning = "summarize",
      priority = 2L,
      hints = c("detail", "summarize"),
      varlist = list(names = c("x"), stata = "x", r = "x", style = "args")
    ),
    "bysort group: summarize x" = list(
      variables = c("group", "x"),
      meaning = "summarize",
      priority = 2L,
      hints = c("by", "summarize"),
      varlist = list(names = c("x"), stata = "x", r = "x", style = "args")
    ),
    "summarize x [aweight = w]" = list(
      variables = c("x", "w"),
      meaning = "summarize",
      priority = 2L,
      hints = c("aweight", "summarize"),
      varlist = list(names = c("x"), stata = "x", r = "x", style = "args")
    ),
    "tabstat x1 x2, by(group) stat(mean sd)" = list(
      variables = c("x1", "x2", "group"),
      meaning = "tabstat",
      priority = 0L,
      hints = c("by", "stat", "tabstat"),
      varlist = list(
        names = c("x1", "x2"),
        stata = "x1 x2",
        r = "x1, x2",
        style = "args"
      )
    ),
    "correlate x1 x2 x3" = list(
      variables = c("x1", "x2", "x3"),
      meaning = "correlate",
      priority = 0L,
      hints = c("correlate"),
      varlist = list(
        names = c("x1", "x2", "x3"),
        stata = "x1 x2 x3",
        r = "x1, x2, x3",
        style = "args"
      )
    ),
    "pwcorr x1 x2 x3" = list(
      variables = c("x1", "x2", "x3"),
      meaning = "pwcorr",
      priority = 0L,
      hints = c("pwcorr"),
      varlist = list(
        names = c("x1", "x2", "x3"),
        stata = "x1 x2 x3",
        r = "x1, x2, x3",
        style = "args"
      )
    ),
    "ttest x, by(group)" = list(
      variables = c("x", "group"),
      meaning = "ttest",
      priority = 0L,
      hints = c("by", "ttest")
    ),
    "tabulate x1 x2, chi2" = list(
      variables = c("x1", "x2"),
      meaning = "tabulate",
      priority = 2L,
      hints = c("chi2", "tabulate")
    ),
    "inspect x" = list(
      variables = character(),
      meaning = "inspect",
      priority = 0L,
      hints = c("inspect")
    ),
    "levelsof x" = list(
      variables = c("x"),
      meaning = "levelsof",
      priority = 0L,
      hints = c("levelsof")
    ),
    "codebook, compact" = list(
      variables = character(),
      meaning = "codebook",
      priority = 2L,
      hints = c("codebook", "compact")
    ),
    "describe using data.dta" = list(
      variables = character(),
      meaning = "describe",
      priority = 2L,
      hints = c("describe")
    ),
    "tabulate x, missing" = list(
      variables = c("x"),
      meaning = "tabulate",
      priority = 2L,
      hints = c("missing", "tabulate")
    ),
    "tabulate x, summarize(y)" = list(
      variables = c("x", "y"),
      meaning = "tabulate",
      priority = 2L,
      hints = c("summarize", "tabulate")
    ),
    "bysort g: tabulate x" = list(
      variables = c("g", "x"),
      meaning = "tabulate",
      priority = 2L,
      hints = c("by", "tabulate")
    ),
    "tabulate x1 x2, exact" = list(
      variables = c("x1", "x2"),
      meaning = "tabulate",
      priority = 2L,
      hints = c("exact", "tabulate")
    ),
    "table x, statistic(mean y)" = list(
      variables = c("x", "y"),
      meaning = "table",
      priority = 1L,
      hints = c("statistic", "table")
    ),
    "dtable x1 x2, by(group)" = list(
      variables = c("x1", "x2", "group"),
      meaning = "dtable",
      priority = 0L,
      hints = c("by", "dtable"),
      varlist = list(
        names = c("x1", "x2"),
        stata = "x1 x2",
        r = "x1, x2",
        style = "args"
      )
    ),
    "mean x" = list(
      variables = c("x"),
      meaning = "mean",
      priority = 0L,
      hints = c("mean"),
      varlist = list(names = c("x"), stata = "x", r = "x", style = "args")
    ),
    "ci mean x" = list(
      variables = c("x"),
      meaning = "ci",
      priority = 0L,
      hints = c("ci")
    ),
    "proportion x" = list(
      variables = c("x"),
      meaning = "proportion",
      priority = 0L,
      hints = c("proportion")
    ),
    "prtest x == 0.5" = list(
      variables = c("x"),
      meaning = "prtest",
      priority = 0L,
      hints = c("prtest")
    ),
    "ranksum x, by(group)" = list(
      variables = c("x", "group"),
      meaning = "ranksum",
      priority = 0L,
      hints = c("by", "ranksum")
    ),
    "signrank x = y" = list(
      variables = c("x", "y"),
      meaning = "signrank",
      priority = 0L,
      hints = c("signrank")
    ),
    "kwallis x, by(group)" = list(
      variables = c("x", "group"),
      meaning = "kwallis",
      priority = 0L,
      hints = c("by", "kwallis")
    ),
    "ksmirnov x, by(group)" = list(
      variables = c("x", "group"),
      meaning = "ksmirnov",
      priority = 0L,
      hints = c("by", "ksmirnov")
    ),
    "anova y group" = list(
      variables = c("y", "group"),
      meaning = "anova",
      priority = 0L,
      hints = c("anova")
    ),
    "oneway y group" = list(
      variables = c("y", "group"),
      meaning = "oneway",
      priority = 0L,
      hints = c("oneway")
    ),
    "swilk x" = list(
      variables = c("x"),
      meaning = "swilk",
      priority = 0L,
      hints = c("swilk")
    ),
    "sktest x" = list(
      variables = c("x"),
      meaning = "sktest",
      priority = 0L,
      hints = c("sktest"),
      varlist = list(names = c("x"), stata = "x", r = "x", style = "args")
    ),
    "spearman x y" = list(
      variables = c("x", "y"),
      meaning = "spearman",
      priority = 0L,
      hints = c("spearman")
    ),
    "ktau x y" = list(
      variables = c("x", "y"),
      meaning = "ktau",
      priority = 0L,
      hints = c("ktau")
    ),
    "pca x1 x2 x3" = list(
      variables = c("x1", "x2", "x3"),
      meaning = "pca",
      priority = 0L,
      hints = c("pca"),
      varlist = list(
        names = c("x1", "x2", "x3"),
        stata = "x1 x2 x3",
        r = "x1, x2, x3",
        style = "args"
      )
    ),
    "factor x1 x2 x3" = list(
      variables = c("x1", "x2", "x3"),
      meaning = "factor",
      priority = 0L,
      hints = c("factor"),
      varlist = list(
        names = c("x1", "x2", "x3"),
        stata = "x1 x2 x3",
        r = "x1, x2, x3",
        style = "args"
      )
    ),
    "stem x" = list(
      variables = c("x"),
      meaning = "stem",
      priority = 0L,
      hints = c("stem")
    ),
    "univar x1 x2" = list(
      variables = c("x1", "x2"),
      meaning = "univar",
      priority = 0L,
      hints = c("univar"),
      varlist = list(
        names = c("x1", "x2"),
        stata = "x1 x2",
        r = "x1, x2",
        style = "args"
      )
    ),
    "count" = list(
      variables = character(),
      meaning = "count",
      priority = 0L,
      hints = c("count")
    ),
    "count if x > 0" = list(
      variables = c("x"),
      meaning = "count",
      priority = 2L,
      hints = c("count")
    ),
    "isid id wave" = list(
      variables = c("id", "wave"),
      meaning = "isid",
      priority = 0L,
      hints = c("isid")
    ),
    "duplicates report x1 x2" = list(
      variables = c("x1", "x2"),
      meaning = "duplicates:0",
      priority = 0L,
      hints = c("duplicates", "report"),
      varlist = list(
        names = c("x1", "x2"),
        stata = "x1 x2",
        r = "x1, x2",
        style = "args"
      )
    ),
    "duplicates tag x1 x2, generate(dup)" = list(
      variables = c("x1", "x2", "dup"),
      meaning = "duplicates:1",
      priority = 0L,
      hints = c("duplicates", "generate", "tag"),
      strings = c("dup"),
      varlist = list(
        names = c("x1", "x2"),
        stata = "x1 x2",
        r = "x1, x2",
        style = "args"
      )
    ),
    "duplicates list x1 x2" = list(
      variables = c("x1", "x2"),
      meaning = "duplicates:2",
      priority = 0L,
      hints = c("duplicates", "list"),
      varlist = list(
        names = c("x1", "x2"),
        stata = "x1 x2",
        r = "x1, x2",
        style = "args"
      )
    ),
    "distinct x1 x2, joint" = list(
      variables = c("x1", "x2"),
      meaning = "distinct",
      priority = 0L,
      hints = c("distinct", "joint"),
      varlist = list(
        names = c("x1", "x2"),
        stata = "x1 x2",
        r = "x1, x2",
        style = "args"
      )
    ),
    "misstable summarize" = list(
      variables = character(),
      meaning = "misstable:0",
      priority = 0L,
      hints = c("misstable", "summarize")
    ),
    "misstable patterns" = list(
      variables = character(),
      meaning = "misstable:1",
      priority = 0L,
      hints = c("misstable", "patterns")
    ),
    "assert x > 0" = list(
      variables = c("x"),
      meaning = "assert",
      priority = 0L,
      hints = c("assert")
    ),
    "mdesc" = list(
      variables = character(),
      meaning = "mdesc",
      priority = 0L,
      hints = c("mdesc")
    ),
    "confirm variable x" = list(
      variables = c("x"),
      meaning = "confirm",
      priority = 0L,
      hints = c("confirm"),
      strings = c("x")
    ),
    "label define gender 1 \"male\" 2 \"female\"" = list(
      variables = c("gender"),
      meaning = "label:0",
      priority = 0L,
      hints = c("define", "label")
    ),
    "label define x 9 \"Unknown\" 10 \"Refused\"" = list(
      variables = c("x"),
      meaning = "label",
      priority = 2L,
      hints = c("define", "label")
    ),
    "label variable x \"Variable name\"" = list(
      variables = c("x"),
      meaning = "label:1",
      priority = 0L,
      hints = c("label", "variable")
    ),
    "label list x" = list(
      variables = c("x"),
      meaning = "label:2",
      priority = 0L,
      hints = c("label", "list")
    ),
    "encode str_x, generate(x)" = list(
      variables = c("str_x", "x"),
      meaning = "encode",
      priority = 0L,
      hints = c("encode", "generate")
    ),
    "decode x, generate(str_x)" = list(
      variables = c("x", "str_x"),
      meaning = "decode",
      priority = 0L,
      hints = c("decode", "generate")
    ),
    "label values x yesno" = list(
      variables = c("x", "yesno"),
      meaning = "label:3",
      priority = 0L,
      hints = c("label", "values")
    ),
    "label drop yesno" = list(
      variables = c("yesno"),
      meaning = "label:4",
      priority = 0L,
      hints = c("drop", "label")
    ),
    "notes x: Collected in wave 2" = list(
      variables = c("x"),
      meaning = "notes",
      priority = 0L,
      hints = c("notes")
    ),
    "generate x2 = x^2" = list(
      variables = c("x2", "x"),
      meaning = "generate",
      priority = 0L,
      hints = c("generate")
    ),
    "generate n = _n" = list(
      variables = c("n"),
      meaning = "generate",
      priority = 1L,
      hints = c("generate")
    ),
    "generate N = _N" = list(
      variables = c("N"),
      meaning = "generate",
      priority = 1L,
      hints = c("generate")
    ),
    "generate x2 = x^2 if x > 0" = list(
      variables = c("x2", "x"),
      meaning = "generate",
      priority = 2L,
      hints = c("generate")
    ),
    "generate x2 = x^2 in 11/20" = list(
      variables = c("x2", "x"),
      meaning = "generate",
      priority = 2L,
      hints = c("generate")
    ),
    "generate dummy = (x1 == 1 & x2 == 2)" = list(
      variables = c("dummy", "x1", "x2"),
      meaning = "generate",
      priority = 2L,
      hints = c("generate")
    ),
    "generate lag_x = x[_n-1]" = list(
      variables = c("lag_x", "x"),
      meaning = "generate",
      priority = 2L,
      hints = c("generate")
    ),
    "generate lead_x = x[_n+2]" = list(
      variables = c("lead_x", "x"),
      meaning = "generate",
      priority = 2L,
      hints = c("generate")
    ),
    "clonevar x2 = x" = list(
      variables = c("x2", "x"),
      meaning = "clonevar",
      priority = 0L,
      hints = c("clonevar")
    ),
    "replace x = x^2" = list(
      variables = c("x"),
      meaning = "replace",
      priority = 0L,
      hints = c("replace")
    ),
    "replace x = x^2 if x > 0" = list(
      variables = c("x"),
      meaning = "replace",
      priority = 2L,
      hints = c("replace")
    ),
    "replace x = x^2 in 11/20" = list(
      variables = c("x"),
      meaning = "replace",
      priority = 2L,
      hints = c("replace")
    ),
    "tabulate x, generate(x_)" = list(
      variables = c("x"),
      derived = c(x_ = "x"),
      meaning = "tabulate",
      priority = 2L,
      hints = c("generate", "tabulate")
    ),
    "recode x (1/5 = 1) (6/10 = 2) (11/15 = 3) (else = .), generate(x3g)" = list(
      variables = c("x", "x3g"),
      meaning = "recode",
      priority = 0L,
      hints = c("generate", "recode")
    ),
    "recode x (9 = .)" = list(
      variables = c("x"),
      meaning = "recode",
      priority = 2L,
      hints = c("recode")
    ),
    "mvdecode x, mv(-9)" = list(
      variables = c("x"),
      meaning = "mvdecode",
      priority = 0L,
      hints = c("mv", "mvdecode")
    ),
    "mvencode x, mv(-9)" = list(
      variables = c("x"),
      meaning = "mvencode",
      priority = 0L,
      hints = c("mv", "mvencode")
    ),
    "destring str_x, generate(num_x)" = list(
      variables = c("str_x", "num_x"),
      meaning = "destring",
      priority = 0L,
      hints = c("destring", "generate")
    ),
    "tostring num_x, generate(str_x)" = list(
      variables = c("num_x", "str_x"),
      meaning = "tostring",
      priority = 0L,
      hints = c("generate", "tostring")
    ),
    "xtile q = x, nquantiles(4)" = list(
      variables = c("q", "x"),
      meaning = "xtile",
      priority = 0L,
      hints = c("nquantiles", "xtile")
    ),
    "xtile q = x [aweight = w], nquantiles(4)" = list(
      variables = c("q", "x", "w"),
      meaning = "xtile",
      priority = 2L,
      hints = c("aweight", "nquantiles", "xtile")
    ),
    "egen bins = cut(x), group(10)" = list(
      variables = c("bins", "x"),
      meaning = "egen:0",
      priority = 0L,
      hints = c("cut", "egen", "group")
    ),
    "egen bins = cut(x), at(0(10)100)" = list(
      variables = c("bins", "x"),
      meaning = "egen",
      priority = 2L,
      hints = c("at", "cut", "egen")
    ),
    "egen x_sum = rowtotal(x1-x5)" = list(
      variables = c("x_sum", "x1", "x5"),
      meaning = "egen:1",
      priority = 0L,
      hints = c("egen", "rowtotal"),
      varlist = list(
        names = c("x1", "x5"),
        stata = "x1-x5",
        r = "x1:x5",
        style = "select"
      )
    ),
    "egen x_avg = rowmean(x1-x5)" = list(
      variables = c("x_avg", "x1", "x5"),
      meaning = "egen",
      priority = 2L,
      hints = c("egen", "rowmean"),
      varlist = list(
        names = c("x1", "x5"),
        stata = "x1-x5",
        r = "x1:x5",
        style = "select"
      )
    ),
    "egen x_min = rowmin(x1-x5)" = list(
      variables = c("x_min", "x1", "x5"),
      meaning = "egen",
      priority = 2L,
      hints = c("egen", "rowmin"),
      varlist = list(
        names = c("x1", "x5"),
        stata = "x1-x5",
        r = "x1:x5",
        style = "select"
      )
    ),
    "egen x_max = rowmax(x1-x5)" = list(
      variables = c("x_max", "x1", "x5"),
      meaning = "egen",
      priority = 2L,
      hints = c("egen", "rowmax"),
      varlist = list(
        names = c("x1", "x5"),
        stata = "x1-x5",
        r = "x1:x5",
        style = "select"
      )
    ),
    "egen x_med = rowmedian(x1-x5)" = list(
      variables = c("x_med", "x1", "x5"),
      meaning = "egen",
      priority = 2L,
      hints = c("egen", "rowmedian"),
      varlist = list(
        names = c("x1", "x5"),
        stata = "x1-x5",
        r = "x1:x5",
        style = "select"
      )
    ),
    "egen x_sd = rowsd(x1-x5)" = list(
      variables = c("x_sd", "x1", "x5"),
      meaning = "egen",
      priority = 2L,
      hints = c("egen", "rowsd"),
      varlist = list(
        names = c("x1", "x5"),
        stata = "x1-x5",
        r = "x1:x5",
        style = "select"
      )
    ),
    "egen x_mi = rowmiss(x1-x5)" = list(
      variables = c("x_mi", "x1", "x5"),
      meaning = "egen",
      priority = 2L,
      hints = c("egen", "rowmiss"),
      varlist = list(
        names = c("x1", "x5"),
        stata = "x1-x5",
        r = "x1:x5",
        style = "select"
      )
    ),
    "egen x_n = rownonmiss(x1-x5)" = list(
      variables = c("x_n", "x1", "x5"),
      meaning = "egen",
      priority = 2L,
      hints = c("egen", "rownonmiss"),
      varlist = list(
        names = c("x1", "x5"),
        stata = "x1-x5",
        r = "x1:x5",
        style = "select"
      )
    ),
    "egen x_nv = rownvals(x1-x5)" = list(
      variables = c("x_nv", "x1", "x5"),
      meaning = "egen",
      priority = 2L,
      hints = c("egen", "rownvals"),
      varlist = list(
        names = c("x1", "x5"),
        stata = "x1-x5",
        r = "x1:x5",
        style = "select"
      )
    ),
    "egen x_avg = mean(x)" = list(
      variables = c("x_avg", "x"),
      meaning = "egen:2",
      priority = 0L,
      hints = c("egen", "mean")
    ),
    "bysort group: egen x_avg = mean(x)" = list(
      variables = c("group", "x_avg", "x"),
      meaning = "egen",
      priority = 2L,
      hints = c("by", "egen", "mean")
    ),
    "egen id = group(g1 g2)" = list(
      variables = c("id", "g1", "g2"),
      meaning = "egen:3",
      priority = 0L,
      hints = c("egen", "group")
    ),
    "egen first = tag(group)" = list(
      variables = c("first", "group"),
      meaning = "egen:4",
      priority = 0L,
      hints = c("egen", "tag")
    ),
    "egen z = std(x)" = list(
      variables = c("z", "x"),
      meaning = "egen",
      priority = 2L,
      hints = c("egen", "std")
    ),
    "egen p = pc(x)" = list(
      variables = c("p", "x"),
      meaning = "egen",
      priority = 2L,
      hints = c("egen", "pc")
    ),
    "winsor2 x, cuts(1 99)" = list(
      variables = c("x"),
      derived = c(x_w = "x"),
      meaning = "winsor2",
      priority = 0L,
      hints = c("cuts", "winsor2")
    ),
    "rename x x2" = list(
      variables = c("x", "x2"),
      meaning = "rename",
      priority = 0L,
      hints = c("rename")
    ),
    "rename *, lower" = list(
      variables = character(),
      meaning = "rename",
      priority = 2L,
      hints = c("lower", "rename")
    ),
    "collapse (mean) x1 x2, by(group)" = list(
      variables = c("x1", "x2", "group"),
      meaning = "collapse",
      priority = 0L,
      hints = c("by", "collapse"),
      varlist = list(
        names = c("x1", "x2"),
        stata = "x1 x2",
        r = "x1, x2",
        style = "args"
      )
    ),
    "collapse (count) n = x (sum) total = y, by(group)" = list(
      variables = c("n", "x", "total", "y", "group"),
      meaning = "collapse",
      priority = 2L,
      hints = c("by", "collapse", "count")
    ),
    "egen r = rank(x)" = list(
      variables = c("r", "x"),
      meaning = "egen",
      priority = 2L,
      hints = c("egen", "rank")
    ),
    "bysort group: egen tot = total(x)" = list(
      variables = c("group", "tot", "x"),
      meaning = "egen",
      priority = 2L,
      hints = c("by", "egen", "total")
    ),
    "bysort group: egen n = count(x)" = list(
      variables = c("group", "n", "x"),
      meaning = "egen",
      priority = 2L,
      hints = c("by", "count", "egen")
    ),
    "bysort group: egen mx = max(x)" = list(
      variables = c("group", "mx", "x"),
      meaning = "egen",
      priority = 2L,
      hints = c("by", "egen", "max")
    ),
    "bysort group: egen mn = min(x)" = list(
      variables = c("group", "mn", "x"),
      meaning = "egen",
      priority = 2L,
      hints = c("by", "egen", "min")
    ),
    "bysort group: egen s = sd(x)" = list(
      variables = c("group", "s", "x"),
      meaning = "egen",
      priority = 2L,
      hints = c("by", "egen", "sd")
    ),
    "bysort group: egen med = median(x)" = list(
      variables = c("group", "med", "x"),
      meaning = "egen",
      priority = 2L,
      hints = c("by", "egen", "median")
    ),
    "egen id = concat(a b), punct(_)" = list(
      variables = c("id", "a", "b"),
      meaning = "egen",
      priority = 2L,
      hints = c("concat", "egen", "punct")
    ),
    "egen n9 = anycount(x1-x5), values(9)" = list(
      variables = c("n9", "x1", "x5"),
      meaning = "egen",
      priority = 2L,
      hints = c("anycount", "egen", "values"),
      varlist = list(
        names = c("x1", "x5"),
        stata = "x1-x5",
        r = "x1:x5",
        style = "select"
      )
    ),
    "egen first = rowfirst(x1-x5)" = list(
      variables = c("first", "x1", "x5"),
      meaning = "egen",
      priority = 2L,
      hints = c("egen", "rowfirst"),
      varlist = list(
        names = c("x1", "x5"),
        stata = "x1-x5",
        r = "x1, x2, x3, x4, x5",
        style = "args"
      )
    ),
    "egen last = rowlast(x1-x5)" = list(
      variables = c("last", "x1", "x5"),
      meaning = "egen",
      priority = 2L,
      hints = c("egen", "rowlast"),
      varlist = list(
        names = c("x1", "x5"),
        stata = "x1-x5",
        r = "x5, x4, x3, x2, x1",
        style = "reverse_args"
      )
    ),
    "egen s = seq(), from(1) to(3)" = list(
      variables = c("s"),
      meaning = "egen",
      priority = 2L,
      hints = c("egen", "from", "seq", "to")
    ),
    "pctile p = x, nquantiles(4)" = list(
      variables = c("p", "x"),
      meaning = "pctile",
      priority = 0L,
      hints = c("nquantiles", "pctile")
    ),
    "generate y = cond(x > 0, 1, 0)" = list(
      variables = c("y", "x"),
      meaning = "cond",
      priority = 0L,
      hints = c("cond")
    ),
    "generate y = inlist(x, 1, 3, 5)" = list(
      variables = c("y", "x"),
      meaning = "inlist",
      priority = 0L,
      hints = c("inlist")
    ),
    "generate y = inrange(x, 1, 5)" = list(
      variables = c("y", "x"),
      meaning = "inrange",
      priority = 0L,
      hints = c("inrange")
    ),
    "generate m = missing(x)" = list(
      variables = c("m", "x"),
      meaning = "missing",
      priority = 0L,
      hints = c("missing")
    ),
    "generate y = round(x, 0.1)" = list(
      variables = c("y", "x"),
      meaning = "round",
      priority = 0L,
      hints = c("round")
    ),
    "generate y = floor(x)" = list(
      variables = c("y", "x"),
      meaning = "floor",
      priority = 0L,
      hints = c("floor")
    ),
    "generate y = ceil(x)" = list(
      variables = c("y", "x"),
      meaning = "ceil",
      priority = 0L,
      hints = c("ceil")
    ),
    "generate y = ln(x)" = list(
      variables = c("y", "x"),
      meaning = "ln",
      priority = 0L,
      hints = c("ln")
    ),
    "generate u = runiform()" = list(
      variables = c("u"),
      meaning = "runiform",
      priority = 0L,
      hints = c("runiform")
    ),
    "generate z = rnormal()" = list(
      variables = c("z"),
      meaning = "rnormal",
      priority = 0L,
      hints = c("rnormal")
    ),
    "generate cs = sum(x)" = list(
      variables = c("cs", "x"),
      meaning = "sum",
      priority = 0L,
      hints = c("sum")
    ),
    "generate days = d2 - d1" = list(
      variables = c("days", "d2", "d1"),
      meaning = "generate",
      priority = 2L,
      hints = c("generate")
    ),
    "recast double x" = list(
      variables = c("x"),
      meaning = "recast",
      priority = 0L,
      hints = c("recast")
    ),
    "format x %9.2f" = list(
      variables = c("x"),
      derived = c(x_text = "x"),
      meaning = "format:0",
      priority = 0L,
      hints = c("format")
    ),
    "rename (a b) (c d)" = list(
      variables = c("a", "b", "c", "d"),
      meaning = "rename",
      priority = 1L,
      hints = c("rename")
    ),
    "rename x*, upper" = list(
      variables = c("x"),
      meaning = "rename",
      priority = 2L,
      hints = c("rename", "upper"),
      strings = c("x")
    ),
    "rename * *_old" = list(
      variables = character(),
      meaning = "rename",
      priority = 2L,
      hints = c("rename")
    ),
    "keep x1 x3-x5" = list(
      variables = c("x1", "x3", "x5"),
      meaning = "keep:0",
      priority = 0L,
      hints = c("keep"),
      varlist = list(
        names = c("x1", "x3", "x5"),
        stata = "x1 x3-x5",
        r = "x1, x3:x5",
        style = "args"
      )
    ),
    "keep x*" = list(
      variables = c("x"),
      meaning = "keep",
      priority = 2L,
      hints = c("keep"),
      strings = c("x*")
    ),
    "drop x" = list(
      variables = c("x"),
      meaning = "drop:0",
      priority = 0L,
      hints = c("drop"),
      varlist = list(names = c("x"), stata = "x", r = "-x", style = "exclude")
    ),
    "drop x1 x3-x5" = list(
      variables = c("x1", "x3", "x5"),
      meaning = "drop",
      priority = 2L,
      hints = c("drop"),
      varlist = list(
        names = c("x1", "x3", "x5"),
        stata = "x1 x3-x5",
        r = "x1, x3:x5",
        style = "args"
      )
    ),
    "keep in 1/10" = list(
      variables = character(),
      meaning = "keep:2",
      priority = 0L,
      hints = c("in", "keep")
    ),
    "keep in 7/12" = list(
      variables = character(),
      meaning = "keep",
      priority = 2L,
      hints = c("in", "keep")
    ),
    "keep in -10/-1" = list(
      variables = character(),
      meaning = "keep",
      priority = 2L,
      hints = c("in", "keep")
    ),
    "keep if x1 == 1 & x2 == 2" = list(
      variables = c("x1", "x2"),
      meaning = "keep:1",
      priority = 0L,
      hints = c("if", "keep")
    ),
    "keep if !missing(x)" = list(
      variables = c("x"),
      meaning = "keep",
      priority = 2L,
      hints = c("if", "keep", "missing")
    ),
    "drop if x == 1" = list(
      variables = c("x"),
      meaning = "drop:1",
      priority = 0L,
      hints = c("drop", "if")
    ),
    "duplicates drop" = list(
      variables = character(),
      meaning = "duplicates:3",
      priority = 0L,
      hints = c("drop", "duplicates")
    ),
    "duplicates drop x1 x2, force" = list(
      variables = c("x1", "x2"),
      meaning = "duplicates",
      priority = 2L,
      hints = c("drop", "duplicates", "force"),
      varlist = list(
        names = c("x1", "x2"),
        stata = "x1 x2",
        r = "x1, x2",
        style = "args"
      )
    ),
    "set seed 2024; sample 1000, count" = list(
      variables = character(),
      meaning = "sample:0",
      priority = 0L,
      hints = c("count", "sample")
    ),
    "set seed 2024; sample 10" = list(
      variables = character(),
      meaning = "sample:1",
      priority = 0L,
      hints = c("sample")
    ),
    "drop in 1/4" = list(
      variables = character(),
      meaning = "drop:2",
      priority = 0L,
      hints = c("drop", "in")
    ),
    "drop if missing(x)" = list(
      variables = c("x"),
      meaning = "drop",
      priority = 2L,
      hints = c("drop", "if", "missing")
    ),
    "keep if inlist(x, 1, 3, 5)" = list(
      variables = c("x"),
      meaning = "keep",
      priority = 2L,
      hints = c("if", "inlist", "keep")
    ),
    "keep if inrange(x, 5000, 10000)" = list(
      variables = c("x"),
      meaning = "keep",
      priority = 2L,
      hints = c("if", "inrange", "keep")
    ),
    "order x1-x4" = list(
      variables = c("x1", "x4"),
      meaning = "order",
      priority = 0L,
      hints = c("order"),
      varlist = list(
        names = c("x1", "x4"),
        stata = "x1-x4",
        r = "x1:x4",
        style = "select"
      )
    ),
    "order x1-x4, before(x5)" = list(
      variables = c("x1", "x4", "x5"),
      meaning = "order",
      priority = 2L,
      hints = c("before", "order"),
      strings = character(),
      varlist = list(
        names = c("x1", "x4"),
        stata = "x1-x4",
        r = "x1:x4",
        style = "select"
      )
    ),
    "sort x1 x2" = list(
      variables = c("x1", "x2"),
      meaning = "sort",
      priority = 0L,
      hints = c("sort"),
      varlist = list(
        names = c("x1", "x2"),
        stata = "x1 x2",
        r = "x1, x2",
        style = "args"
      )
    ),
    "gsort x1 -x2" = list(
      variables = c("x1", "x2"),
      meaning = "gsort",
      priority = 0L,
      hints = c("gsort")
    ),
    "append using data2" = list(
      variables = character(),
      meaning = "append",
      priority = 0L,
      hints = c("append")
    ),
    "merge 1:1 id using data2" = list(
      variables = c("id"),
      meaning = "merge:0",
      priority = 0L,
      hints = c("1:1", "merge"),
      strings = c("id"),
      varlist = list(
        names = c("id"),
        stata = "id",
        r = "\"id\"",
        style = "strings"
      )
    ),
    "merge m:1 id using data2" = list(
      variables = c("id"),
      meaning = "merge:1",
      priority = 0L,
      hints = c("m:1", "merge"),
      strings = c("id"),
      varlist = list(
        names = c("id"),
        stata = "id",
        r = "\"id\"",
        style = "strings"
      )
    ),
    "merge 1:m id using data2" = list(
      variables = c("id"),
      meaning = "merge:2",
      priority = 0L,
      hints = c("1:m", "merge"),
      strings = c("id"),
      varlist = list(
        names = c("id"),
        stata = "id",
        r = "\"id\"",
        style = "strings"
      )
    ),
    "merge 1:1 id using data2, keep(match)" = list(
      variables = c("id"),
      meaning = "merge",
      priority = 2L,
      hints = c("1:1", "keep", "merge"),
      strings = c("id"),
      varlist = list(
        names = c("id"),
        stata = "id",
        r = "\"id\"",
        style = "strings"
      )
    ),
    "merge 1:1 id using data2, keep(master match)" = list(
      variables = c("id"),
      meaning = "merge",
      priority = 2L,
      hints = c("1:1", "keep", "merge"),
      strings = c("id"),
      varlist = list(
        names = c("id"),
        stata = "id",
        r = "\"id\"",
        style = "strings"
      )
    ),
    "merge 1:1 id using data2, keep(using match)" = list(
      variables = c("id"),
      meaning = "merge",
      priority = 2L,
      hints = c("1:1", "keep", "merge"),
      strings = c("id"),
      varlist = list(
        names = c("id"),
        stata = "id",
        r = "\"id\"",
        style = "strings"
      )
    ),
    "merge 1:1 id1 id2 using data2, nogenerate" = list(
      variables = c("id1", "id2"),
      meaning = "merge",
      priority = 2L,
      hints = c("1:1", "merge", "nogenerate"),
      strings = c("id1", "id2"),
      varlist = list(
        names = c("id1", "id2"),
        stata = "id1 id2",
        r = "c(\"id1\", \"id2\")",
        style = "strings"
      )
    ),
    "merge 1:1 id using data2, keep(match) keepusing(id) nogenerate" = list(
      variables = c("id"),
      meaning = "merge",
      priority = 2L,
      hints = c("1:1", "keep", "keepusing", "merge", "nogenerate"),
      strings = c("id"),
      varlist = list(
        names = c("id"),
        stata = "id",
        r = "\"id\"",
        style = "strings"
      )
    ),
    "merge 1:1 id using data2, keep(master) keepusing(id) nogenerate" = list(
      variables = c("id"),
      meaning = "merge",
      priority = 2L,
      hints = c("1:1", "keep", "keepusing", "merge", "nogenerate"),
      strings = c("id"),
      varlist = list(
        names = c("id"),
        stata = "id",
        r = "\"id\"",
        style = "strings"
      )
    ),
    "merge 1:1 _n using data2" = list(
      variables = character(),
      meaning = "merge:3",
      priority = 0L,
      hints = c("1:1", "merge")
    ),
    "joinby id using data2" = list(
      variables = c("id"),
      meaning = "joinby",
      priority = 0L,
      hints = c("joinby"),
      strings = c("id"),
      varlist = list(
        names = c("id"),
        stata = "id",
        r = "\"id\"",
        style = "strings"
      )
    ),
    "append using data2, generate(source)" = list(
      variables = c("source"),
      meaning = "append",
      priority = 2L,
      hints = c("append", "generate"),
      strings = c("source")
    ),
    "cross using data2" = list(
      variables = character(),
      meaning = "cross",
      priority = 0L,
      hints = c("cross")
    ),
    "reshape long var, i(id) j(year)" = list(
      variables = c("var", "id", "year"),
      meaning = "reshape:0",
      priority = 0L,
      hints = c("i", "j", "long", "reshape"),
      strings = c("var", "year")
    ),
    "reshape wide var, i(id) j(year)" = list(
      variables = c("var", "id", "year"),
      meaning = "reshape:1",
      priority = 0L,
      hints = c("i", "j", "reshape", "wide"),
      strings = c("var")
    ),
    "xpose, clear" = list(
      variables = character(),
      meaning = "xpose",
      priority = 0L,
      hints = c("clear", "xpose")
    ),
    "input x y" = list(
      variables = c("x", "y"),
      meaning = "input",
      priority = 1L,
      hints = c("input")
    ),
    "fillin x1 x2" = list(
      variables = c("x1", "x2"),
      meaning = "fillin",
      priority = 0L,
      hints = c("fillin"),
      varlist = list(
        names = c("x1", "x2"),
        stata = "x1 x2",
        r = "x1, x2",
        style = "args"
      )
    ),
    "expand n" = list(
      variables = c("n"),
      meaning = "expand",
      priority = 0L,
      hints = c("expand")
    ),
    "set obs 100" = list(
      variables = character(),
      meaning = "set:0",
      priority = 0L,
      hints = c("obs", "set")
    ),
    "split name, parse(\" \")" = list(
      variables = c("name"),
      meaning = "split",
      priority = 0L,
      hints = c("parse", "split")
    ),
    "generate s = substr(name, 1, 3)" = list(
      variables = c("s", "name"),
      meaning = "substr",
      priority = 0L,
      hints = c("substr")
    ),
    "generate n = strlen(name)" = list(
      variables = c("n", "name"),
      meaning = "strlen",
      priority = 0L,
      hints = c("strlen")
    ),
    "generate s = upper(name)" = list(
      variables = c("s", "name"),
      meaning = "upper",
      priority = 0L,
      hints = c("upper")
    ),
    "generate s = lower(name)" = list(
      variables = c("s", "name"),
      meaning = "lower",
      priority = 0L,
      hints = c("lower")
    ),
    "generate s = strtrim(name)" = list(
      variables = c("s", "name"),
      meaning = "strtrim",
      priority = 0L,
      hints = c("strtrim")
    ),
    "generate s = subinstr(name, \"a\", \"b\", .)" = list(
      variables = c("s", "name"),
      meaning = "subinstr",
      priority = 0L,
      hints = c("subinstr")
    ),
    "generate has = strpos(name, \"a\") > 0" = list(
      variables = c("has", "name"),
      meaning = "strpos",
      priority = 0L,
      hints = c("strpos")
    ),
    "generate has = regexm(name, \"^A\")" = list(
      variables = c("has", "name"),
      meaning = "regexm",
      priority = 0L,
      hints = c("regexm")
    ),
    "generate d = date(s, \"YMD\")" = list(
      variables = c("d", "s"),
      meaning = "date",
      priority = 0L,
      hints = c("date")
    ),
    "generate d = mdy(m, d, y)" = list(
      variables = c("result", "m", "d", "y"),
      output_aliases = c(d = "result"),
      meaning = "mdy",
      priority = 0L,
      hints = c("mdy")
    ),
    "generate y = year(d)" = list(
      variables = c("y", "d"),
      meaning = "year",
      priority = 0L,
      hints = c("year")
    ),
    "generate m = mofd(d)" = list(
      variables = c("m", "d"),
      meaning = "mofd",
      priority = 0L,
      hints = c("mofd")
    ),
    "generate w = word(name, 1)" = list(
      variables = c("w", "name"),
      meaning = "word",
      priority = 0L,
      hints = c("word")
    ),
    "generate n = wordcount(name)" = list(
      variables = c("n", "name"),
      meaning = "wordcount",
      priority = 0L,
      hints = c("wordcount")
    ),
    "generate m = strmatch(name, \"A*\")" = list(
      variables = c("m", "name"),
      meaning = "strmatch",
      priority = 0L,
      hints = c("strmatch")
    ),
    "generate s = regexr(name, \"[0-9]+\", \"\")" = list(
      variables = c("s", "name"),
      meaning = "regexr",
      priority = 0L,
      hints = c("regexr")
    ),
    "generate d = regexs(1) if regexm(name, \"([0-9]+)\")" = list(
      variables = c("d", "name"),
      meaning = "regexs",
      priority = 0L,
      hints = c("regexm", "regexs")
    ),
    "generate has = ustrregexm(name, \"^a\", 1)" = list(
      variables = c("has", "name"),
      meaning = "ustrregexm",
      priority = 0L,
      hints = c("ustrregexm")
    ),
    "generate s = stritrim(name)" = list(
      variables = c("s", "name"),
      meaning = "stritrim",
      priority = 0L,
      hints = c("stritrim")
    ),
    "generate s = strupper(name)" = list(
      variables = c("s", "name"),
      meaning = "strupper",
      priority = 0L,
      hints = c("strupper")
    ),
    "generate s = strlower(name)" = list(
      variables = c("s", "name"),
      meaning = "strlower",
      priority = 0L,
      hints = c("strlower")
    ),
    "generate s = strproper(name)" = list(
      variables = c("s", "name"),
      meaning = "strproper",
      priority = 0L,
      hints = c("strproper")
    ),
    "generate s = string(x)" = list(
      variables = c("s", "x"),
      meaning = "string",
      priority = 0L,
      hints = c("string")
    ),
    "generate x = real(s)" = list(
      variables = c("x", "s"),
      meaning = "real",
      priority = 0L,
      hints = c("real")
    ),
    "generate n = strtoname(s)" = list(
      variables = c("n", "s"),
      meaning = "strtoname",
      priority = 0L,
      hints = c("strtoname")
    ),
    "generate m = month(d)" = list(
      variables = c("m", "d"),
      meaning = "month",
      priority = 0L,
      hints = c("month")
    ),
    "generate dd = day(d)" = list(
      variables = c("dd", "d"),
      meaning = "day",
      priority = 0L,
      hints = c("day")
    ),
    "generate w = dow(d)" = list(
      variables = c("w", "d"),
      meaning = "dow",
      priority = 0L,
      hints = c("dow")
    ),
    "generate q = qofd(d)" = list(
      variables = c("q", "d"),
      meaning = "qofd",
      priority = 0L,
      hints = c("qofd")
    ),
    "generate d = dofm(m)" = list(
      variables = c("d", "m"),
      meaning = "dofm",
      priority = 0L,
      hints = c("dofm")
    ),
    "generate t = clock(s, \"YMDhms\")" = list(
      variables = c("t", "s"),
      meaning = "clock",
      priority = 0L,
      hints = c("clock")
    ),
    "format d %td" = list(
      variables = c("d"),
      meaning = "format:1",
      priority = 0L,
      hints = c("format")
    ),
    "display c(current_date)" = list(
      variables = character(),
      meaning = "display:1",
      priority = 0L,
      hints = c("c", "display")
    ),
    "generate age = (d2 - d1) / 365.25" = list(
      variables = c("age", "d2", "d1"),
      meaning = "generate",
      priority = 2L,
      hints = c("generate")
    ),
    "foreach v of varlist v1-v5 { generate `v'_sq = `v'^2 }" = list(
      variables = c("v1", "v5"),
      meaning = "foreach",
      priority = 0L,
      hints = c("foreach")
    ),
    "forvalues i = 1/5 { generate v`i'_sq = v`i'^2 if v`i' > 0 }" = list(
      variables = character(),
      meaning = "forvalues:0",
      priority = 0L,
      hints = c("forvalues")
    ),
    "forvalues i = 6/10 { forvalues j = 3/5 { replace x_`i'_`j' = x_`i'_`j' + 1 } }" = list(
      variables = character(),
      meaning = "forvalues:1",
      priority = 0L,
      hints = c("forvalues", "replace")
    ),
    "capture command" = list(
      variables = character(),
      meaning = "capture",
      priority = 0L,
      hints = c("capture")
    ),
    "quietly regress y x" = list(
      variables = character(),
      meaning = "quietly",
      priority = 0L,
      hints = c("quietly")
    ),
    "timer on 1" = list(
      variables = character(),
      meaning = "timer",
      priority = 0L,
      hints = c("timer")
    ),
    "set seed 2024" = list(
      variables = character(),
      meaning = "set:1",
      priority = 0L,
      hints = c("seed", "set")
    ),
    "preserve" = list(
      variables = character(),
      meaning = "preserve",
      priority = 0L,
      hints = c("preserve")
    ),
    "local vars x1 x2 x3" = list(
      variables = c("vars", "x1", "x2", "x3"),
      meaning = "local",
      priority = 0L,
      hints = c("local"),
      strings = c("x1", "x2", "x3")
    ),
    "scalar a = 3" = list(
      variables = c("a"),
      meaning = "scalar",
      priority = 0L,
      hints = c("scalar")
    ),
    "matrix A = (1, 2 \\ 3, 4)" = list(
      variables = c("A"),
      meaning = "matrix",
      priority = 0L,
      hints = c("matrix")
    ),
    "return list" = list(
      variables = character(),
      meaning = "return",
      priority = 0L,
      hints = c("return")
    ),
    "ereturn list" = list(
      variables = character(),
      meaning = "ereturn",
      priority = 0L,
      hints = c("ereturn")
    ),
    "display _b[x]" = list(
      variables = c("x"),
      meaning = "display:2",
      priority = 0L,
      hints = c("display"),
      strings = c("x")
    ),
    "display _se[x]" = list(
      variables = c("x"),
      meaning = "display:3",
      priority = 0L,
      hints = c("display"),
      strings = c("x")
    ),
    "while `i' < 10 { local i = `i' + 1 }" = list(
      variables = c("i"),
      meaning = "while",
      priority = 0L,
      hints = c("while")
    ),
    "if `x' > 0 { display \"positive\" }" = list(
      variables = c("x"),
      meaning = "if",
      priority = 0L,
      hints = c("if")
    ),
    "program define myprog" = list(
      variables = character(),
      meaning = "program",
      priority = 0L,
      hints = c("program")
    ),
    "tempfile f" = list(
      variables = c("f"),
      meaning = "tempfile",
      priority = 0L,
      hints = c("tempfile")
    ),
    "set trace on" = list(
      variables = character(),
      meaning = "set:2",
      priority = 0L,
      hints = c("set", "trace")
    ),
    "clear all" = list(
      variables = character(),
      meaning = "clear",
      priority = 2L,
      hints = c("clear")
    ),
    "frame create other" = list(
      variables = character(),
      meaning = "frame",
      priority = 0L,
      hints = c("frame")
    ),
    "which summarize" = list(
      variables = character(),
      meaning = "which",
      priority = 0L,
      hints = c("which")
    ),
    "ado update" = list(
      variables = character(),
      meaning = "ado",
      priority = 0L,
      hints = c("ado")
    ),
    "version 18" = list(
      variables = character(),
      meaning = "version",
      priority = 0L,
      hints = c("version")
    ),
    "cls" = list(
      variables = character(),
      meaning = "cls",
      priority = 0L,
      hints = c("cls")
    ),
    "macro list" = list(
      variables = character(),
      meaning = "macro",
      priority = 0L,
      hints = c("macro")
    ),
    "regress y x1 x2" = list(
      variables = c("y", "x1", "x2"),
      r_default = c("lm"),
      meaning = "regress",
      priority = 0L,
      hints = c("regress"),
      varlist = list(
        names = c("x1", "x2"),
        stata = "x1 x2",
        r = "x1 + x2",
        style = "formula"
      )
    ),
    "regress y x1 x2, robust" = list(
      variables = c("y", "x1", "x2"),
      meaning = "regress",
      priority = 2L,
      hints = c("regress", "robust"),
      varlist = list(
        names = c("x1", "x2"),
        stata = "x1 x2",
        r = "x1 + x2",
        style = "formula"
      )
    ),
    "regress y x1 x2, vce(cluster id)" = list(
      variables = c("y", "x1", "x2", "id"),
      meaning = "regress",
      priority = 2L,
      hints = c("regress", "vce"),
      varlist = list(
        names = c("x1", "x2"),
        stata = "x1 x2",
        r = "x1 + x2",
        style = "formula"
      )
    ),
    "regress y i.group c.x1##c.x2" = list(
      variables = c("y", "group", "x1", "x2"),
      meaning = "regress",
      priority = 1L,
      hints = c("regress")
    ),
    "regress y x [pweight = wt]" = list(
      variables = c("y", "x", "wt"),
      meaning = "regress",
      priority = 2L,
      hints = c("pweight", "regress")
    ),
    "reghdfe y x, absorb(id year)" = list(
      variables = c("y", "x", "id", "year"),
      meaning = "reghdfe",
      priority = 0L,
      hints = c("absorb", "reghdfe")
    ),
    "xtreg y x, fe" = list(
      variables = c("y", "x"),
      meaning = "xtreg",
      priority = 0L,
      hints = c("fe", "xtreg")
    ),
    "xtreg y x, re" = list(
      variables = c("y", "x"),
      meaning = "xtreg",
      priority = 0L,
      hints = c("re", "xtreg"),
      strings = c("id", "year")
    ),
    "ivregress 2sls y x1 (x2 = z)" = list(
      variables = c("y", "x1", "x2", "z"),
      meaning = "ivregress",
      priority = 0L,
      hints = c("ivregress")
    ),
    "logit y x1 x2" = list(
      variables = c("y", "x1", "x2"),
      meaning = "logit",
      priority = 0L,
      hints = c("logit"),
      varlist = list(
        names = c("x1", "x2"),
        stata = "x1 x2",
        r = "x1 + x2",
        style = "formula"
      )
    ),
    "probit y x1 x2" = list(
      variables = c("y", "x1", "x2"),
      meaning = "probit",
      priority = 0L,
      hints = c("probit"),
      varlist = list(
        names = c("x1", "x2"),
        stata = "x1 x2",
        r = "x1 + x2",
        style = "formula"
      )
    ),
    "poisson y x1 x2" = list(
      variables = c("y", "x1", "x2"),
      meaning = "poisson",
      priority = 0L,
      hints = c("poisson"),
      varlist = list(
        names = c("x1", "x2"),
        stata = "x1 x2",
        r = "x1 + x2",
        style = "formula"
      )
    ),
    "margins, dydx(*)" = list(
      variables = character(),
      meaning = "margins:0",
      priority = 0L,
      hints = c("dydx", "margins")
    ),
    "margins group" = list(
      variables = c("group"),
      meaning = "margins:1",
      priority = 0L,
      hints = c("margins"),
      strings = c("group")
    ),
    "predict yhat" = list(
      variables = c("yhat"),
      meaning = "predict",
      priority = 0L,
      hints = c("predict")
    ),
    "test x1 = x2" = list(
      variables = c("x1", "x2"),
      meaning = "test",
      priority = 0L,
      hints = c("test"),
      expressions = c("x1 = x2")
    ),
    "estimates store m1" = list(
      variables = c("m1"),
      meaning = "estimates:0",
      priority = 0L,
      hints = c("estimates", "store")
    ),
    "esttab m1 m2" = list(
      variables = c("m1", "m2"),
      meaning = "esttab",
      priority = 0L,
      hints = c("esttab")
    ),
    "outreg2 using table.doc" = list(
      variables = character(),
      meaning = "outreg2",
      priority = 0L,
      hints = c("outreg2")
    ),
    "glm y x, family(binomial)" = list(
      variables = c("y", "x"),
      meaning = "glm",
      priority = 0L,
      hints = c("family", "glm"),
      varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
    ),
    "logit y x, or" = list(
      variables = c("y", "x"),
      meaning = "logit",
      priority = 2L,
      hints = c("logit", "or"),
      varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
    ),
    "logistic y x" = list(
      variables = c("y", "x"),
      meaning = "logistic",
      priority = 0L,
      hints = c("logistic"),
      varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
    ),
    "predict p, pr" = list(
      variables = c("p"),
      meaning = "predict",
      priority = 2L,
      hints = c("pr", "predict")
    ),
    "predict r, residuals" = list(
      variables = c("r"),
      meaning = "predict",
      priority = 2L,
      hints = c("predict", "residuals")
    ),
    "regress y ib3.group" = list(
      variables = c("y", "group"),
      meaning = "regress",
      priority = 1L,
      hints = c("regress")
    ),
    "mlogit y x1 x2" = list(
      variables = c("y", "x1", "x2"),
      meaning = "mlogit",
      priority = 0L,
      hints = c("mlogit"),
      varlist = list(
        names = c("x1", "x2"),
        stata = "x1 x2",
        r = "x1 + x2",
        style = "formula"
      )
    ),
    "ologit y x1 x2" = list(
      variables = c("y", "x1", "x2"),
      meaning = "ologit",
      priority = 0L,
      hints = c("ologit"),
      varlist = list(
        names = c("x1", "x2"),
        stata = "x1 x2",
        r = "x1 + x2",
        style = "formula"
      )
    ),
    "oprobit y x1 x2" = list(
      variables = c("y", "x1", "x2"),
      meaning = "oprobit",
      priority = 0L,
      hints = c("oprobit"),
      varlist = list(
        names = c("x1", "x2"),
        stata = "x1 x2",
        r = "x1 + x2",
        style = "formula"
      )
    ),
    "nbreg y x" = list(
      variables = c("y", "x"),
      meaning = "nbreg",
      priority = 0L,
      hints = c("nbreg"),
      varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
    ),
    "ppmlhdfe y x, absorb(id year)" = list(
      variables = c("y", "x", "id", "year"),
      meaning = "ppmlhdfe",
      priority = 0L,
      hints = c("absorb", "ppmlhdfe")
    ),
    "tobit y x, ll(0)" = list(
      variables = c("y", "x"),
      meaning = "tobit",
      priority = 0L,
      hints = c("ll", "tobit"),
      varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
    ),
    "qreg y x" = list(
      variables = c("y", "x"),
      meaning = "qreg",
      priority = 0L,
      hints = c("qreg"),
      varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
    ),
    "rreg y x" = list(
      variables = c("y", "x"),
      meaning = "rreg",
      priority = 0L,
      hints = c("rreg"),
      varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
    ),
    "areg y x, absorb(id)" = list(
      variables = c("y", "x", "id"),
      meaning = "areg",
      priority = 0L,
      hints = c("absorb", "areg"),
      varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
    ),
    "xtlogit y x, fe" = list(
      variables = c("y", "x"),
      meaning = "xtlogit",
      priority = 0L,
      hints = c("fe", "xtlogit"),
      varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
    ),
    "xtpoisson y x, fe" = list(
      variables = c("y", "x"),
      meaning = "xtpoisson",
      priority = 0L,
      hints = c("fe", "xtpoisson"),
      varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
    ),
    "mixed y x || id:" = list(
      variables = c("y", "x", "id"),
      meaning = "mixed",
      priority = 0L,
      hints = c("mixed"),
      varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
    ),
    "melogit y x || id:" = list(
      variables = c("y", "x", "id"),
      meaning = "melogit",
      priority = 0L,
      hints = c("melogit"),
      varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
    ),
    "heckman y x, select(s = z)" = list(
      variables = c("y", "x", "s", "z"),
      meaning = "heckman",
      priority = 0L,
      hints = c("heckman", "select")
    ),
    "sem (y <- x1 x2)" = list(
      variables = c("y", "x1", "x2"),
      meaning = "sem",
      priority = 0L,
      hints = c("sem"),
      expressions = c("y ~ x1 + x2")
    ),
    "cluster kmeans x1 x2, k(3)" = list(
      variables = c("x1", "x2"),
      meaning = "cluster",
      priority = 0L,
      hints = c("cluster", "k"),
      varlist = list(
        names = c("x1", "x2"),
        stata = "x1 x2",
        r = "x1, x2",
        style = "args"
      )
    ),
    "bootstrap, reps(500): regress y x" = list(
      variables = c("y", "x"),
      meaning = "bootstrap",
      priority = 0L,
      hints = c("bootstrap", "reps")
    ),
    "jackknife: regress y x" = list(
      variables = c("y", "x"),
      meaning = "jackknife",
      priority = 0L,
      hints = c("jackknife")
    ),
    "lincom x1 - x2" = list(
      variables = c("x1", "x2"),
      meaning = "lincom",
      priority = 0L,
      hints = c("lincom"),
      expressions = c("x1 - x2 = 0")
    ),
    "nlcom _b[x1] / _b[x2]" = list(
      variables = c("x1", "x2"),
      meaning = "nlcom",
      priority = 0L,
      hints = c("nlcom"),
      expressions = c("x1 / x2 = 0")
    ),
    "lrtest m1 m2" = list(
      variables = c("m1", "m2"),
      meaning = "lrtest",
      priority = 0L,
      hints = c("lrtest")
    ),
    "estat ic" = list(
      variables = character(),
      meaning = "estat:0",
      priority = 0L,
      hints = c("estat", "ic")
    ),
    "estat vce" = list(
      variables = character(),
      meaning = "estat:1",
      priority = 0L,
      hints = c("estat", "vce")
    ),
    "estat hettest" = list(
      variables = character(),
      meaning = "estat:2",
      priority = 0L,
      hints = c("estat", "hettest")
    ),
    "estat ovtest" = list(
      variables = character(),
      meaning = "estat:3",
      priority = 0L,
      hints = c("estat", "ovtest")
    ),
    "vif" = list(
      variables = character(),
      meaning = "vif",
      priority = 0L,
      hints = c("vif")
    ),
    "rvfplot" = list(
      variables = character(),
      meaning = "rvfplot",
      priority = 0L,
      hints = c("rvfplot")
    ),
    "avplots" = list(
      variables = character(),
      meaning = "avplots",
      priority = 0L,
      hints = c("avplots")
    ),
    "marginsplot" = list(
      variables = c("x"),
      meaning = "marginsplot",
      priority = 0L,
      hints = c("marginsplot"),
      strings = c("x")
    ),
    "estimates table m1 m2" = list(
      variables = c("m1", "m2"),
      meaning = "estimates:1",
      priority = 0L,
      hints = c("estimates", "table")
    ),
    "eststo m1: regress y x" = list(
      variables = c("m1", "y", "x"),
      meaning = "eststo",
      priority = 0L,
      hints = c("eststo")
    ),
    "etable" = list(
      variables = character(),
      meaning = "etable",
      priority = 0L,
      hints = c("etable")
    ),
    "putexcel set results.xlsx" = list(
      variables = character(),
      meaning = "putexcel",
      priority = 0L,
      hints = c("putexcel")
    ),
    "putdocx begin" = list(
      variables = character(),
      meaning = "putdocx",
      priority = 0L,
      hints = c("putdocx")
    ),
    "teffects psmatch (y) (t x1 x2)" = list(
      variables = c("y", "t", "x1", "x2"),
      meaning = "teffects:0",
      priority = 0L,
      hints = c("psmatch", "teffects")
    ),
    "teffects ipw (y) (t x1 x2)" = list(
      variables = c("y", "t", "x1", "x2"),
      meaning = "teffects:1",
      priority = 0L,
      hints = c("ipw", "teffects")
    ),
    "synth y x1 x2, trunit(1) trperiod(2000)" = list(
      variables = c("y", "x1", "x2"),
      meaning = "synth",
      priority = 0L,
      hints = c("synth", "trperiod", "trunit")
    ),
    "didregress (y) (treated), group(id) time(year)" = list(
      variables = c("y", "treated", "id", "year"),
      meaning = "didregress",
      priority = 0L,
      hints = c("didregress", "group", "time")
    ),
    "csdid y, ivar(id) time(year) gvar(first_treat)" = list(
      variables = c("y", "id", "year", "first_treat"),
      meaning = "csdid",
      priority = 0L,
      hints = c("csdid", "gvar", "ivar", "time"),
      strings = c("y", "id", "year", "first_treat")
    ),
    "rdrobust y x, c(0)" = list(
      variables = c("y", "x"),
      meaning = "rdrobust",
      priority = 0L,
      hints = c("c", "rdrobust")
    ),
    "ivreg2 y x1 (x2 = z), robust" = list(
      variables = c("y", "x1", "x2", "z"),
      meaning = "ivreg2",
      priority = 0L,
      hints = c("ivreg2", "robust")
    ),
    "oaxaca y x1 x2, by(group)" = list(
      variables = c("y", "x1", "x2", "group"),
      meaning = "oaxaca",
      priority = 0L,
      hints = c("by", "oaxaca"),
      varlist = list(
        names = c("x1", "x2"),
        stata = "x1 x2",
        r = "x1 + x2",
        style = "formula"
      )
    ),
    "xtabond y x" = list(
      variables = c("y", "x"),
      meaning = "xtabond",
      priority = 0L,
      hints = c("xtabond"),
      strings = c("id", "year")
    ),
    "mi impute chained (regress) x1 x2 = y" = list(
      variables = c("x1", "x2", "y"),
      meaning = "mi:0",
      priority = 0L,
      hints = c("chained", "impute", "mi")
    ),
    "mi estimate: regress y x" = list(
      variables = c("y", "x"),
      meaning = "mi:1",
      priority = 0L,
      hints = c("estimate", "mi"),
      varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
    ),
    "xtset id year" = list(
      variables = c("id", "year"),
      meaning = "xtset",
      priority = 0L,
      hints = c("xtset")
    ),
    "tsset year" = list(
      variables = c("year"),
      meaning = "tsset",
      priority = 0L,
      hints = c("tsset")
    ),
    "generate lag_x = L.x" = list(
      variables = c("lag_x", "x"),
      meaning = "l.",
      priority = 0L,
      hints = c("l.")
    ),
    "generate lead_x = F.x" = list(
      variables = c("lead_x", "x"),
      meaning = "f.",
      priority = 0L,
      hints = c("f.")
    ),
    "generate d_x = D.x" = list(
      variables = c("d_x", "x"),
      meaning = "d.",
      priority = 0L,
      hints = c("d.")
    ),
    "tsfill" = list(
      variables = character(),
      meaning = "tsfill",
      priority = 0L,
      hints = c("tsfill")
    ),
    "generate lag2_x = L2.x" = list(
      variables = c("lag2_x", "x"),
      meaning = "l.",
      priority = 2L,
      hints = c("l.")
    ),
    "xtdescribe" = list(
      variables = character(),
      meaning = "xtdescribe",
      priority = 0L,
      hints = c("xtdescribe")
    ),
    "xtsum x" = list(
      variables = c("x"),
      meaning = "xtsum",
      priority = 0L,
      hints = c("xtsum")
    ),
    "tsline y" = list(
      variables = c("y"),
      meaning = "tsline",
      priority = 0L,
      hints = c("tsline")
    ),
    "xtline y" = list(
      variables = c("y"),
      meaning = "xtline",
      priority = 0L,
      hints = c("xtline")
    ),
    "arima y, ar(1/2)" = list(
      variables = c("y"),
      meaning = "arima",
      priority = 0L,
      hints = c("ar", "arima")
    ),
    "carryforward x, replace" = list(
      variables = c("x"),
      meaning = "carryforward",
      priority = 0L,
      hints = c("carryforward", "replace"),
      varlist = list(names = c("x"), stata = "x", r = "x", style = "args")
    ),
    "stset time, failure(died)" = list(
      variables = c("time", "died"),
      meaning = "stset",
      priority = 0L,
      hints = c("failure", "stset")
    ),
    "sts graph" = list(
      variables = character(),
      meaning = "sts:0",
      priority = 0L,
      hints = c("graph", "sts")
    ),
    "sts test group" = list(
      variables = c("group"),
      meaning = "sts:1",
      priority = 0L,
      hints = c("sts", "test")
    ),
    "stsum" = list(
      variables = character(),
      meaning = "stsum",
      priority = 0L,
      hints = c("stsum")
    ),
    "stcox x1 x2" = list(
      variables = c("x1", "x2"),
      meaning = "stcox",
      priority = 0L,
      hints = c("stcox"),
      varlist = list(
        names = c("x1", "x2"),
        stata = "x1 x2",
        r = "x1 + x2",
        style = "formula"
      )
    ),
    "streg x, distribution(weibull)" = list(
      variables = c("x"),
      meaning = "streg",
      priority = 0L,
      hints = c("distribution", "streg")
    ),
    "svyset psu [pweight = wt], strata(stratum)" = list(
      variables = c("psu", "wt", "stratum"),
      meaning = "svyset",
      priority = 0L,
      hints = c("pweight", "strata", "svyset")
    ),
    "svy: mean x" = list(
      variables = c("x"),
      meaning = "svy:0",
      priority = 0L,
      hints = c("mean", "svy")
    ),
    "svy: tabulate x" = list(
      variables = c("x"),
      meaning = "svy:1",
      priority = 0L,
      hints = c("svy", "tabulate")
    ),
    "svy: regress y x" = list(
      variables = c("y", "x"),
      meaning = "svy:2",
      priority = 0L,
      hints = c("regress", "svy"),
      varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
    ),
    "svy: mean x, over(g)" = list(
      variables = c("x", "g"),
      meaning = "svy",
      priority = 2L,
      hints = c("mean", "over", "svy")
    ),
    "svy, subpop(rural): mean x" = list(
      variables = c("rural", "x"),
      meaning = "svy",
      priority = 2L,
      hints = c("mean", "subpop", "svy")
    ),
    "svy: proportion x" = list(
      variables = c("x"),
      meaning = "svy",
      priority = 2L,
      hints = c("proportion", "svy")
    ),
    "svy: logit y x" = list(
      variables = c("y", "x"),
      meaning = "svy:3",
      priority = 0L,
      hints = c("logit", "svy"),
      varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
    ),
    "svydescribe" = list(
      variables = character(),
      meaning = "svydescribe",
      priority = 0L,
      hints = c("svydescribe")
    ),
    "histogram x" = list(
      variables = c("x"),
      meaning = "histogram",
      priority = 0L,
      hints = c("histogram")
    ),
    "kdensity x" = list(
      variables = c("x"),
      meaning = "kdensity",
      priority = 0L,
      hints = c("kdensity")
    ),
    "scatter y x" = list(
      variables = c("y", "x"),
      meaning = "scatter",
      priority = 0L,
      hints = c("scatter")
    ),
    "twoway (scatter y x) (lfit y x)" = list(
      variables = c("y", "x"),
      meaning = "twoway:0",
      priority = 0L,
      hints = c("twoway")
    ),
    "line y x" = list(
      variables = c("y", "x"),
      meaning = "line",
      priority = 0L,
      hints = c("line")
    ),
    "graph bar (mean) y, over(group)" = list(
      variables = c("y", "group"),
      meaning = "graph:0",
      priority = 0L,
      hints = c("bar", "graph", "over")
    ),
    "graph box y, over(group)" = list(
      variables = c("y", "group"),
      meaning = "graph:1",
      priority = 0L,
      hints = c("box", "graph", "over")
    ),
    "graph export figure.png" = list(
      variables = character(),
      meaning = "graph:2",
      priority = 0L,
      hints = c("export", "graph")
    ),
    "binscatter y x" = list(
      variables = c("y", "x"),
      meaning = "binscatter",
      priority = 0L,
      hints = c("binscatter")
    ),
    "coefplot" = list(
      variables = character(),
      meaning = "coefplot",
      priority = 0L,
      hints = c("coefplot")
    ),
    "graph bar (count), over(x)" = list(
      variables = c("x"),
      meaning = "graph:3",
      priority = 0L,
      hints = c("bar", "count", "graph", "over")
    ),
    "graph hbar (mean) y, over(group)" = list(
      variables = c("y", "group"),
      meaning = "graph",
      priority = 2L,
      hints = c("graph", "hbar", "over")
    ),
    "graph dot (mean) y, over(group)" = list(
      variables = c("y", "group"),
      meaning = "graph",
      priority = 2L,
      hints = c("dot", "graph", "over")
    ),
    "graph hbox y, over(group)" = list(
      variables = c("y", "group"),
      meaning = "graph",
      priority = 2L,
      hints = c("graph", "hbox", "over")
    ),
    "graph pie, over(group)" = list(
      variables = c("group"),
      meaning = "graph:4",
      priority = 0L,
      hints = c("graph", "over")
    ),
    "graph matrix x1 x2 x3" = list(
      variables = c("x1", "x2", "x3"),
      meaning = "graph",
      priority = 2L,
      hints = c("graph", "matrix"),
      varlist = list(
        names = c("x1", "x2", "x3"),
        stata = "x1 x2 x3",
        r = "x1, x2, x3",
        style = "args"
      )
    ),
    "graph combine g1.gph g2.gph" = list(
      variables = character(),
      meaning = "graph",
      priority = 2L,
      hints = c("combine", "graph")
    ),
    "graph save fig.gph" = list(
      variables = character(),
      meaning = "graph",
      priority = 2L,
      hints = c("graph", "save")
    ),
    "twoway connected y x" = list(
      variables = c("y", "x"),
      meaning = "twoway:1",
      priority = 0L,
      hints = c("connected", "twoway")
    ),
    "twoway area y x" = list(
      variables = c("y", "x"),
      meaning = "twoway:2",
      priority = 0L,
      hints = c("area", "twoway")
    ),
    "twoway lfitci y x" = list(
      variables = c("y", "x"),
      meaning = "twoway",
      priority = 2L,
      hints = c("lfitci", "twoway")
    ),
    "twoway qfit y x" = list(
      variables = c("y", "x"),
      meaning = "twoway",
      priority = 2L,
      hints = c("qfit", "twoway"),
      protect = c("formula = y ~ poly(x, 2)")
    ),
    "twoway rcap hi lo x" = list(
      variables = c("hi", "lo", "x"),
      meaning = "twoway:3",
      priority = 0L,
      hints = c("rcap", "twoway")
    ),
    "twoway rarea hi lo x" = list(
      variables = c("hi", "lo", "x"),
      meaning = "twoway:4",
      priority = 0L,
      hints = c("rarea", "twoway")
    ),
    "twoway scatter y x, by(group)" = list(
      variables = c("y", "x", "group"),
      meaning = "twoway",
      priority = 2L,
      hints = c("by", "scatter", "twoway")
    ),
    "twoway (scatter y x if g == 1) (scatter y x if g == 2)" = list(
      variables = c("y", "x", "g"),
      meaning = "twoway",
      priority = 2L,
      hints = c("twoway")
    ),
    "lowess y x" = list(
      variables = c("y", "x"),
      meaning = "lowess",
      priority = 0L,
      hints = c("lowess")
    ),
    "scatter y x, mlabel(name)" = list(
      variables = c("y", "x", "name"),
      meaning = "scatter",
      priority = 2L,
      hints = c("mlabel", "scatter")
    ),
    "scatter y x, xline(0)" = list(
      variables = c("y", "x"),
      meaning = "scatter",
      priority = 2L,
      hints = c("scatter", "xline")
    ),
    "vioplot y, over(group)" = list(
      variables = c("y", "group"),
      meaning = "vioplot",
      priority = 0L,
      hints = c("over", "vioplot")
    ),
    "qnorm x" = list(
      variables = c("x"),
      meaning = "qnorm",
      priority = 0L,
      hints = c("qnorm")
    ),
    "set scheme s1mono" = list(
      variables = character(),
      meaning = "set:3",
      priority = 0L,
      hints = c("scheme", "set")
    )
  )
}
