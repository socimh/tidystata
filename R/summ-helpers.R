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
    "`.\n\u2139 Create the grouping column first, e.g. ",
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
    capture()
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
      "^(lgl|int|dbl|int64|units|drtn|time|date|dttm|fct|ord)(\\+lbl)?( \\[.*\\])?$"
    )
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

summ_metadata <- function(data, keep_all) {
  lapply(data, function(var) {
    type <- s_type(var, .abbr = TRUE)
    summable <- is_summable_chr(type)
    retained <- summable || keep_all
    list(
      type = type,
      unit = if (retained) s_unit(var) else NA_character_,
      missing = if (retained) is.na(var) else NULL,
      summable = summable
    )
  })
}

summ_check_metadata <- function(metadata, keep_all) {
  types <- vapply(metadata, `[[`, character(1), "type")
  summable <- vapply(metadata, `[[`, logical(1), "summable")
  warning_vars(
    names(metadata)[!summable],
    if (keep_all) {
      "non-numeric (***)."
    } else {
      "non-numeric and thus removed."
    }
  )
  entirely_missing <- vapply(
    metadata,
    function(info) {
      info$summable && length(info$missing) > 0L && all(info$missing)
    },
    logical(1)
  )
  warning_vars(
    names(metadata)[entirely_missing],
    if (keep_all) {
      "entirely missing."
    } else {
      "entirely missing; retained with n = 0."
    }
  )
  if (!any(summable) && !(keep_all && length(metadata))) {
    stop(
      "None of the provided variable(s) is suitable for `summ()`.",
      call. = FALSE
    )
  }
  factors <- names(metadata)[summable & types %in% c("fct", "ord")]
  warning_vars(
    factors,
    if (length(factors) == 1L) {
      "a factor (**)."
    } else {
      "factors (**)."
    }
  )
  labelled <- names(metadata)[summable & grepl("lbl$", types)]
  warning_vars(
    labelled,
    if (length(labelled) == 1L) {
      "a labelled variable (*)."
    } else {
      "labelled variables (*)."
    }
  )
  if (keep_all) metadata else metadata[summable]
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
summ_variable <- function(
  var,
  numeric,
  locs,
  requested,
  calendar = FALSE,
  weights = NULL,
  weight_type = "frequency",
  metadata
) {
  missing <- metadata$missing
  unit <- metadata$unit
  type <- metadata$type
  # Calendar spreads carry their own difftime units, so the type stays bare.
  if (!is.na(unit) && !calendar) {
    type <- paste0(type, " [", unit, "]")
  }
  ids <- if ("unique" %in% requested && length(locs) > 1L) {
    vctrs::vec_group_id(var)
  } else {
    NULL
  }

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
  if (!is.null(weights)) {
    return(summ_weighted(
      var,
      numeric,
      missing,
      locs,
      requested,
      statistics,
      probabilities,
      type,
      weights,
      weight_type
    ))
  }

  # Slice each group once, then dispatch each requested statistic once per
  # variable. The numerical routines and original missingness semantics stay R's.
  kept <- lapply(locs, function(loc) loc[!missing[loc]])
  n_val <- lengths(kept)
  observed <- if (is.null(numeric)) {
    rep(list(numeric()), length(locs))
  } else {
    lapply(kept, function(loc) numeric[loc])
  }
  nonempty <- which(lengths(observed) > 0L)
  apply_observed <- function(fn) {
    result <- rep(NA_real_, length(locs))
    result[nonempty] <- vapply(observed[nonempty], fn, numeric(1))
    result
  }
  center <- if (mean_needed) apply_observed(mean) else NULL
  spread <- if (sd_needed) apply_observed(stats::sd) else NULL
  quantiles <- if (length(probabilities)) {
    lapply(observed, function(x) {
      if (length(x)) {
        stats::quantile(x, probabilities, type = 7, names = FALSE)
      } else {
        rep(NA_real_, length(probabilities))
      }
    })
  } else {
    NULL
  }
  quantile_column <- function(name) {
    vapply(quantiles, `[[`, numeric(1), match(name, names(probabilities)))
  }
  moment <- function(power) {
    result <- rep(NA_real_, length(locs))
    result[nonempty] <- vapply(
      nonempty,
      function(i) {
        sum((observed[[i]] - center[[i]])^power) /
          (n_val[[i]] * spread[[i]]^power)
      },
      numeric(1)
    )
    result
  }
  out <- list(type = rep(type, length(locs)))
  for (statistic in statistics) {
    out[[statistic]] <- if (statistic %in% names(probabilities)) {
      quantile_column(statistic)
    } else {
      switch(
        statistic,
        n = as.integer(n_val),
        unique = if (length(kept) == 1L) {
          vctrs::vec_unique_count(vctrs::vec_slice(var, kept[[1L]]))
        } else {
          vapply(kept, function(loc) length(unique(ids[loc])), integer(1))
        },
        miss_n = as.integer(lengths(locs) - n_val),
        valid_pct = {
          result <- n_val / lengths(locs)
          result[lengths(locs) == 0L] <- NA_real_
          result
        },
        min = apply_observed(min),
        median = apply_observed(stats::median),
        mean = center,
        mad = apply_observed(stats::mad),
        sd = spread,
        max = apply_observed(max),
        iqr = quantile_column("q3") - quantile_column("q1"),
        skew = moment(3),
        kurtosis = moment(4) - 3,
        se = spread / sqrt(n_val),
        sum = apply_observed(sum)
      )
    }
  }
  out[requested]
}

# Format calendar locations: Dates as days, datetimes in their own time zone
# and hms times of day as clock times.
fmt_date <- function(x, var, type) {
  out <- rep(NA_character_, length(x))
  infinite <- is.infinite(x)
  out[infinite] <- as.character(x[infinite])
  finite <- is.finite(x)
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
summ_format_calendar <- function(out, var, requested, type) {
  locations <- setdiff(
    requested,
    c("type", "n", "unique", "miss_n", "valid_pct", calendar_spreads)
  )
  for (statistic in locations) {
    out[[statistic]] <- fmt_date(out[[statistic]], var, type)
  }
  scale <- if (type == "date") 86400 else 1
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
  calendar = FALSE,
  weights = NULL,
  weight_type = "frequency",
  groups,
  metadata
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
  keys <- groups$key
  locs <- groups$loc
  needs_numeric <- any(
    !requested %in%
      c(
        "type",
        "n",
        "unique",
        "miss_n",
        "valid_pct"
      )
  )
  blocks <- lapply(summ_vars, function(column) {
    var <- .data[[column]]
    numeric <- if (needs_numeric && metadata[[column]]$summable) {
      as_numeric(var)
    } else {
      NULL
    }
    out <- summ_variable(
      var,
      numeric,
      locs,
      requested,
      calendar,
      weights,
      weight_type,
      metadata[[column]]
    )
    if (calendar) {
      out <- summ_format_calendar(out, var, requested, metadata[[column]]$type)
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
  columns <- lapply(requested, function(statistic) {
    column <- do.call(vctrs::vec_c, lapply(blocks, `[[`, statistic))
    vctrs::vec_slice(column, rows)
  })
  stats <- tibble::as_tibble(stats::setNames(columns, requested))
  if (calendar) {
    date <- metadata[[summ_vars[[1L]]]]$type == "date"
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
  .mode = c("list", "table"),
  weights = NULL,
  weight_type = "frequency",
  metadata
) {
  .mode <- match.arg(.mode)

  types <- vapply(metadata, `[[`, character(1), "type")
  numeric <- names(types)[!types %in% c("date", "dttm", "time")]
  date <- names(types)[types == "date"]
  datetime <- names(types)[types == "dttm"]
  time <- names(types)[types == "time"]
  groups <- aggregation_groups(.data, group_vars)

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
    .stat,
    weights = weights,
    weight_type = weight_type,
    groups = groups,
    metadata = metadata
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

  date <- summ_data(
    .data,
    date,
    group_vars,
    .detail,
    .stat,
    calendar = TRUE,
    weights = weights,
    weight_type = weight_type,
    groups = groups,
    metadata = metadata
  )
  datetime <- summ_data(
    .data,
    datetime,
    group_vars,
    .detail,
    .stat,
    calendar = TRUE,
    weights = weights,
    weight_type = weight_type,
    groups = groups,
    metadata = metadata
  )
  time <- summ_data(
    .data,
    time,
    group_vars,
    .detail,
    .stat,
    calendar = TRUE,
    weights = weights,
    weight_type = weight_type,
    groups = groups,
    metadata = metadata
  )

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

# Weighted statistics for one variable in every group. Frequency weights use
# the summed weight W as the number of observations; analytic weights are first
# rescaled within the group so that W equals the number of observed values.
# Mean, variance (W - 1 denominator), moments and sums follow Stata's
# `summarize [fweight/aweight]`; percentiles follow Stata's weighted rule.
# `unique`, `miss_n` and `valid_pct` remain row counts.
summ_weighted <- function(
  var,
  numeric,
  missing,
  locs,
  requested,
  statistics,
  probabilities,
  type,
  weights,
  weight_type
) {
  spread_needed <- any(statistics %in% c("sd", "se", "skew", "kurtosis"))
  center_needed <- spread_needed || "mean" %in% statistics
  median_needed <- any(statistics %in% c("median", "mad"))
  if (median_needed) {
    probabilities["median"] <- 0.5
  }
  one_group <- function(loc) {
    kept <- loc[!missing[loc]]
    w <- weights[kept]
    if (weight_type == "analytic" && sum(w) > 0) {
      w <- w * length(w) / sum(w)
    }
    total <- sum(w)
    x <- if (is.null(numeric)) numeric() else numeric[kept]
    has <- length(x) > 0L && total > 0
    center <- if (has && center_needed) sum(w * x) / total else NA_real_
    spread <- if (has && spread_needed && total > 1) {
      sqrt(sum(w * (x - center)^2) / (total - 1))
    } else {
      NA_real_
    }
    quantiles <- if (has && length(probabilities)) {
      weighted_quantile(x, w, probabilities)
    } else {
      rep(NA_real_, length(probabilities))
    }
    names(quantiles) <- names(probabilities)
    positive <- if (any(statistics %in% c("min", "max"))) x[w > 0] else NULL
    median <- if (median_needed) unname(quantiles[["median"]]) else NULL
    vapply(
      statistics,
      function(statistic) {
        if (statistic %in% names(quantiles)) {
          return(unname(quantiles[[statistic]]))
        }
        switch(
          statistic,
          n = total,
          unique = vctrs::vec_unique_count(vctrs::vec_slice(var, kept)),
          miss_n = length(loc) - length(kept),
          valid_pct = if (length(loc)) length(kept) / length(loc) else NA_real_,
          min = if (has) min(positive) else NA_real_,
          median = median,
          mean = center,
          mad = if (has) {
            1.4826 * weighted_quantile(abs(x - median), w, 0.5)
          } else {
            NA_real_
          },
          sd = spread,
          max = if (has) max(positive) else NA_real_,
          iqr = unname(quantiles[["q3"]] - quantiles[["q1"]]),
          skew = if (has) {
            sum(w * (x - center)^3) / (total * spread^3)
          } else {
            NA_real_
          },
          kurtosis = if (has) {
            sum(w * (x - center)^4) / (total * spread^4) - 3
          } else {
            NA_real_
          },
          se = spread / sqrt(total),
          sum = if (has) sum(w * x) else NA_real_
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
    if (statistics[[j]] %in% c("unique", "miss_n")) {
      column <- as.integer(column)
    }
    out[[statistics[[j]]]] <- column
  }
  out[requested]
}
