#' Set seeds with pipeline.
#'
#' Attach a seed to a specific function.
#'
#' @param .fn An expression evaluated after setting the seed.
#' @param seed An integer for reproducibility.
#' @returns The expression's result, preserving its visibility.
#' @details
#' Calls [set.seed()] before evaluating `.fn` once. The global random-number
#' state is changed and is not restored, including when `.fn` fails. Subsequent
#' random draws continue from the state left by `.fn`.
#'
#' @export
#' @examples
#' sample(1:10, 8) %>%
#'   set_seed(123)
#'
#' # When we re-run the code, we will get the same result.
#' sample(1:10, 8) %>%
#'  set_seed(123)
set_seed <- function(.fn, seed) {
  set.seed(seed)
  .fn
}
