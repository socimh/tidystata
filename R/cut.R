#' Cut a numeric vector into groups
#'
#' @description
#' * `xtile()` creates `n` quantile groups, following Stata's `xtile`.
#' * `cut_length()` creates `n` intervals of equal length. Stata has no
#'   equal-width command (`egen cut(), group()` is not equal-width).
#' * `cut_breaks()` cuts at given cutpoints, like `egen cut(), at()`.
#'
#' `cut_quantile()` is an alias of `xtile()`.
#'
#' @param x A numeric vector. `xtile()` also accepts a logical vector,
#' treated as 0/1. SPSS user-missing codes and ranges are omitted. Convert
#' `integer64` inputs and cutpoints explicitly to ordinary numeric values first.
#' @param n A positive integer. The number of intervals.
#' @param method Quantile boundaries (`"quantile"`, the default), or balanced
#' rank groups (`"rank"`, which has no Stata counterpart). Rank groups may
#' split ties, breaking them by original position. They differ in size by at
#' most one; earlier groups get extra rows.
#' @param wt Optional weights for `xtile()`, one per element of `x`, like
#' Stata's `xtile ... [aweight = w]`. Cutpoints then follow Stata's weighted
#' percentile rule; elements with a missing weight get a missing code. Not
#' available with `method = "rank"`.
#' @param breaks Numeric cutpoints for `cut_breaks()`. The observed minimum and
#' maximum are added when values lie beyond the breaks. `NULL` uses the
#' observed median as an interior cutpoint. A single number supplies one
#' interior cutpoint, rather than the number of intervals.
#' @param right A single `TRUE` or `FALSE`. If `FALSE` (default), intervals are
#' closed on the left (`a <= x < b`), as in Stata's `egen cut()`; the last
#' interval also includes its upper end. If `TRUE`, they are closed on the
#' right (`a < x <= b`), as in [base::cut()].
#' @inheritParams base::cut
#'
#' @details `xtile()` follows Stata's `xtile`, and its codes are tested against
#' Stata's output. Cutpoints are the percentiles at `1/n, 2/n, ...`, using
#' Stata's percentile rule (see [summ()]), and each value joins the first group
#' whose cutpoint is at least that value. Equal values stay in the same group;
#' different values may share a group. Ties can leave groups empty; as in
#' Stata, their codes are skipped (codes 1, 3 and 4, say) and a warning is
#' given. Factor levels are the
#' occupied groups. Default labels are the
#' contiguous intervals covered by each group, for example `"[0,0]"` and
#' `"(0,1]"`. Custom labels must match the effective number of groups.
#' Empty and all-missing vectors are rejected. Constant vectors are rejected
#' only by the default quantile method.
#'
#' `cut_breaks()` differs from `egen cut(), at()` at the ends: Stata leaves
#' values outside the breaks (and at the last break) missing, while
#' `cut_breaks()` extends the end intervals to the observed range.
#'
#' `labels = NULL` (the default) or `TRUE` gives interval labels; `FALSE`
#' gives integer codes. Inside grouped [dplyr::mutate()], each group has its
#' own cutpoints and interval labels, which cannot be combined, so the default
#' returns integer codes within each group (like Stata's `xtile, by()`).
#' Supply `labels = TRUE` to request labels there anyway.
#'
#' Rank groups omit missing observations when ranking, then restore missing
#' output positions. If `n` exceeds the observed count, use one group per
#' observation and warn. Default rank labels are `"1"` through the effective
#' group count; custom labels must match that count.
#'
#' @returns An ordered factor, or integer interval codes when `labels = FALSE`
#' or when `xtile()` runs in a grouped data mask with default labels.
#'
#' @name cut
#' @examples
#' xtile(1:20)
#' xtile(c(0, 0, 0, 1, 1), 2)
#'
#' cut_length(1:20)
#'
#' cut_breaks(1:20, breaks = c(5, 15))
#' cut_breaks(1:20, breaks = 10)
#' @family variable generation functions

#' @rdname cut
#' @export
xtile <- function(
  x,
  n = 4,
  labels = NULL,
  method = c("quantile", "rank"),
  wt = NULL
) {
  method <- rlang::arg_match(method)
  x <- cut_numeric_input(x)
  if (is.logical(x) && is.null(dim(x))) {
    x <- as.integer(x)
  }
  if (!is.numeric(x) || is.complex(x) || !is.null(dim(x))) {
    stop_input_type(x, "a numeric or logical vector")
  }
  if (is.null(labels) && cut_in_grouped_mask()) {
    # Group-specific interval labels cannot be combined across groups.
    labels <- FALSE
  } else if (isTRUE(labels)) {
    labels <- NULL
  }
  check_number_whole(n, min = 1)
  if (!is.null(wt)) {
    if (method == "rank") {
      cli::cli_abort(
        "{.arg wt} is not supported with {.code method = \"rank\"}."
      )
    }
    wt <- weights_check(wt, length(x), "wt")
    # Observations with a missing weight get a missing code, as in Stata.
    x[is.na(wt)] <- NA
  }
  observed <- x[!is.na(x)]
  if (length(observed) == 0L) {
    cli::cli_abort("{.arg x} must contain non-missing observations.")
  }
  if (method == "rank") {
    xtile_rank(x, observed, n, labels)
  } else {
    xtile_quantile(x, observed, n, labels, wt)
  }
}

#' @rdname cut
#' @export
cut_quantile <- xtile

# Balanced rank groups: ties are broken by original position, and earlier
# groups get the extra rows.
xtile_rank <- function(x, observed, n, labels, call = rlang::caller_env()) {
  intervals <- min(n, length(observed))
  xtile_check_labels(labels, intervals, call = call)
  if (n > length(observed)) {
    cli::cli_warn(
      "Requested more groups than non-missing observations; using {intervals} groups."
    )
  }
  sizes <- rep(length(observed) %/% intervals, intervals)
  extra <- length(observed) %% intervals
  sizes[seq_len(extra)] <- sizes[seq_len(extra)] + 1L
  observed_positions <- which(!is.na(x))
  ranked_positions <- observed_positions[order(observed, seq_along(observed))]
  codes <- rep(NA_integer_, length(x))
  codes[ranked_positions] <- rep(seq_len(intervals), sizes)
  if (is.null(labels)) {
    labels <- as.character(seq_len(intervals))
  }
  xtile_codes(codes, intervals, labels)
}

xtile_quantile <- function(
  x,
  observed,
  n,
  labels,
  wt,
  call = rlang::caller_env()
) {
  limits <- range(observed)
  if (limits[[1L]] == limits[[2L]]) {
    cli::cli_abort(
      "Can't cut a vector with only one unique value.",
      call = call
    )
  }
  # Stata xtile rule: a value joins the first group whose cutpoint is at least
  # the value; repeated cutpoints retain their original group codes.
  cutpoints <- if (is.null(wt)) {
    stata_quantile(observed, seq_len(n - 1L) / n)
  } else {
    weighted_quantile(observed, wt[!is.na(x)], seq_len(n - 1L) / n)
  }
  if (anyNA(cutpoints)) {
    cli::cli_abort(
      "Can't form quantile cutpoints from these observations.",
      call = call
    )
  }
  # Stata codes each value by the number of cutpoints below it, plus one.
  # Tied cutpoints leave groups empty, and their codes are skipped.
  raw <- findInterval(x, cutpoints, left.open = TRUE) + 1L
  raw[is.na(x)] <- NA_integer_
  # Raw codes run 1..n, so occupancy needs no sorting.
  occupied <- which(tabulate(raw, nbins = n) > 0L)
  intervals <- length(occupied)
  xtile_check_labels(labels, intervals, call = call)
  if (intervals < n) {
    cli::cli_warn(
      "Tied values leave {intervals} of {n} quantile groups occupied; codes skip the empty ones, as in Stata."
    )
  }
  if (identical(labels, FALSE)) {
    return(raw)
  }
  if (is.null(labels)) {
    upper <- c(cutpoints, limits[[2L]])[occupied]
    labels <- quantile_interval_labels(c(limits[[1L]], upper))
  }
  factor(raw, levels = occupied, labels = labels, ordered = TRUE)
}

xtile_check_labels <- function(labels, intervals, call = rlang::caller_env()) {
  if (
    !is.null(labels) && !identical(labels, FALSE) && length(labels) != intervals
  ) {
    cli::cli_abort(
      "{.arg labels} must have length {intervals}, the effective number of intervals.",
      call = call
    )
  }
}

# Integer codes for `labels = FALSE`, otherwise an ordered factor.
xtile_codes <- function(codes, intervals, labels) {
  if (identical(labels, FALSE)) {
    return(codes)
  }
  factor(codes, levels = seq_len(intervals), labels = labels, ordered = TRUE)
}

# TRUE inside a grouped dplyr verb such as group_by() |> mutate().
cut_in_grouped_mask <- function() {
  if (!in_dplyr_verb()) {
    return(FALSE)
  }
  keys <- tryCatch(dplyr::cur_group(), error = function(e) NULL)
  !is.null(keys) && ncol(keys) > 0L
}

# Interval labels formatted like base::cut(), allowing a degenerate first
# interval such as "[0,0]" when the lowest cutpoint equals the minimum.
quantile_interval_labels <- function(bounds) {
  for (digits in 3:12) {
    formatted <- formatC(0 + bounds, digits = digits, width = 1L)
    distinct <- bounds[-1L] == bounds[-length(bounds)] |
      formatted[-1L] != formatted[-length(formatted)]
    if (all(distinct)) {
      break
    }
  }
  labels <- paste0(
    "(",
    formatted[-length(formatted)],
    ",",
    formatted[-1L],
    "]"
  )
  substr(labels[1L], 1L, 1L) <- "["
  labels
}

#' @rdname cut
#' @export
cut_length <- function(x, n = 4, labels = NULL) {
  check_number_whole(n, min = 1)
  x <- cut_numeric_input(x)
  cut_check_x(x)
  breaks <- seq(min(x, na.rm = TRUE), max(x, na.rm = TRUE), length.out = n + 1)
  cut_breaks(x, breaks = breaks, labels = labels)
}

#' @rdname cut
#' @export
cut_breaks <- function(x, breaks = NULL, labels = NULL, right = FALSE) {
  x <- cut_numeric_input(x)
  cut_check_x(x)
  x_min <- min(x, na.rm = TRUE)
  x_max <- max(x, na.rm = TRUE)
  if (x_min == x_max) {
    cli::cli_abort("Can't cut a vector with only one unique value.")
  }
  if (is.null(breaks)) {
    breaks <- stats::median(x, na.rm = TRUE)
    if (breaks %in% c(x_min, x_max)) {
      cli::cli_warn(c(
        "The median ({breaks}) equals the {if (breaks == x_min) 'minimum' else 'maximum'}, so it does not split the values.",
        i = "Supply {.arg breaks} for two groups."
      ))
    }
  }
  breaks <- cut_numeric_input(breaks, "breaks")
  if (!is.numeric(breaks) || anyNA(breaks)) {
    stop_input_type(breaks, "a numeric vector without missing values")
  }

  # The observed range extends the breaks only where values lie beyond them;
  # cut() sorts the breaks.
  breaks <- unique(c(
    if (!is.finite(x_min) || x_min < min(breaks)) x_min,
    breaks,
    if (!is.finite(x_max) || x_max > max(breaks)) x_max
  ))

  cut(
    x,
    breaks = breaks,
    include.lowest = TRUE,
    right = right,
    labels = labels,
    ordered_result = TRUE
  )
}

# Empty input keeps its established handling; all-missing input is rejected
# before min() and max() warn.
cut_check_x <- function(x, call = rlang::caller_env()) {
  if (!is.numeric(x) || is.factor(x)) {
    stop_input_type(x, "a numeric vector", call = call)
  }
  if (length(x) && all(is.na(x))) {
    cli::cli_abort(
      "{.arg x} must contain non-missing observations.",
      call = call
    )
  }
}

# Normalize labelled missingness before any range or interval computation.
cut_numeric_input <- function(x, arg = "x", call = rlang::caller_env()) {
  if (inherits(x, "integer64")) {
    cli::cli_abort(
      "Convert {.arg {arg}} from {.cls integer64} explicitly to ordinary numeric values before binning.",
      call = call
    )
  }
  if (inherits(x, "haven_labelled")) {
    return(haven::zap_labels(haven::zap_missing(x)))
  }
  x
}
