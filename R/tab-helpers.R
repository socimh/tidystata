# Helper functions for tab() and fre() families
s_ungroup <- function(.data) {
  if (dplyr::is_grouped_df(.data)) {
    message("Ungrouping the data.")
    .data <- dplyr::ungroup(.data)
  }
  return(.data)
}

modify_invalid_names <- function(
    .data, function_name) {
  invalid_names <-
    c(
      "n", "percent", "cum",
      "valid", "valid_cum",
      "...any_miss", "...valid_sum", "...tmp"
    )
  if (function_name %in% c("tab1()", "fre1()")) {
    invalid_names <- c(invalid_names, "value", "variable")
  }

  if (function_name %in%
    c("tab()", "tab1()")) {
    invalid_names <- invalid_names
  } else if (function_name %in%
    c("fre()", "fre1()", "tab2()", "fre2()")) {
    invalid_names <- invalid_names %>%
      c("total")
  } else {
    stop("Invalid function name.", call. = FALSE)
  }

  detected_names <- intersect(
    names(.data),
    invalid_names
  )

  if (length(detected_names) > 1) {
    names1 <- detected_names %>%
      paste0("`", ., "`") %>%
      stringr::str_flatten(
        collapse <- ", "
      )
    names2 <- detected_names %>%
      paste0("`.", ., "`") %>%
      stringr::str_flatten(
        collapse = ", "
      )
    message <- paste0(
      "To avoid duplicates in `", function_name, "`, ",
      names1, " are renamed as ", names2, ", respectively.\n",
      "Better to rename them before `", function_name, "`."
    )
    message(message)
  } else if (length(detected_names) == 1) {
    names1 <- detected_names %>%
      paste0("`", ., "`")
    names2 <- detected_names %>%
      paste0("`.", ., "`")
    message <- paste0(
      "To avoid duplicates in `", function_name, "`, ",
      names1, " is renamed as ", names2, ".\n",
      "Better to rename them before `", function_name, "`."
    )
    message(message)
  } else {
    return(.data)
  }

  can_rename <- .data %>%
    dplyr::rename_with(
      ~ paste0(".", .x),
      tidyselect::all_of(detected_names)
    ) %>%
    s_try()

  if (length(detected_names) > 0) {
    if (can_rename) {
      .data %>%
        dplyr::rename_with(
          ~ paste0(".", .x),
          tidyselect::all_of(detected_names)
        ) %>%
        return()
    } else {
      stop("The new name is also taken. Rename fails.", call. = FALSE)
    }
  }
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
    .data, group_vars = character(0), .desc = FALSE) {
  if (any(vapply(.data, function(x) !is.null(dim(x)), logical(1)))) {
    stop("Matrix columns are not supported in tabulation.", call. = FALSE)
  }
  .data <- tibble::as_tibble(.data)
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
        ...any_miss | ...valid_sum == 0, NA_real_, n / ...valid_sum * 100
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
      percent, cum, valid, valid_cum,
      .after = n
    ) %>%
    dplyr::select(-...valid_sum)

  return(out)
}

add_total <- function(data, group_vars = character(0)) {
  if (nrow(data) == 0L) return(data)
  if (length(group_vars) > 0L) {
    groups <- data %>%
      dplyr::group_by(dplyr::across(tidyselect::all_of(group_vars))) %>%
      dplyr::group_split(.keep = TRUE)
    return(purrr::map(groups, function(group) {
      key <- group[1L, group_vars, drop = FALSE]
      values <- dplyr::select(group, -tidyselect::all_of(group_vars))
      values <- add_total(values)
      dplyr::bind_cols(key[rep(1L, nrow(values)), , drop = FALSE], values)
    }) %>% purrr::list_rbind())
  }
  narrow_data <- ncol(data) <= 11

  if (narrow_data) {
    col_name <- data %>%
      dplyr::select(-c(n:dplyr::last_col())) %>%
      ds(dplyr::last_col())
    data <- data %>%
      dplyr::rename(...tmp = {{ col_name }}) %>%
      dplyr::mutate(...tmp = as_character(...tmp))
  } else {
    data <- data %>%
      dplyr::mutate(...tmp = "") %>%
      dplyr::relocate(...tmp, tidyselect::last_col(6):tidyselect::last_col(2))
  }

  # Performance: pre-compute totals once instead of multiple filter/pull passes
  total_n       <- sum(data$n)
  valid_rows    <- !data$...any_miss
  has_valid     <- any(valid_rows)
  has_missing   <- any(!valid_rows)
  n_valid_rows  <- sum(valid_rows)
  n_miss_rows   <- sum(!valid_rows)
  valid_n       <- if (has_valid) sum(data$n[valid_rows]) else 0L
  miss_n        <- if (has_missing) sum(data$n[!valid_rows]) else 0L

  out <- data
  extra_rows <- list()

  if (n_valid_rows > 1 && has_missing) {
    extra_rows[["valid_total"]] <- tibble::tibble(
      ...tmp = "Valid Total", n = valid_n,
      percent = valid_n / total_n * 100, valid = 100
    )
  }

  # Insert valid-total row after valid rows
  if (length(extra_rows) > 0) {
    out <- dplyr::bind_rows(
      out[valid_rows, ],
      extra_rows[["valid_total"]],
      out[!valid_rows, ]
    )
  }

  if (n_miss_rows > 1) {
    miss_total <- tibble::tibble(
      ...tmp = "Missing Total", n = miss_n,
      percent = miss_n / total_n * 100
    )
    out <- dplyr::bind_rows(out, miss_total)
  }

  out <- dplyr::bind_rows(
    out,
    tibble::tibble(...tmp = "Total", n = total_n, percent = 100)
  )

  if (narrow_data) {
    out <- dplyr::rename(out, {{ col_name }} := ...tmp)
  } else {
    out <- dplyr::rename(out, total = ...tmp)
  }

  return(out)
}

append_tab_list <- function(.data, blank_row = FALSE) {
  if (length(.data) == 0L) {
    return(tibble::tibble(
      variable = character(), value = character(), n = integer(),
      percent = double(), cum = double(), valid = double(), valid_cum = double()
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
          . %in% c("int", "dbl"), "num", .
        )
    ) %>%
    unique() %>%
    length()

  if (vec_types > 1) {
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

  out <- .data %>%
    dplyr::count(
      dplyr::across(
        dplyr::everything()
      )
    ) %>%
    tidyr::pivot_wider(
      names_from = 2,
      values_from = n
    ) %>%
    dplyr::mutate(
      dplyr::across(-1, ~ tidyr::replace_na(.x, 0))
    ) %>%
    dplyr::rename(
      {{ join_name }} := 1
    )

  return(out)
}

add_total2 <- function(out, .data) {
  if (nrow(out) == 0L) return(out)
  join_name <- .data %>%
    names() %>%
    stringr::str_flatten(" \\ ")

  out <- out %>%
    dplyr::rename(
      ...tmp := 1
    ) %>%
    dplyr::mutate(
      dplyr::across(
        -1, ~ tidyr::replace_na(.x, 0)
      ),
      ...tmp := ...tmp %>%
        as_character()
    )

  out_sum <- out[1L, , drop = FALSE]
  out_sum$...tmp <- "total"
  for (col in names(out)[-1L]) out_sum[[col]] <- sum(out[[col]])

  out <- out %>%
    dplyr::bind_rows(out_sum) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      total = dplyr::c_across(-1) %>%
        sum()
    ) %>%
    dplyr::ungroup() %>%
    dplyr::rename(
      {{ join_name }} := ...tmp
    )

  return(out)
}

result_to_flextable <- function(tb, group_vars, fre1 = FALSE, fre2 = FALSE) {
  if (!requireNamespace("flextable", quietly = TRUE)) {
    stop(
      "`.type = \"flextable\"` requires the optional flextable package. ",
      "Install it with install.packages('flextable').", call. = FALSE
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
            is.na(variable), NA,
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
