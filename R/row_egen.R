#' Generate a variable based on row-wise operations.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' * `row_mean()` - Calculate the row-wise mean of selected variables.
#' * `row_sum()` - Calculate the row-wise sum of selected variables.
#' * `row_max()` - Calculate the row-wise maximum of selected variables.
#' * `row_min()` - Calculate the row-wise minimum of selected variables.
#' * `row_median()` - Calculate the row-wise median of selected variables.
#' * `row_var()` - Calculate the row-wise variance of selected variables.
#' * `row_sd()` - Calculate the row-wise standard deviation of selected variables.
#' * `row_unique()` - Calculate the row-wise number of unique values of selected variables.
#' * `row_miss()` - Calculate the row-wise number of missing values of selected variables.
#' * `row_non_miss()` - Calculate the row-wise number of non-missing values of selected variables.
#'
#' @param ... a data frame or tibble, or <[`tidy-select`][dplyr_tidy_select]> within the mutate() function.
#'
#' @details Missing values (including NaN) are ignored in numeric summaries.
#' All-missing rows return NA, except row_sum() returns zero. Variance and SD
#' use the sample denominator and need two observed values. row_unique() counts
#' a missing category once. NULL or zero selected columns are rejected; zero
#' rows return an empty vector. Numeric summaries accept numeric and logical
#' columns; missing-value counts also accept other column types.
#'
#' @return An atomic numeric or integer vector with one value per input row.
#' @name row_egen
#'
#' @examples
#' tb <- tibble::tibble(
#'   x = 1:10,
#'   y = 11:20,
#'   z = 21:30
#' )
#'
#' row_mean(tb)
#'
#' row_sum(tb)
#'
#' row_non_miss(tb)
#'
#' tb %>%
#'   dplyr::mutate(
#'     mean = row_mean(x, y),
#'     sum = row_sum(x, y)
#'   )

#' @rdname row_egen
#' @export
row_mean <- function(...) {
  data <- row_input(...)
  out <- rowMeans(data, na.rm = TRUE)
  out[rowSums(!is.na(data)) == 0L] <- NA_real_
  as.double(out)
}

#' @rdname row_egen
#' @export
row_sum <- function(...) {
  as.double(rowSums(row_input(...), na.rm = TRUE))
}

#' @rdname row_egen
#' @export
row_max <- function(...) {
  row_max_dbl(row_input(...))
}

#' @rdname row_egen
#' @export
row_min <- function(...) {
  row_min_dbl(row_input(...))
}

#' @rdname row_egen
#' @export
row_median <- function(...) {
  data <- row_input(...)
  if (nrow(data) == 0L) {
    return(numeric())
  }
  out <- Rfast::rowMedians(as.matrix(data), na.rm = TRUE)
  out[rowSums(!is.na(data)) == 0L] <- NA_real_
  as.double(out)
}

#' @rdname row_egen
#' @export
row_var <- function(...) {
  data <- row_input(...)
  if (nrow(data) == 0L) {
    return(numeric())
  }
  if (ncol(data) == 1L) {
    return(rep(NA_real_, nrow(data)))
  }
  out <- Rfast::rowVars(as.matrix(data), na.rm = TRUE)
  out[rowSums(!is.na(data)) < 2L] <- NA_real_
  as.double(out)
}

#' @rdname row_egen
#' @export
row_sd <- function(...) {
  sqrt(row_var(...))
}

#' @rdname row_egen
#' @export
row_unique <- function(...) {
  row_unique_dbl(row_input(...))
}

#' @rdname row_egen
#' @export
row_miss <- function(...) {
  as.integer(rowSums(is.na(row_input(..., .numeric = FALSE))))
}

#' @rdname row_egen
#' @export
row_non_miss <- function(...) {
  as.integer(rowSums(!is.na(row_input(..., .numeric = FALSE))))
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

row_input <- function(..., .numeric = TRUE) {
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
  if (.numeric) {
    valid <- vapply(
      data,
      function(x) {
        (is.numeric(x) || is.logical(x)) && !is.complex(x) && is.null(dim(x))
      },
      logical(1)
    )
    if (!all(valid)) {
      stop(
        "Numeric row calculations require numeric or logical columns: ",
        paste(names(data)[!valid], collapse = ", "),
        call. = FALSE
      )
    }
    # Rfast's na.rm path needs ordinary NA rather than NaN inputs.
    data <- dplyr::mutate(
      data,
      dplyr::across(dplyr::everything(), function(x) {
        values <- as.double(x)
        values[is.nan(values)] <- NA_real_
        values
      })
    )
  }
  data
}
