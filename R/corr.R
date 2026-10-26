#' Calculate complete-case Pearson correlations
#'
#' Calculate correlations using one common sample, like Stata's `corr`
#' (`correlate`). Rows missing any selected variable are excluded from every
#' correlation. Use [pwcorr()] to use a separate sample for each pair instead.
#'
#' @inheritParams pwcorr
#' @param .wide If `TRUE`, return a lower-triangular correlation table with
#'   one row per variable, like Stata's display. The default is a long table.
#' @param .wt_type `"frequency"` (default) reports the sum of weights as `n`;
#'   `"analytic"` reports the number of complete observations with positive
#'   weights. Both give the same weighted correlation. Zero-weight rows are
#'   excluded. Like [pwcorr()], fractional frequency weights are accepted,
#'   extending Stata's integer frequency-weight convention.
#'
#' @returns An ungrouped tibble with one row per distinct variable pair and
#'   group: any grouping keys, `var1`, `var2`, `r` (Pearson correlation), and
#'   `n` (complete observations or summed frequency weight). Every pair within
#'   a group uses the same sample and has the same `n`. P-values are omitted.
#'   With `.wide = TRUE`, columns are grouping keys, `variable`, and one
#'   correlation column per variable; the diagonal is 1 and the upper triangle
#'   is `NA`. Undefined correlations are `NA`.
#'
#' @details
#' Select at least two numeric or logical vector columns. When `...` is
#' omitted, nonnumeric columns and grouping keys are skipped, as in [pwcorr()].
#' Labelled numeric columns use their codes; tagged and SPSS user-missing values
#' are excluded before determining the common sample. Missing values in
#' unselected columns do not affect the sample.
#'
#' Computed columns are evaluated on ungrouped working data before complete
#' cases and groups are processed. Create columns with grouped [dplyr::mutate()]
#' first for calculations that need to run separately within each group.
#' Groups with fewer than two complete observations retain their pairs with
#' correlations of `NA`; empty grouped inputs return zero rows. The input is
#' not modified.
#'
#' Like Stata's correlation mode, this function computes Pearson correlations.
#' Stata's `covariance`, `means`, and display-formatting options are not
#' implemented. Use [stats::cov()] for covariance and [summ()] for summaries.
#' The tidy long table is an R interface choice; Stata prints a matrix.
#'
#' @seealso [pwcorr()], [stats::cor()]
#' @references [Stata correlate manual](https://www.stata.com/manuals/rcorrelate.pdf).
#' @family tabulation functions
#' @export
#'
#' @examples
#' corr(lifeexp, lexp, gnppc, safewater)
#'
#' corr(lifeexp, lexp, gnppc, safewater, .wide = TRUE)
#'
#' corr(lifeexp, lexp, gnppc, safewater, .by = region)
#'
#' corr(lifeexp, lexp, gnppc_thousands = gnppc / 1000)
#'
#' # Compare listwise and pairwise samples
#' survey <- tibble::tibble(
#'   x = c(1, 2, 3, 4), y = c(2, 3, NA, 5), z = c(1, NA, 4, 3)
#' )
#' corr(survey)
#'
#' pwcorr(survey)
corr <- function(
  .data,
  ...,
  .by = NULL,
  .wide = FALSE,
  .wt = NULL,
  .wt_type = c("frequency", "analytic")
) {
  pwcorr_data(
    .data,
    ...,
    .by = {{ .by }},
    .method = "pearson",
    .wide = .wide,
    .wt = {{ .wt }},
    .wt_type = .wt_type,
    .listwise = TRUE
  )
}
