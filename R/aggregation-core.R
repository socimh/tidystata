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
