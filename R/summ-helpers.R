summ_keep_measured <- function(.data, .data_num, group_vars) {
  out <- .data |>
    dplyr::ungroup() |>
    dplyr::select(
      tidyselect::all_of(group_vars)
    ) |>
    dplyr::bind_cols(.data_num)

  out
}

is_summable_chr <- function(chr) {
  grepl(
    "^(lgl|int|dbl|int64|units|drtn|time|date|dttm|fct|ord)(\\+lbl)?( \\[.*\\])?$",
    chr,
    perl = TRUE
  )
}

summ_warn_vars <- function(vars, suffix) {
  if (length(vars) == 0) {
    return()
  } else if (length(vars) == 1) {
    message <- paste0(vars, " is ", suffix)
    cli::cli_warn("{message}")
  } else if (nchar(vars[1]) + nchar(vars[2]) > 40) {
    message <- paste0(
      vars[1],
      ", ... are ",
      suffix
    )
    cli::cli_warn("{message}")
  } else if (length(vars) > 2) {
    message <- paste(vars[1:2], collapse = ", ") |>
      paste0(", ... are ", suffix)
    cli::cli_warn("{message}")
  } else {
    message <- paste(vars, collapse = " and ") |>
      paste0(" are ", suffix)
    cli::cli_warn("{message}")
  }
}

summ_metadata <- function(data, keep_all) {
  lapply(data, function(var) {
    type <- var_type(var, abbr = TRUE)
    summable <- is_summable_chr(type)
    retained <- summable || keep_all
    list(
      type = type,
      unit = if (retained) var_unit(var) else NA_character_,
      missing = if (retained) is.na(var) else NULL,
      summable = summable
    )
  })
}

summ_check_metadata <- function(
  metadata,
  keep_all,
  call = rlang::caller_env()
) {
  types <- vapply(metadata, `[[`, character(1), "type")
  summable <- vapply(metadata, `[[`, logical(1), "summable")
  summ_warn_vars(
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
  summ_warn_vars(
    names(metadata)[entirely_missing],
    if (keep_all) {
      "entirely missing."
    } else {
      "entirely missing; retained with n = 0."
    }
  )
  if (!any(summable) && !(keep_all && length(metadata))) {
    cli::cli_abort(
      "None of the provided variable(s) is suitable for {.fn summ}.",
      call = call
    )
  }
  factors <- names(metadata)[summable & types %in% c("fct", "ord")]
  summ_warn_vars(
    factors,
    if (length(factors) == 1L) {
      "a factor (**)."
    } else {
      "factors (**)."
    }
  )
  labelled <- names(metadata)[summable & grepl("lbl$", types)]
  summ_warn_vars(
    labelled,
    if (length(labelled) == 1L) {
      "a labelled variable (*)."
    } else {
      "labelled variables (*)."
    }
  )
  if (keep_all) metadata else metadata[summable]
}

summ_stat_names <- function(stat, call = rlang::caller_env()) {
  if (length(stat) == 0L) {
    return(stats::setNames(character(), character()))
  }
  if (!is.character(stat) || anyNA(stat) || any(!nzchar(stat))) {
    cli::cli_abort(
      "{.arg .stat} must be a character vector of non-missing statistic names.",
      call = call
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
    unknown <- paste(unknown, collapse = ", ")
    cli::cli_abort(
      "Unsupported statistic: {unknown}. See {.code ?summ} for supported names.",
      call = call
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
  kept <- lapply(locs, function(loc) loc[!metadata$missing[loc]])
  n_val <- lengths(kept)
  many_small <- length(locs) > 1L && sum(n_val) <= 1000 * length(locs)
  weighted <- !is.null(weights)
  statistics <- setdiff(
    requested,
    c("type", "unique", "miss_n", "valid_pct", if (!weighted) "n")
  )
  probabilities <- summ_probabilities(requested)
  if (weighted && any(c("median", "mad") %in% requested)) {
    probabilities["median"] <- 0.5
  }
  indices <- match(statistics, names(probabilities), nomatch = 0L)
  values <- if (!length(statistics)) {
    list()
  } else if (weighted) {
    group_weighted_summary_dbl(
      numeric,
      weights,
      kept,
      weight_type == "analytic",
      many_small,
      statistics,
      unname(probabilities),
      indices
    )
  } else if (is.null(numeric)) {
    rep(list(rep(NA_real_, length(locs))), length(statistics))
  } else {
    group_summary_dbl(
      numeric,
      kept,
      statistics,
      unname(probabilities),
      indices,
      many_small
    )
  }
  names(values) <- statistics
  out <- c(
    list(type = rep(summ_type_label(metadata, calendar), length(locs))),
    values
  )
  if (!weighted && "n" %in% requested) {
    out$n <- as.integer(n_val)
  }
  if ("unique" %in% requested) {
    out$unique <- if (length(locs) == 1L) {
      vctrs::vec_unique_count(vctrs::vec_slice(var, kept[[1L]]))
    } else {
      group_unique_id(vctrs::vec_group_id(var), kept)
    }
  }
  if ("miss_n" %in% requested) {
    out$miss_n <- as.integer(lengths(locs) - n_val)
  }
  if ("valid_pct" %in% requested) {
    out$valid_pct <- summ_valid_pct(n_val, lengths(locs))
  }
  out[requested]
}

# The displayed type, with the unit appended for measured vectors. Calendar
# spreads carry their own difftime units, so their type stays bare.
summ_type_label <- function(metadata, calendar) {
  if (is.na(metadata$unit) || calendar) {
    metadata$type
  } else {
    paste0(metadata$type, " [", metadata$unit, "]")
  }
}

# Named probabilities for requested percentiles (`p25` and so on), plus the
# quartiles behind `q1`, `q3` and `iqr`.
summ_probabilities <- function(requested) {
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
  probabilities
}

# Share of observed values in each group, NA for empty groups.
summ_valid_pct <- function(n_val, sizes) {
  result <- n_val / sizes
  result[sizes == 0L] <- NA_real_
  result
}

# Format calendar locations: Dates as days, datetimes in their own time zone
# and hms times of day as clock times.
summ_format_date <- function(x, var, type) {
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
  if (!length(zone) || !nzchar(zone[[1L]])) "" else zone[[1L]]
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
    out[[statistic]] <- summ_format_date(out[[statistic]], var, type)
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
  metadata,
  call = rlang::caller_env()
) {
  if (length(summ_vars) == 0L) {
    return(NULL)
  }
  requested <- summ_requested_stats(.stat, .detail, calendar)
  if (calendar) {
    unavailable <- intersect(requested, calendar_unsupported)
    if (length(unavailable)) {
      cli::cli_abort(
        "Unsupported statistic {.code {unavailable}}: not supported for date/datetime/time variables.",
        call = call
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
      # The kernels read logical, integer and double storage in place. Only
      # observed rows are summarised, and is.na() already marks SPSS
      # user-missing and tagged values, so labelled codes need no conversion.
      stored <- typeof(var) %in% c("logical", "integer", "double")
      if (stored && (!is.object(var) || inherits(var, "haven_labelled"))) {
        var
      } else {
        as_numeric(var)
      }
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
      "name",
      "type",
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
  type = c("list", "table"),
  weights = NULL,
  weight_type = "frequency",
  metadata,
  call = rlang::caller_env()
) {
  type <- rlang::arg_match(type)

  types <- vapply(metadata, `[[`, character(1), "type")
  numeric <- names(types)[!types %in% c("date", "dttm", "time")]
  date <- names(types)[types == "date"]
  datetime <- names(types)[types == "dttm"]
  time <- names(types)[types == "time"]
  groups <- aggregation_groups(.data, group_vars)

  requested <- unique(unname(summ_stat_names(.stat, call = call)))
  skipped <- intersect(requested, calendar_unsupported)
  calendar <- c(date, datetime, time)
  if (length(skipped) && length(calendar)) {
    if (length(numeric) == 0L) {
      cli::cli_abort(
        "Unsupported statistic {.code {skipped}}: not supported for date/datetime/time variables.",
        call = call
      )
    }
    skipped_variables <- paste(calendar, collapse = ", ")
    cli::cli_warn(
      "{.code {skipped}} {?is/are} not available for date/datetime/time variables; skipped: {skipped_variables}."
    )
    date <- character()
    datetime <- character()
    time <- character()
  }

  numeric <- summ_data(
    call = call,
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
    numeric <- numeric |>
      dplyr::mutate(
        name = dplyr::case_when(
          !is_summable_chr(type) ~ paste0("***", name),
          type %in% c("fct", "ord") ~ paste0("**", name),
          grepl("lbl$", type) ~ paste0("*", name),
          TRUE ~ name
        ) |>
          as.character()
      )
  }

  date <- summ_data(
    call = call,
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
    call = call,
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
    call = call,
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
  ) |>
    Filter(f = Negate(is.null))

  if (type == "table") {
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
    cli::cli_inform("A list is returned as statistics are heterogeneous.")
  }

  out
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
