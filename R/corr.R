#' Calculate Pearson and Spearman correlations
#'
#' @description
#' Calculate correlations between selected variables, with optional grouping:
#'
#' * `corr()`: Calculate Pearson correlations on one common complete sample,
#'   like Stata's `corr` (`correlate`), reporting correlations and counts.
#' * `pwcorr()`: Calculate Pearson correlations using a separate sample for each
#'   pair by default, like Stata's `pwcorr, sig obs`, reporting correlations,
#'   counts and p-values. Spearman correlations and a common sample are
#'   optional.
#' * `spearman()`: Calculate Spearman rank correlations on one common complete
#'   sample by default, like Stata's `spearman, stats(rho obs p)`, reporting
#'   correlations, counts and p-values. Pairwise samples are optional.
#'
#' @inheritParams tidystata_args
#' @param ... <[`tidy-select`][dplyr_tidy_select]> or
#'   <[`data-masking`][args_data_masking]> Columns to select or compute with
#'   [select_or_transmute()]. Existing columns, selection helpers, and named
#'   expressions can be mixed. Results must be numeric or logical vector
#'   columns. Matrix columns are unsupported. Omit to use every numeric or
#'   logical vector column except grouping keys and the weight column; other
#'   columns are then skipped. Explicitly selecting another type is an error.
#' @param .wide If `TRUE`, return a lower-triangular correlation table, like
#'   Stata's display, without counts or p-values. Defaults to `FALSE` (long).
#' @param .wt Optional numeric weights for `corr()` and Pearson `pwcorr()`,
#'   given as a column of `.data` or one value per row, like Stata's
#'   `[fweight/aweight]`. Missing weights exclude rows with a message; negative
#'   weights are invalid. Spearman correlations do not support weights.
#' @param .wt_type For `corr()` and Pearson `pwcorr()`, `"frequency"` (default)
#'   reports summed weights as `n`; `"analytic"` reports the number of observed
#'   rows. Both give the same weighted correlation. In `pwcorr()`, the choice
#'   also affects p-values. See Details for zero-weight handling.
#' @param .method For `pwcorr()`, `"pearson"` (default) or `"spearman"`.
#'   `corr()` always uses Pearson correlations; `spearman()` always uses ranks.
#' @param .listwise For `pwcorr()`, use one common complete sample if `TRUE`,
#'   like Stata's `listwise` (`casewise`). Defaults to `FALSE` (pairwise).
#'   `corr()` always uses a common sample; `spearman()` does so by default.
#' @param .pairwise For `spearman()`, use a separate sample for each pair if
#'   `TRUE`, like Stata's `pw`. Defaults to `FALSE` (one common complete
#'   sample).
#' @param .adjust For `pwcorr()` and `spearman()`, `"none"` (default),
#'   `"bonferroni"` or `"sidak"`, like Stata's corresponding options. Adjust
#'   p-values separately within each group; not available with `.wide = TRUE`.
#'
#' @returns An ungrouped tibble with:
#' * By default, one row per distinct variable pair and group, with grouping
#'   keys, `var1`, `var2`, `r` (Pearson correlation or Spearman's rho), and `n`
#'   (observations or summed frequency weights). `pwcorr()` and `spearman()`
#'   also return `p` (two-sided p-value); `corr()` omits it.
#' * With `.wide = TRUE`, one row per variable and group, with grouping keys,
#'   `variable`, and one correlation column per variable. The diagonal is 1 and
#'   the upper triangle is `NA`; `n` and `p` are omitted.
#'
#' Variables and pairs follow selection order within each group. Undefined
#' correlations and p-values are `NA`. With `n < 3`, `p` is `NA` even
#' when the correlation is defined; frequency-weighted `n` is the summed weight.
#' Empty grouped inputs return zero rows. The input is not modified.
#'
#' @details
#' **Samples and groups**
#'
#' Select at least two numeric or logical vector columns. Labelled numeric
#' columns use their codes; tagged and SPSS user-missing values are excluded.
#' Missingness in unselected columns does not affect the sample.
#'
#' Listwise deletion uses rows complete on every selected variable, giving
#' all pairs within a group the same sample and `n`. Pairwise deletion uses
#' rows complete for each pair. Groups with fewer than two observations keep
#' their pairs with `NA` correlations.
#'
#' Computed columns are evaluated before grouping and sample selection.
#' Use grouped [dplyr::mutate()] first for group-specific calculations.
#' With identical selections and weights, Pearson `pwcorr(.listwise = TRUE)`
#' matches `corr()` correlations and counts, and adds p-values. `spearman()`
#' matches `pwcorr(.method = "spearman", .listwise = TRUE)`;
#' `spearman(.pairwise = TRUE)` matches `pwcorr(.method = "spearman")`.
#'
#' **Weights**
#'
#' Weights must be finite and nonnegative. Fractional frequency weights are
#' accepted, extending Stata's integer-only convention. Zero-weight rows never
#' contribute to correlations. For pairwise Pearson samples, analytic `n` counts
#' complete zero-weight rows; common samples exclude them from both the sample
#' and `n`. This difference also affects p-values.
#'
#' **Inference**
#'
#' Pearson p-values use `t = r * sqrt((n - 2) / (1 - r^2))` with `n - 2`
#' degrees of freedom, matching [stats::cor.test()] for unweighted data.
#'
#' Spearman ranks are calculated within each pair's sample, with average ranks
#' for ties. P-values test independence using the Stata 18-and-later method:
#' a beta distribution fitted to the first four exact permutation moments.
#' For `n = 3`, or when no valid fit exists, the normal approximation uses
#' `sqrt(n - 1) * r`. Earlier Stata versions and [stats::cor.test()] use other
#' approximations and can give different p-values. Constant variables produce
#' `NA`; Stata's `spearman` instead reports a correlation of 1.
#'
#' Bonferroni and Sidak adjustments are `min(1, k * p)` and
#' `min(1, 1 - (1 - p)^k)`, where `k` counts distinct pairs within each group,
#' including pairs with `NA` p-values. Tests are not combined across groups.
#'
#' **Output names and Stata options**
#'
#' Grouping keys must not conflict with output column names. Wide output also
#' reserves `variable` and the selected variable names.
#'
#' Stata's `covariance`, `means` and display-formatting options are omitted.
#' Use [stats::cov()] for covariance, [summ()] for summaries, and filter the
#' returned table instead of using `star()` or `print()` (for example,
#' `dplyr::filter(p < 0.05)`). The default long table is an R interface choice;
#' Stata prints a matrix.
#'
#' @seealso [stats::cor()], [stats::cor.test()]
#' @references [Stata correlate manual](https://www.stata.com/manuals/rcorrelate.pdf),
#'   [Stata spearman manual](https://www.stata.com/manuals/rspearman.pdf).
#' @name corr
#' @family correlation functions
#'
#' @examples
#' corr(lifeexp, lexp, gnppc, safewater)
#'
#' pwcorr(lifeexp, lexp, gnppc, safewater)
#'
#' spearman(lifeexp, lexp, gnppc, safewater)
#'
#' # Return a correlation table, or calculate correlations by group
#' pwcorr(lifeexp, lexp, gnppc, safewater, .wide = TRUE)
#'
#' pwcorr(lifeexp, lexp, gnppc, .by = region)
#'
#' # Correlate an existing column with a computed column
#' corr(lifeexp, lexp, gnppc_k = gnppc / 1000)
#'
#' # Pairwise Spearman correlations with adjusted p-values
#' spearman(lifeexp, lexp, gnppc, safewater,
#'   .pairwise = TRUE, .adjust = "bonferroni"
#' )
#'
#' # Spearman correlations on one common sample using pwcorr()
#' pwcorr(lifeexp, lexp, gnppc, safewater,
#'   .method = "spearman", .listwise = TRUE
#' )
#'
#' # Pearson correlations on one common sample, retaining adjusted p-values
#' pwcorr(lifeexp, lexp, gnppc, safewater,
#'   .listwise = TRUE, .adjust = "bonferroni"
#' )
#' @rdname corr
#' @export
corr <- function(
  .data,
  ...,
  .by = NULL,
  .wide = FALSE,
  .wt = NULL,
  .wt_type = c("frequency", "analytic")
) {
  pwcorr_data(
    .data,
    ...,
    .by = {{ .by }},
    .method = "pearson",
    .wide = .wide,
    .wt = {{ .wt }},
    .wt_type = .wt_type,
    .listwise = TRUE,
    .p = FALSE
  )
}

#' @rdname corr
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

#' @rdname corr
#' @export
spearman <- function(
  .data,
  ...,
  .by = NULL,
  .pairwise = FALSE,
  .wide = FALSE,
  .adjust = c("none", "bonferroni", "sidak")
) {
  check_bool(.pairwise)
  pwcorr_data(
    .data,
    ...,
    .by = {{ .by }},
    .method = "spearman",
    .wide = .wide,
    .listwise = !.pairwise,
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
    # A single group spanning every row needs no subset copies.
    whole <- length(groups$locs) == 1L && length(loc) == nrow(.data)
    w <- if (is.null(weights) || whole) weights else weights[loc]
    columns <- if (whole) values else lapply(values, `[`, loc)
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
    # The native kernels read logical, integer and double storage in place,
    # treating only NA and NaN (including tagged NA) as missing. SPSS codes
    # declared missing must first become NA, which needs a copy.
    if ((is.logical(x) || is.numeric(x)) && !is.object(x)) {
      return(x)
    }
    if (inherits(x, "haven_labelled") && is.numeric(vctrs::vec_data(x))) {
      return(if (inherits(x, "haven_labelled_spss")) labelled_numeric(x) else x)
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

# Correlation, observation count and p-value for one pair of columns: the
# reference definition that the native pwcorr_pearson() and pwcorr_spearman()
# kernels reproduce exactly, kept for their regression tests. `ok` marks
# complete pairs.
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
  if (method == "pearson") {
    results <- pwcorr_pearson_pairs(columns, w, weight_type)
    p <- pwcorr_pearson_p(results$r, results$n)
  } else {
    results <- pwcorr_spearman(unname(columns))
    p <- results$p
  }
  r <- results$r
  n <- results$n
  if (is.null(w) || weight_type == "analytic") {
    n <- as.integer(n)
  }
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
    r = r,
    n = n,
    p = p
  )
}

# Pearson correlations and sample sizes for every pair, in combn() order,
# from one native pass per pair. Arithmetic matches pwcorr_pair().
pwcorr_pearson_pairs <- function(columns, w, weight_type) {
  if (length(columns) < 2L) {
    return(list(r = double(), n = double()))
  }
  pwcorr_pearson(
    unname(columns),
    if (is.null(w)) NULL else as.double(w),
    weight_type == "frequency"
  )
}

# Two-sided t-test p-values, as pwcorr_pair() gives for Pearson pairs.
pwcorr_pearson_p <- function(r, n) {
  p <- rep(NA_real_, length(r))
  defined <- !is.na(r) & n >= 3
  perfect <- defined & abs(r) >= 1
  p[perfect] <- 0
  tested <- defined & !perfect
  statistic <- r[tested] * sqrt((n[tested] - 2) / (1 - r[tested]^2))
  p[tested] <- 2 *
    stats::pt(abs(statistic), df = n[tested] - 2, lower.tail = FALSE)
  p
}

pwcorr_wide <- function(columns, w, method) {
  variables <- names(columns)
  size <- length(variables)
  matrix <- matrix(NA_real_, size, size)
  diag(matrix) <- 1
  if (size > 1L) {
    pairs <- utils::combn(size, 2L)
    # Pairs (i, j) with i < j fill the lower triangle at [j, i].
    matrix[cbind(pairs[2L, ], pairs[1L, ])] <- if (method == "pearson") {
      pwcorr_pearson_pairs(columns, w, "frequency")$r
    } else {
      pwcorr_spearman(unname(columns))$r
    }
  }
  colnames(matrix) <- variables
  dplyr::bind_cols(
    tibble::tibble(variable = variables),
    tibble::as_tibble(matrix, .name_repair = "minimal")
  )
}
