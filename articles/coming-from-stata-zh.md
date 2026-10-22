# 从 Stata 到 R

[English
version](https://socimh.github.io/tidystata/articles/coming-from-stata.md)

熟悉 Stata 的用户已经知道自己想做什么，需要的只是知道在 R
中怎么写。本页把 Stata 命令和完成同样任务的 R 代码并列：tidystata 中有
Stata 风格函数的，使用 tidystata；其他情况使用常用的 R 包。

## 在 R 中直接查询

[`findit()`](https://socimh.github.io/tidystata/reference/findit.md) 在
R 中查询同一份列表。单个 Stata
命令可以不加引号，更长的内容需要加引号；支持 Stata
的标准缩写。控制台输出为英文。

``` r

findit(reg)
#> # Stata to R: 6 entries
#> 
#> regress y x1 x2                   # Linear regression [stats]
#>   fit <- lm(y ~ x1 + x2, data = data)
#> regress y x1 x2, robust           # Heteroskedasticity-robust standard errors [fixest]
#>   fixest::feols(y ~ x1 + x2, data = data, vcov = "hetero")
#> regress y x1 x2, vce(cluster id)  # Clustered standard errors [fixest]
#>   fixest::feols(y ~ x1 + x2, data = data, cluster = ~id)
#> regress y i.group c.x1##c.x2      # Factor variables and interactions [stats]
#>   lm(y ~ factor(group) + x1 * x2, data = data)
#> regress y x [pweight = wt]        # Regression with sampling weights [fixest]
#>   fixest::feols(y ~ x, data = data, weights = ~wt, vcov = "hetero")
#> regress y ib3.group               # Choose the base category [stats]
#>   lm(y ~ relevel(factor(group), ref = "3"), data = data)
findit("merge 1:1 id, keep(match)")
#> # Stata to R: 10 entries
#> # "merge" is a Stata command and an R function.
#> 
#> ## Stata command
#> merge 1:1 id using data2, keep(match)                            # Keep matched rows only [dplyr]
#>   inner_join(data1, data2, by = "id")
#> merge 1:1 id using data2, keep(match) keepusing(id) nogenerate   # Keep rows of data1 whose id is in data2 [dplyr]
#>   semi_join(data1, data2, by = "id")
#> merge 1:1 id using data2                                         # Merge with a match report [tidystata]
#>   s_merge(data1, data2, "1:1", by = "id")
#> merge 1:1 id using data2, keep(master match)                     # Keep all rows of the master data [dplyr]
#>   left_join(data1, data2, by = "id")
#> merge 1:1 id using data2, keep(using match)                      # Keep all rows of the using data [dplyr]
#>   right_join(data1, data2, by = "id")
#> merge 1:1 id1 id2 using data2, nogenerate                        # Merge on two keys [dplyr]
#>   full_join(data1, data2, by = c("id1", "id2"))
#> merge 1:1 id using data2, keep(master) keepusing(id) nogenerate  # Keep rows of data1 whose id is not in data2 [dplyr]
#>   anti_join(data1, data2, by = "id")
#> merge m:1 id using data2                                         # Many-to-one merge with a match report [tidystata]
#>   s_merge(data1, data2, "m:1", by = "id")
#> merge 1:m id using data2                                         # One-to-many merge with a match report [tidystata]
#>   s_merge(data1, data2, "1:m", by = "id")
#> merge 1:1 _n using data2                                         # Put two datasets side by side by row position [dplyr]
#>   bind_cols(data1, data2)
#> 
#> ## R function: merge() [base]: Merge two data frames (base R)
#>   Related Stata: merge
```

不带参数的
[`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
返回完整列表；输入 `??stata` 可以再次找到它的帮助文档。

## tidystata 以外的功能

tidystata
覆盖日常的数据探索、制表、描述统计、数据准备和检查。其他任务通常使用以下
R 包：

- **回归和固定效应**（`regress`、`reghdfe`、`xtreg`、`ivregress`）：[`lm()`](https://rdrr.io/r/stats/lm.html)、[`glm()`](https://rdrr.io/r/stats/glm.html)
  或 `fixest::feols()`。
- **回归结果表**（`esttab`、`outreg2`）：`modelsummary::modelsummary()`。
- **边际效应**（`margins`）：marginaleffects。
- **长宽数据转换**（`reshape`）：[`tidyr::pivot_longer()`](https://tidyr.tidyverse.org/reference/pivot_longer.html)
  和 `pivot_wider()`。
- **缩尾**（`winsor2`）：`datawizard::winsorize()`。
- **面板和日历时期**（`tsset`、`xtset`、`L.`、`mofd()`）：tsibble 和
  lubridate。
- **调查数据**（`svyset`、`svy:`）：srvyr 和 survey。
- **作图**（`twoway`、`histogram`）：ggplot2；`binscatter` 可用 binsreg
  或 `statar::stat_binmean()`。

tidystata 和 [statar](https://github.com/matthieugomez/statar)
可以同时加载，只有
[`tab()`](https://socimh.github.io/tidystata/reference/tab.md) 和
[`xtile()`](https://socimh.github.io/tidystata/reference/cut.md)
重名。请最后加载 tidystata，或写成
[`tidystata::tab()`](https://socimh.github.io/tidystata/reference/tab.md)。

一些 RStudio 操作可以代替 Stata 的界面：Ctrl+Enter（Mac 上为
Cmd+Return）运行当前行或选中的代码，Tab 键补全名称，Environment 和 Files
窗口相当于 Stata 的 Variables 窗口和 `dir`。

下表中，`data` 是你的数据，`data1` 和 `data2`
是合并时的主数据和被合并数据，`fit` 是已估计的模型。大部分条目使用
dplyr，请先用 [`library(dplyr)`](https://dplyr.tidyverse.org) 或
[`library(tidyverse)`](https://tidyverse.tidyverse.org) 加载。

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

| Stata | R | 说明 |
|:---|:---|:---|
| `order x1-x4` | `relocate(data, x1:x4)` | 把一些变量移到最前面 |
| `order x1-x4, before(x5)` | `relocate(data, x1:x4, .before = x5)` | 把一些变量移到其他位置 |
| `sort x1 x2` | `arrange(data, x1, x2)` | 根据 x1 和 x2 升序排列数据 |
| `gsort x1 -x2` | `arrange(data, x1, desc(x2))` | 根据 x1 和 x2 升序或降序排列数据 |

## 合并数据

[TABLE]

## 转换长、宽数据

[TABLE]

## 构造数据

[TABLE]

## 字符和日期变量

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

## 本指南中的 R 函数

Stata 用户可能用到的 R
函数，包括上文用到的所有函数，及其所属的包、相关的 Stata
命令和用途。输入 `findit(函数名)`，例如
`findit(left_join)`，可以查看它对应的 Stata 命令。

| 函数 | 包 | 相关 Stata 命令 | 说明 |
|:---|:---|:---|:---|
| [`abs()`](https://rdrr.io/r/base/MathFun.html) | base | abs() | 绝对值 |
| [`acf()`](https://rdrr.io/r/stats/acf.html) | stats | corrgram | 自相关函数 |
| [`across()`](https://dplyr.tidyverse.org/reference/across.html) | dplyr |  | 对多列进行相同的计算 |
| [`add_count()`](https://dplyr.tidyverse.org/reference/count.html) | dplyr | bysort g: generate n = \_N | 添加分组计数列 |
| [`add_row()`](https://tibble.tidyverse.org/reference/add_row.html) | tibble | set obs | 给数据添加行 |
| [`addmargins()`](https://rdrr.io/r/stats/addmargins.html) | stats | tabulate x1 x2 | 给表格加合计 |
| `adorn_totals()` | janitor | tabulate x1 x2 | 给 tabyl 加合计 |
| `aes()` | ggplot2 |  | 把变量映射到 x、y、颜色等图形属性 |
| [`aggregate()`](https://rdrr.io/r/stats/aggregate.html) | stats | collapse | 分组统计（base R） |
| [`AIC()`](https://rdrr.io/r/stats/AIC.html) | stats |  | 赤池信息准则（AIC） |
| [`all()`](https://rdrr.io/r/base/all.html) | base | assert | 是否所有值都为 TRUE |
| [`all_of()`](https://tidyselect.r-lib.org/reference/all_of.html) | dplyr | keep \`vars' | 选择字符向量中列出的列 |
| `alpha()` | psych | alpha | Cronbach α 系数 |
| `annotate()` | ggplot2 | text() | 添加单个注释（如文本） |
| [`anova()`](https://rdrr.io/r/stats/anova.html) | stats | anova | 方差分析表，或嵌套模型的比较 |
| `Anova()` | car | anova | II 型和 III 型方差分析表 |
| [`anti_join()`](https://dplyr.tidyverse.org/reference/filter-joins.html) | dplyr |  | 保留第一个数据中在第二个数据里没有匹配的行 |
| [`any()`](https://rdrr.io/r/base/any.html) | base | count if | 是否有任一值为 TRUE |
| [`any_of()`](https://tidyselect.r-lib.org/reference/all_of.html) | dplyr | capture keep | 选择列出且存在的列 |
| [`aov()`](https://rdrr.io/r/stats/aov.html) | stats |  | 方差分析 |
| [`apply()`](https://rdrr.io/r/base/apply.html) | base | egen rowtotal() | 对行或列应用函数 |
| [`arima()`](https://rdrr.io/r/stats/arima.html) | stats |  | ARIMA 时间序列模型 |
| [`arrange()`](https://dplyr.tidyverse.org/reference/arrange.html) | dplyr |  | 对行排序 |
| [`as.character()`](https://rdrr.io/r/base/character.html) | base |  | 转为文本 |
| [`as.Date()`](https://rdrr.io/r/base/as.Date.html) | base |  | 转为日期 |
| [`as.double()`](https://rdrr.io/r/base/double.html) | base |  | 转为双精度数值 |
| [`as.factor()`](https://rdrr.io/r/base/factor.html) | base | encode | 转为因子 |
| [`as.integer()`](https://rdrr.io/r/base/integer.html) | base |  | 转为整数 |
| [`as.numeric()`](https://rdrr.io/r/base/numeric.html) | base |  | 转为数值 |
| [`as_character()`](https://socimh.github.io/tidystata/reference/type_conversion.md) | tidystata | decode | decode() 的别名 |
| `as_date()` | lubridate | dofc() | 转为日期 |
| [`as_dummy()`](https://socimh.github.io/tidystata/reference/as_dummy.md) | tidystata |  | 为每个类别生成虚拟变量 |
| `as_factor()` | haven | decode | 把带标签的取值转为因子 |
| [`as_numeric()`](https://socimh.github.io/tidystata/reference/type_conversion.md) | tidystata | destring | destring() 的别名 |
| `as_survey_design()` | srvyr |  | 声明抽样设计 |
| [`as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html) | tibble |  | 转为 tibble |
| `as_tsibble()` | tsibble |  | 声明时间序列或面板数据 |
| [`assert()`](https://socimh.github.io/tidystata/reference/assert.md) | tidystata |  | 条件不成立时报错，并报告不成立的行数 |
| `att_gt()` | did |  | 交错双重差分（Callaway-Sant'Anna） |
| [`attr()`](https://rdrr.io/r/base/attr.html) | base |  | 读取或设定对象的属性 |
| `augment()` | broom | predict | 把拟合值和残差加到数据中 |
| `avg_comparisons()` | marginaleffects | margins r.x | 平均对比 |
| `avg_predictions()` | marginaleffects |  | 平均预测值，类似 Stata 的 margins |
| `avg_slopes()` | marginaleffects |  | 平均边际效应 |
| `avPlots()` | car |  | 偏回归图 |
| [`bartlett.test()`](https://rdrr.io/r/stats/bartlett.test.html) | stats | oneway | Bartlett 方差齐性检验 |
| [`between()`](https://dplyr.tidyverse.org/reference/between.html) | dplyr |  | 取值是否在某个范围内 |
| [`BIC()`](https://rdrr.io/r/stats/AIC.html) | stats |  | 贝叶斯信息准则（BIC） |
| [`bind_cols()`](https://dplyr.tidyverse.org/reference/bind_cols.html) | dplyr |  | 把数据左右拼接 |
| [`bind_rows()`](https://dplyr.tidyverse.org/reference/bind_rows.html) | dplyr |  | 把数据上下拼接 |
| [`binom.test()`](https://rdrr.io/r/stats/binom.test.html) | stats | bitest | 精确二项检验 |
| [`binomial()`](https://rdrr.io/r/stats/family.html) | stats |  | logit 和 probit 模型的二项分布族 |
| `binsreg()` | binsreg |  | 分箱散点图及估计 |
| `bptest()` | lmtest |  | Breusch-Pagan 异方差检验 |
| [`browse()`](https://socimh.github.io/tidystata/reference/browse.md) | tidystata |  | 在表格窗口中查看数据 |
| [`c()`](https://rdrr.io/r/base/c.html) | base |  | 把多个值组合成向量 |
| [`c_across()`](https://dplyr.tidyverse.org/reference/c_across.html) | dplyr | egen rowtotal() | 在 rowwise() 中组合多列 |
| [`capture()`](https://socimh.github.io/tidystata/reference/capture.md) | tidystata |  | 运行代码，出错时返回 FALSE 而不中断 |
| [`case_match()`](https://dplyr.tidyverse.org/reference/case_match.html) | dplyr | recode | 按取值匹配重新编码 |
| [`case_when()`](https://dplyr.tidyverse.org/reference/case-and-replace-when.html) | dplyr |  | 一次写多个条件分支 |
| [`cat()`](https://rdrr.io/r/base/cat.html) | base |  | 打印不带引号的文本 |
| [`cbind()`](https://rdrr.io/r/base/cbind.html) | base | merge 1:1 \_n | 左右拼接（base R） |
| [`ceiling()`](https://rdrr.io/r/base/Round.html) | base |  | 向上取整 |
| [`chisq.test()`](https://rdrr.io/r/stats/chisq.test.html) | stats | tabulate x1 x2, chi2 | 卡方检验 |
| [`class()`](https://rdrr.io/r/base/class.html) | base | describe | 对象的类 |
| `clean_names()` | janitor | rename \*, lower | 清理并小写变量名 |
| `clogit()` | survival |  | 条件 logit 模型 |
| [`coalesce()`](https://dplyr.tidyverse.org/reference/coalesce.html) | dplyr |  | 多个向量中第一个非缺失值 |
| [`codebook()`](https://socimh.github.io/tidystata/reference/codebook.md) | tidystata |  | 描述每个变量：类型、标签、个数和取值 |
| [`coef()`](https://rdrr.io/r/stats/coef.html) | stats |  | 模型系数 |
| `coefplot()` | fixest | coefplot | fixest 模型的系数图 |
| `coeftest()` | lmtest |  | 使用指定方差矩阵的系数检验 |
| [`colnames()`](https://rdrr.io/r/base/colnames.html) | base | ds | 列名 |
| `comparisons()` | marginaleffects | margins r.x | 预测值之差（对比） |
| `complete()` | tidyr |  | 补齐缺失的取值组合 |
| [`complete.cases()`](https://rdrr.io/r/stats/complete.cases.html) | stats | egen rowmiss() | 无缺失值的行 |
| [`confint()`](https://rdrr.io/r/stats/confint.html) | stats | regress | 系数的置信区间 |
| [`consecutive_id()`](https://dplyr.tidyverse.org/reference/consecutive_id.html) | dplyr | tsspell | 对连续相同的取值编号 |
| [`contains()`](https://tidyselect.r-lib.org/reference/starts_with.html) | dplyr |  | 选择名称包含某段文本的列 |
| `coord_cartesian()` | ggplot2 | xscale(range()) | 放大视图而不删除数据 |
| `coord_flip()` | ggplot2 |  | 交换 x 轴和 y 轴 |
| `coord_polar()` | ggplot2 |  | 极坐标，用于饼图 |
| [`cor()`](https://rdrr.io/r/stats/cor.html) | stats |  | 相关矩阵 |
| [`cor.test()`](https://rdrr.io/r/stats/cor.test.html) | stats |  | 带显著性检验的相关系数 |
| [`count()`](https://dplyr.tidyverse.org/reference/count.html) | dplyr |  | 统计每组的行数 |
| [`cov()`](https://rdrr.io/r/stats/cor.html) | stats | correlate, covariance | 协方差 |
| `coxph()` | survival |  | Cox 比例风险模型 |
| [`cross_join()`](https://dplyr.tidyverse.org/reference/cross_join.html) | dplyr |  | 两个数据所有行的组合 |
| `crossing()` | tidyr | cross | 排序并去重的所有组合 |
| [`cumall()`](https://dplyr.tidyverse.org/reference/cumall.html) | dplyr | sum() | 累计的 all()：直到第一个 FALSE 前为 TRUE |
| [`cume_dist()`](https://dplyr.tidyverse.org/reference/percent_rank.html) | dplyr | cumul | 累积分布 |
| [`cumprod()`](https://rdrr.io/r/base/cumsum.html) | base | generate | 累计乘积 |
| [`cumsum()`](https://rdrr.io/r/base/cumsum.html) | base |  | 累计求和 |
| [`cur_group()`](https://dplyr.tidyverse.org/reference/context.html) | dplyr | by | 当前组的分组键 |
| [`cur_group_id()`](https://dplyr.tidyverse.org/reference/context.html) | dplyr |  | 当前组的编号 |
| [`cut()`](https://socimh.github.io/tidystata/reference/cut.md) | base |  | 把数值切分为区间 |
| [`cut_quantile()`](https://socimh.github.io/tidystata/reference/cut.md) | tidystata | xtile | xtile() 的别名 |
| [`data()`](https://rdrr.io/r/utils/data.html) | utils |  | 载入内置的示例数据 |
| `datasummary()` | modelsummary | tabstat | 自定义描述统计表 |
| `datasummary_skim()` | modelsummary | codebook | 快速概览所有变量 |
| `day()` | lubridate |  | 日期中的日 |
| `days()` | lubridate | d + 7 | 以天为单位的时期，用于日期运算 |
| [`decode()`](https://socimh.github.io/tidystata/reference/type_conversion.md) | tidystata |  | 转为文本，带标签的数据使用数值标签 |
| [`dense_rank()`](https://dplyr.tidyverse.org/reference/row_number.html) | dplyr | egen group() | 无间隔的秩 |
| [`density()`](https://rdrr.io/r/stats/density.html) | stats | kdensity | 核密度估计 |
| [`desc()`](https://dplyr.tidyverse.org/reference/desc.html) | dplyr |  | 在 arrange() 中降序排列 |
| `describe()` | psych | summarize | 描述统计（与 Stata 的 describe 不同） |
| [`destring()`](https://socimh.github.io/tidystata/reference/type_conversion.md) | tidystata |  | 转为数值，并去掉数值标签 |
| [`diag()`](https://rdrr.io/r/base/diag.html) | base |  | 矩阵的对角线 |
| [`diff()`](https://rdrr.io/r/base/diff.html) | base | D. | 相邻取值之差 |
| [`dim()`](https://rdrr.io/r/base/dim.html) | base | describe | 行数和列数 |
| [`dir()`](https://rdrr.io/r/base/list.files.html) | base |  | 列出文件夹中的文件 |
| [`dir.create()`](https://rdrr.io/r/base/files2.html) | base | mkdir | 创建文件夹 |
| [`distinct()`](https://dplyr.tidyverse.org/reference/distinct.html) | dplyr |  | 保留不重复的行 |
| `dmy()` | lubridate | date(s, "DMY") | 把日-月-年格式文本解析为日期 |
| [`dnorm()`](https://rdrr.io/r/stats/Normal.html) | stats | normalden() | 正态分布密度 |
| [`do.call()`](https://rdrr.io/r/base/do.call.html) | base | program | 用参数列表调用函数 |
| `drop_na()` | tidyr | drop if missing(x) | 删除含缺失值的行 |
| [`droplevels()`](https://rdrr.io/r/base/droplevels.html) | base | label define | 删除未使用的因子水平 |
| [`ds()`](https://socimh.github.io/tidystata/reference/names.md) | tidystata |  | 列出变量名 |
| [`ds_as_column()`](https://socimh.github.io/tidystata/reference/names.md) | tidystata | ds | 以单列表格列出变量名 |
| [`duplicates_drop()`](https://socimh.github.io/tidystata/reference/keys.md) | tidystata |  | 删除重复行，保留第一行 |
| [`duplicates_list()`](https://socimh.github.io/tidystata/reference/keys.md) | tidystata |  | 列出重复行 |
| [`duplicates_report()`](https://socimh.github.io/tidystata/reference/keys.md) | tidystata |  | 统计重复行 |
| [`duplicates_tag()`](https://socimh.github.io/tidystata/reference/keys.md) | tidystata |  | 标记重复行 |
| [`ecdf()`](https://rdrr.io/r/stats/ecdf.html) | stats | cumul | 经验累积分布 |
| [`ends_with()`](https://tidyselect.r-lib.org/reference/starts_with.html) | dplyr |  | 选择名称以某段文本结尾的列 |
| `etable()` | fixest | esttab | fixest 模型的回归表 |
| [`everything()`](https://tidyselect.r-lib.org/reference/everything.html) | dplyr | \_all | 选择所有列 |
| `excel_sheets()` | readxl | import excel, describe | Excel 文件的工作表名 |
| [`exp()`](https://rdrr.io/r/base/Log.html) | base | exp() | 指数函数 |
| `expand()` | tidyr | fillin | 取值的所有组合（删除其他列） |
| `expand_grid()` | tidyr | cross | 给定取值的所有组合 |
| `fa()` | psych | factor | 方法更多的因子分析 |
| `facet_grid()` | ggplot2 | by() | 按两个变量分面 |
| `facet_wrap()` | ggplot2 |  | 按组分面 |
| [`factanal()`](https://rdrr.io/r/stats/factanal.html) | stats |  | 因子分析 |
| [`factor()`](https://rdrr.io/r/base/factor.html) | base |  | 带标签水平的类别变量 |
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
| `feglm()` | fixest | xtlogit | 带固定效应的广义线性模型（如 logit） |
| `fenegbin()` | fixest | xtnbreg | 带固定效应的负二项模型 |
| `feols()` | fixest |  | 带固定效应、聚类和工具变量的线性回归 |
| `fepois()` | fixest |  | 带固定效应的泊松回归 |
| [`file.exists()`](https://rdrr.io/r/base/files.html) | base | confirm file | 文件是否存在 |
| [`file.path()`](https://rdrr.io/r/base/file.path.html) | base | global path | 构建文件路径 |
| `fill()` | tidyr |  | 用上一个或下一个值填充缺失值 |
| `fill_gaps()` | tsibble |  | 补齐缺失的时间点 |
| [`filter()`](https://dplyr.tidyverse.org/reference/filter.html) | dplyr |  | 保留满足条件的行 |
| [`findit()`](https://socimh.github.io/tidystata/reference/findit.md) | tidystata |  | 查找 Stata 命令对应的 R 函数 |
| [`first()`](https://dplyr.tidyverse.org/reference/nth.html) | dplyr | x\[1\] | 第一个值 |
| [`fisher.test()`](https://rdrr.io/r/stats/fisher.test.html) | stats |  | Fisher 精确检验 |
| `fitstat()` | fixest | estat firststage | 拟合统计量（含第一阶段 F） |
| [`fitted()`](https://rdrr.io/r/stats/fitted.values.html) | stats |  | 模型的拟合值 |
| `fixed()` | stringr |  | 按字面匹配文本，而非正则表达式 |
| `flextable()` | flextable |  | 用于 Word 或 PowerPoint 的格式化表格 |
| [`floor()`](https://rdrr.io/r/base/Round.html) | base |  | 向下取整 |
| `floor_date()` | lubridate | mofd() | 把日期向下取整到某个单位（如月） |
| [`format()`](https://rdrr.io/r/base/format.html) | base |  | 设定显示格式 |
| [`formatC()`](https://rdrr.io/r/base/formatc.html) | base | string(x, "%9.2f") | 按宽度和填充格式化数值 |
| [`fre()`](https://socimh.github.io/tidystata/reference/tab.md) | tidystata |  | 带合计行的频数表 |
| [`fre2()`](https://socimh.github.io/tidystata/reference/tab.md) | tidystata | tabulate | 带行合计和列合计的交叉表 |
| `fread()` | data.table | import delimited | 快速读取大型文本文件 |
| [`ftable()`](https://rdrr.io/r/stats/ftable.html) | stats | table | 扁平化的多维表 |
| [`full_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html) | dplyr |  | 合并并保留两个数据的所有行 |
| `full_seq()` | tidyr | tsfill | 完整的取值序列 |
| `fwrite()` | data.table | export delimited | 快速写出大型文本文件 |
| `geom_abline()` | ggplot2 | function | 给定斜率和截距的直线 |
| `geom_area()` | ggplot2 |  | 面积图 |
| `geom_bar()` | ggplot2 |  | 频数柱状图 |
| `geom_boxplot()` | ggplot2 |  | 箱线图 |
| `geom_col()` | ggplot2 | graph bar (asis) | 给定高度的柱状图 |
| `geom_density()` | ggplot2 |  | 密度曲线 |
| `geom_errorbar()` | ggplot2 |  | 误差线或带端帽的区间 |
| `geom_histogram()` | ggplot2 |  | 直方图 |
| `geom_hline()` | ggplot2 | yline() | 水平参考线 |
| `geom_jitter()` | ggplot2 | scatter, jitter() | 抖动的散点 |
| `geom_label()` | ggplot2 | mlabel() | 带框的文本标签 |
| `geom_line()` | ggplot2 |  | 连接观测值的折线 |
| `geom_point()` | ggplot2 |  | 点（散点图） |
| `geom_pointrange()` | ggplot2 | rcap | 带区间的点 |
| `geom_qq()` | ggplot2 |  | 分位数-分位数图的点 |
| `geom_qq_line()` | ggplot2 |  | 分位数-分位数图的参考线 |
| `geom_ribbon()` | ggplot2 |  | 两个值之间的阴影带 |
| `geom_sf()` | ggplot2 | spmap | 基于空间数据的地图 |
| `geom_smooth()` | ggplot2 |  | 拟合直线或平滑曲线 |
| `geom_step()` | ggplot2 | line, connect(stairstep) | 阶梯图 |
| `geom_text()` | ggplot2 |  | 图中的文本标签 |
| `geom_tile()` | ggplot2 | heatplot | 热图方块 |
| `geom_violin()` | ggplot2 |  | 小提琴图 |
| `geom_vline()` | ggplot2 |  | 竖直参考线 |
| `get_dupes()` | janitor | duplicates list | 列出重复行 |
| [`getAnywhere()`](https://rdrr.io/r/utils/getAnywhere.html) | utils |  | 查找函数定义在哪里 |
| [`getwd()`](https://rdrr.io/r/base/getwd.html) | base |  | 显示工作文件夹 |
| `ggplot()` | ggplot2 |  | 开始绘图 |
| `ggsave()` | ggplot2 |  | 把图形保存为文件 |
| `glance()` | broom |  | 模型统计量的一行概要 |
| [`glimpse()`](https://pillar.r-lib.org/reference/glimpse.html) | dplyr | describe | 紧凑地查看所有列 |
| [`glm()`](https://rdrr.io/r/stats/glm.html) | stats |  | 广义线性模型，如 logit 或泊松模型 |
| `glm.nb()` | MASS |  | 负二项回归 |
| `glmer()` | lme4 |  | 多层广义线性模型 |
| [`glob2rx()`](https://rdrr.io/r/utils/glob2rx.html) | utils |  | 把通配符模式转为正则表达式 |
| [`grepl()`](https://rdrr.io/r/base/grep.html) | base |  | 文本是否匹配某个模式 |
| [`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html) | dplyr |  | 分组，使后续操作在组内进行 |
| [`group_split()`](https://dplyr.tidyverse.org/reference/group_split.html) | dplyr | by | 按组拆分为多个数据 |
| [`group_vars()`](https://dplyr.tidyverse.org/reference/group_data.html) | dplyr | by | 分组变量的名称 |
| [`gsub()`](https://rdrr.io/r/base/grep.html) | base | subinstr() | 替换所有匹配 |
| [`head()`](https://rdrr.io/r/utils/head.html) | utils |  | 前几行 |
| [`help()`](https://rdrr.io/r/utils/help.html) | utils |  | 打开帮助页面 |
| [`help.search()`](https://rdrr.io/r/utils/help.search.html) | utils |  | 搜索所有已安装的帮助文档 |
| `hour()` | lubridate | hh() | 小时 |
| `hypotheses()` | marginaleffects |  | 线性和非线性假设检验 |
| [`if_all()`](https://dplyr.tidyverse.org/reference/across.html) | dplyr | egen rowmin() | 多列是否都满足条件 |
| [`if_any()`](https://dplyr.tidyverse.org/reference/across.html) | dplyr | egen anymatch() | 多列中是否有任一列满足条件 |
| [`if_else()`](https://dplyr.tidyverse.org/reference/if_else.html) | dplyr |  | 条件成立取一个值，否则取另一个值 |
| [`ifelse()`](https://rdrr.io/r/base/ifelse.html) | base | cond() | 向量化的条件判断（base R） |
| [`inner_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html) | dplyr |  | 合并并只保留匹配成功的行 |
| [`install.packages()`](https://rdrr.io/r/utils/install.packages.html) | utils |  | 从 CRAN 安装包 |
| `install_github()` | remotes |  | 从 GitHub 安装包 |
| [`interaction()`](https://rdrr.io/r/base/interaction.html) | base | egen group() | 把多个因子组合为一个 |
| [`intersect()`](https://generics.r-lib.org/reference/setops.html) | dplyr | merge, keep(match) | 两个数据中都有的行 |
| `interval()` | lubridate |  | 两个日期之间的时间段 |
| [`IQR()`](https://rdrr.io/r/stats/IQR.html) | stats | egen iqr() | 四分位距 |
| [`is.character()`](https://rdrr.io/r/base/character.html) | base | confirm string variable | 向量是否为文本型 |
| [`is.na()`](https://rdrr.io/r/base/NA.html) | base |  | 是否为缺失值 |
| [`is.numeric()`](https://rdrr.io/r/base/numeric.html) | base | confirm numeric variable | 向量是否为数值型 |
| [`is_first()`](https://socimh.github.io/tidystata/reference/is_first.md) | tidystata |  | 标记每组的第一行 |
| [`isid()`](https://socimh.github.io/tidystata/reference/keys.md) | tidystata |  | 检查变量能否唯一识别每一行 |
| [`join_by()`](https://dplyr.tidyverse.org/reference/join_by.html) | dplyr | joinby | 合并键，包括不等式和区间合并 |
| [`kmeans()`](https://rdrr.io/r/stats/kmeans.html) | stats |  | K 均值聚类 |
| [`kruskal.test()`](https://rdrr.io/r/stats/kruskal.test.html) | stats |  | Kruskal-Wallis 检验 |
| [`ks.test()`](https://rdrr.io/r/stats/ks.test.html) | stats |  | Kolmogorov-Smirnov 检验 |
| `labelled()` | haven |  | 给向量加上数值标签 |
| `labs()` | ggplot2 | title() | 标题和坐标轴标签 |
| [`lag()`](https://dplyr.tidyverse.org/reference/lead-lag.html) | dplyr |  | 上一行的值 |
| [`lapply()`](https://rdrr.io/r/base/lapply.html) | base | foreach | 对每个元素应用函数，返回列表 |
| [`last()`](https://dplyr.tidyverse.org/reference/nth.html) | dplyr | x\[\_N\] | 最后一个值 |
| [`last_col()`](https://tidyselect.r-lib.org/reference/everything.html) | dplyr | order | 最后一列 |
| [`lead()`](https://dplyr.tidyverse.org/reference/lead-lag.html) | dplyr |  | 下一行的值 |
| [`left_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html) | dplyr |  | 合并并保留第一个数据的所有行 |
| [`length()`](https://rdrr.io/r/base/length.html) | base | count | 元素个数 |
| [`levels()`](https://rdrr.io/r/base/levels.html) | base |  | 因子的类别 |
| [`library()`](https://rdrr.io/r/base/library.html) | base | ssc install | 加载包 |
| `linearHypothesis()` | car | test | 检验系数的线性约束 |
| [`list()`](https://rdrr.io/r/base/list.html) | base |  | 对象列表 |
| [`list.files()`](https://rdrr.io/r/base/list.files.html) | base | dir | 文件夹中的文件 |
| `list_rbind()` | purrr | append | 把数据框列表上下拼接 |
| [`lm()`](https://rdrr.io/r/stats/lm.html) | stats |  | 线性回归 |
| `lmer()` | lme4 |  | 多层线性模型 |
| [`load()`](https://rdrr.io/r/base/load.html) | base | use | 从 .RData 文件载入对象 |
| [`log()`](https://rdrr.io/r/base/Log.html) | base |  | 对数（默认为自然对数） |
| [`log10()`](https://rdrr.io/r/base/Log.html) | base | log10() | 以 10 为底的对数 |
| [`logLik()`](https://rdrr.io/r/stats/logLik.html) | stats | e(ll) | 模型的对数似然 |
| `look_for()` | labelled | lookfor | 按名称或标签查找变量 |
| [`lowess()`](https://rdrr.io/r/stats/lowess.html) | stats | lowess | Lowess 平滑 |
| `lrtest()` | lmtest |  | 似然比检验 |
| [`ls()`](https://rdrr.io/r/base/ls.html) | base |  | 列出内存中的对象 |
| [`mad()`](https://rdrr.io/r/stats/mad.html) | stats | egen mad() | 中位数绝对偏差 |
| [`make.names()`](https://rdrr.io/r/base/make.names.html) | base |  | 把文本转为合法的名称 |
| `make_date()` | lubridate |  | 由年、月、日生成日期 |
| `make_datetime()` | lubridate | mdyhms() | 由各部分生成日期时间 |
| `map()` | purrr | foreach | 对每个元素应用函数，返回列表 |
| `map2()` | purrr | forvalues | 对成对的元素应用函数 |
| `map_chr()` | purrr | foreach | 对每个元素应用函数，返回文本 |
| `map_dbl()` | purrr | foreach | 对每个元素应用函数，返回数值 |
| [`matches()`](https://tidyselect.r-lib.org/reference/starts_with.html) | dplyr |  | 选择名称匹配正则表达式的列 |
| `matchit()` | MatchIt |  | 用于因果推断的匹配 |
| [`matrix()`](https://rdrr.io/r/base/matrix.html) | base |  | 生成矩阵 |
| [`max()`](https://rdrr.io/r/base/Extremes.html) | base |  | 最大值 |
| [`mcnemar.test()`](https://rdrr.io/r/stats/mcnemar.test.html) | stats | mcc | 配对比例的 McNemar 检验 |
| `mdy()` | lubridate | date(s, "MDY") | 把月-日-年格式文本解析为日期 |
| [`mean()`](https://rdrr.io/r/base/mean.html) | base |  | 均值 |
| [`median()`](https://rdrr.io/r/stats/median.html) | stats |  | 中位数 |
| [`merge()`](https://rdrr.io/r/base/merge.html) | base | merge | 合并两个数据框（base R） |
| [`message()`](https://rdrr.io/r/base/message.html) | base | display | 打印消息 |
| `mice()` | mice |  | 链式方程多重插补 |
| [`min()`](https://rdrr.io/r/base/Extremes.html) | base |  | 最小值 |
| [`min_rank()`](https://dplyr.tidyverse.org/reference/row_number.html) | dplyr | egen rank(), track | 秩（相同取值取最小秩） |
| `minute()` | lubridate | mm() | 分钟 |
| [`misstable()`](https://socimh.github.io/tidystata/reference/misstable.md) | tidystata |  | 每个变量的缺失值，或缺失值模式 |
| [`model.matrix()`](https://rdrr.io/r/stats/model.matrix.html) | stats | xi | 含虚拟变量的设计矩阵 |
| `modelplot()` | modelsummary |  | 系数图 |
| `modelsummary()` | modelsummary |  | 回归结果表和描述统计表 |
| `month()` | lubridate |  | 日期中的月份 |
| `multinom()` | nnet |  | 多项 logit 模型 |
| [`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html) | dplyr |  | 生成或修改列 |
| [`mvdecode()`](https://socimh.github.io/tidystata/reference/na_conversion.md) | tidystata |  | 把指定代码改为缺失值 |
| [`mvencode()`](https://socimh.github.io/tidystata/reference/na_conversion.md) | tidystata |  | 把缺失值替换为指定代码 |
| [`n()`](https://dplyr.tidyverse.org/reference/context.html) | dplyr |  | 当前组的行数 |
| [`n_distinct()`](https://dplyr.tidyverse.org/reference/n_distinct.html) | dplyr | distinct | 不同取值的个数 |
| [`na.omit()`](https://rdrr.io/r/stats/na.fail.html) | stats |  | 删除含缺失值的行 |
| [`na_if()`](https://dplyr.tidyverse.org/reference/na_if.html) | dplyr |  | 把某个取值改为缺失值 |
| [`na_if_value()`](https://socimh.github.io/tidystata/reference/na_conversion.md) | tidystata | mvdecode | mvdecode() 的别名 |
| [`names()`](https://socimh.github.io/tidystata/reference/names.md) | base |  | 对象的名称，例如列名 |
| [`names_as_column()`](https://socimh.github.io/tidystata/reference/names.md) | tidystata | ds | ds_as_column() 的别名 |
| [`nchar()`](https://rdrr.io/r/base/nchar.html) | base | strlen() | 字符个数 |
| [`ncol()`](https://rdrr.io/r/base/nrow.html) | base | describe | 列数 |
| [`near()`](https://dplyr.tidyverse.org/reference/near.html) | dplyr | reldif() | 带容差地比较数值 |
| `nest()` | tidyr | by | 把每组嵌套为列表列中的一行 |
| [`nlevels()`](https://rdrr.io/r/base/nlevels.html) | base | levelsof | 因子水平个数 |
| [`nls()`](https://rdrr.io/r/stats/nls.html) | stats | nl | 非线性最小二乘 |
| [`nobs()`](https://rdrr.io/r/stats/nobs.html) | stats | e(N) | 模型使用的观测数 |
| `now()` | lubridate | now() | 当前日期和时间 |
| [`nrow()`](https://rdrr.io/r/base/nrow.html) | base |  | 行数 |
| [`nth()`](https://dplyr.tidyverse.org/reference/nth.html) | dplyr | x\[5\] | 指定位置的值 |
| [`ntile()`](https://dplyr.tidyverse.org/reference/ntile.html) | dplyr | xtile | 分成 n 个大小相近的组 |
| [`num_range()`](https://tidyselect.r-lib.org/reference/starts_with.html) | dplyr | keep x1-x5 | 按编号选择 x1、x2 等列 |
| `oaxaca()` | oaxaca |  | Blinder-Oaxaca 分解 |
| [`optim()`](https://rdrr.io/r/stats/optim.html) | stats | ml | 通用最优化 |
| [`options()`](https://rdrr.io/r/base/options.html) | base | set | 设定全局选项 |
| [`order()`](https://rdrr.io/r/base/order.html) | base | sort | 使向量排序的位置 |
| [`p.adjust()`](https://rdrr.io/r/stats/p.adjust.html) | stats | test, mtest | 多重检验的 p 值校正 |
| [`pairs()`](https://rdrr.io/r/graphics/pairs.html) | graphics |  | 散点图矩阵 |
| [`pairwise.t.test()`](https://rdrr.io/r/stats/pairwise.t.test.html) | stats | pwmean | 带校正 p 值的两两 t 检验 |
| `parse_number()` | readr | destring, ignore() | 从 \$1,200 这样的文本中提取数字 |
| [`paste()`](https://rdrr.io/r/base/paste.html) | base |  | 用分隔符连接文本 |
| [`paste0()`](https://rdrr.io/r/base/paste.html) | base |  | 不加分隔符连接文本 |
| [`pc()`](https://socimh.github.io/tidystata/reference/std.md) | tidystata |  | 占总和的百分比 |
| [`pchisq()`](https://rdrr.io/r/stats/Chisquare.html) | stats | chi2tail() | 卡方分布概率 |
| [`pct()`](https://socimh.github.io/tidystata/reference/std.md) | tidystata | egen pc() | pc() 的别名 |
| `pdata.frame()` | plm | xtset | 为 plm 声明面板数据 |
| [`percent_rank()`](https://dplyr.tidyverse.org/reference/percent_rank.html) | dplyr | egen rank() | 缩放到 0 到 1 的秩 |
| `pgmm()` | plm |  | 动态面板 GMM（Arellano-Bond） |
| `phtest()` | plm | hausman | Hausman 检验 |
| [`pick()`](https://dplyr.tidyverse.org/reference/pick.html) | dplyr | varlist | 在 mutate() 或 summarise() 中选取列 |
| `pivot_longer()` | tidyr |  | 宽数据转为长数据 |
| `pivot_wider()` | tidyr |  | 长数据转为宽数据 |
| `plm()` | plm |  | 面板模型：固定效应和随机效应 |
| [`plot()`](https://rdrr.io/r/graphics/plot.default.html) | base |  | 基础绘图 |
| `plot_predictions()` | marginaleffects |  | 绘制预测值，类似 marginsplot |
| `plot_slopes()` | marginaleffects | marginsplot | 绘制边际效应 |
| [`pmax()`](https://rdrr.io/r/base/Extremes.html) | base | max(a, b) | 多个向量的逐元素最大值 |
| [`pmin()`](https://rdrr.io/r/base/Extremes.html) | base | min(a, b) | 多个向量的逐元素最小值 |
| [`pnorm()`](https://rdrr.io/r/stats/Normal.html) | stats | normal() | 正态分布累积概率 |
| `polr()` | MASS |  | 有序 logit 或 probit 模型 |
| [`poly()`](https://rdrr.io/r/stats/poly.html) | stats |  | 模型中的多项式项 |
| `pool()` | mice |  | 合并多个插补数据的结果 |
| `position_dodge()` | ggplot2 | over() | 把柱子或点并排放置 |
| `possibly()` | purrr | capture | 出错时返回默认值 |
| [`power.t.test()`](https://rdrr.io/r/stats/power.t.test.html) | stats | power twomeans | t 检验的功效和样本量 |
| [`prcomp()`](https://rdrr.io/r/stats/prcomp.html) | stats |  | 主成分分析 |
| [`predict()`](https://rdrr.io/r/stats/predict.html) | stats |  | 模型的预测值 |
| `predictions()` | marginaleffects | margins | 带标准误的预测值 |
| [`print()`](https://rdrr.io/r/base/print.html) | base |  | 打印对象 |
| [`print_all()`](https://socimh.github.io/tidystata/reference/special-print.md) | tidystata |  | 打印所有行和列 |
| `print_labels()` | haven | label list | 显示数值标签 |
| [`prop.table()`](https://rdrr.io/r/base/proportions.html) | base |  | 把频数转为比例 |
| [`prop.test()`](https://rdrr.io/r/stats/prop.test.html) | stats |  | 比例检验 |
| [`proportions()`](https://rdrr.io/r/base/proportions.html) | base | tabulate, row | 把表格转为比例 |
| [`pt()`](https://rdrr.io/r/stats/TDist.html) | stats | ttail() | t 分布概率 |
| [`pull()`](https://dplyr.tidyverse.org/reference/pull.html) | dplyr |  | 把一列提取为向量 |
| [`pwcorr()`](https://socimh.github.io/tidystata/reference/pwcorr.md) | tidystata |  | 两两相关系数，附样本数和 p 值 |
| [`qnorm()`](https://rdrr.io/r/stats/Normal.html) | stats | invnormal() | 正态分布分位数 |
| [`quantile()`](https://rdrr.io/r/stats/quantile.html) | stats |  | 分位数 |
| `quarter()` | lubridate | quarter() | 日期所在的季度 |
| [`quasibinomial()`](https://rdrr.io/r/stats/family.html) | stats |  | 适用于抽样权重的二项分布族 |
| `ranef()` | lme4 | predict, reffects | 随机效应的预测值 |
| [`range()`](https://rdrr.io/r/base/range.html) | base | summarize | 最小值和最大值 |
| [`rank()`](https://rdrr.io/r/base/rank.html) | base |  | 秩（相同取值取平均秩） |
| [`rbind()`](https://rdrr.io/r/base/cbind.html) | base | append | 上下拼接（base R） |
| [`rbinom()`](https://rdrr.io/r/stats/Binomial.html) | stats | rbinomial() | 二项分布随机数 |
| `rdrobust()` | rdrobust |  | 断点回归 |
| [`read.csv()`](https://rdrr.io/r/utils/read.table.html) | utils | import delimited | 读取 CSV 文件（base R） |
| `read_csv()` | readr |  | 读取 CSV 文件 |
| `read_delim()` | readr | import delimited | 读取任意分隔符的文件 |
| `read_dta()` | haven |  | 读取 Stata .dta 文件 |
| `read_excel()` | readxl |  | 读取 Excel 工作表 |
| `read_sas()` | haven |  | 读取 SAS 文件 |
| `read_sav()` | haven |  | 读取 SPSS .sav 文件 |
| `read_tsv()` | readr | import delimited | 读取制表符分隔的文件 |
| [`readRDS()`](https://rdrr.io/r/base/readRDS.html) | base | use | 读取 R 对象文件（.rds） |
| `reduce()` | purrr | merge | 依次合并元素（如多次合并） |
| [`reframe()`](https://dplyr.tidyverse.org/reference/reframe.html) | dplyr | collapse | 每组汇总为任意行数 |
| `regex()` | stringr |  | 带 ignore_case 等选项的正则表达式 |
| [`relevel()`](https://rdrr.io/r/stats/relevel.html) | stats |  | 指定因子的参照类别 |
| [`relocate()`](https://dplyr.tidyverse.org/reference/relocate.html) | dplyr |  | 移动列的位置 |
| `remove_empty()` | janitor | missings dropvars | 删除空行和空列 |
| [`rename()`](https://dplyr.tidyverse.org/reference/rename.html) | dplyr |  | 重命名列（新名 = 旧名） |
| [`rename_with()`](https://dplyr.tidyverse.org/reference/rename.html) | dplyr |  | 用函数（如 toupper）批量重命名列 |
| [`rep()`](https://rdrr.io/r/base/rep.html) | base | expand | 重复取值 |
| [`rep_len()`](https://rdrr.io/r/base/rep.html) | base |  | 把取值重复到指定长度 |
| `replace_na()` | tidyr | replace x = 0 if missing(x) | 替换缺失值 |
| `resettest()` | lmtest |  | 遗漏变量 RESET 检验 |
| [`residuals()`](https://rdrr.io/r/stats/residuals.html) | stats | predict, residuals | 模型残差 |
| [`rev()`](https://rdrr.io/r/base/rev.html) | base | gsort | 反转顺序 |
| [`right_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html) | dplyr |  | 合并并保留第二个数据的所有行 |
| `rlm()` | MASS |  | 稳健回归 |
| [`rm()`](https://rdrr.io/r/base/rm.html) | base |  | 从内存中删除对象 |
| [`rnorm()`](https://rdrr.io/r/stats/Normal.html) | stats |  | 正态分布随机数 |
| [`round()`](https://rdrr.io/r/base/Round.html) | base |  | 按小数位数四舍五入 |
| [`row_max()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | 逐行求多个变量的最大值 |
| [`row_mean()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | 逐行求多个变量的均值 |
| [`row_median()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | 逐行求多个变量的中位数 |
| [`row_min()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | 逐行求多个变量的最小值 |
| [`row_miss()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | 逐行计算缺失值个数 |
| [`row_non_miss()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | 逐行计算非缺失值个数 |
| [`row_number()`](https://dplyr.tidyverse.org/reference/row_number.html) | dplyr |  | 行号 |
| [`row_nvals()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | 每行不同取值的个数，忽略缺失值 |
| [`row_sd()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | 逐行求多个变量的标准差 |
| [`row_sum()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | 逐行求多个变量的和 |
| [`row_unique()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata | egen rownvals() | 每行不同取值的个数，缺失值算作一个取值 |
| `rownames_to_column()` | tibble | xpose | 把行名转为一列 |
| [`rows_update()`](https://dplyr.tidyverse.org/reference/rows.html) | dplyr | merge, update replace | 用另一个数据更新行 |
| [`rowSums()`](https://rdrr.io/r/base/colSums.html) | base |  | 逐行求和 |
| [`rowwise()`](https://dplyr.tidyverse.org/reference/rowwise.html) | dplyr | egen rowmean() | 逐行计算 |
| `rq()` | quantreg |  | 分位数回归 |
| [`runif()`](https://rdrr.io/r/stats/Uniform.html) | stats |  | 均匀分布随机数 |
| [`s_diff()`](https://socimh.github.io/tidystata/reference/panel.md) | tidystata |  | 与上一期的差分（考虑时间间隔） |
| [`s_lag()`](https://socimh.github.io/tidystata/reference/panel.md) | tidystata |  | 前若干期的值（考虑时间间隔） |
| [`s_lead()`](https://socimh.github.io/tidystata/reference/panel.md) | tidystata |  | 后若干期的值（考虑时间间隔） |
| [`s_merge()`](https://socimh.github.io/tidystata/reference/s_merge.md) | tidystata |  | 合并两个数据并报告匹配结果，类似 Stata 的 merge |
| [`s_print()`](https://socimh.github.io/tidystata/reference/special-print.md) | tidystata | list | 打印首尾几行、等距的几行或全部行 |
| [`s_tag()`](https://socimh.github.io/tidystata/reference/is_first.md) | tidystata | egen tag() | is_first() 的别名 |
| [`s_try()`](https://socimh.github.io/tidystata/reference/capture.md) | tidystata | capture | capture() 的别名 |
| [`sample()`](https://rdrr.io/r/base/sample.html) | base | sample | 随机抽取取值 |
| [`sapply()`](https://rdrr.io/r/base/lapply.html) | base | foreach | 对每个元素应用函数并简化结果 |
| [`save()`](https://rdrr.io/r/base/save.html) | base | save | 把对象保存为 .RData 文件 |
| `save_as_docx()` | flextable |  | 把表格保存为 Word 文件 |
| [`saveRDS()`](https://rdrr.io/r/base/readRDS.html) | base |  | 把一个 R 对象保存到文件 |
| [`scale()`](https://rdrr.io/r/base/scale.html) | base | egen std() | 标准化列 |
| `scale_colour_manual()` | ggplot2 | mcolor() | 手动指定颜色 |
| `scale_fill_brewer()` | ggplot2 | set scheme | ColorBrewer 填充颜色 |
| `scale_x_continuous()` | ggplot2 | xlabel() | 坐标轴刻度和标签 |
| `scale_x_log10()` | ggplot2 | xscale(log) | 对数刻度的 x 轴 |
| [`sd()`](https://rdrr.io/r/stats/sd.html) | stats |  | 标准差 |
| [`select()`](https://dplyr.tidyverse.org/reference/select.html) | dplyr |  | 保留或删除列 |
| `selection()` | sampleSelection |  | Heckman 样本选择模型 |
| `sem()` | lavaan |  | 结构方程模型 |
| [`semi_join()`](https://dplyr.tidyverse.org/reference/filter-joins.html) | dplyr |  | 保留第一个数据中在第二个数据里有匹配的行 |
| `separate_longer_delim()` | tidyr | split | 把文本拆分成多行 |
| `separate_wider_delim()` | tidyr |  | 把一个文本列拆分成多列 |
| `separate_wider_position()` | tidyr | substr() | 按位置把文本拆分成多列 |
| [`seq()`](https://rdrr.io/r/base/seq.html) | base |  | 数列 |
| [`seq_along()`](https://rdrr.io/r/base/seq.html) | base | \_n | 向量元素的位置 |
| [`seq_len()`](https://rdrr.io/r/base/seq.html) | base | \_n | 从 1 到 n 的整数 |
| [`set.seed()`](https://rdrr.io/r/base/Random.html) | base |  | 设定随机数种子 |
| [`set_seed()`](https://socimh.github.io/tidystata/reference/set_seed.md) | tidystata |  | 设定随机数种子，可单独使用或放在管道末尾 |
| `set_variable_labels()` | labelled |  | 设定变量标签 |
| [`setdiff()`](https://generics.r-lib.org/reference/setops.html) | dplyr | merge, keep(master) | 只在第一个数据中的行 |
| [`setwd()`](https://rdrr.io/r/base/getwd.html) | base |  | 更换工作文件夹 |
| [`shapiro.test()`](https://rdrr.io/r/stats/shapiro.test.html) | stats |  | Shapiro-Wilk 正态性检验 |
| [`signif()`](https://rdrr.io/r/base/Round.html) | base | round() | 按有效数字取舍 |
| [`sink()`](https://rdrr.io/r/base/sink.html) | base |  | 把控制台输出写入文件 |
| [`slice()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr |  | 按位置保留行 |
| [`slice_head()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr | bysort g: keep if \_n \<= 3 | 每组的前几行 |
| [`slice_max()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr | gsort -x; keep in 1/5 | 取值最大的若干行 |
| [`slice_min()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr | sort x; keep in 1/5 | 取值最小的若干行 |
| [`slice_sample()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr |  | 随机抽取若干行 |
| [`slice_tail()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr | bysort g: keep if \_n \> \_N - 3 | 每组的最后几行 |
| `slopes()` | marginaleffects | margins, dydx(x) at() | 每个观测的边际效应 |
| [`sort()`](https://rdrr.io/r/base/sort.html) | base |  | 对向量排序 |
| [`source()`](https://rdrr.io/r/base/source.html) | base |  | 运行 R 脚本 |
| [`split()`](https://rdrr.io/r/base/split.html) | base | by | 把数据按组拆分 |
| [`sprintf()`](https://rdrr.io/r/base/sprintf.html) | base |  | 用模板格式化数值和文本 |
| [`sqrt()`](https://rdrr.io/r/base/MathFun.html) | base |  | 平方根 |
| [`starts_with()`](https://tidyselect.r-lib.org/reference/starts_with.html) | dplyr |  | 选择名称以某段文本开头的列 |
| `stat_ecdf()` | ggplot2 | cumul | 经验累积分布图 |
| `stat_summary()` | ggplot2 |  | 在每个 x 处绘制 y 的汇总值（如均值） |
| [`std()`](https://socimh.github.io/tidystata/reference/std.md) | tidystata |  | 标准化为均值 0、标准差 1 |
| [`stem()`](https://rdrr.io/r/graphics/stem.html) | graphics |  | 茎叶图 |
| [`step()`](https://rdrr.io/r/stats/step.html) | stats | stepwise | 逐步回归选择 |
| [`stop()`](https://rdrr.io/r/base/stop.html) | base | exit 198 | 报错并停止 |
| [`stopifnot()`](https://rdrr.io/r/base/stopifnot.html) | base |  | 条件不为 TRUE 时报错 |
| [`str()`](https://rdrr.io/r/utils/str.html) | utils |  | 简要显示对象的结构 |
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
| `strata()` | survival |  | 生存模型公式中的分层项 |
| [`strsplit()`](https://rdrr.io/r/base/strsplit.html) | base | split | 拆分字符串 |
| [`sub()`](https://rdrr.io/r/base/grep.html) | base | regexr() | 替换第一个匹配 |
| [`subset()`](https://rdrr.io/r/base/subset.html) | base | keep if | 满足条件的行（base R） |
| [`substr()`](https://rdrr.io/r/base/substr.html) | base | substr() | 按位置截取字符串 |
| [`sum()`](https://rdrr.io/r/base/sum.html) | base |  | 求和 |
| [`summ()`](https://socimh.github.io/tidystata/reference/summ.md) | tidystata |  | 变量的描述统计 |
| [`summarise()`](https://dplyr.tidyverse.org/reference/summarise.html) | dplyr |  | 把每组汇总为一行统计量 |
| [`summarize()`](https://dplyr.tidyverse.org/reference/summarise.html) | dplyr | collapse | 同 summarise() |
| [`summary()`](https://rdrr.io/r/base/summary.html) | base |  | 对象（如模型）的概要 |
| `Surv()` | survival |  | 模型中的生存时间结局变量 |
| `survdiff()` | survival |  | Log-rank 检验 |
| `survey_mean()` | srvyr |  | 考虑抽样设计的加权均值 |
| `survey_prop()` | srvyr |  | 考虑抽样设计的加权比例 |
| `survey_quantile()` | srvyr | epctile | 加权分位数 |
| `survey_total()` | srvyr | svy: total | 加权总和 |
| `survfit()` | survival |  | Kaplan-Meier 生存曲线 |
| `survreg()` | survival |  | 参数生存模型 |
| `svydesign()` | survey | svyset | 声明抽样设计（survey 包） |
| `svyglm()` | survey |  | 考虑抽样设计的回归 |
| `svymean()` | survey | svy: mean | 加权均值（survey 包） |
| `svytable()` | survey | svy: tabulate | 加权频数表 |
| `synth()` | Synth |  | 合成控制法 |
| [`Sys.Date()`](https://rdrr.io/r/base/Sys.time.html) | base |  | 今天的日期 |
| [`Sys.time()`](https://rdrr.io/r/base/Sys.time.html) | base | c(current_time) | 当前日期和时间 |
| [`t()`](https://rdrr.io/r/base/t.html) | base |  | 矩阵转置 |
| [`t.test()`](https://rdrr.io/r/stats/t.test.html) | stats |  | t 检验和均值的置信区间 |
| [`tab()`](https://socimh.github.io/tidystata/reference/tab.md) | tidystata |  | 频数表 |
| [`tab1()`](https://socimh.github.io/tidystata/reference/tab.md) | tidystata |  | 每个变量一张频数表 |
| [`tab2()`](https://socimh.github.io/tidystata/reference/tab.md) | tidystata |  | 两个变量的交叉表，或每一对变量的交叉表 |
| [`tab_gen()`](https://socimh.github.io/tidystata/reference/as_dummy.md) | tidystata | tabulate, generate() | as_dummy() 的别名 |
| [`table()`](https://rdrr.io/r/base/table.html) | base |  | 统计各取值的个数 |
| [`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md) | tidystata |  | 变量的指定统计量，可分组 |
| `tabyl()` | janitor | tabulate | 频数表和交叉表 |
| `tagged_na()` | haven | replace x = .a | Stata 式扩展缺失值（如 .a） |
| [`tail()`](https://rdrr.io/r/utils/head.html) | utils |  | 最后几行 |
| [`tally()`](https://dplyr.tidyverse.org/reference/count.html) | dplyr | count | 统计行数 |
| [`tapply()`](https://rdrr.io/r/base/tapply.html) | base | bysort g: egen | 分组应用函数 |
| `tbl_cross()` | gtsummary | tabulate x1 x2 | 交叉表 |
| `tbl_regression()` | gtsummary | esttab | 回归结果表 |
| `tbl_summary()` | gtsummary |  | 描述统计表（“表 1”） |
| [`tempfile()`](https://rdrr.io/r/base/tempfile.html) | base |  | 临时文件名 |
| `theme()` | ggplot2 | graphregion() | 微调图形样式 |
| `theme_bw()` | ggplot2 |  | 黑白图形主题 |
| `theme_classic()` | ggplot2 | set scheme | 经典图形主题 |
| `theme_minimal()` | ggplot2 | set scheme | 简洁图形主题 |
| `theme_set()` | ggplot2 |  | 设定所有图形的默认主题 |
| [`tibble()`](https://tibble.tidyverse.org/reference/tibble.html) | tibble |  | 创建数据框（tibble） |
| `tidy()` | broom |  | 以数据框形式给出系数表 |
| `time_length()` | lubridate |  | 以指定单位（如年）计算时间段长度 |
| [`timer()`](https://socimh.github.io/tidystata/reference/timer.md) | tidystata |  | 计算代码运行时间 |
| `to_factor()` | labelled | decode | 把带标签的取值转为因子 |
| `tobit()` | AER |  | Tobit（删失）回归 |
| `today()` | lubridate | today() | 今天的日期 |
| [`tolower()`](https://rdrr.io/r/base/chartr.html) | base | strlower() | 转为小写 |
| [`tostring()`](https://socimh.github.io/tidystata/reference/type_conversion.md) | tidystata |  | 转换为文本，保留数值代码而不是数值标签 |
| [`toupper()`](https://rdrr.io/r/base/chartr.html) | base | strupper() | 转为大写 |
| [`traceback()`](https://rdrr.io/r/base/traceback.html) | base |  | 显示上一个错误发生的位置 |
| [`transmute()`](https://dplyr.tidyverse.org/reference/transmute.html) | dplyr | keep | 生成新列并只保留它们 |
| [`tribble()`](https://tibble.tidyverse.org/reference/tribble.html) | tibble | input | 按行手动输入小表格 |
| [`trimws()`](https://rdrr.io/r/base/trimws.html) | base | strtrim() | 去掉首尾空格 |
| [`trunc()`](https://rdrr.io/r/base/Round.html) | base | int() | 去掉小数部分 |
| [`try()`](https://rdrr.io/r/base/try.html) | base | capture | 出错后继续运行 |
| [`tryCatch()`](https://rdrr.io/r/base/conditions.html) | base | capture | 处理错误和警告 |
| [`ts()`](https://rdrr.io/r/stats/ts.html) | stats | tsset | 时间序列对象 |
| [`TukeyHSD()`](https://rdrr.io/r/stats/TukeyHSD.html) | stats | pwcompare, mcompare(tukey) | Tukey 多重比较 |
| [`typeof()`](https://rdrr.io/r/base/typeof.html) | base | describe | 存储类型 |
| `uncount()` | tidyr |  | 把每行重复指定次数 |
| [`ungroup()`](https://dplyr.tidyverse.org/reference/group_by.html) | dplyr |  | 取消分组 |
| [`union()`](https://generics.r-lib.org/reference/setops.html) | dplyr | append | 两个数据中的所有行（去重） |
| [`unique()`](https://rdrr.io/r/base/unique.html) | base |  | 不重复的取值 |
| `unite()` | tidyr | egen concat() | 把多列合并为一列 |
| `unnest()` | tidyr | expand | 把列表列展开为行 |
| [`update()`](https://rdrr.io/r/stats/update.html) | stats | regress | 修改后重新拟合模型 |
| [`update.packages()`](https://rdrr.io/r/utils/update.packages.html) | utils |  | 更新已安装的包 |
| `val_labels()` | labelled | label values | 读取或设定数值标签 |
| [`value_if_na()`](https://socimh.github.io/tidystata/reference/na_conversion.md) | tidystata | mvencode | mvencode() 的别名 |
| [`var()`](https://rdrr.io/r/stats/cor.html) | stats | summarize, detail | 方差 |
| [`var.test()`](https://rdrr.io/r/stats/var.test.html) | stats | sdtest | 方差相等的 F 检验 |
| `var_label()` | labelled | label variable | 读取或设定变量标签 |
| `VarCorr()` | lme4 | estat sd | 多层模型的方差成分 |
| [`variables()`](https://socimh.github.io/tidystata/reference/variables.md) | tidystata |  | 列出变量及其类型和标签 |
| [`variables_search()`](https://socimh.github.io/tidystata/reference/variables.md) | tidystata |  | 按变量名或标签查找变量 |
| [`varlist()`](https://socimh.github.io/tidystata/reference/varlist.md) | tidystata |  | 用 x\* 等 Stata 通配符选择变量 |
| [`vcov()`](https://rdrr.io/r/stats/vcov.html) | stats |  | 模型的方差协方差矩阵 |
| `vcovBS()` | sandwich |  | 自助法方差矩阵 |
| `vcovCL()` | sandwich | vce(cluster id) | 聚类方差矩阵 |
| `vcovHC()` | sandwich | vce(robust) | 异方差稳健方差矩阵 |
| `vcovJK()` | sandwich |  | 刀切法方差矩阵 |
| [`View()`](https://rdrr.io/r/utils/View.html) | utils | browse | 打开数据查看器 |
| `vif()` | car |  | 方差膨胀因子 |
| `waldtest()` | lmtest | test | 嵌套模型的 Wald 检验 |
| `walk()` | purrr | foreach | 为副作用（如保存文件）应用函数 |
| [`warning()`](https://rdrr.io/r/base/warning.html) | base | display as error | 发出警告 |
| `wday()` | lubridate |  | 星期几 |
| `week()` | lubridate | week() | 一年中的第几周 |
| [`weighted.mean()`](https://rdrr.io/r/stats/weighted.mean.html) | stats | summarize \[aweight = w\] | 加权平均 |
| `weightit()` | WeightIt |  | 平衡权重，如逆概率权重 |
| [`where()`](https://tidyselect.r-lib.org/reference/where.html) | dplyr | ds, has(type numeric) | 按类型选择列，如 where(is.numeric) |
| [`which()`](https://rdrr.io/r/base/which.html) | base | list if | 条件为 TRUE 的位置 |
| [`wilcox.test()`](https://rdrr.io/r/stats/wilcox.test.html) | stats |  | Wilcoxon 秩和检验或符号秩检验 |
| `winsorize()` | datawizard |  | 对极端值缩尾 |
| [`with()`](https://rdrr.io/r/base/with.html) | base |  | 在数据框的列中运行代码 |
| `word()` | stringr |  | 从句子中提取词 |
| `wrap_plots()` | patchwork |  | 组合多张图 |
| [`write.csv()`](https://rdrr.io/r/utils/write.table.html) | utils | export delimited | 写出 CSV 文件（base R） |
| `write_csv()` | readr |  | 写出 CSV 文件 |
| `write_dta()` | haven |  | 写出 Stata .dta 文件 |
| `write_sav()` | haven | savespss | 写出 SPSS 文件 |
| `write_xlsx()` | writexl |  | 写出 Excel 文件 |
| `xlim()` | ggplot2 | xscale(range()) | x 轴范围 |
| [`xtab()`](https://socimh.github.io/tidystata/reference/tab.md) | tidystata | tabulate | tab2() 的别名 |
| [`xtabs()`](https://rdrr.io/r/stats/xtabs.html) | stats | tabulate x1 x2 | 用公式生成交叉表 |
| [`xtile()`](https://socimh.github.io/tidystata/reference/cut.md) | tidystata |  | 按分位数分组，与 Stata 的 xtile 一致 |
| `yday()` | lubridate | doy() | 一年中的第几天 |
| `year()` | lubridate |  | 日期中的年份 |
| `yearmonth()` | tsibble |  | 月度时期 |
| `yearquarter()` | tsibble |  | 季度时期 |
| `years()` | lubridate | d + 365 | 以年为单位的时期，用于日期运算 |
| `ymd()` | lubridate |  | 把 2024-01-31 这样的文本解析为日期 |
| `ymd_hms()` | lubridate |  | 把文本解析为日期时间 |
| `zap_labels()` | haven |  | 去掉数值标签 |
| `zap_missing()` | haven | mvdecode | 把特殊缺失值改为 NA |
