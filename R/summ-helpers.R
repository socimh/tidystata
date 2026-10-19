extract_group_var <- function(.data, by) {
  any_dot_by <- !rlang::quo_is_null(by)
  any_group_by <- dplyr::is_grouped_df(.data)

  if (!any_dot_by && any_group_by) {
    group_vars <- dplyr::group_vars(.data)
  } else if (any_dot_by) {
    check_by_selection(.data, by)
    group_vars <- ds(.data, !!by)
  } else {
    group_vars <- character(0)
  }

  if (!contain_vars(.data, group_vars)) {
    stop("The data do not include all grouping variable(s).")
  }

  return(group_vars)
}

# `.by` selects columns; a computed expression would otherwise fail with a
# misleading "object not found" error from tidyselect.
check_by_selection <- function(.data, by) {
  expr <- rlang::quo_get_expr(by)
  if (select_expr_is_selection(expr, names(.data))) {
    return(invisible())
  }
  stop(
    "`.by` must select existing columns, not compute `",
    rlang::as_label(expr),
    "`.\nℹ Create the grouping column first, e.g. ",
    "`mutate(group = ",
    rlang::as_label(expr),
    ")`, then use `.by = group`.",
    call. = FALSE
  )
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
    check_group_selection(.data, ..., group_vars = group_vars)
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

# A grouping key selected under another name would be summarised as data.
check_group_selection <- function(.data, ..., group_vars) {
  if (!length(group_vars)) {
    return(invisible())
  }
  data <- dplyr::ungroup(.data)
  dots <- rlang::enquos(...)
  dots <- dots[select_is_selection(dots, names(data))]
  selected <- tryCatch(
    tidyselect::eval_select(rlang::expr(c(!!!dots)), data),
    error = function(e) NULL
  )
  if (is.null(selected)) {
    return(invisible())
  }
  source <- names(data)[selected]
  renamed <- source %in% group_vars & names(selected) != source
  if (any(renamed)) {
    stop(
      "Grouping column `",
      source[renamed][[1L]],
      "` cannot also be measured (selected as `",
      names(selected)[renamed][[1L]],
      "`). Copy it first, e.g. with mutate(), to summarise its values.",
      call. = FALSE
    )
  }
  invisible()
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
      stringr::str_length(vars[2]) >
      40
  ) {
    message <- paste0(
      vars[1],
      ", ... are ",
      suffix
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
    ds(
      !tidyselect::where(
        ~ is_summable(.x)
      )
    )

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
  if (length(stat) == 0L) {
    return(stats::setNames(character(), character()))
  }
  if (!is.character(stat) || anyNA(stat) || any(!nzchar(stat))) {
    stop(
      "`.stat` must be a character vector of non-missing statistic names.",
      call. = FALSE
    )
  }
  aliases <- c(missing = "miss_n", p25 = "q1", p50 = "median", p75 = "q3")
  supported <- c(
    "type",
    "n",
    "unique",
    "miss_n",
    "valid_pct",
    "min",
    "q1",
    "median",
    "mean",
    "mad",
    "sd",
    "q3",
    "max",
    "iqr",
    "skew",
    "kurtosis",
    "se",
    "sum",
    names(aliases)
  )
  percentiles <- grepl("^p[0-9]+([.][0-9]+)?$", stat)
  percentile_values <- suppressWarnings(as.numeric(sub("^p", "", stat)))
  percentiles <- percentiles &
    !is.na(percentile_values) &
    percentile_values >= 0 &
    percentile_values <= 100
  unknown <- setdiff(stat, c(supported, stat[percentiles]))
  if (length(unknown)) {
    stop(
      "Unsupported statistic: ",
      paste(unknown, collapse = ", "),
      ". See ?summ for supported names.",
      call. = FALSE
    )
  }
  stat <- unique(stat)
  mapped <- stat
  selected <- stat %in% names(aliases)
  mapped[selected] <- unname(aliases[stat[selected]])
  stats::setNames(mapped, stat)
}

summ_requested_stats <- function(stat, detail, calendar = FALSE) {
  if (length(stat)) {
    requested <- unique(unname(summ_stat_names(stat)))
  } else if (detail) {
    requested <- c(
      "n",
      "unique",
      "miss_n",
      "valid_pct",
      "min",
      "q1",
      "median",
      "mean",
      "mad",
      "sd",
      "q3",
      "max",
      "iqr",
      "skew",
      "kurtosis",
      "se",
      "sum"
    )
    if (calendar) {
      # Retain the established calendar detail column order.
      requested <- c(
        "n",
        "unique",
        "miss_n",
        "valid_pct",
        "min",
        "q1",
        "median",
        "q3",
        "mean",
        "sd",
        "mad",
        "max",
        "iqr",
        "se"
      )
    }
  } else {
    requested <- if (calendar) {
      c("n", "unique", "mean", "sd", "min", "max")
    } else {
      c("n", "unique", "min", "mean", "sd", "max")
    }
  }
  unique(c("type", requested))
}

# Summarise one variable for every group. Type metadata, numeric conversion
# and distinct-value identities are computed once per variable, not per group.
summ_variable <- function(var, locs, requested, calendar = FALSE) {
  missing <- is.na(var)
  unit <- s_unit(var)
  type <- s_type(var, .abbr = TRUE)
  # Calendar spreads carry their own difftime units, so the type stays bare.
  if (!is.na(unit) && !calendar) {
    type <- paste0(type, " [", unit, "]")
  }
  counts <- c("type", "n", "unique", "miss_n", "valid_pct")
  numeric <- if (any(!requested %in% counts) && is_summable(var)) {
    as_numeric(var)
  } else {
    NULL
  }
  ids <- if ("unique" %in% requested) vctrs::vec_group_id(var) else NULL

  quantile_names <- requested[grepl("^p[0-9]", requested)]
  probabilities <- stats::setNames(
    as.numeric(sub("^p", "", quantile_names)) / 100,
    quantile_names
  )
  if (any(requested %in% c("q1", "iqr"))) {
    probabilities["q1"] <- .25
  }
  if (any(requested %in% c("q3", "iqr"))) {
    probabilities["q3"] <- .75
  }
  mean_needed <- any(requested %in% c("mean", "skew", "kurtosis"))
  sd_needed <- any(requested %in% c("sd", "se", "skew", "kurtosis"))
  statistics <- setdiff(requested, "type")

  one_group <- function(loc) {
    kept <- loc[!missing[loc]]
    n_val <- length(kept)
    observed <- if (is.null(numeric)) numeric() else numeric[kept]
    has_values <- length(observed) > 0L
    center <- if (mean_needed && has_values) mean(observed) else NA_real_
    spread <- if (sd_needed && has_values) stats::sd(observed) else NA_real_
    quantiles <- stats::setNames(
      rep(NA_real_, length(probabilities)),
      names(probabilities)
    )
    if (has_values && length(probabilities)) {
      quantiles[] <- stats::quantile(
        observed,
        probabilities,
        type = 7,
        names = FALSE
      )
    }
    vapply(
      statistics,
      function(statistic) {
        if (statistic %in% names(quantiles)) {
          return(unname(quantiles[[statistic]]))
        }
        switch(
          statistic,
          n = n_val,
          unique = length(unique(ids[kept])),
          miss_n = length(loc) - n_val,
          valid_pct = if (length(loc)) n_val / length(loc) else NA_real_,
          min = if (has_values) min(observed) else NA_real_,
          median = if (has_values) stats::median(observed) else NA_real_,
          mean = center,
          mad = if (has_values) stats::mad(observed) else NA_real_,
          sd = spread,
          max = if (has_values) max(observed) else NA_real_,
          iqr = if (has_values) {
            unname(quantiles[["q3"]] - quantiles[["q1"]])
          } else {
            NA_real_
          },
          skew = if (has_values) {
            sum((observed - center)^3) / (n_val * spread^3)
          } else {
            NA_real_
          },
          kurtosis = if (has_values) {
            sum((observed - center)^4) / (n_val * spread^4) - 3
          } else {
            NA_real_
          },
          se = if (n_val) spread / sqrt(n_val) else NA_real_,
          sum = if (has_values) sum(observed) else NA_real_
        )
      },
      numeric(1)
    )
  }

  values <- matrix(
    as.numeric(unlist(lapply(locs, one_group), use.names = FALSE)),
    ncol = length(statistics),
    byrow = TRUE
  )
  out <- list(type = rep(type, length(locs)))
  for (j in seq_along(statistics)) {
    column <- values[, j]
    if (statistics[[j]] %in% c("n", "unique", "miss_n")) {
      column <- as.integer(column)
    }
    out[[statistics[[j]]]] <- column
  }
  tibble::as_tibble(out[requested])
}

# Format calendar locations: Dates as days, datetimes in their own time zone
# and hms times of day as clock times.
fmt_date <- function(x, var) {
  out <- rep(NA_character_, length(x))
  infinite <- is.infinite(x)
  out[infinite] <- as.character(x[infinite])
  finite <- is.finite(x)
  type <- s_type(var, .abbr = TRUE)
  if (type == "date") {
    out[finite] <- format(
      as.Date(x[finite], origin = "1970-01-01"),
      "%Y-%m-%d"
    )
  } else if (type == "time") {
    out[finite] <- fmt_clock(x[finite])
  } else {
    out[finite] <- format(
      as.POSIXct(x[finite], origin = "1970-01-01", tz = "UTC"),
      "%Y-%m-%d %H:%M",
      tz = summ_time_zone(var)
    )
  }
  out
}

# Seconds as hh:mm:ss, matching how hms prints whole-second times.
fmt_clock <- function(seconds) {
  whole <- round(abs(seconds))
  sprintf(
    "%s%02d:%02d:%02d",
    ifelse(seconds < 0 & whole > 0, "-", ""),
    as.integer(whole %/% 3600),
    as.integer(whole %% 3600 %/% 60),
    as.integer(whole %% 60)
  )
}

summ_time_zone <- function(var) {
  zone <- attr(var, "tzone", exact = TRUE)
  if (is.null(zone) || !nzchar(zone[[1L]])) "" else zone[[1L]]
}

calendar_unsupported <- c("sum", "skew", "kurtosis")
calendar_spreads <- c("sd", "mad", "iqr", "se")

# One unit per column keeps spreads comparable and usable in arithmetic:
# Dates always use days; other calendar spreads use the unit that fits the
# typical (median) nonzero spread.
summ_spread_units <- function(column, date) {
  if (date) {
    return("days")
  }
  seconds <- abs(as.numeric(column, units = "secs"))
  seconds <- seconds[is.finite(seconds) & seconds > 0]
  if (!length(seconds)) {
    return("secs")
  }
  typical <- stats::median(seconds)
  if (typical < 60) {
    "secs"
  } else if (typical < 3600) {
    "mins"
  } else if (typical < 86400) {
    "hours"
  } else {
    "days"
  }
}

# Locations become display strings; spreads become difftime seconds, and
# summ_data() then gives each spread column a single unit.
summ_format_calendar <- function(out, var, requested) {
  locations <- setdiff(
    requested,
    c("type", "n", "unique", "miss_n", "valid_pct", calendar_spreads)
  )
  for (statistic in locations) {
    out[[statistic]] <- fmt_date(out[[statistic]], var)
  }
  scale <- if (s_type(var, .abbr = TRUE) == "date") 86400 else 1
  for (statistic in intersect(requested, calendar_spreads)) {
    out[[statistic]] <- as.difftime(out[[statistic]] * scale, units = "secs")
  }
  out
}

summ_data <- function(
  .data,
  summ_vars,
  group_vars,
  .detail,
  .stat,
  calendar = FALSE
) {
  if (length(summ_vars) == 0L) {
    return(NULL)
  }
  requested <- summ_requested_stats(.stat, .detail, calendar)
  if (calendar) {
    unavailable <- intersect(requested, calendar_unsupported)
    if (length(unavailable)) {
      stop(
        "Unsupported statistic ",
        paste0("`", unavailable, "`", collapse = ", "),
        ": not supported for date/datetime/time variables.",
        call. = FALSE
      )
    }
  }
  if (length(group_vars)) {
    groups <- vctrs::vec_group_loc(.data[group_vars])
    keys <- groups$key
    locs <- groups$loc
  } else {
    keys <- NULL
    locs <- list(seq_len(nrow(.data)))
  }
  blocks <- lapply(summ_vars, function(column) {
    var <- .data[[column]]
    out <- summ_variable(var, locs, requested, calendar)
    if (calendar) {
      out <- summ_format_calendar(out, var, requested)
    }
    out
  })
  group_count <- length(locs)
  variable_count <- length(summ_vars)
  # Stack variable blocks, then interleave as group-major, variable-minor rows.
  rows <- c(outer(
    (seq_len(variable_count) - 1L) * group_count,
    seq_len(group_count),
    "+"
  ))
  stats <- vctrs::vec_slice(vctrs::vec_rbind(!!!blocks), rows)
  if (calendar) {
    date <- s_type(.data[[summ_vars[[1L]]]], .abbr = TRUE) == "date"
    for (statistic in intersect(names(stats), calendar_spreads)) {
      units(stats[[statistic]]) <- summ_spread_units(stats[[statistic]], date)
    }
  }
  out <- tibble::tibble(name = rep(summ_vars, group_count))
  if (!is.null(keys)) {
    out <- dplyr::bind_cols(
      vctrs::vec_slice(keys, rep(seq_len(group_count), each = variable_count)),
      out
    )
  }
  out <- dplyr::bind_cols(out, stats)
  if (length(.stat)) {
    mapped <- summ_stat_names(.stat)
    out <- dplyr::select(
      out,
      tidyselect::all_of(group_vars),
      name,
      type,
      tidyselect::all_of(mapped)
    )
  }
  out
}

summ_list <- function(
  .data,
  group_vars,
  .detail,
  .stat,
  .mode = c("list", "table")
) {
  .mode <- match.arg(.mode)

  numeric <- .data %>%
    ds(
      !tidyselect::all_of(group_vars) &
        !tidyselect::where(
          ~ s_type(.x) %in% c("date", "datetime", "time")
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

  time <- .data %>%
    ds(
      !tidyselect::all_of(group_vars) &
        tidyselect::where(
          ~ s_type(.x) %in% c("time")
        )
    )

  requested <- unique(unname(summ_stat_names(.stat)))
  skipped <- intersect(requested, calendar_unsupported)
  calendar <- c(date, datetime, time)
  if (length(skipped) && length(calendar)) {
    if (length(numeric) == 0L) {
      stop(
        "Unsupported statistic ",
        paste0("`", skipped, "`", collapse = ", "),
        ": not supported for date/datetime/time variables.",
        call. = FALSE
      )
    }
    warning(
      "`",
      paste(skipped, collapse = "`, `"),
      "` is not available for date/datetime/time variables; skipped: ",
      paste(calendar, collapse = ", "),
      ".",
      call. = FALSE
    )
    date <- character()
    datetime <- character()
    time <- character()
  }

  numeric <- summ_data(
    .data,
    numeric,
    group_vars,
    .detail,
    .stat
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
        ) %>%
          as.character()
      )
  }

  date <- summ_data(.data, date, group_vars, .detail, .stat, calendar = TRUE)
  datetime <- summ_data(
    .data,
    datetime,
    group_vars,
    .detail,
    .stat,
    calendar = TRUE
  )
  time <- summ_data(.data, time, group_vars, .detail, .stat, calendar = TRUE)

  out <- list(
    numeric = numeric,
    date = date,
    datetime = datetime,
    time = time
  ) %>%
    purrr::discard(~ is.null(.))

  if (.mode == "table") {
    if (length(out) > 0) {
      out <- lapply(out, summ_table_spreads)
      # Calendar locations are text. Shared statistic columns use text too,
      # with numeric values rounded to seven significant digits.
      text_stats <- unique(unlist(lapply(out, function(data) {
        names(data)[vapply(data, is.character, logical(1))]
      })))
      text_stats <- setdiff(text_stats, c(group_vars, "name", "type"))
      out <- lapply(out, function(data) {
        for (stat in intersect(text_stats, names(data))) {
          data[[stat]] <- summ_table_text(data[[stat]])
        }
        data
      })
      out <- dplyr::bind_rows(out)
    }
  } else if (length(out) == 1) {
    out <- out[[1]]
  } else {
    message("A list is returned as statistics are heterogeneous.")
  }

  return(out)
}

# In one stacked table, calendar spreads become plain numbers (days for Dates,
# seconds otherwise) so they share numeric columns; `type` records the unit.
summ_table_spreads <- function(data) {
  spreads <- names(data)[vapply(data, inherits, logical(1), "difftime")]
  if (!length(spreads)) {
    return(data)
  }
  unit <- if (all(data$type == "date")) "days" else "secs"
  for (statistic in spreads) {
    data[[statistic]] <- as.numeric(data[[statistic]], units = unit)
  }
  data$type <- paste0(data$type, " [", unit, "]")
  data
}

summ_table_text <- function(x) {
  if (is.character(x)) {
    return(x)
  }
  if (is.double(x)) {
    x <- signif(x, 7)
  }
  as.character(x)
}
