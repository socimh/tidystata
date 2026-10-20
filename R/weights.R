# Shared weight handling for tab(), xtab(), summ() and xtile().
#
# Frequency weights (Stata [fw], dplyr's `wt`) count each row `w` times.
# Analytic weights (Stata [aw]) are rescaled within each group to sum to the
# number of rows, so counts stay on the sample scale while proportions, means
# and percentiles are weighted.

# Evaluate `.wt` against the data and drop rows whose weight is missing.
weights_prepare <- function(data, wt) {
  if (rlang::quo_is_null(wt)) {
    return(list(data = data, weights = NULL, column = NULL))
  }
  weights <- rlang::eval_tidy(wt, data)
  weights <- weights_check(weights, nrow(data), "`.wt`")
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
    message(
      "Excluded ",
      sum(missing),
      if (sum(missing) == 1L) " row" else " rows",
      " with missing weights."
    )
    data <- dplyr::dplyr_row_slice(data, which(!missing))
    weights <- weights[!missing]
  }
  list(data = data, weights = weights, column = column)
}

weights_check <- function(weights, size, label) {
  if (is.logical(weights) && !is.object(weights)) {
    weights <- as.integer(weights)
  }
  if (!is.numeric(weights) || is.object(weights) || !is.null(dim(weights))) {
    stop(label, " must be a numeric column or vector.", call. = FALSE)
  }
  if (length(weights) == 1L) {
    weights <- rep(weights, size)
  }
  if (length(weights) != size) {
    stop(
      label,
      " must have one value per row (",
      size,
      "), not ",
      length(weights),
      ".",
      call. = FALSE
    )
  }
  if (any(!is.finite(weights) & !is.na(weights))) {
    stop(label, " must be finite.", call. = FALSE)
  }
  if (any(weights < 0, na.rm = TRUE)) {
    stop(label, " must not be negative.", call. = FALSE)
  }
  as.double(weights)
}

# Drop the weight column from an implicit "all columns" selection.
weights_drop_column <- function(data, column, selected) {
  if (is.null(column) || selected) {
    return(data)
  }
  data[setdiff(names(data), column)]
}

# Analytic weights sum to the number of rows within each group.
weights_scale <- function(weights, data, group_vars, type, groups = NULL) {
  if (is.null(weights) || type == "frequency") {
    return(weights)
  }
  id <- if (!is.null(groups)) {
    aggregation_group_id(groups, length(weights))
  } else if (length(group_vars)) {
    vctrs::vec_group_id(data[group_vars])
  } else {
    rep(1L, length(weights))
  }
  # Group ids run 1..k, so totals and sizes can be indexed by id directly.
  totals <- as.vector(rowsum(weights, id))
  sizes <- tabulate(id, nbins = length(totals))
  scale <- ifelse(totals > 0, sizes / totals, 0)
  weights * scale[id]
}

# Stata's weighted percentile rule (as in `summarize, detail` and `xtile`):
# with cumulative weight W_i and target P = p * W, take the first x_i with
# W_i > P; when W_i equals P exactly, average x_i and x_(i+1).
weighted_quantile <- function(x, w, probs) {
  keep <- w > 0
  x <- x[keep]
  w <- w[keep]
  if (!length(x)) {
    return(rep(NA_real_, length(probs)))
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
        return((x[[i]] + x[[i + 1L]]) / 2)
      }
      x[[which(cumulative > target)[[1L]]]]
    },
    numeric(1)
  )
}
