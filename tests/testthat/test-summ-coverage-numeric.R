# Cases 001-050 are shared public contracts, independently run for each export.
# The oracle uses the documented R conventions, never statart internals.
summ_cov_reference <- function(x) {
  observed <- as.numeric(x[!is.na(x)])
  n <- length(observed)
  counts <- c(
    n = n,
    unique = length(unique(observed)),
    missing = sum(is.na(x)),
    valid_pct = if (length(x)) n / length(x) else NA_real_
  )
  if (!n) {
    return(c(
      counts,
      stats::setNames(
        rep(NA_real_, 13),
        c(
          "min",
          "p25",
          "p50",
          "mean",
          "mad",
          "sd",
          "p75",
          "max",
          "iqr",
          "skew",
          "kurtosis",
          "se",
          "sum"
        )
      )
    ))
  }
  center <- mean(observed)
  spread <- stats::sd(observed)
  c(
    counts,
    min = min(observed),
    p25 = unname(stats::quantile(observed, .25)),
    p50 = stats::median(observed),
    mean = center,
    mad = stats::mad(observed),
    sd = spread,
    p75 = unname(stats::quantile(observed, .75)),
    max = max(observed),
    iqr = diff(unname(stats::quantile(observed, c(.25, .75)))),
    skew = mean((observed - center)^3) / spread^3,
    kurtosis = mean((observed - center)^4) / spread^4 - 3,
    se = spread / sqrt(n),
    sum = sum(observed)
  )
}

summ_cov_numeric_cases <- list()
summ_cov_register <- function(id, category, title, check) {
  summ_cov_numeric_cases[[length(summ_cov_numeric_cases) + 1L]] <<-
    list(id = as.integer(id), category = category, title = title, check = check)
}
summ_cov_vectors <- list(
  "positive integers" = 1:7,
  "all negative values" = c(-10, -5, -2, -1),
  "mixed signs" = c(-10, -2, 0, 3, 12),
  "constant nonzero values" = rep(7, 5),
  "constant zero values" = rep(0, 5),
  "singleton observation" = 9,
  "zero observations" = numeric(),
  "entirely NA values" = rep(NA_real_, 4),
  "entirely NaN values" = rep(NaN, 4),
  "mixed NA and NaN only" = c(NA_real_, NaN, NA_real_),
  "partially missing values" = c(1, NA, 3, NaN, 9),
  "positive infinity" = c(1, 2, Inf),
  "negative infinity" = c(-Inf, 1, 2),
  "both infinities" = c(-Inf, 0, Inf),
  "signed zeros" = c(-0, 0, -0, 0),
  "fractional values" = c(.125, .5, 1.75, 2.125),
  "tiny nonzero values" = c(1, 2, 3, 5) * 1e-10,
  "large offset with small spread" = 1e9 + c(1, 2, 4, 8),
  "very large magnitudes" = c(-1e150, -2e149, 1e149, 1e150),
  "near-minimum positive magnitudes" = .Machine$double.xmin * c(1, 2, 4, 8),
  "integer storage boundaries" = as.integer(c(-2147483647, 0, 2147483647)),
  "missing values at both ends" = c(NA_real_, 1, 2, 3, NA_real_),
  "repeated values and ties" = c(1, 1, 1, 4, 4, 9),
  "logical zero-one values" = c(TRUE, FALSE, TRUE, NA)
)
for (i in seq_along(summ_cov_vectors)) {
  local({
    x <- summ_cov_vectors[[i]]
    case_id <- i
    summ_cov_register(
      i,
      "numeric",
      names(summ_cov_vectors)[[i]],
      function(api) {
        df <- tibble::tibble(x = x)
        before <- df
        expected <- summ_cov_reference(x)
        if (length(x) && all(is.na(x))) {
          expect_warning(
            out <- api(df, .stat = names(expected)),
            "entirely missing"
          )
        } else {
          out <- api(df, .stat = names(expected))
        }
        expect_equal(
          unlist(out[names(expected)], use.names = FALSE),
          unname(expected),
          tolerance = 1e-10
        )
        expect_identical(df, before)
        if (case_id == 20L) {
          expect_equal(out$min, min(x), tolerance = 0)
          expect_equal(out$max, max(x), tolerance = 0)
          expect_gt(out$mean, 0)
          expect_gt(out$sum, 0)
        }
      }
    )
  })
}

summ_cov_register(
  25,
  "invariant",
  "row permutations preserve statistics",
  function(api) {
    x <- c(-3, 1, 1, 7, 12, NA_real_)
    requested <- names(summ_cov_reference(x))
    before <- api(tibble::tibble(x = x), .stat = requested)
    after <- api(tibble::tibble(x = rev(x)), .stat = requested)
    expect_equal(before, after, tolerance = 1e-10)
  }
)
summ_cov_register(
  26,
  "invariant",
  "duplicating rows doubles counts and sum",
  function(api) {
    x <- c(-3, 1, 7, NA_real_)
    out <- api(
      tibble::tibble(x = rep(x, 2)),
      .stat = c("n", "missing", "mean", "sum", "sd")
    )
    expect_equal(out$n, 6)
    expect_equal(out$missing, 2)
    expect_equal(out$mean, mean(x, na.rm = TRUE))
    expect_equal(out$sum, 2 * sum(x, na.rm = TRUE))
    expect_equal(out$sd, stats::sd(rep(x, 2), na.rm = TRUE))
  }
)
summ_cov_register(
  27,
  "invariant",
  "translation shifts location but preserves spread",
  function(api) {
    x <- c(-3, 1, 7, 12)
    requested <- c("min", "mean", "p50", "max", "sd", "iqr")
    a <- api(tibble::tibble(x = x), .stat = requested)
    b <- api(tibble::tibble(x = x + 100), .stat = requested)
    expect_equal(
      unlist(b[c("min", "mean", "p50", "max")], use.names = FALSE),
      unlist(a[c("min", "mean", "p50", "max")], use.names = FALSE) + 100
    )
    expect_equal(b$sd, a$sd)
    expect_equal(b$iqr, a$iqr)
  }
)
summ_cov_register(
  28,
  "invariant",
  "negative scaling reverses extrema",
  function(api) {
    x <- c(-3, 1, 7, 12)
    out <- api(
      tibble::tibble(x = -2 * x),
      .stat = c("min", "max", "mean", "sd")
    )
    expect_equal(out$min, -2 * max(x))
    expect_equal(out$max, -2 * min(x))
    expect_equal(out$mean, -2 * mean(x))
    expect_equal(out$sd, 2 * stats::sd(x))
  }
)
summ_cov_register(
  29,
  "numeric",
  "two-point sample SD uses n minus one",
  function(api) {
    out <- api(tibble::tibble(x = c(2, 6)), .stat = c("sd", "se"))
    expect_equal(out$sd, sqrt(8))
    expect_equal(out$se, 2)
  }
)
summ_cov_register(
  30,
  "numeric",
  "two-point percentiles interpolate with type seven",
  function(api) {
    out <- api(tibble::tibble(x = c(0, 10)), .stat = c("p25", "p50", "p75"))
    expect_equal(
      unlist(out[c("p25", "p50", "p75")], use.names = FALSE),
      c(2.5, 5, 7.5)
    )
  }
)
summ_cov_register(
  31,
  "numeric",
  "geometric values retain asymmetric moments",
  function(api) {
    x <- c(1, 2, 4, 8, 16, 32)
    expected <- summ_cov_reference(x)
    out <- api(tibble::tibble(x = x), .stat = names(expected))
    expect_equal(
      unlist(out[names(expected)], use.names = FALSE),
      unname(expected)
    )
  }
)
summ_cov_register(
  32,
  "size",
  "ten thousand integers match closed-form references",
  function(api) {
    n <- 10000
    out <- api(
      tibble::tibble(x = seq_len(n)),
      .stat = c("n", "mean", "sum", "sd")
    )
    expect_equal(out$n, n)
    expect_equal(out$mean, (n + 1) / 2)
    expect_equal(out$sum, n * (n + 1) / 2)
    expect_equal(out$sd, sqrt(n * (n + 1) / 12))
  }
)
summ_cov_register(
  33,
  "grouping",
  "single groups preserve first appearance and counts",
  function(api) {
    df <- tibble::tibble(g = c("B", "A", "B", "A"), x = c(1, 4, 3, 8))
    out <- api(df, x, .by = g, .stat = c("n", "mean", "sum"))
    expect_equal(out$g, c("B", "A"))
    expect_equal(out$n, c(2, 2))
    expect_equal(out$mean, c(2, 6))
    expect_equal(out$sum, c(4, 12))
  }
)
summ_cov_register(
  34,
  "grouping",
  "two grouping keys retain missing combinations",
  function(api) {
    df <- tibble::tibble(
      g = c("A", "A", NA, "A"),
      h = c(1, NA, 1, 1),
      x = c(1, 4, 8, 3)
    )
    out <- api(df, x, .by = c(g, h), .stat = c("n", "sum"))
    expect_equal(out$g, c("A", "A", NA_character_))
    expect_equal(out$h, c(1, NA, 1))
    expect_equal(out$n, c(2, 1, 1))
    expect_equal(out$sum, c(4, 4, 8))
  }
)
summ_cov_register(
  35,
  "grouping",
  "missing key removal affects every selected key",
  function(api) {
    df <- tibble::tibble(
      g = c("A", "A", NA, "A"),
      h = c(1, NA, 1, 1),
      x = c(1, 4, 8, 3)
    )
    out <- api(df, x, .by = c(g, h), .missing = FALSE, .stat = c("n", "sum"))
    expect_equal(nrow(out), 1L)
    expect_equal(out$n, 2)
    expect_equal(out$sum, 4)
  }
)
summ_cov_register(
  36,
  "grouping",
  "all-missing measured groups remain present",
  function(api) {
    df <- tibble::tibble(g = c("A", "A", "B", "B"), x = c(1, 3, NA, NaN))
    out <- api(df, x, .by = g, .stat = c("n", "missing", "sum", "mean"))
    expect_equal(out$n, c(2, 0))
    expect_equal(out$missing, c(0, 2))
    expect_equal(out$sum, c(4, NA_real_))
    expect_equal(out$mean, c(2, NA_real_))
  }
)
summ_cov_register(
  37,
  "grouping",
  "numeric grouping keys preserve missing keys",
  function(api) {
    df <- tibble::tibble(g = c(2, 1, 2, NA_real_), x = c(1, 4, 3, 8))
    out <- api(df, x, .by = g, .stat = "sum")
    expect_equal(out$g, c(2, 1, NA_real_))
    expect_equal(out$sum, c(4, 4, 8))
  }
)
summ_cov_register(
  38,
  "grouping",
  "unused factor levels do not invent observations",
  function(api) {
    df <- tibble::tibble(
      g = factor(c("B", "B"), levels = c("A", "B", "C")),
      x = c(1, 3)
    )
    out <- api(df, x, .by = g, .stat = c("n", "mean"))
    expect_equal(as.character(out$g), "B")
    expect_equal(out$n, 2)
    expect_equal(out$mean, 2)
  }
)
summ_cov_register(
  39,
  "grouping",
  "existing multi-key grouping uses both keys",
  function(api) {
    df <- dplyr::group_by(
      tibble::tibble(g = c("A", "A", "A"), h = c(1, 2, 1), x = c(1, 8, 3)),
      g,
      h
    )
    out <- api(df, x, .stat = "sum")
    expect_equal(out$h, c(1, 2))
    expect_equal(out$sum, c(4, 8))
    expect_identical(dplyr::group_vars(df), c("g", "h"))
  }
)
summ_cov_register(
  40,
  "grouping",
  "explicit regrouping replaces existing groups",
  function(api) {
    df <- dplyr::group_by(
      tibble::tibble(g = c("A", "B", "A"), h = c(1, 1, 2), x = c(1, 3, 8)),
      g
    )
    out <- api(df, x, .by = h, .stat = "mean")
    expect_false("g" %in% names(out))
    expect_equal(out$h, c(1, 2))
    expect_equal(out$mean, c(2, 8))
  }
)
summ_cov_register(
  41,
  "grouping",
  "dropping all missing keys yields typed empty output",
  function(api) {
    df <- tibble::tibble(g = c(NA_character_, NA_character_), x = c(1, 3))
    out <- api(df, x, .by = g, .missing = FALSE, .stat = c("n", "mean"))
    expect_equal(nrow(out), 0L)
    expect_named(out, c("g", "name", "type", "n", "mean"))
    expect_type(out$g, "character")
    expect_type(out$mean, "double")
  }
)
summ_cov_register(
  42,
  "grouping",
  "multiple measured columns retain within-group identity",
  function(api) {
    df <- tibble::tibble(g = c("A", "A", "B"), x = c(1, 3, 8), y = c(2, 4, 9))
    out <- api(df, x, y, .by = g, .stat = c("n", "sum"))
    expect_equal(out$g, c("A", "A", "B", "B"))
    expect_equal(out$name, c("x", "y", "x", "y"))
    expect_equal(out$n, c(2, 2, 1, 1))
    expect_equal(out$sum, c(4, 6, 8, 9))
  }
)
summ_cov_register(
  43,
  "names",
  "multiple reserved grouping keys preserve their values",
  function(api) {
    df <- tibble::tibble(
      sum = c("A", "A", "B"),
      missing = c(1, 1, 2),
      x = c(1, 3, 8)
    )
    out <- suppressMessages(api(
      df,
      x,
      .by = c(sum, missing),
      .stat = c("n", "mean")
    ))
    expect_equal(out$.sum, c("A", "B"))
    expect_equal(out$.missing, c(1, 2))
    expect_equal(out$n, c(2, 1))
    expect_equal(out$mean, c(2, 8))
  }
)
summ_cov_register(
  44,
  "names",
  "reserved grouping repair avoids unused input names",
  function(api) {
    df <- tibble::tibble(n = c(1, 1, 2), .n = c(10, 20, 30), x = c(1, 3, 8))
    out <- suppressMessages(api(df, x, .by = n, .stat = "mean"))
    expect_equal(out$..n, c(1, 2))
    expect_equal(out$mean, c(2, 8))
  }
)
summ_cov_register(
  45,
  "names",
  "Unicode measured names and grouping values survive",
  function(api) {
    df <- tibble::tibble(
      income = c(1, 3, 8),
      region = c("\u5317", "\u5317", NA)
    )
    names(df) <- c("\u6536\u5165", "\u5730\u533a")
    out <- api(
      df,
      tidyselect::all_of("\u6536\u5165"),
      .by = tidyselect::all_of("\u5730\u533a"),
      .stat = "mean"
    )
    expect_equal(out[["\u5730\u533a"]], c("\u5317", NA_character_))
    expect_equal(out$name, c("\u6536\u5165", "\u6536\u5165"))
    expect_equal(out$mean, c(2, 8))
  }
)
summ_cov_register(
  46,
  "names",
  "non-syntactic column names retain literal identity",
  function(api) {
    df <- tibble::tibble(x = c(1, 3, 8), g = c("A", "A", "B"))
    names(df) <- c("income [USD]", "group id")
    out <- api(
      df,
      tidyselect::all_of("income [USD]"),
      .by = tidyselect::all_of("group id"),
      .stat = "sum"
    )
    expect_equal(out$name, rep("income [USD]", 2))
    expect_equal(out[["group id"]], c("A", "B"))
    expect_equal(out$sum, c(4, 8))
  }
)
summ_cov_register(
  47,
  "names",
  "numeric summary names do not overwrite group identifiers",
  function(api) {
    df <- tibble::tibble(mean = c("A", "A", "B"), x = c(1, 3, 8))
    out <- suppressMessages(api(df, x, .by = mean, .stat = c("mean", "sum")))
    expect_equal(out$.mean, c("A", "B"))
    expect_equal(out$mean, c(2, 8))
    expect_equal(out$sum, c(4, 8))
  }
)
summ_cov_register(
  48,
  "preservation",
  "input variable labels and attributes remain unchanged",
  function(api) {
    df <- tibble::tibble(x = c(1, NA_real_, 3))
    attr(df$x, "label") <- "Monthly income"
    attr(df, "source") <- "fixture"
    before <- df
    out <- api(df, .stat = c("n", "mean"))
    expect_equal(out$n, 2)
    expect_equal(out$mean, 2)
    expect_identical(df, before)
  }
)
summ_cov_register(
  49,
  "numeric",
  "cancellation-prone values match base R arithmetic",
  function(api) {
    x <- c(1e16, 1, -1e16, 2)
    out <- api(tibble::tibble(x = x), .stat = c("mean", "sum", "sd"))
    expect_equal(out$mean, mean(x))
    expect_equal(out$sum, sum(x))
    expect_equal(out$sd, stats::sd(x))
  }
)
summ_cov_register(
  50,
  "size",
  "deterministic many-group summaries match independent subsets",
  function(api) {
    i <- seq_len(1000)
    df <- tibble::tibble(g = i %% 17L, x = as.double((i * 37L) %% 101L))
    df$x[i %% 19L == 0L] <- NA_real_
    before <- df
    out <- api(df, x, .by = g, .stat = c("n", "mean", "sum", "sd"))
    for (j in seq_len(nrow(out))) {
      x <- df$x[df$g == out$g[[j]]]
      expect_equal(out$n[[j]], sum(!is.na(x)))
      expect_equal(out$mean[[j]], mean(x, na.rm = TRUE))
      expect_equal(out$sum[[j]], sum(x, na.rm = TRUE))
      expect_equal(out$sd[[j]], stats::sd(x, na.rm = TRUE))
    }
    expect_identical(df, before)
  }
)
stopifnot(identical(
  vapply(summ_cov_numeric_cases, `[[`, integer(1), "id"),
  1:50
))
for (function_name in c("summ", "tabstat")) {
  for (case in summ_cov_numeric_cases) {
    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", case$id),
        paste0("[", case$category, "]"),
        case$title
      ),
      {
        case$check(
          summary_legacy_layout(getExportedValue("statart", function_name))
        )
      }
    )
  }
}
