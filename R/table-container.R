# Newly shaped results preserve the container, not obsolete schema metadata.
table_restore <- function(
  out,
  template,
  type = "auto",
  call = rlang::caller_env()
) {
  if (!is.data.frame(out)) {
    if (is.list(out)) {
      return(lapply(
        out,
        table_restore,
        template = template,
        type = type,
        call = call
      ))
    }
    return(out)
  }
  out <- tibble::as_tibble(dplyr::ungroup(out), .name_repair = "minimal")
  if (type == "auto") {
    if (inherits(template, "data.table")) {
      table_check_data_table(call)
      out <- data.table::as.data.table(out)
    } else if (is.data.frame(template) && !inherits(template, "tbl_df")) {
      out <- as.data.frame(out)
    }
    if (inherits(template, "statart_preview")) {
      out <- preview_restore(out, template)
    }
  }
  out
}

# Avoid reference semantics and preview dispatch in internal calculations.
table_working_data <- function(data, call = rlang::caller_env()) {
  if (inherits(data, "statart_preview")) {
    data <- unpreview_table(data)
  }
  if (inherits(data, "data.table")) {
    table_check_data_table(call)
    data <- tibble::as_tibble(data)
  }
  data
}

# Spatial geometry is not a grouping or measured attribute for aggregation.
# Keep this normalization separate from selection, inspection and browsing.
aggregation_working_data <- function(
  data,
  override_groups = FALSE,
  call = rlang::caller_env()
) {
  data <- table_working_data(data, call)
  if (!is.data.frame(data)) {
    return(data)
  }
  geometry <- vapply(data, inherits, logical(1), what = "sfc")
  if (!inherits(data, "sf") && !any(geometry)) {
    return(data)
  }
  if (override_groups) {
    data <- dplyr::ungroup(data)
  }
  # Ungrouping sf data can reorder columns, so identify geometry by name.
  geometry <- names(data)[vapply(data, inherits, logical(1), what = "sfc")]
  if (any(dplyr::group_vars(data) %in% geometry)) {
    cli::cli_abort(
      "Geometry columns cannot be aggregation grouping keys.",
      call = call
    )
  }
  class(data) <- setdiff(class(data), "sf")
  attr(data, "sf_column") <- NULL
  attr(data, "agr") <- NULL
  dplyr::select(data, !tidyselect::any_of(geometry))
}

# Serialized tables retain their class even without the optional package.
table_check_data_table <- function(call = rlang::caller_env()) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    cli::cli_abort(
      "Install the optional package {.pkg data.table} to work with data.table inputs.",
      call = call
    )
  }
}

# Native data.table expressions delegated by preview methods use DT semantics.
.datatable.aware <- TRUE
