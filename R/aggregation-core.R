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
# groups, and a large preceding total must not cancel small increments.
aggregation_percentages <- function(n, missing, locs) {
  percent <- valid <- cum <- valid_cum <- rep(NA_real_, length(n))
  for (loc in locs) {
    counts <- n[loc]
    absent <- missing[loc]
    total <- sum(counts)
    valid_total <- sum(counts[!absent])
    percent[loc] <- counts / total * 100
    valid[loc] <- ifelse(
      absent | valid_total == 0,
      NA_real_,
      counts / valid_total * 100
    )
    cum[loc] <- cumsum(percent[loc])
    valid_cum[loc] <- cumsum(valid[loc])
  }
  list(percent = percent, cum = cum, valid = valid, valid_cum = valid_cum)
}

aggregation_counts <- function(data, weights) {
  groups <- vctrs::vec_locate_sorted_groups(data, nan_distinct = TRUE)
  out <- as.list(groups$key)
  out$n <- if (is.null(weights)) {
    lengths(groups$loc)
  } else {
    vapply(groups$loc, function(loc) sum(weights[loc]), numeric(1))
  }
  out
}

aggregation_cells <- function(n, row, column, nrow, ncol) {
  cells <- matrix(if (is.integer(n)) 0L else 0, nrow, ncol)
  cells[cbind(row, column)] <- n
  lapply(seq_len(ncol), function(j) cells[, j])
}
