# Helper functions for tab() and fre() families
tab_ungroup <- function(.data) {
  if (dplyr::is_grouped_df(.data)) {
    cli::cli_inform("Ungrouping the data.")
    .data <- dplyr::ungroup(.data)
  }
  .data
}

tab_rename_reserved <- function(
  .data,
  function_name,
  candidates = names(.data),
  call = rlang::caller_env()
) {
  invalid_names <-
    c(
      "n",
      "percent",
      "cum",
      "valid",
      "valid_cum",
      "...any_miss",
      "...valid_sum",
      "...tmp"
    )
  if (function_name %in% c("tab1()", "fre1()")) {
    invalid_names <- c(invalid_names, "value", "variable")
  }

  if (
    function_name %in%
      c("tab()", "tab1()")
  ) {
    invalid_names <- invalid_names
  } else if (
    function_name %in%
      c("fre()", "fre1()", "tab2()")
  ) {
    invalid_names <- invalid_names %>%
      c("total")
  } else {
    cli::cli_abort("Invalid function name.", .internal = TRUE)
  }

  detected_names <- intersect(candidates, invalid_names)
  if (length(detected_names) == 0L) {
    return(.data)
  }
  reserved_name_inform(
    detected_names,
    paste0(".", detected_names),
    function_name
  )

  can_rename <- .data %>%
    dplyr::rename_with(
      ~ paste0(".", .x),
      tidyselect::all_of(detected_names)
    ) %>%
    capture()

  if (can_rename) {
    dplyr::rename_with(
      .data,
      ~ paste0(".", .x),
      tidyselect::all_of(detected_names)
    )
  } else {
    cli::cli_abort("The new name is also taken. Rename fails.", call = call)
  }
}

# Shared wording for input columns renamed to avoid output-column collisions.
reserved_name_inform <- function(old, new, function_name, what = NULL) {
  quote <- function(x) paste0("`", x, "`", collapse = ", ")
  renamed <- paste0(if (is.null(what)) "" else paste0(what, " "), quote(old))
  replacement <- quote(new)
  uses <- if (length(old) == 1L) quote(old) else "these names"
  columns <- if (length(old) == 1L) "column" else "columns"
  cli::cli_inform(c(
    "{renamed} renamed to {replacement} because {.code {function_name}} output uses {uses}.",
    i = "Rename the input {columns} before calling {.code {function_name}} to choose another name."
  ))
}

tab2_check_vars <- function(.data, call = rlang::caller_env()) {
  if (ncol(.data) < 2) {
    cli::cli_abort(
      c(
        "Only 1 variable is input.",
        i = "Provide two variables for cross-tabulation, or more for every pairwise table."
      ),
      call = call
    )
  }
}

tab_prepare_data <- function(.data, ..., group_vars = character(0)) {
  .data <- dplyr::ungroup(.data)
  if (group_vars %>% length() > 0) {
    out <- .data %>%
      remove_group_vars(..., group_vars = group_vars)
  } else {
    if (!missing(...)) {
      .data <- s_select(.data, ...)
    }
    out <- .data %>%
      dplyr::ungroup()
  }
  out
}

tab_counts <- function(data, weights) {
  # Use the same native ordering as dplyr grouping, without per-category masks.
  # Keep dplyr's option validation and legacy locale behavior when configured.
  if (is.null(getOption("dplyr.legacy_locale"))) {
    out <- tibble::as_tibble(aggregation_counts(data, weights))
  } else if (is.null(weights)) {
    out <- dplyr::count(data, dplyr::across(dplyr::everything()))
  } else {
    data$...wt <- weights
    out <- dplyr::count(
      data,
      dplyr::across(-"...wt"),
      wt = .data$...wt
    )
  }

  out
}

tab_data <- function(
  .data,
  group_vars = character(0),
  .desc = FALSE,
  weights = NULL,
  total = FALSE,
  group_order = "keys",
  input_groups = NULL,
  call = rlang::caller_env()
) {
  if (any(vapply(.data, function(x) !is.null(dim(x)), logical(1)))) {
    cli::cli_abort(
      "Matrix columns are not supported in tabulation.",
      call = call
    )
  }
  .data <- tibble::as_tibble(.data)
  if (length(setdiff(names(.data), group_vars)) == 0L) {
    return(dplyr::bind_cols(
      .data[0L, group_vars, drop = FALSE],
      tibble::tibble(
        n = if (is.null(weights)) integer() else double(),
        percent = double(),
        cum = double(),
        valid = double(),
        valid_cum = double(),
        ...any_miss = logical()
      )
    ))
  }
  out <- tab_counts(.data, weights)

  measured <- setdiff(names(out), c(group_vars, "n"))
  out$...any_miss <- rowSums(is.na(as.data.frame(out)[measured])) > 0L

  # Issue 2.3: sort within each group - non-missing first, then missing
  # Issue 2.5: .desc sorts non-NA rows by -n descending, then NA rows after
  if (.desc) {
    out <- out %>%
      dplyr::arrange(
        dplyr::across(tidyselect::all_of(group_vars)),
        .data$...any_miss,
        dplyr::desc(.data$n)
      )
  } else {
    out <- out %>%
      dplyr::arrange(
        dplyr::across(tidyselect::all_of(group_vars)),
        .data$...any_miss
      )
  }

  groups <- aggregation_groups(out, group_vars)
  columns <- aggregation_percentages(out$n, out$...any_miss, groups$loc)
  out[names(columns)] <- columns
  out <- out[c(group_vars, measured, "n", names(columns), "...any_miss")]

  if (total) {
    out <- tab_add_total(out, group_vars, groups)
  }
  order_tab_groups(out, .data, group_vars, group_order, weights, input_groups)
}

tab_add_total <- function(data, group_vars = character(0), groups) {
  if (nrow(data) == 0L) {
    return(data)
  }
  values <- setdiff(names(data), group_vars)
  narrow_data <- length(values) <= 11
  if (narrow_data) {
    label <- values[[match("n", values) - 1L]]
    data[[label]] <- as_character(data[[label]])
  } else {
    label <- "...tmp"
    data[[label]] <- ""
  }

  group_id <- aggregation_group_id(groups, nrow(data))
  first <- vapply(groups$loc, `[[`, integer(1), 1L)
  group_count <- length(first)
  sum_by <- function(x) {
    as.vector(rowsum(x, factor(group_id, levels = seq_len(group_count))))
  }
  valid_rows <- !data$...any_miss
  total_n <- sum_by(data$n)
  valid_n <- sum_by(data$n * valid_rows)
  miss_n <- total_n - valid_n
  n_valid_rows <- sum_by(as.integer(valid_rows))
  n_miss_rows <- sum_by(as.integer(!valid_rows))

  extra_row <- function(groups, text, n, percent, valid = NULL) {
    row <- vctrs::vec_slice(data[group_vars], first[groups])
    row[[label]] <- rep(text, length(groups))
    row$n <- n[groups]
    row$percent <- percent[groups]
    if (!is.null(valid)) {
      row$valid <- rep(valid, length(groups))
    }
    row
  }
  with_valid <- which(n_valid_rows > 1L & n_miss_rows > 0L)
  with_missing <- which(n_miss_rows > 1L)
  extras <- list(
    extra_row(
      with_valid,
      "Valid Total",
      valid_n,
      valid_n / total_n * 100,
      100
    ),
    extra_row(with_missing, "Missing Total", miss_n, miss_n / total_n * 100),
    extra_row(
      seq_len(group_count),
      "Total",
      total_n,
      rep(100, group_count)
    )
  )
  # Within each group: valid rows, valid total, missing rows, missing total,
  # then the overall total.
  out <- vctrs::vec_rbind(data, !!!extras)
  rank <- c(
    ifelse(valid_rows, 1L, 3L),
    rep(2L, length(with_valid)),
    rep(4L, length(with_missing)),
    rep(5L, group_count)
  )
  owner <- c(group_id, with_valid, with_missing, seq_len(group_count))
  out <- vctrs::vec_slice(out, order(owner, rank, seq_along(owner)))

  if (narrow_data) {
    out
  } else {
    out <- dplyr::rename(out, total = "...tmp")
    dplyr::relocate(
      out,
      tidyselect::all_of(c(
        "total",
        "n",
        "percent",
        "cum",
        "valid",
        "valid_cum"
      )),
      .before = tidyselect::all_of(values[[1L]])
    )
  }
}

append_tab_list <- function(.data, blank_row = FALSE) {
  if (length(.data) == 0L) {
    return(tibble::tibble(
      variable = character(),
      value = character(),
      n = integer(),
      percent = double(),
      cum = double(),
      valid = double(),
      valid_cum = double()
    ))
  }
  out <- .data %>%
    purrr::imap(
      ~ dplyr::mutate(
        .x,
        variable = .y
      )
    )

  vec_types <- out %>%
    purrr::map_chr(
      ~ dplyr::pull(., value) %>%
        var_type(abbr = TRUE) %>%
        # Element descriptions refine a family; vctrs checks compatibility below.
        sub("<.*$", "", .) %>%
        dplyr::if_else(
          . %in% c("int", "dbl"),
          "num",
          .
        )
    ) %>%
    unique() %>%
    length()

  value_types <- lapply(out, function(table) table$value)
  # Combining labelled vectors would relabel later values with earlier labels.
  labels <- lapply(value_types, function(x) {
    if (inherits(x, "haven_labelled")) attr(x, "labels", exact = TRUE)
  })
  compatible_types <- length(unique(labels)) <= 1L &&
    tryCatch(
      {
        do.call(vctrs::vec_ptype_common, unname(value_types))
        TRUE
      },
      vctrs_error_incompatible_type = function(error) FALSE
    )

  if (vec_types > 1 || !compatible_types) {
    out <- out %>%
      purrr::map(
        ~ .x %>%
          dplyr::mutate(
            value = as_character(value)
          )
      )
  }

  if (blank_row) {
    out <- out %>%
      purrr::map(
        ~ .x %>%
          dplyr::add_row(
            variable = NA_character_
          )
      )
  }

  out <- out %>%
    purrr::list_rbind() %>%
    dplyr::relocate("variable")

  out
}

tab2_data <- function(.data, weights = NULL) {
  .data <- tibble::as_tibble(.data)
  join_name <- .data %>%
    names() %>%
    stringr::str_flatten(" \\ ")

  .data <- dplyr::rename(.data, {{ join_name }} := 1)
  counts <- tab_counts(.data, weights)

  column_values <- counts[[2L]]
  # Count raw values before assigning display headers, so identities stay apart.
  blank <- !is.na(column_values) & as.character(column_values) == ""
  if (any(blank)) {
    used_names <- c(join_name, as.character(column_values[!blank]))
    empty_name <- "<empty>"
    suffix <- 0L
    while (empty_name %in% used_names) {
      suffix <- suffix + 1L
      empty_name <- paste0("<empty>", suffix)
    }
    column_values <- as.character(column_values)
    column_values[blank] <- empty_name
    counts[[2L]] <- column_values
  }
  # Order headers by raw values (factor levels, ascending, missing last).
  raw_order <- vctrs::vec_order(counts[[2L]])
  headers <- as.character(column_values)[raw_order]
  headers[is.na(headers)] <- "NA"
  columns <- vctrs::vec_group_loc(counts[[2L]])
  column_headers <- as.character(columns$key)
  column_headers[is.na(column_headers)] <- "NA"
  simple <- is.atomic(counts[[2L]]) &&
    is.null(dim(counts[[2L]])) &&
    (!is.object(counts[[2L]]) || is.factor(counts[[2L]])) &&
    !anyDuplicated(column_headers) &&
    !any(column_headers == join_name | grepl("^\\.\\.[0-9.]*$", column_headers))
  if (simple && nrow(counts)) {
    rows <- vctrs::vec_group_loc(counts[[1L]])
    row_id <- vctrs::vec_match(counts[[1L]], rows$key)
    display <- as.character(column_values)
    display[is.na(display)] <- "NA"
    column_id <- match(display, unique(headers))
    cells <- aggregation_cells(
      counts$n,
      row_id,
      column_id,
      length(rows$loc),
      length(columns$loc)
    )
    out <- tibble::as_tibble_col(rows$key, column_name = join_name)
    out[unique(headers)] <- cells
    return(out)
  }
  # Ambiguous display names and specialized classes keep pivot's diagnostics
  # and list-column behavior at the output boundary.
  out <- counts %>%
    tidyr::pivot_wider(
      names_from = 2,
      values_from = "n"
    ) %>%
    dplyr::mutate(
      dplyr::across(-1, ~ tidyr::replace_na(.x, 0))
    )
  out <- out[c(names(out)[1L], unique(headers))]

  out
}

order_tab_groups <- function(
  out,
  data,
  group_vars,
  group_order,
  weights = NULL,
  groups = NULL
) {
  if (group_order == "keys" || length(group_vars) == 0L || nrow(out) == 0L) {
    return(out)
  }
  if (is.null(groups)) {
    groups <- aggregation_groups(data, group_vars)
  }
  keys <- dplyr::arrange(groups$key, dplyr::across(dplyr::everything()))
  # Group size is the (weighted) number of observations in the group.
  group_sizes <- if (is.null(weights)) {
    lengths(groups$loc)
  } else {
    aggregation_group_sums(weights, groups$loc)
  }
  sizes <- group_sizes[vctrs::vec_match(keys, groups$key)]
  missing_keys <- rowSums(is.na(as.data.frame(keys))) > 0L
  ranked_keys <- keys[
    order(missing_keys, -sizes, seq_len(nrow(keys))),
    ,
    drop = FALSE
  ]
  group_id <- vctrs::vec_match(out[group_vars], ranked_keys)
  out[order(group_id, seq_len(nrow(out))), , drop = FALSE]
}

tab2_add_total <- function(out, .data, call = rlang::caller_env()) {
  if (nrow(out) == 0L) {
    return(out)
  }
  if ("total" %in% names(out)[-1L]) {
    cli::cli_abort(
      "Column category {.val total} is reserved for totals in {.code tab2(.total = TRUE)}. Recode this category first, or omit {.arg .total}.",
      call = call
    )
  }

  out <- out %>%
    dplyr::mutate(
      dplyr::across(
        -1,
        ~ tidyr::replace_na(.x, 0)
      )
    )
  out[[1L]] <- as_character(out[[1L]])

  out_sum <- out[1L, , drop = FALSE]
  out_sum[[1L]] <- "total"
  for (col in names(out)[-1L]) {
    out_sum[[col]] <- sum(out[[col]])
  }

  out <- dplyr::bind_rows(out, out_sum)
  counts <- out[-1L]
  totals <- rowSums(as.matrix(counts))
  # sum(integer) retains integer storage unless any row overflows that range.
  if (
    all(vapply(counts, is.integer, logical(1))) &&
      all(totals <= .Machine$integer.max)
  ) {
    totals <- as.integer(totals)
  }
  out$total <- totals

  out
}

result_to_flextable <- function(
  tb,
  group_vars,
  fre1 = FALSE,
  fre2 = FALSE,
  call = rlang::caller_env()
) {
  if (!requireNamespace("flextable", quietly = TRUE)) {
    cli::cli_abort(
      c(
        "{.code .type = \"flextable\"} requires the optional {.pkg flextable} package.",
        i = "Install it with {.code install.packages(\"flextable\")}."
      ),
      call = call
    )
  }
  if (fre2) {
    tb <- tb %>%
      dplyr::mutate(
        dplyr::across(
          1,
          ~ tidyr::replace_na(as_character(.x), "NA")
        )
      )
  } else if (fre1) {
    tb <- tb %>%
      dplyr::mutate(
        dplyr::across(
          dplyr::all_of(
            c(group_vars, "value")
          ),
          ~ ifelse(
            is.na(variable),
            NA,
            tidyr::replace_na(as_character(.x), "NA")
          )
        )
      )
  } else {
    tb <- tb %>%
      dplyr::mutate(
        dplyr::across(
          -dplyr::any_of(
            c("n", "percent", "cum", "valid", "valid_cum")
          ),
          ~ tidyr::replace_na(as_character(.x), "NA")
        )
      )
  }
  ft <- tb %>%
    flextable::as_flextable(
      max_row = 1e3
    )

  ft
}

# Pearson chi-square test of independence for a cross-tabulation from
# `tab2_data()`, with Cramer's V as in Stata's `tab x y, chi2 V`. Categories
# shown in the table, including missing ones, are tested; rows or columns with
# no observations are dropped. For 2 x 2 tables, V keeps its sign, as in Stata.
xtab_chi2 <- function(out) {
  counts <- as.matrix(out[-1L])
  counts <- counts[rowSums(counts) > 0, colSums(counts) > 0, drop = FALSE]
  n <- sum(counts)
  statistic <- p_value <- cramers_v <- NA_real_
  df <- NA_integer_
  if (nrow(counts) >= 2L && ncol(counts) >= 2L) {
    row_totals <- rowSums(counts)
    column_totals <- colSums(counts)
    expected <- outer(row_totals, column_totals) / n
    statistic <- sum((counts - expected)^2 / expected)
    df <- as.integer((nrow(counts) - 1L) * (ncol(counts) - 1L))
    p_value <- stats::pchisq(statistic, df, lower.tail = FALSE)
    cramers_v <- if (df == 1L) {
      (counts[1L, 1L] * counts[2L, 2L] - counts[1L, 2L] * counts[2L, 1L]) /
        sqrt(prod(row_totals) * prod(column_totals))
    } else {
      sqrt(statistic / (n * (min(dim(counts)) - 1L)))
    }
    cramers_v <- unname(cramers_v)
    text <- c(
      sprintf("Pearson chi2(%d) = %.4f   Pr = %.3f", df, statistic, p_value),
      sprintf("Cramer's V = %.4f", cramers_v)
    )
  } else {
    text <- paste(
      "Pearson chi2 is not computed: the table needs at least two rows and",
      "two columns with observations."
    )
  }
  # Fixed-width statistics output, so keep its spacing as written.
  rlang::inform(paste(text, collapse = "\n"))
  test <- tibble::tibble(
    statistic = statistic,
    df = df,
    p_value = p_value,
    cramers_v = cramers_v,
    n = n
  )
  attr(test, "text") <- text
  test
}
