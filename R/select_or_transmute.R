#' Select and compute columns
#'
#' An enhanced [dplyr::select()] that also accepts data-masking expressions. As
#' with [dplyr::transmute()], only the selected and computed columns are
#' returned.
#'
#' @param .data A data frame, tibble, or data.table.
#' @param ... <[`tidy-select`][dplyr_tidy_select]> selections or
#'   <[`data-masking`][args_data_masking]> expressions. Omit to return the input
#'   unchanged.
#'
#' @returns A table containing the selected and computed columns in argument
#'   order. Data-frame classes and grouping follow [dplyr::select()]; a tibble
#'   input returns a tibble. Grouping columns are retained. Unnamed computed
#'   columns use their expression as the name.
#'
#' @details
#' **Selecting and computing**
#'
#' Selections and computations can be mixed; columns follow argument order.
#' Column names, strings, positions, tidyselect helpers and [varlist()] select
#' existing columns. Selection syntax includes `c()`, `:`, `!`, `&`, `|` and
#' unary `-`. Calls without column names, such as `all_of(vars)` or `seq_len(2)`,
#' also act as selections.
#'
#' Other expressions using columns, such as `lexp >= 70` or
#' `gnp_thousands = gnppc / 1000`, are computed with [dplyr::mutate()] and then
#' selected. Arithmetic is therefore not interpreted as column positions.
#' Named constants (`one = 1`, `label = "x"`, `y = c(1, 2)`) create columns;
#' they do not select or rename existing columns by position.
#'
#' **Names and fallback evaluation**
#'
#' Unnamed names, strings and positions must identify existing columns. An
#' error lists unmatched names; a misspelling never falls back to a same-named
#' object in the calling environment. A symbol holding a character vector is
#' still passed to tidyselect, which deprecates this use; write `all_of(vars)`.
#'
#' If selection fails for another reason, such as duplicate output names, the
#' arguments are retried sequentially with [dplyr::transmute()]. If both attempts
#' fail, the error reports both. Computations run once when selection succeeds;
#' a fallback can evaluate them again. Grouping columns follow dplyr's selection
#' rules.
#'
#' @family selection and preview functions
#' @export
#'
#' @examples
#' lifeexp |>
#'   select_or_transmute()
#'
#' lifeexp |>
#'   select_or_transmute(country, lexp)
#'
#' # Ordinary select() rejects this computed expression.
#' try(dplyr::select(lifeexp, lexp >= 70))
#'
#' lifeexp |>
#'   select_or_transmute(lexp >= 70)
select_or_transmute <- function(.data, ...) {
  check_data_frame(.data)
  if (missing(...)) {
    return(.data)
  }

  original <- .data
  dots <- rlang::enquos(...)
  error_call <- rlang::current_env()
  select_check_unmatched(.data, dots)
  labels <- names(dots)
  selection <- select_is_selection(dots, names(.data))
  if (any(!selection)) {
    unnamed <- !nzchar(labels)
    labels[unnamed] <- vapply(dots[unnamed], rlang::as_label, character(1))
    computed <- dots[!selection]
    names(computed) <- labels[!selection]
    .data <- tryCatch(
      dplyr::mutate(.data, !!!computed),
      error = function(e) {
        select_abort_unrecognised(
          "the expression is not a column selection.",
          conditionMessage(e),
          call = error_call
        )
      }
    )
    dots[!selection] <- lapply(labels[!selection], function(label) {
      rlang::quo(!!rlang::sym(label))
    })
    names(dots)[!selection] <- ""
  }
  selected <- select_attempt(dplyr::select(.data, !!!dots))
  if (is.null(selected$error)) {
    return(selected$value)
  }
  fallback <- select_attempt(dplyr::transmute(original, ...))
  if (is.null(fallback$error)) {
    return(fallback$value)
  }
  select_abort_unrecognised(selected$error, fallback$error)
}

# Both interpretations failed; report each attempt's own message.
select_abort_unrecognised <- function(
  select_error,
  mutate_error,
  call = rlang::caller_env()
) {
  cli::cli_abort(
    c(
      "Neither {.code <tidy-select>} nor {.code <data-masking>} recognised the input.",
      " " = "select() error: {select_error}",
      " " = "mutate() error: {mutate_error}"
    ),
    call = call
  )
}

# Replay warnings only from the attempt that succeeds.
select_attempt <- function(expr) {
  warnings <- list()
  error <- NULL
  value <- tryCatch(
    withCallingHandlers(
      expr,
      warning = function(w) {
        warnings[[length(warnings) + 1L]] <<- w
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) {
      error <<- conditionMessage(e)
      NULL
    }
  )
  if (is.null(error)) {
    for (w in warnings) {
      warning(w)
    }
  }
  list(value = value, error = error)
}

selection_operators <- c("c", ":", "!", "&", "|", "(", "-")

selection_helpers <- c(
  "starts_with",
  "ends_with",
  "contains",
  "matches",
  "num_range",
  "all_of",
  "any_of",
  "everything",
  "last_col",
  "where",
  "one_of",
  "varlist"
)

# Selection syntax goes to select(). Named constants and expressions that use
# columns are computed, so arithmetic on columns is never read as positions.
select_is_selection <- function(dots, columns) {
  named <- nzchar(names(dots))
  vapply(
    seq_along(dots),
    function(i) {
      expr <- rlang::quo_get_expr(dots[[i]])
      if (named[[i]] && select_is_constant(expr)) {
        return(FALSE)
      }
      select_expr_is_selection(expr, columns)
    },
    logical(1)
  )
}

select_is_constant <- function(expr) {
  if (rlang::is_syntactic_literal(expr)) {
    return(!is.null(expr))
  }
  rlang::is_call(expr, "c") &&
    length(expr) > 1L &&
    all(vapply(as.list(expr)[-1L], select_is_constant, logical(1)))
}

select_expr_is_selection <- function(expr, columns) {
  if (rlang::is_symbol(expr)) {
    return(TRUE)
  }
  if (rlang::is_syntactic_literal(expr)) {
    return(!is.logical(expr))
  }
  if (!rlang::is_call(expr)) {
    return(FALSE)
  }
  head <- rlang::call_name(expr)
  if (!is.null(head) && head %in% selection_helpers) {
    return(TRUE)
  }
  operator <- !is.null(head) &&
    head %in% selection_operators &&
    (head != "-" || length(expr) == 2L)
  if (operator) {
    return(all(vapply(
      as.list(expr)[-1L],
      select_expr_is_selection,
      logical(1),
      columns = columns
    )))
  }
  # Other calls select only when they do not use columns, e.g. seq_len(2).
  !any(all.vars(expr) %in% columns)
}

# Unnamed names, strings and positions that match no column are typos, not
# data-masking expressions; report all of them together before selecting.
select_check_unmatched <- function(.data, dots, call = rlang::caller_env()) {
  columns <- names(.data)
  unmatched <- character()
  for (i in seq_along(dots)) {
    if (nzchar(names(dots)[[i]])) {
      next
    }
    expr <- rlang::quo_get_expr(dots[[i]])
    if (rlang::is_symbol(expr) || rlang::is_string(expr)) {
      name <- rlang::as_string(expr)
      if (name %in% columns) {
        next
      }
      if (rlang::is_symbol(expr)) {
        # Deprecated tidyselect external character vectors remain possible.
        value <- tryCatch(rlang::eval_tidy(dots[[i]]), error = function(e) NULL)
        if (is.character(value)) {
          next
        }
      }
      unmatched <- c(unmatched, paste0("`", name, "`"))
    } else if (is.numeric(expr) && length(expr) == 1L) {
      if (
        is.na(expr) ||
          expr != round(expr) ||
          abs(expr) > length(columns) ||
          expr == 0
      ) {
        unmatched <- c(unmatched, paste0("position ", expr))
      }
    }
  }
  if (length(unmatched)) {
    unmatched <- paste(unmatched, collapse = ", ")
    cli::cli_abort(
      c(
        "Can't select columns that don't exist: {unmatched} (the data have {length(columns)} column{?s}).",
        i = "Check the spelling, or name a computed value, e.g. {.code new = expression}."
      ),
      call = call
    )
  }
}
