#' Tidyselect columns in stata style
#'
#' @description
#' `s_match()` is a simpler version of `matches()`
#' in <[`tidy-select`][dplyr_tidy_select]>.
#' It is designed to select columns in a Stata-like style.
#'
#' As `matches()`, `s_match()` must be used
#' within a *selecting* function, such as
#' `ds()` or
#' `dplyr::across()`.
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
#' @examples
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
#' \dontrun{
#' tb %>%
#'   ds(s_match("x1-x5"))
#' }
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
  if (is.character(string)) {
    string <- paste0("^(", string, ")$")
    string_vec <- string %>%
      stringr::str_split_1("\\s+")
    if (length(string_vec) == 1) {
      string_vec <- paste0("^", string, "$")
    }
    out <- string_vec %>%
      stringr::str_replace_all("\\*", ".*") %>%
      stringr::str_replace_all("~", ".+") %>%
      stringr::str_replace_all("\\?", ".") %>%
      purrr::map_chr(num_range_to_regex) %>%
      stringr::str_flatten("|")
  }

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
