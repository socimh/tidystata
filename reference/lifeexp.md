# Life expectancy data in 1998

Country indicators for 1998 from the World Bank's World Development
Indicators, arranged like Stata's `lifeexp.dta` example. This dataset
contains variable labels, value labels and missing values.

## Usage

``` r
lifeexp
```

## Format

A tibble with 68 rows and 6 variables:

- region:

  Region (with value labels)

- country:

  Country

- popgrowth:

  Annual population growth rate (%)

- lexp:

  Life expectancy at birth (years)

- gnppc:

  GNI per capita, Atlas method (current US\$)

- safewater:

  People using safely managed drinking water services (% of population)
  in 2000

## Source

World Bank, World Development Indicators,
<https://datatopics.worldbank.org/world-development-indicators/>,
licensed under CC BY 4.0
(<https://creativecommons.org/licenses/by/4.0/>). Indicators
`SP.POP.GROW`, `SP.DYN.LE00.IN` and `NY.GNP.PCAP.CD` for 1998 and
`SH.H2O.SMDW.ZS` for 2000; values are rounded. Country names follow WDI,
and Serbia stands in for the Federal Republic of Yugoslavia. See the
installed `DATA-PROVENANCE.md` for the retrieval date and build script.

## Examples

``` r
lifeexp
#> # A tibble: 68 x 6
#>    region               country                popgrowth  lexp gnppc safewater
#>    <dbl+lbl>            <chr>                      <dbl> <dbl> <dbl>     <dbl>
#>  1 1 [Europe & C. Asia] Albania                     -0.6    74   870        49
#>  2 1 [Europe & C. Asia] Armenia                     -1.2    70   570        83
#>  3 1 [Europe & C. Asia] Austria                      0.1    78 27810        97
#>  4 1 [Europe & C. Asia] Azerbaijan                   0.9    64   510        49
#>  5 1 [Europe & C. Asia] Belarus                     -0.5    68  1540        82
#>  6 1 [Europe & C. Asia] Belgium                      0.2    77 26530       100
#>  7 1 [Europe & C. Asia] Bosnia and Herzegovina       1.8    74  1230        87
#>  8 1 [Europe & C. Asia] Bulgaria                    -0.7    71  1440        90
#>  9 1 [Europe & C. Asia] Croatia                     -0.1    72    NA        85
#> 10 1 [Europe & C. Asia] Czechia                     -0.1    75  6140        95
#> # i 58 more rows
```
