# Catalogue annotations, keyed by stable example IDs.
# Variables follow Stata operand order. Only recorded variable locations are
# editable; quoted R column names and variable lists are declared separately.
findit_templates <- function() {
  if (is.null(findit_cache$templates)) {
    entries <- findit_entries()
    specs <- findit_template_specs()
    if (!identical(names(specs), entries$id)) {
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
    names(findit_cache$templates) <- entries$id
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
    entries$id,
    names(findit_templates())
  )]
  priority <- vapply(templates, function(x) x$priority, integer(1))
  meaning <- vapply(templates, function(x) x$meaning, character(1))
  if (any(entries$match[candidates] == "stata")) {
    stata <- candidates[entries$match[candidates] == "stata"]
    package <- findit_package_priority(entries$package[stata])
    stata <- stata[package == min(package)]
    primary <- stata[priority[stata] == min(priority[stata])]
    functions <- unlist(findit_calls(entries$r[entries$match == "stata"]))
    r <- candidates[entries$match[candidates] == "r"]
    # A distinct R meaning such as log() is not an optional Stata variation.
    distinct <- length(described) && !any(described %in% functions)
    if (distinct && length(r)) {
      preferred <- vapply(
        templates[r],
        function(t) {
          any(described %in% t$r_default)
        },
        logical(1)
      )
      if (any(preferred)) {
        r <- r[preferred]
      }
      r <- r[priority[r] == min(priority[r])]
      # Other uses of log(), for example inside model formulas, are not new
      # meanings of the R function. Expansion still retains every such use.
      r <- utils::head(r, 1L)
    }
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
    package <- findit_package_priority(entries$package[candidates])
    candidates <- candidates[package == min(package)]
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
  templates <- findit_templates()[match(
    attr(x, "entry_ids"),
    names(findit_templates())
  )]
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
    reference <- attr(x, "reference")
    reference$stata <- x$stata
    reference$r <- x$r
    attr(x, "reference") <- reference
  }
  if (nrow(x) && (length(hints) || any(fits))) {
    candidates <- pool[score[pool] == max(score[pool])]
    if (length(variables) && any(fits[candidates])) {
      candidates <- candidates[fits[candidates]]
    }
    attr(x, "candidate_rows") <- candidates
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
        package <- findit_package_priority(x$package[group])
        group <- group[package == min(package)]
        if (length(hints)) {
          size <- lengths(findit_rank_tokens(vapply(
            templates[group],
            function(t) t$stata,
            character(1)
          )))
          group <- group[size == min(size)]
        }
        group <- group[priority[group] == min(priority[group])]
        group[!duplicated(meaning[group])]
      }),
      use.names = FALSE
    )
    selected <- utils::head(selected, 5L)
    order <- c(selected, setdiff(seq_len(nrow(x)), selected))
    customized <- attr(x, "customized")
    ids <- attr(x, "entry_ids")
    x <- x[order, ]
    attr(x, "candidate_rows") <- match(candidates, order)
    attr(x, "entry_ids") <- ids[order]
    if (!is.null(customized)) {
      attr(x, "customized") <- customized[order]
    }
    attr(x, "default_rows") <- seq_along(selected)
    attr(x, "show") <- length(selected)
  }
  attr(x, "unmatched_hints") <- length(hints) > 0L &&
    (!length(score) || max(score[pool]) < length(hints))
  attr(x, "matched_hints") <- length(hints) > 0L &&
    length(unique(vapply(
      templates[candidates],
      function(t) {
        findit_render(t, rep("VAR", length(t$variables)))$stata
      },
      character(1)
    ))) ==
      1L
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
        # Function and option names are syntax, even when an operand shares
        # their spelling, as in id(id).
        if (startsWith(substring(code, ends[j] + 1L), "(")) {
          next
        }
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
      if (
        value %in% c(template$variables, template$strings, template$expressions)
      ) {
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
  c(
    list(
      "legacy-0001" = list(
        variables = c("command"),
        meaning = "findit",
        priority = 0L,
        hints = c("findit")
      ),
      "legacy-0002" = list(
        variables = c("command"),
        aliases = c(function_name = "command"),
        meaning = "help",
        priority = 0L,
        hints = c("help")
      ),
      "legacy-0003" = list(
        variables = c("keyword"),
        meaning = "search",
        priority = 0L,
        hints = c("search"),
        strings = c("keyword")
      ),
      "legacy-0004" = list(
        variables = character(),
        meaning = "clear",
        priority = 0L,
        hints = c("clear")
      ),
      "legacy-0005" = list(
        variables = character(),
        meaning = "pwd",
        priority = 0L,
        hints = c("pwd")
      ),
      "legacy-0006" = list(
        variables = character(),
        meaning = "cd",
        priority = 0L,
        hints = c("cd")
      ),
      "legacy-0007" = list(
        variables = character(),
        meaning = "dir",
        priority = 0L,
        hints = c("dir")
      ),
      "legacy-0008" = list(
        variables = c("path"),
        meaning = "global",
        priority = 0L,
        hints = c("global")
      ),
      "legacy-0009" = list(
        variables = character(),
        meaning = "display:0",
        priority = 0L,
        hints = c("display")
      ),
      "legacy-0010" = list(
        variables = character(),
        meaning = "ssc",
        priority = 0L,
        hints = c("ssc")
      ),
      "legacy-0011" = list(
        variables = character(),
        meaning = "net",
        priority = 0L,
        hints = c("from", "net")
      ),
      "legacy-0012" = list(
        variables = character(),
        meaning = "do",
        priority = 0L,
        hints = c("do")
      ),
      "legacy-0013" = list(
        variables = character(),
        meaning = "log",
        priority = 0L,
        hints = c("log")
      ),
      "legacy-0014" = list(
        variables = character(),
        meaning = "sysuse",
        priority = 0L,
        hints = c("sysuse")
      ),
      "legacy-0015" = list(
        variables = character(),
        meaning = "use",
        priority = 0L,
        hints = c("use")
      ),
      "legacy-0016" = list(
        variables = character(),
        meaning = "save",
        priority = 0L,
        hints = c("replace", "save")
      ),
      "legacy-0017" = list(
        variables = character(),
        meaning = "import:0",
        priority = 0L,
        hints = c("delimited", "import")
      ),
      "legacy-0018" = list(
        variables = character(),
        meaning = "import:1",
        priority = 0L,
        hints = c("excel", "firstrow", "import")
      ),
      "legacy-0019" = list(
        variables = character(),
        meaning = "import:2",
        priority = 0L,
        hints = c("import", "spss")
      ),
      "legacy-0020" = list(
        variables = character(),
        meaning = "export",
        priority = 0L,
        hints = c("delimited", "export")
      ),
      "legacy-0021" = list(
        variables = character(),
        meaning = "export",
        priority = 0L,
        hints = c("excel", "export")
      ),
      "legacy-0022" = list(
        variables = character(),
        meaning = "webuse",
        priority = 0L,
        hints = c("webuse")
      ),
      "legacy-0023" = list(
        variables = character(),
        meaning = "import:3",
        priority = 0L,
        hints = c("import", "sas")
      ),
      "legacy-0024" = list(
        variables = character(),
        meaning = "saveold",
        priority = 0L,
        hints = c("saveold", "version")
      ),
      "legacy-0025" = list(
        variables = character(),
        meaning = "browse",
        priority = 0L,
        hints = c("browse")
      ),
      "legacy-0026" = list(
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
      "legacy-0027" = list(
        variables = c("x", "y"),
        meaning = "browse",
        priority = 2L,
        hints = c("browse"),
        strings = c("x* y*")
      ),
      "legacy-0028" = list(
        variables = c("x"),
        meaning = "browse",
        priority = 2L,
        hints = c("browse"),
        strings = c("x")
      ),
      "legacy-0029" = list(
        variables = c("x"),
        meaning = "browse",
        priority = 2L,
        hints = c("browse"),
        strings = c("x")
      ),
      "legacy-0030" = list(
        variables = c("x"),
        meaning = "browse",
        priority = 2L,
        hints = c("browse"),
        strings = c("x")
      ),
      "legacy-0031" = list(
        variables = character(),
        meaning = "browse",
        priority = 2L,
        hints = c("browse", "in")
      ),
      "legacy-0032" = list(
        variables = character(),
        meaning = "browse",
        priority = 2L,
        hints = c("browse", "in")
      ),
      "legacy-0033" = list(
        variables = character(),
        meaning = "browse",
        priority = 2L,
        hints = c("browse", "in")
      ),
      "legacy-0034" = list(
        variables = c("x1", "x2"),
        meaning = "browse",
        priority = 2L,
        hints = c("browse", "if")
      ),
      "legacy-0035" = list(
        variables = character(),
        meaning = "list",
        priority = 0L,
        hints = c("list")
      ),
      "legacy-0036" = list(
        variables = c("x"),
        meaning = "list",
        priority = 1L,
        hints = c("list")
      ),
      "legacy-0037" = list(
        variables = character(),
        meaning = "describe",
        priority = 0L,
        hints = c("describe")
      ),
      "legacy-0038" = list(
        variables = character(),
        meaning = "ds",
        priority = 0L,
        hints = c("ds")
      ),
      "legacy-0039" = list(
        variables = character(),
        meaning = "codebook",
        priority = 0L,
        hints = c("codebook")
      ),
      "legacy-0040" = list(
        variables = c("income"),
        meaning = "lookfor",
        priority = 0L,
        hints = c("lookfor"),
        strings = c("income")
      ),
      "legacy-0041" = list(
        variables = c("x"),
        meaning = "tabulate",
        priority = 0L,
        hints = c("tabulate")
      ),
      "legacy-0042" = list(
        variables = c("x"),
        meaning = "fre",
        priority = 0L,
        hints = c("fre"),
        varlist = list(names = c("x"), stata = "x", r = "x", style = "args")
      ),
      "legacy-0043" = list(
        variables = c("x1", "x2"),
        meaning = "tabulate",
        priority = 1L,
        hints = c("tabulate")
      ),
      "legacy-0044" = list(
        variables = c("x", "n"),
        meaning = "tabulate",
        priority = 2L,
        hints = c("fweight", "tabulate")
      ),
      "legacy-0045" = list(
        variables = c("x", "w"),
        meaning = "tabulate",
        priority = 2L,
        hints = c("aweight", "tabulate")
      ),
      "legacy-0046" = list(
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
      "legacy-0047" = list(
        variables = c("x1", "x2"),
        meaning = "tab2",
        priority = 0L,
        hints = c("tab2")
      ),
      "legacy-0048" = list(
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
      "legacy-0049" = list(
        variables = character(),
        meaning = "summarize",
        priority = 0L,
        hints = c("summarize")
      ),
      "legacy-0050" = list(
        variables = c("x"),
        meaning = "summarize",
        priority = 1L,
        hints = c("summarize"),
        varlist = list(names = c("x"), stata = "x", r = "x", style = "args")
      ),
      "legacy-0051" = list(
        variables = c("x"),
        meaning = "summarize",
        priority = 2L,
        hints = c("detail", "summarize"),
        varlist = list(names = c("x"), stata = "x", r = "x", style = "args")
      ),
      "legacy-0052" = list(
        variables = c("group", "x"),
        meaning = "summarize",
        priority = 2L,
        hints = c("by", "summarize"),
        varlist = list(names = c("x"), stata = "x", r = "x", style = "args")
      ),
      "legacy-0053" = list(
        variables = c("x", "w"),
        meaning = "summarize",
        priority = 2L,
        hints = c("aweight", "summarize"),
        varlist = list(names = c("x"), stata = "x", r = "x", style = "args")
      ),
      "legacy-0054" = list(
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
      "legacy-0055" = list(
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
      "legacy-0056" = list(
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
      "legacy-0057" = list(
        variables = c("x", "group"),
        meaning = "ttest",
        priority = 0L,
        hints = c("by", "ttest")
      ),
      "legacy-0058" = list(
        variables = c("x1", "x2"),
        meaning = "tabulate",
        priority = 2L,
        hints = c("chi2", "tabulate")
      ),
      "legacy-0059" = list(
        variables = character(),
        meaning = "inspect",
        priority = 0L,
        hints = c("inspect")
      ),
      "legacy-0060" = list(
        variables = c("x"),
        meaning = "levelsof",
        priority = 0L,
        hints = c("levelsof")
      ),
      "legacy-0061" = list(
        variables = character(),
        meaning = "codebook",
        priority = 2L,
        hints = c("codebook", "compact")
      ),
      "legacy-0062" = list(
        variables = character(),
        meaning = "describe",
        priority = 2L,
        hints = c("describe")
      ),
      "legacy-0063" = list(
        variables = c("x"),
        meaning = "tabulate",
        priority = 2L,
        hints = c("missing", "tabulate")
      ),
      "legacy-0064" = list(
        variables = c("x", "y"),
        meaning = "tabulate",
        priority = 2L,
        hints = c("summarize", "tabulate")
      ),
      "legacy-0065" = list(
        variables = c("g", "x"),
        meaning = "tabulate",
        priority = 2L,
        hints = c("by", "tabulate")
      ),
      "legacy-0066" = list(
        variables = c("x1", "x2"),
        meaning = "tabulate",
        priority = 2L,
        hints = c("exact", "tabulate")
      ),
      "legacy-0067" = list(
        variables = c("x", "y"),
        meaning = "table",
        priority = 1L,
        hints = c("statistic", "table")
      ),
      "legacy-0068" = list(
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
      "legacy-0069" = list(
        variables = c("x"),
        meaning = "mean",
        priority = 0L,
        hints = c("mean"),
        varlist = list(names = c("x"), stata = "x", r = "x", style = "args")
      ),
      "legacy-0070" = list(
        variables = c("x"),
        meaning = "ci",
        priority = 0L,
        hints = c("ci")
      ),
      "legacy-0071" = list(
        variables = c("x"),
        meaning = "proportion",
        priority = 0L,
        hints = c("proportion")
      ),
      "legacy-0072" = list(
        variables = c("x"),
        meaning = "prtest",
        priority = 0L,
        hints = c("prtest")
      ),
      "legacy-0073" = list(
        variables = c("x", "group"),
        meaning = "ranksum",
        priority = 0L,
        hints = c("by", "ranksum")
      ),
      "legacy-0074" = list(
        variables = c("x", "y"),
        meaning = "signrank",
        priority = 0L,
        hints = c("signrank")
      ),
      "legacy-0075" = list(
        variables = c("x", "group"),
        meaning = "kwallis",
        priority = 0L,
        hints = c("by", "kwallis")
      ),
      "legacy-0076" = list(
        variables = c("x", "group"),
        meaning = "ksmirnov",
        priority = 0L,
        hints = c("by", "ksmirnov")
      ),
      "legacy-0077" = list(
        variables = c("y", "group"),
        meaning = "anova",
        priority = 0L,
        hints = c("anova")
      ),
      "legacy-0078" = list(
        variables = c("y", "group"),
        meaning = "oneway",
        priority = 0L,
        hints = c("oneway")
      ),
      "legacy-0079" = list(
        variables = c("x"),
        meaning = "swilk",
        priority = 0L,
        hints = c("swilk")
      ),
      "legacy-0080" = list(
        variables = c("x"),
        meaning = "sktest",
        priority = 0L,
        hints = c("sktest"),
        varlist = list(names = c("x"), stata = "x", r = "x", style = "args")
      ),
      "legacy-0081" = list(
        variables = c("x", "y"),
        meaning = "spearman",
        priority = 0L,
        hints = c("spearman")
      ),
      "legacy-0082" = list(
        variables = c("x", "y"),
        meaning = "ktau",
        priority = 0L,
        hints = c("ktau")
      ),
      "legacy-0083" = list(
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
      "legacy-0084" = list(
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
      "legacy-0085" = list(
        variables = c("x"),
        meaning = "stem",
        priority = 0L,
        hints = c("stem")
      ),
      "legacy-0086" = list(
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
      "legacy-0087" = list(
        variables = character(),
        meaning = "count",
        priority = 0L,
        hints = c("count")
      ),
      "legacy-0088" = list(
        variables = c("x"),
        meaning = "count",
        priority = 2L,
        hints = c("count")
      ),
      "legacy-0089" = list(
        variables = c("id", "wave"),
        meaning = "isid",
        priority = 0L,
        hints = c("isid")
      ),
      "legacy-0090" = list(
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
      "legacy-0091" = list(
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
      "legacy-0092" = list(
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
      "legacy-0093" = list(
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
      "legacy-0094" = list(
        variables = character(),
        meaning = "misstable:0",
        priority = 0L,
        hints = c("misstable", "summarize")
      ),
      "legacy-0095" = list(
        variables = character(),
        meaning = "misstable:1",
        priority = 0L,
        hints = c("misstable", "patterns")
      ),
      "legacy-0096" = list(
        variables = c("x"),
        meaning = "assert",
        priority = 0L,
        hints = c("assert")
      ),
      "legacy-0097" = list(
        variables = character(),
        meaning = "mdesc",
        priority = 0L,
        hints = c("mdesc")
      ),
      "legacy-0098" = list(
        variables = c("x"),
        meaning = "confirm",
        priority = 0L,
        hints = c("confirm"),
        strings = c("x")
      ),
      "legacy-0099" = list(
        variables = c("gender"),
        meaning = "label:0",
        priority = 0L,
        hints = c("define", "label")
      ),
      "legacy-0100" = list(
        variables = c("x"),
        meaning = "label",
        priority = 2L,
        hints = c("define", "label")
      ),
      "legacy-0101" = list(
        variables = c("x"),
        meaning = "label:1",
        priority = 0L,
        hints = c("label", "variable")
      ),
      "legacy-0102" = list(
        variables = c("x"),
        meaning = "label:2",
        priority = 0L,
        hints = c("label", "list")
      ),
      "legacy-0103" = list(
        variables = c("str_x", "x"),
        meaning = "encode",
        priority = 0L,
        hints = c("encode", "generate")
      ),
      "legacy-0104" = list(
        variables = c("x", "str_x"),
        meaning = "decode",
        priority = 0L,
        hints = c("decode", "generate")
      ),
      "legacy-0105" = list(
        variables = c("x", "yesno"),
        meaning = "label:3",
        priority = 0L,
        hints = c("label", "values")
      ),
      "legacy-0106" = list(
        variables = character(),
        meaning = "label:4",
        priority = 0L,
        hints = c("drop", "label")
      ),
      "legacy-0107" = list(
        variables = c("x"),
        meaning = "notes",
        priority = 0L,
        hints = c("notes")
      ),
      "legacy-0108" = list(
        variables = c("x2", "x"),
        meaning = "generate",
        priority = 0L,
        hints = c("generate")
      ),
      "legacy-0109" = list(
        variables = c("n"),
        meaning = "generate",
        priority = 1L,
        hints = c("generate")
      ),
      "legacy-0110" = list(
        variables = c("N"),
        meaning = "generate",
        priority = 1L,
        hints = c("generate")
      ),
      "legacy-0111" = list(
        variables = c("x2", "x"),
        meaning = "generate",
        priority = 2L,
        hints = c("generate")
      ),
      "legacy-0112" = list(
        variables = c("x2", "x"),
        meaning = "generate",
        priority = 2L,
        hints = c("generate")
      ),
      "legacy-0113" = list(
        variables = c("dummy", "x1", "x2"),
        meaning = "generate",
        priority = 2L,
        hints = c("generate")
      ),
      "legacy-0114" = list(
        variables = c("lag_x", "x"),
        meaning = "generate",
        priority = 2L,
        hints = c("generate")
      ),
      "legacy-0115" = list(
        variables = c("lead_x", "x"),
        meaning = "generate",
        priority = 2L,
        hints = c("generate")
      ),
      "legacy-0116" = list(
        variables = c("x2", "x"),
        meaning = "clonevar",
        priority = 0L,
        hints = c("clonevar")
      ),
      "legacy-0117" = list(
        variables = c("x"),
        meaning = "replace",
        priority = 0L,
        hints = c("replace")
      ),
      "legacy-0118" = list(
        variables = c("x"),
        meaning = "replace",
        priority = 2L,
        hints = c("replace")
      ),
      "legacy-0119" = list(
        variables = c("x"),
        meaning = "replace",
        priority = 2L,
        hints = c("replace")
      ),
      "legacy-0120" = list(
        variables = c("x"),
        derived = c(x_ = "x"),
        meaning = "tabulate",
        priority = 2L,
        hints = c("generate", "tabulate")
      ),
      "legacy-0121" = list(
        variables = c("x", "x3g"),
        meaning = "recode",
        priority = 0L,
        hints = c("generate", "recode")
      ),
      "legacy-0122" = list(
        variables = c("x"),
        meaning = "recode",
        priority = 2L,
        hints = c("recode")
      ),
      "legacy-0123" = list(
        variables = c("x"),
        meaning = "mvdecode",
        priority = 0L,
        hints = c("mv", "mvdecode")
      ),
      "legacy-0124" = list(
        variables = c("x"),
        meaning = "mvencode",
        priority = 0L,
        hints = c("mv", "mvencode")
      ),
      "legacy-0125" = list(
        variables = c("str_x", "num_x"),
        meaning = "destring",
        priority = 0L,
        hints = c("destring", "generate")
      ),
      "legacy-0126" = list(
        variables = c("num_x", "str_x"),
        meaning = "tostring",
        priority = 0L,
        hints = c("generate", "tostring")
      ),
      "legacy-0127" = list(
        variables = c("q", "x"),
        meaning = "xtile",
        priority = 0L,
        hints = c("nquantiles", "xtile")
      ),
      "legacy-0128" = list(
        variables = c("q", "x", "w"),
        meaning = "xtile",
        priority = 2L,
        hints = c("aweight", "nquantiles", "xtile")
      ),
      "legacy-0129" = list(
        variables = c("bins", "x"),
        meaning = "egen:0",
        priority = 0L,
        hints = c("cut", "egen", "group")
      ),
      "legacy-0130" = list(
        variables = c("bins", "x"),
        meaning = "egen",
        priority = 2L,
        hints = c("at", "cut", "egen")
      ),
      "legacy-0131" = list(
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
      "legacy-0132" = list(
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
      "legacy-0133" = list(
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
      "legacy-0134" = list(
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
      "legacy-0135" = list(
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
      "legacy-0136" = list(
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
      "legacy-0137" = list(
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
      "legacy-0138" = list(
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
      "legacy-0139" = list(
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
      "legacy-0140" = list(
        variables = c("x_avg", "x"),
        meaning = "egen:2",
        priority = 0L,
        hints = c("egen", "mean")
      ),
      "legacy-0141" = list(
        variables = c("group", "x_avg", "x"),
        meaning = "egen",
        priority = 2L,
        hints = c("by", "egen", "mean")
      ),
      "legacy-0142" = list(
        variables = c("id", "g1", "g2"),
        meaning = "egen:3",
        priority = 0L,
        hints = c("egen", "group")
      ),
      "legacy-0143" = list(
        variables = c("first", "group"),
        meaning = "egen:4",
        priority = 0L,
        hints = c("egen", "tag")
      ),
      "legacy-0144" = list(
        variables = c("z", "x"),
        meaning = "egen",
        priority = 2L,
        hints = c("egen", "std")
      ),
      "legacy-0145" = list(
        variables = c("p", "x"),
        meaning = "egen",
        priority = 2L,
        hints = c("egen", "pc")
      ),
      "legacy-0146" = list(
        variables = c("x"),
        derived = c(x_w = "x"),
        meaning = "winsor2",
        priority = 0L,
        hints = c("cuts", "winsor2")
      ),
      "legacy-0147" = list(
        variables = c("x", "x2"),
        meaning = "rename",
        priority = 0L,
        hints = c("rename")
      ),
      "legacy-0148" = list(
        variables = character(),
        meaning = "rename",
        priority = 2L,
        hints = c("lower", "rename")
      ),
      "legacy-0149" = list(
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
      "legacy-0150" = list(
        variables = c("n", "x", "total", "y", "group"),
        meaning = "collapse",
        priority = 2L,
        hints = c("by", "collapse", "count")
      ),
      "legacy-0151" = list(
        variables = c("r", "x"),
        meaning = "egen",
        priority = 2L,
        hints = c("egen", "rank")
      ),
      "legacy-0152" = list(
        variables = c("group", "tot", "x"),
        meaning = "egen",
        priority = 2L,
        hints = c("by", "egen", "total")
      ),
      "legacy-0153" = list(
        variables = c("group", "n", "x"),
        meaning = "egen",
        priority = 2L,
        hints = c("by", "count", "egen")
      ),
      "legacy-0154" = list(
        variables = c("group", "mx", "x"),
        meaning = "egen",
        priority = 2L,
        hints = c("by", "egen", "max")
      ),
      "legacy-0155" = list(
        variables = c("group", "mn", "x"),
        meaning = "egen",
        priority = 2L,
        hints = c("by", "egen", "min")
      ),
      "legacy-0156" = list(
        variables = c("group", "s", "x"),
        meaning = "egen",
        priority = 2L,
        hints = c("by", "egen", "sd")
      ),
      "legacy-0157" = list(
        variables = c("group", "med", "x"),
        meaning = "egen",
        priority = 2L,
        hints = c("by", "egen", "median")
      ),
      "legacy-0158" = list(
        variables = c("id", "a", "b"),
        meaning = "egen",
        priority = 2L,
        hints = c("concat", "egen", "punct")
      ),
      "legacy-0159" = list(
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
      "legacy-0160" = list(
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
      "legacy-0161" = list(
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
      "legacy-0162" = list(
        variables = c("s"),
        meaning = "egen",
        priority = 2L,
        hints = c("egen", "from", "seq", "to")
      ),
      "legacy-0163" = list(
        variables = character(),
        meaning = "pctile",
        priority = 0L,
        hints = c("nquantiles", "pctile")
      ),
      "legacy-0164" = list(
        variables = c("y", "x"),
        meaning = "cond",
        priority = 0L,
        hints = c("cond")
      ),
      "legacy-0165" = list(
        variables = c("y", "x"),
        meaning = "inlist",
        priority = 0L,
        hints = c("inlist")
      ),
      "legacy-0166" = list(
        variables = c("y", "x"),
        meaning = "inrange",
        priority = 0L,
        hints = c("inrange")
      ),
      "legacy-0167" = list(
        variables = c("m", "x"),
        meaning = "missing",
        priority = 0L,
        hints = c("missing")
      ),
      "legacy-0168" = list(
        variables = c("y", "x"),
        meaning = "round",
        priority = 0L,
        hints = c("round")
      ),
      "legacy-0169" = list(
        variables = c("y", "x"),
        meaning = "floor",
        priority = 0L,
        hints = c("floor")
      ),
      "legacy-0170" = list(
        variables = c("y", "x"),
        meaning = "ceil",
        priority = 0L,
        hints = c("ceil")
      ),
      "legacy-0171" = list(
        variables = c("y", "x"),
        meaning = "ln",
        priority = 0L,
        hints = c("ln")
      ),
      "legacy-0172" = list(
        variables = c("u"),
        meaning = "runiform",
        priority = 0L,
        hints = c("runiform")
      ),
      "legacy-0173" = list(
        variables = c("z"),
        meaning = "rnormal",
        priority = 0L,
        hints = c("rnormal")
      ),
      "legacy-0174" = list(
        variables = c("cs", "x"),
        meaning = "sum",
        priority = 0L,
        hints = c("sum")
      ),
      "legacy-0175" = list(
        variables = c("days", "d2", "d1"),
        meaning = "generate",
        priority = 2L,
        hints = c("generate")
      ),
      "legacy-0176" = list(
        variables = c("x"),
        meaning = "recast",
        priority = 0L,
        hints = c("recast")
      ),
      "legacy-0177" = list(
        variables = c("x"),
        derived = c(x_text = "x"),
        meaning = "format:0",
        priority = 0L,
        hints = c("format")
      ),
      "legacy-0178" = list(
        variables = c("a", "b", "c", "d"),
        meaning = "rename",
        priority = 1L,
        hints = c("rename")
      ),
      "legacy-0179" = list(
        variables = c("x"),
        meaning = "rename",
        priority = 2L,
        hints = c("rename", "upper"),
        strings = c("x")
      ),
      "legacy-0180" = list(
        variables = character(),
        meaning = "rename",
        priority = 2L,
        hints = c("rename")
      ),
      "legacy-0181" = list(
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
      "legacy-0182" = list(
        variables = c("x"),
        meaning = "keep",
        priority = 2L,
        hints = c("keep"),
        strings = c("x*")
      ),
      "legacy-0183" = list(
        variables = c("x"),
        meaning = "drop:0",
        priority = 0L,
        hints = c("drop"),
        varlist = list(names = c("x"), stata = "x", r = "-x", style = "exclude")
      ),
      "legacy-0184" = list(
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
      "legacy-0185" = list(
        variables = character(),
        meaning = "keep:2",
        priority = 0L,
        hints = c("in", "keep")
      ),
      "legacy-0186" = list(
        variables = character(),
        meaning = "keep",
        priority = 2L,
        hints = c("in", "keep")
      ),
      "legacy-0187" = list(
        variables = character(),
        meaning = "keep",
        priority = 2L,
        hints = c("in", "keep")
      ),
      "legacy-0188" = list(
        variables = c("x1", "x2"),
        meaning = "keep:1",
        priority = 0L,
        hints = c("if", "keep")
      ),
      "legacy-0189" = list(
        variables = c("x"),
        meaning = "keep",
        priority = 2L,
        hints = c("if", "keep", "missing")
      ),
      "legacy-0190" = list(
        variables = c("x"),
        meaning = "drop:1",
        priority = 0L,
        hints = c("drop", "if")
      ),
      "legacy-0191" = list(
        variables = character(),
        meaning = "duplicates:3",
        priority = 0L,
        hints = c("drop", "duplicates")
      ),
      "legacy-0192" = list(
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
      "legacy-0193" = list(
        variables = character(),
        meaning = "sample:0",
        priority = 0L,
        hints = c("count", "sample")
      ),
      "legacy-0194" = list(
        variables = character(),
        meaning = "sample:1",
        priority = 0L,
        hints = c("sample")
      ),
      "legacy-0195" = list(
        variables = character(),
        meaning = "drop:2",
        priority = 0L,
        hints = c("drop", "in")
      ),
      "legacy-0196" = list(
        variables = c("x"),
        meaning = "drop",
        priority = 2L,
        hints = c("drop", "if", "missing")
      ),
      "legacy-0197" = list(
        variables = c("x"),
        meaning = "keep",
        priority = 2L,
        hints = c("if", "inlist", "keep")
      ),
      "legacy-0198" = list(
        variables = c("x"),
        meaning = "keep",
        priority = 2L,
        hints = c("if", "inrange", "keep")
      ),
      "legacy-0199" = list(
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
      "legacy-0200" = list(
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
      "legacy-0201" = list(
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
      "legacy-0202" = list(
        variables = c("x1", "x2"),
        meaning = "gsort",
        priority = 0L,
        hints = c("gsort")
      ),
      "legacy-0203" = list(
        variables = character(),
        meaning = "append",
        priority = 0L,
        hints = c("append")
      ),
      "legacy-0204" = list(
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
      "legacy-0205" = list(
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
      "legacy-0206" = list(
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
      "legacy-0207" = list(
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
      "legacy-0208" = list(
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
      "legacy-0209" = list(
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
      "legacy-0210" = list(
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
      "legacy-0211" = list(
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
      "legacy-0212" = list(
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
      "legacy-0213" = list(
        variables = character(),
        meaning = "merge:3",
        priority = 0L,
        hints = c("1:1", "merge")
      ),
      "legacy-0214" = list(
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
      "legacy-0215" = list(
        variables = c("source"),
        meaning = "append",
        priority = 2L,
        hints = c("append", "generate"),
        strings = c("source")
      ),
      "legacy-0216" = list(
        variables = character(),
        meaning = "cross",
        priority = 0L,
        hints = c("cross")
      ),
      "legacy-0217" = list(
        variables = c("var", "id", "year"),
        meaning = "reshape:0",
        priority = 0L,
        hints = c("i", "j", "long", "reshape"),
        strings = c("var", "year")
      ),
      "legacy-0218" = list(
        variables = c("var", "id", "year"),
        meaning = "reshape:1",
        priority = 0L,
        hints = c("i", "j", "reshape", "wide"),
        strings = c("var")
      ),
      "legacy-0219" = list(
        variables = character(),
        meaning = "xpose",
        priority = 0L,
        hints = c("clear", "xpose")
      ),
      "legacy-0220" = list(
        variables = c("x", "y"),
        meaning = "input",
        priority = 1L,
        hints = c("input")
      ),
      "legacy-0221" = list(
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
      "legacy-0222" = list(
        variables = c("n"),
        meaning = "expand",
        priority = 0L,
        hints = c("expand")
      ),
      "legacy-0223" = list(
        variables = character(),
        meaning = "set:0",
        priority = 0L,
        hints = c("obs", "set")
      ),
      "legacy-0224" = list(
        variables = c("name"),
        meaning = "split",
        priority = 0L,
        hints = c("parse", "split")
      ),
      "legacy-0225" = list(
        variables = c("s", "name"),
        meaning = "substr",
        priority = 0L,
        hints = c("substr")
      ),
      "legacy-0226" = list(
        variables = c("n", "name"),
        meaning = "strlen",
        priority = 0L,
        hints = c("strlen")
      ),
      "legacy-0227" = list(
        variables = c("s", "name"),
        meaning = "upper",
        priority = 0L,
        hints = c("upper")
      ),
      "legacy-0228" = list(
        variables = c("s", "name"),
        meaning = "lower",
        priority = 0L,
        hints = c("lower")
      ),
      "legacy-0229" = list(
        variables = c("s", "name"),
        meaning = "strtrim",
        priority = 0L,
        hints = c("strtrim")
      ),
      "legacy-0230" = list(
        variables = c("s", "name"),
        meaning = "subinstr",
        priority = 0L,
        hints = c("subinstr")
      ),
      "legacy-0231" = list(
        variables = c("has", "name"),
        meaning = "strpos",
        priority = 0L,
        hints = c("strpos")
      ),
      "legacy-0232" = list(
        variables = c("has", "name"),
        meaning = "regexm",
        priority = 0L,
        hints = c("regexm")
      ),
      "legacy-0233" = list(
        variables = c("d", "s"),
        meaning = "date",
        priority = 0L,
        hints = c("date")
      ),
      "legacy-0234" = list(
        variables = c("result", "m", "d", "y"),
        output_aliases = c(d = "result"),
        meaning = "mdy",
        priority = 0L,
        hints = c("mdy")
      ),
      "legacy-0235" = list(
        variables = c("y", "d"),
        meaning = "year",
        priority = 0L,
        hints = c("year")
      ),
      "legacy-0236" = list(
        variables = c("m", "d"),
        meaning = "mofd",
        priority = 0L,
        hints = c("mofd")
      ),
      "legacy-0237" = list(
        variables = c("w", "name"),
        meaning = "word",
        priority = 0L,
        hints = c("word")
      ),
      "legacy-0238" = list(
        variables = c("n", "name"),
        meaning = "wordcount",
        priority = 0L,
        hints = c("wordcount")
      ),
      "legacy-0239" = list(
        variables = c("m", "name"),
        meaning = "strmatch",
        priority = 0L,
        hints = c("strmatch")
      ),
      "legacy-0240" = list(
        variables = c("s", "name"),
        meaning = "regexr",
        priority = 0L,
        hints = c("regexr")
      ),
      "legacy-0241" = list(
        variables = c("d", "name"),
        meaning = "regexs",
        priority = 0L,
        hints = c("regexm", "regexs")
      ),
      "legacy-0242" = list(
        variables = c("has", "name"),
        meaning = "ustrregexm",
        priority = 0L,
        hints = c("ustrregexm")
      ),
      "legacy-0243" = list(
        variables = c("s", "name"),
        meaning = "stritrim",
        priority = 0L,
        hints = c("stritrim")
      ),
      "legacy-0244" = list(
        variables = c("s", "name"),
        meaning = "strupper",
        priority = 0L,
        hints = c("strupper")
      ),
      "legacy-0245" = list(
        variables = c("s", "name"),
        meaning = "strlower",
        priority = 0L,
        hints = c("strlower")
      ),
      "legacy-0246" = list(
        variables = c("s", "name"),
        meaning = "strproper",
        priority = 0L,
        hints = c("strproper")
      ),
      "legacy-0247" = list(
        variables = c("s", "x"),
        meaning = "string",
        priority = 0L,
        hints = c("string")
      ),
      "legacy-0248" = list(
        variables = c("x", "s"),
        meaning = "real",
        priority = 0L,
        hints = c("real")
      ),
      "legacy-0249" = list(
        variables = c("n", "s"),
        meaning = "strtoname",
        priority = 0L,
        hints = c("strtoname")
      ),
      "legacy-0250" = list(
        variables = c("m", "d"),
        meaning = "month",
        priority = 0L,
        hints = c("month")
      ),
      "legacy-0251" = list(
        variables = c("dd", "d"),
        meaning = "day",
        priority = 0L,
        hints = c("day")
      ),
      "legacy-0252" = list(
        variables = c("w", "d"),
        meaning = "dow",
        priority = 0L,
        hints = c("dow")
      ),
      "legacy-0253" = list(
        variables = c("q", "d"),
        meaning = "qofd",
        priority = 0L,
        hints = c("qofd")
      ),
      "legacy-0254" = list(
        variables = c("d", "m"),
        meaning = "dofm",
        priority = 0L,
        hints = c("dofm")
      ),
      "legacy-0255" = list(
        variables = c("t", "s"),
        meaning = "clock",
        priority = 0L,
        hints = c("clock")
      ),
      "legacy-0256" = list(
        variables = c("d"),
        meaning = "format:1",
        priority = 0L,
        hints = c("format")
      ),
      "legacy-0257" = list(
        variables = character(),
        meaning = "display:1",
        priority = 0L,
        hints = c("c", "display")
      ),
      "legacy-0258" = list(
        variables = c("age", "d2", "d1"),
        meaning = "generate",
        priority = 2L,
        hints = c("generate")
      ),
      "legacy-0259" = list(
        variables = c("v1", "v5"),
        meaning = "foreach",
        priority = 0L,
        hints = c("foreach")
      ),
      "legacy-0260" = list(
        variables = character(),
        meaning = "forvalues:0",
        priority = 0L,
        hints = c("forvalues")
      ),
      "legacy-0261" = list(
        variables = character(),
        meaning = "forvalues:1",
        priority = 0L,
        hints = c("forvalues", "replace")
      ),
      "legacy-0262" = list(
        variables = character(),
        meaning = "capture",
        priority = 0L,
        hints = c("capture")
      ),
      "legacy-0263" = list(
        variables = character(),
        meaning = "quietly",
        priority = 0L,
        hints = c("quietly")
      ),
      "legacy-0265" = list(
        variables = character(),
        meaning = "set:1",
        priority = 0L,
        hints = c("seed", "set")
      ),
      "legacy-0266" = list(
        variables = character(),
        meaning = "preserve",
        priority = 0L,
        hints = c("preserve")
      ),
      "legacy-0267" = list(
        variables = c("vars", "x1", "x2", "x3"),
        meaning = "local",
        priority = 0L,
        hints = c("local"),
        strings = c("x1", "x2", "x3")
      ),
      "legacy-0268" = list(
        variables = c("a"),
        meaning = "scalar",
        priority = 0L,
        hints = c("scalar")
      ),
      "legacy-0269" = list(
        variables = c("A"),
        meaning = "matrix",
        priority = 0L,
        hints = c("matrix")
      ),
      "legacy-0272" = list(
        variables = c("x"),
        meaning = "display:2",
        priority = 0L,
        hints = c("display"),
        strings = c("x")
      ),
      "legacy-0273" = list(
        variables = c("x"),
        meaning = "display:3",
        priority = 0L,
        hints = c("display"),
        strings = c("x")
      ),
      "legacy-0274" = list(
        variables = c("i"),
        meaning = "while",
        priority = 0L,
        hints = c("while")
      ),
      "legacy-0275" = list(
        variables = c("x"),
        meaning = "if",
        priority = 0L,
        hints = c("if")
      ),
      "legacy-0276" = list(
        variables = character(),
        meaning = "program",
        priority = 0L,
        hints = c("program")
      ),
      "legacy-0277" = list(
        variables = c("f"),
        meaning = "tempfile",
        priority = 0L,
        hints = c("tempfile")
      ),
      "legacy-0280" = list(
        variables = character(),
        meaning = "frame",
        priority = 0L,
        hints = c("frame")
      ),
      "legacy-0281" = list(
        variables = character(),
        meaning = "which",
        priority = 0L,
        hints = c("which")
      ),
      "legacy-0282" = list(
        variables = character(),
        meaning = "ado",
        priority = 0L,
        hints = c("ado")
      ),
      "legacy-0284" = list(
        variables = character(),
        meaning = "cls",
        priority = 0L,
        hints = c("cls")
      ),
      "legacy-0286" = list(
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
      "legacy-0287" = list(
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
      "legacy-0288" = list(
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
      "legacy-0289" = list(
        variables = c("y", "group", "x1", "x2"),
        meaning = "regress",
        priority = 1L,
        hints = c("regress")
      ),
      "legacy-0290" = list(
        variables = c("y", "x", "wt"),
        meaning = "regress",
        priority = 2L,
        hints = c("pweight", "regress")
      ),
      "legacy-0291" = list(
        variables = c("y", "x", "id", "year"),
        meaning = "reghdfe",
        priority = 0L,
        hints = c("absorb", "reghdfe")
      ),
      "legacy-0292" = list(
        variables = c("y", "x"),
        meaning = "xtreg",
        priority = 0L,
        hints = c("fe", "xtreg")
      ),
      "legacy-0293" = list(
        variables = c("y", "x"),
        meaning = "xtreg",
        priority = 0L,
        hints = c("re", "xtreg"),
        strings = c("id", "year")
      ),
      "legacy-0294" = list(
        variables = c("y", "x1", "x2", "z"),
        meaning = "ivregress",
        priority = 0L,
        hints = c("ivregress")
      ),
      "legacy-0295" = list(
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
      "legacy-0296" = list(
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
      "legacy-0297" = list(
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
      "legacy-0298" = list(
        variables = character(),
        meaning = "margins:0",
        priority = 0L,
        hints = c("dydx", "margins")
      ),
      "legacy-0299" = list(
        variables = c("g"),
        meaning = "margins:1",
        priority = 0L,
        hints = c("margins"),
        strings = c("g")
      ),
      "legacy-0300" = list(
        variables = c("yhat"),
        meaning = "predict",
        priority = 0L,
        hints = c("predict")
      ),
      "legacy-0301" = list(
        variables = c("x1", "x2"),
        meaning = "test",
        priority = 0L,
        hints = c("test"),
        expressions = c("x1 = x2")
      ),
      "legacy-0302" = list(
        variables = c("m1"),
        meaning = "estimates:0",
        priority = 0L,
        hints = c("estimates", "store")
      ),
      "legacy-0303" = list(
        variables = c("m1", "m2"),
        meaning = "esttab",
        priority = 0L,
        hints = c("esttab")
      ),
      "legacy-0304" = list(
        variables = character(),
        meaning = "outreg2",
        priority = 0L,
        hints = c("outreg2")
      ),
      "legacy-0305" = list(
        variables = c("y", "x"),
        meaning = "glm",
        priority = 0L,
        hints = c("family", "glm"),
        varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
      ),
      "legacy-0306" = list(
        variables = c("y", "x"),
        meaning = "logit",
        priority = 2L,
        hints = c("logit", "or"),
        varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
      ),
      "legacy-0307" = list(
        variables = c("y", "x"),
        meaning = "logistic",
        priority = 0L,
        hints = c("logistic"),
        varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
      ),
      "legacy-0308" = list(
        variables = c("p"),
        meaning = "predict",
        priority = 2L,
        hints = c("pr", "predict")
      ),
      "legacy-0309" = list(
        variables = c("r"),
        meaning = "predict",
        priority = 2L,
        hints = c("predict", "residuals")
      ),
      "legacy-0310" = list(
        variables = c("y", "group"),
        meaning = "regress",
        priority = 1L,
        hints = c("regress")
      ),
      "legacy-0311" = list(
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
      "legacy-0312" = list(
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
      "legacy-0313" = list(
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
      "legacy-0314" = list(
        variables = c("y", "x"),
        meaning = "nbreg",
        priority = 0L,
        hints = c("nbreg"),
        varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
      ),
      "legacy-0315" = list(
        variables = c("y", "x", "id", "year"),
        meaning = "ppmlhdfe",
        priority = 0L,
        hints = c("absorb", "ppmlhdfe")
      ),
      "legacy-0316" = list(
        variables = c("y", "x"),
        meaning = "tobit",
        priority = 0L,
        hints = c("ll", "tobit"),
        varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
      ),
      "legacy-0317" = list(
        variables = c("y", "x"),
        meaning = "qreg",
        priority = 0L,
        hints = c("qreg"),
        varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
      ),
      "legacy-0319" = list(
        variables = c("y", "x", "id"),
        meaning = "areg",
        priority = 0L,
        hints = c("absorb", "areg"),
        varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
      ),
      "legacy-0320" = list(
        variables = c("y", "x"),
        meaning = "xtlogit",
        priority = 0L,
        hints = c("fe", "xtlogit"),
        varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
      ),
      "legacy-0321" = list(
        variables = c("y", "x"),
        meaning = "xtpoisson",
        priority = 0L,
        hints = c("fe", "xtpoisson"),
        varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
      ),
      "legacy-0322" = list(
        variables = c("y", "x", "id"),
        meaning = "mixed",
        priority = 0L,
        hints = c("mixed"),
        varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
      ),
      "legacy-0323" = list(
        variables = c("y", "x", "id"),
        meaning = "melogit",
        priority = 0L,
        hints = c("melogit"),
        varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
      ),
      "legacy-0324" = list(
        variables = c("y", "x", "s", "z"),
        meaning = "heckman",
        priority = 0L,
        hints = c("heckman", "select")
      ),
      "legacy-0325" = list(
        variables = c("y", "x1", "x2"),
        meaning = "sem",
        priority = 0L,
        hints = c("sem"),
        expressions = c("y ~ x1 + x2")
      ),
      "legacy-0326" = list(
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
      "legacy-0327" = list(
        variables = character(),
        meaning = "bootstrap",
        priority = 0L,
        hints = c("bootstrap", "reps")
      ),
      "legacy-0329" = list(
        variables = c("x1", "x2"),
        meaning = "lincom",
        priority = 0L,
        hints = c("lincom"),
        expressions = c("x1 - x2 = 0")
      ),
      "legacy-0330" = list(
        variables = c("x1", "x2"),
        meaning = "nlcom",
        priority = 0L,
        hints = c("nlcom"),
        expressions = c("x1 / x2 = 0")
      ),
      "legacy-0331" = list(
        variables = c("m1", "m2"),
        meaning = "lrtest",
        priority = 0L,
        hints = c("lrtest")
      ),
      "legacy-0332" = list(
        variables = character(),
        meaning = "estat:0",
        priority = 0L,
        hints = c("estat", "ic")
      ),
      "legacy-0333" = list(
        variables = character(),
        meaning = "estat:1",
        priority = 0L,
        hints = c("estat", "vce")
      ),
      "legacy-0334" = list(
        variables = character(),
        meaning = "estat:2",
        priority = 0L,
        hints = c("estat", "hettest")
      ),
      "legacy-0335" = list(
        variables = character(),
        meaning = "estat:3",
        priority = 0L,
        hints = c("estat", "ovtest")
      ),
      "legacy-0336" = list(
        variables = character(),
        meaning = "vif",
        priority = 0L,
        hints = c("vif")
      ),
      "legacy-0337" = list(
        variables = character(),
        meaning = "rvfplot",
        priority = 0L,
        hints = c("rvfplot")
      ),
      "legacy-0338" = list(
        variables = character(),
        meaning = "avplots",
        priority = 0L,
        hints = c("avplots")
      ),
      "legacy-0340" = list(
        variables = c("m1", "m2"),
        meaning = "estimates:1",
        priority = 0L,
        hints = c("estimates", "table")
      ),
      "legacy-0341" = list(
        variables = c("m1", "y", "x"),
        meaning = "eststo",
        priority = 0L,
        hints = c("eststo")
      ),
      "legacy-0342" = list(
        variables = character(),
        meaning = "etable",
        priority = 0L,
        hints = c("etable")
      ),
      "legacy-0348" = list(
        variables = c("y", "treated", "id", "year"),
        meaning = "didregress",
        priority = 0L,
        hints = c("didregress", "group", "time")
      ),
      "legacy-0350" = list(
        variables = c("y", "x"),
        meaning = "rdrobust",
        priority = 0L,
        hints = c("c", "rdrobust")
      ),
      "legacy-0353" = list(
        variables = c("y", "x"),
        meaning = "xtabond",
        priority = 0L,
        hints = c("xtabond"),
        strings = c("id", "year")
      ),
      "legacy-0354" = list(
        variables = character(),
        meaning = "mi:0",
        priority = 0L,
        hints = c("chained", "impute", "mi")
      ),
      "legacy-0355" = list(
        variables = c("y", "x"),
        meaning = "mi:1",
        priority = 0L,
        hints = c("estimate", "mi"),
        varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
      ),
      "legacy-0356" = list(
        variables = c("id", "year"),
        meaning = "xtset",
        priority = 0L,
        hints = c("xtset")
      ),
      "legacy-0357" = list(
        variables = c("year"),
        meaning = "tsset",
        priority = 0L,
        hints = c("tsset")
      ),
      "legacy-0358" = list(
        variables = c("lag_x", "x"),
        meaning = "l.",
        priority = 0L,
        hints = c("l.")
      ),
      "legacy-0359" = list(
        variables = c("lead_x", "x"),
        meaning = "f.",
        priority = 0L,
        hints = c("f.")
      ),
      "legacy-0360" = list(
        variables = c("d_x", "x"),
        meaning = "d.",
        priority = 0L,
        hints = c("d.")
      ),
      "legacy-0361" = list(
        variables = character(),
        meaning = "tsfill",
        priority = 0L,
        hints = c("tsfill")
      ),
      "legacy-0362" = list(
        variables = c("lag2_x", "x"),
        meaning = "l.",
        priority = 2L,
        hints = c("l.")
      ),
      "legacy-0365" = list(
        variables = c("y"),
        meaning = "tsline",
        priority = 0L,
        hints = c("tsline")
      ),
      "legacy-0366" = list(
        variables = c("y"),
        meaning = "xtline",
        priority = 0L,
        hints = c("xtline")
      ),
      "legacy-0367" = list(
        variables = c("y"),
        meaning = "arima",
        priority = 0L,
        hints = c("ar", "arima")
      ),
      "legacy-0368" = list(
        variables = c("x"),
        meaning = "carryforward",
        priority = 0L,
        hints = c("carryforward", "replace"),
        varlist = list(names = c("x"), stata = "x", r = "x", style = "args")
      ),
      "legacy-0369" = list(
        variables = c("time", "died"),
        meaning = "stset",
        priority = 0L,
        hints = c("failure", "stset")
      ),
      "legacy-0370" = list(
        variables = character(),
        meaning = "sts:0",
        priority = 0L,
        hints = c("graph", "sts")
      ),
      "legacy-0371" = list(
        variables = c("group"),
        meaning = "sts:1",
        priority = 0L,
        hints = c("sts", "test")
      ),
      "legacy-0373" = list(
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
      "legacy-0374" = list(
        variables = c("x"),
        meaning = "streg",
        priority = 0L,
        hints = c("distribution", "streg")
      ),
      "legacy-0375" = list(
        variables = c("psu", "wt", "stratum"),
        meaning = "svyset",
        priority = 0L,
        hints = c("pweight", "strata", "svyset")
      ),
      "legacy-0376" = list(
        variables = c("x"),
        meaning = "svy:0",
        priority = 0L,
        hints = c("mean", "svy")
      ),
      "legacy-0377" = list(
        variables = c("x"),
        meaning = "svy:1",
        priority = 0L,
        hints = c("svy", "tabulate")
      ),
      "legacy-0378" = list(
        variables = c("y", "x"),
        meaning = "svy:2",
        priority = 0L,
        hints = c("regress", "svy"),
        varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
      ),
      "legacy-0379" = list(
        variables = c("x", "g"),
        meaning = "svy",
        priority = 2L,
        hints = c("mean", "over", "svy")
      ),
      "legacy-0380" = list(
        variables = c("rural", "x"),
        meaning = "svy",
        priority = 2L,
        hints = c("mean", "subpop", "svy")
      ),
      "legacy-0381" = list(
        variables = c("x"),
        meaning = "svy",
        priority = 2L,
        hints = c("proportion", "svy")
      ),
      "legacy-0382" = list(
        variables = c("y", "x"),
        meaning = "svy:3",
        priority = 0L,
        hints = c("logit", "svy"),
        varlist = list(names = c("x"), stata = "x", r = "x", style = "formula")
      ),
      "legacy-0383" = list(
        variables = character(),
        meaning = "svydescribe",
        priority = 0L,
        hints = c("svydescribe")
      ),
      "legacy-0384" = list(
        variables = c("x"),
        meaning = "histogram",
        priority = 0L,
        hints = c("histogram")
      ),
      "legacy-0385" = list(
        variables = c("x"),
        meaning = "kdensity",
        priority = 0L,
        hints = c("kdensity")
      ),
      "legacy-0386" = list(
        variables = c("y", "x"),
        meaning = "scatter",
        priority = 0L,
        hints = c("scatter")
      ),
      "legacy-0387" = list(
        variables = c("y", "x"),
        meaning = "twoway:0",
        priority = 0L,
        hints = c("twoway")
      ),
      "legacy-0388" = list(
        variables = c("y", "x"),
        meaning = "line",
        priority = 0L,
        hints = c("line")
      ),
      "legacy-0389" = list(
        variables = c("y", "group"),
        meaning = "graph:0",
        priority = 0L,
        hints = c("bar", "graph", "over")
      ),
      "legacy-0390" = list(
        variables = c("y", "group"),
        meaning = "graph:1",
        priority = 0L,
        hints = c("box", "graph", "over")
      ),
      "legacy-0391" = list(
        variables = character(),
        meaning = "graph:2",
        priority = 0L,
        hints = c("export", "graph")
      ),
      "legacy-0393" = list(
        variables = character(),
        meaning = "coefplot",
        priority = 0L,
        hints = c("coefplot")
      ),
      "legacy-0394" = list(
        variables = c("x"),
        meaning = "graph:3",
        priority = 0L,
        hints = c("bar", "count", "graph", "over")
      ),
      "legacy-0395" = list(
        variables = c("y", "group"),
        meaning = "graph",
        priority = 2L,
        hints = c("graph", "hbar", "over")
      ),
      "legacy-0396" = list(
        variables = c("y", "group"),
        meaning = "graph",
        priority = 2L,
        hints = c("dot", "graph", "over")
      ),
      "legacy-0397" = list(
        variables = c("y", "group"),
        meaning = "graph",
        priority = 2L,
        hints = c("graph", "hbox", "over")
      ),
      "legacy-0398" = list(
        variables = c("group"),
        meaning = "graph:4",
        priority = 0L,
        hints = c("graph", "over")
      ),
      "legacy-0399" = list(
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
      "legacy-0400" = list(
        variables = character(),
        meaning = "graph",
        priority = 2L,
        hints = c("combine", "graph")
      ),
      "legacy-0401" = list(
        variables = character(),
        meaning = "graph",
        priority = 2L,
        hints = c("graph", "save")
      ),
      "legacy-0402" = list(
        variables = c("y", "x"),
        meaning = "twoway:1",
        priority = 0L,
        hints = c("connected", "twoway")
      ),
      "legacy-0403" = list(
        variables = c("y", "x"),
        meaning = "twoway:2",
        priority = 0L,
        hints = c("area", "twoway")
      ),
      "legacy-0404" = list(
        variables = c("y", "x"),
        meaning = "twoway",
        priority = 2L,
        hints = c("lfitci", "twoway")
      ),
      "legacy-0405" = list(
        variables = c("y", "x"),
        meaning = "twoway",
        priority = 2L,
        hints = c("qfit", "twoway"),
        protect = c("formula = y ~ poly(x, 2)")
      ),
      "legacy-0406" = list(
        variables = c("hi", "lo", "x"),
        meaning = "twoway:3",
        priority = 0L,
        hints = c("rcap", "twoway")
      ),
      "legacy-0407" = list(
        variables = c("hi", "lo", "x"),
        meaning = "twoway:4",
        priority = 0L,
        hints = c("rarea", "twoway")
      ),
      "legacy-0408" = list(
        variables = c("y", "x", "group"),
        meaning = "twoway",
        priority = 2L,
        hints = c("by", "scatter", "twoway")
      ),
      "legacy-0409" = list(
        variables = c("y", "x", "g"),
        meaning = "twoway",
        priority = 2L,
        hints = c("twoway")
      ),
      "legacy-0410" = list(
        variables = c("y", "x"),
        meaning = "lowess",
        priority = 0L,
        hints = c("lowess")
      ),
      "legacy-0411" = list(
        variables = c("y", "x", "name"),
        meaning = "scatter",
        priority = 2L,
        hints = c("mlabel", "scatter")
      ),
      "legacy-0412" = list(
        variables = c("y", "x"),
        meaning = "scatter",
        priority = 2L,
        hints = c("scatter", "xline")
      ),
      "legacy-0413" = list(
        variables = c("y", "group"),
        meaning = "vioplot",
        priority = 0L,
        hints = c("over", "vioplot")
      ),
      "legacy-0414" = list(
        variables = c("x"),
        meaning = "qnorm",
        priority = 0L,
        hints = c("qnorm")
      ),
      "legacy-0415" = list(
        variables = character(),
        meaning = "set:3",
        priority = 0L,
        hints = c("scheme", "set")
      )
    ),
    findit_reference_specs()
  )
}
