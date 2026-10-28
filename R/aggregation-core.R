# Prepared row groups retain native keys and integer row locations. No class
# conversion or global cache belongs in the computational boundary.
aggregation_groups <- function(data, group_vars) {
  if (!length(group_vars)) {
    return(list(
      key = NULL,
      loc = list(seq_len(nrow(data)))
    ))
  }
  as.list(vctrs::vec_group_loc(data[group_vars]))
}

aggregation_group_id <- function(groups, size) {
  id <- integer(size)
  id[unlist(groups$loc, use.names = FALSE)] <- rep.int(
    seq_along(groups$loc),
    lengths(groups$loc)
  )
  id
}

# Each cumulative sum starts afresh: a zero-weight group must not poison later
# groups, and a large preceding total must not cancel small increments. The
# native group sums match sum() and cumsum() on each group's slice exactly.
aggregation_percentages <- function(n, missing, locs) {
  n <- as.double(n)
  id <- aggregation_group_id(list(loc = locs), length(n))
  total <- group_sum_dbl(n, locs)[id]
  valid_total <- group_sum_dbl(replace(n, missing, 0), locs)[id]
  percent <- n / total * 100
  valid <- n / valid_total * 100
  # As ifelse() did, an undetermined test also gives NA.
  absent <- missing | valid_total == 0
  valid[is.na(absent) | absent] <- NA_real_
  list(
    percent = percent,
    cum = group_cumsum_dbl(percent, locs),
    valid = valid,
    valid_cum = group_cumsum_dbl(valid, locs)
  )
}

aggregation_counts <- function(data, weights) {
  compact <- nrow(data) >= 100000L &&
    ncol(data) == 2L &&
    all(vapply(
      data,
      function(x) {
        (!is.object(x) &&
          typeof(x) %in% c("logical", "integer", "character")) ||
          identical(class(x), "factor") ||
          identical(class(x), c("ordered", "factor"))
      },
      logical(1)
    ))
  if (compact) {
    integer_column <- which(vapply(
      data,
      function(x) typeof(x) %in% c("integer", "logical"),
      logical(1)
    ))[1L]
    if (!is.na(integer_column)) {
      range <- tab_integer_range(data[[integer_column]])
      other <- data[[3L - integer_column]]
      if (!is.null(range)) {
        order <- integer()
        if (is.character(other)) {
          dictionary <- tab_character_id(other, nrow(data) %/% sum(range[2:3]))
          other_range <- integer()
          if (!is.null(dictionary)) {
            keys <- vctrs::vec_locate_sorted_groups(
              vctrs::vec_slice(other, dictionary[[2L]]),
              nan_distinct = TRUE
            )
            order <- integer(length(dictionary[[2L]]))
            order[vapply(keys$loc, `[[`, integer(1), 1L)] <- seq_along(order) -
              1L
            other <- dictionary[[1L]]
          }
        } else {
          other_range <- tab_integer_range(other)
          dictionary <- other_range
        }
        if (!is.null(dictionary)) {
          counts <- tab_count_dense(
            data[[integer_column]],
            range,
            other,
            other_range,
            order,
            weights,
            integer_column == 1L
          )
          if (!is.null(counts)) {
            out <- as.list(vctrs::vec_slice(data, counts[[1L]]))
            out$n <- counts[[2L]]
            return(out)
          }
        }
      }
    }
  }
  groups <- vctrs::vec_locate_sorted_groups(data, nan_distinct = TRUE)
  out <- as.list(groups$key)
  out$n <- if (is.null(weights)) {
    lengths(groups$loc)
  } else {
    aggregation_group_sums(weights, groups$loc)
  }
  out
}

# Like vapply(locs, function(loc) sum(weights[loc]), numeric(1)).
aggregation_group_sums <- function(weights, locs) {
  group_sum_dbl(as.double(weights), locs)
}

aggregation_cells <- function(n, row, column, nrow, ncol) {
  cells <- matrix(if (is.integer(n)) 0L else 0, nrow, ncol)
  cells[cbind(row, column)] <- n
  lapply(seq_len(ncol), function(j) cells[, j])
}
