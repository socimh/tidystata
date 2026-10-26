* Complete-case Pearson reference for corr(). Run from this directory, or
* pass the repository root as the first argument.
version 19
clear all
set more off
args root
if "`root'" == "" local root "../.."
local out "`root'/tests/testthat/fixtures/stata"
import delimited using "`out'/pwcorr-input.csv", clear asdouble
generate byte g = x > 5
generate double aw0 = fw
replace aw0 = 0 if x == 4
export delimited using "`out'/corr-input.csv", replace

tempfile reference
tempname post
postfile `post' str4 wt byte group str1 v1 str1 v2 double(rho n) ///
  using `reference', replace
foreach wt in none fw aw aw0 {
  local w = cond("`wt'" == "none", "", "[`wt'=fw]")
  if "`wt'" == "aw0" local w "[aw=aw0]"
  forvalues group = -1/1 {
    local sample = cond(`group' == -1, "", "if g == `group'")
    quietly correlate x y z `sample' `w'
    matrix C = r(C)
    scalar N = r(N)
    local names x y z
    forvalues i = 1/2 {
      local first = `i' + 1
      forvalues j = `first'/3 {
        post `post' ("`wt'") (`group') ///
          ("`: word `i' of `names''") ("`: word `j' of `names''") ///
          (C[`i', `j']) (N)
      }
    }
  }
}
postclose `post'
use `reference', clear
format rho n %21.0g
export delimited using "`out'/corr-output.csv", replace
