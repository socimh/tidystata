# 从这里开始

本手册帮助 Stata 用户找到熟悉操作的 R 实现。内容围绕 **tidystata** 展开，
也收录 base R 及其他 R 包中的常用方法。这是一份查阅手册，系统学习请参阅另行编写的教材。

目录包含 **{{command_families}} 个命令类别**和 **{{example_count}} 个 Stata–R 配对示例**。
全部 {{lookup_keys}} 个查询词还包括 Stata 函数、运算符及前缀。
R 索引介绍 {{r_functions}} 个函数与包的组合。缩写和不同 R 实现不重复计入命令类别数。

## 查找所需操作

- 点击页首的**命令对照**，在左侧按主题浏览各章。
- 已知 Stata 命令时，查看 [Stata 索引](stata-index.qmd)。
- 按 R 包查找函数时，查看 [R 索引](r-index.qmd)。
- 搜索命令、R 函数或任务说明；需要更多选项或其他 R 实现时，展开后续示例。

每章都有 **English** 切换按钮，点击后前往英文版的对应章节。
从示例链接进入时，切换语言也会保留当前示例的位置。

## 在 R 中查询

```r
library(tidystata)
findit(tab)
findit(tab, sex, region)
findit("merge 1:1 id, keep(match)")
findit(dplyr::left_join)
findit("how do I remove duplicate rows")
findit(tab) |> print(n = Inf)
```

`findit()` 与本手册使用同一份目录。查询含义明确时，控制台优先展示一个示例，
展开后可查看其余用法。查询本身不会加载或安装结果中提到的 R 包。

## 如何改写示例

`data` 表示数据集，`x`、`y`、`g`、`id` 和 `time` 是示意列名；
`data1` 和 `data2` 表示两个数据集，`fit` 表示已经拟合的模型。
部分代码需要先完成任务描述或适用条件中说明的准备步骤，不能直接当作完整分析运行。

`package::function()` 明确标出了函数所属的包。代码下方只注明主要实现包；
辅助函数可能使用函数索引中列出的其他包。未带命名空间的调用须按需先加载相应包。

## 关于注释 {#example-labels}

标有 **与 Stata 有差异** 的注释表示 R 代码完成相同任务，但默认设置、缺失值处理、
估计方法或输出形式有所不同，注释会说明具体差异。其余注释是使用提示。
多数 R 示例在构建目录时运行核验，检查的是 R 代码本身，并非与 Stata 的数值一致性检验。
比较结果时，请特别留意缺失值、权重、参照类别和标准误。

## 继续学习

函数帮助见 [tidystata 文档](https://socimh.github.io/tidystata/)，
较系统的学习材料见[沈明宏的个人网站](https://www.socimh.com/)及其[书籍页面](https://www.socimh.com/books.html)。
若发现缺失或不准确的对照，请在[项目问题页面](https://github.com/socimh/tidystata/issues)反馈。
