findit_audit_row <- function(id) {
  entries <- findit_entries()
  row <- entries[entries$id == id, , drop = FALSE]
  stopifnot(nrow(row) == 1L)
  row
}

findit_audit_eval <- function(id, data, ...) {
  skip_if_not_installed("tidyr")
  scope <- list2env(c(list(data = data), list(...)), parent = globalenv())
  scope$mutate <- dplyr::mutate
  scope$pivot_longer <- tidyr::pivot_longer
  scope$starts_with <- tidyselect::starts_with
  scope$bind_rows <- dplyr::bind_rows
  value <- eval(parse(text = findit_audit_row(id)$r), scope)
  list(value = value, data = scope$data)
}

test_that("Stata equality examples treat numeric missing as unequal", {
  data <- data.frame(x1 = c(1, NA, 1, 2), x2 = c(2, 2, NA, 2))
  expect_identical(
    findit_audit_eval("legacy-0113", data)$value$dummy,
    c(1L, 0L, 0L, 0L)
  )
  data <- data.frame(x = 1:4, g = c(1, NA, 1, 2))
  expect_identical(
    findit_audit_eval("ref-0617f386e6e060d6", data)$data$x,
    c(100, 2, 300, 4)
  )
})

test_that("group extrema keep all-missing groups missing without warnings", {
  data <- data.frame(x = c(NA_real_, NA, 4, 2), g = c(1, 1, 2, 2))
  data$group <- data$g
  ids <- c(
    "legacy-0154",
    "legacy-0155",
    "ref-1ef278cc1360e8d2",
    "ref-4d1ccdc8eb57d22b"
  )
  expected <- list(c(NA, NA, 4, 4), c(NA, NA, 2, 2), c(NA, 2), c(NA, 4))
  columns <- c("mx", "mn", "z", "z")
  for (i in seq_along(ids)) {
    expect_warning(result <- findit_audit_eval(ids[i], data), NA)
    expect_identical(result$value[[columns[i]]], expected[[i]])
  }
})

test_that("append and reshape retain Stata numeric index semantics", {
  data <- data.frame(id = 1:2, var2000 = 3:4, var2001 = 5:6)
  result <- findit_audit_eval("legacy-0217", data)$value
  expect_identical(sort(unique(result$year)), c(2000L, 2001L))
  result <- findit_audit_eval(
    "legacy-0215",
    data,
    data1 = data.frame(x = 1),
    data2 = data.frame(x = 2)
  )$value
  expect_identical(result$source, c(0L, 1L))
})

test_that("indicator generation preserves rows missing the category", {
  data <- data.frame(g = factor(c("a", NA, "b", "a")))
  result <- findit_audit_eval("ref-e409dafad5c4074b", data)$value
  expect_equal(nrow(result), 4L)
  expect_true(all(is.na(result[2L, ])))
  expect_equal(as.numeric(unlist(result[1L, ])), c(1, 0))
})

test_that("Johansen mappings describe actual deterministic model matrices", {
  skip_on_cran()
  skip_if_not_installed("urca")
  set.seed(219)
  Y <- apply(matrix(stats::rnorm(160), 80, 2), 2, cumsum)
  colnames(Y) <- c("y", "x")
  mappings <- c(
    "ref-fb4e9b8daaf9d321" = "rconstant",
    "ref-fb30ad57d9775ab7" = "constant",
    "ref-1cddadb1e6419399" = "rtrend"
  )
  for (id in names(mappings)) {
    row <- findit_audit_row(id)
    fit <- findit_audit_eval(id, data.frame(), Y = Y)$value
    expect_match(row$stata, paste0("trend(", mappings[[id]], ")"), fixed = TRUE)
    if (mappings[[id]] == "rconstant") {
      expect_true("constant" %in% colnames(fit@ZK))
      expect_false("constant" %in% colnames(fit@Z1))
    } else {
      expect_true("constant" %in% colnames(fit@Z1))
      expect_identical(
        "trend.l1" %in% colnames(fit@ZK),
        mappings[[id]] == "rtrend"
      )
    }
  }
})

test_that("mixed estimation uses maximum likelihood on new data", {
  skip_on_cran()
  skip_if_not_installed("lme4")
  # These model packages support optional reference examples, not lookup itself.
  fit <- findit_audit_eval(
    "ref-b660f497a340ebbe",
    transform(
      getExportedValue("lme4", "sleepstudy"),
      y = Reaction,
      x = Days,
      id = Subject
    )
  )$value
  expect_false(getExportedValue("lme4", "isREML")(fit))
  expect_equal(as.numeric(stats::logLik(fit)), -897.0393, tolerance = 1e-6)
})

test_that("Cox examples select Breslow for tied event times", {
  skip_on_cran()
  skip_if_not_installed("survival")
  data <- data.frame(
    time = c(1, 1, 2, 2, 3, 4, 4, 5),
    event = c(1, 1, 1, 0, 1, 1, 0, 1),
    x = c(0, 2, 1, 3, 2, 1, 4, 3),
    z = c(1, 0, 2, 1, 3, 2, 0, 4),
    group = rep(1:2, 4),
    id = rep(1:4, each = 2)
  )
  fit <- findit_audit_eval("ref-68d7ac4c045e9a2d", data)$value
  coxph <- getExportedValue("survival", "coxph")
  Surv <- getExportedValue("survival", "Surv")
  reference <- coxph(
    Surv(time, event) ~ x + z,
    data = data,
    cluster = id,
    ties = "breslow"
  )
  expect_identical(fit$method, "breslow")
  expect_equal(stats::coef(fit), stats::coef(reference))
})

test_that("ordered and imputation examples use valid explicit Stata options", {
  for (id in c("ref-4db4e340590ce0fa", "ref-1135e689d167643c")) {
    row <- findit_audit_row(id)
    expect_false(grepl(", re", row$stata, fixed = TRUE))
    expect_match(row$r, "nAGQ = 12", fixed = TRUE)
  }
  for (id in c("ref-dddfd3374c20231d", "ref-484a2ce965560010")) {
    expect_match(findit_audit_row(id)$stata, "pmm, knn(5)", fixed = TRUE)
  }
})

test_that("matching and PCSE select the stated replacement and covariance", {
  for (id in c(
    "ref-d771d8f68ffce120",
    "ref-bb84c8eaef72fa40",
    "ref-5be2caf7dd24047c"
  )) {
    expect_match(findit_audit_row(id)$r, "replace = TRUE", fixed = TRUE)
  }
  expect_match(
    findit_audit_row("ref-cdfe1eb8bf691f28")$r,
    'cluster = "time"',
    fixed = TRUE
  )
  expect_false(grepl(
    "transform(data",
    findit_audit_row("ref-4184d867c9dce07d")$r,
    fixed = TRUE
  ))
  expect_match(
    findit_audit_row("ref-4184d867c9dce07d")$r,
    "random = ~ x + z | id",
    fixed = TRUE
  )
})

test_that("meta mean-difference variances use the equal-variance model", {
  skip_on_cran()
  skip_if_not_installed("metafor")
  data <- data.frame(
    n1 = c(10, 15),
    m1 = c(5, 4),
    sd1 = c(2, 3),
    n0 = c(20, 25),
    m0 = c(2, 1),
    sd0 = c(4, 1)
  )
  result <- findit_audit_eval("ref-ff66d3c4c1fd45b5", data)$value
  pooled_variance <- ((data$n1 - 1) * data$sd1^2 + (data$n0 - 1) * data$sd0^2) /
    (data$n1 + data$n0 - 2)
  expect_equal(as.numeric(result$yi), c(3, 3))
  expect_equal(
    as.numeric(result$vi),
    pooled_variance * (1 / data$n1 + 1 / data$n0)
  )
})

test_that("meta set consumes standard errors without a fixture-only variance", {
  skip_on_cran()
  skip_if_not_installed("metafor")
  data <- data.frame(yi = c(0.2, -0.1, 0.6), sei = c(0.1, 0.2, 0.3))
  result <- findit_audit_eval("ref-0b4e9c21e56a3c3e", data)$value
  expect_equal(as.numeric(result$yi), data$yi)
  expect_equal(as.numeric(result$vi), c(0.01, 0.04, 0.09))
})

test_that("first-row indicators sort observations and retain missing groups", {
  data <- data.frame(
    id = c(2, 1, NA, 2, 1, NA),
    year = c(2002, 2001, 2002, 2001, 2000, 2000)
  )
  result <- findit_audit_eval("ref-3ee2da07ee573206", data)$value
  expect_identical(result$id, c(1, 1, 2, 2, NA, NA))
  expect_identical(result$year, c(2000, 2001, 2001, 2002, 2000, 2002))
  expect_identical(result$first, c(1L, 0L, 1L, 0L, 1L, 0L))
})

test_that("random-coefficient mappings fit every coefficient on new panel data", {
  skip_on_cran()
  skip_if_not_installed("nlme")
  set.seed(211)
  data <- expand.grid(time = 1:15, id = factor(1:20))
  data$x <- stats::rnorm(300)
  data$z <- stats::rnorm(300)
  slopes <- matrix(stats::rnorm(60), 20, 3)
  i <- as.integer(data$id)
  data$y <- 1 +
    slopes[i, 1] +
    (2 + slopes[i, 2]) * data$x +
    (1 + slopes[i, 3]) * data$z +
    stats::rnorm(300, sd = 0.4)
  fit <- findit_audit_eval("ref-4184d867c9dce07d", data)$value
  expect_identical(dim(stats::coef(fit)), c(20L, 3L))
  expect_identical(fit$data$y, data$y)
})

test_that("cluster reference degrees of freedom handle numeric groups", {
  skip_on_cran()
  skip_if_not_installed("sandwich")
  skip_if_not_installed("lmtest")
  data <- transform(mtcars, y = mpg, x = wt, z = hp, g = cyl)
  data$g[1L] <- NA
  data$x[2L] <- NA
  result <- findit_audit_eval("ref-e8224fa026780ab0", data)$value
  expect_identical(attr(result, "df"), 2L)
  expect_equal(
    unname(result[, 4]),
    2 * stats::pt(-abs(unname(result[, 3])), df = 2)
  )
})

test_that("discriminant priors use only classes in the analysis sample", {
  skip_on_cran()
  skip_if_not_installed("MASS")
  data <- transform(
    iris,
    x = Sepal.Length,
    y = Sepal.Width,
    z = Petal.Length,
    w = Petal.Width,
    g = Species
  )
  data$g[1L] <- NA
  fit <- findit_audit_eval("ref-4b33e1b5d96de617", data)$value
  expect_equal(unname(fit$prior), rep(1 / 3, 3))
  data$x[data$Species == "virginica"] <- NA
  fit <- findit_audit_eval("ref-4b33e1b5d96de617", data)$value
  expect_identical(fit$lev, c("setosa", "versicolor"))
  expect_equal(unname(fit$prior), c(0.5, 0.5))
})

test_that("multi-command Stata examples have default line-delimiter boundaries", {
  ids <- c(
    "ref-e1c643750656e4eb",
    "ref-33cc8179ec0b57f9",
    "ref-78b116fdd30db59f",
    "ref-528a9ec17d19d485",
    "ref-35598c46383b3503",
    "ref-94e1922bc712c2c6",
    "ref-cb46256750cceaaf"
  )
  for (id in ids) {
    stata <- findit_audit_row(id)$stata
    statements <- strsplit(stata, "\n", fixed = TRUE)[[1L]]
    expect_length(statements, 2L)
    expect_true(all(nzchar(statements)))
    expect_false(grepl(";", stata, fixed = TRUE))
  }
  expect_identical(
    strsplit(findit_audit_row("ref-94e1922bc712c2c6")$stata, "\n")[[1L]],
    c("var y x, lags(1)", "vargranger")
  )
})
