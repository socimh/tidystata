#' Generate a variable based on row-wise operations.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' * `row_mean()` - Calculate the row-wise mean of selected varaibles.
#' * `row_sum()` - Calculate the row-wise sum of selected varaibles.
#' * `row_max()` - Calculate the row-wise maximum of selected varaibles.
#' * `row_min()` - Calculate the row-wise minimum of selected varaibles.
#' * `row_median()` - Calculate the row-wise median of selected varaibles.
#' * `row_var()` - Calculate the row-wise variance of selected varaibles.
#' * `row_sd()` - Calculate the row-wise standard deviation of selected varaibles.
#' * `row_unique()` - Calculate the row-wise number of unique values of selected varaibles.
#' * `row_miss()` - Calculate the row-wise number of missing values of selected varaibles.
#' * `row_non_miss()` - Calculate the row-wise number of non-missing values of selected varaibles.
#'
#' @param ... a data frame or tibble, or <[`tidy-select`][dplyr_tidy_select]> within the mutate() function.
#'
#' @return A numeric vector.
#' @name row_egen
#'
#' @examples
#' tb <- tibble::tibble(
#'   x = 1:10,
#'   y = 11:20,
#'   z = 21:30
#' )
#'
#' row_mean(tb)
#'
#' row_sum(tb)
#'
#' row_non_miss(tb)
#'
#' tb %>%
#'   dplyr::mutate(
#'     mean = row_mean(x, y),
#'     sum = row_sum(x, y)
#'   )

#' @rdname row_egen
#' @export
row_mean <- function(...) {
  if (dots_is_tibble(...)) {
    tibble::tibble(...) %>%
      rowMeans(na.rm = TRUE)
  } else {
    dplyr::pick(...) %>%
      rowMeans(na.rm = TRUE)
  }
}

#' @rdname row_egen
#' @export
row_sum <- function(...) {
  if (dots_is_tibble(...)) {
    tibble::tibble(...) %>%
      rowSums(na.rm = TRUE)
  } else {
    dplyr::pick(...) %>%
      rowSums(na.rm = TRUE)
  }
}

# row_max <- function(...) {
#   if (dots_is_tibble(...)) {
#     tibble::tibble(...) %>%
#       dplyr::mutate(dplyr::across(
#         dplyr::everything(),
#         as.double
#       )) %>%
#       df_to_mat(-Inf) %>%
#       Rfast::rowMaxs(value = TRUE) %>%
#       tibble::as_tibble()
#   } else {
#     dplyr::pick(...) %>%
#       dplyr::mutate(dplyr::across(
#         dplyr::everything(),
#         as.double
#       )) %>%
#       df_to_mat(-Inf) %>%
#       Rfast::rowMaxs(value = TRUE)
#   }
# }

#' @rdname row_egen
#' @export
row_max <- function(...) {
  # Unified path: always return plain numeric vector (same fix as row_min)
  if (dots_is_tibble(...)) {
    tibble::tibble(...) %>%
      dplyr::mutate(dplyr::across(dplyr::everything(), as.double)) %>%
      row_max_dbl()
  } else {
    dplyr::pick(...) %>%
      dplyr::mutate(dplyr::across(dplyr::everything(), as.double)) %>%
      row_max_dbl()
  }
}

#' @rdname row_egen
#' @export
row_miss <- function(...) {
  if (dots_is_tibble(...)) {
    tibble::tibble(...) %>%
      dplyr::mutate(dplyr::across(
        dplyr::everything(),
        is.na
      )) %>%
      row_sum()
  } else {
    dplyr::pick(...) %>%
      dplyr::mutate(dplyr::across(
        dplyr::everything(),
        is.na
      )) %>%
      row_sum()
  }
}

#' @rdname row_egen
#' @export
row_non_miss <- function(...) {
  if (dots_is_tibble(...)) {
    tibble::tibble(...) %>%
      dplyr::mutate(dplyr::across(
        dplyr::everything(),
        ~ !is.na(.)
      )) %>%
      row_sum()
  } else {
    dplyr::pick(...) %>%
      dplyr::mutate(dplyr::across(
        dplyr::everything(),
        ~ !is.na(.)
      )) %>%
      row_sum()
  }
}

# row_min <- function(...) {
#   if (dots_is_tibble(...)) {
#     tibble::tibble(...) %>%
#       dplyr::mutate(dplyr::across(
#         dplyr::everything(),
#         as.double
#       )) %>%
#       df_to_mat(Inf) %>%
#       Rfast::rowMins(value = TRUE) %>%
#       tibble::as_tibble()
#   } else {
#     dplyr::pick(...) %>%
#       dplyr::mutate(dplyr::across(
#         dplyr::everything(),
#         as.double
#       )) %>%
#       df_to_mat(Inf) %>%
#       Rfast::rowMins(value = TRUE)
#   }
# }

#' @rdname row_egen
#' @export
row_min <- function(...) {
  # Issue 4.2: Unify tibble and non-tibble paths so the result is always a
  # plain numeric vector. This matches pmin() behaviour and avoids returning
  # a nested tibble-column when used inside dplyr::mutate().
  if (dots_is_tibble(...)) {
    tibble::tibble(...) %>%
      dplyr::mutate(dplyr::across(dplyr::everything(), as.double)) %>%
      row_min_dbl()
  } else {
    dplyr::pick(...) %>%
      dplyr::mutate(dplyr::across(dplyr::everything(), as.double)) %>%
      row_min_dbl()
  }
}

#' @rdname row_egen
#' @export
row_median <- function(...) {
  if (dots_is_tibble(...)) {
    tibble::tibble(...) %>%
      dplyr::mutate(dplyr::across(
        dplyr::everything(),
        as.double
      )) %>%
      as.matrix() %>%
      Rfast::rowMedians(na.rm = TRUE) %>%
      tibble::as_tibble()
  } else {
    dplyr::pick(...) %>%
      dplyr::mutate(dplyr::across(
        dplyr::everything(),
        as.double
      )) %>%
      as.matrix() %>%
      Rfast::rowMedians(na.rm = TRUE)
  }
}

#' @rdname row_egen
#' @export
row_var <- function(...) {
  if (dots_is_tibble(...)) {
    tibble::tibble(...) %>%
      dplyr::mutate(dplyr::across(
        dplyr::everything(),
        as.double
      )) %>%
      as.matrix() %>%
      Rfast::rowVars(na.rm = TRUE) %>%
      tibble::as_tibble()
  } else {
    dplyr::pick(...) %>%
      dplyr::mutate(dplyr::across(
        dplyr::everything(),
        as.double
      )) %>%
      as.matrix() %>%
      Rfast::rowVars(na.rm = TRUE)
  }
}

#' @rdname row_egen
#' @export
row_sd <- function(...) {
  if (dots_is_tibble(...)) {
    tibble::tibble(...) %>%
      dplyr::mutate(dplyr::across(
        dplyr::everything(),
        as.double
      )) %>%
      as.matrix() %>%
      Rfast::rowVars(std = TRUE, na.rm = TRUE) %>%
      tibble::as_tibble()
  } else {
    dplyr::pick(...) %>%
      dplyr::mutate(dplyr::across(
        dplyr::everything(),
        as.double
      )) %>%
      as.matrix() %>%
      Rfast::rowVars(std = TRUE, na.rm = TRUE)
  }
}

#' @rdname row_egen
#' @export
row_unique <- function(...) {
  # Only if ... is double.
  if (dots_is_tibble(...)) {
    tibble::tibble(...) %>%
      dplyr::mutate(dplyr::across(
        dplyr::everything(),
        as.double
      )) %>%
      row_unique_dbl() %>%
      tibble::as_tibble()
  } else {
    dplyr::pick(...) %>%
      dplyr::mutate(dplyr::across(
        dplyr::everything(),
        as.double
      )) %>%
      row_unique_dbl()
  }
}


# Helpers
dots_is_tibble <- function(...) {
  if (s_try(dplyr::pick(...))) {
    return(FALSE)
  } else {
    return(TRUE)
  }
}

# not ready yet
# row_count_value <- function(..., value = NULL) {
#   if (is.logical(value)) {
#     if (value) {
#       f <- function(x) Rfast::rowTrue(x)
#     } else {
#       f <- function(x) Rfast::rowFalse(x)
#     }
#   } else {
#     # Only one value is returned by the function.
#     f <- function(x) Rfast::rowCountValues(x, values = value)
#   }

#   if (dots_is_tibble(...)) {
#     tibble::tibble(...) %>%
#       as.matrix() %>%
#       f() %>%
#       tibble::as_tibble()
#   } else {
#     dplyr::pick(...) %>%
#       f()
#   }
# }
