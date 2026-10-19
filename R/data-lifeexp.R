#' Life expectancy data in 1998
#'
#' Imported from the example dataset `lifeexp.dta` in Stata.
#' This dataset contains variable labels and value labels.
#'
#' @source Embedded notes identify historical World Bank data. A verified
#' reconstruction uses <https://www.stata-press.com/data/r17/lifeexp.dta>
#' and preserves the historical note ordering. The original import release
#' is unknown. See the installed `DATA-PROVENANCE.md` for details.
#'
#' @format A tibble with 68 rows and 6 variables:
#' \describe{
#' \item{region}{Region (with value labels)}
#' \item{country}{Country}
#' \item{popgrowth}{Average annual population growth rate (%)}
#' \item{lexp}{Life expectancy at birth (years)}
#' \item{gnppc}{GNP per capita}
#' \item{safewater}{Safe water (%)}
#' }
#' @examples
#' lifeexp
"lifeexp"
