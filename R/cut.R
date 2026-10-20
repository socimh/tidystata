#' Cut a numeric vector into groups
#'
#' @description
#' * `xtile()` creates `n` quantile groups, following Stata's `xtile`.
#' * `cut_length()` creates `n` intervals of equal length.
#' * `cut_breaks()` cuts at given cutpoints.
#'
#' `cut_quantile()` is an alias of `xtile()`.
#'
#' @param x A numeric vector. `xtile()` also accepts a logical vector,
#' treated as 0/1.
#' @param n A positive integer. The number of intervals.
#' @param method Quantile boundaries (`"quantile"`, the default), or balanced
#' rank groups (`"rank"`). Rank groups may split ties, breaking them by original
#' position. They differ in size by at most one; earlier groups get extra rows.
#' @param wt Optional weights for `xtile()`, one per element of `x`, like
#' Stata's `xtile ... [aweight = w]`. Cutpoints then follow Stata's weighted
#' percentile rule; elements with a missing weight get a missing code. Not
#' available with `method = "rank"`.
#' @param breaks Numeric cutpoints for `cut_breaks()`. The observed minimum and
#' maximum are included automatically. `NULL` uses the observed median as an
#' interior cutpoint. A single number supplies one interior cutpoint, rather
#' than the number of intervals.
#' @inheritParams base::cut
#'
#' @details `xtile()` follows Stata's `xtile` rule with type-7
#' quantile cutpoints at `1/n, 2/n, ...`: each value joins the first group
#' whose cutpoint is at least that value. Equal values stay in the same group
#' and distinct values are never merged, so a 0/1 dummy always gives two
#' groups. Ties can leave fewer than `n` groups; occupied groups are then
#' numbered consecutively and a warning is given. Default labels are the
#' contiguous intervals covered by each group, for example `"[0,0]"` and
#' `"(0,1]"`. Custom labels must match the effective number of groups.
#' Empty and all-missing vectors are rejected. Constant vectors are rejected
#' only by the default quantile method. Cutpoints are not promised to match
#' Stata's percentile definition exactly.
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
#' @return An ordered factor, or integer interval codes when `labels = FALSE`
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

#' @rdname cut
#' @export
xtile <- function(
  x,
  n = 4,
  labels = NULL,
  method = c("quantile", "rank"),
  wt = NULL
) {
  method <- match.arg(method)
  if (is.logical(x) && is.null(dim(x))) {
    x <- as.integer(x)
  }
  if (!is.numeric(x) || is.complex(x) || !is.null(dim(x))) {
    stop("`x` must be a numeric or logical vector.", call. = FALSE)
  }
  if (is.null(labels) && cut_in_grouped_mask()) {
    # Group-specific interval labels cannot be combined across groups.
    labels <- FALSE
  } else if (isTRUE(labels)) {
    labels <- NULL
  }
  if (
    !is.numeric(n) ||
      is.complex(n) ||
      length(n) != 1L ||
      is.na(n) ||
      !is.finite(n) ||
      n < 1 ||
      n != floor(n)
  ) {
    stop("`n` must be a single positive integer.", call. = FALSE)
  }
  if (!is.null(wt)) {
    if (method == "rank") {
      stop("`wt` is not supported with `method = \"rank\"`.", call. = FALSE)
    }
    wt <- weights_check(wt, length(x), "`wt`")
    # Observations with a missing weight get a missing code, as in Stata.
    x[is.na(wt)] <- NA
  }
  observed <- x[!is.na(x)]
  if (length(observed) == 0L) {
    stop("`x` must contain non-missing observations.", call. = FALSE)
  }
  if (method == "rank") {
    intervals <- min(n, length(observed))
    if (
      !is.null(labels) &&
        !identical(labels, FALSE) &&
        length(labels) != intervals
    ) {
      stop(
        "`labels` must have length ",
        intervals,
        ", the effective number of intervals.",
        call. = FALSE
      )
    }
    if (n > length(observed)) {
      warning(
        "Requested more groups than non-missing observations; using ",
        intervals,
        " groups.",
        call. = FALSE
      )
    }
    sizes <- rep(length(observed) %/% intervals, intervals)
    extra <- length(observed) %% intervals
    sizes[seq_len(extra)] <- sizes[seq_len(extra)] + 1L
    observed_positions <- which(!is.na(x))
    ranked_positions <- observed_positions[order(observed, seq_along(observed))]
    codes <- rep(NA_integer_, length(x))
    codes[ranked_positions] <- rep(seq_len(intervals), sizes)
    if (identical(labels, FALSE)) {
      return(codes)
    }
    if (is.null(labels)) {
      labels <- as.character(seq_len(intervals))
    }
    return(factor(
      codes,
      levels = seq_len(intervals),
      labels = labels,
      ordered = TRUE
    ))
  }
  if (length(unique(observed)) == 1L) {
    stop("Cannot cut a vector with only one unique value.", call. = FALSE)
  }
  # Stata xtile rule: a value joins the first group whose cutpoint is at least
  # the value, so distinct values are never merged into one group.
  cutpoints <- if (is.null(wt)) {
    stats::quantile(
      observed,
      probs = seq_len(n - 1L) / n,
      type = 7,
      names = FALSE
    )
  } else {
    weighted_quantile(observed, wt[!is.na(x)], seq_len(n - 1L) / n)
  }
  if (anyNA(cutpoints)) {
    stop(
      "Cannot form quantile cutpoints from these observations.",
      call. = FALSE
    )
  }
  maximum <- max(observed)
  cutpoints <- unique(cutpoints[cutpoints < maximum])
  raw <- findInterval(x, cutpoints, left.open = TRUE) + 1L
  raw[is.na(x)] <- NA_integer_
  occupied <- sort(unique(raw[!is.na(raw)]))
  intervals <- length(occupied)
  if (
    !is.null(labels) && !identical(labels, FALSE) && length(labels) != intervals
  ) {
    stop(
      "`labels` must have length ",
      intervals,
      ", the effective number of intervals.",
      call. = FALSE
    )
  }
  if (intervals < n) {
    warning(
      "Tied values collapsed quantile cutpoints to ",
      intervals,
      " groups (requested ",
      n,
      ").",
      call. = FALSE
    )
  }
  codes <- match(raw, occupied)
  if (identical(labels, FALSE)) {
    return(codes)
  }
  if (is.null(labels)) {
    upper <- c(cutpoints, maximum)[occupied]
    labels <- quantile_interval_labels(c(min(observed), upper))
  }
  factor(codes, levels = seq_len(intervals), labels = labels, ordered = TRUE)
}

# TRUE inside a grouped dplyr verb such as group_by() |> mutate().
#' @rdname cut
#' @export
cut_quantile <- xtile

cut_in_grouped_mask <- function() {
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
  if (
    !is.numeric(n) ||
      is.complex(n) ||
      length(n) != 1L ||
      is.na(n) ||
      !is.finite(n) ||
      n < 1 ||
      n != floor(n)
  ) {
    stop("`n` must be a single positive integer.", call. = FALSE)
  }
  breaks <- seq(min(x, na.rm = TRUE), max(x, na.rm = TRUE), length.out = n + 1)
  cut_breaks(x, breaks = breaks, labels = labels)
}

#' @rdname cut
#' @export
cut_breaks <- function(x, breaks = NULL, labels = NULL, right = TRUE) {
  if (is.null(breaks)) {
    breaks <- stats::median(x, na.rm = TRUE)
  }
  x_min <- min(x, na.rm = TRUE)
  x_max <- max(x, na.rm = TRUE)
  if (x_min == x_max) {
    stop("Cannot cut a vector with only one unique value.")
  }

  breaks <- unique(c(x_min, breaks, x_max))

  cut(
    x,
    breaks = breaks,
    include.lowest = TRUE,
    right = right,
    labels = labels,
    ordered_result = TRUE
  )
}
