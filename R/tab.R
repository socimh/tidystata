#' Tabulate columns
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' Enhanced `count()`.
#'
#' * `tab()` - Tabulates variable(s) simultaneously, similar to `count()`.
#' * `tab1()` - Tabulates variable(s) one by one.
#' * `tab2()` - Cross-tabulates two variables.
#' * `fre()` - Adds “Total” row(s) to the output of `tab()`.
#' * `fre1()` - Adds “Total” row(s) to the output of `tab1()`.
#' * `fre2()` - Adds a “Total” row and a “total” column to the output of `tab2()`.
#'
#' The tabulation and frequency functions return data by default. The `fre()`
#' family adds totals; rich output is available with `.type = "flextable"`
#' when the optional flextable package is installed.
#'
#' If the output tibble has many rows, consider using
#' `print()` to display the output.
#'
#' @param .data A data frame, data frame extension
#' (e.g. a tibble), or a lazy data frame (e.g. from dbplyr or dtplyr).
#' @param ... <[`tidy-select`][dplyr_tidy_select]> or
#' <[`data-masking`][args_data_masking]> Variables to tabulate.
#'
#' Both tidyselect (e.g., `starts_with()`) and
#' data masking (e.g., `x_sq = x^2`) are supported.
#' See examples below.
#' @inheritParams dplyr::summarise
#' @param .desc If TRUE, will show the largest groups at the top.
#' @param .type Output type. `tab1()` and `fre1()` default to a list of
#' tibbles; `fre()` and `fre2()` default to a tibble. Explicit flextable
#' output requires the optional flextable package.
#' @param .flip If TRUE, will transpose the output tibble.
#'
#' @return
#' A tibble, a list of tibbles, or a flextable.
#'
#' @name tab
#'
#' @examples
#' # tabulate the 8th column
#' tab(starwars, 8)
#'
#' # tabulate the "sex" column
#' tab(starwars, sex)
#'
#' tab(starwars, sex, .desc = TRUE)
#'
#' fre(starwars, sex)
#'
#' fre(starwars, sex, .desc = TRUE)
#'
#' tab(starwars, sex, gender)
#'
#' tab(starwars, sex == "male")
#'
#' tab(starwars, male = sex == "male")
#'
#' tab(starwars, ends_with("color"))
#'
#' tab(starwars, s_match("s*e"))
#'
#' tab(starwars)
#'
#' tab1(starwars, 1:3)
#'
#' tab1(starwars, ends_with("color"))
#'
#' tab1(starwars, ends_with("color"), .type = "tibble")
#'
#' fre1(starwars, ends_with("color"))
#'
#' fre1(starwars, ends_with("color"), .type = "list")
#'
#' tab2(starwars, sex, gender)
#'
#' tab2(starwars, height, gender)
#'
#' fre2(starwars, height, gender)
NULL

#' @export
#' @rdname tab
tab <- function(
    .data, ...,
    .by = NULL,
    .desc = FALSE) {
  # Identify group variables
  by <- rlang::enquo(.by)
  group_vars <- extract_group_var(.data, by)

  # Prepare data
  .data_nogroup <- prepare_tab_data(.data, ..., group_vars = group_vars)
  .data <- .data %>%
    dplyr::select(dplyr::any_of(group_vars)) %>%
    dplyr::bind_cols(.data_nogroup)

  # Confirm names
  old_names <- names(.data)
  .data <- modify_invalid_names(.data, "tab()")
  group_vars <- names(.data)[match(group_vars, old_names)]

  # Tabulate
  out <- tab_data(
    .data, group_vars, .desc
  ) %>%
    dplyr::select(-...any_miss)

  # Output
  return(out)
}

#' @export
#' @rdname tab
tab1 <- function(
    .data, ...,
    .by = NULL,
    .desc = FALSE,
    .type = c("list", "tibble")) {
  # Identify group variables
  by <- rlang::enquo(.by)
  group_vars <- extract_group_var(.data, by)

  .type <- match.arg(.type)
  keys <- dplyr::select(dplyr::ungroup(.data), tidyselect::all_of(group_vars))
  values <- prepare_tab_data(.data, ..., group_vars = group_vars)
  .data <- dplyr::bind_cols(keys, values)
  old_names <- names(.data)
  .data <- modify_invalid_names(.data, "tab1()")
  group_vars <- names(.data)[match(group_vars, old_names)]

  out <- purrr::map(.data[setdiff(names(.data), group_vars)], function(value) {
    dplyr::bind_cols(.data[group_vars], tibble::tibble(value = value)) %>%
      tab_data(group_vars, .desc) %>%
      dplyr::select(-...any_miss)
  })

  # Bind rows if the type is a tibble
  if (.type[1] == "tibble") {
    out <- append_tab_list(out)
  }

  # Output
  return(out)
}

#' @export
#' @rdname tab
tab2 <- function(
    .data, ..., .flip = FALSE) {
  # Prepare data
  .data <- .data %>%
    s_select(...)
  .data <- s_ungroup(.data)

  # Confirm names
  check_two_vars(.data)
  .data <- modify_invalid_names(.data, "tab2()")

  # Flip variables
  if (.flip) {
    .data <- .data %>%
      dplyr::relocate(2, 1)
  }

  # Cross-tabulate
  out <- tab2_data(.data)

  # Output
  return(out)
}

#' @export
#' @rdname tab
fre <- function(
    .data, ...,
    .by = NULL,
    .desc = FALSE,
    .type = c("tibble", "flextable")) {
  .type <- match.arg(.type)
  # Identify group variables
  by <- rlang::enquo(.by)
  group_vars <- extract_group_var(.data, by)

  # Prepare data
  .data_nogroup <- prepare_tab_data(.data, ..., group_vars = group_vars)
  .data <- .data %>%
    dplyr::select(dplyr::any_of(group_vars)) %>%
    dplyr::bind_cols(.data_nogroup)

  # Confirm names
  old_names <- names(.data)
  .data <- modify_invalid_names(.data, "fre()")
  group_vars <- names(.data)[match(group_vars, old_names)]

  # Tabulate
  out <- .data %>%
    tab_data(group_vars, .desc) %>%
    add_total(group_vars) %>%
    dplyr::select(-...any_miss)

  if (.type[1] == "flextable") {
    out <- out %>%
      result_to_flextable(group_vars)
  }

  # Output
  return(out)
}

#' @export
#' @rdname tab
fre1 <- function(
    .data, ...,
    .by = NULL,
    .desc = FALSE,
    .type = c("list", "tibble", "flextable")) {
  # Identify group variables
  by <- rlang::enquo(.by)
  group_vars <- extract_group_var(.data, by)

  .type <- match.arg(.type)
  keys <- dplyr::select(dplyr::ungroup(.data), tidyselect::all_of(group_vars))
  values <- prepare_tab_data(.data, ..., group_vars = group_vars)
  .data <- dplyr::bind_cols(keys, values)
  old_names <- names(.data)
  .data <- modify_invalid_names(.data, "fre1()")
  group_vars <- names(.data)[match(group_vars, old_names)]

  out <- purrr::map(.data[setdiff(names(.data), group_vars)], function(value) {
    dplyr::bind_cols(.data[group_vars], tibble::tibble(value = value)) %>%
      tab_data(group_vars, .desc) %>%
      add_total(group_vars) %>%
      dplyr::select(-...any_miss)
  })

  if (.type[1] == "flextable") {
    out <- out %>%
      append_tab_list(blank_row = TRUE) %>%
      dplyr::slice(-dplyr::n()) %>%
      result_to_flextable(group_vars, fre1 = TRUE)
  } else if (.type[1] == "tibble") {
    out <- append_tab_list(
      out,
      blank_row = FALSE
    )
  }

  # Output
  return(out)
}


#' @export
#' @rdname tab
fre2 <- function(
    .data, ..., .flip = FALSE,
    .type = c("tibble", "flextable")) {
  .type <- match.arg(.type)
  # Prepare data
  .data <- .data %>%
    s_select(...)
  .data <- s_ungroup(.data)

  # Confirm names
  check_two_vars(.data)
  .data <- modify_invalid_names(.data, "fre2()")

  # Flip variables
  if (.flip) {
    .data <- .data %>%
      dplyr::relocate(2, 1)
  }

  # Cross-tabulate
  out <- .data %>%
    tab2_data() %>%
    add_total2(.data)

  if (.type[1] == "flextable") {
    out <- out %>%
      result_to_flextable(character(0), fre2 = TRUE)
  }

  # Output
  return(out)
}
