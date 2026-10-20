#' Calculate summaries across columns within each row
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' * `row_mean()`, `row_sum()`, and `row_median()` calculate row arithmetic.
#' * `row_min()` and `row_max()` select the smallest and largest row values.
#' * `row_var()` and `row_sd()` calculate sample variance and standard deviation.
#' * `row_unique()` counts distinct values, including one missing category.
#'   `row_nvals()` follows egenmore's `egen rownvals()` and ignores missing
#'   values unless `.missing = TRUE`, when it equals `row_unique()`.
#' * `row_miss()` and `row_non_miss()` count missing and observed values.
#'
#' @param ... A data frame or tibble, or
#'   <[`tidy-select`][dplyr::dplyr_tidy_select]> expressions inside
#'   [dplyr::mutate()]. Each selected column must be one-dimensional.
#' @param na.rm For arithmetic and extrema helpers, a single logical value. If
#'   `TRUE` (the default), omit missing values; if `FALSE`, any missing input
#'   makes that row's result missing. Count helpers (`row_unique()`,
#'   `row_miss()`, `row_non_miss()`) reject `na.rm`.
#' @param .values For `row_min()` and `row_max()`, additional values to compare
#'   with selected columns: a vector, or a list of vectors. Each must have
#'   length one or the number of input rows (the current group size inside
#'   grouped `mutate()`). Values must have compatible supported types.
#' @param .missing For `row_nvals()`, a single `TRUE` or `FALSE`. If `FALSE`
#'   (the default), missing values are not counted, as in egenmore's
#'   `rownvals()`; if `TRUE`, they count as one value, as in `row_unique()`.
#'
#' @details
#' All helpers preserve the input. Missingness is determined from the original
#' columns, including tagged and SPSS user-missing values. Arithmetic and extrema
#' omit missing values by default. All-missing rows return a typed `NA`, except
#' `row_sum(na.rm = TRUE)` returns zero. Variance and standard deviation use the
#' sample denominator and require at least two observed values. Zero-row inputs
#' return typed empty vectors; `NULL` and zero selected columns are rejected.
#'
#' @section Extrema:
#' `row_min()` and `row_max()` retain the compatible common type of the selected
#' columns. Logical inputs return logical values, integer inputs return integers,
#' and mixed logical/integer/double inputs use their common numeric type.
#' Supported ordered types also include character vectors, ordered factors,
#' `Date`, `POSIXct`, durations, measured vectors, `integer64`, and labelled
#' vectors. Character values use C lexical ordering without numeric parsing;
#' ordered factors use their level order and cannot be mixed with other types.
#' Labelled values are compared by their underlying values. Compatible units
#' are normalized before comparison.
#' Unordered factors, lists, complex values, and incompatible combinations are
#' rejected rather than assigned an arbitrary ordering.
#' Like [pmin()] and [pmax()], bare numeric constants in `row_min()` and
#' `row_max()` are values, not column positions: `row_min(x, 0.5)` caps `x` at
#' 0.5. Inside `mutate()`, a symbol that is not a column but names a numeric
#' vector in the calling environment is also used as values. Select columns by
#' position with `c()` or a tidyselect helper, for example `row_min(c(1, 2))`.
#' Length-one constants (including those in `.values`) never fill a row whose
#' other inputs are all missing; such rows stay `NA`, as with `pmin()`.
#'
#' @section Arithmetic:
#' Plain logical, integer, double, and numeric labelled columns return double
#' vectors. Labels are dropped after applying the original missingness mask.
#' `integer64` arithmetic requires explicit conversion so potential precision
#' loss is a deliberate choice.
#'
#' Columns from the same calendar family (`Date` or `POSIXct`) support mean and
#' median while retaining their common class and metadata. Calendar sums,
#' variance, and standard deviation require explicit numeric conversion first.
#' Durations support mean, median, sum, and standard deviation and return
#' `difftime` vectors in a common unit. For duration variance, explicitly convert
#' to one numeric unit first because variance has squared units.
#'
#' Compatible measured vectors on linear zero-origin scales are normalized to a
#' common unit. Mean, median, sum, and standard deviation retain that unit;
#' variance returns squared units. Offset scales such as Celsius and Fahrenheit
#' support mean and median only. Convert explicitly to a zero-origin unit before
#' requesting sums or dispersion. Nonlinear scales require explicit conversion
#' to a linear unit before any arithmetic. Other classes and incompatible type
#' combinations are rejected. Measured arithmetic requires units >= 1.0.0.
#'
#' @section Counts:
#' `row_unique()` combines compatible column types and counts distinct values
#' without dropping their identities through numeric conversion. This includes
#' compatible factors, labelled vectors, calendar/measured vectors, `integer64`,
#' list columns, and complex vectors. Missing values count as one category.
#' List elements are compared as whole values rather than flattened.
#' For extrema and distinct counts, common-type conversion must preserve each
#' original value's missingness. Conflicting SPSS missing-value definitions
#' that would turn an observed value into a missing value produce an error;
#' harmonize those definitions explicitly before combining the columns.
#'
#' `row_miss()` and `row_non_miss()` use each original column's `is.na()` result.
#' Scalar missing list elements are missing; `NULL` and empty list elements are
#' observed. Count helpers return integer vectors.
#'
#' @section Implementation:
#' All row summaries and counts use native C++ kernels registered through
#' cpp11, which read logical, integer and double columns directly and count
#' missing values in the same pass. Means and sums give the same results as
#' [base::rowMeans()] and [base::rowSums()] without first copying the columns
#' into a matrix. Rfast is no longer required.
#'
#' @returns A vector with one value per input row. Extrema retain the compatible
#'   common type; arithmetic returns doubles or a supported class as described
#'   above; unique and missing-value counts return integers.
#' @name row_egen
#'
#' @examples
#' tb <- tibble::tibble(x = c(1, 2, NA), y = c(3, NA, NA))
#' row_mean(tb)
#' row_sum(tb)
#' row_non_miss(tb)
#'
#' tb |>
#'   dplyr::mutate(mean = row_mean(x, y), sum = row_sum(x, y))
#' tb |>
#'   dplyr::mutate(capped = row_min(x, .values = 0.5))
#' row_sum(tb, na.rm = FALSE)
#'
#' flags <- tibble::tibble(a = c(TRUE, FALSE, NA), b = c(FALSE, NA, NA))
#' row_max(flags) # TRUE, FALSE, NA, with logical type
#'
#' dates <- tibble::tibble(
#'   start = as.Date(c("2024-01-01", NA)),
#'   end = as.Date(c("2024-01-03", "2024-01-05"))
#' )
#' row_min(dates)
#' row_mean(dates)
#' @family variable generation functions

#' @rdname row_egen
#' @export
row_mean <- function(..., na.rm = TRUE) {
  check_bool(na.rm)
  row_numeric_summary(row_input(...), "mean", na.rm = na.rm)
}

#' @rdname row_egen
#' @export
row_sum <- function(..., na.rm = TRUE) {
  check_bool(na.rm)
  row_numeric_summary(row_input(...), "sum", na.rm = na.rm)
}

#' @rdname row_egen
#' @export
row_max <- function(..., .values = NULL, na.rm = TRUE) {
  check_bool(na.rm)
  row_extreme_constants(row_extreme_input(..., .values = .values), TRUE, na.rm)
}

#' @rdname row_egen
#' @export
row_min <- function(..., .values = NULL, na.rm = TRUE) {
  check_bool(na.rm)
  row_extreme_constants(row_extreme_input(..., .values = .values), FALSE, na.rm)
}

#' @rdname row_egen
#' @export
row_median <- function(..., na.rm = TRUE) {
  check_bool(na.rm)
  row_numeric_summary(row_input(...), "median", na.rm = na.rm)
}

#' @rdname row_egen
#' @export
row_var <- function(..., na.rm = TRUE) {
  check_bool(na.rm)
  row_numeric_summary(row_input(...), "var", na.rm = na.rm)
}

#' @rdname row_egen
#' @export
row_sd <- function(..., na.rm = TRUE) {
  check_bool(na.rm)
  row_numeric_summary(row_input(...), "sd", na.rm = na.rm)
}

#' @rdname row_egen
#' @export
row_unique <- function(...) {
  row_reject_na_rm(..., fn = "row_unique")
  row_unique_count(row_input(...))
}

#' @rdname row_egen
#' @export
row_nvals <- function(..., .missing = FALSE) {
  check_bool(.missing)
  row_reject_na_rm(..., fn = "row_nvals")
  # Select the columns once for both counts.
  data <- row_input(...)
  out <- row_unique_count(data)
  if (.missing) {
    return(out)
  }
  out - (row_missing_count(data) > 0L)
}

#' @rdname row_egen
#' @export
row_miss <- function(...) {
  row_reject_na_rm(..., fn = "row_miss")
  row_missing_count(row_input(...))
}

#' @rdname row_egen
#' @export
row_non_miss <- function(...) {
  row_reject_na_rm(..., fn = "row_non_miss")
  data <- row_input(...)
  ncol(data) - row_missing_count(data)
}

row_unique_count <- function(data, call = rlang::caller_env()) {
  if (all(vapply(data, row_plain_numeric, logical(1)))) {
    return(row_unique_dbl(unname(as.list(data))))
  }
  values <- row_common_values(data, call)
  keys <- as.double(vctrs::vec_match(values, values))
  keys[unlist(lapply(data, is.na), use.names = FALSE)] <- NA_real_
  row_unique_dbl(row_key_columns(keys, nrow(data), ncol(data)))
}

# Missing values per row, from each column's is.na() as is.na() on the data
# frame gives them. Plain vectors are read natively; other classes pass their
# is.na() result, which keeps methods such as SPSS user-missing values.
row_missing_count <- function(data) {
  plain <- vapply(
    data,
    function(x) row_plain_numeric(x) || (is.character(x) && !is.object(x)),
    logical(1)
  )
  columns <- unname(as.list(data))
  columns[!plain] <- lapply(columns[!plain], is.na)
  valid <- vapply(
    columns[!plain],
    function(x) is.logical(x) && is.null(dim(x)) && length(x) == nrow(data),
    logical(1)
  )
  if (!all(valid)) {
    return(as.integer(rowSums(is.na(data))))
  }
  row_na_count(columns, !plain)
}

row_reject_na_rm <- function(..., fn, call = rlang::caller_env()) {
  if ("na.rm" %in% ...names()) {
    cli::cli_abort(
      "{.arg na.rm} is not an argument of {.fn {fn}}; it counts values across all selected columns.",
      call = call
    )
  }
}

row_is_number_literal <- function(expr) {
  if (
    is.call(expr) && length(expr) == 2L && identical(expr[[1L]], quote(`-`))
  ) {
    expr <- expr[[2L]]
  }
  is.numeric(expr) && length(expr) == 1L
}

# Split extrema inputs into selected columns, full-length vectors and scalar
# constants. Constants never make an otherwise all-missing row observed.
row_extreme_input <- function(..., .values = NULL) {
  # Dots hold user columns, so report errors through the caller's frame.
  rlang::local_error_call(rlang::caller_env())
  dots <- rlang::enquos(...)
  in_mutate <- !dots_is_tibble()
  constant <- vapply(
    dots,
    function(q) row_is_number_literal(rlang::quo_get_expr(q)),
    logical(1)
  )
  extra <- lapply(dots[constant], rlang::eval_tidy)
  rest <- dots[!constant]
  if (in_mutate && length(rest)) {
    columns <- c(
      names(dplyr::pick(dplyr::everything())),
      names(dplyr::cur_group())
    )
    external <- vapply(
      rest,
      function(q) {
        expr <- rlang::quo_get_expr(q)
        if (!rlang::is_symbol(expr) || rlang::as_string(expr) %in% columns) {
          return(FALSE)
        }
        value <- tryCatch(rlang::eval_tidy(q), error = function(e) NULL)
        is.numeric(value) && is.null(dim(value)) && !is.object(value)
      },
      logical(1)
    )
    extra <- c(extra, lapply(rest[external], rlang::eval_tidy))
    rest <- rest[!external]
  }
  if (!is.null(.values)) {
    extra <- c(
      extra,
      if (is.list(.values) && !is.object(.values)) .values else list(.values)
    )
  }
  data <- if (length(rest)) {
    rlang::inject(row_input(!!!unname(rest)))
  } else {
    rows <- if (in_mutate) dplyr::n() else max(c(1L, lengths(extra)))
    tibble::new_tibble(list(), nrow = rows)
  }
  rows <- nrow(data)
  scalar <- lengths(extra) == 1L
  if (any(!scalar)) {
    data <- row_add_values(data, unname(extra[!scalar]))
  }
  scalars <- extra[scalar]
  if (ncol(data) == 0L && !length(scalars)) {
    cli::cli_abort(
      "Select at least one column; {.code NULL} and zero columns are not supported."
    )
  }
  list(data = data, scalars = scalars)
}

row_extreme_constants <- function(
  input,
  maximum,
  na.rm,
  call = rlang::caller_env()
) {
  data <- input$data
  missing <- if (ncol(data)) row_missing_count(data) else integer(nrow(data))
  observed <- if (ncol(data)) missing < ncol(data) else rep(TRUE, nrow(data))
  complete <- missing == 0L
  if (length(input$scalars)) {
    data <- row_add_values(data, unname(input$scalars), call)
  }
  out <- row_extreme_typed(data, maximum, call)
  drop <- !observed | (!na.rm & !complete)
  if (any(drop)) {
    out <- vctrs::vec_assign(out, drop, vctrs::vec_init(out, 1L))
  }
  out
}

row_plain_numeric <- function(x) {
  !is.object(x) && typeof(x) %in% c("logical", "integer", "double")
}

# Columns for the native kernels, which read logical, integer and double
# vectors directly. Other classes become doubles with NA wherever is.na() is
# TRUE, determined before SPSS user-missing metadata is stripped.
row_kernel_columns <- function(data) {
  unname(lapply(data, function(x) {
    if (row_plain_numeric(x)) {
      return(x)
    }
    missing <- is.na(x)
    values <- as.double(x)
    values[missing] <- NA_real_
    values
  }))
}

row_common_values <- function(data, call = rlang::caller_env()) {
  normalized <- lapply(data, function(x) {
    missing <- is.na(x)
    if (any(missing) && !is.list(x)) {
      x <- vctrs::vec_assign(x, missing, vctrs::vec_init(x, 1L))
    }
    x
  })
  # vctrs performs lossless common-type casting, including unit conversion.
  values <- tryCatch(
    vctrs::vec_c(!!!unname(normalized)),
    error = function(e) {
      cli::cli_abort(
        "Selected columns have incompatible types.",
        parent = e,
        call = call
      )
    }
  )
  original_missing <- unlist(lapply(data, is.na), use.names = FALSE)
  if (any(is.na(values) != original_missing)) {
    cli::cli_abort(
      "Selected columns have incompatible missing-value definitions; convert labelled missing values explicitly before combining them.",
      call = call
    )
  }
  values
}

row_key_columns <- function(keys, rows, columns) {
  lapply(seq_len(columns), function(j) {
    keys[seq_len(rows) + (j - 1L) * rows]
  })
}

row_add_values <- function(data, values, call = rlang::caller_env()) {
  if (is.null(values)) {
    return(data)
  }
  extra <- if (is.list(values) && !is.object(values)) values else list(values)
  rows <- nrow(data)
  for (i in seq_along(extra)) {
    value <- extra[[i]]
    if (is.list(value) || !is.null(dim(value))) {
      cli::cli_abort(
        "{.arg .values} must contain one-dimensional vectors.",
        call = call
      )
    }
    if (is.null(value) || !length(value) %in% c(1L, rows)) {
      cli::cli_abort(
        "Each vector in {.arg .values} must have length one or the input row count ({rows}).",
        call = call
      )
    }
    extra[[i]] <- vctrs::vec_recycle(value, rows)
  }
  names(extra) <- utils::tail(
    make.unique(c(names(data), rep(".values", length(extra)))),
    length(extra)
  )
  tibble::as_tibble(c(as.list(data), extra))
}

row_extreme_typed <- function(data, maximum, call = rlang::caller_env()) {
  kernel <- if (maximum) row_max_dbl else row_min_dbl
  ordered <- vapply(data, is.ordered, logical(1))
  if (any(ordered) && !all(ordered)) {
    cli::cli_abort(
      "Ordered factor extrema require compatible ordered columns; convert explicitly before combining them with other types.",
      call = call
    )
  }
  if (all(vapply(data, row_plain_numeric, logical(1)))) {
    prototype <- vctrs::vec_ptype_common(!!!data)
    return(vctrs::vec_cast(kernel(row_kernel_columns(data)), prototype))
  }
  supported <- vapply(
    data,
    function(x) {
      row_plain_numeric(x) ||
        is.character(x) ||
        is.ordered(x) ||
        inherits(
          x,
          c(
            "Date",
            "POSIXct",
            "difftime",
            "units",
            "integer64",
            "haven_labelled"
          )
        )
    },
    logical(1)
  )
  if (!all(supported)) {
    unsupported <- paste(names(data)[!supported], collapse = ", ")
    cli::cli_abort(
      "Row extrema require supported ordered columns; unordered factors, lists and complex columns have no supported ordering: {unsupported}",
      call = call
    )
  }
  values <- row_common_values(data, call)
  # Rank original values without converting integer64 payloads or class units
  # to doubles. The C++ kernel compares exact integer ranks, then R slices the
  # original common vector to retain its type and metadata.
  ranks <- as.double(vctrs::vec_rank(values, ties = "dense", incomplete = "na"))
  best <- kernel(row_key_columns(ranks, nrow(data), ncol(data)))
  vctrs::vec_set_names(vctrs::vec_slice(values, match(best, ranks)), NULL)
}

row_numeric_summary <- function(
  data,
  operation,
  na.rm = TRUE,
  call = rlang::caller_env()
) {
  plain <- vapply(
    data,
    function(x) {
      row_plain_numeric(x) ||
        (inherits(x, "haven_labelled") && typeof(x) %in% c("integer", "double"))
    },
    logical(1)
  )
  prototype <- NULL
  if (!all(plain)) {
    calendar <- all(vapply(data, inherits, logical(1), "Date")) ||
      all(vapply(data, inherits, logical(1), "POSIXct"))
    duration <- all(vapply(data, inherits, logical(1), "difftime"))
    measured <- all(vapply(data, inherits, logical(1), "units"))
    if (calendar && !operation %in% c("mean", "median")) {
      cli::cli_abort(
        "Calendar Date/POSIXct columns support mean and median, not sums or dispersion; convert explicitly first.",
        call = call
      )
    }
    if (duration && operation == "var") {
      cli::cli_abort(
        "Duration variance has squared units; convert durations explicitly to one numeric unit first.",
        call = call
      )
    }
    if (!calendar && !duration && !measured) {
      cli::cli_abort(
        "Numeric row calculations require compatible supported numeric or logical columns; integer64 and other classes require explicit conversion.",
        call = call
      )
    }
    values <- vctrs::vec_cast_common(!!!data)
    if (measured) {
      row_check_unit_scale(data, operation, call)
    }
    prototype <- vctrs::vec_ptype_common(!!!values)
    if (duration) {
      # SD is a duration, even when inputs describe hms times of day.
      prototype <- as.difftime(numeric(), units = attr(prototype, "units"))
    } else if (measured && operation == "var") {
      prototype <- prototype^2
    }
    data <- tibble::as_tibble(values)
  }
  # The kernels return NA where too few values are observed (one, or two for
  # var and sd) or, with na.rm = FALSE, where any value is missing.
  out <- if (nrow(data) == 0L) {
    numeric()
  } else {
    columns <- row_kernel_columns(data)
    switch(
      operation,
      sum = row_sum_dbl(columns, na.rm),
      mean = row_mean_dbl(columns, na.rm),
      median = row_median_dbl(columns, na.rm),
      var = row_var_dbl(columns, na.rm),
      sd = row_sd_dbl(columns, na.rm)
    )
  }
  if (is.null(prototype)) out else vctrs::vec_restore(out, prototype)
}

row_check_unit_scale <- function(data, operation, call = rlang::caller_env()) {
  for (x in data) {
    base <- tryCatch(
      as.double(units::convert_to_base(units::set_units(
        c(0, 1, 2),
        units(x),
        mode = "standard"
      ))),
      error = function(e) {
        cli::cli_abort(
          "Unsupported measurement scale; convert to an explicit linear unit first.",
          parent = e,
          call = call
        )
      }
    )
    increments <- diff(base)
    if (
      !all(is.finite(base)) ||
        increments[1L] <= 0 ||
        !isTRUE(all.equal(increments[1L], increments[2L], tolerance = 1e-10))
    ) {
      cli::cli_abort(
        "Nonlinear measurement scales require explicit conversion to a linear unit first.",
        call = call
      )
    }
    if (operation %in% c("sum", "var", "sd") && base[1L] != 0) {
      cli::cli_abort(
        "Sums and dispersion of offset units require explicit conversion to a zero-origin unit first.",
        call = call
      )
    }
  }
}

# Test the context without evaluating selections or computed arguments twice.
dots_is_tibble <- function(...) {
  if (!in_dplyr_verb()) {
    return(TRUE)
  }
  tryCatch(
    {
      dplyr::cur_group_id()
      FALSE
    },
    error = function(e) TRUE
  )
}

# A dplyr data mask is active only while a dplyr verb is on the call stack.
# Probing with dplyr::cur_group_id() outside one signals a classed error whose
# message rlang formats with cli, costing milliseconds per call, so skip the
# probe when no frame belongs to dplyr.
in_dplyr_verb <- function() {
  dplyr <- asNamespace("dplyr")
  for (frame in sys.frames()) {
    if (identical(topenv(frame), dplyr)) {
      return(TRUE)
    }
  }
  FALSE
}

# pick() omits grouping columns. When a selection fails, retry with the group
# keys included, so row helpers can use a grouping column as pmin() can.
row_pick <- function(dots) {
  tryCatch(
    dplyr::pick(!!!dots),
    error = function(e) {
      keys <- dplyr::cur_group()
      if (ncol(keys) == 0L) {
        stop(e)
      }
      full <- dplyr::bind_cols(
        dplyr::pick(dplyr::everything()),
        vctrs::vec_slice(keys, rep(1L, dplyr::n()))
      )
      selected <- tryCatch(
        tidyselect::eval_select(
          rlang::expr(c(!!!dots)),
          full,
          allow_rename = FALSE
        ),
        error = function(e2) stop(e)
      )
      full[selected]
    }
  )
}

row_input <- function(...) {
  # Dots hold user columns, so report errors through the caller's frame.
  rlang::local_error_call(rlang::caller_env())
  if (dots_is_tibble(...)) {
    data <- tibble::tibble(...)
  } else {
    # Capture selectors before probing a single data-frame expression, so their
    # original expressions/environments survive evaluation of the promise.
    dots <- rlang::enquos(...)
    candidate <- NULL
    probe_warnings <- list()
    if (length(dots) == 1L) {
      candidate <- tryCatch(
        withCallingHandlers(
          rlang::eval_tidy(dots[[1L]]),
          warning = function(w) {
            probe_warnings[[length(probe_warnings) + 1L]] <<- w
            invokeRestart("muffleWarning")
          }
        ),
        error = function(e) NULL
      )
    }
    if (is.data.frame(candidate)) {
      data <- candidate
      for (condition in probe_warnings) {
        warning(condition)
      }
    } else {
      data <- row_pick(dots)
    }
  }
  if (ncol(data) == 0L) {
    cli::cli_abort(
      "Select at least one column; {.code NULL} and zero columns are not supported."
    )
  }
  valid <- vapply(data, function(x) is.null(dim(x)), logical(1))
  if (!all(valid)) {
    invalid <- paste(names(data)[!valid], collapse = ", ")
    cli::cli_abort(
      "Row calculations require one-dimensional columns: {invalid}"
    )
  }
  data
}
