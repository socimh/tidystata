# 从 Stata 到 R

[English
version](https://socimh.github.io/tidystata/articles/coming-from-stata.md)

需要按章节浏览、搜索或展开替代实现时，请打开 **[Stata 转 R
参考手册](https://www.socimh.com/stata-to-r/zh/)**。
手册提供中英文两个版本，每章均可切换语言。本页继续保留完整的单页对照表。

熟悉 Stata 的用户已经知道自己想做什么，需要的只是知道在 R
中怎么写。本页把 Stata 命令和完成同样任务的 R 代码并列：tidystata 中有
Stata 风格函数的，使用 tidystata；其他情况使用常用的 R 包。

## 在 R 中直接查询

[`findit()`](https://socimh.github.io/tidystata/reference/findit.md) 在
R 中查询同一份列表。单个 Stata
命令可以不加引号，更长的内容需要加引号；支持 Stata
的标准缩写。说明文字随 R
的语言设置显示为中文或英文，两种语言的查询都可使用。

``` r

findit(reg)
#> # Linear regression [stats]
#> Stata: regress y x1 x2
#> R:     fit <- lm(y ~ x1 + x2, data = data)
#> # Note: summary(fit) shows the coefficient table; broom::tidy(fit) returns it as a data frame.
#> 
#> # 17 more examples. To see them all: findit(reg) |> print(n = Inf)
findit("merge 1:1 id, keep(match)")
#> # Keep matched rows only [dplyr]
#> Stata: merge 1:1 id using data2, keep(match)
#> R:     inner_join(data1, data2, by = "id")
#> # Note: dplyr retains overlapping non-key columns with suffixes instead of Stata master values, creates no _merge, and does not enforce a declared 1:1 key constraint.
#> 
#> # merge() [base]: Merge two data frames (base R)
#>   Related Stata: merge
#> 
#> # 17 more examples. To see them all: findit("merge 1:1 id, keep(match)") |> print(n = Inf)
```

也可以查询 R
函数（`findit(left_join)`），或直接提问（`findit("如何删除重复行")`）。
控制台显示最相关的结果，返回的表保留全部匹配项；不带参数的
[`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
返回完整列表。

逗号分隔的变量名会填入兼容的示例，例如
`findit(tab, sex, region)`。任务明确时默认只显示
一个优先推荐的答案；`findit(tab) |> print(n = Inf)` 展开全部变体、精选的
R 实现、 差异说明和参考链接。`findit(dplyr::filter)`
这样的包限定查询可以区分同名函数。

本指南包含 514 个命令族、181 个 Stata 函数和 3 个运算符，共有 1716
个不同的 Stata 示例和 1782 条 R 对照示例。缩写及同一任务的其他 R
实现不会增加命令数量。 R 函数索引包含 949 个函数与包的组合。

## 使用命令对照表

下表涵盖 tidystata 和其他常用 R 包，包括建模、长宽转换、调查分析和作图。
面板滞后、超前和差分可使用 tidystata 的
[`stata_lag()`](https://socimh.github.io/tidystata/reference/panel.md)、[`stata_lead()`](https://socimh.github.io/tidystata/reference/panel.md)
和
[`stata_diff()`](https://socimh.github.io/tidystata/reference/panel.md)；指定时间列，并用
`.by` 区分面板。

索引按字母顺序排列，对照表按主题分组，并依次按命令、推荐顺序和示例排序。
运行某个示例需要其标注的 R
包；[`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
本身不会加载或安装这些参考包。
包标签只列出主要实现包，并不列出所有辅助依赖；R
函数索引标明其他函数及其所属包。

以 **与 Stata 有差异** 开头的说明表示 R
代码完成相同任务，但默认设置、缺失值处理、
估计方法或输出形式有所不同，说明会列出具体差异。其余说明是使用提示。多数
R 示例在构建目录时 运行核验，检查的是 R 代码本身，并非与 Stata
的数值一致性检验。缺失值比较、权重、因子参照组、连接规则和标准误修正尤其需要核对。
已知缺口会明确说明，相关搜索结果不代表已经实现查询中尚未支持的语法。

下表中，`data` 是你的数据，`data1` 和 `data2`
是合并时的主数据和被合并数据，`fit` 是已估计的模型。大部分条目使用
dplyr，请先用 [`library(dplyr)`](https://dplyr.tidyverse.org) 或
[`library(tidyverse)`](https://tidyverse.tidyverse.org) 加载。

## 命令字母索引

[F](#example-ref-5c1a42b934cb6b4f) ·
[Fden](#example-ref-04e11edb60d43424) ·
[Ftail](#example-ref-a7f21b2b3b0647fb) ·
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
[export](#example-legacy-0020) · [f.](#example-legacy-0359) ·
[factor](#example-legacy-0084) ·
[factormat](#example-ref-a0421b00c54bf2a7) ·
[fcast](#example-ref-a303bdc04fa81a48) ·
[fcollapse](#example-ref-ff005b44b4bc06f9) ·
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
[invF](#example-ref-7822f727ce3a3dfe) ·
[invFtail](#example-ref-d4e72ece99ff3f05) ·
[invbinomial](#example-ref-132aa6c600b88f03) ·
[invbinomialtail](#example-ref-bc59ee2e9a87253e) ·
[invcauchy](#example-ref-1e7da01122eba0c2) ·
[invcauchytail](#example-ref-f6437dde18a3cc25) ·
[invchi2](#example-ref-2a448ae96c7604a7) ·
[invchi2tail](#example-ref-23306c7dbf504d73) ·
[invexponential](#example-ref-29514def6e9ecbad) ·
[invexponentialtail](#example-ref-7b571ba451d3e054) ·
[invgammap](#example-ref-2265ddfe6d1a8f29) ·
[invgammaptail](#example-ref-bf84d422d26193ae) ·
[invibeta](#example-ref-8bc4b3768425541a) ·
[invibetatail](#example-ref-88d1fec121a169d0) ·
[invlogistic](#example-ref-62040f03f7fc4986) ·
[invlogistictail](#example-ref-46db3a062f66d769) ·
[invnF](#example-ref-f415a39bfdae4e2a) ·
[invnFtail](#example-ref-d5ae4af1368a8f05) ·
[invnbinomial](#example-ref-2549a0c3e9f10f22) ·
[invnbinomialtail](#example-ref-e4993aa3c1347631) ·
[invnchi2](#example-ref-047e7eddf232874f) ·
[invnchi2tail](#example-ref-22999e358ff1bb18) ·
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
[nF](#example-ref-aa746531f0a8f6c2) ·
[nFden](#example-ref-ff8abb410d9cc40c) ·
[nFtail](#example-ref-52cf941ab80e5328) ·
[nbetaden](#example-ref-d59c43dd30954b2f) ·
[nbinomial](#example-ref-12787c749e7717df) ·
[nbinomialp](#example-ref-55d623f908e6e118) ·
[nbinomialtail](#example-ref-640cde916b8f4f61) ·
[nbreg](#example-legacy-0314) · [nchi2](#example-ref-568e3f754132870a) ·
[nchi2den](#example-ref-f39a41d2d1177e93) ·
[nchi2tail](#example-ref-b77aba953ed51020) ·
[nestreg](#example-ref-c0e97b6e48d38b6c) · [net](#example-legacy-0011) ·
[newey](#example-ref-c263eba9cf3fb057) ·
[nibeta](#example-ref-108f4c14a7573c1b) ·
[nl](#example-ref-3366d57f680bc9fd) · [nlcom](#example-legacy-0330) ·
[normal](#example-ref-34e7210a02898239) ·
[normalden](#example-ref-493740d06c458ca9) ·
[notes](#example-legacy-0107) · [npnF](#example-ref-6b33380e283b39a7) ·
[npnchi2](#example-ref-5b19051b8727105b) ·
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

## 基础功能

[TABLE]

## 探索数据

[TABLE]

## 检查数据

[TABLE]

## 变量和数值标签

[TABLE]

## 构造和修改变量

[TABLE]

## 筛选变量或个案

[TABLE]

## 排列变量或个案

[TABLE]

## 合并数据

[TABLE]

## 转换长、宽数据

[TABLE]

## 构造数据

[TABLE]

## 字符串与日期

[TABLE]

## 循环和编程

[TABLE]

## 模型和结果表

[TABLE]

## 面板和时间序列

[TABLE]

## 生存分析

[TABLE]

## 调查数据

[TABLE]

## 作图

[TABLE]

## 编程工具

[TABLE]

## 数据管理

[TABLE]

## 文件与导入导出

[TABLE]

## 标签与元数据

[TABLE]

## 描述性表格

[TABLE]

## 模型与检验

[TABLE]

## 统计分布

[TABLE]

## 模型与估计

[TABLE]

## 估计后分析与诊断

[TABLE]

## 假设检验与置信区间

[TABLE]

## 多变量与心理测量方法

[TABLE]

## 检验功效与精度设计

[TABLE]

## 重抽样与模拟

[TABLE]

## 模型报告

[TABLE]

## 空间分析流程

[TABLE]

## 因果推断

[TABLE]

## 面板数据

[TABLE]

## 时间序列与预测

[TABLE]

## 复杂抽样分析

[TABLE]

## 元分析

[TABLE]

## 多重插补

[TABLE]

## 多层模型

[TABLE]

## 流行病学

[TABLE]

## 贝叶斯分析

[TABLE]

## 按包查阅 R 函数

| R | 包 | Stata | 说明 |
|----|----|----|----|
| `ivreg()` | AER | ivregress | 示例用途：公式式工具变量回归 |
| `tobit()` | AER |  | Tobit（删失）回归 |
| `dbAppendTable()` | DBI | jdbc | 示例用途：将受控行追加到已有 SQL 表 |
| `dbDisconnect()` | DBI | odbc | 示例用途：通过 SQL 查询载入所选行 |
| `dbGetQuery()` | DBI | odbc | 示例用途：通过 SQL 查询载入所选行 |
| `dbListFields()` | DBI | odbc | 示例用途：查看数据库表字段名 |
| `dbListTables()` | DBI | odbc | 示例用途：查看数据库中的可用表 |
| `dbReadTable()` | DBI | jdbc | 示例用途：通过 DBI 后端载入完整 SQL 表 |
| `oblimin()` | GPArotation | rotate | 示例用途：使用斜交oblimin载荷旋转准则 |
| `quartimax()` | GPArotation | rotate | 示例用途：使用正交quartimax载荷旋转准则 |
| `boxcox()` | MASS | boxcox | 示例用途：剖面估计Box-Cox响应变换参数 |
| `corresp()` | MASS | ca | 示例用途：对列联表进行简单对应分析 |
| `glm.nb()` | MASS |  | 负二项回归 |
| `isoMDS()` | MASS | mds | 示例用途：拟合非度量多维尺度分析 |
| `lda()` | MASS | discrim | 示例用途：拟合线性判别分析 |
| `mca()` | MASS | mca | 示例用途：通过指示矩阵MCA分析多个分类变量 |
| `mvrnorm()` | MASS | drawnorm | 示例用途：联合生成独立标准正态变量列 |
| `polr()` | MASS |  | 有序 logit 或 probit 模型 |
| `qda()` | MASS | discrim | 示例用途：拟合二次判别分析 |
| `rlm()` | MASS |  | 稳健回归 |
| `MCMCregress()` | MCMCpack | bayesmh | 示例用途：正态及逆Gamma先验的贝叶斯高斯回归 |
| `match_data()` | MatchIt | psmatch2 | 示例用途：倾向得分匹配后的ATT点对比 |
| `matchit()` | MatchIt |  | 用于因果推断的匹配 |
| `synth()` | Synth |  | 合成控制法 |
| `SurvS4()` | VGAM | cpoisson | 示例用途：拟合右删失泊松计数模型 |
| `binom2.rho()` | VGAM | biprobit | 示例用途：联合拟合相关的二元probit方程 |
| `cens.poisson()` | VGAM | cpoisson | 示例用途：拟合右删失泊松计数模型 |
| `multinomial()` | VGAM | slogit | 示例用途：拟合秩一刻板多项logit模型 |
| `posnegbinomial()` | VGAM | tnbreg | 示例用途：拟合零截断NB2回归 |
| `posnormal()` | VGAM | truncreg | 示例用途：拟合在零处左截断的正态回归 |
| `pospoisson()` | VGAM | tpoisson | 示例用途：拟合零截断泊松回归 |
| `rrvglm()` | VGAM | slogit | 示例用途：拟合秩一刻板多项logit模型 |
| `vglm()` | VGAM | tpoisson | 示例用途：拟合零截断泊松回归 |
| `weightit()` | WeightIt |  | 平衡权重，如逆概率权重 |
| [`.libPaths()`](https://rdrr.io/r/base/libPaths.html) | base | adopath | 示例用途：查看 R 包库搜索路径 |
| [`I()`](https://rdrr.io/r/base/AsIs.html) | base | regress | 示例用途：拟合二次项回归 |
| [`Mod()`](https://rdrr.io/r/base/complex.html) | base | psdensity | 示例用途：参数化AR(1)谱密度 |
| [`R.home()`](https://rdrr.io/r/base/Rhome.html) | base | sysdir | 示例用途：查看 R 安装与临时文件夹 |
| [`Sys.Date()`](https://rdrr.io/r/base/Sys.time.html) | base |  | 今天的日期 |
| [`Sys.sleep()`](https://rdrr.io/r/base/Sys.sleep.html) | base | sleep | 示例用途：将毫秒转为秒后暂停执行 |
| [`Sys.time()`](https://rdrr.io/r/base/Sys.time.html) | base | c(current_time) | 当前日期和时间 |
| [`abs()`](https://rdrr.io/r/base/MathFun.html) | base | abs() | 绝对值 |
| [`all()`](https://rdrr.io/r/base/all.html) | base | assert | 是否所有值都为 TRUE |
| [`any()`](https://rdrr.io/r/base/any.html) | base | count if | 是否有任一值为 TRUE |
| [`anyDuplicated()`](https://rdrr.io/r/base/duplicated.html) | base | gisid | 示例用途：使用 gisid 验证编号唯一且完整 |
| [`anyNA()`](https://rdrr.io/r/base/NA.html) | base | gisid | 示例用途：使用 gisid 验证编号唯一且完整 |
| [`apply()`](https://rdrr.io/r/base/apply.html) | base | egen rowtotal() | 对行或列应用函数 |
| [`as.Date()`](https://rdrr.io/r/base/as.Date.html) | base |  | 转为日期 |
| [`as.POSIXct()`](https://rdrr.io/r/base/as.POSIXlt.html) | base | clock | 示例用途：使用显式 UTC 时区解析日期时间 |
| [`as.character()`](https://rdrr.io/r/base/character.html) | base |  | 转为文本 |
| [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) | base | getmata | 示例用途：将矩阵转换为具名数据列 |
| [`as.double()`](https://rdrr.io/r/base/double.html) | base |  | 转为双精度数值 |
| [`as.factor()`](https://rdrr.io/r/base/factor.html) | base | encode | 转为因子 |
| [`as.integer()`](https://rdrr.io/r/base/integer.html) | base |  | 转为整数 |
| [`as.matrix()`](https://rdrr.io/r/base/matrix.html) | base | cf | 示例用途：验证两个数据表指定列的值一致 |
| [`as.numeric()`](https://rdrr.io/r/base/numeric.html) | base |  | 转为数值 |
| [`as.vector()`](https://rdrr.io/r/base/vector.html) | base | margins | 示例用途：计算连续解释变量的平均边际效应 |
| [`attr()`](https://rdrr.io/r/base/attr.html) | base |  | 读取或设定对象的属性 |
| [`attributes()`](https://rdrr.io/r/base/attributes.html) | base | char | 示例用途：查看自定义列特征 |
| [`body()`](https://rdrr.io/r/base/body.html) | base | viewsource | 示例用途：查看指定 R 函数的函数体 |
| [`c()`](https://rdrr.io/r/base/c.html) | base |  | 把多个值组合成向量 |
| [`cat()`](https://rdrr.io/r/base/cat.html) | base |  | 打印不带引号的文本 |
| [`cbind()`](https://rdrr.io/r/base/cbind.html) | base | merge 1:1 \_n | 左右拼接（base R） |
| [`ceiling()`](https://rdrr.io/r/base/Round.html) | base |  | 向上取整 |
| [`charToRaw()`](https://rdrr.io/r/base/rawConversion.html) | base | changeeol | 示例用途：将文本文件换行统一为 Unix 格式 |
| [`character()`](https://rdrr.io/r/base/character.html) | base | tokenize | 示例用途：拆分带引号短语与单词 |
| [`chol()`](https://rdrr.io/r/base/chol.html) | base | irf | 示例用途：Cholesky正交化VAR响应 |
| [`class()`](https://rdrr.io/r/base/class.html) | base | describe | 对象的类 |
| [`close()`](https://rdrr.io/r/base/connections.html) | base | file | 示例用途：写入并关闭 UTF-8 文本连接 |
| [`col()`](https://rdrr.io/r/base/col.html) | base | spmatrix | 示例用途：行标准化逆距离空间权重 |
| [`colMeans()`](https://rdrr.io/r/base/colSums.html) | base | margins | 示例用途：计算连续解释变量的平均边际效应 |
| [`colSums()`](https://rdrr.io/r/base/colSums.html) | base | missings | 示例用途：按数值变量报告缺失值数 |
| [`colnames()`](https://rdrr.io/r/base/colnames.html) | base | ds | 列名 |
| [`crossprod()`](https://rdrr.io/r/base/crossprod.html) | base | tsfilter | 示例用途：Hodrick-Prescott趋势周期分解 |
| [`cumprod()`](https://rdrr.io/r/base/cumsum.html) | base | generate | 累计乘积 |
| [`cumsum()`](https://rdrr.io/r/base/cumsum.html) | base |  | 累计求和 |
| [`cut()`](https://socimh.github.io/tidystata/reference/cut.md) | base |  | 把数值切分为区间 |
| [`data.frame()`](https://rdrr.io/r/base/data.frame.html) | base | range | 示例用途：创建包含端点的等距网格 |
| [`diag()`](https://rdrr.io/r/base/diag.html) | base |  | 矩阵的对角线 |
| [`diff()`](https://rdrr.io/r/base/diff.html) | base | D. | 相邻取值之差 |
| [`dim()`](https://rdrr.io/r/base/dim.html) | base | describe | 行数和列数 |
| [`dir()`](https://rdrr.io/r/base/list.files.html) | base |  | 列出文件夹中的文件 |
| [`dir.create()`](https://rdrr.io/r/base/files2.html) | base | mkdir | 创建文件夹 |
| [`do.call()`](https://rdrr.io/r/base/do.call.html) | base | program | 用参数列表调用函数 |
| [`double()`](https://rdrr.io/r/base/double.html) | base | postfile | 示例用途：初始化带列类型的结果容器 |
| [`dput()`](https://rdrr.io/r/base/dput.html) | base | dataex | 示例用途：为小型数据示例生成可复现 R 代码 |
| [`drop()`](https://rdrr.io/r/base/drop.html) | base | lincom | 示例用途：估计两个斜率之和及标准误 |
| [`droplevels()`](https://rdrr.io/r/base/droplevels.html) | base | label define | 删除未使用的因子水平 |
| [`duplicated()`](https://rdrr.io/r/base/duplicated.html) | base | gegen | 示例用途：标记各非缺失组的一条观测 |
| [`eigen()`](https://rdrr.io/r/base/eigen.html) | base | varstable | 示例用途：VAR(1)伴随矩阵特征值 |
| [`environment()`](https://rdrr.io/r/base/environment.html) | base | include | 示例用途：在当前求值环境执行辅助代码 |
| [`exp()`](https://rdrr.io/r/base/Log.html) | base | exp() | 指数函数 |
| [`expand.grid()`](https://rdrr.io/r/base/expand.grid.html) | base | arimasoc | 示例用途：ARMA信息准则比较 |
| [`factor()`](https://rdrr.io/r/base/factor.html) | base |  | 带标签水平的类别变量 |
| [`file()`](https://rdrr.io/r/base/connections.html) | base | file | 示例用途：写入并关闭 UTF-8 文本连接 |
| [`file.copy()`](https://rdrr.io/r/base/files.html) | base | copy | 示例用途：复制本地文件到新路径 |
| [`file.exists()`](https://rdrr.io/r/base/files.html) | base | confirm file | 文件是否存在 |
| [`file.info()`](https://rdrr.io/r/base/file.info.html) | base | hexdump | 示例用途：以十六进制字节查看文件 |
| [`file.path()`](https://rdrr.io/r/base/file.path.html) | base | global path | 构建文件路径 |
| [`floor()`](https://rdrr.io/r/base/Round.html) | base |  | 向下取整 |
| [`format()`](https://rdrr.io/r/base/format.html) | base |  | 设定显示格式 |
| [`formatC()`](https://rdrr.io/r/base/formatc.html) | base | string(x, "%9.2f") | 按宽度和填充格式化数值 |
| [`getwd()`](https://rdrr.io/r/base/getwd.html) | base |  | 显示工作文件夹 |
| [`grep()`](https://rdrr.io/r/base/grep.html) | base | unab | 示例用途：展开列名前缀通配符 |
| [`grepl()`](https://rdrr.io/r/base/grep.html) | base |  | 文本是否匹配某个模式 |
| [`gsub()`](https://rdrr.io/r/base/grep.html) | base | subinstr() | 替换所有匹配 |
| [`iconv()`](https://rdrr.io/r/base/iconv.html) | base | unicode | 示例用途：将 Latin-1 文本转换为 UTF-8 |
| [`identical()`](https://rdrr.io/r/base/identical.html) | base | cf | 示例用途：验证两个数据表指定列的值一致 |
| [`ifelse()`](https://rdrr.io/r/base/ifelse.html) | base | cond() | 向量化的条件判断（base R） |
| [`integer()`](https://rdrr.io/r/base/integer.html) | base | gdistinct | 示例用途：分别统计多列不同值数 |
| [`interaction()`](https://rdrr.io/r/base/interaction.html) | base | egen group() | 把多个因子组合为一个 |
| [`invisible()`](https://rdrr.io/r/base/invisible.html) | base | exit | 示例用途：提前从函数返回 |
| [`is.character()`](https://rdrr.io/r/base/character.html) | base | confirm string variable | 向量是否为文本型 |
| [`is.infinite()`](https://rdrr.io/r/base/is.finite.html) | base | gencohort | 示例用途：构造首次处理队列并标记从未处理者 |
| [`is.na()`](https://rdrr.io/r/base/NA.html) | base |  | 是否为缺失值 |
| [`is.nan()`](https://rdrr.io/r/base/is.finite.html) | base | egen | 示例用途：对多列可用值逐行求均值 |
| [`is.numeric()`](https://rdrr.io/r/base/numeric.html) | base | confirm numeric variable | 向量是否为数值型 |
| [`lapply()`](https://rdrr.io/r/base/lapply.html) | base | foreach | 对每个元素应用函数，返回列表 |
| [`length()`](https://rdrr.io/r/base/length.html) | base | count | 元素个数 |
| [`lengths()`](https://rdrr.io/r/base/lengths.html) | base | wordcount | 示例用途：统计简单空白分隔词数 |
| [`levels()`](https://rdrr.io/r/base/levels.html) | base |  | 因子的类别 |
| [`library()`](https://rdrr.io/r/base/library.html) | base | ssc install | 加载包 |
| [`list()`](https://rdrr.io/r/base/list.html) | base |  | 对象列表 |
| [`list.files()`](https://rdrr.io/r/base/list.files.html) | base | dir | 文件夹中的文件 |
| [`load()`](https://rdrr.io/r/base/load.html) | base | use | 从 .RData 文件载入对象 |
| [`local()`](https://rdrr.io/r/base/eval.html) | base | tempvar | 示例用途：在局部作用域使用临时向量计算 |
| [`log()`](https://rdrr.io/r/base/Log.html) | base |  | 对数（默认为自然对数） |
| [`log10()`](https://rdrr.io/r/base/Log.html) | base | log10() | 以 10 为底的对数 |
| [`logical()`](https://rdrr.io/r/base/logical.html) | base | missings | 示例用途：删除完全缺失的数值列 |
| [`ls()`](https://rdrr.io/r/base/ls.html) | base |  | 列出内存中的对象 |
| [`make.names()`](https://rdrr.io/r/base/make.names.html) | base |  | 把文本转为合法的名称 |
| [`mapply()`](https://rdrr.io/r/base/mapply.html) | base | arimasoc | 示例用途：ARMA信息准则比较 |
| [`match()`](https://rdrr.io/r/base/match.html) | base | rename | 示例用途：同时重命名多列 |
| [`match.arg()`](https://rdrr.io/r/base/match.arg.html) | base | unabcmd | 示例用途：在已知 R 选项中解析唯一缩写 |
| [`matrix()`](https://rdrr.io/r/base/matrix.html) | base |  | 生成矩阵 |
| [`max()`](https://rdrr.io/r/base/Extremes.html) | base |  | 最大值 |
| [`mean()`](https://rdrr.io/r/base/mean.html) | base |  | 均值 |
| [`merge()`](https://rdrr.io/r/base/merge.html) | base | merge | 合并两个数据框（base R） |
| [`message()`](https://rdrr.io/r/base/message.html) | base | display | 打印消息 |
| [`min()`](https://rdrr.io/r/base/Extremes.html) | base |  | 最小值 |
| [`names()`](https://socimh.github.io/tidystata/reference/names.md) | base |  | 对象的名称，例如列名 |
| [`nchar()`](https://rdrr.io/r/base/nchar.html) | base | strlen() | 字符个数 |
| [`ncol()`](https://rdrr.io/r/base/nrow.html) | base | describe | 列数 |
| [`nlevels()`](https://rdrr.io/r/base/nlevels.html) | base | levelsof | 因子水平个数 |
| [`normalizePath()`](https://rdrr.io/r/base/normalizePath.html) | base | findfile | 示例用途：在指定文件夹中查找文件 |
| [`nrow()`](https://rdrr.io/r/base/nrow.html) | base |  | 行数 |
| [`numeric()`](https://rdrr.io/r/base/numeric.html) | base | rangestat | 示例用途：在各闭区间数值键邻域内计算均值 |
| [`options()`](https://rdrr.io/r/base/options.html) | base | set | 设定全局选项 |
| [`order()`](https://rdrr.io/r/base/order.html) | base | sort | 使向量排序的位置 |
| [`paste()`](https://rdrr.io/r/base/paste.html) | base |  | 用分隔符连接文本 |
| [`paste0()`](https://rdrr.io/r/base/paste.html) | base |  | 不加分隔符连接文本 |
| [`plot()`](https://rdrr.io/r/graphics/plot.default.html) | base |  | 基础绘图 |
| [`pmatch()`](https://rdrr.io/r/base/pmatch.html) | base | unab | 示例用途：解析无歧义的缩写列名 |
| [`pmax()`](https://rdrr.io/r/base/Extremes.html) | base | max(a, b) | 多个向量的逐元素最大值 |
| [`pmin()`](https://rdrr.io/r/base/Extremes.html) | base | min(a, b) | 多个向量的逐元素最小值 |
| [`print()`](https://rdrr.io/r/base/print.html) | base |  | 打印对象 |
| [`prop.table()`](https://rdrr.io/r/base/proportions.html) | base |  | 把频数转为比例 |
| [`proportions()`](https://rdrr.io/r/base/proportions.html) | base | tabulate, row | 把表格转为比例 |
| [`qr()`](https://rdrr.io/r/base/qr.html) | base | orthog | 示例用途：按指定顺序对中心化解释变量列正交化 |
| [`qr.Q()`](https://rdrr.io/r/base/qraux.html) | base | orthog | 示例用途：按指定顺序对中心化解释变量列正交化 |
| [`range()`](https://rdrr.io/r/base/range.html) | base | summarize | 最小值和最大值 |
| [`rank()`](https://rdrr.io/r/base/rank.html) | base |  | 秩（相同取值取平均秩） |
| [`rbind()`](https://rdrr.io/r/base/cbind.html) | base | append | 上下拼接（base R） |
| [`readBin()`](https://rdrr.io/r/base/readBin.html) | base | hexdump | 示例用途：以十六进制字节查看文件 |
| [`readLines()`](https://rdrr.io/r/base/readLines.html) | base | changeeol | 示例用途：将文本文件换行统一为 Unix 格式 |
| [`readRDS()`](https://rdrr.io/r/base/readRDS.html) | base | use | 读取 R 对象文件（.rds） |
| [`regexpr()`](https://rdrr.io/r/base/grep.html) | base | strpos | 示例用途：定位 ASCII 子串并以零表示未找到 |
| [`rep()`](https://rdrr.io/r/base/rep.html) | base | expand | 重复取值 |
| [`rep_len()`](https://rdrr.io/r/base/rep.html) | base |  | 把取值重复到指定长度 |
| [`replace()`](https://rdrr.io/r/base/replace.html) | base | generate | 示例用途：生成忽略缺失值的累计和 |
| [`replicate()`](https://rdrr.io/r/base/lapply.html) | base | bootstrap | 示例用途：通过重抽样完整聚类自助估计均值 |
| [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html) | base | ftools | 示例用途：查看 R 数据操作包版本与可用性 |
| [`return()`](https://rdrr.io/r/base/function.html) | base | exit | 示例用途：提前从函数返回 |
| [`rev()`](https://rdrr.io/r/base/rev.html) | base | gsort | 反转顺序 |
| [`rm()`](https://rdrr.io/r/base/rm.html) | base |  | 从内存中删除对象 |
| [`round()`](https://rdrr.io/r/base/Round.html) | base |  | 按小数位数四舍五入 |
| [`row()`](https://rdrr.io/r/base/row.html) | base | spmatrix | 示例用途：行标准化逆距离空间权重 |
| [`rowMeans()`](https://rdrr.io/r/base/colSums.html) | base | egen | 示例用途：对多列可用值逐行求均值 |
| [`rowSums()`](https://rdrr.io/r/base/colSums.html) | base |  | 逐行求和 |
| [`sample()`](https://rdrr.io/r/base/sample.html) | base | sample | 随机抽取取值 |
| [`sample.int()`](https://rdrr.io/r/base/sample.html) | base | bsample | 示例用途：抽取非参数观测自助样本 |
| [`sapply()`](https://rdrr.io/r/base/lapply.html) | base | foreach | 对每个元素应用函数并简化结果 |
| [`save()`](https://rdrr.io/r/base/save.html) | base | save | 把对象保存为 .RData 文件 |
| [`saveRDS()`](https://rdrr.io/r/base/readRDS.html) | base |  | 把一个 R 对象保存到文件 |
| [`scale()`](https://rdrr.io/r/base/scale.html) | base | egen std() | 标准化列 |
| [`scan()`](https://rdrr.io/r/base/scan.html) | base | tokenize | 示例用途：拆分带引号短语与单词 |
| [`seq()`](https://rdrr.io/r/base/seq.html) | base |  | 数列 |
| [`seq_along()`](https://rdrr.io/r/base/seq.html) | base | \_n | 向量元素的位置 |
| [`seq_len()`](https://rdrr.io/r/base/seq.html) | base | \_n | 从 1 到 n 的整数 |
| [`serialize()`](https://rdrr.io/r/base/serialize.html) | base | datasignature | 示例用途：保存 R 序列化结果供后续比较 |
| [`set.seed()`](https://rdrr.io/r/base/Random.html) | base |  | 设定随机数种子 |
| [`setwd()`](https://rdrr.io/r/base/getwd.html) | base |  | 更换工作文件夹 |
| [`sign()`](https://rdrr.io/r/base/sign.html) | base | compare | 示例用途：比较指定子样本中的取值大小 |
| [`signif()`](https://rdrr.io/r/base/Round.html) | base | round() | 按有效数字取舍 |
| [`sin()`](https://rdrr.io/r/base/Trig.html) | base | tsfilter | 示例用途：Baxter-King近似带通周期 |
| [`sink()`](https://rdrr.io/r/base/sink.html) | base |  | 把控制台输出写入文件 |
| [`solve()`](https://rdrr.io/r/base/solve.html) | base | estat | 示例用途：计算量表题项的复相关平方 |
| [`sort()`](https://rdrr.io/r/base/sort.html) | base |  | 对向量排序 |
| [`source()`](https://rdrr.io/r/base/source.html) | base |  | 运行 R 脚本 |
| [`split()`](https://rdrr.io/r/base/split.html) | base | by | 把数据按组拆分 |
| [`sprintf()`](https://rdrr.io/r/base/sprintf.html) | base |  | 用模板格式化数值和文本 |
| [`sqrt()`](https://rdrr.io/r/base/MathFun.html) | base |  | 平方根 |
| [`stop()`](https://rdrr.io/r/base/stop.html) | base | exit 198 | 报错并停止 |
| [`stopifnot()`](https://rdrr.io/r/base/stopifnot.html) | base |  | 条件不为 TRUE 时报错 |
| [`strsplit()`](https://rdrr.io/r/base/strsplit.html) | base | split | 拆分字符串 |
| [`sub()`](https://rdrr.io/r/base/grep.html) | base | regexr() | 替换第一个匹配 |
| [`subset()`](https://rdrr.io/r/base/subset.html) | base | keep if | 满足条件的行（base R） |
| [`substr()`](https://rdrr.io/r/base/substr.html) | base | substr() | 按位置截取字符串 |
| [`sum()`](https://rdrr.io/r/base/sum.html) | base |  | 求和 |
| [`summary()`](https://rdrr.io/r/base/summary.html) | base |  | 对象（如模型）的概要 |
| [`sys.source()`](https://rdrr.io/r/base/sys.source.html) | base | include | 示例用途：在当前求值环境执行辅助代码 |
| [`t()`](https://rdrr.io/r/base/t.html) | base |  | 矩阵转置 |
| [`table()`](https://rdrr.io/r/base/table.html) | base |  | 统计各取值的个数 |
| [`tapply()`](https://rdrr.io/r/base/tapply.html) | base | bysort g: egen | 分组应用函数 |
| [`tempdir()`](https://rdrr.io/r/base/tempfile.html) | base | sysdir | 示例用途：查看 R 安装与临时文件夹 |
| [`tempfile()`](https://rdrr.io/r/base/tempfile.html) | base |  | 临时文件名 |
| [`tolower()`](https://rdrr.io/r/base/chartr.html) | base | strlower() | 转为小写 |
| [`toupper()`](https://rdrr.io/r/base/chartr.html) | base | strupper() | 转为大写 |
| [`traceback()`](https://rdrr.io/r/base/traceback.html) | base |  | 显示上一个错误发生的位置 |
| [`transform()`](https://rdrr.io/r/base/transform.html) | base | expandcl | 示例用途：复制完整组并赋予新的组编号 |
| [`trimws()`](https://rdrr.io/r/base/trimws.html) | base | strtrim() | 去掉首尾空格 |
| [`trunc()`](https://rdrr.io/r/base/Round.html) | base | int() | 去掉小数部分 |
| [`try()`](https://rdrr.io/r/base/try.html) | base | capture | 出错后继续运行 |
| [`tryCatch()`](https://rdrr.io/r/base/conditions.html) | base | capture | 处理错误和警告 |
| [`typeof()`](https://rdrr.io/r/base/typeof.html) | base | describe | 存储类型 |
| [`unclass()`](https://rdrr.io/r/base/class.html) | base | rotate | 示例用途：使用斜交oblimin载荷旋转准则 |
| [`unique()`](https://rdrr.io/r/base/unique.html) | base |  | 不重复的取值 |
| [`unname()`](https://rdrr.io/r/base/unname.html) | base | cf | 示例用途：验证两个数据表指定列的值一致 |
| [`unsplit()`](https://rdrr.io/r/base/split.html) | base | permute | 示例用途：在固定分层内部置换结果变量 |
| [`vapply()`](https://rdrr.io/r/base/lapply.html) | base | gdistinct | 示例用途：分别统计多列不同值数 |
| [`vector()`](https://rdrr.io/r/base/vector.html) | base | irf | 示例用途：简约式VAR(1)脉冲响应矩阵 |
| [`warning()`](https://rdrr.io/r/base/warning.html) | base | display as error | 发出警告 |
| [`which()`](https://rdrr.io/r/base/which.html) | base | list if | 条件为 TRUE 的位置 |
| [`with()`](https://rdrr.io/r/base/with.html) | base |  | 在数据框的列中运行代码 |
| [`writeBin()`](https://rdrr.io/r/base/readBin.html) | base | changeeol | 示例用途：将文本文件换行统一为 Unix 格式 |
| [`writeLines()`](https://rdrr.io/r/base/writeLines.html) | base | checksum | 示例用途：将文件摘要保存为附属文本文件 |
| [`xor()`](https://rdrr.io/r/base/Logic.html) | base | egen | 示例用途：标记两列是否不同 |
| `betareg()` | betareg | betareg | 示例用途：使用logit均值连接拟合贝塔回归 |
| `binsreg()` | binsreg |  | 分箱散点图及估计 |
| `boot()` | boot | centile | 示例用途：估计中位数并自助计算置信区间 |
| `boot.ci()` | boot | centile | 示例用途：估计中位数并自助计算置信区间 |
| `augment()` | broom | predict | 把拟合值和残差加到数据中 |
| `glance()` | broom |  | 模型统计量的一行概要 |
| `tidy()` | broom |  | 以数据框形式给出系数表 |
| `Anova()` | car | anova | II 型和 III 型方差分析表 |
| `avPlots()` | car |  | 偏回归图 |
| `deltaMethod()` | car | nlcom | 示例用途：使用Delta方法估计斜率比 |
| `leveneTest()` | car | robvar | 示例用途：使用以中位数为中心的Levene方法检验组间方差相等 |
| `linearHypothesis()` | car | test | 检验系数的线性约束 |
| `vif()` | car |  | 方差膨胀因子 |
| `knn()` | class | discrim | 示例用途：使用五个最近邻进行分类 |
| `bal.tab()` | cobalt | pstest | 示例用途：匹配前后标准化协变量平衡 |
| `HPDinterval()` | coda | bayesstats | 示例用途：90%最高后验密度区间 |
| `effectiveSize()` | coda | bayesstats | 示例用途：MCMC有效样本量 |
| `fread()` | data.table | import delimited | 快速读取大型文本文件 |
| `fwrite()` | data.table | export delimited | 快速写出大型文本文件 |
| `winsorize()` | datawizard |  | 对极端值缩尾 |
| `att_gt()` | did |  | 交错双重差分（Callaway-Sant'Anna） |
| [`across()`](https://dplyr.tidyverse.org/reference/across.html) | dplyr |  | 对多列进行相同的计算 |
| [`add_count()`](https://dplyr.tidyverse.org/reference/count.html) | dplyr | bysort g: generate n = \_N | 添加分组计数列 |
| [`all_of()`](https://tidyselect.r-lib.org/reference/all_of.html) | dplyr | keep \`vars' | 选择字符向量中列出的列 |
| [`anti_join()`](https://dplyr.tidyverse.org/reference/filter-joins.html) | dplyr |  | 保留第一个数据中在第二个数据里没有匹配的行 |
| [`any_of()`](https://tidyselect.r-lib.org/reference/all_of.html) | dplyr | capture keep | 选择列出且存在的列 |
| [`arrange()`](https://dplyr.tidyverse.org/reference/arrange.html) | dplyr |  | 对行排序 |
| [`between()`](https://dplyr.tidyverse.org/reference/between.html) | dplyr |  | 取值是否在某个范围内 |
| [`bind_cols()`](https://dplyr.tidyverse.org/reference/bind_cols.html) | dplyr |  | 把数据左右拼接 |
| [`bind_rows()`](https://dplyr.tidyverse.org/reference/bind_rows.html) | dplyr |  | 把数据上下拼接 |
| [`c_across()`](https://dplyr.tidyverse.org/reference/c_across.html) | dplyr | egen rowtotal() | 在 rowwise() 中组合多列 |
| [`case_match()`](https://dplyr.tidyverse.org/reference/case_match.html) | dplyr | recode | 按取值匹配重新编码 |
| [`case_when()`](https://dplyr.tidyverse.org/reference/case-and-replace-when.html) | dplyr |  | 一次写多个条件分支 |
| [`coalesce()`](https://dplyr.tidyverse.org/reference/coalesce.html) | dplyr |  | 多个向量中第一个非缺失值 |
| [`consecutive_id()`](https://dplyr.tidyverse.org/reference/consecutive_id.html) | dplyr | tsspell | 对连续相同的取值编号 |
| [`contains()`](https://tidyselect.r-lib.org/reference/starts_with.html) | dplyr |  | 选择名称包含某段文本的列 |
| [`count()`](https://dplyr.tidyverse.org/reference/count.html) | dplyr |  | 统计每组的行数 |
| [`cross_join()`](https://dplyr.tidyverse.org/reference/cross_join.html) | dplyr |  | 两个数据所有行的组合 |
| [`cumall()`](https://dplyr.tidyverse.org/reference/cumall.html) | dplyr | sum() | 累计的 all()：直到第一个 FALSE 前为 TRUE |
| [`cume_dist()`](https://dplyr.tidyverse.org/reference/percent_rank.html) | dplyr | cumul | 累积分布 |
| [`cur_group()`](https://dplyr.tidyverse.org/reference/context.html) | dplyr | by | 当前组的分组键 |
| [`cur_group_id()`](https://dplyr.tidyverse.org/reference/context.html) | dplyr |  | 当前组的编号 |
| [`dense_rank()`](https://dplyr.tidyverse.org/reference/row_number.html) | dplyr | egen group() | 无间隔的秩 |
| [`desc()`](https://dplyr.tidyverse.org/reference/desc.html) | dplyr |  | 在 arrange() 中降序排列 |
| [`distinct()`](https://dplyr.tidyverse.org/reference/distinct.html) | dplyr |  | 保留不重复的行 |
| [`ends_with()`](https://tidyselect.r-lib.org/reference/starts_with.html) | dplyr |  | 选择名称以某段文本结尾的列 |
| [`everything()`](https://tidyselect.r-lib.org/reference/everything.html) | dplyr | \_all | 选择所有列 |
| [`filter()`](https://dplyr.tidyverse.org/reference/filter.html) | dplyr |  | 保留满足条件的行 |
| [`first()`](https://dplyr.tidyverse.org/reference/nth.html) | dplyr | x\[1\] | 第一个值 |
| [`full_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html) | dplyr |  | 合并并保留两个数据的所有行 |
| [`glimpse()`](https://pillar.r-lib.org/reference/glimpse.html) | dplyr | describe | 紧凑地查看所有列 |
| [`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html) | dplyr |  | 分组，使后续操作在组内进行 |
| [`group_split()`](https://dplyr.tidyverse.org/reference/group_split.html) | dplyr | by | 按组拆分为多个数据 |
| [`group_vars()`](https://dplyr.tidyverse.org/reference/group_data.html) | dplyr | by | 分组变量的名称 |
| [`if_all()`](https://dplyr.tidyverse.org/reference/across.html) | dplyr | egen rowmin() | 多列是否都满足条件 |
| [`if_any()`](https://dplyr.tidyverse.org/reference/across.html) | dplyr | egen anymatch() | 多列中是否有任一列满足条件 |
| [`if_else()`](https://dplyr.tidyverse.org/reference/if_else.html) | dplyr |  | 条件成立取一个值，否则取另一个值 |
| [`inner_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html) | dplyr |  | 合并并只保留匹配成功的行 |
| [`intersect()`](https://generics.r-lib.org/reference/setops.html) | dplyr | merge, keep(match) | 两个数据中都有的行 |
| [`join_by()`](https://dplyr.tidyverse.org/reference/join_by.html) | dplyr | joinby | 合并键，包括不等式和区间合并 |
| [`lag()`](https://dplyr.tidyverse.org/reference/lead-lag.html) | dplyr |  | 上一行的值 |
| [`last()`](https://dplyr.tidyverse.org/reference/nth.html) | dplyr | x\[\_N\] | 最后一个值 |
| [`last_col()`](https://tidyselect.r-lib.org/reference/everything.html) | dplyr | order | 最后一列 |
| [`lead()`](https://dplyr.tidyverse.org/reference/lead-lag.html) | dplyr |  | 下一行的值 |
| [`left_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html) | dplyr |  | 合并并保留第一个数据的所有行 |
| [`matches()`](https://tidyselect.r-lib.org/reference/starts_with.html) | dplyr |  | 选择名称匹配正则表达式的列 |
| [`min_rank()`](https://dplyr.tidyverse.org/reference/row_number.html) | dplyr | egen rank(), track | 秩（相同取值取最小秩） |
| [`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html) | dplyr |  | 生成或修改列 |
| [`n()`](https://dplyr.tidyverse.org/reference/context.html) | dplyr |  | 当前组的行数 |
| [`n_distinct()`](https://dplyr.tidyverse.org/reference/n_distinct.html) | dplyr | distinct | 不同取值的个数 |
| [`na_if()`](https://dplyr.tidyverse.org/reference/na_if.html) | dplyr |  | 把某个取值改为缺失值 |
| [`near()`](https://dplyr.tidyverse.org/reference/near.html) | dplyr | reldif() | 带容差地比较数值 |
| [`nth()`](https://dplyr.tidyverse.org/reference/nth.html) | dplyr | x\[5\] | 指定位置的值 |
| [`ntile()`](https://dplyr.tidyverse.org/reference/ntile.html) | dplyr | xtile | 分成 n 个大小相近的组 |
| [`num_range()`](https://tidyselect.r-lib.org/reference/starts_with.html) | dplyr | keep x1-x5 | 按编号选择 x1、x2 等列 |
| [`percent_rank()`](https://dplyr.tidyverse.org/reference/percent_rank.html) | dplyr | egen rank() | 缩放到 0 到 1 的秩 |
| [`pick()`](https://dplyr.tidyverse.org/reference/pick.html) | dplyr | varlist | 在 mutate() 或 summarise() 中选取列 |
| [`pull()`](https://dplyr.tidyverse.org/reference/pull.html) | dplyr |  | 把一列提取为向量 |
| [`reframe()`](https://dplyr.tidyverse.org/reference/reframe.html) | dplyr | collapse | 每组汇总为任意行数 |
| [`relocate()`](https://dplyr.tidyverse.org/reference/relocate.html) | dplyr |  | 移动列的位置 |
| [`rename()`](https://dplyr.tidyverse.org/reference/rename.html) | dplyr |  | 重命名列（新名 = 旧名） |
| [`rename_with()`](https://dplyr.tidyverse.org/reference/rename.html) | dplyr |  | 用函数（如 toupper）批量重命名列 |
| [`right_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html) | dplyr |  | 合并并保留第二个数据的所有行 |
| [`row_number()`](https://dplyr.tidyverse.org/reference/row_number.html) | dplyr |  | 行号 |
| [`rows_update()`](https://dplyr.tidyverse.org/reference/rows.html) | dplyr | merge, update replace | 用另一个数据更新行 |
| [`rowwise()`](https://dplyr.tidyverse.org/reference/rowwise.html) | dplyr | egen rowmean() | 逐行计算 |
| [`select()`](https://dplyr.tidyverse.org/reference/select.html) | dplyr |  | 保留或删除列 |
| [`semi_join()`](https://dplyr.tidyverse.org/reference/filter-joins.html) | dplyr |  | 保留第一个数据中在第二个数据里有匹配的行 |
| [`setdiff()`](https://generics.r-lib.org/reference/setops.html) | dplyr | merge, keep(master) | 只在第一个数据中的行 |
| [`slice()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr |  | 按位置保留行 |
| [`slice_head()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr | bysort g: keep if \_n \<= 3 | 每组的前几行 |
| [`slice_max()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr | gsort -x; keep in 1/5 | 取值最大的若干行 |
| [`slice_min()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr | sort x; keep in 1/5 | 取值最小的若干行 |
| [`slice_sample()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr |  | 随机抽取若干行 |
| [`slice_tail()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr | bysort g: keep if \_n \> \_N - 3 | 每组的最后几行 |
| [`starts_with()`](https://tidyselect.r-lib.org/reference/starts_with.html) | dplyr |  | 选择名称以某段文本开头的列 |
| [`summarise()`](https://dplyr.tidyverse.org/reference/summarise.html) | dplyr |  | 把每组汇总为一行统计量 |
| [`summarize()`](https://dplyr.tidyverse.org/reference/summarise.html) | dplyr | collapse | 同 summarise() |
| [`tally()`](https://dplyr.tidyverse.org/reference/count.html) | dplyr | count | 统计行数 |
| [`transmute()`](https://dplyr.tidyverse.org/reference/transmute.html) | dplyr | keep | 生成新列并只保留它们 |
| [`ungroup()`](https://dplyr.tidyverse.org/reference/group_by.html) | dplyr |  | 取消分组 |
| [`union()`](https://generics.r-lib.org/reference/setops.html) | dplyr | append | 两个数据中的所有行（去重） |
| [`where()`](https://tidyselect.r-lib.org/reference/where.html) | dplyr | ds, has(type numeric) | 按类型选择列，如 where(is.numeric) |
| `cohens_d()` | effectsize | esize | 示例用途：估计两个独立组的Cohen标准化均值差 |
| `iv_robust()` | estimatr | ivregress | 示例用途：两阶段最小二乘协方差：HC1 |
| `coefplot()` | fixest | coefplot | fixest 模型的系数图 |
| `etable()` | fixest | esttab | fixest 模型的回归表 |
| `feglm()` | fixest | xtlogit | 带固定效应的广义线性模型（如 logit） |
| `fenegbin()` | fixest | xtnbreg | 带固定效应的负二项模型 |
| `feols()` | fixest |  | 带固定效应、聚类和工具变量的线性回归 |
| `fepois()` | fixest |  | 带固定效应的泊松回归 |
| `fitstat()` | fixest | estat firststage | 拟合统计量（含第一阶段 F） |
| `sunab()` | fixest | eventstudyinteract | 示例用途：Sun-Abraham队列交互事件研究估计 |
| `flextable()` | flextable |  | 用于 Word 或 PowerPoint 的格式化表格 |
| `save_as_docx()` | flextable |  | 把表格保存为 Word 文件 |
| `fct_collapse()` | forcats | recode | 把多个水平合并为组 |
| `fct_count()` | forcats | tabulate | 统计各水平的个数 |
| `fct_drop()` | forcats | label define | 删除未使用的水平 |
| `fct_infreq()` | forcats | tabulate x, sort | 按频数排序水平 |
| `fct_lump_n()` | forcats | recode | 把少见的水平合并为 Other |
| `fct_na_value_to_level()` | forcats | tabulate x, missing | 把缺失值变为一个水平 |
| `fct_recode()` | forcats | label define, modify | 重命名因子水平 |
| `fct_relevel()` | forcats | ib3.x | 把因子水平移到前面 |
| `fct_reorder()` | forcats | graph bar, sort | 按另一个变量排序水平 |
| `fct_rev()` | forcats | label define | 反转水平顺序 |
| `Arima()` | forecast | forecast | 示例用途：ARIMA一步拟合值 |
| `forecast()` | forecast | forecast | 示例用途：八期ARIMA预测 |
| `fracdiff()` | fracdiff | arfima | 示例用途：分数阶差分ARMA估计 |
| `boottest()` | fwildclusterboot | boottest | 示例用途：施加原假设的野生聚类自助法：rademacher权重 |
| `geeglm()` | geepack | xtgee | 示例用途：gaussian GEE：independence工作相关结构 |
| `aes()` | ggplot2 |  | 把变量映射到 x、y、颜色等图形属性 |
| `after_stat()` | ggplot2 | histogram | 示例用途：绘制密度直方图 |
| `annotate()` | ggplot2 | text() | 添加单个注释（如文本） |
| `coord_cartesian()` | ggplot2 | xscale(range()) | 放大视图而不删除数据 |
| `coord_flip()` | ggplot2 |  | 交换 x 轴和 y 轴 |
| `coord_polar()` | ggplot2 |  | 极坐标，用于饼图 |
| `facet_grid()` | ggplot2 | by() | 按两个变量分面 |
| `facet_wrap()` | ggplot2 |  | 按组分面 |
| `geom_abline()` | ggplot2 | function | 给定斜率和截距的直线 |
| `geom_area()` | ggplot2 |  | 面积图 |
| `geom_bar()` | ggplot2 |  | 频数柱状图 |
| `geom_boxplot()` | ggplot2 |  | 箱线图 |
| `geom_col()` | ggplot2 | graph bar (asis) | 给定高度的柱状图 |
| `geom_contour()` | ggplot2 | twoway | 示例用途：在规则网格上绘制等高线 |
| `geom_density()` | ggplot2 |  | 密度曲线 |
| `geom_errorbar()` | ggplot2 |  | 误差线或带端帽的区间 |
| `geom_histogram()` | ggplot2 |  | 直方图 |
| `geom_hline()` | ggplot2 | yline() | 水平参考线 |
| `geom_jitter()` | ggplot2 | scatter, jitter() | 抖动的散点 |
| `geom_label()` | ggplot2 | mlabel() | 带框的文本标签 |
| `geom_line()` | ggplot2 |  | 连接观测值的折线 |
| `geom_linerange()` | ggplot2 | twoway | 示例用途：使用垂直线表示区间 |
| `geom_point()` | ggplot2 |  | 点（散点图） |
| `geom_pointrange()` | ggplot2 | rcap | 带区间的点 |
| `geom_qq()` | ggplot2 |  | 分位数-分位数图的点 |
| `geom_qq_line()` | ggplot2 |  | 分位数-分位数图的参考线 |
| `geom_rect()` | ggplot2 | twoway | 示例用途：绘制上下限之间的区间条 |
| `geom_ribbon()` | ggplot2 |  | 两个值之间的阴影带 |
| `geom_segment()` | ggplot2 | twoway | 示例用途：绘制从零起始的垂直针状线 |
| `geom_sf()` | ggplot2 | spmap | 基于空间数据的地图 |
| `geom_smooth()` | ggplot2 |  | 拟合直线或平滑曲线 |
| `geom_step()` | ggplot2 | line, connect(stairstep) | 阶梯图 |
| `geom_text()` | ggplot2 |  | 图中的文本标签 |
| `geom_tile()` | ggplot2 | heatplot | 热图方块 |
| `geom_violin()` | ggplot2 |  | 小提琴图 |
| `geom_vline()` | ggplot2 |  | 竖直参考线 |
| `ggplot()` | ggplot2 |  | 开始绘图 |
| `ggsave()` | ggplot2 |  | 把图形保存为文件 |
| `labs()` | ggplot2 | title() | 标题和坐标轴标签 |
| `position_dodge()` | ggplot2 | over() | 把柱子或点并排放置 |
| `position_jitter()` | ggplot2 | dotplot | 示例用途：按类别显示各个观测 |
| `scale_colour_manual()` | ggplot2 | mcolor() | 手动指定颜色 |
| `scale_fill_brewer()` | ggplot2 | set scheme | ColorBrewer 填充颜色 |
| `scale_x_continuous()` | ggplot2 | xlabel() | 坐标轴刻度和标签 |
| `scale_x_log10()` | ggplot2 | xscale(log) | 对数刻度的 x 轴 |
| `scale_y_continuous()` | ggplot2 | scatter | 示例用途：设置纵轴刻度 |
| `scale_y_log10()` | ggplot2 | scatter | 示例用途：使用对数纵轴 |
| `stat_ecdf()` | ggplot2 | cumul | 经验累积分布图 |
| `stat_summary()` | ggplot2 |  | 在每个 x 处绘制 y 的汇总值（如均值） |
| `stat_summary_2d()` | ggplot2 | heatplot | 在二维分箱内汇总变量 |
| `theme()` | ggplot2 | graphregion() | 微调图形样式 |
| `theme_bw()` | ggplot2 |  | 黑白图形主题 |
| `theme_classic()` | ggplot2 | set scheme | 经典图形主题 |
| `theme_minimal()` | ggplot2 | set scheme | 简洁图形主题 |
| `theme_set()` | ggplot2 |  | 设定所有图形的默认主题 |
| `xlim()` | ggplot2 | xscale(range()) | x 轴范围 |
| `glmmTMB()` | glmmTMB | menbreg | 示例用途：二次均值方差负二项混合模型 |
| `nbinom2()` | glmmTMB | menbreg | 示例用途：二次均值方差负二项混合模型 |
| `cv.glmnet()` | glmnet | lasso | 示例用途：拟合交叉验证的lasso线性预测模型 |
| [`pairs()`](https://rdrr.io/r/graphics/pairs.html) | graphics |  | 散点图矩阵 |
| [`plot()`](https://rdrr.io/r/graphics/plot.default.html) | graphics | quantile | 示例用途：绘制有序观测与累计比例的关系 |
| [`stem()`](https://rdrr.io/r/graphics/stem.html) | graphics |  | 茎叶图 |
| `arrow()` | grid | twoway | 示例用途：在成对坐标间绘制箭头 |
| `tbl_cross()` | gtsummary | tabulate x1 x2 | 交叉表 |
| `tbl_regression()` | gtsummary | esttab | 回归结果表 |
| `tbl_summary()` | gtsummary |  | 描述统计表（“表 1”） |
| `as_factor()` | haven | decode | 把带标签的取值转为因子 |
| `is_tagged_na()` | haven | mvencode | 示例用途：只编码一种带标记缺失 |
| `labelled()` | haven |  | 给向量加上数值标签 |
| `print_labels()` | haven | label list | 显示数值标签 |
| `read_dta()` | haven |  | 读取 Stata .dta 文件 |
| `read_sas()` | haven |  | 读取 SAS 文件 |
| `read_sav()` | haven |  | 读取 SPSS .sav 文件 |
| `read_xpt()` | haven | import | 示例用途：导入 SAS XPORT 第五版文件 |
| `tagged_na()` | haven | replace x = .a | Stata 式扩展缺失值（如 .a） |
| `write_dta()` | haven |  | 写出 Stata .dta 文件 |
| `write_sav()` | haven | savespss | 写出 SPSS 文件 |
| `write_xpt()` | haven | export | 示例用途：导出 SAS XPORT 第五版数据 |
| `zap_labels()` | haven |  | 去掉数值标签 |
| `zap_missing()` | haven | mvdecode | 把特殊缺失值改为 NA |
| `adorn_totals()` | janitor | tabulate x1 x2 | 给 tabyl 加合计 |
| `clean_names()` | janitor | rename \*, lower | 清理并小写变量名 |
| `get_dupes()` | janitor | duplicates list | 列出重复行 |
| `remove_empty()` | janitor | missings dropvars | 删除空行和空列 |
| `tabyl()` | janitor | tabulate | 频数表和交叉表 |
| `look_for()` | labelled | lookfor | 按名称或标签查找变量 |
| `set_variable_labels()` | labelled |  | 设定变量标签 |
| `to_factor()` | labelled | decode | 把带标签的取值转为因子 |
| `val_labels()` | labelled | label values | 读取或设定数值标签 |
| `var_label()` | labelled | label variable | 读取或设定变量标签 |
| `cfa()` | lavaan | sem | 示例用途：拟合三因子验证性测量模型 |
| `fitMeasures()` | lavaan | estat | 示例用途：报告验证性因子模型拟合指标 |
| `lavResiduals()` | lavaan | estat | 示例用途：检查结构方程模型残差相关 |
| `modindices()` | lavaan | estat | 示例用途：检查结构方程模型修正指数 |
| `sem()` | lavaan |  | 结构方程模型 |
| `standardizedSolution()` | lavaan | sem | 示例用途：报告标准化结构方程模型参数 |
| `VarCorr()` | lme4 | estat sd | 多层模型的方差成分 |
| `fixef()` | lme4 | quadchk | 示例用途：混合Logit估计对求积点数的敏感性 |
| `glmer()` | lme4 |  | 多层广义线性模型 |
| `glmerControl()` | lme4 | melogit | 示例用途：Logistic随机截距模型：Laplace近似 |
| `lmer()` | lme4 |  | 多层线性模型 |
| `ranef()` | lme4 | predict, reffects | 随机效应的预测值 |
| `bptest()` | lmtest |  | Breusch-Pagan 异方差检验 |
| `coeftest()` | lmtest |  | 使用指定方差矩阵的系数检验 |
| `grangertest()` | lmtest | vargranger | 示例用途：检验x是否Granger预测y |
| `lrtest()` | lmtest |  | 似然比检验 |
| `resettest()` | lmtest |  | 遗漏变量 RESET 检验 |
| `waldtest()` | lmtest | test | 嵌套模型的 Wald 检验 |
| `as_date()` | lubridate | dofc() | 转为日期 |
| `day()` | lubridate |  | 日期中的日 |
| `days()` | lubridate | d + 7 | 以天为单位的时期，用于日期运算 |
| `days_in_month()` | lubridate | daysinmonth | 示例用途：获取各日历月的天数 |
| `dmy()` | lubridate | date(s, "DMY") | 把日-月-年格式文本解析为日期 |
| `floor_date()` | lubridate | mofd() | 把日期向下取整到某个单位（如月） |
| `hour()` | lubridate | hh() | 小时 |
| `interval()` | lubridate |  | 两个日期之间的时间段 |
| `make_date()` | lubridate |  | 由年、月、日生成日期 |
| `make_datetime()` | lubridate | mdyhms() | 由各部分生成日期时间 |
| `mdy()` | lubridate | date(s, "MDY") | 把月-日-年格式文本解析为日期 |
| `minute()` | lubridate | mm() | 分钟 |
| `month()` | lubridate |  | 日期中的月份 |
| `now()` | lubridate | now() | 当前日期和时间 |
| `quarter()` | lubridate | quarter() | 日期所在的季度 |
| `time_length()` | lubridate |  | 以指定单位（如年）计算时间段长度 |
| `today()` | lubridate | today() | 今天的日期 |
| `wday()` | lubridate |  | 星期几 |
| `week()` | lubridate | week() | 一年中的第几周 |
| `yday()` | lubridate | doy() | 一年中的第几天 |
| `year()` | lubridate |  | 日期中的年份 |
| `years()` | lubridate | d + 365 | 以年为单位的时期，用于日期运算 |
| `ymd()` | lubridate |  | 把 2024-01-31 这样的文本解析为日期 |
| `ymd_hms()` | lubridate |  | 把文本解析为日期时间 |
| `avg_comparisons()` | marginaleffects | margins r.x | 平均对比 |
| `avg_predictions()` | marginaleffects |  | 平均预测值，类似 Stata 的 margins |
| `avg_slopes()` | marginaleffects |  | 平均边际效应 |
| `comparisons()` | marginaleffects | margins r.x | 预测值之差（对比） |
| `hypotheses()` | marginaleffects |  | 线性和非线性假设检验 |
| `plot_predictions()` | marginaleffects |  | 绘制预测值，类似 marginsplot |
| `plot_slopes()` | marginaleffects | marginsplot | 绘制边际效应 |
| `predictions()` | marginaleffects | margins | 带标准误的预测值 |
| `slopes()` | marginaleffects | margins, dydx(x) at() | 每个观测的边际效应 |
| `cumul()` | metafor | meta | 示例用途：按年份累积的固定效应元分析 |
| `escalc()` | metafor | meta | 示例用途：声明通用效应量与抽样方差 |
| `leave1out()` | metafor | meta | 示例用途：逐一剔除研究的合并估计 |
| `ranktest()` | metafor | meta | 示例用途：秩相关小样本研究效应检验 |
| `regtest()` | metafor | meta | 示例用途：Egger回归不对称检验 |
| `rma()` | metafor | meta | 示例用途：逆方差元分析方法：FE |
| `trimfill()` | metafor | meta | 示例用途：剪补法敏感性分析 |
| `D1()` | mice | mi | 示例用途：合并多变量Wald比较 |
| `D2()` | mice | mi | 示例用途：合并重复完整数据Wald检验 |
| `complete()` | mice | mi | 示例用途：提取第一个完整数据集 |
| `make.predictorMatrix()` | mice | mi | 示例用途：自定义插补预测矩阵 |
| `mice()` | mice |  | 链式方程多重插补 |
| `pool()` | mice |  | 合并多个插补数据的结果 |
| `pool.scalar()` | mice | mi | 示例用途：插补连续变量均值的Rubin合并 |
| `MIcombine()` | mitools | mi | 示例用途：直接合并系数向量与协方差矩阵 |
| `datasummary()` | modelsummary | tabstat | 自定义描述统计表 |
| `datasummary_skim()` | modelsummary | codebook | 快速概览所有变量 |
| `modelplot()` | modelsummary |  | 系数图 |
| `modelsummary()` | modelsummary |  | 回归结果表和描述统计表 |
| `glht()` | multcomp | contrast | 示例用途：构造各组与参照类别之间的对比 |
| `mcp()` | multcomp | contrast | 示例用途：构造各组与参照类别之间的对比 |
| `dmvnorm()` | mvtnorm | lnmvnormalden | 示例用途：计算多变量正态对数密度 |
| `pmvnorm()` | mvtnorm | binormal | 示例用途：计算相关二元正态概率 |
| `corAR1()` | nlme | xtregar | 示例用途：随机截距加AR(1)残差相关 |
| `gls()` | nlme | hetregress | 示例用途：拟合带乘性异方差的正态均值模型 |
| `lme()` | nlme | xtregar | 示例用途：随机截距加AR(1)残差相关 |
| `nlme()` | nlme | menl | 示例用途：随机系数非线性指数增长 |
| `varExp()` | nlme | hetregress | 示例用途：拟合带乘性异方差的正态均值模型 |
| `varIdent()` | nlme | xtgls | 示例用途：组间异方差面板极大似然GLS |
| `multinom()` | nnet |  | 多项 logit 模型 |
| `oaxaca()` | oaxaca |  | Blinder-Oaxaca 分解 |
| `clmm()` | ordinal | meologit | 示例用途：随机截距累积Logit模型 |
| `coords()` | pROC | roctab | 示例用途：列出不同ROC阈值的敏感度与特异度 |
| `roc()` | pROC | roctab | 示例用途：估计诊断标记的非参数ROC曲线下面积 |
| `roc.test()` | pROC | roccomp | 示例用途：使用DeLong推断比较配对标记的ROC面积 |
| `wrap_plots()` | patchwork |  | 组合多张图 |
| `pdata.frame()` | plm | xtset | 为 plm 声明面板数据 |
| `pgmm()` | plm |  | 动态面板 GMM（Arellano-Bond） |
| `phtest()` | plm | hausman | Hausman 检验 |
| `plm()` | plm |  | 面板模型：固定效应和随机效应 |
| `plmtest()` | plm | xttest0 | 示例用途：个体随机效应Breusch-Pagan检验 |
| `purtest()` | plm | xtunitroot | 示例用途：面板单位根检验：levinlin |
| `vcovBK()` | plm | xtpcse | 示例用途：Beck-Katz面板修正协方差 |
| `vcovHC()` | plm | xtreg | 示例用途：按个体聚类的面板稳健标准误 |
| `vcovSCC()` | plm | xtreg | 示例用途：Driscoll-Kraay协方差 |
| `polychor()` | polycor | tetrachoric | 示例用途：使用最大似然估计四分相关 |
| `zeroinfl()` | pscl | zip | 示例用途：拟合采用logit零膨胀部分的零膨胀泊松模型 |
| `ICC()` | psych | icc | 示例用途：估计单向模型单次测量组内相关 |
| `KMO()` | psych | estat | 示例用途：使用KMO指标评估因子分析适用性 |
| `alpha()` | psych | alpha | Cronbach α 系数 |
| `cohen.kappa()` | psych | kap | 示例用途：估计两名评分者的非加权Cohen kappa |
| `describe()` | psych | summarize | 描述统计（与 Stata 的 describe 不同） |
| `fa()` | psych | factor | 方法更多的因子分析 |
| `mardia()` | psych | mvtest | 示例用途：计算Mardia多变量偏度与峰度检验 |
| `principal()` | psych | factor | 示例用途：拟合主成分因子解 |
| `list_rbind()` | purrr | append | 把数据框列表上下拼接 |
| `map()` | purrr | foreach | 对每个元素应用函数，返回列表 |
| `map2()` | purrr | forvalues | 对成对的元素应用函数 |
| `map_chr()` | purrr | foreach | 对每个元素应用函数，返回文本 |
| `map_dbl()` | purrr | foreach | 对每个元素应用函数，返回数值 |
| `possibly()` | purrr | capture | 出错时返回默认值 |
| `reduce()` | purrr | merge | 依次合并元素（如多次合并） |
| `walk()` | purrr | foreach | 为副作用（如保存文件）应用函数 |
| `ES.h()` | pwr | power | 示例用途：使用Cohen h近似设计单比例检验 |
| `pwr.anova.test()` | pwr | power | 示例用途：设计平衡单因素方差分析每组样本量 |
| `pwr.f2.test()` | pwr | power | 示例用途：计算三个解释变量整体R平方检验功效 |
| `pwr.norm.test()` | pwr | power | 示例用途：在标准差已知时设计单均值z检验样本量 |
| `pwr.p.test()` | pwr | power | 示例用途：使用Cohen h近似设计单比例检验 |
| `pwr.r.test()` | pwr | power | 示例用途：设计检出相关系数的样本量 |
| `pwr.t2n.test()` | pwr | power | 示例用途：计算独立组样本量不等时的功效 |
| `rq()` | quantreg |  | 分位数回归 |
| `rdbwdensity()` | rddensity | rdbwdensity | 示例用途：密度断点检验带宽选择 |
| `rddensity()` | rddensity | rddensity | 示例用途：处理阈值处密度连续性 |
| `rdbwselect()` | rdrobust | rdbwselect | 示例用途：断点带宽选择：mserd |
| `rdrobust()` | rdrobust |  | 断点回归 |
| `parse_number()` | readr | destring, ignore() | 从 \$1,200 这样的文本中提取数字 |
| `read_csv()` | readr |  | 读取 CSV 文件 |
| `read_delim()` | readr | import delimited | 读取任意分隔符的文件 |
| `read_tsv()` | readr | import delimited | 读取制表符分隔的文件 |
| `write_csv()` | readr |  | 写出 CSV 文件 |
| `excel_sheets()` | readxl | import excel, describe | Excel 文件的工作表名 |
| `read_excel()` | readxl |  | 读取 Excel 工作表 |
| `install_github()` | remotes |  | 从 GitHub 安装包 |
| `find_root()` | rprojroot | setroot | 示例用途：依据标记文件定位项目根目录 |
| `has_file()` | rprojroot | setroot | 示例用途：依据标记文件定位项目根目录 |
| `selection()` | sampleSelection |  | Heckman 样本选择模型 |
| `NeweyWest()` | sandwich | newey | 示例用途：Newey-West HAC系数推断 |
| `vcovBS()` | sandwich |  | 自助法方差矩阵 |
| `vcovCL()` | sandwich | vce(cluster id) | 聚类方差矩阵 |
| `vcovHC()` | sandwich | vce(robust) | 异方差稳健方差矩阵 |
| `vcovJK()` | sandwich |  | 刀切法方差矩阵 |
| `st_as_sf()` | sf | spset | 示例用途：声明平面点几何及坐标参考系统 |
| `as_survey_design()` | srvyr |  | 声明抽样设计 |
| `survey_mean()` | srvyr |  | 考虑抽样设计的加权均值 |
| `survey_prop()` | srvyr |  | 考虑抽样设计的加权比例 |
| `survey_quantile()` | srvyr | epctile | 加权分位数 |
| `survey_total()` | srvyr | svy: total | 加权总和 |
| [`AIC()`](https://rdrr.io/r/stats/AIC.html) | stats |  | 赤池信息准则（AIC） |
| [`BIC()`](https://rdrr.io/r/stats/AIC.html) | stats |  | 贝叶斯信息准则（BIC） |
| [`Box.test()`](https://rdrr.io/r/stats/box.test.html) | stats | wntestq | 示例用途：Ljung-Box 序列相关联合检验 |
| [`Gamma()`](https://rdrr.io/r/stats/family.html) | stats | glm | 示例用途：为正值结果拟合伽马对数连接模型 |
| [`HoltWinters()`](https://rdrr.io/r/stats/HoltWinters.html) | stats | tssmooth | 示例用途：简单指数平滑 |
| [`IQR()`](https://rdrr.io/r/stats/IQR.html) | stats | egen iqr() | 四分位距 |
| [`StructTS()`](https://rdrr.io/r/stats/StructTS.html) | stats | sspace | 示例用途：局部水平状态空间模型 |
| [`TukeyHSD()`](https://rdrr.io/r/stats/TukeyHSD.html) | stats | pwcompare, mcompare(tukey) | Tukey 多重比较 |
| [`acf()`](https://rdrr.io/r/stats/acf.html) | stats | corrgram | 自相关函数 |
| [`addmargins()`](https://rdrr.io/r/stats/addmargins.html) | stats | tabulate x1 x2 | 给表格加合计 |
| [`aggregate()`](https://rdrr.io/r/stats/aggregate.html) | stats | collapse | 分组统计（base R） |
| [`anova()`](https://rdrr.io/r/stats/anova.html) | stats | anova | 方差分析表，或嵌套模型的比较 |
| [`aov()`](https://rdrr.io/r/stats/aov.html) | stats |  | 方差分析 |
| [`approx()`](https://rdrr.io/r/stats/approxfun.html) | stats | ipolate | 示例用途：线性插值内部缺失结果值 |
| [`arima()`](https://rdrr.io/r/stats/arima.html) | stats |  | ARIMA 时间序列模型 |
| [`as.dist()`](https://rdrr.io/r/stats/dist.html) | stats | mdsmat | 示例用途：对给定相异性矩阵进行尺度分析 |
| [`ave()`](https://rdrr.io/r/stats/ave.html) | stats | stgen | 示例用途：标记生存观察史中曾经暴露的受试者 |
| [`bartlett.test()`](https://rdrr.io/r/stats/bartlett.test.html) | stats | oneway | Bartlett 方差齐性检验 |
| [`binom.test()`](https://rdrr.io/r/stats/binom.test.html) | stats | bitest | 精确二项检验 |
| [`binomial()`](https://rdrr.io/r/stats/family.html) | stats |  | logit 和 probit 模型的二项分布族 |
| [`cancor()`](https://rdrr.io/r/stats/cancor.html) | stats | canon | 示例用途：估计两组变量间的典型相关 |
| [`ccf()`](https://rdrr.io/r/stats/acf.html) | stats | xcorr | 示例用途：正负滞后的互相关 |
| [`chisq.test()`](https://rdrr.io/r/stats/chisq.test.html) | stats | tabulate x1 x2, chi2 | 卡方检验 |
| [`cmdscale()`](https://rdrr.io/r/stats/cmdscale.html) | stats | mds | 示例用途：拟合经典度量多维尺度分析 |
| [`coef()`](https://rdrr.io/r/stats/coef.html) | stats |  | 模型系数 |
| [`complete.cases()`](https://rdrr.io/r/stats/complete.cases.html) | stats | egen rowmiss() | 无缺失值的行 |
| [`confint()`](https://rdrr.io/r/stats/confint.html) | stats | regress | 系数的置信区间 |
| [`cooks.distance()`](https://rdrr.io/r/stats/influence.measures.html) | stats | predict | 示例用途：计算Cook影响距离 |
| [`cor()`](https://rdrr.io/r/stats/cor.html) | stats |  | 相关矩阵 |
| [`cor.test()`](https://rdrr.io/r/stats/cor.test.html) | stats |  | 带显著性检验的相关系数 |
| [`cov()`](https://rdrr.io/r/stats/cor.html) | stats | correlate, covariance | 协方差 |
| [`cov2cor()`](https://rdrr.io/r/stats/cor.html) | stats | estat | 示例用途：提取系数估计之间的相关系数 |
| [`cutree()`](https://rdrr.io/r/stats/cutree.html) | stats | cluster | 示例用途：把层次聚类树切分为三组 |
| [`dbeta()`](https://rdrr.io/r/stats/Beta.html) | stats | betaden | 示例用途：计算贝塔分布密度 |
| [`dbinom()`](https://rdrr.io/r/stats/Binomial.html) | stats | binomialp | 示例用途：计算二项分布概率质量 |
| [`dcauchy()`](https://rdrr.io/r/stats/Cauchy.html) | stats | cauchyden | 示例用途：计算柯西分布密度 |
| [`dchisq()`](https://rdrr.io/r/stats/Chisquare.html) | stats | chi2den | 示例用途：计算卡方分布密度 |
| [`density()`](https://rdrr.io/r/stats/density.html) | stats | kdensity | 核密度估计 |
| [`dexp()`](https://rdrr.io/r/stats/Exponential.html) | stats | exponentialden | 示例用途：计算指数分布密度 |
| [`df()`](https://rdrr.io/r/stats/Fdist.html) | stats | Fden | 示例用途：计算F分布密度 |
| [`dfbetas()`](https://rdrr.io/r/stats/influence.measures.html) | stats | dfbeta | 示例用途：计算删除观测对指定斜率的标准化影响 |
| [`dffits()`](https://rdrr.io/r/stats/influence.measures.html) | stats | predict | 示例用途：计算DFFITS影响统计量 |
| [`dgamma()`](https://rdrr.io/r/stats/GammaDist.html) | stats | gammaden | 示例用途：计算伽马分布密度 |
| [`dhyper()`](https://rdrr.io/r/stats/Hypergeometric.html) | stats | hypergeometricp | 示例用途：计算超几何分布概率质量 |
| [`dist()`](https://rdrr.io/r/stats/dist.html) | stats | mds | 示例用途：拟合经典度量多维尺度分析 |
| [`dlogis()`](https://rdrr.io/r/stats/Logistic.html) | stats | logisticden | 示例用途：计算逻辑斯蒂分布密度 |
| [`dnbinom()`](https://rdrr.io/r/stats/NegBinomial.html) | stats | nbinomialp | 示例用途：计算负二项分布概率质量 |
| [`dnorm()`](https://rdrr.io/r/stats/Normal.html) | stats | normalden() | 正态分布密度 |
| [`dpois()`](https://rdrr.io/r/stats/Poisson.html) | stats | poissonp | 示例用途：计算泊松分布概率质量 |
| [`dt()`](https://rdrr.io/r/stats/TDist.html) | stats | tden | 示例用途：计算Student t分布密度 |
| [`dweibull()`](https://rdrr.io/r/stats/Weibull.html) | stats | weibullden | 示例用途：计算威布尔分布密度 |
| [`ecdf()`](https://rdrr.io/r/stats/ecdf.html) | stats | cumul | 经验累积分布 |
| [`expand.model.frame()`](https://rdrr.io/r/stats/expand.model.frame.html) | stats | vce(cluster g) | 按拟合模型的观测提取并对齐附加变量 |
| [`factanal()`](https://rdrr.io/r/stats/factanal.html) | stats |  | 因子分析 |
| [`filter()`](https://dplyr.tidyverse.org/reference/filter.html) | stats | tssmooth | 示例用途：五期居中移动平均 |
| [`fisher.test()`](https://rdrr.io/r/stats/fisher.test.html) | stats |  | Fisher 精确检验 |
| [`fitted()`](https://rdrr.io/r/stats/fitted.values.html) | stats |  | 模型的拟合值 |
| [`ftable()`](https://rdrr.io/r/stats/ftable.html) | stats | table | 扁平化的多维表 |
| [`gaussian()`](https://rdrr.io/r/stats/family.html) | stats | glm | 示例用途：拟合高斯恒等连接广义线性模型 |
| [`glm()`](https://rdrr.io/r/stats/glm.html) | stats |  | 广义线性模型，如 logit 或泊松模型 |
| [`hatvalues()`](https://rdrr.io/r/stats/influence.measures.html) | stats | predict | 示例用途：计算杠杆值 |
| [`hclust()`](https://rdrr.io/r/stats/hclust.html) | stats | cluster | 示例用途：对标准化变量进行单连接层次聚类 |
| [`inverse.gaussian()`](https://rdrr.io/r/stats/family.html) | stats | glm | 示例用途：拟合逆高斯对数连接模型 |
| [`kmeans()`](https://rdrr.io/r/stats/kmeans.html) | stats |  | K 均值聚类 |
| [`kruskal.test()`](https://rdrr.io/r/stats/kruskal.test.html) | stats |  | Kruskal-Wallis 检验 |
| [`ks.test()`](https://rdrr.io/r/stats/ks.test.html) | stats |  | Kolmogorov-Smirnov 检验 |
| [`lm()`](https://rdrr.io/r/stats/lm.html) | stats |  | 线性回归 |
| [`logLik()`](https://rdrr.io/r/stats/logLik.html) | stats | e(ll) | 模型的对数似然 |
| [`lowess()`](https://rdrr.io/r/stats/lowess.html) | stats | lowess | Lowess 平滑 |
| [`mad()`](https://rdrr.io/r/stats/mad.html) | stats | egen mad() | 中位数绝对偏差 |
| [`manova()`](https://rdrr.io/r/stats/manova.html) | stats | manova | 示例用途：使用Pillai检验多变量组间差异 |
| [`mantelhaen.test()`](https://rdrr.io/r/stats/mantelhaen.test.html) | stats | mhodds | 示例用途：Mantel-Haenszel共同优势比 |
| [`mcnemar.test()`](https://rdrr.io/r/stats/mcnemar.test.html) | stats | mcc | 配对比例的 McNemar 检验 |
| [`median()`](https://rdrr.io/r/stats/median.html) | stats |  | 中位数 |
| [`model.frame()`](https://rdrr.io/r/stats/model.frame.html) | stats | estat | 示例用途：汇总实际估计样本中的变量 |
| [`model.matrix()`](https://rdrr.io/r/stats/model.matrix.html) | stats | xi | 含虚拟变量的设计矩阵 |
| [`na.omit()`](https://rdrr.io/r/stats/na.fail.html) | stats |  | 删除含缺失值的行 |
| [`nls()`](https://rdrr.io/r/stats/nls.html) | stats | nl | 非线性最小二乘 |
| [`nobs()`](https://rdrr.io/r/stats/nobs.html) | stats | e(N) | 模型使用的观测数 |
| [`offset()`](https://rdrr.io/r/stats/offset.html) | stats | poisson | 示例用途：通过暴露量拟合泊松发生率 |
| [`optim()`](https://rdrr.io/r/stats/optim.html) | stats | ml | 通用最优化 |
| [`p.adjust()`](https://rdrr.io/r/stats/p.adjust.html) | stats | test, mtest | 多重检验的 p 值校正 |
| [`pacf()`](https://rdrr.io/r/stats/acf.html) | stats | pac | 示例用途：偏自相关函数 |
| [`pairwise.t.test()`](https://rdrr.io/r/stats/pairwise.t.test.html) | stats | pwmean | 带校正 p 值的两两 t 检验 |
| [`pbeta()`](https://rdrr.io/r/stats/Beta.html) | stats | ibeta | 示例用途：计算贝塔分布累积概率 |
| [`pbinom()`](https://rdrr.io/r/stats/Binomial.html) | stats | binomial | 示例用途：计算二项分布含边界下尾概率 |
| [`pcauchy()`](https://rdrr.io/r/stats/Cauchy.html) | stats | cauchy | 示例用途：计算柯西分布累积概率 |
| [`pchisq()`](https://rdrr.io/r/stats/Chisquare.html) | stats | chi2tail() | 卡方分布概率 |
| [`pexp()`](https://rdrr.io/r/stats/Exponential.html) | stats | exponential | 示例用途：计算指数分布累积概率 |
| [`pf()`](https://rdrr.io/r/stats/Fdist.html) | stats | F | 示例用途：计算F分布累积概率 |
| [`pgamma()`](https://rdrr.io/r/stats/GammaDist.html) | stats | gammap | 示例用途：计算伽马分布累积概率 |
| [`phyper()`](https://rdrr.io/r/stats/Hypergeometric.html) | stats | hypergeometric | 示例用途：计算超几何分布含边界下尾概率 |
| [`plogis()`](https://rdrr.io/r/stats/Logistic.html) | stats | predictnl | 示例用途：对预测作非线性变换并计算Delta方法标准误 |
| [`pnbinom()`](https://rdrr.io/r/stats/NegBinomial.html) | stats | nbinomial | 示例用途：计算负二项分布含边界下尾概率 |
| [`pnorm()`](https://rdrr.io/r/stats/Normal.html) | stats | normal() | 正态分布累积概率 |
| [`poisson()`](https://rdrr.io/r/stats/family.html) | stats | glm | 示例用途：拟合泊松对数连接广义线性模型 |
| [`poisson.test()`](https://rdrr.io/r/stats/poisson.test.html) | stats | stir | 示例用途：比较两组发生率 |
| [`poly()`](https://rdrr.io/r/stats/poly.html) | stats |  | 模型中的多项式项 |
| [`power.prop.test()`](https://rdrr.io/r/stats/power.prop.test.html) | stats | power | 示例用途：设计两个独立比例检验的样本量 |
| [`power.t.test()`](https://rdrr.io/r/stats/power.t.test.html) | stats | power twomeans | t 检验的功效和样本量 |
| [`ppoints()`](https://rdrr.io/r/stats/ppoints.html) | stats | quantile | 示例用途：绘制有序观测与累计比例的关系 |
| [`ppois()`](https://rdrr.io/r/stats/Poisson.html) | stats | poisson | 示例用途：计算泊松分布含边界下尾概率 |
| [`prcomp()`](https://rdrr.io/r/stats/prcomp.html) | stats |  | 主成分分析 |
| [`predict()`](https://rdrr.io/r/stats/predict.html) | stats |  | 模型的预测值 |
| [`princomp()`](https://rdrr.io/r/stats/princomp.html) | stats | pcamat | 示例用途：直接根据相关矩阵执行主成分分析 |
| [`promax()`](https://rdrr.io/r/stats/varimax.html) | stats | rotate | 示例用途：使用promax旋转因子载荷 |
| [`prop.test()`](https://rdrr.io/r/stats/prop.test.html) | stats |  | 比例检验 |
| [`prop.trend.test()`](https://rdrr.io/r/stats/prop.trend.test.html) | stats | nptrend | 示例用途：检验比例的有序趋势 |
| [`pt()`](https://rdrr.io/r/stats/TDist.html) | stats | ttail() | t 分布概率 |
| [`ptukey()`](https://rdrr.io/r/stats/Tukey.html) | stats | tukeyprob | 示例用途：计算学生化极差累积概率 |
| [`pweibull()`](https://rdrr.io/r/stats/Weibull.html) | stats | weibull | 示例用途：计算威布尔分布累积概率 |
| [`qbeta()`](https://rdrr.io/r/stats/Beta.html) | stats | invibeta | 示例用途：计算贝塔分布第90百分位数 |
| [`qcauchy()`](https://rdrr.io/r/stats/Cauchy.html) | stats | invcauchy | 示例用途：计算柯西分布第90百分位数 |
| [`qchisq()`](https://rdrr.io/r/stats/Chisquare.html) | stats | qchi | 示例用途：比较样本分位数与卡方分位数 |
| [`qexp()`](https://rdrr.io/r/stats/Exponential.html) | stats | invexponential | 示例用途：计算指数分布第90百分位数 |
| [`qf()`](https://rdrr.io/r/stats/Fdist.html) | stats | invF | 示例用途：计算F分布第90百分位数 |
| [`qgamma()`](https://rdrr.io/r/stats/GammaDist.html) | stats | invgammap | 示例用途：计算伽马分布第90百分位数 |
| [`qlogis()`](https://rdrr.io/r/stats/Logistic.html) | stats | invlogistic | 示例用途：计算逻辑斯蒂分布第90百分位数 |
| [`qnorm()`](https://rdrr.io/r/stats/Normal.html) | stats | invnormal() | 正态分布分位数 |
| [`qqplot()`](https://rdrr.io/r/stats/qqnorm.html) | stats | qqplot | 示例用途：使用 Q-Q 图比较两个经验分布 |
| [`qt()`](https://rdrr.io/r/stats/TDist.html) | stats | invt | 示例用途：计算Student t分布第90百分位数 |
| [`qtukey()`](https://rdrr.io/r/stats/Tukey.html) | stats | invtukeyprob | 示例用途：计算Tukey多重比较临界值 |
| [`quantile()`](https://rdrr.io/r/stats/quantile.html) | stats | pctile | 分位数 |
| [`quasibinomial()`](https://rdrr.io/r/stats/family.html) | stats |  | 适用于抽样权重的二项分布族 |
| [`quasipoisson()`](https://rdrr.io/r/stats/family.html) | stats | svy | 示例用途：调查Poisson均值模型 |
| [`qweibull()`](https://rdrr.io/r/stats/Weibull.html) | stats | invweibull | 示例用途：计算威布尔分布第90百分位数 |
| [`rbeta()`](https://rdrr.io/r/stats/Beta.html) | stats | rbeta | 示例用途：模拟贝塔随机变量 |
| [`rbinom()`](https://rdrr.io/r/stats/Binomial.html) | stats | rbinomial() | 二项分布随机数 |
| [`rcauchy()`](https://rdrr.io/r/stats/Cauchy.html) | stats | rcauchy | 示例用途：模拟柯西随机变量 |
| [`rchisq()`](https://rdrr.io/r/stats/Chisquare.html) | stats | rchi2 | 示例用途：模拟卡方随机变量 |
| [`relevel()`](https://rdrr.io/r/stats/relevel.html) | stats |  | 指定因子的参照类别 |
| [`reshape()`](https://rdrr.io/r/stats/reshape.html) | stats | icc | 示例用途：估计单向模型单次测量组内相关 |
| [`residuals()`](https://rdrr.io/r/stats/residuals.html) | stats | predict, residuals | 模型残差 |
| [`rexp()`](https://rdrr.io/r/stats/Exponential.html) | stats | rexponential | 示例用途：模拟指数随机变量 |
| [`rgamma()`](https://rdrr.io/r/stats/GammaDist.html) | stats | rgamma | 示例用途：模拟伽马随机变量 |
| [`rhyper()`](https://rdrr.io/r/stats/Hypergeometric.html) | stats | rhypergeometric | 示例用途：模拟超几何随机变量 |
| [`rlogis()`](https://rdrr.io/r/stats/Logistic.html) | stats | rlogistic | 示例用途：模拟逻辑斯蒂随机变量 |
| [`rnbinom()`](https://rdrr.io/r/stats/NegBinomial.html) | stats | rnbinomial | 示例用途：模拟负二项随机变量 |
| [`rnorm()`](https://rdrr.io/r/stats/Normal.html) | stats |  | 正态分布随机数 |
| [`rpois()`](https://rdrr.io/r/stats/Poisson.html) | stats | rpoisson | 示例用途：模拟泊松随机变量 |
| [`rstandard()`](https://rdrr.io/r/stats/influence.measures.html) | stats | predict | 示例用途：计算内部标准化残差 |
| [`rstudent()`](https://rdrr.io/r/stats/influence.measures.html) | stats | predict | 示例用途：计算外部学生化残差 |
| [`rt()`](https://rdrr.io/r/stats/TDist.html) | stats | rt | 示例用途：模拟t随机变量 |
| [`runif()`](https://rdrr.io/r/stats/Uniform.html) | stats |  | 均匀分布随机数 |
| [`runmed()`](https://rdrr.io/r/stats/runmed.html) | stats | tssmooth | 示例用途：滑动中位数非线性平滑 |
| [`rweibull()`](https://rdrr.io/r/stats/Weibull.html) | stats | rweibull | 示例用途：模拟威布尔随机变量 |
| [`sd()`](https://rdrr.io/r/stats/sd.html) | stats |  | 标准差 |
| [`setNames()`](https://rdrr.io/r/stats/setNames.html) | stats | labmask | 示例用途：将已有文本值设为数值标签 |
| [`shapiro.test()`](https://rdrr.io/r/stats/shapiro.test.html) | stats |  | Shapiro-Wilk 正态性检验 |
| [`sigma()`](https://rdrr.io/r/stats/sigma.html) | stats | estat | 示例用途：随机截距组内相关 |
| [`spectrum()`](https://rdrr.io/r/stats/spectrum.html) | stats | pergram | 示例用途：原始周期图 |
| [`step()`](https://rdrr.io/r/stats/step.html) | stats | stepwise | 逐步回归选择 |
| [`t.test()`](https://rdrr.io/r/stats/t.test.html) | stats |  | t 检验和均值的置信区间 |
| [`ts()`](https://rdrr.io/r/stats/ts.html) | stats | tsset | 时间序列对象 |
| [`uniroot()`](https://rdrr.io/r/stats/uniroot.html) | stats | ciwidth | 示例用途：按目标均值区间宽度设计样本量 |
| [`update()`](https://rdrr.io/r/stats/update.html) | stats | regress | 修改后重新拟合模型 |
| [`var()`](https://rdrr.io/r/stats/cor.html) | stats | summarize, detail | 方差 |
| [`var.test()`](https://rdrr.io/r/stats/var.test.html) | stats | sdtest | 方差相等的 F 检验 |
| [`varimax()`](https://rdrr.io/r/stats/varimax.html) | stats | rotate | 示例用途：使用varimax旋转因子载荷 |
| [`vcov()`](https://rdrr.io/r/stats/vcov.html) | stats |  | 模型的方差协方差矩阵 |
| [`weighted.mean()`](https://rdrr.io/r/stats/weighted.mean.html) | stats | summarize \[aweight = w\] | 加权平均 |
| [`wilcox.test()`](https://rdrr.io/r/stats/wilcox.test.html) | stats |  | Wilcoxon 秩和检验或符号秩检验 |
| [`xtabs()`](https://rdrr.io/r/stats/xtabs.html) | stats | tabulate x1 x2 | 用公式生成交叉表 |
| `stri_reverse()` | stringi | ustrreverse | 示例用途：反转 Unicode 码点顺序 |
| `stri_trans_nfc()` | stringi | ustrnormalize | 示例用途：规范化 Unicode 规范等价文本 |
| `stri_trans_nfkc()` | stringi | ustrnormalize | 示例用途：规范化 Unicode 兼容字符 |
| `fixed()` | stringr |  | 按字面匹配文本，而非正则表达式 |
| `regex()` | stringr |  | 带 ignore_case 等选项的正则表达式 |
| `str_c()` | stringr | generate s = a + b | 连接字符串 |
| `str_count()` | stringr |  | 统计字符串中的匹配次数 |
| `str_detect()` | stringr |  | 字符串是否包含某个模式 |
| `str_dup()` | stringr | "-" \* 10 | 重复字符串 |
| `str_ends()` | stringr | substr() | 字符串是否以某模式结尾 |
| `str_extract()` | stringr |  | 提取匹配的文本 |
| `str_extract_all()` | stringr | ustrregexs() | 提取所有匹配 |
| `str_flatten()` | stringr | levelsof, separate() | 把向量合并成一个字符串 |
| `str_glue()` | stringr | display "\`x'" | 填充文本模板 |
| `str_length()` | stringr |  | 字符个数 |
| `str_locate()` | stringr | strpos() | 匹配的位置 |
| `str_match()` | stringr | regexs() | 提取正则表达式的分组 |
| `str_pad()` | stringr | string(x, "%05.0f") | 把字符串填充到固定宽度 |
| `str_remove()` | stringr | subinstr() | 删除第一个匹配 |
| `str_remove_all()` | stringr | subinstr() | 删除所有匹配 |
| `str_replace()` | stringr |  | 替换第一个匹配 |
| `str_replace_all()` | stringr |  | 替换所有匹配 |
| `str_split()` | stringr | split | 把字符串拆分成多个部分 |
| `str_squish()` | stringr |  | 去掉首尾空格并合并连续空格 |
| `str_starts()` | stringr | substr() | 字符串是否以某模式开头 |
| `str_sub()` | stringr |  | 按位置截取字符串 |
| `str_subset()` | stringr | keep if regexm() | 保留匹配的字符串 |
| `str_to_lower()` | stringr |  | 转为小写 |
| `str_to_sentence()` | stringr | strproper() | 句首字母大写 |
| `str_to_title()` | stringr |  | 首字母大写 |
| `str_to_upper()` | stringr |  | 转为大写 |
| `str_trim()` | stringr |  | 去掉首尾空格 |
| `str_trunc()` | stringr | abbrev() | 把字符串截短到指定宽度 |
| `str_wrap()` | stringr | display | 把文本按宽度换行 |
| `word()` | stringr |  | 从句子中提取词 |
| `as.svrepdesign()` | survey | svyset | 示例用途：分层删除一组Jackknife重复权重 |
| `cv()` | survey | estat | 示例用途：调查均值变异系数 |
| `deff()` | survey | estat | 示例用途：调查均值设计效应 |
| `degf()` | survey | svydescribe | 示例用途：调查设计自由度和抽样单元数 |
| `postStratify()` | survey | svyset | 示例用途：按总体分类总量后分层调查权重 |
| `rake()` | survey | svyset | 示例用途：按已知分类边际校准样本权重 |
| `svyby()` | survey | svy | 示例用途：分域均值 |
| `svychisq()` | survey | svy | 示例用途：设计校正分类关联检验：F |
| `svyciprop()` | survey | svy | 示例用途：调查比例置信区间方法：logit |
| `svydesign()` | survey | svyset | 声明抽样设计（survey 包） |
| `svyglm()` | survey |  | 考虑抽样设计的回归 |
| `svymean()` | survey | svy: mean | 加权均值（survey 包） |
| `svyratio()` | survey | svy | 示例用途：调查总体总量比 |
| `svytable()` | survey | svy: tabulate | 加权频数表 |
| `svytotal()` | survey | svy | 示例用途：调查加权总体总量 |
| `Surv()` | survival |  | 模型中的生存时间结局变量 |
| `basehaz()` | survival | predict | 示例用途：零协变量处基线累积风险 |
| `clogit()` | survival |  | 条件 logit 模型 |
| `concordance()` | survival | estat | 示例用途：Cox回归后删失结局一致性 |
| `cox.zph()` | survival | estat | 示例用途：Cox比例风险诊断 |
| `coxph()` | survival |  | Cox 比例风险模型 |
| `finegray()` | survival | stcrreg | 示例用途：Fine-Gray亚分布风险流程 |
| `frailty()` | survival | stcox | 示例用途：共享Gamma脆弱性Cox模型 |
| `strata()` | survival |  | 生存模型公式中的分层项 |
| `survSplit()` | survival | stsplit | 示例用途：在固定切点拆分风险区间 |
| `survdiff()` | survival |  | Log-rank 检验 |
| `survfit()` | survival |  | Kaplan-Meier 生存曲线 |
| `survreg()` | survival |  | 参数生存模型 |
| [`add_row()`](https://tibble.tidyverse.org/reference/add_row.html) | tibble | set obs | 给数据添加行 |
| [`as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html) | tibble |  | 转为 tibble |
| `rownames_to_column()` | tibble | xpose | 把行名转为一列 |
| [`tibble()`](https://tibble.tidyverse.org/reference/tibble.html) | tibble |  | 创建数据框（tibble） |
| [`tribble()`](https://tibble.tidyverse.org/reference/tribble.html) | tibble | input | 按行手动输入小表格 |
| `complete()` | tidyr |  | 补齐缺失的取值组合 |
| `crossing()` | tidyr | cross | 排序并去重的所有组合 |
| `drop_na()` | tidyr | drop if missing(x) | 删除含缺失值的行 |
| `expand()` | tidyr | fillin | 取值的所有组合（删除其他列） |
| `expand_grid()` | tidyr | cross | 给定取值的所有组合 |
| `fill()` | tidyr |  | 用上一个或下一个值填充缺失值 |
| `full_seq()` | tidyr | tsfill | 完整的取值序列 |
| `nest()` | tidyr | by | 把每组嵌套为列表列中的一行 |
| `pivot_longer()` | tidyr |  | 宽数据转为长数据 |
| `pivot_wider()` | tidyr |  | 长数据转为宽数据 |
| `replace_na()` | tidyr | replace x = 0 if missing(x) | 替换缺失值 |
| `separate_longer_delim()` | tidyr | split | 把文本拆分成多行 |
| `separate_wider_delim()` | tidyr |  | 把一个文本列拆分成多列 |
| `separate_wider_position()` | tidyr | substr() | 按位置把文本拆分成多列 |
| `uncount()` | tidyr |  | 把每行重复指定次数 |
| `unite()` | tidyr | egen concat() | 把多列合并为一列 |
| `unnest()` | tidyr | expand | 把列表列展开为行 |
| [`as_character()`](https://socimh.github.io/tidystata/reference/type_conversion.md) | tidystata | decode | decode() 的别名 |
| [`as_dummy()`](https://socimh.github.io/tidystata/reference/as_dummy.md) | tidystata |  | 为每个类别生成虚拟变量 |
| [`as_numeric()`](https://socimh.github.io/tidystata/reference/type_conversion.md) | tidystata | destring | destring() 的别名 |
| [`assert()`](https://socimh.github.io/tidystata/reference/assert.md) | tidystata |  | 条件不成立时报错，并报告不成立的行数 |
| [`browse()`](https://socimh.github.io/tidystata/reference/browse.md) | tidystata |  | 在表格窗口中查看数据 |
| [`capture()`](https://socimh.github.io/tidystata/reference/capture.md) | tidystata |  | 成功时返回结果，出错时显示失败消息并返回 NULL；quiet 抑制警告和消息 |
| [`codebook()`](https://socimh.github.io/tidystata/reference/codebook.md) | tidystata |  | 描述每个变量：类型、标签、个数和取值 |
| [`corr()`](https://socimh.github.io/tidystata/reference/corr.md) | tidystata |  | 完整个案 Pearson 相关系数 |
| [`cut_quantile()`](https://socimh.github.io/tidystata/reference/cut.md) | tidystata | xtile | xtile() 的别名 |
| [`decode()`](https://socimh.github.io/tidystata/reference/type_conversion.md) | tidystata |  | 转为文本，带标签的数据使用数值标签 |
| [`destring()`](https://socimh.github.io/tidystata/reference/type_conversion.md) | tidystata |  | 转为数值，并去掉数值标签 |
| [`ds()`](https://socimh.github.io/tidystata/reference/names.md) | tidystata |  | 列出变量名 |
| [`duplicates_drop()`](https://socimh.github.io/tidystata/reference/keys.md) | tidystata |  | 删除重复行，保留第一行 |
| [`duplicates_list()`](https://socimh.github.io/tidystata/reference/keys.md) | tidystata |  | 列出重复行 |
| [`duplicates_report()`](https://socimh.github.io/tidystata/reference/keys.md) | tidystata |  | 统计重复行 |
| [`duplicates_tag()`](https://socimh.github.io/tidystata/reference/keys.md) | tidystata |  | 标记重复行 |
| [`findit()`](https://socimh.github.io/tidystata/reference/findit.md) | tidystata |  | 查找 Stata 命令对应的 R 函数 |
| [`fre()`](https://socimh.github.io/tidystata/reference/tab.md) | tidystata |  | 带合计行的频数表 |
| [`fre2()`](https://socimh.github.io/tidystata/reference/tab.md) | tidystata | tabulate | 带行合计和列合计的交叉表 |
| [`is_first()`](https://socimh.github.io/tidystata/reference/is_first.md) | tidystata |  | 标记每组的第一行 |
| [`isid()`](https://socimh.github.io/tidystata/reference/keys.md) | tidystata |  | 检查变量能否唯一识别每一行 |
| [`misstable()`](https://socimh.github.io/tidystata/reference/misstable.md) | tidystata |  | 每个变量的缺失值，或缺失值模式 |
| [`mvdecode()`](https://socimh.github.io/tidystata/reference/na_conversion.md) | tidystata |  | 把指定代码改为缺失值 |
| [`mvencode()`](https://socimh.github.io/tidystata/reference/na_conversion.md) | tidystata |  | 把缺失值替换为指定代码 |
| [`na_if_value()`](https://socimh.github.io/tidystata/reference/na_conversion.md) | tidystata | mvdecode | mvdecode() 的别名 |
| [`pc()`](https://socimh.github.io/tidystata/reference/std.md) | tidystata |  | 占总和的百分比 |
| [`pct()`](https://socimh.github.io/tidystata/reference/std.md) | tidystata | egen pc() | pc() 的别名 |
| [`print_all()`](https://socimh.github.io/tidystata/reference/special-print.md) | tidystata |  | 打印所有行和列 |
| [`pwcorr()`](https://socimh.github.io/tidystata/reference/pwcorr.md) | tidystata |  | 两两相关系数，附样本数和 p 值 |
| [`row_max()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | 逐行求多个变量的最大值 |
| [`row_mean()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | 逐行求多个变量的均值 |
| [`row_median()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | 逐行求多个变量的中位数 |
| [`row_min()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | 逐行求多个变量的最小值 |
| [`row_miss()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | 逐行计算缺失值个数 |
| [`row_non_miss()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | 逐行计算非缺失值个数 |
| [`row_nvals()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | 每行不同取值的个数，忽略缺失值 |
| [`row_sd()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | 逐行求多个变量的标准差 |
| [`row_sum()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | 逐行求多个变量的和 |
| [`row_unique()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata | egen rownvals() | 每行不同取值的个数，缺失值算作一个取值 |
| [`set_seed()`](https://socimh.github.io/tidystata/reference/set_seed.md) | tidystata |  | 设定随机数种子，可单独使用或放在管道末尾 |
| [`stata_diff()`](https://socimh.github.io/tidystata/reference/panel.md) | tidystata |  | 与上一期的差分（考虑时间间隔） |
| [`stata_lag()`](https://socimh.github.io/tidystata/reference/panel.md) | tidystata |  | 前若干期的值（考虑时间间隔） |
| [`stata_lead()`](https://socimh.github.io/tidystata/reference/panel.md) | tidystata |  | 后若干期的值（考虑时间间隔） |
| [`stata_merge()`](https://socimh.github.io/tidystata/reference/stata_merge.md) | tidystata |  | 合并两个数据并报告匹配结果，类似 Stata 的 merge |
| [`std()`](https://socimh.github.io/tidystata/reference/std.md) | tidystata |  | 标准化为均值 0、标准差 1 |
| [`summ()`](https://socimh.github.io/tidystata/reference/summ.md) | tidystata |  | 变量的描述统计 |
| [`tab()`](https://socimh.github.io/tidystata/reference/tab.md) | tidystata |  | 频数表 |
| [`tab1()`](https://socimh.github.io/tidystata/reference/tab.md) | tidystata |  | 每个变量一张频数表 |
| [`tab2()`](https://socimh.github.io/tidystata/reference/tab.md) | tidystata |  | 两个变量的交叉表，或每一对变量的交叉表 |
| [`tab_gen()`](https://socimh.github.io/tidystata/reference/as_dummy.md) | tidystata | tabulate, generate() | as_dummy() 的别名 |
| [`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md) | tidystata |  | 变量的指定统计量，可分组 |
| [`timer()`](https://socimh.github.io/tidystata/reference/timer.md) | tidystata |  | 计算代码运行时间 |
| [`tostring()`](https://socimh.github.io/tidystata/reference/type_conversion.md) | tidystata |  | 转换为文本，保留数值代码而不是数值标签 |
| [`value_if_na()`](https://socimh.github.io/tidystata/reference/na_conversion.md) | tidystata | mvencode | mvencode() 的别名 |
| [`variables()`](https://socimh.github.io/tidystata/reference/variables.md) | tidystata |  | 列出变量及其类型和标签 |
| [`variables_search()`](https://socimh.github.io/tidystata/reference/variables.md) | tidystata |  | 按变量名或标签查找变量 |
| [`varlist()`](https://socimh.github.io/tidystata/reference/varlist.md) | tidystata |  | 用 x\* 等 Stata 通配符选择变量 |
| [`xtile()`](https://socimh.github.io/tidystata/reference/cut.md) | tidystata |  | 按分位数分组，与 Stata 的 xtile 一致 |
| `md5sum()` | tools | checksum | 示例用途：计算文件完整性摘要 |
| `garch()` | tseries | arch | 示例用途：ARCH(1)条件方差模型 |
| `as_tsibble()` | tsibble |  | 声明时间序列或面板数据 |
| `fill_gaps()` | tsibble |  | 补齐缺失的时间点 |
| `yearmonth()` | tsibble |  | 月度时期 |
| `yearquarter()` | tsibble |  | 季度时期 |
| `ca.jo()` | urca | vecrank | 示例用途：Johansen trace秩检验：const确定项 |
| `cajorls()` | urca | vec | 示例用途：秩一向量误差修正模型 |
| `ur.df()` | urca | dfuller | 示例用途：ADF单位根检验：none，0阶增广滞后 |
| `ur.ers()` | urca | dfgls | 示例用途：DF-GLS单位根检验：constant |
| `ur.pp()` | urca | pperron | 示例用途：Phillips-Perron Z-tau检验：constant |
| [`View()`](https://rdrr.io/r/utils/View.html) | utils | browse | 打开数据查看器 |
| [`capture.output()`](https://rdrr.io/r/utils/capture.output.html) | utils | dataex | 示例用途：为小型数据示例生成可复现 R 代码 |
| [`combn()`](https://rdrr.io/r/utils/combn.html) | utils | tab2 | 示例用途：生成各变量对的列联表 |
| [`data()`](https://rdrr.io/r/utils/data.html) | utils |  | 载入内置的示例数据 |
| [`getAnywhere()`](https://rdrr.io/r/utils/getAnywhere.html) | utils |  | 查找函数定义在哪里 |
| [`glob2rx()`](https://rdrr.io/r/utils/glob2rx.html) | utils |  | 把通配符模式转为正则表达式 |
| [`head()`](https://rdrr.io/r/utils/head.html) | utils |  | 前几行 |
| [`help()`](https://rdrr.io/r/utils/help.html) | utils |  | 打开帮助页面 |
| [`help.search()`](https://rdrr.io/r/utils/help.search.html) | utils |  | 搜索所有已安装的帮助文档 |
| [`install.packages()`](https://rdrr.io/r/utils/install.packages.html) | utils |  | 从 CRAN 安装包 |
| [`object.size()`](https://rdrr.io/r/utils/object.size.html) | utils | memory | 示例用途：测量一个 R 数据表占用的内存 |
| [`packageVersion()`](https://rdrr.io/r/utils/packageDescription.html) | utils | ftools | 示例用途：查看 R 数据操作包版本与可用性 |
| [`read.csv()`](https://rdrr.io/r/utils/read.table.html) | utils | import delimited | 读取 CSV 文件（base R） |
| [`read.delim()`](https://rdrr.io/r/utils/read.table.html) | utils | import | 示例用途：导入制表符分隔数据 |
| [`read.fwf()`](https://rdrr.io/r/utils/read.fwf.html) | utils | infix | 示例用途：读取相邻定宽数值字段 |
| [`read.table()`](https://rdrr.io/r/utils/read.table.html) | utils | infile | 示例用途：导入空白分隔的数值字段 |
| [`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html) | utils | about | 示例用途：查看 R 版本与平台信息 |
| [`str()`](https://rdrr.io/r/utils/str.html) | utils |  | 简要显示对象的结构 |
| [`tail()`](https://rdrr.io/r/utils/head.html) | utils |  | 最后几行 |
| [`unzip()`](https://rdrr.io/r/utils/unzip.html) | utils | unzipfile | 示例用途：将 ZIP 包解压到指定临时文件夹 |
| [`update.packages()`](https://rdrr.io/r/utils/update.packages.html) | utils |  | 更新已安装的包 |
| [`write.csv()`](https://rdrr.io/r/utils/write.table.html) | utils | export delimited | 写出 CSV 文件（base R） |
| [`write.table()`](https://rdrr.io/r/utils/write.table.html) | utils | outfile | 示例用途：导出纯数值字段并使用 Stata 缺失文本 |
| `write_xlsx()` | writexl |  | 写出 Excel 文件 |
| `zipr()` | zip | zipfile | 示例用途：创建含文本文件的 ZIP 压缩包 |
| `na.locf()` | zoo | stfill | 示例用途：在生存分析受试者内向前携带已观察协变量 |
| `rollapply()` | zoo | rolling | 示例用途：滚动窗口回归系数 |
