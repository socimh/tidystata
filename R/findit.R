#' Find the R equivalent of a Stata command
#'
#' @description
#' `findit()` looks up a Stata command and returns the R code that does the
#' same job, whether a tidystata function or one from another package. It
#' covers everyday data work (browsing, tabulating, generating, merging,
#' reshaping) and points to the packages tidystata leaves to others, such as
#' fixest for `reghdfe`, modelsummary for `esttab`, binsreg for `binscatter`
#' and srvyr for `svy`.
#'
#' It also works the other way round: give it an R function, such as
#' `findit(left_join)`, and it describes the function and lists the Stata
#' commands it replaces. Beginners need not know which is which; a word that
#' is both, such as `log` or `round`, shows both meanings.
#'
#' Type a single word bare, as in `findit(reg)`, add names and hints with commas,
#' as in `findit(tab, sex, region)` or `findit(tab, gen)`, or quote full Stata
#' syntax, as in `findit("merge 1:1 id, keep(match)")`. Call `findit()` with no
#' argument for the whole list.
#'
#' @param command A Stata command or an R function name, either one bare word
#' (`findit(tab)`, `findit(left_join)`) or a quoted string
#' (`findit("bysort g: egen m = mean(x)")`). R functions may also be written
#' as `lm()` or `dplyr::left_join`. Use `!!` to look up a string stored in a
#' variable: `findit(!!cmd)`. `NULL` (default) returns every entry.
#' @param ... Unnamed variable names and command hints, captured without
#' evaluation. Names customize examples in Stata operand order, including new
#' output variables: `findit(xtile, quartile, income)`. A bare hint such as `gen`
#' selects the `generate()` option. Hints match exactly or by an unambiguous
#' prefix of at least three letters. Quote a name to use it literally when it
#' conflicts with a hint, as in `findit(tab, "gen")`. Use `!!` for a name stored
#' in a string. Calls, numbers, missing arguments and named arguments are not
#' accepted here.
#'
#' @returns A tibble with one row per Stata idiom and the columns `match`
#' (`"stata"` when the word is a Stata command, `"r"` when it is an R function
#' used in the entry, `"keyword"` for a text match, `"nearest"` for the
#' closest entries to a plain question, `"all"` for the whole list), `stata` (the Stata code), `r` (equivalent R code), `package` (where
#' the R function lives) and `task` (what it does). It prints each entry as
#' a short block: what it does, then the Stata code and the R code on lines
#' labelled `Stata:` and `R:`, so the code is never cut off. When one entry
#' answers the query, only that entry is printed. Routine commands have a
#' canonical default, such as `tabulate x` for `findit(tab)`. Up to five examples
#' are printed when different meanings or structural choices remain unresolved,
#' such as the direction of `reshape`. Hidden examples are always counted, with
#' a line to run for the rest, such as `findit(tab) |> print(n = Inf)`.
#' The returned tibble
#' always has every match, so it can be stored, filtered or opened with
#' `View()`. Headings use a single `#`, without an introductory summary.
#' R-function notes already demonstrated or resolved by comma-separated inputs
#' are omitted. Supplied names customize compatible
#' examples; examples requiring different variables retain all their original
#' placeholders. No matches are removed. A note identifies retained placeholders
#' when those examples are displayed, or explains when no example fits. If
#' nothing matches, a message suggests similar names and an empty tibble is
#' returned invisibly.
#'
#' @details
#' Matching follows fixed rules, without any guessing:
#'
#' * The first word is looked up both as a Stata command and as an R function.
#'   Stata's minimum abbreviations work: `reg`, `regr` and `regress` all find
#'   `regress`; `su` and `sum` find `summarize`; `ta` and `tab` find
#'   `tabulate`. R functions must be named in full (`lm` finds `lm()` but not
#'   `glm()`); upper and lower case are ignored only when no exact name
#'   matches.
#' * Entries found as a Stata command come first. Entries found only through
#'   the R function follow. A description is added only when the function does
#'   not appear in a displayed example. About 600
#'   R functions are described, including many that no entry uses yet, such
#'   as `n_distinct()` or `fct_relevel()`; for those, `findit()` prints the
#'   description and the related Stata command.
#' * A leading `by ...:` or `bysort ...:` prefix is set aside, so
#'   `findit("bys g: sum x")` looks up `summarize` and lists the grouped
#'   entries first.
#' * The remaining words put the best-matching entries first. For example,
#'   `findit("merge keep(match)")` lists `inner_join()` before the other merge
#'   entries, and `findit("mutate egen")` lists the `egen` entries among the
#'   many that use `mutate()`. Among equally good entries, the one with the
#'   fewest further words comes first. All matching entries are still
#'   returned.
#' * Comma-separated names and hints select among these examples and fill their
#'   recorded variable roles. Variable lists can accept several names, while
#'   fixed roles must all be supplied. Dataset names, function names and unrelated
#'   constants are unchanged. Strings that represent column names or formulas
#'   are customized too. R names are quoted as needed; non-Stata names are shown
#'   with backticks in the reference Stata line. This is a lookup over existing
#'   examples, not a parser or executor for arbitrary Stata programs.
#' * If a hint prefix has several interpretations, competing examples are shown.
#'   If no example satisfies every hint, the closest alternatives are shown with
#'   an explanation. For plain questions a uniquely highest-ranked meaning is
#'   shown alone; tied meanings retain up to five representative examples.
#' * If neither matches, the text is searched for in the Stata code, the R
#'   code and the task, so `findit(winsor)` and `findit(dummy)` also work.
#' * Otherwise the text is read as a plain question, in English or Chinese,
#'   and the closest entries are listed under their own heading:
#'   `findit("how do I remove duplicate rows")`. The closest entries are
#'   the ones sharing the most informative words with the question, after
#'   common words are dropped and a short built-in list of synonyms is
#'   applied ("average" also means "mean"). A question of three or more
#'   words that happens to start with a command, such as
#'   `findit("count how many people in each category")`, lists the closest
#'   entries first. No language model is involved, so the same question
#'   always gives the same answer.
#'
#' R reads a call before `findit()` runs, so anything that is not a single R
#' name must be quoted: several words (`"merge 1:1 id"`), reserved words
#' (`"if"`), and names starting with an underscore (`"_n"`).
#'
#' When R runs in Chinese (the `LANGUAGE` environment variable or, if it is
#' unset, the locale), the task and function descriptions are shown in
#' Chinese, and Chinese keywords are searched in any language.
#' `Sys.setenv(LANGUAGE = "en")` switches back to English, as it does for R's
#' own messages.
#'
#' The list is curated rather than exhaustive. Longer explanations, in English
#' and Chinese, are in the "Coming from Stata" articles on the package
#' website.
#'
#' tidystata and statar can be attached together; only `tab()` and `xtile()`
#' share names. Attach tidystata last, or write `tidystata::tab()`.
#'
#' @concept Stata
#' @concept Stata to R
#' @concept cheat sheet
#' @concept search
#' @concept help
#' @export
#' @examples
#' findit(reg)
#' findit(su)
#' findit(tab, sex, region)
#' findit(tab, gen)
#' findit(xtile, quartile, income)
#' findit("merge 1:1 id, keep(match)")
#' findit("bys g: egen m = mean(x)")
#' findit(winsor)
#'
#' # Plain questions
#' findit("how do I remove duplicate rows")
#'
#' # R functions work too, and words with both meanings show both
#' findit(left_join)
#' findit(log)
#'
#' # The whole list
#' findit()
findit <- function(command = NULL, ...) {
  expr <- rlang::enexpr(command)
  extra <- rlang::enexprs(..., .ignore_empty = "none")
  findit_check_arguments(expr, extra)
  found <- withVisible(findit_lookup(findit_query(expr)))
  if (length(extra)) {
    found$value <- findit_customize(found$value, extra)
  }
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
  name <- sub("^.*::", "", sub("[(][)]$", "", name))
  terms <- c(if (grouped) "by", gsub(",", "", tolower(words[-1]), fixed = TRUE))
  terms <- terms[nzchar(terms)]

  stata_hit <- findit_command_hit(word, entries)
  functions <- findit_function_hit(name, entries)
  r_hit <- !stata_hit &
    vapply(entries$functions, function(f) any(functions %in% f), logical(1))
  if (any(stata_hit) || length(functions)) {
    found <- rbind(
      findit_rank(entries[stata_hit, ], terms, "stata"),
      findit_rank(entries[r_hit, ], terms, "r"),
      make.row.names = FALSE
    )
    show <- if (findit_single_best(found, terms)) 1L
    leaders <- if (length(terms) && nrow(found)) {
      which(found$.score == found$.score[1] & found$.extra == found$.extra[1])
    }
    found <- found[setdiff(names(found), c(".score", ".extra"))]
    # A plain question that starts with a command word, such as "count how
    # many people in each group", gets the closest entries first.
    if (findit_plain(original, words, found)) {
      nearest <- findit_nearest(original, entries)
      found <- rbind(nearest, found[!found$stata %in% nearest$stata, ])
      attr(found, "relevance") <- attr(nearest, "relevance")
      show <- NULL
      leaders <- NULL
    }
    attr(found, "leaders") <- leaders
    return(findit_result(
      found,
      functions = functions,
      query = original,
      show = show
    ))
  }

  text <- tolower(original)
  haystack <- tolower(
    paste(entries$stata, entries$r, entries$task, entries$task_zh, sep = "\r")
  )
  keyword <- grepl(text, haystack, fixed = TRUE)
  if (any(keyword)) {
    return(findit_result(entries[keyword, ], "keyword"))
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
  keep <- order(-score)[seq_len(min(10L, sum(score >= 0.4 * max(score))))]
  keep <- keep[score[keep] > 0]
  found <- entries[keep, ]
  found$match <- rep("nearest", nrow(found))
  attr(found, "relevance") <- score[keep]
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
  (startsWith(entries$command, word) & nchar(word) >= nchar(entries$abbrev)) |
    (endsWith(entries$command, ".") & startsWith(word, entries$command))
}

# R functions match by full name: exactly, or ignoring case when nothing
# matches exactly (`surv` finds `Surv()`).
findit_function_hit <- function(name, entries) {
  known <- unique(c(unlist(entries$functions), findit_functions()$`function`))
  exact <- known[known == name]
  if (length(exact)) exact else known[tolower(known) == tolower(name)]
}

# Extra words rank the entries; the R code counts too, so that
# `findit("mutate egen")` can narrow a widely used R function. Among entries
# with the same score, the one with the fewest Stata words beyond the query
# comes first, so "merge 1:1 id, keep(match)" prefers the entry without
# further options.
findit_rank <- function(found, terms, match) {
  text <- tolower(paste(found$stata, if (match == "r") found$r))
  score <- vapply(
    text,
    function(t) sum(vapply(terms, grepl, logical(1), t, fixed = TRUE)),
    numeric(1),
    USE.NAMES = FALSE
  )
  extra <- if (length(terms)) {
    vapply(
      strsplit(tolower(found$stata), "[ ,]+"),
      function(w) sum(!w %in% terms),
      numeric(1)
    )
  } else {
    numeric(nrow(found))
  }
  ordered <- order(-score, extra, seq_along(score))
  found <- found[ordered, ]
  found$match <- rep(match, nrow(found))
  found$.score <- score[ordered]
  found$.extra <- extra[ordered]
  found
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
  show = NULL
) {
  if (!is.null(match)) {
    entries$match <- rep(match, nrow(entries))
  }
  described <- findit_functions()
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
  described <- described[
    match(functions, described$`function`),
    c("function", "package", "description", "stata")
  ]
  described$used <- described$`function` %in% unlist(findit_entries()$functions)
  attr(out, "r_functions") <- described
  query_rows <- if (!is.null(show)) seq_len(show) else attr(entries, "leaders")
  relevance <- attr(entries, "relevance")
  if (length(relevance)) {
    query_rows <- which(relevance == max(relevance))
  }
  attr(out, "query_rows") <- query_rows
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
  body <- utils::capture.output(findit_print_body(x, shown))
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
        " more example. To see them all: "
      } else {
        " more examples. To see them all: "
      },
      input,
      " |> print(n = Inf)\n",
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
  invisible(x)
}

findit_print_body <- function(x, shown) {
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
  lapply(calls, function(x) {
    x <- unique(sub("^.*::", "", x))
    x[!x %in% c("function", "if", "while")]
  })
}
