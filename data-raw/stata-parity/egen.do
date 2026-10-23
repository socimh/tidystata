* Reference values for row_*(), std(), pc() and is_first(). Run with
* `stata egen.do`.
version 19
clear all
set more off
local out "../../tests/testthat/fixtures/stata"

input g a b c d
1 1 2 3 4
1 -1.5 . 2.25 8
1 . . . .
2 5 5 5 .
2 . 3 . .
2 0 -2 7.5 .5
2 10 . 1 1
3 2 2 2 2
3 . . . 6
. 4 1 . 2
. 4 1 . 2
end
gen long row = _n
egen r_mean = rowmean(a b c d)
egen r_total = rowtotal(a b c d)
egen r_min = rowmin(a b c d)
egen r_max = rowmax(a b c d)
egen r_median = rowmedian(a b c d)
egen r_sd = rowsd(a b c d)
egen r_miss = rowmiss(a b c d)
egen r_nonmiss = rownonmiss(a b c d)
egen s_std = std(a)
egen s_std_m = std(a), mean(50) std(10)
egen s_pc = pc(d)
egen s_prop = pc(d), prop
bysort g (row): egen b_std = std(a)
bysort g (row): egen b_pc = pc(d)
sort row
egen t_tag = tag(g)
egen t_tag_m = tag(g), missing
egen t_tag_ab = tag(a b)
format a-t_tag_ab %21.0g
export delimited using "`out'/egen-output.csv", replace
