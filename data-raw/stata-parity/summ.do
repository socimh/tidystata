* Reference values for summ(), tabstat() and the percentile rule they share
* with xtile(). Run with `stata summ.do` from this folder; see README.md.
version 19
clear all
set more off
local out "../../tests/testthat/fixtures/stata"

* Inputs are exact binary fractions, so the CSV carries them without rounding.
* g 1-2: 1..4 and 1..10 (n*p hits whole numbers); g 3: ties and a missing
* value; g 4: 20 irregular values with negatives; g 5: one value; g 6:
* a constant; g 7: skewed values.
input g x fw aw
1 1 1 1
1 2 2 .5
1 3 1 1.5
1 4 3 2
2 1 1 .25
2 2 1 .5
2 3 2 .75
2 4 1 1
2 5 1 1.25
2 6 3 1.5
2 7 1 1.75
2 8 1 2
2 9 2 2.25
2 10 1 2.5
3 3 1 1
3 1 2 1
3 4 1 2
3 1 1 2
3 5 1 1
3 9 2 .5
3 2 1 .5
3 . 1 1
4 -3.5 1 .5
4 12.25 2 1
4 0 1 1.5
4 7.75 1 2
4 -1 3 .5
4 2.5 1 1
4 2.5 1 1.5
4 19 1 2
4 -8.125 2 .5
4 4 1 1
4 6.5 1 1.5
4 6.5 2 2
4 1 1 .5
4 33 1 1
4 -0.5 1 1.5
4 5 2 2
4 10 1 .5
4 3.25 1 1
4 8 4 1.5
4 -2 1 2
5 7 3 2
6 5 1 1
6 5 2 2
6 5 1 3
7 1 1 1
7 1 1 1
7 1 2 1
7 2 1 1
7 2 1 1
7 3 1 1
7 5 1 1
7 8 1 1
7 13 1 1
7 40 1 1
end
format x fw aw %21.0g
export delimited g x fw aw using "`out'/summ-input.csv", replace

tempname post
tempfile results
postfile `post' g str4 wt double(N sum_w mean sd var skewness kurtosis min ///
  max sum p1 p5 p10 p25 p50 p75 p90 p95 p99 p2_5 p30 p33 p66_6) ///
  using `results'
levelsof g, local(groups)
foreach g of local groups {
  foreach wt in none fw aw {
    local w = cond("`wt'" == "none", "", "[`wt'=`wt']")
    quietly summarize x if g == `g' `w', detail
    * Scalars keep full double precision until the next command.
    local stats
    foreach s in N sum_w mean sd Var skewness kurtosis min max sum ///
      p1 p5 p10 p25 p50 p75 p90 p95 p99 {
      scalar s_`s' = r(`s')
      local stats `stats' (s_`s')
    }
    quietly _pctile x if g == `g' `w', p(2.5 30 33 66.6)
    post `post' (`g') ("`wt'") `stats' (r(r1)) (r(r2)) (r(r3)) (r(r4))
  }
}
postclose `post'
use `results', clear
format N-p66_6 %21.0g
export delimited using "`out'/summ-output.csv", replace
