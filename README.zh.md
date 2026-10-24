
<!-- README.zh.md is generated from README.zh.Rmd. Please edit that file -->

# tidystata

<!-- badges: start -->

[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable) [![CRAN status](https://www.r-pkg.org/badges/version/tidystata)](https://CRAN.R-project.org/package=tidystata) [![R-CMD-check](https://github.com/socimh/tidystata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/socimh/tidystata/actions/workflows/R-CMD-check.yaml)

<!-- badges: end -->

[English](https://github.com/socimh/tidystata/blob/master/README.md)

[tidystata](https://socimh.github.io/tidystata/) 把 Stata 风格的数据探索和整理带到 R 中：查看变量、汇总统计、列频数表、生成新变量。变量可以用 tidyselect 方式选择，分组计算用 `.by`。结果都是普通的数据表，可以继续用 R 的常用工具筛选、合并和作图。

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
findit("reg, robust")
#> # Heteroskedasticity-robust standard errors [fixest]
#> Stata: regress y x1 x2, robust
#> R:     fixest::feols(y ~ x1 + x2, data = data, vcov = "hetero")
findit("egen rowmean")
#> # Row mean [tidystata]
#> Stata: egen x_avg = rowmean(x1-x5)
#> R:     mutate(data, x_avg = row_mean(x1:x5))
```

只写一个命令，例如 `findit(reg)`，会列出该命令的所有条目。在中文环境下运行 R 时，条目说明会显示为中文。全部条目按主题列在[从 Stata 到 R](https://socimh.github.io/tidystata/articles/coming-from-stata-zh.html)中。

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

``` r
summ(lifeexp, lexp, gnppc, safewater, .by = region)
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

### tab()：频数表

``` r
tab(dplyr::starwars, sex)
#> # A tibble: 5 x 6
#>   sex                n percent   cum valid valid_cum
#>   <chr>          <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 female            16   18.4   18.4 19.3       19.3
#> 2 hermaphroditic     1    1.15  19.5  1.20      20.5
#> 3 male              60   69.0   88.5 72.3       92.8
#> 4 none               6    6.90  95.4  7.23     100  
#> 5 <NA>               4    4.60 100   NA         NA
```

`tab1()` 对多个变量分别列频数表，变量可以用 `ends_with()`、`matches()` 等 tidyselect 函数或 Stata 风格的 `varlist()` 选择；`tab2()` 生成两个变量的交叉表。

### fre()：带合计和值标签的频数表

``` r
fre(lifeexp, region)
#> # A tibble: 4 x 6
#>   region               n percent   cum valid valid_cum
#>   <chr>            <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 Europe & C. Asia    44    64.7  64.7  64.7      64.7
#> 2 North America       14    20.6  85.3  20.6      85.3
#> 3 South America       10    14.7 100    14.7     100  
#> 4 Total               68   100    NA    NA        NA
```

### row_mean() 等：按行计算

与 Stata 的 `egen rowmean()`、`rowtotal()` 和 `rownonmiss()` 一样，按行计算的函数接受一组连续的列，并跳过缺失值。

``` r
scores <- tibble(
  id = 1:4,
  math = c(80, 92, NA, 75),
  read = c(70, 88, 95, NA),
  art = c(90, NA, 85, 60)
)
scores |>
  mutate(
    mean = row_mean(math:art),
    total = row_sum(math:art),
    answered = row_non_miss(math:art)
  )
#> # A tibble: 4 x 7
#>      id  math  read   art  mean total answered
#>   <int> <dbl> <dbl> <dbl> <dbl> <dbl>    <int>
#> 1     1    80    70    90  80     240        3
#> 2     2    92    88    NA  90     180        2
#> 3     3    NA    95    85  90     180        2
#> 4     4    75    NA    60  67.5   135        2
```

### stata_lag()：面板数据的滞后、超前和差分

`stata_lag()`、`stata_lead()` 和 `stata_diff()` 相当于 `xtset id year` 之后的 `L.`、`F.` 和 `D.`：它们按时间变量取值，所以年份不连续时得到缺失值，而不是上一行的值。

``` r
panel <- tibble(
  id = c(1, 1, 1, 2, 2),
  year = c(2001, 2002, 2004, 2001, 2002),
  x = c(10, 12, 15, 20, 21)
)
panel |>
  mutate(
    lag_x = stata_lag(x, time = year),
    d_x = stata_diff(x, time = year),
    .by = id
  )
#> # A tibble: 5 x 5
#>      id  year     x lag_x   d_x
#>   <dbl> <dbl> <dbl> <dbl> <dbl>
#> 1     1  2001    10    NA    NA
#> 2     1  2002    12    10     2
#> 3     1  2004    15    NA    NA
#> 4     2  2001    20    NA    NA
#> 5     2  2002    21    20     1
```

## 了解更多

tidystata 还提供相关系数（`pwcorr()`）、缺失值报告（`misstable()`）、主键检查与合并（`isid()`、`stata_merge()`）以及分组（`xtile()`）等函数。示例和输出约定见以下指南（英文）。

- [Getting started](https://socimh.github.io/tidystata/articles/getting-started.html)：简短的工作流程。
- [Containers and missing values](https://socimh.github.io/tidystata/articles/containers-and-missing-values.html)：返回类型、分组和标签。
- [Reference](https://socimh.github.io/tidystata/reference/index.html)：全部函数。

## 行为准则

tidystata 项目遵循[贡献者行为准则](https://www.contributor-covenant.org/version/2/0/CODE_OF_CONDUCT.html)。参与本项目即表示你同意遵守其中的条款。
