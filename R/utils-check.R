# Argument checks shared across families. The signatures follow the rlang
# checkers exported from rlang 1.2.0, so these can later be replaced by
# rlang's own versions without touching call sites. Each check names the
# offending argument (`arg`) and the user's call (`call`).

check_bool <- function(
  x,
  ...,
  allow_null = FALSE,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (is.logical(x) && length(x) == 1L && !is.na(x)) {
    return(invisible(NULL))
  }
  if (allow_null && is.null(x)) {
    return(invisible(NULL))
  }
  stop_input_type(x, "`TRUE` or `FALSE`", ..., arg = arg, call = call)
}

check_string <- function(
  x,
  ...,
  allow_empty = TRUE,
  allow_null = FALSE,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (is.character(x) && length(x) == 1L && !is.na(x)) {
    if (allow_empty || nzchar(x)) {
      return(invisible(NULL))
    }
    stop_input_type(x, "a non-empty string", ..., arg = arg, call = call)
  }
  if (allow_null && is.null(x)) {
    return(invisible(NULL))
  }
  stop_input_type(x, "a single string", ..., arg = arg, call = call)
}

check_number_whole <- function(
  x,
  ...,
  min = NULL,
  max = NULL,
  allow_infinite = FALSE,
  allow_null = FALSE,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (allow_null && is.null(x)) {
    return(invisible(NULL))
  }
  is_whole <- is.numeric(x) &&
    length(x) == 1L &&
    !is.na(x) &&
    (is.finite(x) && x == trunc(x) || allow_infinite && is.infinite(x))
  check_number_range(
    x,
    is_whole,
    "a whole number",
    min = min,
    max = max,
    ...,
    arg = arg,
    call = call
  )
}

check_number_decimal <- function(
  x,
  ...,
  min = NULL,
  max = NULL,
  allow_infinite = TRUE,
  allow_null = FALSE,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (allow_null && is.null(x)) {
    return(invisible(NULL))
  }
  is_number <- is.numeric(x) &&
    length(x) == 1L &&
    !is.na(x) &&
    (allow_infinite || is.finite(x))
  check_number_range(
    x,
    is_number,
    if (allow_infinite) "a number" else "a finite number",
    min = min,
    max = max,
    ...,
    arg = arg,
    call = call
  )
}

check_number_range <- function(x, ok, what, min, max, ..., arg, call) {
  if (!is.null(min) && !is.null(max)) {
    what <- paste(what, "between", min, "and", max)
  } else if (!is.null(min)) {
    what <- paste(what, "larger than or equal to", min)
  } else if (!is.null(max)) {
    what <- paste(what, "smaller than or equal to", max)
  }
  if (ok && (is.null(min) || x >= min) && (is.null(max) || x <= max)) {
    return(invisible(NULL))
  }
  stop_input_type(x, what, ..., arg = arg, call = call)
}

check_data_frame <- function(
  x,
  ...,
  allow_null = FALSE,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (is.data.frame(x)) {
    return(invisible(NULL))
  }
  if (allow_null && is.null(x)) {
    return(invisible(NULL))
  }
  stop_input_type(x, "a data frame", ..., arg = arg, call = call)
}

# Summaries and one-way tables also take one atomic vector, such as a
# column; lazy and arrow tables are rejected before any data handling.
check_data_frame_or_vector <- function(
  x,
  ...,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (is.data.frame(x) || (is.atomic(x) && !is.null(x) && is.null(dim(x)))) {
    return(invisible(NULL))
  }
  stop_input_type(
    x,
    "a data frame or an atomic vector",
    ...,
    arg = arg,
    call = call
  )
}

stop_input_type <- function(
  x,
  what,
  ...,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  # Like rlang, show the value of a rejected plain number.
  if (is.numeric(x) && !is.object(x) && length(x) == 1L && !is.na(x)) {
    cli::cli_abort(
      "{.arg {arg}} must be {what}, not the number {x}.",
      ...,
      arg = arg,
      call = call
    )
  }
  cli::cli_abort(
    "{.arg {arg}} must be {what}, not {.obj_type_friendly {x}}.",
    ...,
    arg = arg,
    call = call
  )
}

# Wrappers such as tabstat() and fre2() forward to another export. Called at
# the top of the forwarded function, this makes its errors name the call the
# user wrote rather than the wrapper's internal call.
local_wrapper_error_call <- function() {
  frame <- parent.frame()
  caller <- parent.frame(2L)
  if (identical(topenv(caller), topenv(frame))) {
    rlang::local_error_call(caller, frame = frame)
  }
  invisible()
}
