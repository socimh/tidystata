#' Cut a numeric vector into groups
#'
#' @description
#' Group numeric values using quantiles, equal widths, or chosen cutpoints:
#'
#' * `cut_quantile()` (`xtile()`): Create `n` quantile groups, following
#'   Stata's `xtile`.
#' * `cut_length()`: Create `n` intervals of equal length. Stata has no
#'   equal-width command (`egen cut(), group()` is not equal-width).
#' * `cut_breaks()`: Cut at given cutpoints, like `egen cut(), at()`.
#'
#' @param x A numeric vector. `cut_quantile()` also accepts logical vectors,
#'   treated as 0/1. SPSS user-missing codes and ranges are omitted. Convert
#'   `integer64` inputs and cutpoints explicitly to ordinary numeric values
#'   first.
#' @param n Number of groups or intervals, as a positive integer. Defaults to 4.
#' @param method For `cut_quantile()`, quantile boundaries (`"quantile"`, the
#'   default) or balanced rank groups (`"rank"`, with no Stata counterpart).
#'   Rank groups may split ties, breaking them by original position. They differ
#'   in size by at most one; earlier groups get extra rows.
#' @param wt Optional finite, non-negative weights for `cut_quantile()`, one per
#'   element of `x` or a scalar recycled to its length, like Stata's
#'   `xtile ... [aweight = w]`. Cutpoints follow Stata's weighted percentile
#'   rule. Zero-weight rows do not enter cutpoint estimation but still receive
#'   codes; elements with a missing weight get a missing code. Not available
#'   with `method = "rank"`.
#' @param breaks Numeric cutpoints for `cut_breaks()`. The observed minimum and
#'   maximum are added when values lie beyond the breaks. `NULL` uses the
#'   observed median as an interior cutpoint. A single number supplies one
#'   interior cutpoint, rather than the number of intervals.
#' @param right For `cut_breaks()`, if `FALSE` (default), intervals are closed
#'   on the left (`a <= x < b`), as in Stata's `egen cut()`; the last interval
#'   also includes its upper end. If `TRUE`, they are closed on the right
#'   (`a < x <= b`), and the first interval also includes its lower end, as in
#'   [base::cut()] with `include.lowest = TRUE`.
#' @param labels `NULL` (default) creates labels; `FALSE` returns integer
#'   codes. Supply a character vector for custom labels, one per effective
#'   group. For `cut_quantile()`, grouped data masks default to integer codes,
#'   and `TRUE` explicitly requests labels.
#'
#' @details
#' **Quantile and rank groups**
#'
#' In quantile mode, `cut_quantile()` uses Stata's percentiles at `1/n, 2/n, ...`
#' (see [summ()]). Each value joins the first group whose cutpoint is at least
#' that value. Equal values stay together; different values may share a group.
#' Ties can leave empty groups, whose codes are skipped (for example 1, 3, 4),
#' with a warning. Factor levels contain only occupied groups.
#'
#' Rank mode omits missing values while ranking and restores their missing
#' output positions afterward. If `n` exceeds the observed count, it warns
#' and uses one group per observation.
#'
#' **Labels and grouped use**
#'
#' Quantile labels describe contiguous intervals, such as `"[0,0]"` and `"(0,1]"`;
#' rank labels run from `"1"` to the effective group count. Custom labels must
#' match the effective number of groups. Interval labels always use a decimal
#' point, regardless of `options(OutDec)`, to avoid ambiguity with commas.
#'
#' Inside grouped [dplyr::mutate()], each group has its own cutpoints and labels.
#' Because those labels cannot be combined, `cut_quantile()` defaults to integer
#' codes, like Stata's `xtile, by()`; `labels = TRUE` requests labels explicitly.
#' `cut_length()` and `cut_breaks()` retain factor output in grouped data masks.
#' For these functions, supply character labels or use `FALSE` for integer codes.
#'
#' **Limits and interval endpoints**
#'
#' `cut_quantile()` rejects empty and all-missing inputs; constants are allowed
#' only in rank mode. `cut_length()` and `cut_breaks()` reject constants and
#' all-missing inputs. Equal-width intervals also require finite values.
#'
#' `cut_breaks()` extends end intervals to the observed range. Stata's
#' `egen cut(), at()` instead leaves values outside the breaks, including
#' values at the last break, missing.
#'
#' @returns An ordered factor, or integer interval codes when `labels = FALSE`
#'   or when `cut_quantile()` runs in a grouped data mask with default labels.
#'   Results have the length and order of `x`; missing inputs and missing
#'   weights give missing codes. All-missing inputs are rejected. Empty inputs
#'   are rejected by `cut_quantile()` and `cut_length()`;
#'   `cut_breaks(numeric(), breaks = 50)` returns an empty ordered factor,
#'   or an empty integer vector with `labels = FALSE`.
#'
#' @name cut
#' @examples
#' cut_quantile(1:20)
#'
#' cut_length(1:20)
#'
#' cut_breaks(1:20, breaks = c(5, 15))
#'
#' cut_breaks(1:20, breaks = 10)
#' @family variable generation functions

#' @rdname cut
#' @export
#' @order 2
xtile <- function(
  x,
  n = 4,
  labels = NULL,
  method = c("quantile", "rank"),
  wt = NULL
) {
  method <- rlang::arg_match(method)
  # Interval labels use a decimal point: "[2,8,6,6]" would be ambiguous.
  rlang::local_options(OutDec = ".")
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
#' @order 1
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
  observed <- x[!is.na(x)]
  if (!length(observed)) {
    cli::cli_abort("{.arg x} must contain non-missing observations.")
  }
  if (!all(is.finite(observed))) {
    cli::cli_abort(c(
      "{.arg x} must contain only finite values for equal-width bins.",
      i = "Use {.fn cut_breaks} to place infinite values in open intervals."
    ))
  }
  breaks <- seq(min(observed), max(observed), length.out = n + 1)
  cut_breaks(x, breaks = breaks, labels = labels)
}

#' @rdname cut
#' @export
cut_breaks <- function(x, breaks = NULL, labels = NULL, right = FALSE) {
  # Interval labels use a decimal point: "[0,5,1,25)" would be ambiguous.
  rlang::local_options(OutDec = ".")
  x <- cut_numeric_input(x)
  cut_check_x(x)
  # An empty x has no observed range, as min() and max() of nothing.
  observed <- x[!is.na(x)]
  x_min <- if (length(observed)) min(observed) else Inf
  x_max <- if (length(observed)) max(observed) else -Inf
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
