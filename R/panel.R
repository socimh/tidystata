#' Panel lags, leads and differences
#'
#' @description
#' Time-aware versions of [dplyr::lag()] and [dplyr::lead()], following
#' Stata's time-series operators after `xtset`:
#'
#' * `s_lag(x, n, time = t)` is `Ln.x`: the value of `x` at time `t - n`.
#' * `s_lead(x, n, time = t)` is `Fn.x`: the value of `x` at time `t + n`.
#' * `s_diff(x, n, time = t)` is `Dn.x`: the `n`th difference, so
#'   `s_diff(x, time = t)` is `x - L.x` and `s_diff(x, 2, time = t)` is
#'   `D.(D.x)`.
#'
#' Values are found by time, not by row position, so gaps in time give
#' missing values and the row order does not matter. Use them in
#' [dplyr::mutate()] with the panel identifier in `.by` or [dplyr::group_by()],
#' as `xtset id year` would declare it.
#'
#' @param x A vector. `s_diff()` needs a numeric, logical, `Date`, date-time
#' or `difftime` vector.
#' @param n A single non-negative whole number: the number of periods
#' (`s_lag()`, `s_lead()`) or the order of the difference (`s_diff()`).
#' @param time The time variable, unique within each panel. Supported types:
#' * numbers, including labelled numbers and Stata `%tm`, `%tq` or `%ty`
#'   variables read by haven, which arrive as plain numbers;
#' * `Date` and date-times (`POSIXct`/`POSIXlt`), with `unit`;
#' * period classes, which need no `unit`: tsibble's `yearweek()`,
#'   `yearmonth()` and `yearquarter()`, and zoo's `yearmon` and `yearqtr`;
#' * ordered factors, such as survey waves, where each level is one period in
#'   level order, so an unused level is a gap.
#'
#' Missing times give missing results. Text and unordered factors are not
#' accepted, because their sorted order need not be the time order (`"W10"`
#' sorts before `"W2"`); convert them first, for example with
#' `as.numeric(as.character(year))` or `factor(wave, levels, ordered = TRUE)`.
#' @param delta The length of one period in units of `time` (or of `unit`),
#' like the `delta()` option of `xtset`. For example, `delta = 5` for data
#' every five years.
#' @param unit For `Date` and date-time times, the period: `"day"` (the
#' default for dates), `"week"`, `"month"`, `"quarter"` or `"year"`, and for
#' date-times also `"second"` (their default), `"minute"` and `"hour"`. Times
#' are compared by whole periods, as with Stata's `%tw`, `%tm`, `%tq` and
#' `%ty` dates, so any day in March is one month after any day in February.
#' Weeks start on Monday, and date-times use the local clock of their time
#' zone. Must be `NULL` for numbers and period classes.
#'
#' @returns A vector like `x`, with `NA` where the required period is absent
#' from the panel. `s_diff()` returns a double vector, or a `difftime` for
#' dates, date-times and `difftime` input.
#'
#' @details
#' Compared with [dplyr::lag()]: `lag(x, order_by = year)` takes the previous
#' *row* after sorting, so after a gap (2002, then 2004) it returns the 2002
#' value as the lag of 2004, and it silently accepts repeated years or a
#' forgotten `.by`. `s_lag(x, time = year)` takes the value at `year - 1`,
#' returns `NA` across the gap, and errors on repeated times, as Stata's
#' `L.x` does. The two agree on sorted, gap-free panels. For irregular event
#' sequences, where the previous record is wanted however long ago it was,
#' use `dplyr::lag()`.
#'
#' Time values must be unique within each panel (within the whole vector when
#' there is no grouping), as Stata requires with "repeated time values within
#' panel"; check them first with [isid()], such as `isid(data, id, year)`.
#' Numeric times are matched exactly, so steps such as `0.1` should be
#' rescaled to whole numbers first.
#'
#' @name panel
#' @examples
#' panel <- tibble::tibble(
#'   id = c(1, 1, 1, 2, 2),
#'   year = c(2001, 2002, 2004, 2001, 2002),
#'   x = c(10, 12, 15, 20, 21)
#' )
#' # 2004 has no 2003, so its lag is missing, unlike dplyr::lag()
#' dplyr::mutate(
#'   panel,
#'   lag_x = s_lag(x, time = year),
#'   lead_x = s_lead(x, time = year),
#'   d_x = s_diff(x, time = year),
#'   .by = id
#' )
#'
#' # Monthly data stored as dates
#' sales <- tibble::tibble(
#'   month = as.Date(c("2024-01-31", "2024-02-29", "2024-04-30")),
#'   amount = c(5, 7, 4)
#' )
#' dplyr::mutate(sales, previous = s_lag(amount, time = month, unit = "month"))
#' @family variable generation functions
NULL

#' @rdname panel
#' @export
s_lag <- function(x, n = 1L, time, delta = 1, unit = NULL) {
  check_number_whole(n, min = 0)
  period <- panel_period(time, x, delta, unit)
  vctrs::vec_slice(x, panel_rows(period, n * delta, time))
}

#' @rdname panel
#' @export
s_lead <- function(x, n = 1L, time, delta = 1, unit = NULL) {
  check_number_whole(n, min = 0)
  period <- panel_period(time, x, delta, unit)
  vctrs::vec_slice(x, panel_rows(period, -n * delta, time))
}

#' @rdname panel
#' @export
s_diff <- function(x, n = 1L, time, delta = 1, unit = NULL) {
  check_number_whole(n, min = 0)
  calendar <- inherits(x, c("Date", "POSIXt"))
  out <- if (calendar || inherits(x, "difftime")) x else egen_numeric(x)
  if (inherits(out, "POSIXlt")) {
    out <- as.POSIXct(out)
  }
  period <- panel_period(time, x, delta, unit)
  # Every difference looks up the same earlier rows.
  rows <- panel_rows(period, delta, time)
  for (i in seq_len(n)) {
    previous <- vctrs::vec_slice(out, rows)
    out <- if (calendar && i == 1L) {
      difftime(
        out,
        previous,
        units = if (inherits(x, "Date")) "days" else "secs"
      )
    } else {
      out - previous
    }
  }
  out
}

# The row whose time is `shift` units earlier, after checking that times are
# unique. Distinct, nonmissing periods are matched natively in one sorted walk;
# otherwise duplicated() reports repeats and match() finds the rows.
panel_rows <- function(period, shift, time, call = rlang::caller_env()) {
  if (is.double(period) && !anyNA(period)) {
    # The kernel sorts short vectors itself; long ones use the radix sort.
    order <- if (
      length(period) > 10000L && is.unsorted(period, strictly = TRUE)
    ) {
      order(period, method = "radix")
    }
    rows <- panel_lag_index(period, order, as.double(shift))
    if (!is.null(rows)) {
      return(rows)
    }
  }
  panel_check_unique(period, time, call)
  match(period - shift, period, incomparables = NA)
}

# Time as a whole-period index.
panel_period <- function(time, x, delta, unit, call = rlang::caller_env()) {
  if (missing(time)) {
    cli::cli_abort(
      "{.arg time} must be supplied, such as {.code time = year}; it plays the role of the time variable in Stata's {.code xtset}.",
      call = call
    )
  }
  if (length(time) != length(x)) {
    cli::cli_abort(
      "{.arg time} must have the same length as {.arg x}.",
      call = call
    )
  }
  check_number_decimal(delta, allow_infinite = FALSE, call = call)
  if (delta <= 0) {
    cli::cli_abort("{.arg delta} must be positive.", call = call)
  }
  time_period(time, unit, call = call)
}

panel_check_unique <- function(period, time, call = rlang::caller_env()) {
  repeated <- duplicated(period, incomparables = NA)
  if (any(repeated)) {
    # Inside grouped mutate(), the panel is already supplied.
    grouped <- tryCatch(
      ncol(dplyr::cur_group()) > 0L,
      error = function(e) FALSE
    )
    example <- format(vctrs::vec_slice(time, which(repeated)[[1L]]))
    hint <- if (grouped) {
      "Each time should appear once per panel; find the repeats with {.code isid(data, id, time)}."
    } else {
      "Supply the panel identifier, such as {.code .by = id}, and check it with {.code isid(data, id, time)}."
    }
    cli::cli_abort(
      c("Repeated time values within panel, such as {example}.", i = hint),
      call = call
    )
  }
}

# Whole-period index for each supported time type.
time_period <- function(time, unit, call = rlang::caller_env()) {
  natural <- period_class_unit(time)
  if (!is.null(natural)) {
    if (!is.null(unit) && !identical(unit, natural)) {
      cli::cli_abort(
        "{.arg time} is already a {natural} period; omit {.arg unit}.",
        call = call
      )
    }
    if (inherits(time, c("yearmon", "yearqtr"))) {
      # zoo stores the year plus the fraction of the year elapsed.
      return(round(as.numeric(time) * if (natural == "month") 12 else 4))
    }
    return(date_period(as.Date(time), natural))
  }
  if (inherits(time, "POSIXt")) {
    units <- c(
      "second",
      "minute",
      "hour",
      "day",
      "week",
      "month",
      "quarter",
      "year"
    )
    unit <- if (is.null(unit)) {
      units[[1L]]
    } else {
      rlang::arg_match(unit, units, error_call = call)
    }
    return(datetime_period(time, unit))
  }
  if (inherits(time, "Date")) {
    units <- c("day", "week", "month", "quarter", "year")
    unit <- if (is.null(unit)) {
      units[[1L]]
    } else {
      rlang::arg_match(unit, units, error_call = call)
    }
    return(date_period(time, unit))
  }
  if (
    is.ordered(time) ||
      (is.numeric(time) && !is.object(time)) ||
      (inherits(time, "haven_labelled") && is.numeric(vctrs::vec_data(time)))
  ) {
    if (!is.null(unit)) {
      cli::cli_abort(
        "{.arg unit} applies to dates and date-times only.",
        call = call
      )
    }
    if (inherits(time, "haven_labelled")) {
      return(labelled_numeric(time))
    }
    return(as.numeric(vctrs::vec_data(time)))
  }
  hint <- if (is.factor(time)) {
    c(
      i = "Its levels need not be in time order. Use {.code factor(wave, levels = ..., ordered = TRUE)}, or {.code as.numeric(as.character(year))} for numeric labels."
    )
  } else if (is.character(time)) {
    c(
      i = "Convert it first, such as {.code as.numeric(year)}, {.code as.Date(date)} or {.code factor(wave, levels = ..., ordered = TRUE)}."
    )
  }
  cli::cli_abort(
    c(
      "{.arg time} must be numeric, a date, a date-time or a period, not {.obj_type_friendly {time}}.",
      hint
    ),
    call = call
  )
}

# The period of tsibble and zoo period classes, or NULL for other types.
period_class_unit <- function(time) {
  if (inherits(time, c("yearmonth", "yearmon"))) {
    return("month")
  }
  if (inherits(time, c("yearquarter", "yearqtr"))) {
    return("quarter")
  }
  if (inherits(time, "yearweek")) {
    return("week")
  }
  NULL
}

date_period <- function(time, unit) {
  days <- as.numeric(time)
  if (unit == "day") {
    return(days)
  }
  if (unit == "week") {
    # 1970-01-01 was a Thursday; shifting by three days starts weeks on Monday.
    return(floor((days + 3) / 7))
  }
  parts <- as.POSIXlt(time)
  year <- parts$year + 1900
  switch(
    unit,
    month = year * 12 + parts$mon,
    quarter = year * 4 + parts$mon %/% 3,
    year = year
  )
}

# Date-times use their local clock, so periods follow the time zone's days.
datetime_period <- function(time, unit) {
  if (unit == "second") {
    return(as.numeric(as.POSIXct(time)))
  }
  parts <- as.POSIXlt(time)
  days <- as.numeric(as.Date(parts))
  switch(
    unit,
    minute = (days * 24 + parts$hour) * 60 + parts$min,
    hour = days * 24 + parts$hour,
    date_period(as.Date(parts), unit)
  )
}
