#' Directly obtain the regression results
#'
#' @description
#' These functions are wrappers for the `broom` package to directly obtain the regression results.
#' The naming convention is `regress_*` for raw formula and `tidy_*` for the model object.
#'
#' * `regress()` returns the regression results as a list.
#' * `regress_coef()` returns the coefficients.
#' * `regress_stat()` returns the model statistics.
#' * `regress_data()` returns the augmented data.
#'
#' @param .data A data frame, data frame extension
#' (e.g. a tibble), or a lazy data frame (e.g. from dbplyr or dtplyr).
#' @param formula A formula specifying the model.
#' @param model A character string specifying the model to be used.
#' @param digit A positive integer specifying the number of digits to be displayed.
#' @param format A character string specifying the format of the coefficients.
#' The default is `%.3f`, which means three decimal places.
#'
#' @return Return the regression results as a list or a tibble.
#'
#' @seealso [etable()]
#'
#' @name regress
#' @examples
#' regress(mtcars, mpg ~ wt + hp)
#' regress_coef(mtcars, mpg ~ wt + hp)
#' 
#' mtcars %>%
#'   dplyr::mutate(mpg20 = mpg > 20) %>%
#'   regress(mpg20 ~ wt + hp, model = "logit")

#' @rdname regress
#' @export
regress <- function(
    .data,
    formula,
    model = "lm",
    digit = integer(0),
    format = "%.3f") {
  coef <- tryCatch(
    {
      regress_coef(.data, formula, model, digit, format)
    },
    error = function(e) {
      NULL
    }
  )
  stat <- tryCatch(
    {
      regress_stat(.data, formula, model)
    },
    error = function(e) {
      NULL
    }
  )
  data <- tryCatch(
    {
      regress_data(.data, formula, model)
    },
    error = function(e) {
      NULL
    }
  )

  out <- list(
    coef = coef,
    stat = stat,
    data = data
  ) %>%
    purrr::discard(~ is.null(.))

  if (length(out) == 1) {
    out <- out[[1]]
  }

  return(out)
}

#' @rdname regress
#' @export
regress_coef <- function(
    .data,
    formula,
    model = "lm",
    digit = integer(0),
    format = "%.3f") {
  formula <- check_formula(formula) |>
    as.formula()

  if (model == "lm") {
    out <- lm(formula, data = .data) %>%
      broom::tidy()
  } else if (model %in% c("logit", "glm")) {
    out <- glm(formula, data = .data, family = binomial(link = "logit")) %>%
      broom::tidy()
  } else if (model == "probit") {
    out <- glm(formula, data = .data, family = binomial(link = "probit")) %>%
      broom::tidy()
  } else if (model == "gamma") {
    out <- glm(formula, data = .data, family = Gamma(link = "inverse")) %>%
      broom::tidy()
  } else if (model == "poisson") {
    out <- glm(formula, data = .data, family = poisson(link = "log")) %>%
      broom::tidy()
  } else if (model %in% c("ologit", "clm")) {
    out <- ordinal::clm(formula, data = .data) %>%
      broom::tidy()
  } else if (model == "oprobit") {
    out <- ordinal::clm(formula, data = .data, link = "probit") %>%
      broom::tidy()
  } else if (model %in% c("mlogit", "multinom")) {
    out <- nnet::multinom(formula, data = .data) %>%
      broom::tidy()
  } else if (model %in% c("hlm", "multilevel", "mixed", "lme4", "lmer")) {
    mod <- lme4::lmer(formula, data = .data)
    df <- broom.mixed::glance(mod) %>%
      dplyr::pull(df.residual)
    out <- broom.mixed::tidy(mod) %>%
      dplyr::mutate(
        p.value = 2 * pt(q = statistic, df = df, lower.tail = FALSE)
      )
  } else {
    stop("Invalid model")
  }

  if (length(digit) > 1) {
    stop("The digit should be a positive integer.")
  } else if (length(digit) == 1) {
    digit <- as.integer(digit)
    format <- stringr::str_glue(
      "%.{digit}f"
    )
  }

  out <- out %>%
    dplyr::mutate(
      star = dplyr::case_when(
        p.value < 0.001 ~ "***",
        p.value < 0.01 ~ "**",
        p.value < 0.05 ~ "*",
        p.value < 0.1 ~ "+",
        TRUE ~ ""
      ),
      coef = sprintf(format, estimate),
      coef = ifelse(
        is.na(std.error), coef,
        stringr::str_glue(
          "{coef}{star}\n({se})",
          se = sprintf(format, std.error)
        )
      )
    ) %>%
    dplyr::relocate(coef, .after = term)

  return(out)
}

#' @rdname regress
#' @export
regress_stat <- function(
    .data,
    formula,
    model = "lm") {
  formula <- check_formula(formula) |>
    as.formula()

  if (model == "lm") {
    out <- lm(formula, data = .data) %>%
      broom::glance()
  } else if (model %in% c("logit", "glm")) {
    out <- glm(formula, data = .data, family = binomial(link = "logit")) %>%
      broom::glance()
  } else if (model == "probit") {
    out <- glm(formula, data = .data, family = binomial(link = "probit")) %>%
      broom::glance()
  } else if (model == "gamma") {
    out <- glm(formula, data = .data, family = Gamma(link = "inverse")) %>%
      broom::glance()
  } else if (model == "poisson") {
    out <- glm(formula, data = .data, family = poisson(link = "log")) %>%
      broom::glance()
  } else if (model %in% c("ologit", "clm")) {
    out <- ordinal::clm(formula, data = .data) %>%
      broom::glance()
  } else if (model == "oprobit") {
    out <- ordinal::clm(formula, data = .data, link = "probit") %>%
      broom::glance()
  } else if (model %in% c("mlogit", "multinom")) {
    out <- nnet::multinom(formula, data = .data) %>%
      broom::glance()
  } else if (model %in% c("hlm", "multilevel", "mixed", "lme4", "lmer")) {
    out <- lme4::lmer(formula, data = .data) %>%
      broom.mixed::glance()
  } else {
    stop("Invalid model")
  }

  return(out)
}

#' @rdname regress
#' @export
regress_data <- function(
    .data,
    formula,
    model = "lm") {
  formula <- check_formula(formula) |>
    as.formula()

  if (model == "lm") {
    out <- lm(formula, data = .data) %>%
      broom::augment()
  } else if (model %in% c("logit", "glm")) {
    out <- glm(formula, data = .data, family = binomial(link = "logit")) %>%
      broom::augment()
  } else if (model == "probit") {
    out <- glm(formula, data = .data, family = binomial(link = "probit")) %>%
      broom::augment()
  } else if (model == "gamma") {
    out <- glm(formula, data = .data, family = Gamma(link = "inverse")) %>%
      broom::augment()
  } else if (model == "poisson") {
    out <- glm(formula, data = .data, family = poisson(link = "log")) %>%
      broom::augment()
  } else if (model %in% c("ologit", "clm")) {
    out <- ordinal::clm(formula, data = .data) %>%
      broom::augment()
  } else if (model == "oprobit") {
    out <- ordinal::clm(formula, data = .data, link = "probit") %>%
      broom::augment()
  } else if (model %in% c("mlogit", "multinom")) {
    out <- nnet::multinom(formula, data = .data) %>%
      broom::augment()
  } else if (model %in% c("hlm", "multilevel", "mixed", "lme4", "lmer")) {
    out <- lme4::lmer(formula, data = .data) %>%
      broom.mixed::augment()
  } else {
    stop("Invalid model")
  }

  return(out)
}


# Helper functions
check_formula <- function(formula) {
  if (
    !purrr::is_formula(formula) && !purrr::is_character(formula)
  ) {
    stop("Invalid formula")
  } else if (purrr::is_character(formula)) {
    formula <- as.formula(formula)
  }
  return(formula)
}
