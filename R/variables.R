#' Show the variable list of a dataset
#'
#' @description
#' * `variables()` works like the "Variables" tab in Stata.
#' * `variables_search()` searches for variables by name or variable label,
#'   rather than by the values stored in the columns.
#'
#' @param .data The input data frame, tibble, or data.table.
#' @param ... <[`tidy-select`][dplyr_tidy_select]> Existing columns to
#' select or rename before listing or searching. Omit to include all columns.
#' Computed columns are not created by this argument.
#' @param string A single non-missing character string to search for in names
#' or labels. Search is case-insensitive and matches substrings by default.
#' An empty string matches all selected variables. Wildcards `*`, `?`, and `~`
#' represent zero or more, exactly one, and one or more characters, respectively.
#' Use `^` and `$` anchors to require a complete name or label match.
#'
#' @returns A table with a character `name` column. A character `label` column
#' is added only when at least one selected variable has a usable label;
#' unlabelled variables then have `NA` labels. Search returns only matching
#' rows, in selection order, with the same columns as the selected variable list.
#' Tables preserve the input's data.frame, tibble, or data.table container and
#' supported preview settings. Results are ungrouped; arbitrary subclasses are
#' not reconstructed on the inventory rows.
#'
#' @details
#' Variable labels are read from each column's `label` attribute, including
#' ordinary vectors without a labelled class. A usable label is a single,
#' non-missing value that converts to nonempty text. Value-label mappings and
#' cell values are not searched. Selecting or renaming columns retains their
#' variable labels; the input data are not modified.
#'
#' Selection follows [dplyr::select()]. On grouped data frames, grouping columns
#' are retained and may produce a message when not explicitly selected. Ungroup
#' first to search only independently selected columns.
#'
#' Search patterns are translated before matching. One bracketed letter range
#' such as `[a-h]`, or ascending nonnegative integer range such as `[1-12]`,
#' is supported. Multiple bracketed ranges are unsupported. Numeric ranges are
#' expanded into alternatives, so use unanchored patterns such as `item[1-12]`
#' for substring matching. This pattern language is not a general-purpose
#' regular-expression interface; invalid patterns produce an error.
#'
#' @name variables
#' @seealso [ds()], [codebook()], [browse()]
#'
#' @examples
#' variables(lifeexp)
#' variables_search(lifeexp, "n")
#' variables_search(lifeexp, "^country$")
#'
#' # Inspect metadata before choosing columns for subsequent analysis.
#' survey <- tibble::tibble(age = c(30, 45), income = c(2000, 3000))
#' attr(survey$income, "label") <- "Monthly earnings"
#' variables(survey, earnings = income, age)
#' variables_search(survey, "earn")
#' @family inspection functions

#' @rdname variables
#' @export
variables <- function(.data, ...) {
  if (!missing(...)) {
    .data <- dplyr::select(.data, ...)
  }

  out <- ds(.data, .type = "table")

  labels <- variable_labels(.data)
  if (any(!is.na(labels))) {
    out$label <- unname(labels)
  }

  out
}

#' @rdname variables
#' @export
variables_search <- function(.data, string, ...) {
  check_string(string)
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
    dplyr::filter(
      out,
      stringr::str_detect(name, string) |
        stringr::str_detect(label, string)
    )
  } else {
    dplyr::filter(out, stringr::str_detect(name, string))
  }
}

# Variable labels are column attributes, independent of the values' classes.
variable_labels <- function(.data) {
  vapply(
    .data,
    function(x) {
      label <- attr(x, "label", exact = TRUE)
      if (length(label) != 1L || is.na(label) || !nzchar(as.character(label))) {
        NA_character_
      } else {
        as.character(label)
      }
    },
    character(1)
  )
}
