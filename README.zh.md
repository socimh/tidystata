# tidystata

[![Lifecycle:
stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![CRAN
status](https://www.r-pkg.org/badges/version/tidystata)](https://CRAN.R-project.org/package=tidystata)
[![R-CMD-check](https://github.com/socimh/tidystata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/socimh/tidystata/actions/workflows/R-CMD-check.yaml)

[English](https://github.com/socimh/tidystata/blob/master/README.md)

[tidystata](https://socimh.github.io/tidystata/) 把 Stata
风格的数据探索和整理带到 R
中：查看变量、汇总统计、列频数表、生成新变量。变量可以用 tidyselect
方式选择，分组计算用 `.by`。结果都是普通的数据表，可以继续用 R
的常用工具筛选、合并和作图。

## 安装

``` r

# install.packages("pak")
pak::pak("socimh/tidystata")
```

## 核心函数

``` r

library(tidystata)
library(dplyr)
```

### findit()：查找 Stata 命令对应的 R 代码

``` r

findit(reg, robust)
#> # Heteroskedasticity-robust standard errors [fixest]
#> Stata: regress y x1 x2, robust
#> R:     fixest::feols(y ~ x1 + x2, data = data, vcov = "hetero")
#> # Note: Match fixest covariance small-sample corrections and singleton handling with Stata; the same formula does not guarantee identical standard errors or retained observations.
#> 
#> # 17 broader regress examples. Browse the family: findit(regress)

findit("egen rowmean")
#> # Average available values across columns [tidystata]
#> Stata: egen z = rowmean(x y)
#> R:     mutate(data, z = row_mean(x, y))
#> 
#> # 70 broader egen examples. Browse the family: findit(egen)
```

单独查询命令（如
`findit(egen)`）返回整个命令族，默认显示最多五种操作。具体查询（如
`findit("egen rowmean")`）返回一个明确的推荐；含义不明确时保留最多十个相关候选项。`print(n = Inf)`
展开已返回的结果；查询命令族可浏览更广的操作。同一任务优先推荐
tidystata，其次是 tidyverse，最后是其他包或 base
R。可以用逗号添加变量名或提示，例如 `findit(tab, sex, region)` 或
`findit(tab, gen)`。在中文环境下运行 R
时，条目说明会显示为中文。全部条目按主题列在[从 Stata 到
R](https://socimh.github.io/tidystata/articles/coming-from-stata-zh.html)中。

也可以输入 Stata 文本：`` findit(`tab sex region`, row) `` 和
`findit("tab sex region, row")` 会用指定变量生成相同的行百分比示例。
查询 do-file 中的一条命令时，可选中文本后运行 **Find Stata equivalent**
插件（[`findit_selection()`](https://socimh.github.io/tidystata/reference/findit.md)），或复制文本后运行
[`findit_clip()`](https://socimh.github.io/tidystata/reference/findit.md)。
两者均在控制台显示结果，分别需要可选的 rstudioapi 和 clipr 包。

### codebook()：描述每个变量

``` r

codebook(lifeexp)
#> # A tibble: 6 x 5
#>   variable  label                    type             n unique
#>   <chr>     <chr>                    <chr>        <int>  <int>
#> 1 region    Region                   double+label    68      3
#> 2 country   Country                  character       68     68
#> 3 popgrowth Avg. annual % growth     double          68     32
#> 4 lexp      Life expectancy at birth double          68     20
#> 5 gnppc     GNP per capita           double          67     64
#> 6 safewater Safe water               double          54     32
```

### summ()：汇总统计

`lexp:safewater` 选择从 `lexp` 到 `safewater`
的三个连续变量，包括两端；也可以使用
[`ends_with()`](https://tidyselect.r-lib.org/reference/starts_with.html)、[`matches()`](https://tidyselect.r-lib.org/reference/starts_with.html)
等 tidyselect 函数或 Stata 风格的
[`varlist()`](https://socimh.github.io/tidystata/reference/varlist.md)。

``` r

summ(lifeexp, lexp:safewater, .by = region)
#> # A tibble: 9 x 9
#>   region               name      type      n unique   min    mean       sd   max
#>   <dbl+lbl>            <chr>     <chr> <int>  <int> <dbl>   <dbl>    <dbl> <dbl>
#> 1 1 [Europe & C. Asia] lexp      dbl      44     17    62    72.5     4.95    79
#> 2 1 [Europe & C. Asia] gnppc     dbl      43     42   170 11284.  12920.   46650
#> 3 1 [Europe & C. Asia] safewater dbl      42     25    36    81.6    18.6    100
#> 4 2 [North America]    lexp      dbl      14     13    57    69.7     6.14    79
#> 5 2 [North America]    gnppc     dbl      14     14   410  6294.   9080.   32040
#> 6 2 [North America]    safewater dbl       6      5    40    58      24.0     99
#> 7 3 [South America]    lexp      dbl      10      8    61    70.7     4.06    76
#> 8 3 [South America]    gnppc     dbl      10      9   960  3881    2432.    7960
#> 9 3 [South America]    safewater dbl       6      6    45    65.3    17.0     91
```

### tab()、tab1() 和 tab2()：频数表

用 `lifeexp` 中的地区和一个新类别作比较：预期寿命是否达到 70
岁。`region:lexp_70` 选择这两列。

[`tab()`](https://socimh.github.io/tidystata/reference/tab.md)
统计每种实际出现的组合的频数，并给出百分比。

``` r

lifeexp_tab <- lifeexp |>
  transmute(region, lexp_70 = lexp >= 70)

tab(lifeexp_tab, region:lexp_70)
#> # A tibble: 6 x 7
#>   region               lexp_70     n percent   cum valid valid_cum
#>   <dbl+lbl>            <lgl>   <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 1 [Europe & C. Asia] FALSE      12   17.6   17.6 17.6       17.6
#> 2 1 [Europe & C. Asia] TRUE       32   47.1   64.7 47.1       64.7
#> 3 2 [North America]    FALSE       6    8.82  73.5  8.82      73.5
#> 4 2 [North America]    TRUE        8   11.8   85.3 11.8       85.3
#> 5 3 [South America]    FALSE       3    4.41  89.7  4.41      89.7
#> 6 3 [South America]    TRUE        7   10.3  100   10.3      100
```

[`tab1()`](https://socimh.github.io/tidystata/reference/tab.md)
返回一个命名列表，为每个变量分别生成频数表。

``` r

tab1(lifeexp_tab, region:lexp_70)
#> $region
#> # A tibble: 3 x 6
#>   value                    n percent   cum valid valid_cum
#>   <dbl+lbl>            <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 1 [Europe & C. Asia]    44    64.7  64.7  64.7      64.7
#> 2 2 [North America]       14    20.6  85.3  20.6      85.3
#> 3 3 [South America]       10    14.7 100    14.7     100  
#> 
#> $lexp_70
#> # A tibble: 2 x 6
#>   value     n percent   cum valid valid_cum
#>   <lgl> <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 FALSE    21    30.9  30.9  30.9      30.9
#> 2 TRUE     47    69.1 100    69.1     100
```

[`tab2()`](https://socimh.github.io/tidystata/reference/tab.md)
将联合频数排列成交叉表，地区为行，预期寿命类别为列。

``` r

tab2(lifeexp_tab, region:lexp_70)
#> # A tibble: 3 x 3
#>   `region \\ lexp_70`  `FALSE` `TRUE`
#>   <dbl+lbl>              <int>  <int>
#> 1 1 [Europe & C. Asia]      12     32
#> 2 2 [North America]          6      8
#> 3 3 [South America]          3      7
```

也可以对连续变量制表。当不同取值较多时，用
[`print_interval()`](https://socimh.github.io/tidystata/reference/special-print.md)
查看等间隔选取的行，或用
[`print_headtail()`](https://socimh.github.io/tidystata/reference/special-print.md)
查看开头和结尾。这些函数只缩短显示内容，仍保留完整的频数表。

``` r

tab(lifeexp, lexp) |> print_interval(n = 6)
#> # A tibble: 20 x 6
#>     lexp     n percent    cum valid valid_cum
#>    <dbl> <int>   <dbl>  <dbl> <dbl>     <dbl>
#>  1    57     1    1.47   1.47  1.47      1.47
#>  5    64     3    4.41  11.8   4.41     11.8 
#>  9    68     3    4.41  25     4.41     25   
#> 12    71     6    8.82  47.1   8.82     47.1 
#> 16    75     4    5.88  72.1   5.88     72.1 
#> 20    79     6    8.82 100     8.82    100   
#> # ... 14 rows omitted between displayed positions; use print(x, n = Inf) to
#> # show all rows.
```

## 了解更多

tidystata 还提供
[`stata_recode()`](https://socimh.github.io/tidystata/reference/stata_recode.md)、[`destring()`](https://socimh.github.io/tidystata/reference/type_conversion.md)、[`encode()`](https://socimh.github.io/tidystata/reference/type_conversion.md)、[`decode()`](https://socimh.github.io/tidystata/reference/type_conversion.md)、[`tostring()`](https://socimh.github.io/tidystata/reference/type_conversion.md)、`row_*()`
和 `duplicates_*()`
系列、[`stata_lag()`](https://socimh.github.io/tidystata/reference/panel.md)、[`stata_lead()`](https://socimh.github.io/tidystata/reference/panel.md)、[`stata_diff()`](https://socimh.github.io/tidystata/reference/panel.md)、[`corr()`](https://socimh.github.io/tidystata/reference/corr.md)、[`pwcorr()`](https://socimh.github.io/tidystata/reference/corr.md)、[`misstable()`](https://socimh.github.io/tidystata/reference/misstable.md)、[`isid()`](https://socimh.github.io/tidystata/reference/keys.md)、[`stata_merge()`](https://socimh.github.io/tidystata/reference/stata_merge.md)、[`xtile()`](https://socimh.github.io/tidystata/reference/cut.md)
和
[`preview()`](https://socimh.github.io/tidystata/reference/preview.md)。示例和输出约定见以下指南（英文）。

- [Getting
  started](https://socimh.github.io/tidystata/articles/getting-started.html)：简短的工作流程。
- [Inspect and prepare
  data](https://socimh.github.io/tidystata/articles/inspect-and-prepare.html)：清理变量、检查标识符与合并记录。
- [Tabulate and compare
  categories](https://socimh.github.io/tidystata/articles/tabulation.html)：[`tab()`](https://socimh.github.io/tidystata/reference/tab.md)
  与 [`fre()`](https://socimh.github.io/tidystata/reference/tab.md)
  系列。
- [Summarise
  measurements](https://socimh.github.io/tidystata/articles/summary-statistics.html)：[`summ()`](https://socimh.github.io/tidystata/reference/summ.md)、[`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md)
  与相关分析。
- [Containers and missing
  values](https://socimh.github.io/tidystata/articles/containers-and-missing-values.html)：返回类型、分组和标签。
- [Reference](https://socimh.github.io/tidystata/reference/index.html)：全部函数。

## 行为准则

tidystata
项目遵循[贡献者行为准则](https://www.contributor-covenant.org/version/2/0/CODE_OF_CONDUCT.html)。参与本项目即表示你同意遵守其中的条款。
