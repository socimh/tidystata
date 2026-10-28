# 从 Stata 到 R

[English
version](https://socimh.github.io/tidystata/articles/coming-from-stata.md)

本指南并列展示 Stata 命令与对应的 R 代码，并说明两者的差异。

## 浏览章节

选择下方主题，或通过 Stata 和 R 索引查找。

[Stata
索引](https://socimh.github.io/tidystata/articles/stata-zh-command-index.md)
· [R
函数索引](https://socimh.github.io/tidystata/articles/stata-zh-r-index.md)

- [基础功能](https://socimh.github.io/tidystata/articles/stata-zh-basics.md)
- [贝叶斯分析](https://socimh.github.io/tidystata/articles/stata-zh-bayesian-analysis.md)
- [因果推断](https://socimh.github.io/tidystata/articles/stata-zh-causal-inference.md)
- [检查数据](https://socimh.github.io/tidystata/articles/stata-zh-check-data.md)
- [合并数据](https://socimh.github.io/tidystata/articles/stata-zh-combine-data.md)
- [复杂抽样分析](https://socimh.github.io/tidystata/articles/stata-zh-complex-survey-analysis.md)
- [构造和修改变量
  (1/2)](https://socimh.github.io/tidystata/articles/stata-zh-construct-and-modify-variables.md)
- [构造和修改变量
  (2/2)](https://socimh.github.io/tidystata/articles/stata-zh-construct-and-modify-variables-2.md)
- [构造数据](https://socimh.github.io/tidystata/articles/stata-zh-construct-data.md)
- [数据管理
  (1/6)](https://socimh.github.io/tidystata/articles/stata-zh-data-management.md)
- [数据管理
  (2/6)](https://socimh.github.io/tidystata/articles/stata-zh-data-management-2.md)
- [数据管理
  (3/6)](https://socimh.github.io/tidystata/articles/stata-zh-data-management-3.md)
- [数据管理
  (4/6)](https://socimh.github.io/tidystata/articles/stata-zh-data-management-4.md)
- [数据管理
  (5/6)](https://socimh.github.io/tidystata/articles/stata-zh-data-management-5.md)
- [数据管理
  (6/6)](https://socimh.github.io/tidystata/articles/stata-zh-data-management-6.md)
- [描述性表格
  (1/2)](https://socimh.github.io/tidystata/articles/stata-zh-descriptive-tables.md)
- [描述性表格
  (2/2)](https://socimh.github.io/tidystata/articles/stata-zh-descriptive-tables-2.md)
- [流行病学](https://socimh.github.io/tidystata/articles/stata-zh-epidemiology.md)
- [探索数据
  (1/2)](https://socimh.github.io/tidystata/articles/stata-zh-explore-data.md)
- [探索数据
  (2/2)](https://socimh.github.io/tidystata/articles/stata-zh-explore-data-2.md)
- [文件与导入导出](https://socimh.github.io/tidystata/articles/stata-zh-files-and-import-export.md)
- [作图
  (1/2)](https://socimh.github.io/tidystata/articles/stata-zh-graphs.md)
- [作图
  (2/2)](https://socimh.github.io/tidystata/articles/stata-zh-graphs-2.md)
- [假设检验与置信区间](https://socimh.github.io/tidystata/articles/stata-zh-hypothesis-tests-and-confidence-intervals.md)
- [变量和数值标签](https://socimh.github.io/tidystata/articles/stata-zh-labels.md)
- [标签与元数据](https://socimh.github.io/tidystata/articles/stata-zh-labels-and-metadata.md)
- [循环和编程](https://socimh.github.io/tidystata/articles/stata-zh-loops-and-programming.md)
- [元分析](https://socimh.github.io/tidystata/articles/stata-zh-meta-analysis.md)
- [模型报告](https://socimh.github.io/tidystata/articles/stata-zh-model-reporting.md)
- [模型与估计
  (1/2)](https://socimh.github.io/tidystata/articles/stata-zh-models-and-estimation.md)
- [模型与估计
  (2/2)](https://socimh.github.io/tidystata/articles/stata-zh-models-and-estimation-2.md)
- [模型和结果表](https://socimh.github.io/tidystata/articles/stata-zh-models-and-tables.md)
- [模型与检验](https://socimh.github.io/tidystata/articles/stata-zh-models-and-tests.md)
- [多层模型](https://socimh.github.io/tidystata/articles/stata-zh-multilevel-models.md)
- [多重插补](https://socimh.github.io/tidystata/articles/stata-zh-multiple-imputation.md)
- [多变量与心理测量方法
  (1/2)](https://socimh.github.io/tidystata/articles/stata-zh-multivariate-and-psychometric-methods.md)
- [多变量与心理测量方法
  (2/2)](https://socimh.github.io/tidystata/articles/stata-zh-multivariate-and-psychometric-methods-2.md)
- [面板和时间序列](https://socimh.github.io/tidystata/articles/stata-zh-panel-and-time-series.md)
- [面板数据](https://socimh.github.io/tidystata/articles/stata-zh-panel-data.md)
- [估计后分析与诊断](https://socimh.github.io/tidystata/articles/stata-zh-postestimation-and-diagnostics.md)
- [检验功效与精度设计](https://socimh.github.io/tidystata/articles/stata-zh-power-and-precision-planning.md)
- [编程工具](https://socimh.github.io/tidystata/articles/stata-zh-programming-utilities.md)
- [重抽样与模拟](https://socimh.github.io/tidystata/articles/stata-zh-resampling-and-simulation.md)
- [转换长、宽数据](https://socimh.github.io/tidystata/articles/stata-zh-reshape.md)
- [筛选变量或个案](https://socimh.github.io/tidystata/articles/stata-zh-select-variables-and-rows.md)
- [排列变量或个案](https://socimh.github.io/tidystata/articles/stata-zh-sort.md)
- [空间分析流程](https://socimh.github.io/tidystata/articles/stata-zh-spatial-workflows.md)
- [统计分布
  (1/2)](https://socimh.github.io/tidystata/articles/stata-zh-statistical-distributions.md)
- [统计分布
  (2/2)](https://socimh.github.io/tidystata/articles/stata-zh-statistical-distributions-2.md)
- [字符串与日期
  (1/2)](https://socimh.github.io/tidystata/articles/stata-zh-strings-and-dates.md)
- [字符串与日期
  (2/2)](https://socimh.github.io/tidystata/articles/stata-zh-strings-and-dates-2.md)
- [调查数据](https://socimh.github.io/tidystata/articles/stata-zh-survey-data.md)
- [生存分析](https://socimh.github.io/tidystata/articles/stata-zh-survival-analysis.md)
- [时间序列与预测](https://socimh.github.io/tidystata/articles/stata-zh-time-series-and-forecasting.md)

## 在 R 中直接查询

加载 tidystata 后，用
[`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
查询同一份目录。单个命令可不加引号，
较长语法需要引号；也可以传入自己的变量名：

``` r

findit(reg)
findit("merge 1:1 id, keep(match)")
findit(tab, sex, region)
```

也支持 R 函数及中英文问题。追加 `|> print(n = Inf)`
可查看返回的全部示例、 注释与来源。完整用法见
[`findit()`](https://socimh.github.io/tidystata/reference/findit.md)。

## 改写示例

请将示例变量名替换为自己的变量。`data` 表示数据集，`data1` 和 `data2`
表示合并时的两份数据，`fit` 表示已拟合的模型。

R
标签注明主要使用的包。未加包名前缀的函数需要先加载相应包；许多数据准备示例
使用
[`library(dplyr)`](https://dplyr.tidyverse.org)。[`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
本身不会加载或安装这些包。

## 关于注释

**与 Stata 有差异**
表示默认设置、缺失值处理、估计方法或输出形式存在差异，
具体差异见注释。其余注释是使用提示。

执行核验检查 R 代码本身，并不证明结果与 Stata
数值一致。改写示例前，请核对
缺失值、权重、因子参照组、连接规则和标准误设置。搜索结果也不代表支持命令的全部选项。
