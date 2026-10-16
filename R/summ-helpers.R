extract_group_var <- function(.data, by) {
  any_dot_by <- !rlang::quo_is_null(by)
  any_group_by <- dplyr::is_grouped_df(.data)

  if (!any_dot_by && any_group_by) {
    group_vars <- dplyr::group_vars(.data)
  } else if (any_dot_by) {
    group_vars <- ds(.data, !!by)
  } else {
    group_vars <- character(0)
  }

  if (!contain_vars(.data, group_vars)) {
    stop("The data do not include all grouping variable(s).")
  }

  return(group_vars)
}

contain_vars <- function(.data, group_vars) {
  contain <- .data %>%
    dplyr::ungroup() %>%
    dplyr::select(
      tidyselect::all_of(group_vars)
    ) %>%
    s_try()
  return(contain)
}

remove_group_vars <- function(.data, ..., group_vars) {
  if (!missing(...)) {
    .data <- s_select(.data, ...)
  }
  out <- .data %>%
    dplyr::ungroup() %>%
    dplyr::select(
      -tidyselect::any_of(group_vars)
    ) %>%
    # Suppress "adding missing grouping variables" message
    suppressMessages()
  return(out)
}

keep_useful_vars <- function(.data, .data_num, group_vars) {
  out <- .data %>%
    dplyr::ungroup() %>%
    dplyr::select(
      tidyselect::all_of(group_vars)
    ) %>%
    dplyr::bind_cols(.data_num)

  return(out)
}

is_summable_chr <- function(chr) {
  chr %>%
    stringr::str_detect(
      "^(lgl|int|dbl|int64|units|drtn|time|date|dttm|fct|ord)"
    )
}

is_summable <- function(.x) {
  s_type(.x, .abbr = TRUE) %>%
    is_summable_chr()
}

check_summarise <- function(.data) {
  out <- .data %>%
    dplyr::select(tidyselect::where(
      ~ is_summable(.x)
    ))
  summ_vars <- names(out)

  if (length(summ_vars) == 0) {
    stop(
      "None of the provided variable(s) is suitable for `summ()`.",
      call. = FALSE
    )
  } else {
    return(out)
  }
}

warning_vars <- function(vars, suffix) {
  if (length(vars) == 0) {
    return()
  } else if (length(vars) == 1) {
    message <- paste0(vars, " is ", suffix)
    warning(message, call. = FALSE)
  } else if (
    stringr::str_length(vars[1]) +
      stringr::str_length(vars[2]) > 40) {
    message <- paste0(
      vars[1], ", ... are ", suffix
    )
    warning(message, call. = FALSE)
  } else if (length(vars) > 2) {
    message <- paste(vars[1:2], collapse = ", ") %>%
      paste0(", ... are ", suffix)
    warning(message, call. = FALSE)
  } else {
    message <- paste(vars, collapse = " and ") %>%
      paste0(" are ", suffix)
    warning(message, call. = FALSE)
  }
}

check_numeric <- function(.data, .keep_all) {
  # Check if vars are numeric
  non_num_vars <- .data %>%
    ds(!tidyselect::where(
      ~ is_summable(.x)
    ))

  suffix <- dplyr::if_else(
    .keep_all,
    "non-numeric (***).",
    "non-numeric and thus removed."
  )
  warning_vars(non_num_vars, suffix)
}

check_missing <- function(.data, .keep_all) {
  na_vars <- .data %>%
    ds(tidyselect::where(
      ~ is_summable(.x) && length(.x) > 0L && all(is.na(.x))
    ))

  suffix <- dplyr::if_else(
    .keep_all,
    "entirely missing.",
    "entirely missing; retained with n = 0."
  )
  warning_vars(na_vars, suffix)
}

check_factor <- function(.data) {
  fct_vars <- .data %>%
    ds(tidyselect::where(
      ~ s_type(.x, .abbr = TRUE) %in% c("fct", "ord")
    ))

  suffix <- dplyr::if_else(
    length(fct_vars) == 1,
    "a factor (**).",
    "factors (**)."
  )
  warning_vars(fct_vars, suffix)
}

check_label <- function(.data) {
  lbl_vars <- .data %>%
    ds(tidyselect::where(
      ~ s_type(.x, .abbr = TRUE) %>%
        stringr::str_detect("lbl$")
    ))

  suffix <- dplyr::if_else(
    length(lbl_vars) == 1,
    "a labelled variable (*).",
    "labelled variables (*)."
  )
  warning_vars(lbl_vars, suffix)
}

summ_stat_names <- function(stat) {
  if (length(stat) == 0L) return(stats::setNames(character(), character()))
  if (!is.character(stat) || anyNA(stat) || any(!nzchar(stat))) {
    stop("`.stat` must be a character vector of non-missing statistic names.", call. = FALSE)
  }
  aliases <- c(missing = "miss_n", p25 = "q1", p50 = "median", p75 = "q3")
  supported <- c("type", "n", "unique", "miss_n", "valid_pct", "min", "q1",
                 "median", "mean", "mad", "sd", "q3", "max", "iqr", "skew",
                 "kurtosis", "se", "sum", names(aliases))
  unknown <- setdiff(stat, supported)
  if (length(unknown)) {
    stop("Unsupported statistic: ", paste(unknown, collapse = ", "),
         ". See ?summ for supported names.", call. = FALSE)
  }
  stat <- unique(stat)
  mapped <- stat
  selected <- stat %in% names(aliases)
  mapped[selected] <- unname(aliases[stat[selected]])
  stats::setNames(mapped, stat)
}

select_summ_stats <- function(data, stat) {
  mapped <- summ_stat_names(stat)
  unavailable <- setdiff(unname(mapped), names(data))
  if (length(unavailable)) {
    stop("Unsupported statistic for this variable type: ",
         paste(unavailable, collapse = ", "), call. = FALSE)
  }
  dplyr::select(data, type, tidyselect::all_of(mapped))
}

summ_var <- function(var, stat = character(0), .detail = FALSE) {
  num_var <- as_numeric(var)
  n_val <- sum(!is.na(var))
  observed <- num_var[!is.na(num_var)]
  has_values <- length(observed) > 0L
  type_str <- if (!is.na(s_unit(var))) {
    paste0(s_type(var, .abbr = TRUE), " [", s_unit(var), "]")
  } else {
    s_type(var, .abbr = TRUE)
  }
  stat_tb <- tibble::tibble(
    type = type_str,
    n = n_val,
    unique = dplyr::n_distinct(var, na.rm = TRUE),
    min = if (has_values) min(observed) else NA_real_,
    mean = if (has_values) mean(observed) else NA_real_,
    sd = if (has_values) stats::sd(observed) else NA_real_,
    max = if (has_values) max(observed) else NA_real_
  )
  if (.detail || length(stat)) {
    stat_tb$miss_n <- length(var) - n_val
    stat_tb$valid_pct <- if (length(var)) n_val / length(var) else NA_real_
    stat_tb$q1 <- if (has_values) unname(stats::quantile(observed, .25)) else NA_real_
    stat_tb$median <- if (has_values) stats::median(observed) else NA_real_
    stat_tb$mad <- if (has_values) stats::mad(observed) else NA_real_
    stat_tb$q3 <- if (has_values) unname(stats::quantile(observed, .75)) else NA_real_
    stat_tb$iqr <- if (has_values) stats::IQR(observed) else NA_real_
    stat_tb$skew <- if (has_values) skew(num_var, n_val) else NA_real_
    stat_tb$kurtosis <- if (has_values) kurtosis(num_var, n_val) else NA_real_
    stat_tb$se <- if (n_val) stat_tb$sd / sqrt(n_val) else NA_real_
    stat_tb$sum <- if (has_values) sum(observed) else NA_real_
    stat_tb <- dplyr::select(stat_tb, tidyselect::all_of(c(
      "type", "n", "unique", "miss_n", "valid_pct", "min", "q1", "median",
      "mean", "mad", "sd", "q3", "max", "iqr", "skew", "kurtosis", "se", "sum"
    )))
  }
  if (length(stat)) stat_tb <- select_summ_stats(stat_tb, stat)
  stat_tb
}

fmt_date <- function(x, var) {
  # Format a numeric date/datetime value back to a readable string
  vtype <- s_type(var, .abbr = TRUE)
  if (is.na(x) || !is.finite(x)) return(NA_character_)
  if (vtype == "date") {
    format(as.Date(x, origin = "1970-01-01"), "%Y-%m-%d")
  } else {
    format(as.POSIXct(x, origin = "1970-01-01", tz = "UTC"), "%Y-%m-%d %H:%M")
  }
}

fmt_duration <- function(secs, format = "compact") {
  # Format duration in seconds as human-readable string
  if (is.na(secs) || !is.finite(secs)) return(NA_character_)
  
  if (format == "long") {
    # Long format: "548 days", "2 hours 15 minutes", "30 seconds"
    if (secs >= 86400) {
      days <- round(secs / 86400)
      if (days == 1) return("1 day")
      else return(paste(days, "days"))
    } else if (secs >= 3600) {
      hours <- floor(secs / 3600)
      mins <- round((secs %% 3600) / 60)
      if (mins == 0) {
        if (hours == 1) return("1 hour")
        else return(paste(hours, "hours"))
      } else {
        return(paste(hours, "hours", mins, "minutes"))
      }
    } else if (secs >= 60) {
      mins <- floor(secs / 60)
      secs_rem <- round(secs %% 60)
      if (secs_rem == 0) {
        if (mins == 1) return("1 minute")
        else return(paste(mins, "minutes"))
      } else {
        return(paste(mins, "minutes", secs_rem, "seconds"))
      }
    } else {
      secs_round <- round(secs)
      if (secs_round == 1) return("1 second")
      else return(paste(secs_round, "seconds"))
    }
  } else {
    # Compact format: "548d", "2h 15m", "30s"
    if (secs >= 86400) sprintf("%.1fd", secs / 86400)
    else if (secs >= 3600) sprintf("%.1fh", secs / 3600)
    else if (secs >= 60) sprintf("%.1fm", secs / 60)
    else sprintf("%ds", secs)
  }
}

fmt_date_sd <- function(sd_secs, var, format = "compact") {
  # Format sd (in seconds for datetime, in days for date) as a human-readable span
  if (is.na(sd_secs) || !is.finite(sd_secs)) return(NA_character_)
  vtype <- s_type(var, .abbr = TRUE)
  if (vtype == "date") {
    # For dates, sd_secs is in days
    days <- round(sd_secs)
    if (format == "long") {
      if (days == 1) return("1 day")
      else return(paste(days, "days"))
    } else {
      sprintf("%dd", days)
    }
  } else {
    # For datetime, sd_secs is in seconds
    fmt_duration(sd_secs, format)
  }
}

summ_date <- function(var, stat = character(0), .detail = FALSE, 
                        .duration_format = "compact", return_raw = FALSE) {
  if ("sum" %in% stat) stop("`sum` is not supported for date/datetime variables.", call. = FALSE)
  n_val    <- sum(!is.na(var), na.rm = TRUE)
  miss_val <- sum(is.na(var), na.rm = TRUE)
  num_var  <- as_numeric(var)

  observed <- num_var[!is.na(num_var)]
  has_values <- length(observed) > 0L
  min_raw <- if (has_values) min(observed) else NA_real_
  median_raw <- if (has_values) median(observed) else NA_real_
  q1_raw <- if (has_values) unname(quantile(observed, .25)) else NA_real_
  q3_raw <- if (has_values) unname(quantile(observed, .75)) else NA_real_
  mean_raw <- if (has_values) mean(observed) else NA_real_
  sd_raw <- if (has_values) sd(observed) else NA_real_
  max_raw <- if (has_values) max(observed) else NA_real_
  iqr_raw <- if (has_values) IQR(observed) else NA_real_
  mad_raw <- if (has_values) mad(observed) else NA_real_

  vtype <- s_type(var, .abbr = TRUE)
  
  if (return_raw) {
    # Return actual Date/POSIXct types for list mode
    if (vtype == "date") {
      stat_tb <- tibble::tibble(
        type      = dplyr::if_else(
          !is.na(s_unit(var)),
          stringr::str_glue("[{s_unit(var)}]"),
          "date"
        ) %>% as.character(),
        n         = n_val,
        unique    = dplyr::n_distinct(var, na.rm = TRUE),
        miss_n    = miss_val,
        valid_pct = if (length(var)) n_val / length(var) else NA_real_,
        min       = as.Date(min_raw, origin = "1970-01-01"),
        mean      = as.Date(round(mean_raw), origin = "1970-01-01"),
        max       = as.Date(max_raw, origin = "1970-01-01"),
        sd        = fmt_date_sd(sd_raw, var, .duration_format),
        mad       = fmt_date_sd(mad_raw, var, .duration_format),
        iqr       = fmt_date_sd(iqr_raw, var, .duration_format),
        se        = fmt_date_sd(sd_raw / sqrt(n_val), var, .duration_format)
      )
    } else {
      stat_tb <- tibble::tibble(
        type      = dplyr::if_else(
          !is.na(s_unit(var)),
          stringr::str_glue("[{s_unit(var)}]"),
          "datetime"
        ) %>% as.character(),
        n         = n_val,
        unique    = dplyr::n_distinct(var, na.rm = TRUE),
        miss_n    = miss_val,
        valid_pct = if (length(var)) n_val / length(var) else NA_real_,
        min       = as.POSIXct(min_raw, origin = "1970-01-01", tz = "UTC"),
        mean      = as.POSIXct(round(mean_raw), origin = "1970-01-01", tz = "UTC"),
        max       = as.POSIXct(max_raw, origin = "1970-01-01", tz = "UTC"),
        sd        = fmt_date_sd(sd_raw, var, .duration_format),
        mad       = fmt_date_sd(mad_raw, var, .duration_format),
        iqr       = fmt_date_sd(iqr_raw, var, .duration_format),
        se        = fmt_date_sd(sd_raw / sqrt(n_val), var, .duration_format)
      )
    }
  } else {
    # Return formatted strings for table mode
    stat_tb <- tibble::tibble(
      type      = dplyr::if_else(
        !is.na(s_unit(var)),
        stringr::str_glue("[{s_unit(var)}]"),
        s_type(var, .abbr = TRUE)
      ) %>% as.character(),
      n         = n_val,
      unique    = dplyr::n_distinct(var, na.rm = TRUE),
      miss_n    = miss_val,
      valid_pct = if (length(var)) n_val / length(var) else NA_real_,
      min       = fmt_date(min_raw, var),
      q1        = fmt_date(q1_raw, var),
      median    = fmt_date(median_raw, var),
      q3        = fmt_date(q3_raw, var),
      mean      = fmt_date(mean_raw, var),
      sd        = fmt_date_sd(sd_raw, var, .duration_format),
      mad       = fmt_date_sd(mad_raw, var, .duration_format),
      max       = fmt_date(max_raw, var),
      iqr       = fmt_date_sd(iqr_raw, var, .duration_format),
      se        = fmt_date_sd(sd_raw / sqrt(n_val), var, .duration_format)
    )
  }
  
  if (length(stat) > 0) {
    stat_tb <- select_summ_stats(stat_tb, stat)
  } else if (!.detail) {
    stat_tb <- stat_tb %>%
      dplyr::select(type, n, unique, mean, sd, min, max)
  }
  return(stat_tb)
}

summ_data <- function(.data, .fn, summ_vars, group_vars, .detail, .stat, 
                       .duration_format = "compact", return_raw = FALSE) {
  if (length(summ_vars) > 0) {
    # Create a wrapper function that passes the extra arguments
    fn_wrapper <- function(x) {
      if (identical(.fn, summ_date)) {
        .fn(x, .stat, .detail, .duration_format, return_raw)
      } else {
        .fn(x, .stat, .detail)
      }
    }
    
    out <- .data %>%
      dplyr::summarise(
        dplyr::across(
          tidyselect::all_of(summ_vars),
          ~ fn_wrapper(.x)
        ),
        .by = tidyselect::all_of(group_vars)
      ) %>%
      suppressWarnings() %>%
      tidyr::pivot_longer(
        !tidyselect::all_of(group_vars)
      ) %>%
      tidyr::unnest(value)
  } else {
    out <- NULL
  }
  return(out)
}

summ_list <- function(.data, group_vars, .detail, .stat, 
                        .mode = c("list", "table"),
                        .duration_format = c("compact", "long")) {
  .mode <- match.arg(.mode)
  .duration_format <- match.arg(.duration_format)
  
  numeric <- .data %>%
    ds(
      !tidyselect::all_of(group_vars) &
        !tidyselect::where(
          ~ s_type(.x) %in% c("date", "datetime")
        )
    )

  date <- .data %>%
    ds(
      !tidyselect::all_of(group_vars) &
        tidyselect::where(
          ~ s_type(.x) %in% c("date")
        )
    )

  datetime <- .data %>%
    ds(
      !tidyselect::all_of(group_vars) &
        tidyselect::where(
          ~ s_type(.x) %in% c("datetime")
        )
    )


  numeric <- summ_data(
    .data, summ_var, numeric, group_vars, .detail, .stat
  )

  if (!is.null(numeric) && nrow(numeric) > 0) {
    numeric <- numeric %>%
      dplyr::mutate(
        name = dplyr::case_when(
          !is_summable_chr(type) ~
            stringr::str_glue("***{name}"),
          type %in% c("fct", "ord") ~
            stringr::str_glue("**{name}"),
          stringr::str_detect(type, "lbl$") ~
            stringr::str_glue("*{name}"),
          TRUE ~ name
        ) %>% as.character()
      )
  }

  date <- summ_data(
    .data, summ_date, date, group_vars, .detail, .stat, .duration_format
  )

  datetime <- summ_data(
    .data, summ_date, datetime, group_vars, .detail, .stat, .duration_format
  )

  out <- list(
    numeric = numeric,
    date = date,
    datetime = datetime
  ) %>%
    purrr::discard(~ is.null(.))

  if (.mode == "table") {
    if (length(out) > 0) {
      # Calendar summaries format locations and spreads as text. Use the same
      # representation for shared statistic columns when stacking numeric rows.
      text_stats <- unique(unlist(lapply(out, function(data) {
        names(data)[vapply(data, is.character, logical(1))]
      })))
      text_stats <- setdiff(text_stats, c(group_vars, "name", "type"))
      out <- lapply(out, function(data) {
        for (stat in intersect(text_stats, names(data))) {
          data[[stat]] <- as.character(data[[stat]])
        }
        data
      })
      out <- dplyr::bind_rows(out)
    }
  } else if (length(out) == 1) {
    out <- out[[1]]
  } else {
    message(
      "A list is returned as statistics are heterogeneous.",
      call. = FALSE
    )
  }

  return(out)
}
