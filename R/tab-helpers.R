# Helper functions for tab() and fre() families
s_ungroup <- function(.data) {
  if (dplyr::is_grouped_df(.data)) {
    message("Ungrouping the data.")
    .data <- dplyr::ungroup(.data)
  }
  return(.data)
}

modify_invalid_names <- function(
  .data,
  function_name,
  candidates = names(.data)
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
      c("fre()", "fre1()", "tab2()", "fre2()")
  ) {
    invalid_names <- invalid_names %>%
      c("total")
  } else {
    stop("Invalid function name.", call. = FALSE)
  }

  detected_names <- intersect(candidates, invalid_names)
  if (length(detected_names) == 0L) {
    return(.data)
  }
  message(reserved_name_message(
    detected_names,
    paste0(".", detected_names),
    function_name
  ))

  can_rename <- .data %>%
    dplyr::rename_with(
      ~ paste0(".", .x),
      tidyselect::all_of(detected_names)
    ) %>%
    s_try()

  if (can_rename) {
    dplyr::rename_with(
      .data,
      ~ paste0(".", .x),
      tidyselect::all_of(detected_names)
    )
  } else {
    stop("The new name is also taken. Rename fails.", call. = FALSE)
  }
}

# Shared wording for input columns renamed to avoid output-column collisions.
reserved_name_message <- function(old, new, function_name, what = NULL) {
  quote <- function(x) paste0("`", x, "`", collapse = ", ")
  paste0(
    if (is.null(what)) "" else paste0(what, " "),
    quote(old),
    " renamed to ",
    quote(new),
    " because `",
    function_name,
    "` output uses ",
    if (length(old) == 1L) quote(old) else "these names",
    ".\n",
    "\u2139 Rename the input column",
    if (length(old) == 1L) "" else "s",
    " before calling `",
    function_name,
    "` to choose another name."
  )
}

check_two_vars <- function(.data) {
  var_n <- ncol(.data)
  message1 <- paste0(
    "Only ",
    var_n,
    " variable is input.
      Please provide two variables for cross-tabulation."
  )
  message2 <- paste0(
    var_n,
    " variables are input.
      Please provide only two variables for cross-tabulation."
  )
  if (var_n < 2) {
    stop(message1, call. = FALSE)
  } else if (var_n > 2) {
    stop(message2, call. = FALSE)
  }
}

prepare_tab_data <- function(.data, ..., group_vars = character(0)) {
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
  return(out)
}

tab_data <- function(
  .data,
  group_vars = character(0),
  .desc = FALSE
) {
  if (any(vapply(.data, function(x) !is.null(dim(x)), logical(1)))) {
    stop("Matrix columns are not supported in tabulation.", call. = FALSE)
  }
  .data <- tibble::as_tibble(.data)
  if (length(setdiff(names(.data), group_vars)) == 0L) {
    return(dplyr::bind_cols(
      .data[0L, group_vars, drop = FALSE],
      tibble::tibble(
        n = integer(),
        percent = double(),
        cum = double(),
        valid = double(),
        valid_cum = double(),
        ...any_miss = logical()
      )
    ))
  }
  out <- .data %>%
    dplyr::count(
      dplyr::across(
        dplyr::everything()
      )
    )

  if (group_vars %>% length() > 0) {
    out <- out %>%
      dplyr::group_by(
        dplyr::pick(
          dplyr::all_of(group_vars)
        )
      )
  }

  measured <- setdiff(names(out), c(group_vars, "n"))
  out$...any_miss <- rowSums(is.na(as.data.frame(out)[measured])) > 0L
  out <- out %>%
    dplyr::mutate(
      percent = n / sum(n) * 100,
      ...valid_sum = sum(n[!...any_miss]),
      valid = dplyr::if_else(
        ...any_miss | ...valid_sum == 0,
        NA_real_,
        n / ...valid_sum * 100
      )
    )

  # Issue 2.3: sort within each group — non-missing first, then missing
  # Issue 2.5: .desc sorts non-NA rows by -n descending, then NA rows after
  if (.desc) {
    out <- out %>%
      dplyr::arrange(
        dplyr::across(tidyselect::all_of(group_vars)),
        ...any_miss,
        dplyr::desc(n)
      )
  } else {
    out <- out %>%
      dplyr::arrange(
        dplyr::across(tidyselect::all_of(group_vars)),
        ...any_miss
      )
  }

  out <- out %>%
    dplyr::mutate(
      cum = cumsum(percent),
      valid_cum = cumsum(valid)
    )

  if (group_vars %>% length() > 0) {
    out <- out %>%
      dplyr::ungroup()
  }

  out <- out %>%
    dplyr::relocate(
      percent,
      cum,
      valid,
      valid_cum,
      .after = n
    ) %>%
    dplyr::select(-...valid_sum)

  return(out)
}

add_total <- function(data, group_vars = character(0)) {
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

  if (length(group_vars) > 0L) {
    groups <- vctrs::vec_group_loc(data[group_vars])
    group_id <- integer(nrow(data))
    group_id[unlist(groups$loc)] <- rep(
      seq_along(groups$loc),
      lengths(groups$loc)
    )
    first <- vapply(groups$loc, `[[`, integer(1), 1L)
  } else {
    group_id <- rep(1L, nrow(data))
    first <- 1L
  }
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
    out <- dplyr::rename(out, total = ...tmp)
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
        s_type(.abbr = TRUE) %>%
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
    dplyr::relocate(variable)

  return(out)
}

tab2_data <- function(.data) {
  .data <- tibble::as_tibble(.data)
  join_name <- .data %>%
    names() %>%
    stringr::str_flatten(" \\ ")

  counts <- .data %>%
    dplyr::rename(
      {{ join_name }} := 1
    ) %>%
    dplyr::count(
      dplyr::across(
        dplyr::everything()
      )
    )

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
  out <- counts %>%
    tidyr::pivot_wider(
      names_from = 2,
      values_from = n
    ) %>%
    dplyr::mutate(
      dplyr::across(-1, ~ tidyr::replace_na(.x, 0))
    )
  out <- out[c(names(out)[1L], unique(headers))]

  return(out)
}

order_tab_groups <- function(out, data, group_vars, group_order) {
  if (group_order == "keys" || length(group_vars) == 0L || nrow(out) == 0L) {
    return(out)
  }
  groups <- vctrs::vec_group_loc(data[group_vars])
  keys <- dplyr::arrange(groups$key, dplyr::across(dplyr::everything()))
  sizes <- lengths(groups$loc)[vctrs::vec_match(keys, groups$key)]
  missing_keys <- rowSums(is.na(as.data.frame(keys))) > 0L
  ranked_keys <- keys[
    order(missing_keys, -sizes, seq_len(nrow(keys))),
    ,
    drop = FALSE
  ]
  group_id <- vctrs::vec_match(out[group_vars], ranked_keys)
  out[order(group_id, seq_len(nrow(out))), , drop = FALSE]
}

add_total2 <- function(out, .data) {
  if (nrow(out) == 0L) {
    return(out)
  }
  if ("total" %in% names(out)[-1L]) {
    stop(
      "Column category `total` is reserved for totals in `fre2()`. ",
      "Recode this category before calling `fre2()`, or use `tab2()`.",
      call. = FALSE
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

  out <- out %>%
    dplyr::bind_rows(out_sum) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      total = dplyr::c_across(-1) %>%
        sum()
    ) %>%
    dplyr::ungroup()

  return(out)
}

result_to_flextable <- function(tb, group_vars, fre1 = FALSE, fre2 = FALSE) {
  if (!requireNamespace("flextable", quietly = TRUE)) {
    stop(
      "`.type = \"flextable\"` requires the optional flextable package. ",
      "Install it with install.packages('flextable').",
      call. = FALSE
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

  return(ft)
}
