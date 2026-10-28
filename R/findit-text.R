# Stata text is data. Match only catalogue syntax whose variable sites are known.
findit_text_tokens <- function(text) {
  pattern <- '"(?:[^"\\\\]|\\\\.)*"|[[:alpha:]_][[:alnum:]_]*|[0-9]+|[^[:space:]]'
  regmatches(text, gregexpr(pattern, text, perl = TRUE))[[1L]]
}

findit_text_variables <- function(words) {
  all(grepl("^[[:alpha:]_][[:alnum:]_]*$", words)) &&
    !any(words %in% c("if", "in", "using", "by", "bysort"))
}

findit_text_escape <- function(tokens) {
  vapply(
    strsplit(tokens, "", fixed = TRUE),
    function(chars) {
      paste0(
        ifelse(
          chars %in%
            c(
              "\\",
              ".",
              "^",
              "$",
              "|",
              "(",
              ")",
              "[",
              "]",
              "{",
              "}",
              "*",
              "+",
              "?"
            ),
          paste0("\\", chars),
          chars
        ),
        collapse = ""
      )
    },
    character(1),
    USE.NAMES = FALSE
  )
}

findit_text_pattern <- function(template) {
  sites <- template$sites$stata
  if (
    !length(sites) ||
      any(vapply(
        sites,
        function(s) {
          !s$kind %in% c("name", "list")
        },
        logical(1)
      ))
  ) {
    return(NULL)
  }
  sites <- sites[order(vapply(sites, function(s) s$start, integer(1)))]
  name <- "[[:alpha:]_][[:alnum:]_]*"
  parts <- character()
  cursor <- 1L
  for (site in sites) {
    if (site$start < cursor) {
      return(NULL)
    }
    literal <- substr(template$stata, cursor, site$start - 1L)
    parts <- c(parts, findit_text_escape(findit_text_tokens(literal)))
    capture <- if (site$kind == "list") {
      paste0("(", name, "(?:\r", name, ")*)")
    } else {
      paste0("(", name, ")")
    }
    parts <- c(parts, capture)
    cursor <- site$end + 1L
  }
  parts <- c(
    parts,
    findit_text_escape(findit_text_tokens(
      substring(template$stata, cursor)
    ))
  )
  list(pattern = paste0("^", paste(parts, collapse = "\r"), "$"), sites = sites)
}

findit_text_match <- function(text, template, pattern) {
  if (is.null(pattern)) {
    return(NULL)
  }
  hit <- regmatches(text, regexec(pattern$pattern, text, perl = TRUE))[[1L]]
  if (!length(hit)) {
    return(NULL)
  }
  values <- rep(list(NULL), length(template$variables))
  for (i in seq_along(pattern$sites)) {
    site <- pattern$sites[[i]]
    slots <- if (site$kind == "list") {
      match(template$varlist$names, template$variables)
    } else {
      site$slot
    }
    value <- strsplit(hit[i + 1L], "\r", fixed = TRUE)[[1L]]
    if (site$kind == "list") {
      # The renderer expands the first list slot to all supplied list names.
      value <- list(value)
      slots <- slots[1L]
    } else {
      value <- list(value)
    }
    if (!is.null(values[[slots]]) && !identical(values[[slots]], value[[1L]])) {
      return(NULL)
    }
    values[slots] <- value
  }
  required <- seq_along(values)
  if (!is.null(template$varlist)) {
    positions <- match(template$varlist$names, template$variables)
    required <- setdiff(required, positions[-1L])
  }
  if (any(lengths(values[required]) == 0L)) {
    return(NULL)
  }
  variables <- unlist(values, use.names = FALSE)
  if (!findit_text_variables(variables)) {
    return(NULL)
  }
  variables
}

findit_text_input <- function(query, arguments) {
  unchanged <- list(
    query = query,
    arguments = arguments,
    rows = NULL,
    generic = FALSE
  )
  if (is.null(query) || !grepl("[[:space:],]", trimws(query))) {
    return(unchanged)
  }
  tokens <- findit_text_tokens(trimws(query))
  if (
    length(tokens) >= 3L && !grepl("[=,:()\"]", query) && findit_question(query)
  ) {
    return(unchanged)
  }
  command <- tokens[1L]
  entries <- findit_entries()
  commands <- unique(entries$command[findit_command_hit(
    tolower(tokens[1L]),
    entries
  )])
  if (length(commands) != 1L) {
    return(unchanged)
  }
  templates <- findit_templates()[entries$id[entries$command == commands]]
  known <- unique(unlist(lapply(templates, function(t) t$hints)))
  is_hint <- function(word) {
    any(tolower(known) == tolower(word)) ||
      (nchar(word) >= 3L && any(startsWith(tolower(known), tolower(word))))
  }
  tokens[1L] <- commands
  comma <- which(tokens == ",")
  boundary <- if (length(comma)) comma[1L] else length(tokens) + 1L
  variables <- tokens[seq_len(boundary - 1L)][-1L]
  if (!length(variables)) {
    return(unchanged)
  }
  options <- if (length(comma) && boundary < length(tokens)) {
    tokens[seq.int(boundary + 1L, length(tokens))]
  } else {
    character()
  }
  names_only <- function(words) {
    all(grepl("^[[:alpha:]_][[:alnum:]_]*$", words))
  }
  # With explicit comma operands, keep the established syntax/hint query.
  hint_query <- length(arguments) &&
    length(variables) &&
    all(vapply(variables, is_hint, logical(1)))
  if (hint_query) {
    return(unchanged)
  }
  simple <- length(comma) <= 1L &&
    names_only(c(variables, options)) &&
    findit_text_variables(variables) &&
    all(vapply(options, is_hint, logical(1)))
  if (simple) {
    plain <- vapply(
      templates,
      function(t) {
        words <- findit_text_tokens(t$stata)
        names_only(words) &&
          words[1L] == commands &&
          all(words[-1L] %in% c(t$variables, t$varlist$names)) &&
          findit_template_fits(t, length(variables))
      },
      logical(1)
    )
    if (any(plain)) {
      return(list(
        query = command,
        arguments = c(
          as.list(variables),
          lapply(options, rlang::sym),
          arguments
        ),
        rows = NULL,
        generic = FALSE
      ))
    }
  }
  if (is.null(findit_cache$text_patterns)) {
    findit_cache$text_patterns <- lapply(
      findit_templates(),
      findit_text_pattern
    )
  }
  text <- paste(tokens, collapse = "\r")
  matches <- lapply(names(templates), function(id) {
    findit_text_match(text, templates[[id]], findit_cache$text_patterns[[id]])
  })
  names(matches) <- names(templates)
  matches <- matches[lengths(matches) > 0L]
  if (
    length(matches) &&
      all(vapply(matches, identical, logical(1), matches[[1L]]))
  ) {
    hints <- unique(unlist(lapply(templates[names(matches)], function(t) {
      t$hints
    })))
    hints <- setdiff(hints, commands)
    return(list(
      query = command,
      arguments = c(
        as.list(matches[[1L]]),
        lapply(hints, rlang::sym),
        arguments
      ),
      rows = names(matches),
      generic = FALSE
    ))
  }
  # Hint-only searches remain searches; unfamiliar concrete syntax stays intact.
  unchanged$generic <- length(comma) > 0L ||
    !names_only(variables) ||
    !all(vapply(variables, is_hint, logical(1)))
  unchanged
}
