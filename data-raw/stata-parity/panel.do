* Reference values for stata_lag(), stata_lead() and stata_diff(). Run with
* `stata panel.do`. Each block writes its input and the L., F. and D. results.
version 19
clear all
set more off
local out "../../tests/testthat/fixtures/stata"

program define panel_ops
  syntax varname, out(string) [delta(integer 1)]
  xtset id `varlist', delta(`delta')
  gen l1 = L.x
  gen l2 = L2.x
  gen f1 = F.x
  gen f2 = F2.x
  gen d1 = D.x
  gen d2 = D2.x
  sort row
  format x l1-d2 %21.0g
  export delimited using "`out'", replace
end

* Annual panel with gaps, a missing year and a single-row panel.
clear
input id year x
1 2002 12
1 2001 10
1 2005 18
1 2004 15
2 2003 33
2 2001 31
2 2002 32
2 . 99
3 2001 40
4 2001 1
4 2002 .
4 2003 4
4 2004 9
end
gen long row = _n
panel_ops year, out("`out'/panel-annual.csv")

* Five-yearly data with delta(5).
clear
input id year x
1 2000 1
1 2005 3
1 2015 8
2 2000 2
2 2010 7
2 2005 4
end
gen long row = _n
panel_ops year, out("`out'/panel-delta5.csv") delta(5)

* Daily dates turned into %tw, %tm and %tq periods. The weekly dates cross
* year ends, where Stata's week 52 has 8 or 9 days.
clear
input id str10 day x
1 "2023-12-23" 1
1 "2023-12-30" 2
1 "2024-01-01" 3
1 "2024-01-08" 4
1 "2024-01-15" 6
1 "2024-02-29" 7
1 "2024-03-31" 8
2 "2024-12-22" 10
2 "2024-12-29" 11
2 "2025-01-05" 13
2 "2025-01-07" 14
2 "2025-04-01" 15
2 "2025-07-01" 17
end
gen long row = _n
tempfile days
save `days'
* Stata needs unique times within each panel, so each unit keeps the first
* row of a repeated period; the output lists the rows used.
foreach unit in w m q {
  use `days', clear
  gen t = `unit'ofd(daily(day, "YMD"))
  bysort id t (row): keep if _n == 1
  panel_ops t, out("`out'/panel-`unit'.csv")
}
