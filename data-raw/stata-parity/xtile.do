* Reference groups for xtile() and cut_breaks(). Run with `stata xtile.do`.
* xtile refuses more groups than observations plus one, so those stay missing.
version 19
clear all
set more off
local out "../../tests/testthat/fixtures/stata"

import delimited using "`out'/summ-input.csv", clear asdouble
gen long row = _n
foreach n in 2 3 4 5 10 {
  gen q`n' = .
  gen fq`n' = .
  gen aq`n' = .
  levelsof g, local(groups)
  foreach g of local groups {
    quietly {
      capture xtile t = x if g == `g', nquantiles(`n')
      capture replace q`n' = t if g == `g'
      capture drop t
      capture xtile t = x if g == `g' [fw=fw], nquantiles(`n')
      capture replace fq`n' = t if g == `g'
      capture drop t
      capture xtile t = x if g == `g' [aw=aw], nquantiles(`n')
      capture replace aq`n' = t if g == `g'
      capture drop t
    }
  }
}
export delimited row g x q* fq* aq* using "`out'/xtile-output.csv", replace

* egen cut(), at(): left-closed intervals [a, b); values outside the
* breaks are missing. icodes numbers the intervals from 0.
egen c_at = cut(x), at(-10 0 2.5 5 10 40)
egen c_ic = cut(x), at(-10 0 2.5 5 10 40) icodes
egen c_in = cut(x), at(0 2.5 5 10)
egen c_inic = cut(x), at(0 2.5 5 10) icodes
egen c_grp = cut(x), group(4)
egen c_grpic = cut(x), group(4) icodes
format x c_* %21.0g
export delimited row x c_* using "`out'/cut-output.csv", replace
