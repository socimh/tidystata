#' Know the type of an object.
#'
#' @name s_type
#' @param .x An object.
#' @param .abbr A logical. If `TRUE`, the abbreviation
#' of the type is returned.
#' @return A character. `s_type()` returns `"units"` for measured vectors
#' in either abbreviation mode. `s_unit()` returns the unit string for measured
#' or duration vectors, including empty or all-missing measured vectors, and
#' `NA_character_` for vectors without units.
#' @export
#'
#' @examples
#' s_type(1:10)
#' s_type(letters)

#' @export
#' @rdname s_type
s_type <- function(.x, .abbr = FALSE) {
  type <- .x %>%
    pillar::type_sum() %>%
    stringr::str_extract("^(\\w|\\+)+")

  if (vctrs::obj_is_vector(.x)) {
    if (vctrs::vec_ptype_abbr(.x) == "units") {
      type <- "units"
    }
  }

  if (type == "hvn_lbll") {
    type <- unclass(.x) %>%
      pillar::type_sum() %>%
      paste0("+lbl")
  }

  if (!.abbr) {
    type <- type %>%
      stringr::str_replace("int", "integer") %>%
      stringr::str_replace("dbl", "double") %>%
      stringr::str_replace("chr", "character") %>%
      stringr::str_replace("lgl", "logical") %>%
      stringr::str_replace("cpl", "complex") %>%
      stringr::str_replace("fct", "factor") %>%
      stringr::str_replace("ord", "ordered") %>%
      stringr::str_replace("dttm", "datetime") %>%
      stringr::str_replace("drtn", "duration") %>%
      stringr::str_replace("df", "dataframe") %>%
      stringr::str_replace("fn", "function") %>%
      stringr::str_replace("env", "environment") %>%
      stringr::str_replace("sym", "symbol") %>%
      stringr::str_replace("lbl", "label")
  }

  return(type)
}

#' @export
#' @rdname s_type
s_unit <- function(.x) {
  unit <- NA_character_

  if (s_type(.x, .abbr = TRUE) %in% c("units", "drtn", "time")) {
    unit <- units(.x) %>% as.character()
  }

  return(unit)
}
