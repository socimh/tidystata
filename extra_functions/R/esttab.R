#' Directly obtain the regression results
#'
#' @description
#' `esttab()` works like the `esttab` command in Stata.
#' Given a model fit object (e.g. from `lm()` or `glm()`), `esttab()` returns a tibble of coefficients.
#'
#' @param model A model object.
#' @param digit A positive integer specifying the number of digits to be displayed.
#' @param format A character string specifying the format of the coefficients.
#' The default is `%.3f`, which means three decimal places.
#' It can also be a custom format string, e.g., `"{estimate}{star} ({std.error})"`.
#' @param stats A character vector of statistics to include (e.g., "n.obs", "r.squared", "adj.r.squared", "AIC", "BIC", "logLik").
#' Default is NULL (no statistics).
#'
#' @return Return the regression results as a list or a tibble.
#'
#' @export
#' @examples
#' lm(mpg ~ wt + hp, data = mtcars) %>%
#'   esttab()
#'
#' lm(mpg ~ wt + hp, data = mtcars) %>%
#'   esttab(format = "{estimate} (p={p.value})")
#'   
#' lm(mpg ~ wt + hp, data = mtcars) %>%
#'   esttab(stats = c("n.obs", "r.squared"))
esttab <- function(
    model,
    digit = integer(0),
    format = "%.3f",
    stats = NULL) {
  broom_works <- s_try(broom::tidy(model))
  broom_mixed_works <- s_try(broom.mixed::tidy(model))

  if (broom_works) {
    out <- broom::tidy(model)
  } else if (broom_mixed_works) {
    out <- broom.mixed::tidy(model)
  } else {
    stop("tidy() does not work for the model.", call. = FALSE)
  }

  if (!"p.value" %in% names(out)) {
    if ("statistic" %in% names(out)) {
      nobs <- tryCatch(
        broom.mixed::glance(model)$df.residual,
        error = function(e) NA_real_
      )
      if (is.null(nobs) || is.na(nobs)) {
         # Fallback if df is not available: use normal approximation
         # This is common for lmer models where df is tricky
         out <- out %>%
           dplyr::mutate(
             p.value = 2 * (1 - pnorm(abs(statistic)))
           )
      } else {
         out <- out %>%
           dplyr::mutate(
             p.value = 2 * pt(q = abs(statistic), df = nobs, lower.tail = FALSE)
           )
      }
    } else {
      out$p.value <- NA_real_
    }
  }

  if (length(digit) > 1) {
    stop("The digit should be a positive integer.")
  } else if (length(digit) == 1) {
    digit <- as.integer(digit)
    num_fmt <- stringr::str_glue(
      "%.{digit}f"
    )
  } else {
    # Default format for numbers if digit is not specified but format is simple
    if (stringr::str_detect(format, "^%")) {
      num_fmt <- format
    } else {
      num_fmt <- "%.3f"
    }
  }

  # If format is a simple C-style format string (starts with %), assume standard output
  # Otherwise, assume it's a glue string
  if (stringr::str_detect(format, "^%")) {
     format_str <- "{estimate_fmt}{star}\n({std.error_fmt})"
  } else {
     # Replace user-friendly placeholders with internal fmt column names
     format_str <- format %>%
       stringr::str_replace_all("\\{estimate\\}", "{estimate_fmt}") %>%
       stringr::str_replace_all("\\{std.error\\}", "{std.error_fmt}") %>%
       stringr::str_replace_all("\\{statistic\\}", "{statistic_fmt}") %>%
       stringr::str_replace_all("\\{p.value\\}", "{p.value_fmt}")
  }

  out <- out %>%
    dplyr::mutate(
      star = dplyr::case_when(
        p.value < 0.001 ~ "***",
        p.value < 0.01 ~ "**",
        p.value < 0.05 ~ "*",
        p.value < 0.1 ~ "+",
        TRUE ~ ""
      )
    )
    
  # Create formatted columns for glue
  # We use explicit columns to avoid issues with missing columns in `out`
  # e.g., if std.error is missing
  
  if (!"std.error" %in% names(out)) out$std.error <- NA_real_
  if (!"statistic" %in% names(out)) out$statistic <- NA_real_
  if (!"p.value" %in% names(out)) out$p.value <- NA_real_

  out <- out %>%
    dplyr::mutate(
      estimate_fmt = sprintf(num_fmt, estimate),
      std.error_fmt = ifelse(is.na(std.error), "", sprintf(num_fmt, std.error)),
      statistic_fmt = ifelse(is.na(statistic), "", sprintf(num_fmt, statistic)),
      p.value_fmt = ifelse(is.na(p.value), "", sprintf(num_fmt, p.value)),
      
      coef = stringr::str_glue(format_str)
    ) %>%
    dplyr::select(-ends_with("_fmt")) %>%
    dplyr::relocate(coef, .after = term) %>%
    # Select only essential columns by default: term, coef, star (if part of coef, maybe keep separate for programmatic use?)
    # User requested: "only term, coef, and other essential model settings"
    # We should keep 'term' and 'coef'. 'star' is often useful to keep separate if someone wants to filter.
    # But raw estimate, std.error, statistic, p.value should be hidden as they are now in 'coef'.
    # However, 'effect' and 'group' are essential for mixed models.
    dplyr::select(any_of(c("term", "coef", "star", "effect", "group")))

  if (!is.null(stats)) {
    glance_out <- tryCatch({
      if (broom_works) {
        broom::glance(model)
      } else if (broom_mixed_works) {
        broom.mixed::glance(model)
      } else {
        NULL
      }
    }, error = function(e) NULL)

    if (!is.null(glance_out)) {
      # Standardize common statistic names to match user expectations (Stata-like)
      # broom usually returns 'nobs', 'r.squared', 'adj.r.squared', 'AIC', 'BIC', 'logLik'
      
      # We map user-requested stats to broom names
      stat_map <- c(
        "N" = "nobs",
        "n.obs" = "nobs",
        "r2" = "r.squared",
        "r.squared" = "r.squared",
        "ar2" = "adj.r.squared",
        "adj.r.squared" = "adj.r.squared",
        "aic" = "AIC",
        "AIC" = "AIC",
        "bic" = "BIC",
        "BIC" = "BIC",
        "ll" = "logLik",
        "logLik" = "logLik"
      )
      
      # Filter stats that are present in glance_out
      requested_stats <- stats
      found_stats <- list()
      found_vals <- character(0)
      found_names <- character(0)
      
      for (s in requested_stats) {
        broom_name <- stat_map[s]
        if (is.na(broom_name)) broom_name <- s # Try direct name if not in map
        
        if (broom_name %in% names(glance_out)) {
          val <- glance_out[[broom_name]]
          # Format based on type
          if (is.numeric(val)) {
             # N should be integer format if it looks like an integer
             if (broom_name == "nobs") {
               val_fmt <- sprintf("%.0f", val)
             } else {
               val_fmt <- sprintf(num_fmt, val)
             }
          } else {
             val_fmt <- as.character(val)
          }
          found_names <- c(found_names, s)
          found_vals <- c(found_vals, val_fmt)
        }
      }
      
      if (length(found_vals) > 0) {
        stats_df <- dplyr::tibble(
          term = found_names,
          coef = found_vals,
          star = ""
        )
        
        # Bind to the main output
        # Ensure columns match
        out <- dplyr::bind_rows(out, stats_df)
      }
    }
  }

  return(out)
}
