#' Find R equivalents of Stata commands
#'
#' `findit()` looks up Stata commands and their R equivalents, including
#' functions from tidystata and other packages. It also supports reverse lookup
#' from R functions, keyword searches, and plain-language questions. Omit the
#' query to browse all entries.
#'
#' @param command A Stata command, R function, or search phrase. Supply a bare
#'   name (`findit(reg)`, `findit(left_join)`) or a quoted string for full
#'   syntax (`findit("merge 1:1 id, keep(match)")`). R function names may
#'   include `()` or a namespace prefix. Use `!!cmd` to look up a string stored
#'   in `cmd`. Defaults to `NULL` (all entries).
#'
#' @param ... Optional variable names or command hints, captured without
#'   evaluation. Names customize examples in Stata operand order, while hints
#'   prioritize examples (`findit(tab, gen)`). Hints accept exact or unambiguous
#'   prefixes of at least three letters. Quote names that conflict with hints
#'   (`findit(tab, "gen")`). Use `!!` for stored strings. Only unnamed names and
#'   strings are accepted.
#'
#' @returns A tibble of class `tidystata_findit` with one row per matching Stata
#'   idiom and five columns: `match` (match type), `stata` (Stata code), `r`
#'   (equivalent R code), `package` (primary R package), and `task`
#'   (description). The returned object contains every selected match, including
#'   any hidden by printing. If nothing matches, a zero-row result with the same
#'   columns and class is returned invisibly with an explanatory message.
#'
#' @details
#' **Matching**
#'
#' A clear specific query returns one preferred answer; ambiguous queries
#' return up to ten relevant candidates. Bare Stata commands return the
#' complete command family, and an omitted query returns the whole reference.
#'
#' * Stata abbreviations are recognized (`reg`, `regr`, `regress`), while R
#'   functions require their full names. Exact-case matches take priority.
#'   Shared names, such as `log`, show both Stata and R interpretations.
#' * Stata command matches appear before R function matches. Keyword searches
#'   are used when neither matches. Additional syntax and hints refine the
#'   ranking. Within the relevant operation, tidystata functions take priority,
#'   followed by tidyverse functions, then other packages or base R.
#'   `by` and `bysort` prefixes prioritize grouped operations.
#' * Plain-language questions match curated keywords and synonyms in English
#'   or Chinese.
#'
#' **Output**
#'
#' * Results print as readable Stata/R code pairs. A single clear match is shown
#'   alone; otherwise, up to five representative examples appear. Bare commands
#'   browse their whole family; specific queries omit unrelated family entries.
#'   Footers distinguish hidden relevant candidates from broader family examples
#'   and report when the ten-candidate limit applies. The print method's `n`
#'   argument sets how many matches are printed; use
#'   `print(n = Inf)` to display all matches.
#' * The `match` column identifies the lookup type: `"stata"`, `"r"`,
#'   `"keyword"`, `"nearest"`, or `"all"`.
#' * Supplied variable names customize compatible examples. Unresolved
#'   placeholders and unsupported combinations are explained in notes.
#'
#' **Notes**
#'
#' * Quote multiword Stata syntax, reserved words (`"if"`), and names that are
#'   not valid R symbols (`"_n"`).
#' * Lookup works offline. External packages such as fixest, modelsummary, and
#'   srvyr are needed only when running their examples.
#' * Chinese descriptions follow R's language settings. Use `Sys.setenv(LANGUAGE
#'   = "en")` to switch to English.
#' * The reference is curated, not a parser or executor for arbitrary Stata
#'   programs. See the "Coming from Stata" articles for further guidance.
#'
#' @concept Stata
#' @concept Stata to R
#' @concept cheat sheet
#' @concept search
#' @concept help
#' @export
#'
#' @examples
#' findit(reg)
#'
#' findit(tab, gen)
#'
#' findit(tab, sex, region)
#'
#' findit("merge 1:1 id, keep(match)")
#'
#' findit("how do I remove duplicate rows")
#'
#' findit(left_join)
#'
#' # Filter the complete reference
#' entries <- findit()
#' entries |>
#'   dplyr::filter(package == "tidystata")
findit <- function(command = NULL, ...) {
  expr <- rlang::enexpr(command)
  extra <- rlang::enexprs(..., .ignore_empty = "none")
  findit_check_arguments(expr, extra)
  query <- findit_query(expr)
  found <- withVisible(findit_lookup(query))
  if (length(extra)) {
    found$value <- findit_customize(found$value, extra)
  }
  found$value <- findit_select(found$value, query, length(extra) > 0L)
  # The call as typed, so the printed hint can be run as it stands.
  attr(found$value, "input") <- paste0(
    "findit(",
    if (!is.null(expr)) {
      paste(
        vapply(
          c(list(expr), extra),
          function(x) {
            paste(
              deparse(x, width.cutoff = 500L, backtick = TRUE),
              collapse = ""
            )
          },
          character(1)
        ),
        collapse = ", "
      )
    },
    ")"
  )
  if (found$visible) found$value else invisible(found$value)
}

findit_lookup <- function(query) {
  entries <- findit_entries()
  if (is.null(query)) {
    return(findit_result(entries, "all"))
  }

  original <- gsub("\\s+", " ", trimws(query))
  prefix <- "^by(s|so|sor|sort)? [^:]*: *"
  grouped <- grepl(prefix, original, ignore.case = TRUE)
  words <- strsplit(sub(prefix, "", original, ignore.case = TRUE), " ")[[1]]
  first <- sub("[,:].*$", "", words[1])
  word <- tolower(first)
  # Taken before the colon is cut, so `dplyr::left_join()` keeps its name.
  name <- sub(":$", "", sub(",.*$", "", words[1]))
  namespace <- if (grepl("::", name, fixed = TRUE)) {
    sub("::.*$", "", name)
  }
  name <- sub("^.*::", "", sub("[(][)]$", "", name))
  terms <- unique(c(
    if (grouped) "by",
    findit_rank_tokens(paste(words[-1], collapse = " "))[[1L]]
  ))

  gap <- findit_gaps()
  gap <- gap[
    tolower(gap$query) == tolower(original) |
      (!grepl(" ", gap$query, fixed = TRUE) & tolower(gap$query) == word),
    ,
    drop = FALSE
  ]
  if (nrow(gap)) {
    detail <- if (findit_chinese()) gap$detail_zh else gap$detail
    rlang::inform(paste0(
      "No curated R equivalent for \"",
      original,
      "\". ",
      detail[1L]
    ))
    return(invisible(findit_result(entries[0L, ], "keyword")))
  }
  stata_hit <- if (is.null(namespace)) {
    findit_command_hit(word, entries)
  } else {
    rep(FALSE, nrow(entries))
  }
  functions <- findit_function_hit(name, entries, namespace)
  r_hit <- !stata_hit &
    vapply(entries$functions, function(f) any(functions %in% f), logical(1))
  if (!is.null(namespace)) {
    r_hit <- r_hit & findit_namespace_hit(namespace, functions, entries)
  }
  if (any(stata_hit) || length(functions)) {
    found <- rbind(
      findit_rank(entries[stata_hit, ], terms, "stata"),
      findit_rank(entries[r_hit, ], terms, "r"),
      make.row.names = FALSE
    )
    show <- if (
      findit_single_best(found, terms) &&
        !findit_ambiguous_option(original, found$stata)
    ) {
      1L
    }
    leaders <- if (length(terms) && nrow(found)) {
      which(
        found$.score == found$.score[1] & found$.context == found$.context[1]
      )
    }
    found <- found[setdiff(names(found), c(".score", ".extra", ".context"))]
    # A plain question that starts with a command word, such as "count how
    # many people in each group", gets the closest entries first.
    if (findit_plain(original, words, found)) {
      nearest <- findit_nearest(original, entries)
      found <- rbind(nearest, found[!found$id %in% nearest$id, ])
      attr(found, "relevance") <- attr(nearest, "relevance")
      attr(found, "candidate_count") <- attr(nearest, "candidate_count")
      show <- NULL
      leaders <- NULL
    }
    attr(found, "leaders") <- leaders
    result <- findit_result(
      found,
      functions = functions,
      query = original,
      show = show,
      namespace = namespace
    )
    options <- findit_options(original)
    if (length(options) && any(stata_hit)) {
      recorded <- lapply(entries$stata[stata_hit], findit_options)
      represented <- vapply(
        recorded,
        function(known) {
          all(vapply(
            options,
            function(option) {
              option %in%
                known ||
                (nchar(option) >= 3L && any(startsWith(known, option)))
            },
            logical(1)
          ))
        },
        logical(1)
      )
      if (!any(represented)) {
        rlang::inform(paste0(
          "The supplied options are not represented together in a curated ",
          "example; showing related examples."
        ))
        attr(result, "unrepresented_options") <- TRUE
      }
    }
    return(result)
  }

  if (!is.null(namespace)) {
    rlang::inform(findit_no_match(query, first, character()))
    return(invisible(findit_result(entries[0L, ], "keyword")))
  }

  keyword <- findit_keyword(original, entries)
  if (any(keyword)) {
    found <- entries[keyword, ]
    found <- found[order(findit_package_priority(found$package)), ]
    return(findit_result(found, "keyword"))
  }

  nearest <- findit_nearest(original, entries)
  if (nrow(nearest)) {
    return(findit_result(nearest, query = original))
  }

  candidates <- unique(c(entries$command, findit_functions()$`function`))
  rlang::inform(findit_no_match(query, first, candidates))
  invisible(findit_result(entries[0L, ], "keyword"))
}

# A question in plain words: three or more words, no Stata syntax, and none of
# the words after the first appear in the Stata code of the entries found.
findit_plain <- function(original, words, found) {
  if (length(words) < 3L || grepl("[=,:()\"]", original)) {
    return(FALSE)
  }
  phrases <- paste0(
    "\\b(how (do|can|many)|values with|data into|the data|statistics of|",
    "of all|only (rows|columns)|a (bar|line|scatter) chart)\\b"
  )
  if (grepl(phrases, tolower(original), perl = TRUE)) {
    return(TRUE)
  }
  rest <- unlist(findit_tokens(paste(words[-1], collapse = " ")))
  code <- unlist(findit_tokens(found$stata))
  length(rest) > 0L && !any(rest %in% code)
}

# The closest entries to a question in plain English or Chinese, scored with
# BM25 over the task, section, detail and code. Entries scoring at least 40%
# of the best are kept, at most ten.
findit_nearest <- function(query, entries) {
  index <- findit_index()
  words <- findit_expand(query)
  words <- words[words %in% names(index$idf)]
  if (!length(words)) {
    return(entries[0L, ])
  }
  idf <- index$idf[words]
  score <- vapply(
    index$tf,
    function(tf) {
      n <- tf[words]
      n[is.na(n)] <- 0
      sum(idf * n * 2.2 / (n + 1.2 * (0.25 + 0.75 * sum(tf) / index$length)))
    },
    numeric(1)
  )
  # Ordinary preparation questions should not prefer predictive margins or
  # survey estimators solely because their descriptions also mention a mean.
  context <- paste0(
    "model|regress|predict|margin|survey|weight|panel|time.series|survival|",
    "hazard|causal|bayes|meta.analysis|psychometr|power|test|confidence|",
    "probabilit|odds|risk|effect|coefficient|correlation|likelihood|",
    "\u6a21\u578b|\u56de\u5f52|\u9884\u6d4b|\u52a0\u6743|\u8c03\u67e5|",
    "\u751f\u5b58|\u56e0\u679c|\u9762\u677f|\u65f6\u95f4\u5e8f\u5217|",
    "\u7f6e\u4fe1|\u68c0\u9a8c|\u6982\u7387|\u98ce\u9669|\u6548\u5e94|\u76f8\u5173"
  )
  if (!grepl(context, tolower(query), perl = TRUE)) {
    specialized <- grepl(context, tolower(entries$section), perl = TRUE)
    score[specialized] <- score[specialized] / 3
  }
  keep <- order(-score, findit_package_priority(entries$package))[
    seq_len(min(10L, sum(score >= 0.4 * max(score))))
  ]
  keep <- keep[score[keep] > 0]
  found <- entries[keep, ]
  found$match <- rep("nearest", nrow(found))
  attr(found, "relevance") <- score[keep]
  attr(found, "candidate_count") <- sum(score > 0 & score >= 0.4 * max(score))
  found
}

# Word counts per entry, with the task counted three times, and the inverse
# document frequency of each word. Built once per session.
findit_index <- function() {
  if (is.null(findit_cache$index)) {
    entries <- findit_entries()
    described <- findit_functions()
    about <- vapply(
      entries$functions,
      function(f) {
        rows <- match(f, described$`function`)
        rows <- rows[!is.na(rows)]
        paste(
          described$description[rows],
          described$description_zh[rows],
          collapse = " "
        )
      },
      character(1)
    )
    text <- paste(
      strrep(paste(entries$task, entries$task_zh, ""), 3L),
      entries$section,
      entries$section_zh,
      entries$detail,
      entries$detail_zh,
      entries$stata,
      vapply(entries$functions, paste, character(1), collapse = " "),
      about
    )
    tf <- lapply(findit_tokens(text), function(w) c(table(w)))
    n <- length(tf)
    df <- table(unlist(lapply(tf, names)))
    findit_cache$index <- list(
      tf = tf,
      idf = c(log(1 + (n - df + 0.5) / (df + 0.5))),
      length = mean(vapply(tf, sum, numeric(1)))
    )
  }
  findit_cache$index
}

findit_stop_words <- c(
  "a",
  "about",
  "all",
  "an",
  "and",
  "are",
  "as",
  "at",
  "be",
  "by",
  "can",
  "do",
  "does",
  "for",
  "from",
  "get",
  "have",
  "how",
  "i",
  "if",
  "in",
  "into",
  "is",
  "it",
  "its",
  "me",
  "my",
  "need",
  "of",
  "on",
  "or",
  "our",
  "so",
  "some",
  "that",
  "the",
  "their",
  "them",
  "then",
  "there",
  "these",
  "this",
  "to",
  "use",
  "using",
  "want",
  "way",
  "we",
  "what",
  "when",
  "where",
  "which",
  "who",
  "with",
  "would",
  "you",
  "your"
)

# English words, lower case and lightly stemmed so that "values", "valued"
# and "value" agree; runs of Chinese characters become overlapping pairs.
findit_tokens <- function(text) {
  text <- tolower(text)
  lapply(text, function(t) {
    english <- strsplit(t, "[^a-z]+")[[1]]
    english <- english[nchar(english) > 1L & !english %in% findit_stop_words]
    english <- sub("ies$", "y", english)
    english <- sub("^(.{3,})(ing|ed)$", "\\1", english)
    english <- sub("^(.{3,}[^s])s$", "\\1", english)
    english <- sub("^(.{3,})e$", "\\1", english)
    runs <- regmatches(
      t,
      gregexpr("(*UTF)[\\x{4e00}-\\x{9fff}]+", t, perl = TRUE)
    )[[1]]
    chinese <- unlist(lapply(runs, function(r) {
      n <- nchar(r)
      if (n == 1L) r else substring(r, seq_len(n - 1L), seq_len(n - 1L) + 1L)
    }))
    c(english, chinese)
  })
}

# Question words plus the words they stand for in the entries, from the
# curated synonym list: English words match whole words, while phrases and
# Chinese match anywhere in the question.
findit_expand <- function(query) {
  if (is.null(findit_cache$synonyms)) {
    findit_cache$synonyms <- findit_read("findit-synonyms.csv")
  }
  synonyms <- findit_cache$synonyms
  text <- tolower(query)
  words <- strsplit(text, "[^a-z]+")[[1]]
  single <- grepl("^[a-z]+$", synonyms$word)
  hit <- ifelse(
    single,
    synonyms$word %in% words,
    vapply(synonyms$word, grepl, logical(1), text, fixed = TRUE)
  )
  findit_tokens(paste(c(text, synonyms$means[hit]), collapse = " "))[[1]]
}

# Stata's rule: a prefix of the command at least as long as its minimum
# abbreviation. Operators such as `L.` match any word that starts with them.
findit_command_hit <- function(word, entries) {
  command <- tolower(entries$command)
  (startsWith(command, word) & nchar(word) >= nchar(entries$abbrev)) |
    (endsWith(command, ".") & startsWith(word, command))
}

# R functions match by full name: exactly, or ignoring case when nothing
# matches exactly (`surv` finds `Surv()`).
findit_function_hit <- function(name, entries, namespace = NULL) {
  known <- unique(c(unlist(entries$functions), findit_functions()$`function`))
  if (!is.null(namespace)) {
    described <- findit_functions()
    known <- described$`function`[described$package == namespace]
  }
  exact <- known[known == name]
  if (length(exact)) exact else known[tolower(known) == tolower(name)]
}

# Extra words rank the entries; the R code counts too, so that
# `findit("mutate egen")` can narrow a widely used R function. Among entries
# with the same score, the one with the fewest Stata words beyond the query
# comes first, so "merge 1:1 id, keep(match)" prefers the entry without
# further options.
findit_rank <- function(found, terms, match) {
  text <- findit_rank_tokens(paste(found$stata, if (match == "r") found$r))
  score <- vapply(
    text,
    function(t) sum(terms %in% t),
    numeric(1),
    USE.NAMES = FALSE
  )
  extra <- if (length(terms)) {
    vapply(
      findit_rank_tokens(found$stata),
      function(w) sum(!w %in% terms),
      numeric(1)
    )
  } else {
    numeric(nrow(found))
  }
  row_tokens <- intersect(terms, c("_n", "_N"))
  row_mismatch <- if (length(row_tokens)) {
    vapply(text, function(tokens) !all(row_tokens %in% tokens), logical(1))
  } else {
    rep(FALSE, nrow(found))
  }
  # keep if missing(x) and keep if !missing(x) select opposite rows, so a
  # negation mismatch outweighs package preference.
  negated <- vapply(
    findit_rank_tokens(found$stata),
    function(tokens) "!" %in% tokens,
    logical(1)
  )
  context <- 2L *
    (row_mismatch | (length(terms) > 0L & negated != ("!" %in% terms))) +
    (grepl("^by(s|so|sor|sort)? .*:", found$stata) != ("by" %in% terms))
  ordered <- order(
    -score,
    context,
    findit_package_priority(found$package),
    extra,
    seq_along(score)
  )
  found <- found[ordered, ]
  found$match <- rep(match, nrow(found))
  found$.score <- score[ordered]
  found$.extra <- extra[ordered]
  found$.context <- context[ordered]
  found
}

# An option name alone does not choose between e.g. keep(match) and
# keep(master match), even when one of those examples happens to be shorter.
findit_ambiguous_option <- function(query, stata) {
  options <- sub("^[^,]*,", "", stata)
  options[!grepl(",", stata, fixed = TRUE)] <- ""
  calls <- unique(unlist(regmatches(
    options,
    gregexpr("[A-Za-z_][A-Za-z0-9_]*[(][^()]*[)]", options)
  )))
  names <- sub("[(].*$", "", calls)
  terms <- findit_rank_tokens(query)[[1L]]
  any(vapply(
    unique(names),
    function(name) {
      name %in%
        terms &&
        !grepl(paste0("\\b", name, "\\s*[(]"), query, perl = TRUE) &&
        sum(names == name) > 1L
    },
    logical(1)
  ))
}

findit_package_priority <- function(package) {
  tidyverse <- c(
    "dplyr",
    "tidyr",
    "tibble",
    "readr",
    "purrr",
    "stringr",
    "forcats",
    "ggplot2",
    "tidyselect",
    "lubridate",
    "haven",
    "hms",
    "readxl",
    "broom",
    "modelr",
    "magrittr"
  )
  ifelse(package == "tidystata", 0L, ifelse(package %in% tidyverse, 1L, 2L))
}

# Narrow only after comma hints and variable requirements have been resolved.
# Bare Stata commands remain complete family browsers.
findit_select <- function(x, query, customized = FALSE) {
  if (is.null(query) || !nrow(x)) {
    return(x)
  }
  query <- gsub("\\s+", " ", trimws(query))
  entries <- findit_entries()
  rows <- match(attr(x, "entry_ids"), entries$id)
  commands <- unique(entries$command[rows[x$match == "stata"]])
  bare <- !customized &&
    !grepl("[[:space:]:(),]", query) &&
    any(findit_command_hit(tolower(query), entries))
  if (bare) {
    templates <- findit_templates()[attr(x, "entry_ids")]
    meaning <- vapply(templates, function(t) t$meaning, character(1))
    egen <- grepl("^egen .*=[[:space:]]*[A-Za-z_]+[(]", x$stata)
    meaning[egen] <- sub(
      "^egen .*=[[:space:]]*([A-Za-z_]+)[(].*$",
      "\\1",
      x$stata[egen]
    )
    defaults <- attr(x, "default_rows")
    remaining <- setdiff(seq_len(nrow(x)), defaults)
    candidates <- c(defaults, remaining)
    defaults <- utils::head(candidates[!duplicated(meaning[candidates])], 5L)
    attr(x, "default_rows") <- defaults
    attr(x, "show") <- length(defaults)
    return(x)
  }
  candidates <- attr(x, "candidate_rows")
  if (is.null(candidates)) {
    candidates <- attr(x, "query_rows")
  }
  if (is.null(candidates)) {
    candidates <- seq_len(nrow(x))
  }
  defaults <- attr(x, "default_rows")
  nearest <- any(x$match == "nearest")
  if (nearest) {
    candidates <- which(x$match == "nearest")
  } else {
    candidates <- c(
      intersect(defaults, candidates),
      setdiff(candidates, defaults)
    )
  }
  clear <- if (customized) {
    length(defaults) == 1L &&
      isTRUE(attr(x, "matched_hints")) &&
      !isTRUE(attr(x, "unmatched_hints"))
  } else {
    isTRUE(attr(x, "single_best"))
  }
  clear <- clear && !isTRUE(attr(x, "unrepresented_options")) && !nearest
  relevant <- attr(x, "entry_ids")[candidates]
  selected <- if (clear) {
    utils::head(candidates, 1L)
  } else {
    utils::head(candidates, 10L)
  }
  total <- attr(x, "candidate_count")
  x <- x[selected, ]
  attr(x, "candidate_rows") <- NULL
  attr(x, "single_best") <- NULL
  attr(x, "truncated") <- !clear &&
    (length(candidates) > 10L || (length(total) && total > 10L))
  if (length(commands) == 1L) {
    broader <- sum(entries$command == commands & !entries$id %in% relevant)
    if (broader > 0L) {
      attr(x, "broader") <- list(command = commands, count = broader)
    }
  }
  x
}

# Rank syntax tokens, so x cannot match exp() and Stata's row index _n stays
# distinct from the group size _N. Spacing around operators is immaterial.
findit_rank_tokens <- function(text) {
  matches <- gregexpr(
    "[1m]:[1m]|[A-Za-z_][A-Za-z0-9_]*|[0-9]+(?:[.][0-9]+)?|==|!=|<=|>=|[=<>+*/^!-]",
    text,
    perl = TRUE
  )
  lapply(regmatches(text, matches), function(tokens) {
    tokens <- ifelse(tokens == "_N", "_N", tolower(tokens))
    tokens[tokens %in% c("bys", "byso", "bysor", "bysort")] <- "by"
    tokens
  })
}

# One entry answers the query when it contains every extra word and is closer
# than any other entry, as `inner_join()` is for "merge 1:1 id, keep(match)".
findit_single_best <- function(found, terms) {
  if (!length(terms) || !nrow(found) || found$.score[1] < length(terms)) {
    return(FALSE)
  }
  nrow(found) == 1L ||
    found$.score[2] < found$.score[1] ||
    found$.extra[2] > found$.extra[1]
}

findit_query <- function(expr, call = rlang::caller_env()) {
  if (is.null(expr)) {
    return(NULL)
  }
  if (rlang::is_symbol(expr)) {
    return(rlang::as_string(expr))
  }
  if (rlang::is_string(expr) && nzchar(trimws(expr))) {
    return(expr)
  }
  # R function names written as code: `lm()`, `dplyr::left_join`, or both.
  if (
    rlang::is_call(expr, "::") || (rlang::is_call(expr) && !length(expr[-1]))
  ) {
    return(paste(deparse(expr), collapse = ""))
  }
  cli::cli_abort(
    "{.arg command} must be one Stata word, an R function name or a quoted string, as in {.code findit(reg)}, {.code findit(left_join)} or {.code findit(\"merge 1:1 id\")}.",
    call = call
  )
}

findit_no_match <- function(query, word, candidates) {
  distance <- utils::adist(word, candidates, ignore.case = TRUE)[1L, ]
  close <- distance <= max(2L, nchar(word) %/% 2L)
  nearest <- candidates[close][order(distance[close])]
  nearest <- utils::head(nearest, 3L)
  paste0(
    "No Stata command, R function or keyword matches \"",
    query,
    "\".",
    if (length(nearest)) {
      paste0("\nDid you mean: ", paste(nearest, collapse = ", "), "?")
    },
    "\nUse `findit()` for the whole list."
  )
}

findit_result <- function(
  entries,
  match = NULL,
  functions = character(),
  query = NULL,
  show = NULL,
  namespace = NULL
) {
  if (!is.null(match)) {
    entries$match <- rep(match, nrow(entries))
  }
  described <- findit_functions()
  if (!is.null(namespace)) {
    described <- described[described$package == namespace, ]
  }
  if (findit_chinese()) {
    entries$task <- ifelse(
      nzchar(entries$task_zh),
      entries$task_zh,
      entries$task
    )
    described$description <- ifelse(
      nzchar(described$description_zh),
      described$description_zh,
      described$description
    )
  }
  out <- tibble::as_tibble(entries[c("match", "stata", "r", "package", "task")])
  attr(out, "entry_ids") <- entries$id
  fields <- c(
    "id",
    "stata",
    "r",
    "detail",
    "detail_zh",
    "source",
    "r_source",
    "equivalence",
    "approach",
    "kind",
    "validation"
  )
  attr(out, "reference") <- as.data.frame(entries[intersect(
    fields,
    names(entries)
  )])
  described <- described[
    which(described$`function` %in% functions),
    c("function", "package", "description", "stata")
  ]
  described$used <- described$`function` %in% unlist(findit_entries()$functions)
  attr(out, "r_functions") <- described
  query_rows <- attr(entries, "leaders")
  relevance <- attr(entries, "relevance")
  if (length(relevance)) {
    query_rows <- which(relevance == max(relevance))
  }
  attr(out, "query_rows") <- query_rows
  attr(out, "candidate_count") <- attr(entries, "candidate_count")
  attr(out, "single_best") <- !is.null(show)
  if (any(out$match == "nearest")) {
    attr(out, "query") <- query
  }
  defaults <- if (all(out$match == "all")) {
    seq_len(if (nrow(out) <= 6L) nrow(out) else 5L)
  } else if (!is.null(show)) {
    seq_len(show)
  } else {
    findit_defaults(entries, functions)
  }
  attr(out, "default_rows") <- defaults
  attr(out, "show") <- length(defaults)
  class(out) <- c("tidystata_findit", class(out))
  out
}

#' @export
print.tidystata_findit <- function(x, n = NULL, ...) {
  details <- !missing(n)
  defaults <- if (is.null(n)) attr(x, "default_rows")
  if (is.null(n)) {
    n <- attr(x, "show")
    if (is.null(n)) n <- 5L
  }
  shown <- if (!is.null(defaults)) {
    as.data.frame(x)[defaults[defaults <= nrow(x)], , drop = FALSE]
  } else {
    utils::head(as.data.frame(x), n)
  }
  # Detect the real output stream before the internal capture opens a sink.
  old_options <- options(cli.num_colors = cli::num_ansi_colors())
  on.exit(options(old_options), add = TRUE)
  # Blocks start with blank lines, which are dropped from the top.
  body <- utils::capture.output(findit_print_body(x, shown, details))
  body <- body[cumsum(nzchar(body)) > 0L]
  if (!length(body)) {
    body <- "# No matching entries."
  }
  cat(body, sep = "\n")
  hidden <- nrow(x) - nrow(shown)
  if (hidden > 0L) {
    input <- attr(x, "input")
    if (is.null(input)) {
      input <- "x"
    }
    cat(
      "\n# ",
      hidden,
      if (hidden == 1L) {
        " more relevant example. To see them all: "
      } else {
        " more relevant examples. To see them all: "
      },
      input,
      " |> print(n = Inf)\n",
      sep = ""
    )
  }
  if (
    hidden == 0L &&
      (isTRUE(attr(x, "truncated")) || !is.null(attr(x, "broader")))
  ) {
    cat("\n")
  }
  if (isTRUE(attr(x, "truncated"))) {
    cat(
      "# Only the 10 best candidates are retained; refine the query for a closer match.\n"
    )
  }
  broader <- attr(x, "broader")
  if (!is.null(broader)) {
    cat(
      "# ",
      broader$count,
      " broader ",
      broader$command,
      if (broader$count == 1L) " example" else " examples",
      ". Browse the family: findit(",
      broader$command,
      ")\n",
      sep = ""
    )
  }
  customized <- attr(x, "customized")
  if (!is.null(customized)) {
    shown_rows <- if (!is.null(defaults)) {
      defaults[defaults <= nrow(x)]
    } else {
      utils::head(seq_len(nrow(x)), n)
    }
    if (!any(customized)) {
      cat(
        "\n# Supplied names do not fit an example; original placeholders are retained.\n"
      )
    } else if (any(!customized[shown_rows])) {
      cat(
        "\n# Examples with different variable requirements retain their original placeholders.\n"
      )
    }
  }
  if (isTRUE(attr(x, "unmatched_hints"))) {
    cat(
      "\n# No example matches all supplied hints; showing the closest alternatives.\n"
    )
  }
  if (isTRUE(attr(x, "unrepresented_options"))) {
    cat("\n# These examples do not implement every supplied option.\n")
  }
  invisible(x)
}

findit_print_body <- function(x, shown, details = FALSE) {
  functions <- attr(x, "r_functions")
  if (length(functions) && nrow(functions) > 0L) {
    # Describe distinct R meanings, but not a function already demonstrated.
    displayed <- unlist(findit_calls(shown$r))
    functions <- functions[
      !functions$`function` %in% c(displayed, attr(x, "resolved_functions")),
      ,
      drop = FALSE
    ]
  }
  headed <- length(functions) && nrow(functions) > 0L
  lines <- character()
  is_stata <- logical()
  # Each entry is a block: what it does, then the Stata and the R code on
  # labelled lines, with a blank line before the next entry. Basic ANSI
  # colours read on light and dark themes; cli drops them where unsupported.
  if (nrow(shown) > 0L) {
    lines <- paste0(
      "\n\n",
      cli::style_bold(paste0("# ", shown$task)),
      cli::col_grey(paste0(" [", shown$package, "]")),
      "\n",
      cli::col_blue(paste0(cli::style_bold("Stata: "), shown$stata)),
      "\n",
      cli::col_green(paste0(cli::style_bold("R:     "), shown$r))
    )
    metadata <- findit_metadata(shown)
    note <- if (findit_chinese()) metadata$detail_zh else metadata$detail
    show_note <- nzchar(note)
    lines[show_note] <- paste0(lines[show_note], "\n# Note: ", note[show_note])
    if (details) {
      source <- nzchar(metadata$source)
      lines[source] <- paste0(
        lines[source],
        "\n# Source: ",
        metadata$source[source],
        "\n# R reference: ",
        metadata$r_source[source]
      )
    }
    is_stata <- shown$match == "stata"
  }
  # The closest entries to a plain question get their own heading, before
  # or after the exact matches as in the table.
  nearest <- shown$match == "nearest"
  close <- lines[nearest]
  is_stata <- is_stata[!nearest]
  lines <- lines[!nearest]
  if (length(close) && nearest[1]) {
    cat(
      "\n",
      findit_heading("# Closest entries for", attr(x, "query")),
      sep = ""
    )
    cat(close, if (length(lines) || headed) "\n", sep = "")
    close <- character()
  }
  plain <- lines[is_stata | !headed]
  # The first entry follows the closest entries, which already end their line.
  if (length(plain)) {
    plain[1] <- substring(plain[1], 2L)
  }
  cat(plain, sep = "")
  if (headed) {
    related <- ifelse(
      nzchar(functions$stata),
      paste0("\n  Related Stata: ", functions$stata),
      ""
    )
    cat(
      if (any(is_stata)) "\n",
      paste0(
        "\n",
        findit_heading(paste0(
          "# ",
          functions$`function`,
          "() [",
          functions$package,
          "]: ",
          functions$description
        )),
        related
      ),
      sep = ""
    )
    cat(lines[!is_stata], sep = "")
  }
  if (length(close)) {
    cat(
      if (length(lines) || headed) "\n",
      "\n",
      findit_heading("# Closest entries for", attr(x, "query")),
      sep = ""
    )
    cat(close, sep = "")
  }
  if (length(lines) || headed || any(nearest)) {
    cat("\n")
  }
}

# Section headings stand out in cyan where the console has colour. A query,
# if given, is quoted after the heading.
findit_heading <- function(text, query = NULL) {
  if (!is.null(query)) {
    text <- paste0(text, " \"", query, "\"")
  }
  cli::col_cyan(cli::style_bold(text))
}

findit_cache <- new.env(parent = emptyenv())

findit_entries <- function() {
  if (is.null(findit_cache$entries)) {
    entries <- findit_read("stata-to-r.csv")
    provenance <- findit_read("findit-provenance.csv")
    rows <- match(entries$id, provenance$id)
    if (
      anyNA(rows) || anyDuplicated(entries$id) || anyDuplicated(provenance$id)
    ) {
      cli::cli_abort(
        "The findit reference metadata does not match the catalogue."
      )
    }
    for (name in setdiff(names(provenance), "id")) {
      entries[[name]] <- provenance[[name]][rows]
    }
    entries$functions <- findit_calls(entries$r)
    findit_cache$entries <- entries
  }
  findit_cache$entries
}

findit_functions <- function() {
  if (is.null(findit_cache$functions)) {
    findit_cache$functions <- findit_read("r-functions.csv")
  }
  findit_cache$functions
}

# Chinese text follows R's own rule for translated messages: the first entry
# of `LANGUAGE` if it is set, otherwise the character locale.
findit_chinese <- function() {
  language <- strsplit(Sys.getenv("LANGUAGE"), ":", fixed = TRUE)[[1]]
  if (length(language) && nzchar(language[1])) {
    return(startsWith(tolower(language[1]), "zh"))
  }
  grepl("^zh|chinese", Sys.getlocale("LC_CTYPE"), ignore.case = TRUE)
}

findit_read <- function(file) {
  readr::read_csv(
    system.file("extdata", file, package = "tidystata"),
    col_types = readr::cols(.default = readr::col_character()),
    na = character(),
    locale = readr::locale(encoding = "UTF-8"),
    progress = FALSE
  )
}

# Names of the functions called in each line of R code. Text inside quotes is
# skipped, so a regular expression such as "^x_" is not read as a call.
findit_calls <- function(code) {
  code <- gsub("\"(?:[^\"\\\\]|\\\\.)*\"", "\"\"", code, perl = TRUE)
  pattern <- paste0(
    "(?<![A-Za-z0-9_.:])(?:[A-Za-z][A-Za-z0-9.]*::)?",
    "[A-Za-z_.][A-Za-z0-9_.]*(?=[(])"
  )
  calls <- regmatches(code, gregexpr(pattern, code, perl = TRUE))
  local <- regmatches(
    code,
    gregexpr(
      "[A-Za-z_.][A-Za-z0-9_.]* *<- *function *[(]",
      code,
      perl = TRUE
    )
  )
  lapply(seq_along(calls), function(i) {
    x <- unique(sub("^.*::", "", calls[[i]]))
    helpers <- sub(" *<-.*$", "", local[[i]])
    specials <- if (grepl("coxph(", code[i], fixed = TRUE)) "tt"
    x[!x %in% c("function", "if", "while", "for", helpers, specials)]
  })
}
