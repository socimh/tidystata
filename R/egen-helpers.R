egen_numeric <- function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (inherits(x, "haven_labelled") && is.numeric(vctrs::vec_data(x))) {
    return(labelled_numeric(x))
  }
  if ((is.numeric(x) || is.logical(x)) && !is.object(x)) {
    return(as.numeric(x))
  }
  stop_input_type(x, "a numeric or logical vector", arg = arg, call = call)
}
