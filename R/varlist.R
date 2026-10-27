#' Select columns with a Stata varlist
#'
#' @description
#' `varlist()` selects columns with a Stata-style varlist string such as `"inc*
#' age? x[1-12]"`, as in Stata's `keep inc* age?`. It is a simpler version of
#' `matches()` in <[`tidy-select`][dplyr_tidy_select]>.
#'
#' Use `varlist()` within a *selecting* function, such as `ds()`, `tab()` or
#' `dplyr::across()`. Alternatively, provide `vars` explicitly to return
#' matching positions in a standalone call.
#'
#' @param string A single character string containing patterns, separated by
#'   spaces, like selecting a varlist in Stata's `keep` command.
#' @param ignore_case If `TRUE` (the default), matching ignores case.
#' @returns An integer vector of positions in the available column names.
#' @inheritParams tidyselect::starts_with
#'
#' @details
#'
#' * `*` matches zero or more characters.
#' * `~` matches one or more characters.
#' * `?` matches one character.
#' * `[a-h]` matches any character in the range from `a` to `h`.
#' * `[1-12]` matches any number in the range from `1` to `12`.
#' * `var1-var5` does not select a range of variables. Use `var1:var5` outside
#'   `varlist()` instead.
#'
#' Space-separated patterns are alternatives, each matched against complete
#' column names. Numeric ranges expand within each pattern before matching. Each
#' pattern can contain one bracketed range; separate patterns may each contain
#' their own range.
#'
#' @examples
#' varlist("x[1-2] y", vars = c("x1", "x2", "x3", "y"))
#'
#' tb <- tibble::as_tibble(
#'   matrix(1:15, nrow = 1, dimnames = list(NULL, paste0("x", 1:15)))
#' )
#' tb
#'
#' # List variable names by ds()
#' ds(tb)
#'
#' tb |>
#'   ds(varlist("x1*"))
#'
#' tb |>
#'   ds(varlist("x1~"))
#'
#' tb |>
#'   ds(varlist("*5"))
#'
#' tb |>
#'   ds(varlist("?5"))
#'
#' tb |>
#'   ds(varlist("x[9-15]"))
#'
#' # A literal hyphen pattern selects no columns here; it is not a range.
#' tb |>
#'   ds(varlist("x1-x5"))
#' @family selection and preview functions
#' @export
varlist <- function(
  string,
  ignore_case = TRUE,
  vars = NULL
) {
  if (!is.character(string)) {
    stop_input_type(string, "a character vector")
  }
  error_call <- rlang::current_env()
  # Expand complete raw patterns before attaching their boundary anchors.
  # paste0 also retains the existing literal-NA pattern behavior.
  patterns <- paste0(string, "") |>
    split_one("\\s+", arg = "string", call = error_call) |>
    varlist_wildcards() |>
    vapply(
      num_range_to_regex,
      character(1),
      call = error_call,
      USE.NAMES = FALSE
    )
  out <- paste(paste0("^(", patterns, ")$"), collapse = "|")

  tidyselect::matches(
    out,
    ignore_case,
    vars = vars
  )
}

# Stata wildcards as regular expressions: `*` is any text, `~` at least one
# character and `?` exactly one.
varlist_wildcards <- function(string) {
  string <- gsub("*", ".*", string, fixed = TRUE)
  string <- gsub("~", ".+", string, fixed = TRUE)
  gsub("?", ".", string, fixed = TRUE)
}

# Splits one string, keeping the empty piece after a trailing separator (as
# stringr does), so "x[1-5]" splits into "x" and "".
split_one <- function(
  string,
  pattern,
  arg = rlang::caller_arg(string),
  call = rlang::caller_env()
) {
  check_string(string, arg = arg, call = call)
  out <- strsplit(string, pattern, perl = TRUE)[[1L]]
  ends <- grepl(paste0("(?:", pattern, ")$"), string, perl = TRUE)
  if (!nzchar(string) || ends) c(out, "") else out
}

num_range_to_regex <- function(string, call = rlang::caller_env()) {
  any_range <- grepl("\\[.*\\]", string, perl = TRUE)

  if (!any_range) {
    return(string)
  }

  range <- regmatches(string, regexpr("\\[.*\\]", string, perl = TRUE))
  start_end <- split_one(gsub("\\[|\\]", "", range, perl = TRUE), "-")

  multiple_ranges <- length(start_end) > 2
  if (multiple_ranges) {
    cli::cli_abort("Only one range is allowed.", call = call)
  }

  letter_range <- sum(start_end %in% c(letters, LETTERS)) == 2
  if (letter_range) {
    return(string)
  }

  num_range <- length(start_end) == 2L &&
    all(grepl("^[0-9]+$", start_end))

  if (num_range) {
    if (any(as.double(start_end) > .Machine$integer.max)) {
      cli::cli_abort(
        "Numeric range endpoints must not exceed {.val {(.Machine$integer.max)}}.",
        call = call
      )
    }
    begin <- as.integer(start_end[1])
    end <- as.integer(start_end[2])
    if (begin > end) {
      cli::cli_abort(
        "The number range should start with a smaller number.",
        call = call
      )
    } else {
      string_parts <- split_one(string, "\\[.*\\]")
      range <- seq(begin, end)
      return(paste(
        paste0(string_parts[1], range, string_parts[2]),
        collapse = "|"
      ))
    }
  } else {
    cli::cli_abort(
      "The range should be specified as {.code [a-m]} or {.code [1-10]}.",
      call = call
    )
  }
}
