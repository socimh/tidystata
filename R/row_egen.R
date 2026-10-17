#' Calculate summaries across columns within each row
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' * `row_mean()`, `row_sum()`, and `row_median()` calculate row arithmetic.
#' * `row_min()` and `row_max()` select the smallest and largest row values.
#' * `row_var()` and `row_sd()` calculate sample variance and standard deviation.
#' * `row_unique()` counts distinct values, including one missing category.
#' * `row_miss()` and `row_non_miss()` count missing and observed values.
#'
#' @param ... A data frame or tibble, or
#'   <[`tidy-select`][dplyr::dplyr_tidy_select]> expressions inside
#'   [dplyr::mutate()]. Each selected column must be one-dimensional.
#'
#' @details
#' All helpers preserve the input. Missingness is determined from the original
#' columns, including tagged and SPSS user-missing values. Arithmetic and extrema
#' omit missing values. All-missing rows return a typed `NA`, except `row_sum()`
#' returns zero. Variance and standard deviation use the sample denominator and
#' require at least two observed values. Zero-row inputs return typed empty
#' vectors; `NULL` and zero selected columns are rejected.
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
#' Means and sums use base R's compiled row aggregations. Extrema, distinct
#' counts, medians, and sample variance/standard deviation use native C++ kernels
#' registered through cpp11; Rfast is no longer required.
#'
#' @return A vector with one value per input row. Extrema retain the compatible
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

#' @rdname row_egen
#' @export
row_mean <- function(...) {
  row_numeric_summary(row_input(...), "mean")
}

#' @rdname row_egen
#' @export
row_sum <- function(...) {
  row_numeric_summary(row_input(...), "sum")
}

#' @rdname row_egen
#' @export
row_max <- function(...) {
  row_extreme_typed(row_input(...), TRUE)
}

#' @rdname row_egen
#' @export
row_min <- function(...) {
  row_extreme_typed(row_input(...), FALSE)
}

#' @rdname row_egen
#' @export
row_median <- function(...) {
  row_numeric_summary(row_input(...), "median")
}

#' @rdname row_egen
#' @export
row_var <- function(...) {
  row_numeric_summary(row_input(...), "var")
}

#' @rdname row_egen
#' @export
row_sd <- function(...) {
  row_numeric_summary(row_input(...), "sd")
}

#' @rdname row_egen
#' @export
row_unique <- function(...) {
  data <- row_input(...)
  if (all(vapply(data, row_plain_numeric, logical(1)))) {
    return(row_unique_dbl(row_double_columns(data)))
  }
  values <- row_common_values(data)
  keys <- as.double(vctrs::vec_match(values, values))
  keys[unlist(lapply(data, is.na), use.names = FALSE)] <- NA_real_
  row_unique_dbl(row_key_columns(keys, nrow(data), ncol(data)))
}

#' @rdname row_egen
#' @export
row_miss <- function(...) {
  as.integer(rowSums(is.na(row_input(...))))
}

#' @rdname row_egen
#' @export
row_non_miss <- function(...) {
  as.integer(rowSums(!is.na(row_input(...))))
}

row_plain_numeric <- function(x) {
  !is.object(x) && typeof(x) %in% c("logical", "integer", "double")
}

row_double_columns <- function(data) {
  tibble::as_tibble(lapply(data, function(x) {
    missing <- is.na(x)
    values <- as.double(x)
    # Determine missingness before stripping SPSS user-missing metadata.
    values[missing] <- NA_real_
    values
  }))
}

row_common_values <- function(data) {
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
      stop(
        "Selected columns have incompatible types: ",
        conditionMessage(e),
        call. = FALSE
      )
    }
  )
  original_missing <- unlist(lapply(data, is.na), use.names = FALSE)
  if (any(is.na(values) != original_missing)) {
    stop(
      "Selected columns have incompatible missing-value definitions; ",
      "convert labelled missing values explicitly before combining them.",
      call. = FALSE
    )
  }
  values
}

row_key_columns <- function(keys, rows, columns) {
  tibble::as_tibble(stats::setNames(
    lapply(seq_len(columns), function(j) {
      keys[seq_len(rows) + (j - 1L) * rows]
    }),
    paste0("x", seq_len(columns))
  ))
}

row_extreme_typed <- function(data, maximum) {
  kernel <- if (maximum) row_max_dbl else row_min_dbl
  ordered <- vapply(data, is.ordered, logical(1))
  if (any(ordered) && !all(ordered)) {
    stop(
      "Ordered factor extrema require compatible ordered columns; ",
      "convert explicitly before combining them with other types.",
      call. = FALSE
    )
  }
  if (all(vapply(data, row_plain_numeric, logical(1)))) {
    prototype <- vctrs::vec_ptype_common(!!!data)
    return(vctrs::vec_cast(kernel(row_double_columns(data)), prototype))
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
    stop(
      "Row extrema require supported ordered columns; unordered factors, lists ",
      "and complex columns have no supported ordering: ",
      paste(names(data)[!supported], collapse = ", "),
      call. = FALSE
    )
  }
  values <- row_common_values(data)
  # Rank original values without converting integer64 payloads or class units
  # to doubles. The C++ kernel compares exact integer ranks, then R slices the
  # original common vector to retain its type and metadata.
  ranks <- as.double(vctrs::vec_rank(values, ties = "dense", incomplete = "na"))
  best <- kernel(row_key_columns(ranks, nrow(data), ncol(data)))
  vctrs::vec_set_names(vctrs::vec_slice(values, match(best, ranks)), NULL)
}

row_numeric_summary <- function(data, operation) {
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
      stop(
        "Calendar Date/POSIXct columns support mean and median, not sums or dispersion; convert explicitly first.",
        call. = FALSE
      )
    }
    if (duration && operation == "var") {
      stop(
        "Duration variance has squared units; convert durations explicitly to one numeric unit first.",
        call. = FALSE
      )
    }
    if (!calendar && !duration && !measured) {
      stop(
        "Numeric row calculations require compatible supported numeric or logical columns; integer64 and other classes require explicit conversion.",
        call. = FALSE
      )
    }
    values <- vctrs::vec_cast_common(!!!data)
    if (measured) {
      row_check_unit_scale(data, operation)
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
  data <- row_double_columns(data)
  observed <- rowSums(!is.na(data))
  out <- if (nrow(data) == 0L) {
    numeric()
  } else {
    switch(
      operation,
      sum = rowSums(data, na.rm = TRUE),
      mean = rowMeans(data, na.rm = TRUE),
      median = row_median_dbl(data),
      var = row_var_dbl(data),
      sd = row_sd_dbl(data)
    )
  }
  if (operation != "sum") {
    out[observed < if (operation %in% c("var", "sd")) 2L else 1L] <- NA_real_
  }
  out <- as.double(out)
  if (is.null(prototype)) out else vctrs::vec_restore(out, prototype)
}

row_check_unit_scale <- function(data, operation) {
  for (x in data) {
    base <- tryCatch(
      as.double(units::convert_to_base(units::set_units(
        c(0, 1, 2),
        units(x),
        mode = "standard"
      ))),
      error = function(e) {
        stop(
          "Unsupported measurement scale; convert to an explicit linear unit first: ",
          conditionMessage(e),
          call. = FALSE
        )
      }
    )
    increments <- diff(base)
    if (
      !all(is.finite(base)) ||
        increments[1L] <= 0 ||
        !isTRUE(all.equal(increments[1L], increments[2L], tolerance = 1e-10))
    ) {
      stop(
        "Nonlinear measurement scales require explicit conversion to a linear unit first.",
        call. = FALSE
      )
    }
    if (operation %in% c("sum", "var", "sd") && base[1L] != 0) {
      stop(
        "Sums and dispersion of offset units require explicit conversion to a zero-origin unit first.",
        call. = FALSE
      )
    }
  }
}

# Test the context without evaluating selections or computed arguments twice.
dots_is_tibble <- function(...) {
  tryCatch(
    {
      dplyr::cur_group_id()
      FALSE
    },
    error = function(e) TRUE
  )
}

row_input <- function(...) {
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
      data <- dplyr::pick(!!!dots)
    }
  }
  if (ncol(data) == 0L) {
    stop(
      "Select at least one column; NULL and zero columns are not supported.",
      call. = FALSE
    )
  }
  valid <- vapply(data, function(x) is.null(dim(x)), logical(1))
  if (!all(valid)) {
    stop(
      "Row calculations require one-dimensional columns: ",
      paste(names(data)[!valid], collapse = ", "),
      call. = FALSE
    )
  }
  data
}
