#' Import and export with various data formats
#'
#' @param data A tibble.
#' @param file A file path.
#' @param ... arguments passed to the appropriate function.
#'
#' @return A tibble.
#' @name import-export
#'
#' @examples
#' # Read data
#' \dontrun{
#' tb <- read_data("data.xlsx")
#' tb <- read_data("data.dta")
#' }
#'
#' # Write data
#' \dontrun{
#' write_data(tb, "data.json")
#' write_data(tb, "data.ftr")
#' }

#' @rdname import-export
#' @export
read_data <- function(file, ...) {
  if (stringr::str_detect(file, "\\.(?i)rdata$")) {
    load(file, ...)
  } else if (stringr::str_detect(file, "\\.(?i)rds$")) {
    return(readr::read_rds(file, ...))
  } else if (stringr::str_detect(file, "\\.(?i)xlsx?$")) {
    return(readxl::read_excel(file, ...))
  } else if (stringr::str_detect(file, "\\.(?i)sav$")) {
    return(haven::read_sav(file, ...))
  } else if (stringr::str_detect(file, "\\.(?i)dta$")) {
    return(haven::read_dta(file, ...))
  } else if (stringr::str_detect(file, "\\.(?i)sas7bdat$")) {
    return(haven::read_sas(file, ...))
  } else if (
    stringr::str_detect(file, "\\.(?i)([tc]sv|txt|gz|bz2|xz|zip)$") ||
      stringr::str_detect(file, "^(ht|f)tps?")
  ) {
    return(vroom::vroom(file, ...))
  } else if (stringr::str_detect(file, "\\.(?i)(ftr|feather)$")) {
    return(arrow::read_feather(file, ...))
  } else if (stringr::str_detect(file, "\\.(?i)json$")) {
    return(jsonlite::fromJSON(file, ...))
  } else if (stringr::str_detect(file, "\\.(?i)html$")) {
    return(rvest::read_html(file, ...))
  } else {
    stop("Unsupported file format")
  }
}

#' @rdname import-export
#' @export
write_data <- function(data, file, ...) {
  if (stringr::str_detect(file, "\\.(?i)rdata$")) {
    save(data, file = file, ...)
  } else if (stringr::str_detect(file, "\\.(?i)rds$")) {
    readr::write_rds(data, file, ...)
  } else if (stringr::str_detect(file, "\\.(?i)xlsx?$")) {
    openxlsx::write.xlsx(data, file, ...)
  } else if (stringr::str_detect(file, "\\.(?i)sav$")) {
    haven::write_sav(data, file, ...)
  } else if (stringr::str_detect(file, "\\.(?i)dta$")) {
    haven::write_dta(data, file, ...)
  } else if (stringr::str_detect(file, "\\.(?i)sas7bdat$")) {
    haven::write_xpt(data, file, ...)
  } else if (
    stringr::str_detect(file, "\\.(?i)(tsv|gz|bz2|xz)$")
  ) {
    vroom::vroom_write(data, file, ...)
  } else if (stringr::str_detect(file, "\\.(?i)txt$")) {
    vroom::vroom_write(data, file, ..., delim = "\t")
  } else if (stringr::str_detect(file, "\\.(?i)csv$")) {
    readr::write_csv(data, file, ...)
  } else if (stringr::str_detect(file, "\\.(?i)(ftr|feather)$")) {
    arrow::write_feather(data, file, ...)
  } else if (stringr::str_detect(file, "\\.(?i)json$")) {
    jsonlite::write_json(data, file, ...)
  } else if (stringr::str_detect(file, "\\.(?i)html$")) {
    htmlTable::htmlTable(data) |>
      as.character() |>
      writeLines(file, ...)
  } else if (stringr::str_detect(file, "\\.(?i)docx$")) {
    officer::read_docx() %>%
      flextable::body_add_flextable(value = flextable::qflextable(data)) %>%
      print(target = file, ...)
  } else if (stringr::str_detect(file, "\\.(?i)tex$")) {
    data %>%
      kableExtra::kable("latex") |>
      writeLines(file, ...)
  } else if (stringr::str_detect(file, "\\.(?i)md$")) {
    data %>%
      kableExtra::kable("markdown") |>
      writeLines(file, ...)
  } else {
    stop("Unsupported file format")
  }
  return(invisible(data))
}
