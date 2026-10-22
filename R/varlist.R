#' Select columns with a Stata varlist
#'
#' @description
#' `varlist()` selects columns with a Stata-style varlist string such as
#' `"inc* age? x[1-12]"`, as in Stata's `keep inc* age?`. It is a simpler
#' version of `matches()` in <[`tidy-select`][dplyr_tidy_select]>.
#'
#' Use `varlist()` within a *selecting* function, such as `ds()`, `tab()` or
#' `dplyr::across()`. Alternatively, provide `vars` explicitly to return
#' matching positions in a standalone call. `varlist()` was called `s_match()`
#' before tidystata 0.3.0; the old name still works with a deprecation
#' warning.
#'
#' @param string A single character string containing patterns, separated by
#' spaces, like selecting a varlist in Stata's `keep` command.
#' @param ignore_case If `TRUE` (the default), matching ignores case.
#' @param ignore.case `r lifecycle::badge("deprecated")` Use `ignore_case`
#'   instead.
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
#' * `var1-var5` is NOT used to select a range of variables.
#' Use `var1:var5` outside `varlist()` instead.
#'
#' Space-separated patterns are alternatives, each matched against complete
#' column names. Numeric ranges expand within each pattern before matching.
#' Each pattern can contain one bracketed range; separate patterns may each
#' contain their own range.
#'
#' @examples
#' varlist("x[1-2] y", vars = c("x1", "x2", "x3", "y"))
#'
#' tb <- paste0("x", 1:15) |>
#'   tibble::as_tibble() |>
#'   tidyr::pivot_wider(names_from = value)
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
#'
#' tb |>
#'   ds(x1:x5)
#'
#' @family selection and preview functions
#' @export
varlist <- function(
  string,
  ignore_case = TRUE,
  vars = NULL,
  ignore.case = lifecycle::deprecated()
) {
  if (lifecycle::is_present(ignore.case)) {
    lifecycle::deprecate_soft(
      "0.3.0",
      "varlist(ignore.case)",
      "varlist(ignore_case)"
    )
    ignore_case <- ignore.case
  }
  if (!is.character(string)) {
    stop_input_type(string, "a character vector")
  }
  error_call <- rlang::current_env()
  # Expand complete raw patterns before attaching their boundary anchors.
  # paste0 also retains the existing literal-NA pattern behavior.
  patterns <- paste0(string, "") |>
    stringr::str_split_1("\\s+") |>
    stringr::str_replace_all("\\*", ".*") |>
    stringr::str_replace_all("~", ".+") |>
    stringr::str_replace_all("\\?", ".") |>
    vapply(
      num_range_to_regex,
      character(1),
      call = error_call,
      USE.NAMES = FALSE
    )
  out <- paste0("^(", patterns, ")$") |>
    stringr::str_flatten("|")

  tidyselect::matches(
    out,
    ignore_case,
    vars = vars
  )
}

# Helper function
num_range_to_regex <- function(string, call = rlang::caller_env()) {
  any_range <- stringr::str_detect(string, "\\[.*\\]")

  if (!any_range) {
    return(string)
  }

  start_end <- string |>
    stringr::str_extract_all("\\[.*\\]") |>
    stringr::str_remove_all("\\[|\\]") |>
    stringr::str_split_1("-")

  multiple_ranges <- length(start_end) > 2
  if (multiple_ranges) {
    cli::cli_abort("Only one range is allowed.", call = call)
  }

  letter_range <- sum(start_end %in% c(letters, LETTERS)) == 2
  if (letter_range) {
    return(string)
  }

  num_range <- start_end |>
    as.integer() |>
    capture()

  if (num_range) {
    begin <- as.integer(start_end[1])
    end <- as.integer(start_end[2])
    if (begin > end) {
      cli::cli_abort(
        "The number range should start with a smaller number.",
        call = call
      )
    } else {
      string_parts <- string |>
        stringr::str_split_1("\\[.*\\]")
      range <- seq(begin, end)
      out <- paste0(string_parts[1], range, string_parts[2]) |>
        stringr::str_flatten("|")
      return(out)
    }
  } else {
    cli::cli_abort(
      "The range should be specified as {.code [a-m]} or {.code [1-10]}.",
      call = call
    )
  }
}
