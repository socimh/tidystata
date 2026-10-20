#' Find the R equivalent of a Stata command
#'
#' @description
#' `findit()` looks up a Stata command and returns the R code that does the
#' same job, whether a statart function or one from another package. It
#' covers everyday data work (browsing, tabulating, generating, merging,
#' reshaping) and points to the packages statart leaves to others, such as
#' fixest for `reghdfe`, modelsummary for `esttab`, binsreg for `binscatter`
#' and srvyr for `svy`.
#'
#' It also works the other way round: give it an R function, such as
#' `findit(left_join)`, and it describes the function and lists the Stata
#' commands it replaces. Beginners need not know which is which; a word that
#' is both, such as `log` or `round`, shows both meanings.
#'
#' Type a single word bare, as in `findit(reg)`, or quote anything longer, as
#' in `findit("merge 1:1 id, keep(match)")`. Call `findit()` with no argument
#' for the whole list.
#'
#' @param command A Stata command or an R function name, either one bare word
#' (`findit(tab)`, `findit(left_join)`) or a quoted string
#' (`findit("bysort g: egen m = mean(x)")`). R functions may also be written
#' as `lm()` or `dplyr::left_join`. Use `!!` to look up a string stored in a
#' variable: `findit(!!cmd)`. `NULL` (default) returns every entry.
#'
#' @return A tibble with one row per Stata idiom and the columns `match`
#' (`"stata"` when the word is a Stata command, `"r"` when it is an R function
#' used in the entry, `"keyword"` for a text match, `"all"` for the whole
#' list), `stata` (the Stata code), `r` (equivalent R code), `package` (where
#' the R function lives) and `task` (what it does). It prints each entry as
#' the Stata code and task on one line, followed by the R code, so the code is
#' never cut off; the first `n` entries are shown (`print(findit(), n = Inf)`
#' for all). A matched R function is printed with a one-line description. If
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
#'   the R function follow, under a description of that function. About 600
#'   R functions are described, including many that no entry uses yet, such
#'   as `n_distinct()` or `fct_relevel()`; for those, `findit()` prints the
#'   description and the related Stata command.
#' * A leading `by ...:` or `bysort ...:` prefix is set aside, so
#'   `findit("bys g: sum x")` looks up `summarize` and lists the grouped
#'   entries first.
#' * The remaining words put the best-matching entries first. For example,
#'   `findit("merge keep(match)")` lists `inner_join()` before the other merge
#'   entries, and `findit("mutate egen")` lists the `egen` entries among the
#'   many that use `mutate()`. All matching entries are still returned.
#' * If neither matches, the text is searched for in the Stata code, the R
#'   code and the task, so `findit(winsor)` and `findit(dummy)` also work.
#'
#' R reads a call before `findit()` runs, so anything that is not a single R
#' name must be quoted: several words (`"merge 1:1 id"`), reserved words
#' (`"if"`), and names starting with an underscore (`"_n"`).
#'
#' The list is curated rather than exhaustive. Longer explanations, in English
#' and Chinese, are in the "Coming from Stata" articles on the package
#' website.
#'
#' statart and statar can be attached together; only `tab()` and `xtile()`
#' share names. Attach statart last, or write `statart::tab()`.
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
#' findit("merge 1:1 id, keep(match)")
#' findit("bys g: egen m = mean(x)")
#' findit(winsor)
#'
#' # R functions work too, and words with both meanings show both
#' findit(left_join)
#' findit(log)
#'
#' # The whole list
#' findit()
findit <- function(command = NULL) {
  query <- findit_query(rlang::enexpr(command))
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
      findit_rank(entries[r_hit, ], terms, "r")
    )
    return(findit_result(found, functions = functions))
  }

  text <- tolower(original)
  haystack <- tolower(paste(entries$stata, entries$r, entries$task, sep = "\r"))
  keyword <- grepl(text, haystack, fixed = TRUE)
  if (any(keyword)) {
    return(findit_result(entries[keyword, ], "keyword"))
  }

  candidates <- unique(c(entries$command, findit_functions()$`function`))
  message(findit_no_match(query, first, candidates))
  invisible(findit_result(entries[0L, ], "keyword"))
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
# `findit("mutate egen")` can narrow a widely used R function.
findit_rank <- function(found, terms, match) {
  text <- tolower(paste(found$stata, if (match == "r") found$r))
  score <- vapply(
    text,
    function(t) sum(vapply(terms, grepl, logical(1), t, fixed = TRUE)),
    numeric(1)
  )
  found <- found[order(-score, seq_along(score)), ]
  found$match <- rep(match, nrow(found))
  found
}

findit_query <- function(expr) {
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
  stop(
    "`command` must be one Stata word, an R function name or a quoted string, ",
    "as in `findit(reg)`, `findit(left_join)` or `findit(\"merge 1:1 id\")`.",
    call. = FALSE
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

findit_result <- function(entries, match = NULL, functions = character()) {
  if (!is.null(match)) {
    entries$match <- rep(match, nrow(entries))
  }
  out <- tibble::as_tibble(entries[c("match", "stata", "r", "package", "task")])
  described <- findit_functions()
  described <- described[
    match(functions, described$`function`),
    c("function", "package", "description", "stata")
  ]
  described$used <- described$`function` %in% unlist(findit_entries()$functions)
  attr(out, "r_functions") <- described
  class(out) <- c("statart_findit", class(out))
  out
}

#' @export
print.statart_findit <- function(x, n = 20, ...) {
  functions <- attr(x, "r_functions")
  shown <- utils::head(as.data.frame(x), n)
  cat("# Stata to R:", nrow(x), if (nrow(x) == 1L) "entry\n" else "entries\n")
  headed <- length(functions) && nrow(functions) > 0L
  if (headed && any(x$match == "stata")) {
    cat(
      "# \"",
      functions$`function`[1],
      "\" is a Stata command and an R function.\n",
      sep = ""
    )
  }
  lines <- character()
  is_stata <- logical()
  if (nrow(shown) > 0L) {
    width <- nchar(shown$stata, type = "width")
    pad <- strrep(" ", pmax(min(max(width), 64L) - width, 0L))
    lines <- paste0(
      "\n",
      shown$stata,
      pad,
      "  # ",
      shown$task,
      " [",
      shown$package,
      "]",
      "\n  ",
      shown$r
    )
    is_stata <- shown$match == "stata"
  }
  if (headed && any(is_stata)) {
    cat("\n## Stata command")
  }
  cat(lines[is_stata | !headed], sep = "")
  if (headed) {
    related <- ifelse(
      nzchar(functions$stata),
      paste0("\n  Related Stata: ", functions$stata),
      ""
    )
    cat(
      if (any(is_stata)) "\n",
      paste0(
        "\n## R function: ",
        functions$`function`,
        "() [",
        functions$package,
        "]: ",
        functions$description,
        related
      ),
      sep = ""
    )
    if (!any(x$match == "r") && any(functions$used)) {
      cat("\n  Used in the entries above.")
    }
    cat(lines[!is_stata], sep = "")
  }
  if (length(lines) || headed) {
    cat("\n")
  }
  if (nrow(x) > nrow(shown)) {
    cat(
      "\n# ... and ",
      nrow(x) - nrow(shown),
      " more. Use `print(n = Inf)` to see all, or `View()`.",
      if (any(x$match[-seq_len(nrow(shown))] == "r")) {
        " Add a Stata word to narrow, as in findit(\"mutate egen\")."
      },
      "\n",
      sep = ""
    )
  }
  invisible(x)
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

findit_read <- function(file) {
  readr::read_csv(
    system.file("extdata", file, package = "statart"),
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
