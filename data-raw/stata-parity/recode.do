* Reference codes for recode(). Run with `stata recode.do`.
* Inputs are exact binary fractions. r8 uses `missing`, which matches every
* missing value; recode() writes this as NA ~ code. Labels are exported as
* decoded text.
version 19
clear all
set more off
local out "../../tests/testthat/fixtures/stata"

input double x
-3
0
1
1.5
2
3
4.5
5
5.5
6
7
9
10
10.5
12
.
end
gen long row = _n

recode x (1/5 = 1) (6/10 = 2), generate(r1)
recode x (1/5 = 1) (6/10 = 2) (else = .), generate(r2)
recode x (min/5 = 0) (6/max = 1) (missing = 9), generate(r3)
recode x (1 = 2) (2 = 1), generate(r4)
recode x (1/5 = 1) (3 = 2), generate(r5)
recode x (1 3 7 = 0), generate(r6)
recode x (9 = .), generate(r7)
recode x (missing = 0), generate(r8)
recode x (1 3/5 = 1) (-3 0 = 0), generate(r9)
recode x (min/5 = 1 "Low") (6/max = 2 "High"), generate(r10)
decode r10, generate(r10_label)
format x r1-r10 %21.0g
export delimited row x r1-r10 r10_label using "`out'/recode-output.csv", nolabel replace
