#' Pairwise correlations
#'
#' @description
#' A tidy table of pairwise correlations, like Stata's `pwcorr, sig obs`.
#' Each pair of variables uses every row where both are observed (pairwise
#' deletion), and the table reports the correlation, the number of
#' observations and the p-value.
#'
#' @param .data A data frame, tibble, or data.table.
#' @param ... <[`tidy-select`][dplyr_tidy_select]> Numeric or logical
#' variables. Omit to use every numeric or logical column; other columns are
#' then skipped. Selecting another type is an error.
#' @param .by <[`tidy-select`][dplyr_tidy_select]> Optional grouping
#' variables. Grouped data use their groups unless `.by` is supplied.
#' @param .method `"pearson"` (default) or `"spearman"`, like Stata's
#' `pwcorr` and `spearman`.
#' @param .wide A single `TRUE` or `FALSE`. If `TRUE`, return the correlation
#' matrix as Stata prints it: one row per variable and the lower triangle
#' filled, without `n` or `p`.
#' @param .wt Optional weights: a numeric column of `.data` (or a vector with
#' one value per row), like Stata's `pwcorr [fweight/aweight]`. Pearson
#' correlations only. Rows with a missing weight are excluded with a message.
#' @param .wt_type `"frequency"` (default) or `"analytic"`. The correlation is
#' the same under both; with frequency weights, `n` and the p-value use the
#' summed weight, and with analytic weights the number of rows.
#'
#' @return
#' By default, a tibble with one row per pair (and group): any grouping keys,
#' `var1`, `var2`, `r`, `n` and `p`. With `.wide = TRUE`, a tibble with any
#' grouping keys, `variable` and one column of correlations per variable.
#'
#' @details
#' The p-value is the two-sided test of zero correlation that Stata reports,
#' based on `t = r * sqrt((n - 2) / (1 - r^2))` with `n - 2` degrees of
#' freedom. For Pearson correlations it matches `cor.test()`; for Spearman
#' correlations it is the same large-sample approximation that Stata uses.
#' Correlations with a constant variable, and p-values with fewer than three
#' observations, are `NA`. Labelled numeric columns are correlated on their
#' codes. For listwise deletion, as in Stata's `correlate`, drop incomplete
#' rows first with `tidyr::drop_na()`.
#'
#' @examples
#' pwcorr(lifeexp, lexp, gnppc, safewater)
#' pwcorr(lifeexp, lexp, gnppc, safewater, .wide = TRUE)
#' pwcorr(lifeexp, lexp, gnppc, .by = region)
#' pwcorr(lifeexp, lexp, gnppc, .method = "spearman")
#' @export
pwcorr <- function(
  .data,
  ...,
  .by = NULL,
  .method = c("pearson", "spearman"),
  .wide = FALSE,
  .wt = NULL,
  .wt_type = c("frequency", "analytic")
) {
  if (!is.data.frame(.data)) {
    stop("`.data` must be a data frame.", call. = FALSE)
  }
  .method <- match.arg(.method)
  .wt_type <- match.arg(.wt_type)
  check_flag(.wide, ".wide")
  by <- rlang::enquo(.by)
  .data <- aggregation_working_data(
    .data,
    override_groups = !rlang::quo_is_null(by)
  )
  group_vars <- extract_group_var(
    if (rlang::quo_is_null(by)) .data else dplyr::ungroup(.data),
    by
  )
  .data <- dplyr::ungroup(.data)
  weighted <- weights_prepare(.data, rlang::enquo(.wt))
  if (!is.null(weighted$weights) && .method != "pearson") {
    stop("`.wt` is supported for Pearson correlations only.", call. = FALSE)
  }
  .data <- weights_drop_column(weighted$data, weighted$column, !missing(...))
  weights <- weighted$weights

  values <- remove_group_vars(.data, ..., group_vars = group_vars)
  values <- pwcorr_values(values, selected = !missing(...))
  if (.wide && "variable" %in% names(values)) {
    stop(
      "Column `variable` holds the row names of the wide table; ",
      "rename the variable `variable` first.",
      call. = FALSE
    )
  }
  reserved <- if (.wide) "variable" else c("var1", "var2", "r", "n", "p")
  clash <- intersect(group_vars, c(reserved, if (.wide) names(values)))
  if (length(clash)) {
    stop(
      "Grouping variable `",
      clash[[1L]],
      "` clashes with an output column name; rename it first.",
      call. = FALSE
    )
  }

  groups <- group_locations(.data, group_vars)
  out <- lapply(seq_along(groups$locs), function(i) {
    loc <- groups$locs[[i]]
    w <- if (is.null(weights)) NULL else weights[loc]
    columns <- lapply(values, `[`, loc)
    table <- if (.wide) {
      pwcorr_wide(columns, w, .method)
    } else {
      pwcorr_long(columns, w, .method, .wt_type)
    }
    keys <- vctrs::vec_slice(groups$keys, rep(i, nrow(table)))
    dplyr::bind_cols(keys, table)
  })
  if (!length(out)) {
    empty <- if (.wide) {
      pwcorr_wide(lapply(values, `[`, 0L), NULL, .method)
    } else {
      pwcorr_long(lapply(values, `[`, 0L), NULL, .method, .wt_type)
    }
    return(dplyr::bind_cols(groups$keys, empty[0L, ]))
  }
  vctrs::vec_rbind(!!!out)
}

# Numeric versions of the correlated columns. Unselected non-numeric columns
# are skipped; explicitly selected ones are an error.
pwcorr_values <- function(data, selected) {
  numeric <- lapply(data, function(x) {
    if (is.logical(x) && !is.object(x)) {
      return(as.numeric(x))
    }
    if (inherits(x, "haven_labelled") && is.numeric(vctrs::vec_data(x))) {
      return(as.numeric(vctrs::vec_data(x)))
    }
    if (is.numeric(x) && !is.object(x)) {
      return(as.numeric(x))
    }
    NULL
  })
  invalid <- vapply(numeric, is.null, logical(1))
  if (selected && any(invalid)) {
    stop(
      "`",
      paste(names(data)[invalid], collapse = "`, `"),
      "` must be numeric or logical to be correlated.",
      call. = FALSE
    )
  }
  numeric <- numeric[!invalid]
  if (length(numeric) < 2L) {
    stop("Select at least two numeric variables to correlate.", call. = FALSE)
  }
  numeric
}

# Correlation, observation count and p-value for one pair of columns.
pwcorr_pair <- function(x, y, w, method, weight_type) {
  ok <- !is.na(x) & !is.na(y)
  x <- x[ok]
  y <- y[ok]
  if (is.null(w)) {
    n <- length(x)
    r <- if (n > 1L) {
      suppressWarnings(stats::cor(x, y, method = method))
    } else {
      NA_real_
    }
  } else {
    w <- w[ok]
    n <- if (weight_type == "frequency") sum(w) else length(x)
    total <- sum(w)
    r <- NA_real_
    if (total > 0) {
      dx <- x - sum(w * x) / total
      dy <- y - sum(w * y) / total
      r <- sum(w * dx * dy) / sqrt(sum(w * dx^2) * sum(w * dy^2))
    }
  }
  if (!is.finite(r)) {
    r <- NA_real_
  }
  p <- if (is.na(r) || n < 3) {
    NA_real_
  } else if (abs(r) >= 1) {
    0
  } else {
    statistic <- r * sqrt((n - 2) / (1 - r^2))
    2 * stats::pt(abs(statistic), df = n - 2, lower.tail = FALSE)
  }
  list(r = r, n = n, p = p)
}

pwcorr_long <- function(columns, w, method, weight_type) {
  variables <- names(columns)
  pairs <- utils::combn(length(variables), 2L)
  results <- lapply(seq_len(ncol(pairs)), function(k) {
    i <- pairs[1L, k]
    j <- pairs[2L, k]
    pwcorr_pair(columns[[i]], columns[[j]], w, method, weight_type)
  })
  n <- vapply(results, `[[`, numeric(1), "n")
  if (is.null(w) || weight_type == "analytic") {
    n <- as.integer(n)
  }
  tibble::tibble(
    var1 = variables[pairs[1L, ]],
    var2 = variables[pairs[2L, ]],
    r = vapply(results, `[[`, numeric(1), "r"),
    n = n,
    p = vapply(results, `[[`, numeric(1), "p")
  )
}

pwcorr_wide <- function(columns, w, method) {
  variables <- names(columns)
  size <- length(variables)
  matrix <- matrix(NA_real_, size, size)
  for (i in seq_len(size)) {
    for (j in seq_len(i)) {
      matrix[i, j] <- if (i == j) {
        1
      } else {
        pwcorr_pair(columns[[i]], columns[[j]], w, method, "frequency")$r
      }
    }
  }
  colnames(matrix) <- variables
  dplyr::bind_cols(
    tibble::tibble(variable = variables),
    tibble::as_tibble(matrix, .name_repair = "minimal")
  )
}

# Group keys in sorted order with the row locations of each group. Ungrouped
# data form one group with no key columns.
group_locations <- function(data, group_vars) {
  if (!length(group_vars)) {
    return(list(
      keys = tibble::new_tibble(list(), nrow = 1L),
      locs = list(seq_len(nrow(data)))
    ))
  }
  groups <- vctrs::vec_group_loc(
    tibble::as_tibble(data[group_vars], .name_repair = "minimal")
  )
  order <- vctrs::vec_order(groups$key)
  list(
    keys = vctrs::vec_slice(groups$key, order),
    locs = groups$loc[order]
  )
}
