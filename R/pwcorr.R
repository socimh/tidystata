#' Calculate pairwise correlations
#'
#' @description
#' Calculate pairwise correlations, like Stata's `pwcorr, sig obs`. Each pair of
#' variables uses every row where both are observed (pairwise deletion), and the
#' table reports the correlation, the number of observations and the p-value.
#'
#' @inheritParams tidystata_args
#' @param ... <[`tidy-select`][dplyr_tidy_select]> or
#'   <[`data-masking`][args_data_masking]> Columns to select or compute with
#'   [select_or_transmute()]. Existing columns, selection helpers, and named
#'   expressions can be mixed. Results must be numeric or logical vector
#'   columns. Matrix columns are unsupported. Omit to use every numeric or
#'   logical vector column; other columns are then skipped. Selecting another
#'   type is an error.
#' @param .method `"pearson"` (default) or `"spearman"`, like Stata's `pwcorr`
#'   and `spearman, pw`. [spearman()] gives Spearman correlations with Stata's
#'   default casewise deletion.
#' @param .wide If `TRUE`, return the correlation matrix as Stata prints it: one
#'   row per variable and the lower triangle filled, without `n` or `p`.
#' @param .wt Optional weights: a numeric column of `.data` (or a vector with
#'   one value per row), like Stata's `pwcorr [fweight/aweight]`. Pearson
#'   correlations only. Rows with a missing weight are excluded with a message.
#' @param .wt_type `"frequency"` (default) or `"analytic"`. The correlation is
#'   the same under both; with frequency weights, `n` and the p-value use the
#'   summed weight, and with analytic weights the number of observed rows.
#'   See Details for zero-weight handling.
#' @param .listwise If `TRUE`, use only rows where every selected variable is
#'   observed, like Stata's `pwcorr, listwise`. Every pair then has the same
#'   `n`. Unlike [corr()], `p` is kept.
#' @param .adjust `"none"` (default), `"bonferroni"` or `"sidak"`, like Stata's
#'   `bonferroni` and `sidak` options. Adjust p-values separately within each
#'   group; not available with `.wide = TRUE`.
#'
#' @returns An ungrouped tibble with:
#' * By default, one row per distinct variable pair and group, with any grouping
#'   keys, `var1`, `var2`, `r` (correlation), `n` (observations or summed
#'   frequency weight), and `p` (two-sided p-value).
#' * With `.wide = TRUE`, one row per variable and group, with grouping keys,
#'   `variable`, and one correlation column per variable. The diagonal is 1 and
#'   the upper triangle is `NA`; `n` and `p` are omitted.
#'
#' Undefined correlations and p-values are `NA` (see Details).
#'
#' @details
#' Computed columns are evaluated on ungrouped working data before correlations
#' are calculated within groups. Create columns with grouped [dplyr::mutate()]
#' first when a calculation needs to run separately within each group.
#'
#' Labelled numeric columns are correlated on their codes, excluding tagged
#' and SPSS user-missing values. Use [corr()] for listwise Pearson correlations,
#' like Stata's `corr` (`correlate`).
#'
#' Weights must be finite and nonnegative. Fractional frequency weights are
#' accepted, extending Stata's integer frequency-weight convention. Zero-weight
#' rows do not contribute to the correlation. With pairwise deletion, analytic
#' `n` includes complete zero-weight rows; with `.listwise = TRUE`, these rows
#' are excluded from the common sample and from `n`. This also affects p-values.
#'
#' The p-value is the two-sided test of zero correlation that Stata reports.
#' For Pearson correlations it is based on `t = r * sqrt((n - 2) / (1 - r^2))`
#' with `n - 2` degrees of freedom and matches `cor.test()`. For Spearman
#' correlations it is the beta approximation of Stata 18 and later; see
#' [spearman()]. Correlations with a constant variable, and p-values with fewer
#' than three observations, are `NA`.
#'
#' With `k` distinct variable pairs within a group, Bonferroni and Sidak
#' adjustments are `min(1, k * p)` and `min(1, 1 - (1 - p)^k)`, respectively.
#' Each group's `k` includes pairs whose p-value is `NA`; adjustment does not
#' combine tests across groups.
#'
#' Stata's display options `star()` and `print()` are not implemented, because
#' the result is a data frame: filter it instead, for example with
#' `dplyr::filter(p < 0.05)`. Use `.listwise = TRUE` for Stata's `casewise`.
#'
#' @examples
#' pwcorr(lifeexp, lexp, gnppc, safewater)
#'
#' pwcorr(lifeexp, lexp, gnppc, safewater, .wide = TRUE)
#'
#' pwcorr(lifeexp, lexp, gnppc, .by = region)
#'
#' pwcorr(lifeexp, lexp, gnppc, .method = "spearman")
#'
#' # One common sample, with Bonferroni-adjusted p-values
#' pwcorr(
#'   lifeexp, lexp, gnppc, safewater,
#'   .listwise = TRUE, .adjust = "bonferroni"
#' )
#'
#' # Correlate an existing column with a computed column
#' pwcorr(lifeexp, lexp, gnppc_thousands = gnppc / 1000)
#' @family tabulation functions
#' @export
pwcorr <- function(
  .data,
  ...,
  .by = NULL,
  .method = c("pearson", "spearman"),
  .wide = FALSE,
  .wt = NULL,
  .wt_type = c("frequency", "analytic"),
  .listwise = FALSE,
  .adjust = c("none", "bonferroni", "sidak")
) {
  pwcorr_data(
    .data,
    ...,
    .by = {{ .by }},
    .method = .method,
    .wide = .wide,
    .wt = {{ .wt }},
    .wt_type = .wt_type,
    .listwise = .listwise,
    .adjust = .adjust
  )
}

# Shared preparation and output for pairwise and complete-case correlations.
# `.p = FALSE` drops the p-value column, as corr() does.
pwcorr_data <- function(
  .data,
  ...,
  .by = NULL,
  .method = c("pearson", "spearman"),
  .wide = FALSE,
  .wt = NULL,
  .wt_type = c("frequency", "analytic"),
  .listwise = FALSE,
  .adjust = c("none", "bonferroni", "sidak"),
  .p = TRUE
) {
  local_wrapper_error_call()
  check_data_frame(.data)
  .method <- rlang::arg_match(.method)
  .wt_type <- rlang::arg_match(.wt_type)
  .adjust <- rlang::arg_match(.adjust)
  check_bool(.wide)
  check_bool(.listwise)
  if (.wide && .adjust != "none") {
    cli::cli_abort(
      "{.arg .adjust} needs p-values, which {.code .wide = TRUE} omits."
    )
  }
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
  error_call <- rlang::current_env()
  weighted <- weights_prepare(.data, rlang::enquo(.wt))
  if (!is.null(weighted$weights) && .method != "pearson") {
    cli::cli_abort("{.arg .wt} is supported for Pearson correlations only.")
  }
  .data <- weights_drop_column(
    weighted$data,
    weighted$column,
    !missing(...),
    group_vars
  )
  weights <- weighted$weights

  values <- remove_group_vars(.data, ..., group_vars = group_vars)
  values <- pwcorr_values(values, selected = !missing(...), call = error_call)
  if (.wide && "variable" %in% names(values)) {
    cli::cli_abort(
      "Column {.var variable} holds the row names of the wide table; rename the variable {.var variable} first."
    )
  }
  reserved <- if (.wide) {
    "variable"
  } else {
    c("var1", "var2", "r", "n", if (.p) "p")
  }
  clash <- intersect(group_vars, c(reserved, if (.wide) names(values)))
  if (length(clash)) {
    cli::cli_abort(
      "Grouping variable {.var {clash[[1L]]}} clashes with an output column name; rename it first."
    )
  }

  groups <- group_locations(.data, group_vars)
  out <- lapply(seq_along(groups$locs), function(i) {
    loc <- groups$locs[[i]]
    w <- if (is.null(weights)) NULL else weights[loc]
    columns <- lapply(values, `[`, loc)
    if (.listwise) {
      complete <- Reduce(`&`, lapply(columns, Negate(is.na)))
      if (!is.null(w)) {
        complete <- complete & w > 0
      }
      columns <- lapply(columns, `[`, complete)
      if (!is.null(w)) w <- w[complete]
    }
    table <- if (.wide) {
      pwcorr_wide(columns, w, .method)
    } else {
      pwcorr_long(columns, w, .method, .wt_type, .adjust)
    }
    if (!.p && !.wide) {
      table$p <- NULL
    }
    keys <- vctrs::vec_slice(groups$keys, rep(i, nrow(table)))
    dplyr::bind_cols(keys, table)
  })
  if (!length(out)) {
    empty <- if (.wide) {
      pwcorr_wide(lapply(values, `[`, 0L), NULL, .method)
    } else {
      pwcorr_long(lapply(values, `[`, 0L), NULL, .method, .wt_type, .adjust)
    }
    if (!.p && !.wide) {
      empty$p <- NULL
    }
    return(dplyr::bind_cols(groups$keys, empty[0L, ]))
  }
  vctrs::vec_rbind(!!!out)
}

# Numeric versions of the correlated columns. Unselected non-numeric columns
# are skipped; explicitly selected ones are an error.
pwcorr_values <- function(data, selected, call = rlang::caller_env()) {
  numeric <- lapply(data, function(x) {
    if (!is.null(dim(x))) {
      return(NULL)
    }
    if (is.logical(x) && !is.object(x)) {
      return(as.numeric(x))
    }
    if (inherits(x, "haven_labelled") && is.numeric(vctrs::vec_data(x))) {
      return(labelled_numeric(x))
    }
    if (is.numeric(x) && !is.object(x)) {
      return(as.numeric(x))
    }
    NULL
  })
  invalid <- vapply(numeric, is.null, logical(1))
  if (selected && any(invalid)) {
    cli::cli_abort(
      "{.var {names(data)[invalid]}} must be numeric or logical to be correlated.",
      call = call
    )
  }
  numeric <- numeric[!invalid]
  if (length(numeric) < 2L) {
    cli::cli_abort(
      "Select at least two numeric variables to correlate.",
      call = call
    )
  }
  numeric
}

# Correlation, observation count and p-value for one pair of columns. `ok`
# marks complete pairs; callers pass it to reuse each column's missing mask.
pwcorr_pair <- function(
  x,
  y,
  w,
  method,
  weight_type,
  ok = !is.na(x) & !is.na(y)
) {
  if (is.null(w)) {
    n <- sum(ok)
    # cor() drops incomplete pairs itself, with the same result as on the
    # complete subsets, so the columns are not copied for every pair.
    r <- if (n > 1L) {
      suppressWarnings(stats::cor(
        x,
        y,
        method = method,
        use = if (n == length(ok)) "everything" else "complete.obs"
      ))
    } else {
      NA_real_
    }
  } else {
    if (!all(ok)) {
      x <- x[ok]
      y <- y[ok]
      w <- w[ok]
    }
    n <- if (weight_type == "frequency") sum(w) else length(x)
    positive <- w > 0
    r <- NA_real_
    if (any(positive)) {
      # Zero-weight rows contribute to analytic n, but not to arithmetic.
      x <- x[positive]
      y <- y[positive]
      w <- w[positive] / max(w[positive])
      # Center before scaling to preserve small representable differences
      # when a variable has a large common offset.
      x <- pwcorr_rescale(x)
      y <- pwcorr_rescale(y)
      total <- sum(w)
      dx <- x - sum(w * x) / total
      dy <- y - sum(w * y) / total
      # Separate square roots avoid underflow in the variance product.
      r <- sum(w * dx * dy) / sqrt(sum(w * dx^2)) / sqrt(sum(w * dy^2))
    }
  }
  if (!is.finite(r)) {
    r <- NA_real_
  }
  p <- if (is.na(r) || n < 3) {
    NA_real_
  } else if (method == "spearman") {
    spearman_p(rank(x[ok]), rank(y[ok]), r)
  } else if (abs(r) >= 1) {
    0
  } else {
    statistic <- r * sqrt((n - 2) / (1 - r^2))
    2 * stats::pt(abs(statistic), df = n - 2, lower.tail = FALSE)
  }
  list(r = r, n = n, p = p)
}

# Two-sided Spearman p-value as in Stata 18 and later (spearman.ado): a beta
# distribution fitted to the first four exact permutation moments of the
# cross-product of the ranks, or a normal approximation when no valid fit
# exists.
spearman_p <- function(x, y, rho) {
  n <- length(x)
  fit <- if (n >= 4L) spearman_beta_fit(x, y) else NULL
  if (is.null(fit)) {
    statistic <- sqrt(n - 1) * rho
    lower <- stats::pnorm(statistic)
    upper <- stats::pnorm(-statistic)
  } else {
    lower <- stats::pbeta(fit$stat, fit$alpha, fit$beta)
    upper <- stats::pbeta(fit$stat, fit$alpha, fit$beta, lower.tail = FALSE)
  }
  min(1, 2 * min(lower, upper))
}

# Stata's Moments and BetaFit programs. Returns the statistic on the [0, 1]
# scale of the fitted beta distribution, or NULL when the fit is invalid.
spearman_beta_fit <- function(x, y) {
  center <- function(v) {
    mean <- mean(v)
    v - if (abs(mean) < 1) mean else trunc(mean)
  }
  x <- center(x)
  y <- center(y)
  n <- length(x)
  sx <- spearman_power_sums(x)
  sy <- spearman_power_sums(y)
  m1 <- n * sx$mean * sy$mean
  m2 <- (n - 1) * sx$sd2 * sy$sd2
  m3 <- (sx$x3 *
    sy$x3 +
    (3 * sx$x2x * sy$x2x + 36 * sx$xxx * sy$xxx / (n - 2)) / (n - 1)) /
    n -
    3 * m1 * m2 -
    m1^3
  m4 <- (sx$x4 *
    sy$x4 +
    (4 *
      sx$x3x *
      sy$x3x +
      12 * sx$x2x2 * sy$x2x2 +
      (24 * sx$x2xx * sy$x2xx + 576 * sx$xxxx * sy$xxxx / (n - 3)) / (n - 2)) /
      (n - 1)) /
    n -
    4 * m1 * m3 -
    6 * m1^2 * m2 -
    m1^4
  g3 <- m3 / sqrt(m2)^3
  g4 <- m4 / m2^2
  r <- 6 * (g4 - g3^2 - 1) / (6 + 3 * g3^2 - 2 * g4)
  d <- 1 - 24 * (r + 1) / ((r + 2) * (r + 3) * g4 - 3 * (r - 6) * (r + 1))
  # A negative discriminant gives a symmetric beta distribution.
  d <- sqrt(max(d, 0))
  shape <- (r / 2) * if (g3 > 0) c(1 - d, 1 + d) else c(1 + d, 1 - d)
  if (anyNA(shape) || any(shape <= 0)) {
    return(NULL)
  }
  e <- sqrt(m2 * (sum(shape) + 1) / prod(shape))
  lower <- m1 - shape[[1L]] * e
  upper <- m1 + shape[[2L]] * e
  if (!is.finite(lower) || !is.finite(upper) || lower >= upper) {
    return(NULL)
  }
  list(
    stat = (sum(x * y) - lower) / (upper - lower),
    alpha = shape[[1L]],
    beta = shape[[2L]]
  )
}

# Power sums over distinct indices that the permutation moments need, such as
# `x2x` = sum over i != j of x[i]^2 * x[j], computed by Stata's recursions.
spearman_power_sums <- function(x) {
  x <- sort(x)
  lag <- function(v) c(0, v[-length(v)])
  s1 <- cumsum(x)
  s2 <- cumsum(x^2)
  s3 <- cumsum(x^3)
  xx <- cumsum(x * lag(s1))
  x2x <- cumsum(x * (lag(s2) + x * lag(s1)))
  xxx <- cumsum(x * lag(xx))
  list(
    mean = mean(x),
    sd2 = stats::var(x),
    x3 = sum(x^3),
    x4 = sum(x^4),
    x2x = x2x[[length(x)]],
    xxx = xxx[[length(x)]],
    x3x = sum(x * (lag(s3) + x^2 * lag(s1))),
    x2x2 = sum(x^2 * lag(s2)),
    x2xx = sum(x * (lag(x2x) + x * lag(xx))),
    xxxx = sum(x * lag(xxx))
  )
}


# Anchor subtraction preserves nearby gaps. Opposite finite extremes can
# overflow during subtraction, so only that case needs scaling first.
pwcorr_rescale <- function(x) {
  centered <- x - x[[1L]]
  if (all(is.finite(x)) && any(!is.finite(centered))) {
    x <- x / max(abs(x))
    centered <- x - x[[1L]]
  }
  scale <- max(abs(centered))
  if (is.finite(scale) && scale > 0) centered / scale else centered
}

pwcorr_long <- function(columns, w, method, weight_type, adjust = "none") {
  variables <- names(columns)
  pairs <- utils::combn(length(variables), 2L)
  observed <- lapply(columns, Negate(is.na))
  results <- lapply(seq_len(ncol(pairs)), function(k) {
    i <- pairs[1L, k]
    j <- pairs[2L, k]
    ok <- observed[[i]] & observed[[j]]
    pwcorr_pair(columns[[i]], columns[[j]], w, method, weight_type, ok)
  })
  n <- vapply(results, `[[`, numeric(1), "n")
  if (is.null(w) || weight_type == "analytic") {
    n <- as.integer(n)
  }
  p <- vapply(results, `[[`, numeric(1), "p")
  # Like Stata, adjust for every pair in the table, not only defined p-values.
  k <- ncol(pairs)
  p <- switch(
    adjust,
    none = p,
    bonferroni = pmin(1, k * p),
    sidak = pmin(1, -expm1(k * log1p(-p)))
  )
  tibble::tibble(
    var1 = variables[pairs[1L, ]],
    var2 = variables[pairs[2L, ]],
    r = vapply(results, `[[`, numeric(1), "r"),
    n = n,
    p = p
  )
}

pwcorr_wide <- function(columns, w, method) {
  variables <- names(columns)
  size <- length(variables)
  matrix <- matrix(NA_real_, size, size)
  observed <- lapply(columns, Negate(is.na))
  for (i in seq_len(size)) {
    for (j in seq_len(i)) {
      matrix[i, j] <- if (i == j) {
        1
      } else {
        ok <- observed[[i]] & observed[[j]]
        pwcorr_pair(columns[[i]], columns[[j]], w, method, "frequency", ok)$r
      }
    }
  }
  colnames(matrix) <- variables
  dplyr::bind_cols(
    tibble::tibble(variable = variables),
    tibble::as_tibble(matrix, .name_repair = "minimal")
  )
}
