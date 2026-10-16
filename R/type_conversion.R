#' Better type conversion
#'
#' It improves the performance of converting
#' several types of variables.
#' Character input to `as_numeric()` is parsed with [readr::parse_number()],
#' preserving its length. Invalid numbers generate parsing warnings. Factors
#' return their level codes; labelled numeric variables return their values.
#'
#' @name type_conversion
#' @param .x A vector or matrix.
#'
#' @examples
#' lifeexp %>%
#'   dplyr::mutate(
#'     region_chr = as_character(region),
#'     region_num = as_numeric(region),
#'     region_fct = haven::as_factor(region),
#'     .keep = "used"
#'   )

#' @export
#' @rdname type_conversion
as_character <- function(.x) {
  type <- s_type(.x, .abbr = TRUE)
  if (type %>% stringr::str_detect("lbl")) {
    vec <- .x %>%
      haven::as_factor() %>%
      as.character()
  } else {
    vec <- .x %>%
      as.character()
  }
  return(vec)
}

#' @export
#' @rdname type_conversion
as_numeric <- function(.x) {
  if (length(.x) == 0L) {
    return(numeric(0))
  }
  if (s_type(.x, .abbr = TRUE) %in%
    c("units", "drtn", "time", "dttm", "fct", "ord")) {
    .x <- as.numeric(.x)
  } else if (s_type(.x, .abbr = TRUE) %>%
    stringr::str_detect("lbl")) {
    .x <- unclass(.x) %>% as.numeric()
  } else if (is.character(.x)) {
    is_nan <- !is.na(.x) & trimws(.x) == "NaN"
    .x[is_nan] <- NA_character_
    .x <- readr::parse_number(.x)
    .x[is_nan] <- NaN
  } else if (!is_summable(.x)) {
    .x <- rep(NA_real_, length(.x))
  } else {
     .x <- as.numeric(.x)
  }
  return(.x)
}
