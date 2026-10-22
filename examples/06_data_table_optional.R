# Optional: run this script only if you want to test data.table inputs.
# install.packages("data.table")
library(tidystata)
library(data.table)

dt <- data.table(group = c("A", "A", "B"), x = c(1, 3, 5))
dt
class(tab(dt, group)) # data.table, data.frame
class(summ(dt, x))
class(codebook(dt))
class(variables(dt))
class(tab1(dt, group)$group)
class(fre(dt, group, .type = "tibble")) # Explicit tibble output.

# Wrapping creates an independent copy.
wrapped <- preview_table(dt, n = 2)
wrapped[, x := x * 2]
wrapped
dt # Original x remains 1, 3, 5.

# Native data.table selection, grouping, and external-variable lookup.
wrapped[, .(total = sum(x)), by = group]
cutoff <- 3
wrapped[x > cutoff]
columns <- "x"
wrapped[, ..columns]

# A native reference assignment result is an alias of the wrapped table.
alias <- wrapped[, x := x + 1]
alias[, x := 99]
wrapped # x is now 99 in both objects.

# Removing the preview creates another independent copy.
plain <- unpreview_table(wrapped)
plain[, x := 0]
plain
wrapped # x is still 99.
