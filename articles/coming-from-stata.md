# Coming from Stata

[中文版](https://socimh.github.io/tidystata/articles/coming-from-stata-zh.md)

This complete reference is part of the tidystata website. Use the header
to return to function help or other articles, and the contents to jump
to a section. The language link above switches between the English and
Chinese editions.

If you know Stata, you already know what you want to do; the question is
how to say it in R. This page lists Stata commands next to the R code
that does the same job, using tidystata where it has a Stata-style
function and the standard package everywhere else.

## Look it up from the console

[`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
searches the same list from R. Type one Stata word bare, or quote
anything longer. Stata’s abbreviations work.

``` r

findit(reg)
#> # Linear regression [stats]
#> Stata: regress y x1 x2
#> R:     fit <- lm(y ~ x1 + x2, data = data)
#> # Note: summary(fit) shows the coefficient table; broom::tidy(fit) returns it as a data frame.
#> 
#> # Fit linear regression through the origin [stats]
#> Stata: regress y x z, noconstant
#> R:     stats::lm(y ~ x + z - 1, data=data)
#> # Note: OLS coefficient correspondence requires the same complete-case sample, contrasts and weights. R returns an lm object; Stata coefficient tables and stored estimates have a different structure.
#> 
#> # Include two continuous main effects and their interaction [stats]
#> Stata: regress y c.x##c.z
#> R:     stats::lm(y ~ x * z, data=data)
#> # Note: OLS coefficient correspondence requires the same complete-case sample, contrasts and weights. R returns an lm object; Stata coefficient tables and stored estimates have a different structure.
#> 
#> # Fit a quadratic regression [stats]
#> Stata: regress y c.x##c.x
#> R:     stats::lm(y ~ x + I(x^2), data=data)
#> # Note: OLS coefficient correspondence requires the same complete-case sample, contrasts and weights. R returns an lm object; Stata coefficient tables and stored estimates have a different structure.
#> 
#> # Adjust regression for a categorical predictor [stats]
#> Stata: regress y i.g c.x
#> R:     stats::lm(y ~ factor(g) + x, data=data)
#> # Note: OLS coefficient correspondence requires the same complete-case sample, contrasts and weights. R returns an lm object; Stata coefficient tables and stored estimates have a different structure.
#> 
#> # 13 more relevant examples. To see them all: findit(reg) |> print(n = Inf)
findit("merge 1:1 id, keep(match)")
#> # Keep matched rows only [dplyr]
#> Stata: merge 1:1 id using data2, keep(match)
#> R:     inner_join(data1, data2, by = "id")
#> # Note: dplyr retains overlapping non-key columns with suffixes instead of Stata master values, creates no _merge, and does not enforce a declared 1:1 key constraint.
#> 
#> # merge() [base]: Merge two data frames (base R)
#>   Related Stata: merge
#> 
#> # 12 broader merge examples. Browse the family: findit(merge)
```

You can also look up an R function (`findit(left_join)`) or ask a
question (`findit("how do I remove duplicate rows")`). A bare command
such as `findit(egen)` returns the whole command family and shows up to
five operations. A specific query such as `findit("egen rowmean")`
returns one clear answer; ambiguous queries retain up to ten relevant
candidates. Call
[`findit()`](https://socimh.github.io/tidystata/reference/findit.md) for
the whole catalogue. Descriptions follow R’s language setting; English
and Chinese queries both work.

Comma-separated names customize compatible examples, such as
`findit(tab, sex, region)`. A matching hint such as `findit(tab, gen)`
can narrow the result to one answer. `print(n = Inf)` expands the
returned candidates, qualifications and source links. The footer counts
additional relevant results separately from broader operations; use
`findit(egen)` to browse the broader family. Within a matching
operation, recommendations prefer tidystata, then tidyverse, then other
packages or base R. Package-qualified lookups such as
`findit(dplyr::filter)` distinguish functions with the same name.

This reference contains 514 command families, 181 Stata functions and 3
operators, with 1721 distinct Stata examples and 1877 paired R examples.
Abbreviations and alternative R implementations do not increase the
command count. The R index describes 969 function/package pairs.

## Use the command tables

Use
[`destring()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
([`as_numeric()`](https://socimh.github.io/tidystata/reference/type_conversion.md))
to read numbers from text and
[`tostring()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
([`as_character()`](https://socimh.github.io/tidystata/reference/type_conversion.md))
to write stored codes as text. For categories,
[`encode()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
creates labelled integer codes from strings, and
[`decode()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
reads value labels back as text. Character encoding assigns fresh sorted
codes starting at 1; encoding factors preserves their existing integer
indices and all levels. `encode(decode(x))` need not recover the
original codes. Encode character columns before grouping so all rows use
the same dictionary.

The tables cover tidystata and other R packages, including modelling,
reshaping, survey analysis and graphics. For panel lags and leads,
tidystata provides
[`stata_lag()`](https://socimh.github.io/tidystata/reference/panel.md),
[`stata_lead()`](https://socimh.github.io/tidystata/reference/panel.md)
and
[`stata_diff()`](https://socimh.github.io/tidystata/reference/panel.md);
specify the time column and use `.by` to identify panels.

The index is alphabetical; tables are grouped by subject and sorted by
command, preferred answer and example. A package named beside a snippet
is needed to run that snippet, but
[`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
itself does not load or install reference packages. The label names the
primary package, rather than every helper dependency; the R function
index identifies additional functions and their packages.

A note that begins **Differs from Stata** means the R code does the same
job, but a default, the missing-value handling, an estimator or the
output layout differs; the note says how. Other notes are practical
tips. Most R snippets are run against controlled checks when the
catalogue is built; this tests the R code itself, not numerical
agreement with Stata. Missing-value comparisons, weights, factor
reference levels, join rules and standard-error corrections need
particular care. Known gaps are explained explicitly, and related search
results are not a translation of unsupported syntax.

In the tables below, `data` is your dataset, `data1` and `data2` are the
master and using data of a merge, and `fit` is a fitted model. Most
entries use dplyr, so attach it with
[`library(dplyr)`](https://dplyr.tidyverse.org) or
[`library(tidyverse)`](https://tidyverse.tidyverse.org).

## Alphabetical command index

[about](#example-ref-23457083a342d8a8) ·
[ac](#example-ref-fa917324a24efd88) · [ado](#example-legacy-0282) ·
[adopath](#example-ref-73ca091b91521ced) ·
[alpha](#example-ref-3350ec12cf1b42cc) ·
[ameans](#example-ref-5aa7518f2ab0218c) · [anova](#example-legacy-0077)
· [append](#example-legacy-0203) · [arch](#example-ref-598745454da87580)
· [areg](#example-legacy-0319) · [arfima](#example-ref-e96e8df2d5b61151)
· [arfimasoc](#example-ref-1564bed3021cc0d0) ·
[args](#example-ref-c15a768824347ad4) · [arima](#example-legacy-0367) ·
[arimasoc](#example-ref-9d32453886de0ca3) ·
[assert](#example-legacy-0096) ·
[assertnested](#example-ref-efdb2be1b7fda4a4) ·
[avplots](#example-legacy-0338) ·
[bayesboot](#example-ref-248ad08de8506a43) ·
[bayesmh](#example-ref-a699c64e08f36922) ·
[bayespredict](#example-ref-6cba06fa3d730369) ·
[bayesreps](#example-ref-fcd48dd1f7c36516) ·
[bayesstats](#example-ref-8260e45b67b5cefc) ·
[bayestest](#example-ref-a3b91560ebcf8bb4) ·
[betaden](#example-ref-1ddb01b2d1bd95c7) ·
[betareg](#example-ref-82e8d6d9f7ce5fee) ·
[binomial](#example-ref-feba781dd53899e6) ·
[binomialp](#example-ref-2870ce8439c98ab1) ·
[binomialtail](#example-ref-43b004304971bd9f) ·
[binormal](#example-ref-40b76311946722a2) ·
[binreg](#example-ref-e4242aa8ef193f7a) ·
[binscatter](#example-legacy-0392) ·
[biprobit](#example-ref-49b93e6110e11d41) ·
[bitest](#example-ref-6b1deacb918cbb8f) ·
[bitesti](#example-ref-a21517e1bdcd8013) ·
[bootstrap](#example-legacy-0327) ·
[boottest](#example-ref-7d951ad20c68b412) ·
[boxcox](#example-ref-365246014b25ce61) ·
[brier](#example-ref-40573305fb703752) · [browse](#example-legacy-0025)
· [bsample](#example-ref-a94810d1a2f1b172) ·
[bsqreg](#example-ref-56fab71164c2051b) ·
[bstat](#example-ref-8e67b9a3f14095e5) ·
[ca](#example-ref-ac4b4f5bb1e1dfae) ·
[camat](#example-ref-6d012b8e4da5f580) ·
[candisc](#example-ref-d7dd63e96c7cde66) ·
[canon](#example-ref-3873ffa966698552) · [capture](#example-legacy-0262)
· [carryforward](#example-legacy-0368) ·
[cauchy](#example-ref-9ff30d80b6535c8e) ·
[cauchyden](#example-ref-962a0bdb77d23af4) ·
[cauchytail](#example-ref-e30d72a91a34f079) ·
[cc](#example-ref-424c110bc6ea6371) ·
[cci](#example-ref-56ec6198a3201dac) · [cd](#example-legacy-0006) ·
[ceil](#example-legacy-0170) · [cem](#example-ref-b18b9901ce3d1478) ·
[centile](#example-ref-3f5e57210f45e8d0) ·
[cf](#example-ref-4b9c299d86ed3a89) ·
[changeeol](#example-ref-6afe57067a9e200d) ·
[char](#example-ref-7bb19cce251b8b6c) ·
[checksum](#example-ref-615f498ce61d6837) ·
[chi2](#example-ref-df210246f0ec980f) ·
[chi2den](#example-ref-94b83d4b1d225655) ·
[chi2tail](#example-ref-c2efa894972c510b) · [ci](#example-legacy-0070) ·
[cii](#example-ref-7f0c9e5685b478ce) ·
[ciwidth](#example-ref-e6cbcdc452abc5ff) · [clear](#example-legacy-0004)
· [clock](#example-legacy-0255) ·
[cloglog](#example-ref-e8440c74a473a83d) ·
[clonevar](#example-legacy-0116) · [cls](#example-legacy-0284) ·
[cluster](#example-legacy-0326) ·
[clustermat](#example-ref-2ce75b7749122961) ·
[cnsreg](#example-ref-b9ce2cd62c9c5d58) ·
[codebook](#example-legacy-0039) · [coefplot](#example-legacy-0393) ·
[cofd](#example-ref-78954527a10244b3) · [collapse](#example-legacy-0149)
· [compare](#example-ref-8def4bd824b2adc6) ·
[compress](#example-ref-9d975f8a2d35bf89) · [cond](#example-legacy-0164)
· [confirm](#example-legacy-0098) ·
[constraint](#example-ref-c91fb5a231785812) ·
[continue](#example-ref-58bb1358d0179422) ·
[contract](#example-ref-85fabe5e78c671ca) ·
[contrast](#example-ref-e7102b7161f365a6) ·
[copy](#example-ref-e0f605601bc6b6b3) ·
[corr2data](#example-ref-3184bb6d107ab390) ·
[correlate](#example-legacy-0055) ·
[corrgram](#example-ref-c2fbf01bb5085dc1) ·
[count](#example-legacy-0087) ·
[cpoisson](#example-ref-b48590230dce17cb) ·
[creturn](#example-ref-6514fb3dda6eb2a9) · [cross](#example-legacy-0216)
· [cs](#example-ref-c17d647491b15283) · [csdid](#example-legacy-0349) ·
[csi](#example-ref-89ed301de4fbd054) ·
[cumsp](#example-ref-77e672182b0ffdc7) ·
[cumul](#example-ref-634739a188699054) · [d.](#example-legacy-0360) ·
[dataex](#example-ref-b5a3ff959e6efea9) ·
[datasignature](#example-ref-e07062decc6c2795) ·
[date](#example-legacy-0233) · [day](#example-legacy-0251) ·
[daysinmonth](#example-ref-0995cab5c73d2f46) ·
[decode](#example-legacy-0104) · [describe](#example-legacy-0037) ·
[destring](#example-legacy-0125) ·
[dfbeta](#example-ref-272a9bd4c2db9d00) ·
[dfgls](#example-ref-f55a0252af7cc516) ·
[dfuller](#example-ref-d422b3dfaca8173e) ·
[did_imputation](#example-ref-582b51e66d955a85) ·
[didregress](#example-legacy-0348) · [dir](#example-legacy-0007) ·
[discrim](#example-ref-d94286a887ea99b9) ·
[display](#example-legacy-0009) · [distinct](#example-legacy-0093) ·
[do](#example-legacy-0012) · [dofc](#example-ref-b8b543d1a3d6725d) ·
[dofm](#example-legacy-0254) · [dofq](#example-ref-f10d37d14007b512) ·
[dofy](#example-ref-4f8cc37e57116157) ·
[dotplot](#example-ref-1319ab431bbe7e57) · [dow](#example-legacy-0252) ·
[doy](#example-ref-988943aa295ba4e9) ·
[drawnorm](#example-ref-d702c5cc8b38b18d) ·
[drdid](#example-ref-91b9d3a21c4c8352) · [drop](#example-legacy-0190) ·
[ds](#example-legacy-0038) · [dstdize](#example-ref-1e52bf6f47309d39) ·
[dtable](#example-legacy-0068) · [duplicates](#example-legacy-0092) ·
[ebalance](#example-ref-08875e78947a0f87) · [egen](#example-legacy-0129)
· [eivreg](#example-ref-c7b4b3cfb82adf4c) ·
[elasticnet](#example-ref-4b4ceaa0c28a79bd) ·
[encode](#example-legacy-0103) · [ereturn](#example-legacy-0271) ·
[error](#example-ref-78fa7f8656860b4b) ·
[esize](#example-ref-f23200cdd1b8ece1) ·
[esizei](#example-ref-e0f877f2b7170d5f) · [estat](#example-legacy-0334)
· [estimates](#example-legacy-0302) · [eststo](#example-legacy-0341) ·
[esttab](#example-legacy-0303) · [etable](#example-legacy-0342) ·
[eventstudyinteract](#example-ref-c5ed35903218b46d) ·
[exit](#example-ref-c38d419f44b8b51e) · [expand](#example-legacy-0222) ·
[expandcl](#example-ref-9d521682f9180c8f) ·
[exponential](#example-ref-5ef4b1a2dd10712f) ·
[exponentialden](#example-ref-1fef28de83dba7b8) ·
[exponentialtail](#example-ref-6cd8276eeaa5eec3) ·
[export](#example-legacy-0020) · [F](#example-ref-5c1a42b934cb6b4f) ·
[f.](#example-legacy-0359) · [factor](#example-legacy-0084) ·
[factormat](#example-ref-a0421b00c54bf2a7) ·
[fcast](#example-ref-a303bdc04fa81a48) ·
[fcollapse](#example-ref-ff005b44b4bc06f9) ·
[Fden](#example-ref-04e11edb60d43424) ·
[file](#example-ref-db37147f74447ccd) ·
[filefilter](#example-ref-1d589d51d8c70b62) ·
[fillin](#example-legacy-0221) ·
[findfile](#example-ref-bd15645a8d5b473c) ·
[findit](#example-legacy-0001) ·
[firstdayofmonth](#example-ref-54895385a937d3fc) ·
[flevelsof](#example-ref-de66c3f18db505af) ·
[floor](#example-legacy-0169) · [fmerge](#example-ref-fc8cbe46037e770a)
· [foreach](#example-legacy-0259) ·
[forecast](#example-ref-b942cb356f40594e) ·
[format](#example-legacy-0177) · [forvalues](#example-legacy-0260) ·
[fracreg](#example-ref-5b30581380bcbc7f) ·
[fralias](#example-ref-83c60851da971036) · [frame](#example-legacy-0280)
· [fre](#example-legacy-0042) · [frget](#example-ref-ece62cf14db3df86) ·
[frlink](#example-ref-f25874e32f399df3) ·
[frunalias](#example-ref-c431b0cad1da93c8) ·
[Ftail](#example-ref-a7f21b2b3b0647fb) ·
[ftools](#example-ref-289daa81773fd223) ·
[gammaden](#example-ref-2ad06af7ddddaa94) ·
[gammap](#example-ref-01f2d600d32ad31a) ·
[gammaptail](#example-ref-714f37f89d8bb54b) ·
[gcollapse](#example-ref-62b9cf30e03c4f15) ·
[gcontract](#example-ref-508fa38cbefc51be) ·
[gdistinct](#example-ref-1b4368f569d7de37) ·
[gduplicates](#example-ref-d5640ac837c849f8) ·
[gegen](#example-ref-faef9fb25fafad76) ·
[gencohort](#example-ref-dd1eed2ab75107c8) ·
[generate](#example-legacy-0108) ·
[getmata](#example-ref-3496cf3ffcb648d4) ·
[gettoken](#example-ref-41d57dcb2eb002c2) ·
[gisid](#example-ref-4419a5c318f57df9) ·
[glevelsof](#example-ref-6e0aa47ddd5b5ef0) · [glm](#example-legacy-0305)
· [global](#example-legacy-0008) ·
[gquantiles](#example-ref-158e868ced40feda) ·
[graph](#example-legacy-0394) ·
[greshape](#example-ref-dcece139fbb03122) ·
[gsort](#example-legacy-0202) · [gstats](#example-ref-59b4ae2cf32059c9)
· [gtoplevelsof](#example-ref-82d88b501faecfca) ·
[gunique](#example-ref-629f627811842fb5) ·
[halfyear](#example-ref-1d9a43054eea05d0) ·
[hashsort](#example-ref-0905accc0f3784cd) ·
[hausman](#example-ref-849eddc244235227) ·
[heatplot](#example-ref-ddd2e9383eb21a10) ·
[heckman](#example-legacy-0324) · [help](#example-legacy-0002) ·
[hetregress](#example-ref-e4b6c14fccc8c48c) ·
[hexdump](#example-ref-570232fd0996bc66) ·
[hh](#example-ref-17f46a3b2bc2ee55) · [histogram](#example-legacy-0384)
· [hotelling](#example-ref-e4415465525a1eef) ·
[hypergeometric](#example-ref-45c9549bcc76cf27) ·
[hypergeometricp](#example-ref-6607de2b22c37756) ·
[ibeta](#example-ref-5d08215988b6faf2) ·
[ibetatail](#example-ref-f83ef193c4abcda1) ·
[icc](#example-ref-0a740ae74df03d49) · [if](#example-legacy-0275) ·
[import](#example-legacy-0017) ·
[include](#example-ref-425204e32bec7c1a) ·
[infile](#example-ref-299f7397650052b9) ·
[infix](#example-ref-5407351358e20a8a) · [inlist](#example-legacy-0165)
· [input](#example-legacy-0220) · [inrange](#example-legacy-0166) ·
[insobs](#example-ref-4b82e73619fe09f5) ·
[inspect](#example-legacy-0059) ·
[intreg](#example-ref-4369e2ccad9e8d3f) ·
[invbinomial](#example-ref-132aa6c600b88f03) ·
[invbinomialtail](#example-ref-bc59ee2e9a87253e) ·
[invcauchy](#example-ref-1e7da01122eba0c2) ·
[invcauchytail](#example-ref-f6437dde18a3cc25) ·
[invchi2](#example-ref-2a448ae96c7604a7) ·
[invchi2tail](#example-ref-23306c7dbf504d73) ·
[invexponential](#example-ref-29514def6e9ecbad) ·
[invexponentialtail](#example-ref-7b571ba451d3e054) ·
[invF](#example-ref-7822f727ce3a3dfe) ·
[invFtail](#example-ref-d4e72ece99ff3f05) ·
[invgammap](#example-ref-2265ddfe6d1a8f29) ·
[invgammaptail](#example-ref-bf84d422d26193ae) ·
[invibeta](#example-ref-8bc4b3768425541a) ·
[invibetatail](#example-ref-88d1fec121a169d0) ·
[invlogistic](#example-ref-62040f03f7fc4986) ·
[invlogistictail](#example-ref-46db3a062f66d769) ·
[invnbinomial](#example-ref-2549a0c3e9f10f22) ·
[invnbinomialtail](#example-ref-e4993aa3c1347631) ·
[invnchi2](#example-ref-047e7eddf232874f) ·
[invnchi2tail](#example-ref-22999e358ff1bb18) ·
[invnF](#example-ref-f415a39bfdae4e2a) ·
[invnFtail](#example-ref-d5ae4af1368a8f05) ·
[invnibeta](#example-ref-d701858fe7a31496) ·
[invnormal](#example-ref-4eca2239aba08a06) ·
[invnt](#example-ref-ce6c456fae75074b) ·
[invnttail](#example-ref-629c712cc666771c) ·
[invpoisson](#example-ref-091c6b49221081eb) ·
[invpoissontail](#example-ref-71dbb4e5e1eacd16) ·
[invt](#example-ref-55897e88e233fdc9) ·
[invttail](#example-ref-195ddf4168a434a9) ·
[invtukeyprob](#example-ref-3b92c66f85f28e14) ·
[invweibull](#example-ref-15301a7064db7033) ·
[invweibullph](#example-ref-0b620d678f158b62) ·
[invweibullphtail](#example-ref-fef1ce0996fe0418) ·
[invweibulltail](#example-ref-6e1bf485cb728222) ·
[ipolate](#example-ref-9726e88cf6c39663) ·
[iqreg](#example-ref-d80ba0949fafd0c5) ·
[ir](#example-ref-fa8295fd9665c707) ·
[irf](#example-ref-592f527a0a4f309e) ·
[iri](#example-ref-f2c0ff5df78a1db2) · [isid](#example-legacy-0089) ·
[istdize](#example-ref-960da5d791be00b1) ·
[ivlpirf](#example-ref-9df372b42d20ac42) ·
[ivreg2](#example-legacy-0351) ·
[ivreghdfe](#example-ref-329f9408437ac4ad) ·
[ivregress](#example-legacy-0294) · [jackknife](#example-legacy-0328) ·
[jdbc](#example-ref-f255f842be63a861) · [joinby](#example-legacy-0214) ·
[kap](#example-ref-9cca470553f93372) · [kdensity](#example-legacy-0385)
· [keep](#example-legacy-0188) · [kmatch](#example-ref-0a73210a9b8f5c6c)
· [ksmirnov](#example-legacy-0076) · [ktau](#example-legacy-0082) ·
[kwallis](#example-legacy-0075) · [l.](#example-legacy-0358) ·
[label](#example-legacy-0099) ·
[labelbook](#example-ref-9ae24151c140e349) ·
[labmask](#example-ref-bbcf56dd34ad234f) ·
[lasso](#example-ref-8337a2996167318e) ·
[levelsof](#example-legacy-0060) · [lincom](#example-legacy-0329) ·
[line](#example-legacy-0388) · [linktest](#example-ref-32f765c0804915c9)
· [list](#example-legacy-0035) · [ln](#example-legacy-0171) ·
[lncauchyden](#example-ref-1fc53e631d2dc942) ·
[lnigammaden](#example-ref-39a51d37765aa3a3) ·
[lnmvnormalden](#example-ref-45ff43a9a6548301) ·
[lnnormal](#example-ref-4c727371373cbbce) ·
[lnnormalden](#example-ref-26a56f0b7235dc00) ·
[local](#example-legacy-0267) · [log](#example-legacy-0013) ·
[logistic](#example-legacy-0307) ·
[logisticden](#example-ref-cb722204d6a14215) ·
[logistictail](#example-ref-7a9b94b0cf3766e6) ·
[logit](#example-legacy-0295) · [lookfor](#example-legacy-0040) ·
[lower](#example-legacy-0228) · [lowess](#example-legacy-0410) ·
[lpirf](#example-ref-fb273f4a13fdbb23) · [lrtest](#example-legacy-0331)
· [ltable](#example-ref-8d2acd0bb58f1da8) ·
[macro](#example-legacy-0285) · [manova](#example-ref-8013012bf24623d0)
· [manovatest](#example-ref-277c2aedaf2f162d) ·
[margins](#example-legacy-0299) · [marginsplot](#example-legacy-0339) ·
[mark](#example-ref-823767d4c80165ac) ·
[markin](#example-ref-b025093a29ec0fc9) ·
[markout](#example-ref-741a39f397969345) ·
[marksample](#example-ref-c43f3f6ae503d480) ·
[matlist](#example-ref-0ed97a436faeb432) ·
[matname](#example-ref-9b3a0ae16d0d625f) ·
[matrix](#example-legacy-0269) · [mca](#example-ref-f7d0d03f2da98b65) ·
[mcc](#example-ref-4011b78651ba1662) ·
[mcci](#example-ref-bc1ec02d2a96af92) · [mdesc](#example-legacy-0097) ·
[mds](#example-ref-80385cf3e8e6af52) ·
[mdsmat](#example-ref-ed7dfa3b1a50c826) · [mdy](#example-legacy-0234) ·
[mean](#example-legacy-0069) ·
[mecloglog](#example-ref-d0a6fbe06f55047d) ·
[median](#example-ref-91a4f93830a14da2) ·
[meglm](#example-ref-42529cfbff20e560) · [melogit](#example-legacy-0323)
· [memory](#example-ref-4eb8c7fc9bda5292) ·
[menbreg](#example-ref-ab81cc1eb1c6107c) ·
[menl](#example-ref-4ef5ffa50f3d7272) ·
[meologit](#example-ref-a3ed08671d69d11a) ·
[meoprobit](#example-ref-aea7c36f245fc934) ·
[mepoisson](#example-ref-d1e95b5ac37e9c54) ·
[meprobit](#example-ref-c2b98ab0b2ba784d) ·
[merge](#example-legacy-0213) · [meta](#example-ref-ec16aab587fbd4e5) ·
[mhodds](#example-ref-d6b7fedb7dcf6ec3) · [mi](#example-legacy-0355) ·
[missing](#example-legacy-0167) ·
[missings](#example-ref-1935ad2e5ccddb4a) ·
[misstable](#example-legacy-0095) · [mixed](#example-legacy-0322) ·
[mkdir](#example-ref-940b90dd6bc69dc6) ·
[mkmat](#example-ref-c63d0c9a4e203226) ·
[mlexp](#example-ref-5826d7aebecb8834) · [mlogit](#example-legacy-0311)
· [mm](#example-ref-da923b546ce233a1) · [mofd](#example-legacy-0236) ·
[month](#example-legacy-0250) · [mvdecode](#example-legacy-0123) ·
[mvencode](#example-legacy-0124) ·
[mvreg](#example-ref-84c8c53fd61de90e) ·
[mvtest](#example-ref-3ecf635c5a04e393) ·
[nbetaden](#example-ref-d59c43dd30954b2f) ·
[nbinomial](#example-ref-12787c749e7717df) ·
[nbinomialp](#example-ref-55d623f908e6e118) ·
[nbinomialtail](#example-ref-640cde916b8f4f61) ·
[nbreg](#example-legacy-0314) · [nchi2](#example-ref-568e3f754132870a) ·
[nchi2den](#example-ref-f39a41d2d1177e93) ·
[nchi2tail](#example-ref-b77aba953ed51020) ·
[nestreg](#example-ref-c0e97b6e48d38b6c) · [net](#example-legacy-0011) ·
[newey](#example-ref-c263eba9cf3fb057) ·
[nF](#example-ref-aa746531f0a8f6c2) ·
[nFden](#example-ref-ff8abb410d9cc40c) ·
[nFtail](#example-ref-52cf941ab80e5328) ·
[nibeta](#example-ref-108f4c14a7573c1b) ·
[nl](#example-ref-3366d57f680bc9fd) · [nlcom](#example-legacy-0330) ·
[normal](#example-ref-34e7210a02898239) ·
[normalden](#example-ref-493740d06c458ca9) ·
[notes](#example-legacy-0107) · [npnchi2](#example-ref-5b19051b8727105b)
· [npnF](#example-ref-6b33380e283b39a7) ·
[npnt](#example-ref-18171672d2eba71f) ·
[nptrend](#example-ref-2a51c04e2be7cab2) ·
[nt](#example-ref-a7067a71f45672d1) ·
[nttail](#example-ref-89a59cfb79facfc9) ·
[numlabel](#example-ref-974c4b4290d3cd19) ·
[numlist](#example-ref-ee709ee97c96908d) ·
[oaxaca](#example-legacy-0352) · [odbc](#example-ref-8a069c1ba83f3321) ·
[ologit](#example-legacy-0312) · [oneway](#example-legacy-0078) ·
[oprobit](#example-legacy-0313) · [order](#example-legacy-0199) ·
[orthog](#example-ref-ea18d45d4423c18a) ·
[orthpoly](#example-ref-8f348a54483f5e1f) ·
[outfile](#example-ref-110e71fab08cf6ec) ·
[outreg2](#example-legacy-0304) · [pac](#example-ref-69101d3864251e9b) ·
[pca](#example-legacy-0083) · [pcamat](#example-ref-00561b34869d95bf) ·
[pchi](#example-ref-e1309be06e0b38b7) ·
[pcorr](#example-ref-ea2329846cf4b268) · [pctile](#example-legacy-0163)
· [pergram](#example-ref-1aeba87728d5d2a3) ·
[permute](#example-ref-292452b3fa489e8a) ·
[pnorm](#example-ref-66218decfce42ae0) · [poisson](#example-legacy-0297)
· [poissonp](#example-ref-fb3fc687b6c00f4e) ·
[poissontail](#example-ref-d013f38f4d1a6908) ·
[post](#example-ref-cb3abc89318d6401) ·
[postclose](#example-ref-28168f8812c6edf8) ·
[postfile](#example-ref-cb7ba85bda9415ad) ·
[power](#example-ref-2ab5891e99093540) ·
[pperron](#example-ref-134445e92b8bcdde) ·
[ppmlhdfe](#example-legacy-0315) · [predict](#example-legacy-0300) ·
[predictnl](#example-ref-6ba8a46966480542) ·
[preserve](#example-legacy-0266) · [probit](#example-legacy-0296) ·
[program](#example-legacy-0276) · [proportion](#example-legacy-0071) ·
[prtest](#example-legacy-0072) ·
[prtesti](#example-ref-971a68a42a649495) ·
[psdensity](#example-ref-35598c46383b3503) ·
[psmatch2](#example-ref-53a32004020d27b2) ·
[pstest](#example-ref-4c2925312c789f88) ·
[putdocx](#example-legacy-0344) · [putexcel](#example-legacy-0343) ·
[putmata](#example-ref-6684c62f17819c10) ·
[pwcompare](#example-ref-04f3796134ebbfd1) ·
[pwcorr](#example-legacy-0056) · [pwd](#example-legacy-0005) ·
[pwmean](#example-ref-100192fe13d36928) ·
[qchi](#example-ref-18e22c71e74519a4) · [qnorm](#example-legacy-0414) ·
[qofd](#example-legacy-0253) · [qqplot](#example-ref-e7a57db3275f2d0a) ·
[qreg](#example-legacy-0317) · [quadchk](#example-ref-747bf4d1e377d4aa)
· [quantile](#example-ref-c6511d2a27e0664d) ·
[quarter](#example-ref-f2d67dbca115eb2c) ·
[query](#example-ref-1b72a7892bf8829e) · [quietly](#example-legacy-0263)
· [range](#example-ref-c02e744164fdca71) ·
[rangestat](#example-ref-d822762c0bd07025) ·
[ranksum](#example-legacy-0073) · [rbeta](#example-ref-cb8ca3ab427ea6ac)
· [rbinomial](#example-ref-15798a0e76780499) ·
[rcauchy](#example-ref-5925b5343b823852) ·
[rchi2](#example-ref-c1b7f09e89c0a3f7) ·
[rdbwdensity](#example-ref-cdd15738a4b9b9ff) ·
[rdbwselect](#example-ref-0cfe29a80d51c9c5) ·
[rddensity](#example-ref-8d3ea81d5f1c5f8d) ·
[rdrobust](#example-legacy-0350) · [real](#example-legacy-0248) ·
[recast](#example-legacy-0176) · [recode](#example-legacy-0121) ·
[regexm](#example-legacy-0232) · [regexr](#example-legacy-0240) ·
[regexreplaceall](#example-ref-3180a833739616f6) ·
[regexs](#example-legacy-0241) · [reghdfe](#example-legacy-0291) ·
[regress](#example-legacy-0286) · [rename](#example-legacy-0147) ·
[replace](#example-legacy-0117) ·
[require](#example-ref-7d724937622b3a10) ·
[reshape](#example-legacy-0217) · [return](#example-legacy-0270) ·
[rexponential](#example-ref-335a8ccbcaa08605) ·
[rgamma](#example-ref-3eec6ff20c19f0fa) ·
[rhypergeometric](#example-ref-72b9b4fe3caddb63) ·
[rlogistic](#example-ref-e7da942016a97878) ·
[rnbinomial](#example-ref-13701f5a2c3804ad) ·
[rnormal](#example-legacy-0173) ·
[robvar](#example-ref-d1a36a4376db7a4c) ·
[roccomp](#example-ref-a6b32c1f12a34322) ·
[roctab](#example-ref-5f3c4419e9cf6bb5) ·
[rolling](#example-ref-f86c4fb2477d2861) ·
[rotate](#example-ref-57abd3ee75ad1365) ·
[rotatemat](#example-ref-d057cc0c8f5645a8) ·
[round](#example-legacy-0168) ·
[rpoisson](#example-ref-5835c9b273303fb4) · [rreg](#example-legacy-0318)
· [rt](#example-ref-bca4be437ce650c1) · [runiform](#example-legacy-0172)
· [runtest](#example-ref-31aea2abde6b1b1b) ·
[rvfplot](#example-legacy-0337) ·
[rweibull](#example-ref-71658cc974a85630) ·
[sample](#example-legacy-0194) · [save](#example-legacy-0016) ·
[saveold](#example-legacy-0024) ·
[savespss](#example-ref-c958d73ab7ce288a) ·
[scalar](#example-legacy-0268) · [scatter](#example-legacy-0386) ·
[sdtest](#example-ref-369f819a9cc899ad) ·
[sdtesti](#example-ref-62db53b564979db2) ·
[search](#example-legacy-0003) · [sem](#example-legacy-0325) ·
[separate](#example-ref-9b5a6a090f018366) ·
[seqvar](#example-ref-e7cd72235c2f1ab0) ·
[serrbar](#example-ref-cc86d859adef517e) · [set](#example-legacy-0223) ·
[setroot](#example-ref-5fa741cf1efb1145) ·
[signrank](#example-legacy-0074) ·
[signtest](#example-ref-d2ef77a797833590) ·
[simulate](#example-ref-f000b6233d328ef1) ·
[sktest](#example-legacy-0080) · [sleep](#example-ref-347c05e27d4a8c6f)
· [slogit](#example-ref-eaee6997697c7cbc) ·
[snapshot](#example-ref-04718cc77dd9cfad) ·
[snapspan](#example-ref-31814126170a334b) · [sort](#example-legacy-0201)
· [spbalance](#example-ref-5c3c72f689513489) ·
[spdistance](#example-ref-795bba6a282d3068) ·
[spearman](#example-legacy-0081) ·
[spgenerate](#example-ref-75c2687c067f701d) ·
[spikeplot](#example-ref-fc39728e9d21f5a9) ·
[split](#example-legacy-0224) ·
[splitsample](#example-ref-5c02eb8f80e1b4fe) ·
[spmatrix](#example-ref-d005116dfc53403e) ·
[spset](#example-ref-f42e291471b5d648) ·
[sqreg](#example-ref-76ede023c9cb991d) ·
[ss](#example-ref-47fb0cf6376ca362) · [ssc](#example-legacy-0010) ·
[sspace](#example-ref-8d75a52acc4b187c) ·
[stack](#example-ref-8a476a86b491d87a) ·
[stbase](#example-ref-5866bbda3af7c890) ·
[stci](#example-ref-c991df924cd85d00) · [stcox](#example-legacy-0373) ·
[stcrreg](#example-ref-d32aa6f87266a052) ·
[stdescribe](#example-ref-c06f9546907b38cc) ·
[stem](#example-legacy-0085) · [stfill](#example-ref-3db32b86e08b395a) ·
[stgen](#example-ref-bb94f4e07e9e63b4) ·
[stintreg](#example-ref-d8f682d3518d22a9) ·
[stir](#example-ref-da237ea7b237b598) ·
[stjoin](#example-ref-a33964a40512a701) ·
[stmh](#example-ref-5b93282a74b798ee) ·
[stptime](#example-ref-c96e0fe130d42704) ·
[strate](#example-ref-50a7cfbc2ffb51d6) · [streg](#example-legacy-0374)
· [string](#example-legacy-0247) · [stritrim](#example-legacy-0243) ·
[strlen](#example-legacy-0226) · [strlower](#example-legacy-0245) ·
[strltrim](#example-ref-ac30ece96a229828) ·
[strmatch](#example-legacy-0239) ·
[strofreal](#example-ref-d14d31d3ca3d7a5a) ·
[strpos](#example-legacy-0231) · [strproper](#example-legacy-0246) ·
[strreverse](#example-ref-ac8f1b95baecfda6) ·
[strrtrim](#example-ref-1bed474169e0c6f3) ·
[strtoname](#example-legacy-0249) · [strtrim](#example-legacy-0229) ·
[strupper](#example-legacy-0244) · [sts](#example-legacy-0370) ·
[stset](#example-legacy-0369) · [stsplit](#example-ref-694387b841854205)
· [stsum](#example-legacy-0372) ·
[sttocc](#example-ref-6c287486746d0e63) ·
[stvary](#example-ref-1f3dff5a6980ef06) ·
[subinstr](#example-legacy-0230) ·
[subinword](#example-ref-7ad4f2a57dc3d8ff) ·
[substr](#example-legacy-0225) · [sum](#example-legacy-0174) ·
[summarize](#example-legacy-0049) ·
[svmat](#example-ref-d3ad44b694c800ff) · [svy](#example-legacy-0382) ·
[svydescribe](#example-legacy-0383) · [svyset](#example-legacy-0375) ·
[swilk](#example-legacy-0079) ·
[symmetry](#example-ref-c5bd5ba8110f2331) ·
[symmi](#example-ref-3e8e8436fa6d7ab5) ·
[symplot](#example-ref-08d9644a14ecf21f) ·
[syntax](#example-ref-1867eb9b570fd41c) · [synth](#example-legacy-0347)
· [sysdir](#example-ref-619219fe706ceedc) ·
[sysuse](#example-legacy-0014) · [t](#example-ref-2c8dfd0861f66dbe) ·
[tab1](#example-legacy-0046) · [tab2](#example-legacy-0047) ·
[tabdisp](#example-ref-613de86151d0da19) ·
[tabi](#example-ref-482f72657e4e651d) · [table](#example-legacy-0048) ·
[tabodds](#example-ref-21bed840be991c43) ·
[tabstat](#example-legacy-0054) · [tabulate](#example-legacy-0041) ·
[tden](#example-ref-6c0d2103e6560270) ·
[tebalance](#example-ref-6098501e134d0ad0) ·
[teffects](#example-legacy-0346) · [tempfile](#example-legacy-0277) ·
[tempname](#example-ref-33cc8179ec0b57f9) ·
[tempvar](#example-ref-e1c643750656e4eb) ·
[teoverlap](#example-ref-87c306b9b17d38f5) ·
[test](#example-legacy-0301) · [testnl](#example-ref-51b76f52f1a7e87b) ·
[testparm](#example-ref-15d8dd807370dfdb) ·
[tetrachoric](#example-ref-e33b588e542040ae) ·
[timer](#example-legacy-0264) · [tnbreg](#example-ref-cb5be76f35c4800e)
· [tobit](#example-legacy-0316) ·
[tokenize](#example-ref-03148a8fd16fa3db) ·
[tostring](#example-legacy-0126) ·
[tpoisson](#example-ref-35a02cec2e6b343c) ·
[truncreg](#example-ref-bc01c31505cf0bae) ·
[tsfill](#example-legacy-0361) ·
[tsfilter](#example-ref-a5666a86424fa0cb) ·
[tsline](#example-legacy-0365) ·
[tsreport](#example-ref-e1438dc0fe5915ab) ·
[tsset](#example-legacy-0357) ·
[tssmooth](#example-ref-33a54a664dcb3b5c) ·
[ttail](#example-ref-58b924c8549fe950) · [ttest](#example-legacy-0057) ·
[ttesti](#example-ref-8b8cb56788a07c6b) ·
[tukeyprob](#example-ref-74a6ded8a34ca5c1) ·
[twoway](#example-legacy-0387) · [type](#example-ref-9bd4a676836d685e) ·
[uchar](#example-ref-8ea85e98a28b243d) ·
[ucm](#example-ref-9a05479152f579ab) ·
[unab](#example-ref-7f04a5c9610c898b) ·
[unabcmd](#example-ref-f1bbecbe3e5fff51) ·
[unicode](#example-ref-f3aad7aba2426d06) ·
[univar](#example-legacy-0086) ·
[unzipfile](#example-ref-f730ec25c59382ea) ·
[upper](#example-legacy-0227) · [use](#example-legacy-0015) ·
[uselabel](#example-ref-3921423a80b9f77f) ·
[ustrlen](#example-ref-946f3a4fc7de2910) ·
[ustrlower](#example-ref-46e23458f84bbc78) ·
[ustrnormalize](#example-ref-c7b1583303e68cd6) ·
[ustrpos](#example-ref-4ec683ff95289a09) ·
[ustrregexm](#example-legacy-0242) ·
[ustrregexra](#example-ref-d5e9bc5125404ac3) ·
[ustrregexrf](#example-ref-386b6c2051d068ac) ·
[ustrreverse](#example-ref-442cf2085f4203fc) ·
[ustrtrim](#example-ref-4f6e98f172095152) ·
[ustrupper](#example-ref-f91c75ef080a017f) ·
[usubstr](#example-ref-d47f29ab29981da8) ·
[var](#example-ref-8f02be90201f1e4e) ·
[vargranger](#example-ref-94e1922bc712c2c6) ·
[varstable](#example-ref-93d64f94da919caf) ·
[vec](#example-ref-bbbcf1999b7d4690) ·
[vecrank](#example-ref-fb30ad57d9775ab7) ·
[version](#example-legacy-0283) ·
[viewsource](#example-ref-038adf093f5242cf) ·
[vif](#example-legacy-0336) · [vioplot](#example-legacy-0413) ·
[webuse](#example-legacy-0022) ·
[weibull](#example-ref-e2ad271bf6f94743) ·
[weibullden](#example-ref-b79b1421fb3736cf) ·
[weibullph](#example-ref-957fce2fdbb35508) ·
[weibullphden](#example-ref-dd1263bfd19e51b1) ·
[weibullphtail](#example-ref-5bd302d64d25b22c) ·
[weibulltail](#example-ref-25783014442f5646) ·
[which](#example-legacy-0281) · [while](#example-legacy-0274) ·
[winsor2](#example-legacy-0146) ·
[wntestq](#example-ref-78b116fdd30db59f) · [word](#example-legacy-0237)
· [wordcount](#example-legacy-0238) ·
[xcorr](#example-ref-a889809845041fa7) ·
[xi](#example-ref-3eaf87d97050c2ee) · [xpose](#example-legacy-0219) ·
[xtabond](#example-legacy-0353) ·
[xtcloglog](#example-ref-e72403fd36b09037) ·
[xtdescribe](#example-legacy-0363) ·
[xtdidregress](#example-ref-9187913ae8c6e442) ·
[xtdpd](#example-ref-d063a9405a644477) ·
[xtdpdsys](#example-ref-5ba7ff3d04cd454a) ·
[xtgee](#example-ref-7d7024ac875212b5) ·
[xtgls](#example-ref-00689fe1f837a48c) ·
[xthtaylor](#example-ref-72ab0af4ff2a84a8) ·
[xtile](#example-legacy-0127) · [xtivreg](#example-ref-b6cdab2ddbd2971c)
· [xtline](#example-legacy-0366) · [xtlogit](#example-legacy-0320) ·
[xtologit](#example-ref-4db4e340590ce0fa) ·
[xtoprobit](#example-ref-1135e689d167643c) ·
[xtpcse](#example-ref-cdfe1eb8bf691f28) ·
[xtpoisson](#example-legacy-0321) ·
[xtprobit](#example-ref-4af1cc8acfc0c5c8) ·
[xtrc](#example-ref-4184d867c9dce07d) · [xtreg](#example-legacy-0292) ·
[xtregar](#example-ref-9e3a49ccc57538be) ·
[xtscc](#example-ref-5a91f4289759015f) · [xtset](#example-legacy-0356) ·
[xtsum](#example-legacy-0364) · [xttest0](#example-ref-528a9ec17d19d485)
· [xtunitroot](#example-ref-22005312f4439688) ·
[year](#example-legacy-0235) · [ym](#example-ref-992f7b07dfe04842) ·
[yq](#example-ref-7267ebf1f3634d6d) ·
[zinb](#example-ref-b01e3debe4ced886) ·
[zip](#example-ref-602a2595a5e31ca9) ·
[zipfile](#example-ref-bd63f95928bd68cd) ·
[ztest](#example-ref-3005afe7687130b7) ·
[ztesti](#example-ref-568b5f87c5a703e6)

## Basics

[TABLE]

## Explore data

[TABLE]

## Check data

[TABLE]

## Labels

[TABLE]

## Construct and modify variables

[TABLE]

## Select variables and rows

[TABLE]

## Sort

[TABLE]

## Combine data

[TABLE]

## Reshape

[TABLE]

## Construct data

[TABLE]

## Strings and dates

[TABLE]

## Loops and programming

[TABLE]

## Models and tables

[TABLE]

## Panel and time series

[TABLE]

## Survival analysis

[TABLE]

## Survey data

[TABLE]

## Graphs

[TABLE]

## Programming utilities

[TABLE]

## Data management

[TABLE]

## Files and import/export

[TABLE]

## Labels and metadata

[TABLE]

## Descriptive tables

[TABLE]

## Models and tests

[TABLE]

## Statistical distributions

[TABLE]

## Models and estimation

[TABLE]

## Postestimation and diagnostics

[TABLE]

## Hypothesis tests and confidence intervals

[TABLE]

## Multivariate and psychometric methods

[TABLE]

## Power and precision planning

[TABLE]

## Resampling and simulation

[TABLE]

## Model reporting

[TABLE]

## Spatial workflows

[TABLE]

## Causal inference

[TABLE]

## Panel data

[TABLE]

## Time series and forecasting

[TABLE]

## Complex survey analysis

[TABLE]

## Meta-analysis

[TABLE]

## Multiple imputation

[TABLE]

## Multilevel models

[TABLE]

## Epidemiology

[TABLE]

## Bayesian analysis

[TABLE]

## R functions by package

| R | Package | Stata | Description |
|----|----|----|----|
| `ivreg()` | AER | ivregress | Instrumental-Variable Regression |
| `tobit()` | AER |  | Tobit (censored) regression |
| [`.libPaths()`](https://rdrr.io/r/base/libPaths.html) | base | adopath | Search Paths for Packages |
| [`abs()`](https://rdrr.io/r/base/MathFun.html) | base | abs() | Absolute value |
| [`all()`](https://rdrr.io/r/base/all.html) | base | assert | Whether all values are TRUE |
| [`any()`](https://rdrr.io/r/base/any.html) | base | count if | Whether any value is TRUE |
| [`anyDuplicated()`](https://rdrr.io/r/base/duplicated.html) | base | gisid | Determine Duplicate Elements |
| [`anyNA()`](https://rdrr.io/r/base/NA.html) | base | gisid | Not Available / Missing Values |
| [`apply()`](https://rdrr.io/r/base/apply.html) | base | egen rowtotal() | Apply a function over rows or columns |
| [`as.character()`](https://rdrr.io/r/base/character.html) | base |  | Convert to text |
| [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) | base | getmata | Coerce to a Data Frame |
| [`as.Date()`](https://rdrr.io/r/base/as.Date.html) | base |  | Convert to a date |
| [`as.double()`](https://rdrr.io/r/base/double.html) | base |  | Convert to double-precision numbers |
| [`as.factor()`](https://rdrr.io/r/base/factor.html) | base | encode | Convert to a factor |
| [`as.integer()`](https://rdrr.io/r/base/integer.html) | base |  | Convert to whole numbers |
| [`as.matrix()`](https://rdrr.io/r/base/matrix.html) | base | cf | Matrices |
| [`as.numeric()`](https://rdrr.io/r/base/numeric.html) | base |  | Convert to numbers |
| [`as.POSIXct()`](https://rdrr.io/r/base/as.POSIXlt.html) | base | clock | Date-time Conversion Functions |
| [`as.vector()`](https://rdrr.io/r/base/vector.html) | base | margins | Vectors - Creation, Coercion, etc |
| [`attr()`](https://rdrr.io/r/base/attr.html) | base |  | Get or set an attribute of an object |
| [`attributes()`](https://rdrr.io/r/base/attributes.html) | base | char | Object Attribute Lists |
| [`body()`](https://rdrr.io/r/base/body.html) | base | viewsource | Access to and Manipulation of the Body of a Function |
| [`c()`](https://rdrr.io/r/base/c.html) | base |  | Combine values into a vector |
| [`cat()`](https://rdrr.io/r/base/cat.html) | base |  | Print text without quotes |
| [`cbind()`](https://rdrr.io/r/base/cbind.html) | base | merge 1:1 \_n | Put side by side (base R) |
| [`ceiling()`](https://rdrr.io/r/base/Round.html) | base |  | Round up |
| [`character()`](https://rdrr.io/r/base/character.html) | base | tokenize | Character Vectors |
| [`charToRaw()`](https://rdrr.io/r/base/rawConversion.html) | base | changeeol | Convert to or from (Bit/Packed) Raw Vectors |
| [`chol()`](https://rdrr.io/r/base/chol.html) | base | irf | The Cholesky Decomposition |
| [`class()`](https://rdrr.io/r/base/class.html) | base | describe | Class of an object |
| [`close()`](https://rdrr.io/r/base/connections.html) | base | file | Functions to Manipulate Connections (Files, URLs, ...) |
| [`col()`](https://rdrr.io/r/base/col.html) | base | spmatrix | Column Indexes |
| [`colMeans()`](https://rdrr.io/r/base/colSums.html) | base | margins | Form Row and Column Sums and Means |
| [`colnames()`](https://rdrr.io/r/base/colnames.html) | base | ds | Column names |
| [`colSums()`](https://rdrr.io/r/base/colSums.html) | base | missings | Form Row and Column Sums and Means |
| [`crossprod()`](https://rdrr.io/r/base/crossprod.html) | base | tsfilter | Matrix Cross-Product |
| [`cumprod()`](https://rdrr.io/r/base/cumsum.html) | base | generate | Running product |
| [`cumsum()`](https://rdrr.io/r/base/cumsum.html) | base |  | Running sum |
| [`cut()`](https://socimh.github.io/tidystata/reference/cut.md) | base |  | Cut numbers into intervals |
| [`data.frame()`](https://rdrr.io/r/base/data.frame.html) | base | range | Data Frames |
| [`diag()`](https://rdrr.io/r/base/diag.html) | base |  | Diagonal of a matrix |
| [`diff()`](https://rdrr.io/r/base/diff.html) | base | D. | Differences between neighbouring values |
| [`dim()`](https://rdrr.io/r/base/dim.html) | base | describe | Numbers of rows and columns |
| [`dir()`](https://rdrr.io/r/base/list.files.html) | base |  | List files in a folder |
| [`dir.create()`](https://rdrr.io/r/base/files2.html) | base | mkdir | Create a folder |
| [`do.call()`](https://rdrr.io/r/base/do.call.html) | base | program | Call a function with a list of arguments |
| [`double()`](https://rdrr.io/r/base/double.html) | base | postfile | Double-Precision Vectors |
| [`dput()`](https://rdrr.io/r/base/dput.html) | base | dataex | Write an Object to a File or Recreate it |
| [`drop()`](https://rdrr.io/r/base/drop.html) | base | lincom | Drop Redundant Extent Information |
| [`droplevels()`](https://rdrr.io/r/base/droplevels.html) | base | label define | Drop unused factor levels |
| [`duplicated()`](https://rdrr.io/r/base/duplicated.html) | base | gegen | Determine Duplicate Elements |
| [`eigen()`](https://rdrr.io/r/base/eigen.html) | base | varstable | Spectral Decomposition of a Matrix |
| [`environment()`](https://rdrr.io/r/base/environment.html) | base | include | Environment Access |
| [`exp()`](https://rdrr.io/r/base/Log.html) | base | exp() | Exponential |
| [`expand.grid()`](https://rdrr.io/r/base/expand.grid.html) | base | arimasoc | Create a Data Frame from All Combinations of Factor Variables |
| [`factor()`](https://rdrr.io/r/base/factor.html) | base |  | Categorical variable with labelled levels |
| [`file()`](https://rdrr.io/r/base/connections.html) | base | file | Functions to Manipulate Connections (Files, URLs, ...) |
| [`file.copy()`](https://rdrr.io/r/base/files.html) | base | copy | File Manipulation |
| [`file.exists()`](https://rdrr.io/r/base/files.html) | base | confirm file | Whether a file exists |
| [`file.info()`](https://rdrr.io/r/base/file.info.html) | base | hexdump | Extract File Information |
| [`file.path()`](https://rdrr.io/r/base/file.path.html) | base | global path | Build a file path |
| [`floor()`](https://rdrr.io/r/base/Round.html) | base |  | Round down |
| [`format()`](https://rdrr.io/r/base/format.html) | base |  | Format values for display |
| [`formatC()`](https://rdrr.io/r/base/formatc.html) | base | string(x, "%9.2f") | Format numbers with width and padding |
| [`getwd()`](https://rdrr.io/r/base/getwd.html) | base |  | Show the working directory |
| [`grep()`](https://rdrr.io/r/base/grep.html) | base | unab | Pattern Matching and Replacement |
| [`grepl()`](https://rdrr.io/r/base/grep.html) | base |  | Whether text matches a pattern |
| [`gsub()`](https://rdrr.io/r/base/grep.html) | base | subinstr() | Replace every match |
| [`I()`](https://rdrr.io/r/base/AsIs.html) | base | regress | Inhibit Interpretation/Conversion of Objects |
| [`iconv()`](https://rdrr.io/r/base/iconv.html) | base | unicode | Convert Character Vector between Encodings |
| [`identical()`](https://rdrr.io/r/base/identical.html) | base | cf | Test Objects for Exact Equality |
| [`ifelse()`](https://rdrr.io/r/base/ifelse.html) | base | cond() | Vectorised if-else (base R) |
| [`integer()`](https://rdrr.io/r/base/integer.html) | base | gdistinct | Integer Vectors |
| [`interaction()`](https://rdrr.io/r/base/interaction.html) | base | egen group() | Combine factors into one |
| [`invisible()`](https://rdrr.io/r/base/invisible.html) | base | exit | Change the Print Mode to Invisible |
| [`is.character()`](https://rdrr.io/r/base/character.html) | base | confirm string variable | Whether a vector holds text |
| [`is.infinite()`](https://rdrr.io/r/base/is.finite.html) | base | gencohort | Finite, Infinite and NaN Numbers |
| [`is.na()`](https://rdrr.io/r/base/NA.html) | base |  | Whether values are missing |
| [`is.nan()`](https://rdrr.io/r/base/is.finite.html) | base | egen | Finite, Infinite and NaN Numbers |
| [`is.numeric()`](https://rdrr.io/r/base/numeric.html) | base | confirm numeric variable | Whether a vector holds numbers |
| [`lapply()`](https://rdrr.io/r/base/lapply.html) | base | foreach | Apply a function to each element, returning a list |
| [`length()`](https://rdrr.io/r/base/length.html) | base | count | Number of elements |
| [`lengths()`](https://rdrr.io/r/base/lengths.html) | base | wordcount | Lengths of List or Vector Elements |
| [`levels()`](https://rdrr.io/r/base/levels.html) | base |  | Categories of a factor |
| [`library()`](https://rdrr.io/r/base/library.html) | base | ssc install | Attach a package |
| [`list()`](https://rdrr.io/r/base/list.html) | base |  | A list of objects |
| [`list.files()`](https://rdrr.io/r/base/list.files.html) | base | dir | Files in a folder |
| [`load()`](https://rdrr.io/r/base/load.html) | base | use | Load objects from an .RData file |
| [`local()`](https://rdrr.io/r/base/eval.html) | base | tempvar | Evaluate an (Unevaluated) Expression |
| [`log()`](https://rdrr.io/r/base/Log.html) | base |  | Logarithm (natural by default) |
| [`log10()`](https://rdrr.io/r/base/Log.html) | base | log10() | Base-10 logarithm |
| [`logical()`](https://rdrr.io/r/base/logical.html) | base | missings | Logical Vectors |
| [`ls()`](https://rdrr.io/r/base/ls.html) | base |  | List objects in memory |
| [`make.names()`](https://rdrr.io/r/base/make.names.html) | base |  | Turn text into valid names |
| [`mapply()`](https://rdrr.io/r/base/mapply.html) | base | arimasoc | Apply a Function to Multiple List or Vector Arguments |
| [`match()`](https://rdrr.io/r/base/match.html) | base | rename | Value Matching |
| [`match.arg()`](https://rdrr.io/r/base/match.arg.html) | base | unabcmd | Argument Verification Using Partial Matching |
| [`matrix()`](https://rdrr.io/r/base/matrix.html) | base |  | Create a matrix |
| [`max()`](https://rdrr.io/r/base/Extremes.html) | base |  | Largest value |
| [`mean()`](https://rdrr.io/r/base/mean.html) | base |  | Mean |
| [`merge()`](https://rdrr.io/r/base/merge.html) | base | merge | Merge two data frames (base R) |
| [`message()`](https://rdrr.io/r/base/message.html) | base | display | Print a message |
| [`min()`](https://rdrr.io/r/base/Extremes.html) | base |  | Smallest value |
| [`Mod()`](https://rdrr.io/r/base/complex.html) | base | psdensity | Complex Numbers and Basic Functionality |
| [`names()`](https://socimh.github.io/tidystata/reference/names.md) | base |  | Names of an object, such as column names |
| [`nchar()`](https://rdrr.io/r/base/nchar.html) | base | strlen() | Number of characters |
| [`ncol()`](https://rdrr.io/r/base/nrow.html) | base | describe | Number of columns |
| [`nlevels()`](https://rdrr.io/r/base/nlevels.html) | base | levelsof | Number of factor levels |
| [`normalizePath()`](https://rdrr.io/r/base/normalizePath.html) | base | findfile | Express File Paths in Canonical Form |
| [`nrow()`](https://rdrr.io/r/base/nrow.html) | base |  | Number of rows |
| [`numeric()`](https://rdrr.io/r/base/numeric.html) | base | rangestat | Numeric Vectors |
| [`options()`](https://rdrr.io/r/base/options.html) | base | set | Set global options |
| [`order()`](https://rdrr.io/r/base/order.html) | base | sort | Positions that would sort a vector |
| [`paste()`](https://rdrr.io/r/base/paste.html) | base |  | Join text with a separator |
| [`paste0()`](https://rdrr.io/r/base/paste.html) | base |  | Join text without a separator |
| [`plot()`](https://rdrr.io/r/graphics/plot.default.html) | base |  | Basic plot |
| [`pmatch()`](https://rdrr.io/r/base/pmatch.html) | base | unab | Partial String Matching |
| [`pmax()`](https://rdrr.io/r/base/Extremes.html) | base | max(a, b) | Element-wise maximum of several vectors |
| [`pmin()`](https://rdrr.io/r/base/Extremes.html) | base | min(a, b) | Element-wise minimum of several vectors |
| [`print()`](https://rdrr.io/r/base/print.html) | base |  | Print an object |
| [`prop.table()`](https://rdrr.io/r/base/proportions.html) | base |  | Turn counts into proportions |
| [`proportions()`](https://rdrr.io/r/base/proportions.html) | base | tabulate, row | Turn a table into proportions |
| [`qr()`](https://rdrr.io/r/base/qr.html) | base | orthog | The QR Decomposition of a Matrix |
| [`qr.Q()`](https://rdrr.io/r/base/qraux.html) | base | orthog | Reconstruct the Q, R, or X Matrices from a QR Object |
| [`R.home()`](https://rdrr.io/r/base/Rhome.html) | base | sysdir | Return the R Home Directory |
| [`range()`](https://rdrr.io/r/base/range.html) | base | summarize | Minimum and maximum |
| [`rank()`](https://rdrr.io/r/base/rank.html) | base |  | Ranks, with ties averaged |
| [`rbind()`](https://rdrr.io/r/base/cbind.html) | base | append | Stack rows (base R) |
| [`readBin()`](https://rdrr.io/r/base/readBin.html) | base | hexdump | Transfer Binary Data To and From Connections |
| [`readLines()`](https://rdrr.io/r/base/readLines.html) | base | changeeol | Read Text Lines from a Connection |
| [`readRDS()`](https://rdrr.io/r/base/readRDS.html) | base | use | Read an R object file (.rds) |
| [`regexpr()`](https://rdrr.io/r/base/grep.html) | base | strpos | Pattern Matching and Replacement |
| [`rep()`](https://rdrr.io/r/base/rep.html) | base | expand | Repeat values |
| [`rep_len()`](https://rdrr.io/r/base/rep.html) | base |  | Repeat values to a given length |
| [`replace()`](https://rdrr.io/r/base/replace.html) | base | generate | Replace Values in a Vector |
| [`replicate()`](https://rdrr.io/r/base/lapply.html) | base | bootstrap | Apply a Function over a List or Vector |
| [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html) | base | ftools | Loading and Unloading Name Spaces |
| [`return()`](https://rdrr.io/r/base/function.html) | base | exit | Function Definition |
| [`rev()`](https://rdrr.io/r/base/rev.html) | base | gsort | Reverse the order |
| [`rm()`](https://rdrr.io/r/base/rm.html) | base |  | Remove objects from memory |
| [`round()`](https://rdrr.io/r/base/Round.html) | base |  | Round to a number of decimals |
| [`row()`](https://rdrr.io/r/base/row.html) | base | spmatrix | Row Indexes |
| [`rowMeans()`](https://rdrr.io/r/base/colSums.html) | base | egen | Form Row and Column Sums and Means |
| [`rowSums()`](https://rdrr.io/r/base/colSums.html) | base |  | Sum across columns in each row |
| [`sample()`](https://rdrr.io/r/base/sample.html) | base | sample | Random sample of values |
| [`sample.int()`](https://rdrr.io/r/base/sample.html) | base | bsample | Random Samples and Permutations |
| [`sapply()`](https://rdrr.io/r/base/lapply.html) | base | foreach | Apply a function to each element and simplify |
| [`save()`](https://rdrr.io/r/base/save.html) | base | save | Save objects to an .RData file |
| [`saveRDS()`](https://rdrr.io/r/base/readRDS.html) | base |  | Save one R object to a file |
| [`scale()`](https://rdrr.io/r/base/scale.html) | base | egen std() | Standardise columns |
| [`scan()`](https://rdrr.io/r/base/scan.html) | base | tokenize | Read Data Values |
| [`seq()`](https://rdrr.io/r/base/seq.html) | base |  | Sequence of numbers |
| [`seq_along()`](https://rdrr.io/r/base/seq.html) | base | \_n | Positions of the elements of a vector |
| [`seq_len()`](https://rdrr.io/r/base/seq.html) | base | \_n | Whole numbers from 1 to n |
| [`serialize()`](https://rdrr.io/r/base/serialize.html) | base | datasignature | Simple Serialization Interface |
| [`set.seed()`](https://rdrr.io/r/base/Random.html) | base |  | Make random numbers reproducible |
| [`setwd()`](https://rdrr.io/r/base/getwd.html) | base |  | Change the working directory |
| [`sign()`](https://rdrr.io/r/base/sign.html) | base | compare | Sign Function |
| [`signif()`](https://rdrr.io/r/base/Round.html) | base | round() | Round to significant digits |
| [`sin()`](https://rdrr.io/r/base/Trig.html) | base | tsfilter | Trigonometric Functions |
| [`sink()`](https://rdrr.io/r/base/sink.html) | base |  | Send console output to a file |
| [`solve()`](https://rdrr.io/r/base/solve.html) | base | estat | Solve a System of Equations |
| [`sort()`](https://rdrr.io/r/base/sort.html) | base |  | Sort a vector |
| [`source()`](https://rdrr.io/r/base/source.html) | base |  | Run an R script |
| [`split()`](https://rdrr.io/r/base/split.html) | base | by | Split data into groups |
| [`sprintf()`](https://rdrr.io/r/base/sprintf.html) | base |  | Format numbers and text with a template |
| [`sqrt()`](https://rdrr.io/r/base/MathFun.html) | base |  | Square root |
| [`stop()`](https://rdrr.io/r/base/stop.html) | base | exit 198 | Stop with an error |
| [`stopifnot()`](https://rdrr.io/r/base/stopifnot.html) | base |  | Stop if a condition is not TRUE |
| [`strsplit()`](https://rdrr.io/r/base/strsplit.html) | base | split | Split strings |
| [`sub()`](https://rdrr.io/r/base/grep.html) | base | regexr() | Replace the first match |
| [`subset()`](https://rdrr.io/r/base/subset.html) | base | keep if | Rows meeting a condition (base R) |
| [`substr()`](https://rdrr.io/r/base/substr.html) | base | substr() | Part of a string by position |
| [`sum()`](https://rdrr.io/r/base/sum.html) | base |  | Sum |
| [`summary()`](https://rdrr.io/r/base/summary.html) | base |  | Summary of an object, such as a model |
| [`Sys.Date()`](https://rdrr.io/r/base/Sys.time.html) | base |  | Today's date |
| [`Sys.sleep()`](https://rdrr.io/r/base/Sys.sleep.html) | base | sleep | Suspend Execution for a Time Interval |
| [`sys.source()`](https://rdrr.io/r/base/sys.source.html) | base | include | Parse and Evaluate Expressions from a File |
| [`Sys.time()`](https://rdrr.io/r/base/Sys.time.html) | base | c(current_time) | Current date and time |
| [`t()`](https://rdrr.io/r/base/t.html) | base |  | Transpose a matrix |
| [`table()`](https://rdrr.io/r/base/table.html) | base |  | Count values |
| [`tapply()`](https://rdrr.io/r/base/tapply.html) | base | bysort g: egen | Apply a function within groups |
| [`tempdir()`](https://rdrr.io/r/base/tempfile.html) | base | sysdir | Create Names for Temporary Files |
| [`tempfile()`](https://rdrr.io/r/base/tempfile.html) | base |  | Name for a temporary file |
| [`tolower()`](https://rdrr.io/r/base/chartr.html) | base | strlower() | Lower case |
| [`toupper()`](https://rdrr.io/r/base/chartr.html) | base | strupper() | Upper case |
| [`traceback()`](https://rdrr.io/r/base/traceback.html) | base |  | Show where the last error happened |
| [`transform()`](https://rdrr.io/r/base/transform.html) | base | expandcl | Transform an Object, for Example a Data Frame |
| [`trimws()`](https://rdrr.io/r/base/trimws.html) | base | strtrim() | Remove leading and trailing spaces |
| [`trunc()`](https://rdrr.io/r/base/Round.html) | base | int() | Drop the decimals |
| [`try()`](https://rdrr.io/r/base/try.html) | base | capture | Run code and continue after an error |
| [`tryCatch()`](https://rdrr.io/r/base/conditions.html) | base | capture | Handle errors and warnings |
| [`typeof()`](https://rdrr.io/r/base/typeof.html) | base | describe | Storage type |
| [`unclass()`](https://rdrr.io/r/base/class.html) | base | rotate | Object Classes |
| [`unique()`](https://rdrr.io/r/base/unique.html) | base |  | Distinct values |
| [`unname()`](https://rdrr.io/r/base/unname.html) | base | cf | Remove names or dimnames |
| [`unsplit()`](https://rdrr.io/r/base/split.html) | base | permute | Divide into Groups and Reassemble |
| [`vapply()`](https://rdrr.io/r/base/lapply.html) | base | gdistinct | Apply a Function over a List or Vector |
| [`vector()`](https://rdrr.io/r/base/vector.html) | base | irf | Vectors - Creation, Coercion, etc |
| [`warning()`](https://rdrr.io/r/base/warning.html) | base | display as error | Give a warning |
| [`which()`](https://rdrr.io/r/base/which.html) | base | list if | Positions where a condition is TRUE |
| [`with()`](https://rdrr.io/r/base/with.html) | base |  | Evaluate code with the columns of a data frame |
| [`writeBin()`](https://rdrr.io/r/base/readBin.html) | base | changeeol | Transfer Binary Data To and From Connections |
| [`writeLines()`](https://rdrr.io/r/base/writeLines.html) | base | checksum | Write Lines to a Connection |
| [`xor()`](https://rdrr.io/r/base/Logic.html) | base | egen | Logical Operators |
| `betareg()` | betareg | betareg | Beta Regression for Rates and Proportions |
| `binsreg()` | binsreg |  | Binned scatter plot and estimation |
| `boot()` | boot | centile | Bootstrap Resampling |
| `boot.ci()` | boot | centile | Nonparametric Bootstrap Confidence Intervals |
| `augment()` | broom | predict | Add fitted values and residuals to the data |
| `glance()` | broom |  | One-row summary of model statistics |
| `tidy()` | broom |  | Coefficient table as a data frame |
| `Anova()` | car | anova | Type II and III ANOVA tables |
| `avPlots()` | car |  | Added-variable plots |
| `deltaMethod()` | car | nlcom | Estimate and Standard Error of a Nonlinear Function of Estimated Regression Coefficients |
| `leveneTest()` | car | robvar | Levene's Test |
| `linearHypothesis()` | car | test | Test linear restrictions on coefficients |
| `vif()` | car |  | Variance inflation factors |
| `knn()` | class | discrim | k-Nearest Neighbour Classification |
| `bal.tab()` | cobalt | pstest | Display Balance Statistics in a Table |
| `effectiveSize()` | coda | bayesstats | Effective sample size for estimating the mean |
| `HPDinterval()` | coda | bayesstats | Highest Posterior Density intervals |
| `fread()` | data.table | import delimited | Fast reading of large text files |
| `fwrite()` | data.table | export delimited | Fast writing of large text files |
| `winsorize()` | datawizard |  | Winsorise extreme values |
| `dbAppendTable()` | DBI | jdbc | Insert rows into a table |
| `dbDisconnect()` | DBI | odbc | Disconnect (close) a connection |
| `dbGetQuery()` | DBI | odbc | Retrieve results from a query |
| `dbListFields()` | DBI | odbc | List field names of a remote table |
| `dbListTables()` | DBI | odbc | List remote tables |
| `dbReadTable()` | DBI | jdbc | Read database tables as data frames |
| `att_gt()` | did |  | Staggered difference in differences (Callaway-Sant'Anna) |
| [`across()`](https://dplyr.tidyverse.org/reference/across.html) | dplyr |  | Apply the same calculation to several columns |
| [`add_count()`](https://dplyr.tidyverse.org/reference/count.html) | dplyr | bysort g: generate n = \_N | Add a column with group counts |
| [`all_of()`](https://tidyselect.r-lib.org/reference/all_of.html) | dplyr | keep \`vars' | Select columns named in a character vector |
| [`anti_join()`](https://dplyr.tidyverse.org/reference/filter-joins.html) | dplyr |  | Keep rows of the first table with no match in the second |
| [`any_of()`](https://tidyselect.r-lib.org/reference/all_of.html) | dplyr | capture keep | Select listed columns that exist |
| [`arrange()`](https://dplyr.tidyverse.org/reference/arrange.html) | dplyr |  | Sort rows |
| [`between()`](https://dplyr.tidyverse.org/reference/between.html) | dplyr |  | Whether values lie within a range |
| [`bind_cols()`](https://dplyr.tidyverse.org/reference/bind_cols.html) | dplyr |  | Put tables side by side |
| [`bind_rows()`](https://dplyr.tidyverse.org/reference/bind_rows.html) | dplyr |  | Stack tables on top of each other |
| [`c_across()`](https://dplyr.tidyverse.org/reference/c_across.html) | dplyr | egen rowtotal() | Combine columns inside rowwise() |
| [`case_match()`](https://dplyr.tidyverse.org/reference/case_match.html) | dplyr | recode | Recode values by matching them |
| [`case_when()`](https://dplyr.tidyverse.org/reference/case-and-replace-when.html) | dplyr | recode | Several if-else conditions in one step |
| [`coalesce()`](https://dplyr.tidyverse.org/reference/coalesce.html) | dplyr |  | First non-missing value across vectors |
| [`consecutive_id()`](https://dplyr.tidyverse.org/reference/consecutive_id.html) | dplyr | tsspell | Number runs of identical values |
| [`contains()`](https://tidyselect.r-lib.org/reference/starts_with.html) | dplyr |  | Select columns whose names contain some text |
| [`count()`](https://dplyr.tidyverse.org/reference/count.html) | dplyr |  | Count rows in each group |
| [`cross_join()`](https://dplyr.tidyverse.org/reference/cross_join.html) | dplyr |  | Every combination of rows from two tables |
| [`cumall()`](https://dplyr.tidyverse.org/reference/cumall.html) | dplyr | sum() | Running all(): TRUE until the first FALSE |
| [`cume_dist()`](https://dplyr.tidyverse.org/reference/percent_rank.html) | dplyr | cumul | Cumulative distribution |
| [`cur_group()`](https://dplyr.tidyverse.org/reference/context.html) | dplyr | by | Keys of the current group |
| [`cur_group_id()`](https://dplyr.tidyverse.org/reference/context.html) | dplyr |  | Number of the current group |
| [`dense_rank()`](https://dplyr.tidyverse.org/reference/row_number.html) | dplyr | egen group() | Ranks without gaps |
| [`desc()`](https://dplyr.tidyverse.org/reference/desc.html) | dplyr |  | Sort in descending order inside arrange() |
| [`distinct()`](https://dplyr.tidyverse.org/reference/distinct.html) | dplyr |  | Keep unique rows |
| [`ends_with()`](https://tidyselect.r-lib.org/reference/starts_with.html) | dplyr |  | Select columns whose names end with some text |
| [`everything()`](https://tidyselect.r-lib.org/reference/everything.html) | dplyr | \_all | Select all columns |
| [`filter()`](https://dplyr.tidyverse.org/reference/filter.html) | dplyr |  | Keep rows that meet a condition |
| [`filter_out()`](https://dplyr.tidyverse.org/reference/filter.html) | dplyr | drop if | Drop rows that meet a condition, keeping rows where it is missing |
| [`first()`](https://dplyr.tidyverse.org/reference/nth.html) | dplyr | x\[1\] | First value |
| [`full_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html) | dplyr |  | Merge keeping all rows of both tables |
| [`glimpse()`](https://pillar.r-lib.org/reference/glimpse.html) | dplyr | describe | Compact view of all columns |
| [`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html) | dplyr |  | Group rows so later steps work within groups |
| [`group_split()`](https://dplyr.tidyverse.org/reference/group_split.html) | dplyr | by | Split a table into one table per group |
| [`group_vars()`](https://dplyr.tidyverse.org/reference/group_data.html) | dplyr | by | Names of the grouping variables |
| [`if_all()`](https://dplyr.tidyverse.org/reference/across.html) | dplyr | egen rowmin() | Whether a condition holds in all of several columns |
| [`if_any()`](https://dplyr.tidyverse.org/reference/across.html) | dplyr | egen anymatch() | Whether a condition holds in any of several columns |
| [`if_else()`](https://dplyr.tidyverse.org/reference/if_else.html) | dplyr |  | One value if a condition holds, another if not |
| [`inner_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html) | dplyr |  | Merge keeping only matched rows |
| [`intersect()`](https://generics.r-lib.org/reference/setops.html) | dplyr | merge, keep(match) | Rows in both tables |
| [`join_by()`](https://dplyr.tidyverse.org/reference/join_by.html) | dplyr | joinby | Join keys, including inequality and range joins |
| [`lag()`](https://dplyr.tidyverse.org/reference/lead-lag.html) | dplyr |  | Value from the previous row |
| [`last()`](https://dplyr.tidyverse.org/reference/nth.html) | dplyr | x\[\_N\] | Last value |
| [`last_col()`](https://tidyselect.r-lib.org/reference/everything.html) | dplyr | order | The last column |
| [`lead()`](https://dplyr.tidyverse.org/reference/lead-lag.html) | dplyr |  | Value from the next row |
| [`left_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html) | dplyr |  | Merge keeping all rows of the first table |
| [`matches()`](https://tidyselect.r-lib.org/reference/starts_with.html) | dplyr |  | Select columns whose names match a regular expression |
| [`min_rank()`](https://dplyr.tidyverse.org/reference/row_number.html) | dplyr | egen rank(), track | Ranks with ties given the lowest rank |
| [`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html) | dplyr |  | Create or change columns |
| [`n()`](https://dplyr.tidyverse.org/reference/context.html) | dplyr |  | Number of rows in the current group |
| [`n_distinct()`](https://dplyr.tidyverse.org/reference/n_distinct.html) | dplyr | distinct | Number of distinct values |
| [`na_if()`](https://dplyr.tidyverse.org/reference/na_if.html) | dplyr | mvdecode | Turn one value into missing |
| [`near()`](https://dplyr.tidyverse.org/reference/near.html) | dplyr | reldif() | Compare numbers with a tolerance |
| [`nth()`](https://dplyr.tidyverse.org/reference/nth.html) | dplyr | x\[5\] | Value at a given position |
| [`ntile()`](https://dplyr.tidyverse.org/reference/ntile.html) | dplyr | xtile | Split into n groups of nearly equal size |
| [`num_range()`](https://tidyselect.r-lib.org/reference/starts_with.html) | dplyr | keep x1-x5 | Select x1, x2 and so on by number |
| [`percent_rank()`](https://dplyr.tidyverse.org/reference/percent_rank.html) | dplyr | egen rank() | Percentile ranks: (minimum rank - 1) / (nonmissing count - 1); multiply by 100 for percentages |
| [`pick()`](https://dplyr.tidyverse.org/reference/pick.html) | dplyr | varlist | Select columns inside mutate() or summarise() |
| [`pull()`](https://dplyr.tidyverse.org/reference/pull.html) | dplyr |  | Extract one column as a vector |
| [`reframe()`](https://dplyr.tidyverse.org/reference/reframe.html) | dplyr | collapse | Summarise to any number of rows per group |
| [`relocate()`](https://dplyr.tidyverse.org/reference/relocate.html) | dplyr |  | Move columns to a new position |
| [`rename()`](https://dplyr.tidyverse.org/reference/rename.html) | dplyr |  | Rename columns (new = old) |
| [`rename_with()`](https://dplyr.tidyverse.org/reference/rename.html) | dplyr |  | Rename columns with a function, such as toupper |
| [`replace_when()`](https://dplyr.tidyverse.org/reference/case-and-replace-when.html) | dplyr | replace if | Replace values where conditions hold, keeping the rest |
| [`right_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html) | dplyr |  | Merge keeping all rows of the second table |
| [`row_number()`](https://dplyr.tidyverse.org/reference/row_number.html) | dplyr |  | Row number |
| [`rows_update()`](https://dplyr.tidyverse.org/reference/rows.html) | dplyr | merge, update replace | Update rows from another table |
| [`rowwise()`](https://dplyr.tidyverse.org/reference/rowwise.html) | dplyr | egen rowmean() | Compute row by row |
| [`select()`](https://dplyr.tidyverse.org/reference/select.html) | dplyr |  | Keep or drop columns |
| [`semi_join()`](https://dplyr.tidyverse.org/reference/filter-joins.html) | dplyr |  | Keep rows of the first table that have a match in the second |
| [`setdiff()`](https://generics.r-lib.org/reference/setops.html) | dplyr | merge, keep(master) | Rows in the first table only |
| [`slice()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr |  | Keep rows by position |
| [`slice_head()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr | bysort g: keep if \_n \<= 3 | First rows of each group |
| [`slice_max()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr | gsort -x; keep in 1/5 | Rows with the largest values |
| [`slice_min()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr | sort x; keep in 1/5 | Rows with the smallest values |
| [`slice_sample()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr |  | Random sample of rows |
| [`slice_tail()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr | bysort g: keep if \_n \> \_N - 3 | Last rows of each group |
| [`starts_with()`](https://tidyselect.r-lib.org/reference/starts_with.html) | dplyr |  | Select columns whose names start with some text |
| [`summarise()`](https://dplyr.tidyverse.org/reference/summarise.html) | dplyr |  | Reduce each group to one row of statistics |
| [`summarize()`](https://dplyr.tidyverse.org/reference/summarise.html) | dplyr | collapse | Same as summarise() |
| [`tally()`](https://dplyr.tidyverse.org/reference/count.html) | dplyr | count | Count rows |
| [`transmute()`](https://dplyr.tidyverse.org/reference/transmute.html) | dplyr | keep | Create columns and keep only those |
| [`ungroup()`](https://dplyr.tidyverse.org/reference/group_by.html) | dplyr |  | Remove grouping |
| [`union()`](https://generics.r-lib.org/reference/setops.html) | dplyr | append | Rows in either table, without duplicates |
| [`where()`](https://tidyselect.r-lib.org/reference/where.html) | dplyr | ds, has(type numeric) | Select columns by type, such as where(is.numeric) |
| `cohens_d()` | effectsize | esize | Cohen's d and Other Standardized Differences |
| `iv_robust()` | estimatr | ivregress | Two-Stage Least Squares Instrumental Variables Regression |
| `coefplot()` | fixest | coefplot | Coefficient plot for fixest models |
| `etable()` | fixest | esttab | Regression table for fixest models |
| `feglm()` | fixest | xtlogit | GLM, such as logit, with fixed effects |
| `fenegbin()` | fixest | xtnbreg | Negative binomial model with fixed effects |
| `feols()` | fixest |  | Linear regression with fixed effects, clustering and IV |
| `fepois()` | fixest |  | Poisson regression with fixed effects |
| `fitstat()` | fixest | estat firststage | Fit statistics, including the first-stage F |
| `sunab()` | fixest | eventstudyinteract | Sun and Abraham interactions |
| `flextable()` | flextable |  | Formatted table for Word or PowerPoint |
| `save_as_docx()` | flextable |  | Save tables to a Word file |
| `fct_collapse()` | forcats | recode | Combine levels into groups |
| `fct_count()` | forcats | tabulate | Count each level |
| `fct_drop()` | forcats | label define | Drop unused levels |
| `fct_infreq()` | forcats | tabulate x, sort | Order levels by frequency |
| `fct_lump_n()` | forcats | recode | Lump rare levels into Other |
| `fct_na_value_to_level()` | forcats | tabulate x, missing | Make missing values a level |
| `fct_recode()` | forcats | label define, modify | Rename factor levels |
| `fct_relevel()` | forcats | ib3.x | Move factor levels to the front |
| `fct_reorder()` | forcats | graph bar, sort | Order levels by another variable |
| `fct_rev()` | forcats | label define | Reverse the order of levels |
| `Arima()` | forecast | forecast | Fit ARIMA model to univariate time series |
| `forecast()` | forecast | forecast | Objects exported from other packages |
| `fracdiff()` | fracdiff | arfima | ML Estimates for Fractionally-Differenced ARIMA (p,d,q) models |
| `boottest()` | fwildclusterboot | boottest | Fast wild cluster bootstrap inference |
| `geeglm()` | geepack | xtgee | Fit Generalized Estimating Equations (GEE) |
| `aes()` | ggplot2 |  | Map variables to x, y, colour and other plot features |
| `after_stat()` | ggplot2 | histogram | Control aesthetic evaluation |
| `annotate()` | ggplot2 | text() | Add one annotation, such as text |
| `coord_cartesian()` | ggplot2 | xscale(range()) | Zoom in without dropping data |
| `coord_flip()` | ggplot2 |  | Swap the x and y axes |
| `coord_polar()` | ggplot2 |  | Polar coordinates, used for pie charts |
| `facet_grid()` | ggplot2 | by() | Panels by two variables |
| `facet_wrap()` | ggplot2 |  | One panel per group |
| `geom_abline()` | ggplot2 | function | Line with a given slope and intercept |
| `geom_area()` | ggplot2 |  | Area plot |
| `geom_bar()` | ggplot2 |  | Bar chart of counts |
| `geom_boxplot()` | ggplot2 |  | Box plot |
| `geom_col()` | ggplot2 | graph bar (asis) | Bars with given heights |
| `geom_contour()` | ggplot2 | twoway | 2D contours of a 3D surface |
| `geom_density()` | ggplot2 |  | Density curve |
| `geom_errorbar()` | ggplot2 |  | Error bars or capped ranges |
| `geom_histogram()` | ggplot2 |  | Histogram |
| `geom_hline()` | ggplot2 | yline() | Horizontal reference line |
| `geom_jitter()` | ggplot2 | scatter, jitter() | Jittered points |
| `geom_label()` | ggplot2 | mlabel() | Text labels in boxes |
| `geom_line()` | ggplot2 |  | Lines connecting observations |
| `geom_linerange()` | ggplot2 | twoway | Vertical intervals: lines, crossbars & errorbars |
| `geom_point()` | ggplot2 |  | Points (scatter plot) |
| `geom_pointrange()` | ggplot2 | rcap | Points with intervals |
| `geom_qq()` | ggplot2 |  | Quantile-quantile points |
| `geom_qq_line()` | ggplot2 |  | Reference line for a quantile-quantile plot |
| `geom_rect()` | ggplot2 | twoway | Rectangles |
| `geom_ribbon()` | ggplot2 |  | Shaded band between two values |
| `geom_segment()` | ggplot2 | twoway | Line segments and curves |
| `geom_sf()` | ggplot2 | spmap | Map from spatial data |
| `geom_smooth()` | ggplot2 |  | Fitted line or smooth curve |
| `geom_step()` | ggplot2 | line, connect(stairstep) | Step plot |
| `geom_text()` | ggplot2 |  | Text labels on a plot |
| `geom_tile()` | ggplot2 | heatplot | Heat-map tiles |
| `geom_violin()` | ggplot2 |  | Violin plot |
| `geom_vline()` | ggplot2 |  | Vertical reference line |
| `ggplot()` | ggplot2 |  | Start a plot |
| `ggsave()` | ggplot2 |  | Save a plot to a file |
| `labs()` | ggplot2 | title() | Title and axis labels |
| `position_dodge()` | ggplot2 | over() | Place bars or points side by side |
| `position_jitter()` | ggplot2 | dotplot | Jitter points to avoid overplotting |
| `scale_colour_manual()` | ggplot2 | mcolor() | Choose colours by hand |
| `scale_fill_brewer()` | ggplot2 | set scheme | ColorBrewer fill colours |
| `scale_x_continuous()` | ggplot2 | xlabel() | Axis breaks and labels |
| `scale_x_log10()` | ggplot2 | xscale(log) | Logarithmic x axis |
| `scale_y_continuous()` | ggplot2 | scatter | Position scales for continuous data (x & y) |
| `scale_y_log10()` | ggplot2 | scatter | Position scales for continuous data (x & y) |
| `stat_ecdf()` | ggplot2 | cumul | Empirical cumulative distribution plot |
| `stat_summary()` | ggplot2 |  | Plot a summary, such as the mean, of y at each x |
| `stat_summary_2d()` | ggplot2 | heatplot | Summarize a variable within two-dimensional bins |
| `theme()` | ggplot2 | graphregion() | Fine-tune the look of a plot |
| `theme_bw()` | ggplot2 |  | Black-and-white plot theme |
| `theme_classic()` | ggplot2 | set scheme | Classic plot theme |
| `theme_minimal()` | ggplot2 | set scheme | Minimal plot theme |
| `theme_set()` | ggplot2 |  | Set the default theme for every plot |
| `xlim()` | ggplot2 | xscale(range()) | Limits of the x axis |
| `glmmTMB()` | glmmTMB | menbreg | Fit Models with TMB |
| `nbinom2()` | glmmTMB | menbreg | Family functions for glmmTMB |
| `cv.glmnet()` | glmnet | lasso | Cross-validation for glmnet |
| `oblimin()` | GPArotation | rotate | Rotations Functions Using Gradient Projection Algorithms |
| `quartimax()` | GPArotation | rotate | Rotations Functions Using Gradient Projection Algorithms |
| [`pairs()`](https://rdrr.io/r/graphics/pairs.html) | graphics |  | Scatter-plot matrix |
| [`plot()`](https://rdrr.io/r/graphics/plot.default.html) | graphics | quantile | The Default Scatterplot Function |
| [`stem()`](https://rdrr.io/r/graphics/stem.html) | graphics |  | Stem-and-leaf display |
| `arrow()` | grid | twoway | Describe arrows to add to a line |
| `tbl_cross()` | gtsummary | tabulate x1 x2 | Cross table |
| `tbl_regression()` | gtsummary | esttab | Regression table |
| `tbl_summary()` | gtsummary |  | Descriptive Table 1 |
| `as_factor()` | haven | decode | Turn labelled values into a factor |
| `is_tagged_na()` | haven | mvencode | "Tagged" missing values |
| `labelled()` | haven |  | Attach value labels to a vector |
| `print_labels()` | haven | label list | Show value labels |
| `read_dta()` | haven |  | Read a Stata .dta file |
| `read_sas()` | haven |  | Read a SAS file |
| `read_sav()` | haven |  | Read an SPSS .sav file |
| `read_xpt()` | haven | import | Read and write SAS transport files |
| `tagged_na()` | haven | replace x = .a | Stata-style extended missing values such as .a |
| `write_dta()` | haven |  | Write a Stata .dta file |
| `write_sav()` | haven | savespss | Write an SPSS file |
| `write_xpt()` | haven | export | Read and write SAS transport files |
| `zap_labels()` | haven |  | Remove value labels |
| `zap_missing()` | haven | mvdecode | Turn special missing values into NA |
| `adorn_totals()` | janitor | tabulate x1 x2 | Add totals to a tabyl |
| `clean_names()` | janitor | rename \*, lower | Clean and lower-case variable names |
| `get_dupes()` | janitor | duplicates list | List duplicated rows |
| `remove_empty()` | janitor | missings dropvars | Drop empty rows and columns |
| `tabyl()` | janitor | tabulate | Frequency and cross tables |
| `look_for()` | labelled | lookfor | Find variables by name or label |
| `set_variable_labels()` | labelled |  | Set variable labels |
| `to_factor()` | labelled | decode | Turn labelled values into a factor |
| `val_labels()` | labelled | label values | Get or set value labels |
| `var_label()` | labelled | label variable | Get or set a variable label |
| `cfa()` | lavaan | sem | Fit Confirmatory Factor Analysis Models |
| `fitMeasures()` | lavaan | estat | Fit Measures for a Latent Variable Model |
| `lavResiduals()` | lavaan | estat | Residuals |
| `modindices()` | lavaan | estat | Modification Indices |
| `sem()` | lavaan |  | Structural equation model |
| `standardizedSolution()` | lavaan | sem | Standardized Solution |
| `fixef()` | lme4 | quadchk | Extract fixed-effects estimates |
| `glmer()` | lme4 |  | Multilevel generalised linear model |
| `glmerControl()` | lme4 | melogit | Control of Mixed Model Fitting |
| `lmer()` | lme4 |  | Multilevel linear model |
| `ranef()` | lme4 | predict, reffects | Predicted random effects |
| `VarCorr()` | lme4 | estat sd | Variance components of a multilevel model |
| `bptest()` | lmtest |  | Breusch-Pagan test for heteroskedasticity |
| `coeftest()` | lmtest |  | Coefficient tests with a chosen variance matrix |
| `grangertest()` | lmtest | vargranger | Test for Granger Causality |
| `lrtest()` | lmtest |  | Likelihood-ratio test |
| `resettest()` | lmtest |  | RESET test for omitted variables |
| `waldtest()` | lmtest | test | Wald test of nested models |
| `as_date()` | lubridate | dofc() | Convert to a date |
| `day()` | lubridate |  | Day of the month |
| `days()` | lubridate | d + 7 | A period of days, for date arithmetic |
| `days_in_month()` | lubridate | daysinmonth | Get the number of days in the month of a date-time |
| `dmy()` | lubridate | date(s, "DMY") | Parse day-month-year text into a date |
| `floor_date()` | lubridate | mofd() | Round a date down to a unit, such as the month |
| `hour()` | lubridate | hh() | Hour of a date-time |
| `interval()` | lubridate |  | Time span between two dates |
| `make_date()` | lubridate |  | Date from year, month and day |
| `make_datetime()` | lubridate | mdyhms() | Date-time from its parts |
| `mdy()` | lubridate | date(s, "MDY") | Parse month-day-year text into a date |
| `minute()` | lubridate | mm() | Minute of a date-time |
| `month()` | lubridate |  | Month of a date |
| `now()` | lubridate | now() | Current date and time |
| `quarter()` | lubridate | quarter() | Quarter of a date |
| `time_length()` | lubridate |  | Length of a time span in chosen units, such as years |
| `today()` | lubridate | today() | Today's date |
| `wday()` | lubridate |  | Day of the week |
| `week()` | lubridate | week() | Week of the year |
| `yday()` | lubridate | doy() | Day of the year |
| `year()` | lubridate |  | Year of a date |
| `years()` | lubridate | d + 365 | A period of years, for date arithmetic |
| `ymd()` | lubridate |  | Parse text such as 2024-01-31 into a date |
| `ymd_hms()` | lubridate |  | Parse text into a date-time |
| `avg_comparisons()` | marginaleffects | margins r.x | Average contrasts |
| `avg_predictions()` | marginaleffects |  | Average predictions, like Stata's margins |
| `avg_slopes()` | marginaleffects |  | Average marginal effects |
| `comparisons()` | marginaleffects | margins r.x | Differences between predictions (contrasts) |
| `hypotheses()` | marginaleffects |  | Tests of linear and nonlinear hypotheses |
| `plot_predictions()` | marginaleffects |  | Plot predictions, like marginsplot |
| `plot_slopes()` | marginaleffects | marginsplot | Plot marginal effects |
| `predictions()` | marginaleffects | margins | Predictions with standard errors |
| `slopes()` | marginaleffects | margins, dydx(x) at() | Marginal effects for each observation |
| `boxcox()` | MASS | boxcox | Box-Cox Transformations for Linear Models |
| `corresp()` | MASS | ca | Simple Correspondence Analysis |
| `glm.nb()` | MASS |  | Negative binomial regression |
| `isoMDS()` | MASS | mds | Kruskal's Non-metric Multidimensional Scaling |
| `lda()` | MASS | discrim | Linear Discriminant Analysis |
| `mca()` | MASS | mca | Multiple Correspondence Analysis |
| `mvrnorm()` | MASS | drawnorm | Simulate from a Multivariate Normal Distribution |
| `polr()` | MASS |  | Ordered logit or probit |
| `qda()` | MASS | discrim | Quadratic Discriminant Analysis |
| `rlm()` | MASS |  | Robust regression |
| `match_data()` | MatchIt | psmatch2 | Construct a matched dataset from a matchit object |
| `matchit()` | MatchIt |  | Matching for causal inference |
| `MCMCregress()` | MCMCpack | bayesmh | Markov Chain Monte Carlo for Gaussian Linear Regression |
| `cumul()` | metafor | meta | Cumulative Meta-Analysis for 'rma' Objects |
| `escalc()` | metafor | meta | Calculate Effect Sizes and Outcome Measures |
| `leave1out()` | metafor | meta | Leave-One-Out Diagnostics for 'rma' Objects |
| `ranktest()` | metafor | meta | Rank Correlation Test for Funnel Plot Asymmetry |
| `regtest()` | metafor | meta | Regression Test for Funnel Plot Asymmetry |
| `rma()` | metafor | meta | Meta-Analysis via Linear (Mixed-Effects) Models |
| `trimfill()` | metafor | meta | Trim and Fill Analysis for 'rma.uni' Objects |
| `complete()` | mice | mi | Extracts the completed data from a mids object |
| `D1()` | mice | mi | Compare two nested models using D1-statistic |
| `D2()` | mice | mi | Compare two nested models using D2-statistic |
| `make.predictorMatrix()` | mice | mi | Creates a predictorMatrix argument |
| `mice()` | mice |  | Multiple imputation by chained equations |
| `pool()` | mice |  | Combine results across imputations |
| `pool.scalar()` | mice | mi | Multiple imputation pooling: univariate version |
| `MIcombine()` | mitools | mi | Multiple imputation inference |
| `datasummary()` | modelsummary | tabstat | Custom summary-statistics tables |
| `datasummary_skim()` | modelsummary | codebook | Quick overview of all variables |
| `modelplot()` | modelsummary |  | Coefficient plot |
| `modelsummary()` | modelsummary |  | Regression and summary tables |
| `glht()` | multcomp | contrast | General Linear Hypotheses |
| `mcp()` | multcomp | contrast | General Linear Hypotheses |
| `dmvnorm()` | mvtnorm | lnmvnormalden | Multivariate Normal Density and Random Deviates |
| `pmvnorm()` | mvtnorm | binormal | Multivariate Normal Distribution |
| `corAR1()` | nlme | xtregar | AR(1) Correlation Structure |
| `gls()` | nlme | hetregress | Fit Linear Model Using Generalized Least Squares |
| `lme()` | nlme | xtregar | Linear Mixed-Effects Models |
| `nlme()` | nlme | menl | Nonlinear Mixed-Effects Models |
| `varExp()` | nlme | hetregress | Exponential Variance Function |
| `varIdent()` | nlme | xtgls | Constant Variance Function |
| `multinom()` | nnet |  | Multinomial logit |
| `oaxaca()` | oaxaca |  | Blinder-Oaxaca decomposition |
| `clmm()` | ordinal | meologit | Cumulative Link Mixed Models |
| `wrap_plots()` | patchwork |  | Combine several plots |
| `pdata.frame()` | plm | xtset | Declare panel data for plm |
| `pgmm()` | plm |  | Dynamic panel GMM (Arellano-Bond) |
| `phtest()` | plm | hausman | Hausman test |
| `plm()` | plm |  | Panel models: fixed and random effects |
| `plmtest()` | plm | xttest0 | Lagrange FF Multiplier Tests for Panel Models |
| `purtest()` | plm | xtunitroot | Unit root tests for panel data |
| `vcovBK()` | plm | xtpcse | Beck and Katz Robust Covariance Matrix Estimators |
| `vcovHC()` | plm | xtreg | Robust Covariance Matrix Estimators |
| `vcovSCC()` | plm | xtreg | Driscoll and Kraay (1998) Robust Covariance Matrix Estimator |
| `polychor()` | polycor | tetrachoric | Polychoric Correlation |
| `coords()` | pROC | roctab | Coordinates of a ROC curve |
| `roc()` | pROC | roctab | Build a ROC curve |
| `roc.test()` | pROC | roccomp | Compare two ROC curves |
| `zeroinfl()` | pscl | zip | Zero-inflated Count Data Regression |
| `alpha()` | psych | alpha | Cronbach's alpha |
| `cohen.kappa()` | psych | kap | Find Cohen's kappa and weighted kappa coefficients for correlation of two raters |
| `describe()` | psych | summarize | Summary statistics (unlike Stata's describe) |
| `fa()` | psych | factor | Factor analysis with more methods |
| `ICC()` | psych | icc | Intraclass Correlations (ICC1, ICC2, ICC3 from Shrout and Fleiss) |
| `KMO()` | psych | estat | Find the Kaiser, Meyer, Olkin Measure of Sampling Adequacy |
| `mardia()` | psych | mvtest | Calculate univariate or multivariate (Mardia's test) skew and kurtosis for a vector, matrix, or data.frame |
| `principal()` | psych | factor | Principal components analysis (PCA) |
| `list_rbind()` | purrr | append | Stack a list of data frames |
| `map()` | purrr | foreach | Apply a function to each element, returning a list |
| `map_chr()` | purrr | foreach | Apply a function to each element, returning text |
| `map_dbl()` | purrr | foreach | Apply a function to each element, returning numbers |
| `map2()` | purrr | forvalues | Apply a function to pairs of elements |
| `possibly()` | purrr | capture | Return a default value instead of an error |
| `reduce()` | purrr | merge | Combine elements one after another, such as repeated merges |
| `walk()` | purrr | foreach | Apply a function for its side effects, such as saving files |
| `ES.h()` | pwr | power | Effect size calculation for proportions |
| `pwr.anova.test()` | pwr | power | Power calculations for balanced one-way analysis of variance tests |
| `pwr.f2.test()` | pwr | power | Power calculations for the general linear model |
| `pwr.norm.test()` | pwr | power | Power calculations for the mean of a normal distribution (known variance) |
| `pwr.p.test()` | pwr | power | Power calculations for proportion tests (one sample) |
| `pwr.r.test()` | pwr | power | Power calculations for correlation test |
| `pwr.t2n.test()` | pwr | power | Power calculations for two samples (different sizes) t-tests of means |
| `rq()` | quantreg |  | Quantile regression |
| `rdbwdensity()` | rddensity | rdbwdensity | Bandwidth Selection for Manipulation Testing |
| `rddensity()` | rddensity | rddensity | Manipulation Testing Using Local Polynomial Density Estimation |
| `rdbwselect()` | rdrobust | rdbwselect | Bandwidth Selection Procedures for Local Polynomial Regression Discontinuity Estimators |
| `rdrobust()` | rdrobust |  | Regression discontinuity |
| `locale()` | readr |  | Describe decimal marks, encodings and date conventions for parsing |
| `parse_double()` | readr | destring, dpcomma | Parse text as decimal numbers, with locale-specific marks |
| `parse_number()` | readr | destring, ignore() | Extract a number from text such as \$1,200 |
| `read_csv()` | readr |  | Read a CSV file |
| `read_delim()` | readr | import delimited | Read a file with any delimiter |
| `read_tsv()` | readr | import delimited | Read a tab-separated file |
| `write_csv()` | readr |  | Write a CSV file |
| `excel_sheets()` | readxl | import excel, describe | Sheet names of an Excel file |
| `read_excel()` | readxl |  | Read an Excel sheet |
| `install_github()` | remotes |  | Install a package from GitHub |
| `find_root()` | rprojroot | setroot | Find the root of a directory hierarchy |
| `has_file()` | rprojroot | setroot | Is a directory the project root? |
| `selection()` | sampleSelection |  | Heckman sample-selection model |
| `NeweyWest()` | sandwich | newey | Newey-West HAC Covariance Matrix Estimation |
| `vcovBS()` | sandwich |  | Bootstrap variance matrix |
| `vcovCL()` | sandwich | vce(cluster id) | Clustered variance matrix |
| `vcovHC()` | sandwich | vce(robust) | Heteroskedasticity-robust variance matrix |
| `vcovJK()` | sandwich |  | Jackknife variance matrix |
| `st_as_sf()` | sf | spset | Convert foreign object to an sf object |
| `as_survey_design()` | srvyr |  | Declare a survey design |
| `survey_mean()` | srvyr |  | Survey-weighted mean |
| `survey_prop()` | srvyr |  | Survey-weighted proportion |
| `survey_quantile()` | srvyr | epctile | Survey-weighted quantiles |
| `survey_total()` | srvyr | svy: total | Survey-weighted total |
| [`acf()`](https://rdrr.io/r/stats/acf.html) | stats | corrgram | Autocorrelation function |
| [`addmargins()`](https://rdrr.io/r/stats/addmargins.html) | stats | tabulate x1 x2 | Add totals to a table |
| [`aggregate()`](https://rdrr.io/r/stats/aggregate.html) | stats | collapse | Group statistics (base R) |
| [`AIC()`](https://rdrr.io/r/stats/AIC.html) | stats |  | Akaike information criterion |
| [`anova()`](https://rdrr.io/r/stats/anova.html) | stats | anova | ANOVA table, or comparison of nested models |
| [`aov()`](https://rdrr.io/r/stats/aov.html) | stats |  | Analysis of variance |
| [`approx()`](https://rdrr.io/r/stats/approxfun.html) | stats | ipolate | Interpolation Functions |
| [`arima()`](https://rdrr.io/r/stats/arima.html) | stats |  | ARIMA time-series model |
| [`as.dist()`](https://rdrr.io/r/stats/dist.html) | stats | mdsmat | Distance Matrix Computation |
| [`ave()`](https://rdrr.io/r/stats/ave.html) | stats | stgen | Group Averages Over Level Combinations of Factors |
| [`bartlett.test()`](https://rdrr.io/r/stats/bartlett.test.html) | stats | oneway | Bartlett test of equal variances |
| [`BIC()`](https://rdrr.io/r/stats/AIC.html) | stats |  | Bayesian information criterion |
| [`binom.test()`](https://rdrr.io/r/stats/binom.test.html) | stats | bitest | Exact binomial test |
| [`binomial()`](https://rdrr.io/r/stats/family.html) | stats |  | Binomial family for logit and probit models |
| [`Box.test()`](https://rdrr.io/r/stats/box.test.html) | stats | wntestq | \#1BoxBox-#1PiercePierce and \#1LjungLjung-#1BoxBox Tests |
| [`cancor()`](https://rdrr.io/r/stats/cancor.html) | stats | canon | Canonical Correlations |
| [`ccf()`](https://rdrr.io/r/stats/acf.html) | stats | xcorr | Auto- and Cross- Covariance and -Correlation Function Estimation |
| [`chisq.test()`](https://rdrr.io/r/stats/chisq.test.html) | stats | tabulate x1 x2, chi2 | Chi-square test |
| [`cmdscale()`](https://rdrr.io/r/stats/cmdscale.html) | stats | mds | Classical (Metric) Multidimensional Scaling |
| [`coef()`](https://rdrr.io/r/stats/coef.html) | stats |  | Model coefficients |
| [`complete.cases()`](https://rdrr.io/r/stats/complete.cases.html) | stats | egen rowmiss() | Rows with no missing values |
| [`confint()`](https://rdrr.io/r/stats/confint.html) | stats | regress | Confidence intervals of coefficients |
| [`cooks.distance()`](https://rdrr.io/r/stats/influence.measures.html) | stats | predict | Regression Deletion Diagnostics |
| [`cor()`](https://rdrr.io/r/stats/cor.html) | stats |  | Correlation matrix |
| [`cor.test()`](https://rdrr.io/r/stats/cor.test.html) | stats |  | Correlation with a significance test |
| [`cov()`](https://rdrr.io/r/stats/cor.html) | stats | correlate, covariance | Covariance |
| [`cov2cor()`](https://rdrr.io/r/stats/cor.html) | stats | estat | Correlation, Variance and Covariance (Matrices) |
| [`cutree()`](https://rdrr.io/r/stats/cutree.html) | stats | cluster | Cut a Tree into Groups of Data |
| [`dbeta()`](https://rdrr.io/r/stats/Beta.html) | stats | betaden | The Beta Distribution |
| [`dbinom()`](https://rdrr.io/r/stats/Binomial.html) | stats | binomialp | The Binomial Distribution |
| [`dcauchy()`](https://rdrr.io/r/stats/Cauchy.html) | stats | cauchyden | The Cauchy Distribution |
| [`dchisq()`](https://rdrr.io/r/stats/Chisquare.html) | stats | chi2den | The (non-central) Chi-Squared Distribution |
| [`density()`](https://rdrr.io/r/stats/density.html) | stats | kdensity | Kernel density estimate |
| [`dexp()`](https://rdrr.io/r/stats/Exponential.html) | stats | exponentialden | The Exponential Distribution |
| [`df()`](https://rdrr.io/r/stats/Fdist.html) | stats | Fden | The F Distribution |
| [`dfbetas()`](https://rdrr.io/r/stats/influence.measures.html) | stats | dfbeta | Regression Deletion Diagnostics |
| [`dffits()`](https://rdrr.io/r/stats/influence.measures.html) | stats | predict | Regression Deletion Diagnostics |
| [`dgamma()`](https://rdrr.io/r/stats/GammaDist.html) | stats | gammaden | The Gamma Distribution |
| [`dhyper()`](https://rdrr.io/r/stats/Hypergeometric.html) | stats | hypergeometricp | The Hypergeometric Distribution |
| [`dist()`](https://rdrr.io/r/stats/dist.html) | stats | mds | Distance Matrix Computation |
| [`dlogis()`](https://rdrr.io/r/stats/Logistic.html) | stats | logisticden | The Logistic Distribution |
| [`dnbinom()`](https://rdrr.io/r/stats/NegBinomial.html) | stats | nbinomialp | The Negative Binomial Distribution |
| [`dnorm()`](https://rdrr.io/r/stats/Normal.html) | stats | normalden() | Normal density |
| [`dpois()`](https://rdrr.io/r/stats/Poisson.html) | stats | poissonp | The Poisson Distribution |
| [`dt()`](https://rdrr.io/r/stats/TDist.html) | stats | tden | The Student t Distribution |
| [`dweibull()`](https://rdrr.io/r/stats/Weibull.html) | stats | weibullden | The Weibull Distribution |
| [`ecdf()`](https://rdrr.io/r/stats/ecdf.html) | stats | cumul | Empirical cumulative distribution |
| [`expand.model.frame()`](https://rdrr.io/r/stats/expand.model.frame.html) | stats | vce(cluster g) | Retrieve additional variables aligned with a fitted model's observations |
| [`factanal()`](https://rdrr.io/r/stats/factanal.html) | stats |  | Factor analysis |
| [`filter()`](https://dplyr.tidyverse.org/reference/filter.html) | stats | tssmooth | Linear Filtering on a Time Series |
| [`fisher.test()`](https://rdrr.io/r/stats/fisher.test.html) | stats |  | Fisher's exact test |
| [`fitted()`](https://rdrr.io/r/stats/fitted.values.html) | stats |  | Fitted values of a model |
| [`ftable()`](https://rdrr.io/r/stats/ftable.html) | stats | table | Flat multi-way table |
| [`Gamma()`](https://rdrr.io/r/stats/family.html) | stats | glm | Family Objects for Models |
| [`gaussian()`](https://rdrr.io/r/stats/family.html) | stats | glm | Family Objects for Models |
| [`glm()`](https://rdrr.io/r/stats/glm.html) | stats |  | Generalised linear model, such as logit or Poisson |
| [`hatvalues()`](https://rdrr.io/r/stats/influence.measures.html) | stats | predict | Regression Deletion Diagnostics |
| [`hclust()`](https://rdrr.io/r/stats/hclust.html) | stats | cluster | Hierarchical Clustering |
| [`HoltWinters()`](https://rdrr.io/r/stats/HoltWinters.html) | stats | tssmooth | Holt-Winters Filtering |
| [`inverse.gaussian()`](https://rdrr.io/r/stats/family.html) | stats | glm | Family Objects for Models |
| [`IQR()`](https://rdrr.io/r/stats/IQR.html) | stats | egen iqr() | Interquartile range |
| [`kmeans()`](https://rdrr.io/r/stats/kmeans.html) | stats |  | K-means clustering |
| [`kruskal.test()`](https://rdrr.io/r/stats/kruskal.test.html) | stats |  | Kruskal-Wallis test |
| [`ks.test()`](https://rdrr.io/r/stats/ks.test.html) | stats |  | Kolmogorov-Smirnov test |
| [`lm()`](https://rdrr.io/r/stats/lm.html) | stats |  | Linear regression |
| [`logLik()`](https://rdrr.io/r/stats/logLik.html) | stats | e(ll) | Log-likelihood of a model |
| [`lowess()`](https://rdrr.io/r/stats/lowess.html) | stats | lowess | Lowess smoother |
| [`mad()`](https://rdrr.io/r/stats/mad.html) | stats | egen mad() | Median absolute deviation |
| [`manova()`](https://rdrr.io/r/stats/manova.html) | stats | manova | Multivariate Analysis of Variance |
| [`mantelhaen.test()`](https://rdrr.io/r/stats/mantelhaen.test.html) | stats | mhodds | Cochran-Mantel-#1HaenszelHaenszel Chi-Squared Test for Count Data |
| [`mcnemar.test()`](https://rdrr.io/r/stats/mcnemar.test.html) | stats | mcc | McNemar test for paired proportions |
| [`median()`](https://rdrr.io/r/stats/median.html) | stats |  | Median |
| [`model.frame()`](https://rdrr.io/r/stats/model.frame.html) | stats | estat | Extracting the Model Frame from a Formula or Fit |
| [`model.matrix()`](https://rdrr.io/r/stats/model.matrix.html) | stats | xi | Design matrix with dummy variables |
| [`na.omit()`](https://rdrr.io/r/stats/na.fail.html) | stats |  | Drop rows with missing values |
| [`nls()`](https://rdrr.io/r/stats/nls.html) | stats | nl | Nonlinear least squares |
| [`nobs()`](https://rdrr.io/r/stats/nobs.html) | stats | e(N) | Number of observations used by a model |
| [`offset()`](https://rdrr.io/r/stats/offset.html) | stats | poisson | Include an Offset in a Model Formula |
| [`optim()`](https://rdrr.io/r/stats/optim.html) | stats | ml | General-purpose optimisation |
| [`p.adjust()`](https://rdrr.io/r/stats/p.adjust.html) | stats | test, mtest | Adjust p-values for multiple tests |
| [`pacf()`](https://rdrr.io/r/stats/acf.html) | stats | pac | Auto- and Cross- Covariance and -Correlation Function Estimation |
| [`pairwise.t.test()`](https://rdrr.io/r/stats/pairwise.t.test.html) | stats | pwmean | Pairwise t tests with adjusted p-values |
| [`pbeta()`](https://rdrr.io/r/stats/Beta.html) | stats | ibeta | The Beta Distribution |
| [`pbinom()`](https://rdrr.io/r/stats/Binomial.html) | stats | binomial | The Binomial Distribution |
| [`pcauchy()`](https://rdrr.io/r/stats/Cauchy.html) | stats | cauchy | The Cauchy Distribution |
| [`pchisq()`](https://rdrr.io/r/stats/Chisquare.html) | stats | chi2tail() | Chi-square probability |
| [`pexp()`](https://rdrr.io/r/stats/Exponential.html) | stats | exponential | The Exponential Distribution |
| [`pf()`](https://rdrr.io/r/stats/Fdist.html) | stats | F | The F Distribution |
| [`pgamma()`](https://rdrr.io/r/stats/GammaDist.html) | stats | gammap | The Gamma Distribution |
| [`phyper()`](https://rdrr.io/r/stats/Hypergeometric.html) | stats | hypergeometric | The Hypergeometric Distribution |
| [`plogis()`](https://rdrr.io/r/stats/Logistic.html) | stats | predictnl | The Logistic Distribution |
| [`pnbinom()`](https://rdrr.io/r/stats/NegBinomial.html) | stats | nbinomial | The Negative Binomial Distribution |
| [`pnorm()`](https://rdrr.io/r/stats/Normal.html) | stats | normal() | Normal cumulative probability |
| [`poisson()`](https://rdrr.io/r/stats/family.html) | stats | glm | Family Objects for Models |
| [`poisson.test()`](https://rdrr.io/r/stats/poisson.test.html) | stats | stir | Exact Poisson tests |
| [`poly()`](https://rdrr.io/r/stats/poly.html) | stats |  | Polynomial terms for a model |
| [`power.prop.test()`](https://rdrr.io/r/stats/power.prop.test.html) | stats | power | Power Calculations for Two-Sample Test for Proportions |
| [`power.t.test()`](https://rdrr.io/r/stats/power.t.test.html) | stats | power twomeans | Power and sample size for a t test |
| [`ppoints()`](https://rdrr.io/r/stats/ppoints.html) | stats | quantile | Ordinates for Probability Plotting |
| [`ppois()`](https://rdrr.io/r/stats/Poisson.html) | stats | poisson | The Poisson Distribution |
| [`prcomp()`](https://rdrr.io/r/stats/prcomp.html) | stats |  | Principal components |
| [`predict()`](https://rdrr.io/r/stats/predict.html) | stats |  | Predictions from a model |
| [`princomp()`](https://rdrr.io/r/stats/princomp.html) | stats | pcamat | Principal Components Analysis |
| [`promax()`](https://rdrr.io/r/stats/varimax.html) | stats | rotate | Rotation Methods for Factor Analysis |
| [`prop.test()`](https://rdrr.io/r/stats/prop.test.html) | stats |  | Test of a proportion |
| [`prop.trend.test()`](https://rdrr.io/r/stats/prop.trend.test.html) | stats | nptrend | Test for trend in proportions |
| [`pt()`](https://rdrr.io/r/stats/TDist.html) | stats | ttail() | t-distribution probability |
| [`ptukey()`](https://rdrr.io/r/stats/Tukey.html) | stats | tukeyprob | The Studentized Range Distribution |
| [`pweibull()`](https://rdrr.io/r/stats/Weibull.html) | stats | weibull | The Weibull Distribution |
| [`qbeta()`](https://rdrr.io/r/stats/Beta.html) | stats | invibeta | The Beta Distribution |
| [`qcauchy()`](https://rdrr.io/r/stats/Cauchy.html) | stats | invcauchy | The Cauchy Distribution |
| [`qchisq()`](https://rdrr.io/r/stats/Chisquare.html) | stats | qchi | The (non-central) Chi-Squared Distribution |
| [`qexp()`](https://rdrr.io/r/stats/Exponential.html) | stats | invexponential | The Exponential Distribution |
| [`qf()`](https://rdrr.io/r/stats/Fdist.html) | stats | invF | The F Distribution |
| [`qgamma()`](https://rdrr.io/r/stats/GammaDist.html) | stats | invgammap | The Gamma Distribution |
| [`qlogis()`](https://rdrr.io/r/stats/Logistic.html) | stats | invlogistic | The Logistic Distribution |
| [`qnorm()`](https://rdrr.io/r/stats/Normal.html) | stats | invnormal() | Normal quantile |
| [`qqplot()`](https://rdrr.io/r/stats/qqnorm.html) | stats | qqplot | Quantile-Quantile Plots |
| [`qt()`](https://rdrr.io/r/stats/TDist.html) | stats | invt | The Student t Distribution |
| [`qtukey()`](https://rdrr.io/r/stats/Tukey.html) | stats | invtukeyprob | The Studentized Range Distribution |
| [`quantile()`](https://rdrr.io/r/stats/quantile.html) | stats | pctile | Quantiles |
| [`quasibinomial()`](https://rdrr.io/r/stats/family.html) | stats |  | Binomial family that allows survey weights |
| [`quasipoisson()`](https://rdrr.io/r/stats/family.html) | stats | svy | Family Objects for Models |
| [`qweibull()`](https://rdrr.io/r/stats/Weibull.html) | stats | invweibull | The Weibull Distribution |
| [`rbeta()`](https://rdrr.io/r/stats/Beta.html) | stats | rbeta | The Beta Distribution |
| [`rbinom()`](https://rdrr.io/r/stats/Binomial.html) | stats | rbinomial() | Binomial random numbers |
| [`rcauchy()`](https://rdrr.io/r/stats/Cauchy.html) | stats | rcauchy | The Cauchy Distribution |
| [`rchisq()`](https://rdrr.io/r/stats/Chisquare.html) | stats | rchi2 | The (non-central) Chi-Squared Distribution |
| [`relevel()`](https://rdrr.io/r/stats/relevel.html) | stats |  | Choose the base category of a factor |
| [`reshape()`](https://rdrr.io/r/stats/reshape.html) | stats | icc | Reshape Grouped Data |
| [`residuals()`](https://rdrr.io/r/stats/residuals.html) | stats | predict, residuals | Model residuals |
| [`rexp()`](https://rdrr.io/r/stats/Exponential.html) | stats | rexponential | The Exponential Distribution |
| [`rgamma()`](https://rdrr.io/r/stats/GammaDist.html) | stats | rgamma | The Gamma Distribution |
| [`rhyper()`](https://rdrr.io/r/stats/Hypergeometric.html) | stats | rhypergeometric | The Hypergeometric Distribution |
| [`rlogis()`](https://rdrr.io/r/stats/Logistic.html) | stats | rlogistic | The Logistic Distribution |
| [`rnbinom()`](https://rdrr.io/r/stats/NegBinomial.html) | stats | rnbinomial | The Negative Binomial Distribution |
| [`rnorm()`](https://rdrr.io/r/stats/Normal.html) | stats |  | Normal random numbers |
| [`rpois()`](https://rdrr.io/r/stats/Poisson.html) | stats | rpoisson | The Poisson Distribution |
| [`rstandard()`](https://rdrr.io/r/stats/influence.measures.html) | stats | predict | Regression Deletion Diagnostics |
| [`rstudent()`](https://rdrr.io/r/stats/influence.measures.html) | stats | predict | Regression Deletion Diagnostics |
| [`rt()`](https://rdrr.io/r/stats/TDist.html) | stats | rt | The Student t Distribution |
| [`runif()`](https://rdrr.io/r/stats/Uniform.html) | stats |  | Uniform random numbers |
| [`runmed()`](https://rdrr.io/r/stats/runmed.html) | stats | tssmooth | Running Medians -- Robust Scatter Plot Smoothing |
| [`rweibull()`](https://rdrr.io/r/stats/Weibull.html) | stats | rweibull | The Weibull Distribution |
| [`sd()`](https://rdrr.io/r/stats/sd.html) | stats |  | Standard deviation |
| [`setNames()`](https://rdrr.io/r/stats/setNames.html) | stats | labmask | Set the Names in an Object |
| [`shapiro.test()`](https://rdrr.io/r/stats/shapiro.test.html) | stats |  | Shapiro-Wilk normality test |
| [`sigma()`](https://rdrr.io/r/stats/sigma.html) | stats | estat | Extract Residual Standard Deviation 'Sigma' |
| [`spectrum()`](https://rdrr.io/r/stats/spectrum.html) | stats | pergram | Spectral Density Estimation |
| [`step()`](https://rdrr.io/r/stats/step.html) | stats | stepwise | Stepwise model selection |
| [`StructTS()`](https://rdrr.io/r/stats/StructTS.html) | stats | sspace | Fit Structural Time Series |
| [`t.test()`](https://rdrr.io/r/stats/t.test.html) | stats |  | t test and confidence interval of a mean |
| [`ts()`](https://rdrr.io/r/stats/ts.html) | stats | tsset | Time-series object |
| [`TukeyHSD()`](https://rdrr.io/r/stats/TukeyHSD.html) | stats | pwcompare, mcompare(tukey) | Tukey multiple comparisons |
| [`uniroot()`](https://rdrr.io/r/stats/uniroot.html) | stats | ciwidth | One Dimensional Root (Zero) Finding |
| [`update()`](https://rdrr.io/r/stats/update.html) | stats | regress | Refit a model with changes |
| [`var()`](https://rdrr.io/r/stats/cor.html) | stats | summarize, detail | Variance |
| [`var.test()`](https://rdrr.io/r/stats/var.test.html) | stats | sdtest | F test of equal variances |
| [`varimax()`](https://rdrr.io/r/stats/varimax.html) | stats | rotate | Rotation Methods for Factor Analysis |
| [`vcov()`](https://rdrr.io/r/stats/vcov.html) | stats |  | Variance-covariance matrix of a model |
| [`weighted.mean()`](https://rdrr.io/r/stats/weighted.mean.html) | stats | summarize \[aweight = w\] | Weighted mean |
| [`wilcox.test()`](https://rdrr.io/r/stats/wilcox.test.html) | stats |  | Wilcoxon rank-sum or signed-rank test |
| [`xtabs()`](https://rdrr.io/r/stats/xtabs.html) | stats | tabulate x1 x2 | Cross-tabulation from a formula |
| `stri_reverse()` | stringi | ustrreverse | Reverse Each String |
| `stri_trans_nfc()` | stringi | ustrnormalize | Perform or Check For Unicode Normalization |
| `stri_trans_nfkc()` | stringi | ustrnormalize | Perform or Check For Unicode Normalization |
| `fixed()` | stringr |  | Match text literally rather than as a regular expression |
| `regex()` | stringr |  | Regular expression with options such as ignore_case |
| `str_c()` | stringr | generate s = a + b | Join strings |
| `str_count()` | stringr |  | Count matches in a string |
| `str_detect()` | stringr |  | Whether a string contains a pattern |
| `str_dup()` | stringr | "-" \* 10 | Repeat a string |
| `str_ends()` | stringr | substr() | Whether a string ends with a pattern |
| `str_extract()` | stringr |  | Extract the matching text |
| `str_extract_all()` | stringr | ustrregexs() | Extract every match |
| `str_flatten()` | stringr | levelsof, separate() | Collapse a vector into one string |
| `str_glue()` | stringr | display "\`x'" | Fill a text template |
| `str_length()` | stringr |  | Number of characters |
| `str_locate()` | stringr | strpos() | Position of a match |
| `str_match()` | stringr | regexs() | Extract the groups of a regular expression |
| `str_pad()` | stringr | string(x, "%05.0f") | Pad a string to a fixed width |
| `str_remove()` | stringr | subinstr() | Remove the first match |
| `str_remove_all()` | stringr | subinstr() | Remove every match |
| `str_replace()` | stringr |  | Replace the first match |
| `str_replace_all()` | stringr |  | Replace every match |
| `str_split()` | stringr | split | Split strings into pieces |
| `str_squish()` | stringr |  | Trim spaces and collapse repeated spaces |
| `str_starts()` | stringr | substr() | Whether a string starts with a pattern |
| `str_sub()` | stringr |  | Part of a string by position |
| `str_subset()` | stringr | keep if regexm() | Keep the strings that match |
| `str_to_lower()` | stringr |  | Lower case |
| `str_to_sentence()` | stringr | strproper() | Sentence case |
| `str_to_title()` | stringr |  | Title case |
| `str_to_upper()` | stringr |  | Upper case |
| `str_trim()` | stringr |  | Remove leading and trailing spaces |
| `str_trunc()` | stringr | abbrev() | Shorten strings to a width |
| `str_wrap()` | stringr | display | Wrap text into lines |
| `word()` | stringr |  | Extract words from a sentence |
| `as.svrepdesign()` | survey | svyset | Convert a survey design to use replicate weights |
| `cv()` | survey | estat | Summary statistics for sample surveys |
| `deff()` | survey | estat | Summary statistics for sample surveys |
| `degf()` | survey | svydescribe | Contingency tables for survey data |
| `postStratify()` | survey | svyset | Post-stratify a survey |
| `rake()` | survey | svyset | Raking of replicate weight design |
| `svyby()` | survey | svy | Survey statistics on subsets |
| `svychisq()` | survey | svy | Contingency tables for survey data |
| `svyciprop()` | survey | svy | Confidence intervals for proportions |
| `svydesign()` | survey | svyset | Declare a survey design (survey package) |
| `svyglm()` | survey |  | Survey-weighted regression |
| `svymean()` | survey | svy: mean | Survey-weighted mean (survey package) |
| `svyratio()` | survey | svy | Ratio estimation |
| `svytable()` | survey | svy: tabulate | Survey-weighted table |
| `svytotal()` | survey | svy | Summary statistics for sample surveys |
| `basehaz()` | survival | predict | Alias for the survfit function |
| `clogit()` | survival |  | Conditional logit |
| `concordance()` | survival | estat | Compute the concordance statistic for data or a model |
| `cox.zph()` | survival | estat | Test the Proportional Hazards Assumption of a Cox Regression |
| `coxph()` | survival |  | Cox proportional hazards model |
| `finegray()` | survival | stcrreg | Create data for a Fine-Gray model |
| `frailty()` | survival | stcox | Random effects terms |
| `strata()` | survival |  | Stratum term in a survival model formula |
| `Surv()` | survival |  | Survival-time outcome for a model |
| `survdiff()` | survival |  | Log-rank test |
| `survfit()` | survival |  | Kaplan-Meier survival curves |
| `survreg()` | survival |  | Parametric survival model |
| `survSplit()` | survival | stsplit | Split a survival data set at specified times |
| `synth()` | Synth |  | Synthetic control |
| [`add_row()`](https://tibble.tidyverse.org/reference/add_row.html) | tibble | set obs | Add rows to a table |
| [`as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html) | tibble |  | Convert to a tibble |
| `rownames_to_column()` | tibble | xpose | Turn row names into a column |
| [`tibble()`](https://tibble.tidyverse.org/reference/tibble.html) | tibble |  | Create a data frame (tibble) |
| [`tribble()`](https://tibble.tidyverse.org/reference/tribble.html) | tibble | input | Type a small table row by row |
| `complete()` | tidyr |  | Add rows for missing combinations of values |
| `crossing()` | tidyr | cross | All combinations, sorted and unique |
| `drop_na()` | tidyr | drop if missing(x) | Drop rows with missing values |
| `expand()` | tidyr | fillin | All combinations of values, dropping other columns |
| `expand_grid()` | tidyr | cross | Table of every combination of given values |
| `fill()` | tidyr |  | Fill missing values with the previous or next value |
| `full_seq()` | tidyr | tsfill | Complete sequence of values |
| `nest()` | tidyr | by | Nest rows into list-columns, one row per group |
| `pivot_longer()` | tidyr |  | Reshape from wide to long |
| `pivot_wider()` | tidyr |  | Reshape from long to wide |
| `replace_na()` | tidyr | replace x = 0 if missing(x) | Replace missing values |
| `separate_longer_delim()` | tidyr | split | Split text into rows |
| `separate_wider_delim()` | tidyr |  | Split one text column into several |
| `separate_wider_position()` | tidyr | substr() | Split text into columns by position |
| `uncount()` | tidyr |  | Repeat each row a given number of times |
| `unite()` | tidyr | egen concat() | Join columns into one |
| `unnest()` | tidyr | expand | Expand list-columns back into rows |
| [`as_character()`](https://socimh.github.io/tidystata/reference/type_conversion.md) | tidystata | tostring | Alias of tostring(): stored codes as text |
| [`as_dummy()`](https://socimh.github.io/tidystata/reference/as_dummy.md) | tidystata |  | Dummy variables for every category |
| [`as_numeric()`](https://socimh.github.io/tidystata/reference/type_conversion.md) | tidystata | destring | Alias of destring() |
| [`assert()`](https://socimh.github.io/tidystata/reference/assert.md) | tidystata |  | Verify every condition for every row; otherwise report failing rows and stop |
| [`browse()`](https://socimh.github.io/tidystata/reference/browse.md) | tidystata |  | View data in a spreadsheet window |
| [`capture()`](https://socimh.github.io/tidystata/reference/capture.md) | tidystata |  | Preserve successful results and visibility; report errors and return invisible NULL; quiet suppresses warnings and messages |
| [`codebook()`](https://socimh.github.io/tidystata/reference/codebook.md) | tidystata |  | Describe every variable: type, variable label, observed count and distinct count |
| [`corr()`](https://socimh.github.io/tidystata/reference/corr.md) | tidystata |  | Pearson correlations on one common complete-case sample, with counts, optional groups or weights, and no p-values |
| [`cut_breaks()`](https://socimh.github.io/tidystata/reference/cut.md) | tidystata |  | Cut at chosen cutpoints, extending end intervals to the observed range |
| [`cut_length()`](https://socimh.github.io/tidystata/reference/cut.md) | tidystata |  | Cut numeric values into equal-width intervals; labels = FALSE returns integer codes |
| [`cut_quantile()`](https://socimh.github.io/tidystata/reference/cut.md) | tidystata | xtile | Alias of xtile() |
| [`decode()`](https://socimh.github.io/tidystata/reference/type_conversion.md) | tidystata |  | Convert to text, using value labels for labelled data |
| [`destring()`](https://socimh.github.io/tidystata/reference/type_conversion.md) | tidystata |  | Convert to numbers, dropping value labels |
| [`ds()`](https://socimh.github.io/tidystata/reference/names.md) | tidystata |  | List variable names |
| [`duplicates_drop()`](https://socimh.github.io/tidystata/reference/keys.md) | tidystata |  | Drop duplicated rows, keeping the first |
| [`duplicates_list()`](https://socimh.github.io/tidystata/reference/keys.md) | tidystata |  | List duplicated rows |
| [`duplicates_report()`](https://socimh.github.io/tidystata/reference/keys.md) | tidystata |  | Count duplicated rows |
| [`duplicates_tag()`](https://socimh.github.io/tidystata/reference/keys.md) | tidystata |  | Mark duplicated rows |
| [`encode()`](https://socimh.github.io/tidystata/reference/type_conversion.md) | tidystata | encode | Encode character categories as labelled integer codes; preserve factor codes |
| [`findit()`](https://socimh.github.io/tidystata/reference/findit.md) | tidystata |  | Find the R equivalent of a Stata command |
| [`fre()`](https://socimh.github.io/tidystata/reference/tab.md) | tidystata |  | Joint frequency table like tab(), adding totals and displaying value labels |
| [`fre1()`](https://socimh.github.io/tidystata/reference/tab.md) | tidystata | tab1 | One one-way table per variable like tab1(), adding totals and displaying value labels |
| [`fre2()`](https://socimh.github.io/tidystata/reference/tab.md) | tidystata | tabulate | Pairwise cross-tabulations like tab2(), adding totals and row labels; column headers keep category codes |
| [`is_first()`](https://socimh.github.io/tidystata/reference/is_first.md) | tidystata |  | Mark the first row of each group |
| [`isid()`](https://socimh.github.io/tidystata/reference/keys.md) | tidystata |  | Confirm unique keys with a message and return data invisibly; .missing allows missing keys and empty strings |
| [`misstable()`](https://socimh.github.io/tidystata/reference/misstable.md) | tidystata |  | Missing values per variable, or missing-value patterns |
| [`mvdecode()`](https://socimh.github.io/tidystata/reference/na_conversion.md) | tidystata |  | Turn given codes into missing values |
| [`mvencode()`](https://socimh.github.io/tidystata/reference/na_conversion.md) | tidystata |  | Replace missing values with a code |
| [`na_if_value()`](https://socimh.github.io/tidystata/reference/na_conversion.md) | tidystata | mvdecode | Alias of mvdecode() |
| [`pc()`](https://socimh.github.io/tidystata/reference/std.md) | tidystata |  | Percentage of the total, not a percentile rank; prop = TRUE returns proportions |
| `pct()` | tidystata | egen pc() | Removed alias of pc(); use pc() for total shares and dplyr::percent_rank() for percentile ranks |
| [`preview()`](https://socimh.github.io/tidystata/reference/preview.md) | tidystata |  | Persist a head/tail or interval console preview (10 data rows by default), retaining every row and column |
| [`preview_headtail()`](https://socimh.github.io/tidystata/reference/preview.md) | tidystata |  | Persist a first-and-last-row preview; a row of dots marks an omitted middle; all data are retained |
| [`preview_interval()`](https://socimh.github.io/tidystata/reference/preview.md) | tidystata |  | Persist an approximately evenly spaced row preview without separator rows, retaining all data |
| [`print_headtail()`](https://socimh.github.io/tidystata/reference/special-print.md) | tidystata |  | Print first and last rows once with a dotted omission row; return the complete input invisibly without changing preview preferences |
| [`print_interval()`](https://socimh.github.io/tidystata/reference/special-print.md) | tidystata |  | Print approximately evenly spaced rows once without separator rows; return the complete input invisibly without changing preview preferences |
| [`pwcorr()`](https://socimh.github.io/tidystata/reference/corr.md) | tidystata |  | Pearson or Spearman correlations with pairwise samples by default; .listwise keeps p-values on one common sample; optional Bonferroni or Sidak adjustment within each group |
| [`recode()`](https://socimh.github.io/tidystata/reference/stata_recode.md) | tidystata | recode | Alias of stata_recode() |
| [`row_max()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | Maximum across variables in each row |
| [`row_mean()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | Mean across variables in each row |
| [`row_median()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | Median across variables in each row |
| [`row_min()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | Minimum across variables in each row |
| [`row_miss()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | Number of missing values in each row |
| [`row_non_miss()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | Number of observed values in each row |
| [`row_nvals()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | Number of distinct values in each row, ignoring missing values |
| [`row_sd()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | Standard deviation across variables in each row |
| [`row_sum()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | Sum across variables in each row |
| [`row_unique()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata | egen rownvals() | Number of distinct values in each row, counting missing as one |
| [`row_var()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | Sample variance across variables in each row |
| [`select_or_transmute()`](https://socimh.github.io/tidystata/reference/select_or_transmute.md) | tidystata |  | Return selected and computed columns, retaining grouping columns |
| [`set_seed()`](https://socimh.github.io/tidystata/reference/set_seed.md) | tidystata |  | Set the random seed, alone or at the end of a pipe |
| [`spearman()`](https://socimh.github.io/tidystata/reference/corr.md) | tidystata |  | Unweighted Spearman rank correlations on one common complete-case sample by default; .pairwise uses separate samples; returns r, n and Stata 18+ p-values with optional within-group adjustment |
| [`stata_diff()`](https://socimh.github.io/tidystata/reference/panel.md) | tidystata |  | Difference from the previous period, respecting time gaps |
| [`stata_lag()`](https://socimh.github.io/tidystata/reference/panel.md) | tidystata |  | Value from an earlier period, respecting time gaps |
| [`stata_lead()`](https://socimh.github.io/tidystata/reference/panel.md) | tidystata |  | Value from a later period, respecting time gaps |
| [`stata_merge()`](https://socimh.github.io/tidystata/reference/stata_merge.md) | tidystata |  | Merge two tables and report matches, like Stata's merge |
| [`stata_recode()`](https://socimh.github.io/tidystata/reference/stata_recode.md) | tidystata |  | Recode numeric values with Stata-style ranges, value sets and labels; unmatched values are kept |
| [`std()`](https://socimh.github.io/tidystata/reference/std.md) | tidystata |  | Z-scores: subtract the observed mean and divide by the sample SD |
| [`summ()`](https://socimh.github.io/tidystata/reference/summ.md) | tidystata |  | Summary statistics for variables |
| [`tab()`](https://socimh.github.io/tidystata/reference/tab.md) | tidystata |  | Count joint category combinations in one long table with frequencies and percentages |
| [`tab_gen()`](https://socimh.github.io/tidystata/reference/as_dummy.md) | tidystata | tabulate, generate() | Alias of as_dummy() |
| [`tab1()`](https://socimh.github.io/tidystata/reference/tab.md) | tidystata |  | One one-way frequency table per variable; returns a list by default |
| [`tab2()`](https://socimh.github.io/tidystata/reference/tab.md) | tidystata |  | Wide cross-tabulations for every variable pair; explicit .by creates grouped tables |
| [`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md) | tidystata |  | Chosen statistics for variables, optionally by group |
| [`timer()`](https://socimh.github.io/tidystata/reference/timer.md) | tidystata |  | Time how long code takes |
| [`tostring()`](https://socimh.github.io/tidystata/reference/type_conversion.md) | tidystata |  | Convert to text, keeping codes rather than value labels |
| [`unpreview()`](https://socimh.github.io/tidystata/reference/preview.md) | tidystata |  | Restore ordinary printing by removing preview preferences, retaining all data and grouping |
| [`value_if_na()`](https://socimh.github.io/tidystata/reference/na_conversion.md) | tidystata | mvencode | Alias of mvencode() |
| [`var_type()`](https://socimh.github.io/tidystata/reference/var_type.md) | tidystata |  | Describe storage type or class, optionally using an abbreviation |
| [`var_unit()`](https://socimh.github.io/tidystata/reference/var_type.md) | tidystata |  | Read measurement or duration units; return NA_character\_ when absent |
| [`variables()`](https://socimh.github.io/tidystata/reference/variables.md) | tidystata |  | List variables with their types and labels |
| [`variables_search()`](https://socimh.github.io/tidystata/reference/variables.md) | tidystata |  | Find variables by name or label |
| [`varlist()`](https://socimh.github.io/tidystata/reference/varlist.md) | tidystata |  | Select variables with Stata wildcards such as x\* |
| [`xtile()`](https://socimh.github.io/tidystata/reference/cut.md) | tidystata |  | Quantile groups using Stata's rule; ties stay together; grouped data masks default to integer codes |
| `md5sum()` | tools | checksum | Compute MD5 Checksums |
| `garch()` | tseries | arch | Fit GARCH Models to Time Series |
| `as_tsibble()` | tsibble |  | Declare time-series or panel data |
| `fill_gaps()` | tsibble |  | Add rows for missing time points |
| `yearmonth()` | tsibble |  | Monthly period |
| `yearquarter()` | tsibble |  | Quarterly period |
| `ca.jo()` | urca | vecrank | Johansen Procedure for VAR |
| `cajorls()` | urca | vec | OLS regression of VECM |
| `ur.df()` | urca | dfuller | Augmented-Dickey-Fuller Unit Root Test |
| `ur.ers()` | urca | dfgls | Elliott, Rothenberg and Stock Unit Root Test |
| `ur.pp()` | urca | pperron | Phillips and Perron Unit Root Test |
| [`capture.output()`](https://rdrr.io/r/utils/capture.output.html) | utils | dataex | Send Output to a Character String or File |
| [`combn()`](https://rdrr.io/r/utils/combn.html) | utils | tab2 | Generate All Combinations of n Elements, Taken m at a Time |
| [`data()`](https://rdrr.io/r/utils/data.html) | utils |  | Load a built-in example dataset |
| [`getAnywhere()`](https://rdrr.io/r/utils/getAnywhere.html) | utils |  | Find where a function is defined |
| [`glob2rx()`](https://rdrr.io/r/utils/glob2rx.html) | utils |  | Turn a wildcard pattern into a regular expression |
| [`head()`](https://rdrr.io/r/utils/head.html) | utils |  | First rows |
| [`help()`](https://rdrr.io/r/utils/help.html) | utils |  | Open a help page |
| [`help.search()`](https://rdrr.io/r/utils/help.search.html) | utils |  | Search all installed help pages |
| [`install.packages()`](https://rdrr.io/r/utils/install.packages.html) | utils |  | Install a package from CRAN |
| [`object.size()`](https://rdrr.io/r/utils/object.size.html) | utils | memory | Report the Space Allocated for an Object |
| [`packageVersion()`](https://rdrr.io/r/utils/packageDescription.html) | utils | ftools | Package Description |
| [`read.csv()`](https://rdrr.io/r/utils/read.table.html) | utils | import delimited | Read a CSV file (base R) |
| [`read.delim()`](https://rdrr.io/r/utils/read.table.html) | utils | import | Data Input |
| [`read.fwf()`](https://rdrr.io/r/utils/read.fwf.html) | utils | infix | Read Fixed Width Format Files |
| [`read.table()`](https://rdrr.io/r/utils/read.table.html) | utils | infile | Data Input |
| [`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html) | utils | about | Collect Information About the Current R Session |
| [`str()`](https://rdrr.io/r/utils/str.html) | utils |  | Compact view of an object's structure |
| [`tail()`](https://rdrr.io/r/utils/head.html) | utils |  | Last rows |
| [`unzip()`](https://rdrr.io/r/utils/unzip.html) | utils | unzipfile | Extract or List Zip Archives |
| [`update.packages()`](https://rdrr.io/r/utils/update.packages.html) | utils |  | Update installed packages |
| [`View()`](https://rdrr.io/r/utils/View.html) | utils | browse | Open the data viewer |
| [`write.csv()`](https://rdrr.io/r/utils/write.table.html) | utils | export delimited | Write a CSV file (base R) |
| [`write.table()`](https://rdrr.io/r/utils/write.table.html) | utils | outfile | Data Output |
| `binom2.rho()` | VGAM | biprobit | Bivariate Probit Regression |
| `cens.poisson()` | VGAM | cpoisson | Censored Poisson Family Function |
| `multinomial()` | VGAM | slogit | Multinomial Logit Model |
| `posnegbinomial()` | VGAM | tnbreg | Positive Negative Binomial Distribution Family Function |
| `posnormal()` | VGAM | truncreg | Positive Normal Distribution Family Function |
| `pospoisson()` | VGAM | tpoisson | Positive Poisson Distribution Family Function |
| `rrvglm()` | VGAM | slogit | Fitting Reduced-Rank Vector Generalized Linear Models (RR-VGLMs) and Doubly Constrained RR-VGLMs (DRR-VGLMs) |
| `SurvS4()` | VGAM | cpoisson | Create a Survival Object |
| `vglm()` | VGAM | tpoisson | Fitting Vector Generalized Linear Models |
| `weightit()` | WeightIt |  | Balancing weights, such as inverse-probability weights |
| `write_xlsx()` | writexl |  | Write an Excel file |
| `zipr()` | zip | zipfile | Compress Files into 'zip' Archives |
| `na.locf()` | zoo | stfill | Last Observation Carried Forward |
| `rollapply()` | zoo | rolling | Apply Rolling Functions |

## Chaptered edition

Prefer separate chapters? The [standalone Stata to R
reference](https://www.socimh.com/stata-to-r/) provides chapter
navigation and expandable alternatives on a separate website. It opens
in a new tab, keeping the tidystata website available here.
