#' Set the random seed, in a pipeline or alone
#'
#' Attach a seed to one expression at the end of a pipeline, as in
#' `sample(x, 5) |> set_seed(123)`, or set it alone like Stata's
#' `set seed 123` with `set_seed(123)`.
#'
#' @param x An expression evaluated after setting the seed. When `seed` is
#'   omitted, `x` is the seed itself, as in `set_seed(123)`.
#' @param seed An integer for reproducibility.
#' @returns The expression's result, preserving its visibility. Used alone,
#'   `set_seed()` returns `NULL` invisibly.
#' @details
#' Calls [set.seed()] before evaluating `x` once. The global random-number
#' state is changed and is not restored, including when `x` fails. Subsequent
#' random draws continue from the state left by `x`.
#'
#' With only one argument, that argument is the seed and must be a single
#' finite number. A pipeline that forgets the seed therefore errors, unless
#' its result happens to be a single number, which is then used as the seed.
#'
#' @family utility functions
#' @export
#' @examples
#' sample(1:10, 8) |>
#'   set_seed(123)
#'
#' # When we re-run the code, we will get the same result.
#' sample(1:10, 8) |>
#'  set_seed(123)
#'
#' # Alone, like Stata's set seed 123
#' set_seed(123)
#' sample(1:10, 8)
set_seed <- function(x, seed) {
  if (missing(seed)) {
    if (missing(x)) {
      cli::cli_abort("Supply a seed, as in {.code set_seed(123)}.")
    }
    seed <- x
    if (!is.numeric(seed) || length(seed) != 1L || !is.finite(seed)) {
      cli::cli_abort(c(
        "Used alone, {.fn set_seed} needs one number as the seed, as in {.code set_seed(123)}.",
        i = "In a pipeline, give the seed: {.code x |> set_seed(123)}."
      ))
    }
    set.seed(seed)
    return(invisible(NULL))
  }
  set.seed(seed)
  if (missing(x)) {
    return(invisible(NULL))
  }
  x
}
