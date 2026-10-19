#' Tidyselect columns in stata style
#'
#' @description
#' `s_match()` is a simpler version of `matches()`
#' in <[`tidy-select`][dplyr_tidy_select]>.
#' It is designed to select columns in a Stata-like style.
#'
#' Use `s_match()` within a *selecting* function, such as `ds()` or
#' `dplyr::across()`. Alternatively, provide `vars` explicitly to return
#' matching positions in a standalone call.
#'
#' @param string A single character string containing patterns, separated by
#' spaces, like selecting a varlist in Stata's `keep` command.
#' @return An integer vector of positions in the available column names.
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
#' Use `var1:var5` out of `s_match()` instead.
#'
#' Space-separated patterns are alternatives, each matched against complete
#' column names. Numeric ranges expand within each pattern before matching.
#' Each pattern can contain one bracketed range; separate patterns may each
#' contain their own range.
#'
#' @examples
#' s_match("x[1-2] y", vars = c("x1", "x2", "x3", "y"))
#'
#' tb <- paste0("x", 1:15) %>%
#'   tibble::as_tibble() %>%
#'   tidyr::pivot_wider(names_from = value)
#' tb
#'
#' # List variable names by ds()
#' ds(tb)
#'
#' tb %>%
#'   ds(s_match("x1*"))
#'
#' tb %>%
#'   ds(s_match("x1~"))
#'
#' tb %>%
#'   ds(s_match("*5"))
#'
#' tb %>%
#'   ds(s_match("?5"))
#'
#' tb %>%
#'   ds(s_match("x[9-15]"))
#'
#' # A literal hyphen pattern selects no columns here; it is not a range.
#' tb %>%
#'   ds(s_match("x1-x5"))
#'
#' tb %>%
#'   ds(x1:x5)
#'
#' @export
s_match <- function(
  string,
  ignore.case = TRUE,
  vars = NULL
) {
  if (!is.character(string)) {
    stop("`string` must be a character string.", call. = FALSE)
  }
  # Expand complete raw patterns before attaching their boundary anchors.
  # paste0 also retains the existing literal-NA pattern behavior.
  patterns <- paste0(string, "") %>%
    stringr::str_split_1("\\s+") %>%
    stringr::str_replace_all("\\*", ".*") %>%
    stringr::str_replace_all("~", ".+") %>%
    stringr::str_replace_all("\\?", ".") %>%
    purrr::map_chr(num_range_to_regex)
  out <- paste0("^(", patterns, ")$") %>%
    stringr::str_flatten("|")

  tidyselect::matches(
    out,
    ignore.case,
    vars = vars
  )
}

# Helper function
num_range_to_regex <- function(string) {
  any_range <- stringr::str_detect(string, "\\[.*\\]")

  if (!any_range) {
    return(string)
  }

  start_end <- string %>%
    stringr::str_extract_all("\\[.*\\]") %>%
    stringr::str_remove_all("\\[|\\]") %>%
    stringr::str_split_1("-")

  multiple_ranges <- length(start_end) > 2
  if (multiple_ranges) {
    stop("Only one range is allowed.", call. = FALSE)
  }

  letter_range <- sum(start_end %in% c(letters, LETTERS)) == 2
  if (letter_range) {
    return(string)
  }

  num_range <- start_end %>%
    as.integer() %>%
    s_try()

  if (num_range) {
    begin <- as.integer(start_end[1])
    end <- as.integer(start_end[2])
    if (begin > end) {
      stop(
        "The number range should start with a smaller number.",
        call. = FALSE
      )
    } else {
      string_parts <- string %>%
        stringr::str_split_1("\\[.*\\]")
      range <- seq(begin, end)
      out <- paste0(string_parts[1], range, string_parts[2]) %>%
        stringr::str_flatten("|")
      return(out)
    }
  } else {
    stop("The range should be specified as [a-m] or [1-10]", call. = FALSE)
  }
}
