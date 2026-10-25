# Shared weight handling for tab(), tab2(), summ() and xtile().
#
# Frequency weights (Stata [fw], dplyr's `wt`) count each row `w` times.
# Analytic weights (Stata [aw]) are rescaled within each group to sum to the
# number of rows, so counts stay on the sample scale while proportions, means
# and percentiles are weighted.

# Evaluate `.wt` against the data and drop rows whose weight is missing.
weights_prepare <- function(data, wt, call = rlang::caller_env()) {
  if (rlang::quo_is_null(wt)) {
    return(list(data = data, weights = NULL, column = NULL))
  }
  weights <- rlang::eval_tidy(wt, data)
  weights <- weights_check(weights, nrow(data), ".wt", call = call)
  expr <- rlang::quo_get_expr(wt)
  column <- if (
    rlang::is_symbol(expr) && rlang::as_string(expr) %in% names(data)
  ) {
    rlang::as_string(expr)
  } else if (rlang::is_string(expr) && expr %in% names(data)) {
    expr
  } else {
    NULL
  }
  missing <- is.na(weights)
  if (any(missing)) {
    cli::cli_inform("Excluded {sum(missing)} row{?s} with missing weights.")
    data <- dplyr::dplyr_row_slice(data, which(!missing))
    weights <- weights[!missing]
  }
  list(data = data, weights = weights, column = column)
}

weights_check <- function(weights, size, arg, call = rlang::caller_env()) {
  if (is.logical(weights) && !is.object(weights)) {
    weights <- as.integer(weights)
  }
  if (!is.numeric(weights) || is.object(weights) || !is.null(dim(weights))) {
    cli::cli_abort(
      "{.arg {arg}} must be a numeric column or vector.",
      call = call
    )
  }
  if (length(weights) == 1L) {
    weights <- rep(weights, size)
  }
  if (length(weights) != size) {
    cli::cli_abort(
      "{.arg {arg}} must have one value per row ({size}), not {length(weights)}.",
      call = call
    )
  }
  if (any(!is.finite(weights) & !is.na(weights))) {
    cli::cli_abort("{.arg {arg}} must be finite.", call = call)
  }
  if (any(weights < 0, na.rm = TRUE)) {
    cli::cli_abort("{.arg {arg}} must not be negative.", call = call)
  }
  as.double(weights)
}

# Drop the weight column from an implicit "all columns" selection.
weights_drop_column <- function(
  data,
  column,
  selected,
  group_vars = character()
) {
  if (is.null(column) || selected || column %in% group_vars) {
    return(data)
  }
  data[setdiff(names(data), column)]
}

# Analytic weights sum to the number of rows within each group.
weights_scale <- function(weights, data, group_vars, type, groups = NULL) {
  if (is.null(weights) || !length(weights) || type == "frequency") {
    return(weights)
  }
  id <- if (!is.null(groups)) {
    aggregation_group_id(groups, length(weights))
  } else if (length(group_vars)) {
    vctrs::vec_group_id(data[group_vars])
  } else {
    rep(1L, length(weights))
  }
  # Normalize within each group before summing: finite weights can have an
  # infinite total, and groups can have very different weight scales.
  locs <- if (is.null(groups)) vctrs::vec_group_loc(id)$loc else groups$loc
  maxima <- vapply(locs, function(loc) max(weights[loc]), numeric(1))
  maxima[maxima == 0] <- 1
  weights <- weights / maxima[id]
  # Group ids run 1..k, so totals and sizes can be indexed by id directly.
  totals <- as.vector(rowsum(weights, id))
  sizes <- tabulate(id, nbins = length(totals))
  scale <- ifelse(totals > 0, sizes / totals, 0)
  weights * scale[id]
}

# Stata's percentile rule (as in `summarize, detail`, `_pctile` and `xtile`):
# with cumulative weight W_i and target P = p * W, take the first x_i with
# W_i > P; when W_i equals P, average x_i and x_(i+1). P is compared within
# a relative sqrt(eps), so 10 * 0.3 counts as 3, as Stata's 10 * 30 / 100.
weighted_quantile <- function(x, w, probs) {
  keep <- w > 0
  x <- x[keep]
  w <- w[keep]
  if (!length(x)) {
    return(rep(NA_real_, length(probs)))
  }
  # The percentile is invariant to weight scale, even if the total overflows.
  if (!is.finite(sum(w))) {
    w <- w / max(w)
  }
  order_x <- order(x)
  x <- x[order_x]
  cumulative <- cumsum(w[order_x])
  total <- cumulative[[length(cumulative)]]
  vapply(
    probs,
    function(p) {
      if (p <= 0) {
        return(x[[1L]])
      }
      if (p >= 1) {
        return(x[[length(x)]])
      }
      target <- p * total
      tolerance <- sqrt(.Machine$double.eps) * total
      exact <- which(abs(cumulative - target) <= tolerance)
      if (length(exact) && exact[[1L]] < length(x)) {
        i <- exact[[1L]]
        return(weights_midpoint(x[[i]], x[[i + 1L]]))
      }
      x[[which(cumulative > target)[[1L]]]]
    },
    numeric(1)
  )
}

# Unweighted percentiles use the same rule with every weight 1.
stata_quantile <- function(x, probs) {
  weighted_quantile(x, rep.int(1, length(x)), probs)
}

# Keep finite midpoints finite without rounding away subnormal values.
weights_midpoint <- function(x, y) {
  x <- as.double(x)
  y <- as.double(y)
  result <- (x + y) / 2
  overflow <- is.infinite(result) & is.finite(x) & is.finite(y)
  result[overflow] <- x[overflow] / 2 + y[overflow] / 2
  result
}
