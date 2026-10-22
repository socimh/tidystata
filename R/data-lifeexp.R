#' Life expectancy data in 1998
#'
#' Country indicators for 1998 from the World Bank's World Development
#' Indicators, arranged like Stata's `lifeexp.dta` example. This dataset
#' contains variable labels, value labels and missing values.
#'
#' @source World Bank, World Development Indicators,
#' <https://datacatalog.worldbank.org/search/dataset/0037712>, licensed under
#' CC BY 4.0 (<https://creativecommons.org/licenses/by/4.0/>). Indicators
#' `SP.POP.GROW`, `SP.DYN.LE00.IN` and `NY.GNP.PCAP.CD` for 1998 and
#' `SH.H2O.SMDW.ZS` for 2000; values are rounded. Country names follow WDI,
#' and Serbia stands in for the Federal Republic of Yugoslavia. See the
#' installed `DATA-PROVENANCE.md` for the retrieval date and build script.
#'
#' @format A tibble with 68 rows and 6 variables:
#' \describe{
#' \item{region}{Region (with value labels)}
#' \item{country}{Country}
#' \item{popgrowth}{Annual population growth rate (%)}
#' \item{lexp}{Life expectancy at birth (years)}
#' \item{gnppc}{GNI per capita, Atlas method (current US$)}
#' \item{safewater}{People using safely managed drinking water services
#'   (% of population) in 2000}
#' }
#' @examples
#' lifeexp
"lifeexp"
