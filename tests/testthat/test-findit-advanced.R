findit_advanced_ipw_se <- function(data, estimand) {
  x <- stats::model.matrix(~ x + z, data)
  a <- data$treat
  y <- data$y
  p <- stats::fitted(stats::glm(
    treat ~ x + z,
    data = data,
    family = stats::binomial()
  ))
  w0 <- if (estimand == "ATE") (1 - a) / (1 - p) else (1 - a) * p / (1 - p)
  w1 <- if (estimand == "ATE") a / p else a
  mu0 <- stats::weighted.mean(y, w0)
  mu1 <- stats::weighted.mean(y, w1)
  k <- ncol(x)
  n <- nrow(x)
  # Joint logit scores and normalized weighted-mean equations, independently
  # differentiated from the Stata IPW estimating equations.
  scores <- cbind(x * as.numeric(a - p), w0 * (y - mu0), w1 * (y - mu1))
  derivative <- matrix(0, k + 2L, k + 2L)
  derivative[seq_len(k), seq_len(k)] <-
    -crossprod(x, x * as.numeric(p * (1 - p))) / n
  if (estimand == "ATE") {
    derivative[k + 1L, seq_len(k)] <- colMeans(
      x * as.numeric(w0 * p * (y - mu0))
    )
    derivative[k + 2L, seq_len(k)] <- -colMeans(
      x * as.numeric(w1 * (1 - p) * (y - mu1))
    )
  } else {
    derivative[k + 1L, seq_len(k)] <- colMeans(x * as.numeric(w0 * (y - mu0)))
  }
  derivative[k + 1L, k + 1L] <- -mean(w0)
  derivative[k + 2L, k + 2L] <- -mean(w1)
  inverse <- solve(derivative)
  covariance <- inverse %*% crossprod(scores) %*% t(inverse) / n^2
  contrast <- c(rep(0, k), -1, 1)
  sqrt(drop(contrast %*% covariance %*% contrast))
}

findit_advanced_ipw_se <- function(data, estimand) {
  x <- stats::model.matrix(~ x + z, data)
  a <- data$treat
  y <- data$y
  p <- stats::fitted(stats::glm(
    treat ~ x + z,
    data = data,
    family = stats::binomial()
  ))
  w0 <- if (estimand == "ATE") (1 - a) / (1 - p) else (1 - a) * p / (1 - p)
  w1 <- if (estimand == "ATE") a / p else a
  mu0 <- stats::weighted.mean(y, w0)
  mu1 <- stats::weighted.mean(y, w1)
  k <- ncol(x)
  n <- nrow(x)
  # Joint logit scores and normalized weighted-mean equations, independently
  # differentiated from the Stata IPW estimating equations.
  scores <- cbind(x * as.numeric(a - p), w0 * (y - mu0), w1 * (y - mu1))
  derivative <- matrix(0, k + 2L, k + 2L)
  derivative[seq_len(k), seq_len(k)] <-
    -crossprod(x, x * as.numeric(p * (1 - p))) / n
  if (estimand == "ATE") {
    derivative[k + 1L, seq_len(k)] <- colMeans(
      x * as.numeric(w0 * p * (y - mu0))
    )
    derivative[k + 2L, seq_len(k)] <- -colMeans(
      x * as.numeric(w1 * (1 - p) * (y - mu1))
    )
  } else {
    derivative[k + 1L, seq_len(k)] <- colMeans(x * as.numeric(w0 * (y - mu0)))
  }
  derivative[k + 1L, k + 1L] <- -mean(w0)
  derivative[k + 2L, k + 2L] <- -mean(w1)
  inverse <- solve(derivative)
  covariance <- inverse %*% crossprod(scores) %*% t(inverse) / n^2
  contrast <- c(rep(0, k), -1, 1)
  sqrt(drop(contrast %*% covariance %*% contrast))
}

findit_advanced_eval <- function(id, ...) {
  entries <- findit_entries()
  row <- entries[entries$id == id, , drop = FALSE]
  stopifnot(nrow(row) == 1L)
  eval(parse(text = row$r), list2env(list(...), parent = globalenv()))
}

test_that("Bayesian summaries report posterior uncertainty and MCSE explicitly", {
  skip_on_cran()
  skip_if_not_installed("posterior")
  skip_if_not_installed("coda")
  set.seed(917)
  draws <- getExportedValue("coda", "mcmc")(
    cbind(x = stats::rnorm(1000), z = stats::rgamma(1000, 2))
  )
  result <- findit_advanced_eval("ref-9bfbf80f25e5cd7e", draws = draws)
  expect_true(all(
    c("variable", "mean", "sd", "mcse", "median") %in% names(result)
  ))
  expect_equal(result$mean, c(mean(draws[, "x"]), mean(draws[, "z"])))
  expect_equal(
    result$`2.5%`,
    c(
      unname(stats::quantile(draws[, "x"], 0.025)),
      unname(stats::quantile(draws[, "z"], 0.025))
    )
  )
  expect_true(all(is.finite(result$mcse) & result$mcse > 0))
})

test_that("HPD summaries retain the selected parameter and summary statistics", {
  skip_on_cran()
  skip_if_not_installed("posterior")
  skip_if_not_installed("coda")
  set.seed(918)
  draws <- getExportedValue("coda", "mcmc")(
    cbind(x = stats::rgamma(1000, 2), z = stats::rnorm(1000))
  )
  result <- findit_advanced_eval("ref-8478098bfcf6c3e6", draws = draws)
  expect_identical(result$variable, "x")
  expect_equal(result$mean, mean(draws[, "x"]))
  expect_true(all(
    c("sd", "mcse", "median", "lower", "upper") %in% names(result)
  ))
  expect_lt(result$lower, result$upper)
  expect_lt(
    result$upper - result$lower,
    diff(stats::quantile(draws[, "x"], c(0.05, 0.95)))
  )
})

test_that("ESS summaries include correlation time and sampling efficiency", {
  skip_on_cran()
  skip_if_not_installed("coda")
  set.seed(920)
  draws <- getExportedValue("coda", "mcmc")(
    cbind(x = as.numeric(stats::arima.sim(list(ar = 0.8), n = 1000)))
  )
  result <- findit_advanced_eval("ref-8260e45b67b5cefc", draws = draws)
  expect_true(all(
    c("ess", "correlation_time", "efficiency") %in% names(result)
  ))
  expect_lt(result$ess, 1000)
  expect_equal(result$correlation_time * result$efficiency, 1)
  expect_equal(result$ess / result$efficiency, 1000)
})

test_that("transformed Bayesian summaries transform draws before averaging", {
  skip_on_cran()
  skip_if_not_installed("posterior")
  skip_if_not_installed("coda")
  set.seed(919)
  draws <- getExportedValue("coda", "mcmc")(cbind(x = stats::rnorm(1000)))
  result <- findit_advanced_eval("ref-842f8e7fd674bf12", draws = draws)
  expect_equal(result$mean, mean(exp(draws[, "x"])))
  expect_gt(result$mean, exp(mean(draws[, "x"])))
  expect_true(is.finite(result$mcse))
})

test_that("legacy margins standardize over the full covariate distribution", {
  skip_on_cran()
  skip_if_not_installed("marginaleffects")
  data <- data.frame(
    g = factor(rep(c("a", "b"), each = 5)),
    x = c(0:4, 10:14),
    noise = rep(c(1, -2, 2, -2, 1), 2)
  )
  data$y <- 1 + 2 * (data$g == "b") + 3 * data$x + data$noise
  fit <- stats::lm(y ~ g + x, data = data)
  result <- findit_advanced_eval("legacy-0299", fit = fit)
  expect_equal(result$estimate, c(22, 24), tolerance = 1e-8)
})

test_that("moving averages retain partial windows and exclude missing values", {
  skip_if_not_installed("zoo")
  y <- stats::ts(c(1, NA, 5, 7))
  centered <- findit_advanced_eval("ref-908b5fac4a37b64e", y = y)
  trailing <- findit_advanced_eval("ref-c8c11e9696fed69b", y = y)
  expect_equal(as.numeric(centered), c(3, 13 / 3, 13 / 3, 6))
  expect_equal(as.numeric(trailing), c(1, 1, 3, 13 / 3))
})

test_that("residual wntestq retains the stated chi-square degrees of freedom", {
  set.seed(921)
  fit <- stats::arima(stats::rnorm(100), order = c(1, 0, 0))
  result <- findit_advanced_eval("ref-78b116fdd30db59f", fit = fit)
  expect_equal(unname(result$parameter), 8)
})

test_that("survey coefficients of variation are percentages", {
  skip_on_cran()
  skip_if_not_installed("survey")
  des <- getExportedValue("survey", "svydesign")(
    ids = ~1,
    weights = ~w,
    data = data.frame(y = c(2, 4, 6, 8), w = 1)
  )
  result <- findit_advanced_eval("ref-2e4effb67e9bd27b", des = des)
  expect_equal(as.numeric(result), 100 * sqrt(5 / 3) / 5)
})

test_that("Freeman-Tukey meta effects use Stata's full-angle scale", {
  skip_on_cran()
  skip_if_not_installed("metafor")
  data <- data.frame(cases = c(1, 5), n = c(10, 20))
  result <- findit_advanced_eval("ref-49e4f770342070d7", data = data)
  expected <- asin(sqrt(data$cases / (data$n + 1))) +
    asin(sqrt((data$cases + 1) / (data$n + 1)))
  expect_equal(as.numeric(result$yi), expected)
  expect_equal(as.numeric(result$vi), 1 / (data$n + 0.5))
})

test_that("legacy mixed models use Stata's maximum-likelihood default", {
  skip_on_cran()
  skip_if_not_installed("lme4")
  data <- transform(
    getExportedValue("lme4", "sleepstudy"),
    y = Reaction,
    x = Days,
    id = Subject
  )
  fit <- findit_advanced_eval("legacy-0322", data = data)
  expect_false(getExportedValue("lme4", "isREML")(fit))
})

test_that("legacy Cox regressions use Breslow for tied failures", {
  skip_on_cran()
  skip_if_not_installed("survival")
  data <- data.frame(
    time = c(1, 1, 2, 2, 3, 4, 4, 5),
    died = c(1, 1, 1, 0, 1, 1, 0, 1),
    x1 = c(0, 2, 1, 3, 2, 1, 4, 3),
    x2 = c(1, 0, 2, 1, 3, 2, 0, 4)
  )
  fit <- findit_advanced_eval("legacy-0373", data = data)
  expect_identical(fit$method, "breslow")
})

test_that("hierarchical clustering preserves the original measurement scales", {
  data <- data.frame(x = c(0, 1, 10, 15), y = c(0, 100, 1, 150))
  data$z <- data$x
  data$w <- data$y
  fit <- findit_advanced_eval("ref-218e578162fe368f", data = data)
  expect_equal(fit$height[1], sqrt(202))
  expect_equal(fit$merge[1, ], c(-1L, -3L))
})

test_that("incomplete legacy statistical procedures are omitted", {
  entries <- findit_entries()
  expect_false(any(
    entries$id %in%
      c(
        "legacy-0318",
        "legacy-0345",
        "legacy-0346",
        "legacy-0372"
      )
  ))
})

test_that("survey designs nest reused PSU identifiers within strata", {
  skip_on_cran()
  skip_if_not_installed("survey")
  data <- data.frame(
    stratum = rep(1:3, each = 4),
    psu = rep(c(1, 1, 2, 2), 3),
    w = 1,
    N = 20
  )
  for (id in c("ref-f500ff6caf8a9389", "ref-10843c0679f9557a")) {
    design <- findit_advanced_eval(id, data = data)
    expect_equal(length(unique(design$cluster[, 1])), 6L)
  }
})

test_that("linear-combination hypotheses customize coefficient names", {
  skip_on_cran()
  skip_if_not_installed("marginaleffects")
  data <- transform(mtcars, outcome = mpg, income = wt, education = hp)
  fit <- stats::lm(outcome ~ income + education, data = data)
  ids <- c("ref-6772ad22a798fa0e", "ref-6b008bc7b61a0c6d")
  for (i in seq_along(ids)) {
    rendered <- findit_render(
      findit_templates()[[ids[i]]],
      c("income", "education")
    )
    expect_match(rendered$r, "income", fixed = TRUE)
    expect_match(rendered$r, "education", fixed = TRUE)
    result <- eval(parse(text = rendered$r))
    contrast <- c(0, 1, if (i == 1L) 1 else -1)
    expect_equal(as.numeric(result$estimate), sum(contrast * stats::coef(fit)))
    expect_equal(
      as.numeric(result$std.error),
      sqrt(drop(t(contrast) %*% stats::vcov(fit) %*% contrast))
    )
  }
})

test_that("categorical CEM explicitly disables Stata autocuts", {
  row <- findit_entries()
  row <- row[row$id == "ref-b18b9901ce3d1478", ]
  expect_match(row$stata, "category (#0)", fixed = TRUE)
})

test_that("IPW counterparts estimate treatment effects and joint uncertainty", {
  skip_on_cran()
  skip_if_not_installed("WeightIt")
  set.seed(922)
  data <- data.frame(x = stats::rnorm(180), z = stats::rnorm(180))
  data$treat <- stats::rbinom(
    180,
    1,
    stats::plogis(0.3 * data$x - 0.2 * data$z)
  )
  data$y <- 2 * data$treat + data$x + stats::rnorm(180)
  propensity <- stats::glm(treat ~ x + z, data = data, family = binomial())
  p <- stats::fitted(propensity)
  for (i in 1:2) {
    id <- c("ref-99100ebe369ff83b", "ref-e5280f9a9032ba70")[i]
    result <- findit_advanced_eval(id, data = data)
    w <- if (i == 1L) {
      ifelse(data$treat == 1, 1 / p, 1 / (1 - p))
    } else {
      ifelse(data$treat == 1, 1, p / (1 - p))
    }
    expected <- weighted.mean(data$y[data$treat == 1], w[data$treat == 1]) -
      weighted.mean(data$y[data$treat == 0], w[data$treat == 0])
    coefficients <- stats::coef(result)
    expect_equal(unname(coefficients["treat", 1]), expected, tolerance = 1e-8)
    expect_true(is.finite(coefficients["treat", 2]))
    expect_gt(coefficients["treat", 2], 0)
    expect_equal(
      unname(coefficients["treat", 2]),
      findit_advanced_ipw_se(data, c("ATE", "ATT")[i]),
      tolerance = 1e-8
    )
    expect_equal(
      unname(coefficients["treat", 2]),
      findit_advanced_ipw_se(data, c("ATE", "ATT")[i]),
      tolerance = 1e-8
    )
  }
})
