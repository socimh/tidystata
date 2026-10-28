#' Calculate Spearman rank correlations
#'
#' @description
#' Calculate Spearman rank correlations, like Stata's
#' `spearman, stats(rho obs p)`. By default, as in Stata, rows missing any
#' selected variable are excluded from every correlation (casewise deletion).
#' Use `.pairwise = TRUE` for Stata's `pw` option.
#'
#' @inheritParams pwcorr
#' @param .pairwise If `TRUE`, each pair uses every row where both variables
#'   are observed, like Stata's `spearman, pw`. The default `FALSE` uses one
#'   common complete sample.
#'
#' @returns An ungrouped tibble with:
#' * By default, one row per distinct variable pair and group, with any grouping
#'   keys, `var1`, `var2`, `r` (Spearman's rho), `n` (observations), and `p`
#'   (two-sided p-value).
#' * With `.wide = TRUE`, one row per variable and group, with grouping keys,
#'   `variable`, and one correlation column per variable. The diagonal is 1 and
#'   the upper triangle is `NA`; `n` and `p` are omitted.
#'
#' Undefined correlations and p-values are `NA`. With fewer than three
#' observations, `p` is `NA` even when the correlation is defined.
#'
#' @details
#' Ties receive average ranks, and ranks are computed within each sample used
#' for a correlation. The p-value tests independence as Stata 18 and later do:
#' a beta distribution is fitted to the first four exact permutation moments
#' of the statistic, with a normal approximation, `sqrt(n - 1) * r`, when
#' `n = 3` or no valid fit exists. Earlier Stata versions and
#' [stats::cor.test()] use other approximations, so their p-values can differ.
#' Columns are selected, computed and grouped as in
#' [pwcorr()]. Like Stata's `spearman`, weights are not supported. A constant
#' variable gives `NA`, where Stata reports a correlation of 1.
#'
#' `spearman()` is the same as `pwcorr(.method = "spearman", .listwise = TRUE)`;
#' with `.pairwise = TRUE` it is the same as `pwcorr(.method = "spearman")`.
#'
#' @seealso [pwcorr()], [corr()], [stats::cor()]
#' @references [Stata spearman manual](https://www.stata.com/manuals/rspearman.pdf).
#' @family tabulation functions
#' @export
#'
#' @examples
#' spearman(lifeexp, lexp, gnppc, safewater)
#'
#' spearman(lifeexp, lexp, gnppc, safewater, .pairwise = TRUE)
#'
#' spearman(lifeexp, lexp, gnppc, .by = region)
#'
#' spearman(lifeexp, lexp, gnppc, safewater, .adjust = "bonferroni")
#'
#' spearman(lifeexp, lexp, gnppc, safewater, .wide = TRUE)
spearman <- function(
  .data,
  ...,
  .by = NULL,
  .pairwise = FALSE,
  .wide = FALSE,
  .adjust = c("none", "bonferroni", "sidak")
) {
  check_bool(.pairwise)
  pwcorr_data(
    .data,
    ...,
    .by = {{ .by }},
    .method = "spearman",
    .wide = .wide,
    .listwise = !.pairwise,
    .adjust = .adjust
  )
}
