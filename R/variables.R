#' Show the variable list of a dataset
#'
#' @description
#' * `variables()` works like the "Variables" tab in Stata.
#' * `variables_search()` searches for variables by name or label.
#'
#' @param .data The input data (data frame or tibble).
#' @param ...  <[`tidy-select`][dplyr_tidy_select]> or
#' <[`data-masking`][args_data_masking]> Variables to include in the codebook.
#' *This argument can be omitted*.
#' @param string A string to search for in the variable names or labels.
#' Search is case-insensitive and matches substrings by default. Wildcards
#' `*`, `?`, and `~` represent any sequence, one character, and one or more
#' characters. Use `^` and `$` anchors to require a complete-name/label match.
#'
#' @return  A tibble.
#' @name variables
#' @seealso [ds()], [codebook()], [browse()]
#'
#' @examples
#' variables(lifeexp)
#'
#' variables_search(lifeexp, "n")

#' @rdname variables
#' @export
variables <- function(.data, ...) {
  # if ... is empty, select all variables
  if (!missing(...)) {
    .data <- dplyr::select(.data, ...)
  }

  out <- .data %>%
    names_as_column()

  labels <- variable_labels(.data)
  if (any(!is.na(labels))) {
    out$label <- unname(labels)
  }

  return(out)
}

#' @rdname variables
#' @export
variables_search <- function(.data, string, ...) {
  if (is.character(string)) {
    string <- string %>%
      stringr::str_replace_all("\\*", ".*") %>%
      stringr::str_replace_all("~", ".+") %>%
      stringr::str_replace_all("\\?", ".") %>%
      purrr::map_chr(num_range_to_regex)
    string <- stringr::str_glue("(?i).*{string}.*")
  }

  out <- variables(.data, ...)
  if ("label" %in% colnames(out)) {
    out %>%
      dplyr::filter(
        stringr::str_detect(name, string) |
          stringr::str_detect(label, string)
      ) %>%
      return()
  } else {
    out %>%
      dplyr::filter(
        stringr::str_detect(name, string)
      ) %>%
      return()
  }
}

# Variable labels are column attributes, independent of the values' classes.
variable_labels <- function(.data) {
  vapply(.data, function(x) {
    label <- attr(x, "label", exact = TRUE)
    if (length(label) != 1L || is.na(label) || !nzchar(as.character(label))) {
      NA_character_
    } else {
      as.character(label)
    }
  }, character(1))
}
