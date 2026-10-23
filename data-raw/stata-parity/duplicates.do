* Reference values for duplicates_tag(); duplicates_report() and
* duplicates_drop() follow from the same copy counts. Run with
* `stata duplicates.do`. Missing values are equal to each other, as in Stata.
version 19
clear all
set more off
local out "../../tests/testthat/fixtures/stata"

input a b
1 1
1 1
1 2
2 .
2 .
. .
3 1
1 1
end
gen long row = _n
duplicates tag a b, generate(dup)
duplicates tag a, generate(dup_a)
export delimited using "`out'/duplicates-tag.csv", replace

