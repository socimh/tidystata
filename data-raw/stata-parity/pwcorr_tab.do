* Reference values for pwcorr(), tab() percentages and tab2() chi2. Run with
* `stata pwcorr_tab.do`.
version 19
clear all
set more off
local out "../../tests/testthat/fixtures/stata"

input x y z fw r c
1 2.5 . 1 1 1
2 3 1 2 1 2
3 2 4 1 2 1
4 6.5 2 3 2 2
5 5 8 1 1 1
6 . 3 2 3 2
7 9.25 9 1 3 1
8 7 5 4 2 2
9 10 . 1 1 2
10 8.5 7 2 . 1
end
export delimited using "`out'/pwcorr-input.csv", replace

tempname post
postfile `post' str1 v1 str1 v2 str4 wt double(rho p n) ///
  using "`out'/pwcorr-output.dta", replace
foreach wt in none fw {
  local w = cond("`wt'" == "none", "", "[fw=fw]")
  quietly pwcorr x y z `w', sig obs
  matrix C = r(C)
  matrix S = r(sig)
  matrix N = r(Nobs)
  local names x y z
  forvalues i = 1/3 {
    forvalues j = 1/3 {
      post `post' ("`: word `i' of `names''") ("`: word `j' of `names''") ///
        ("`wt'") (C[`i', `j']) (S[`i', `j']) (N[`i', `j'])
    }
  }
}
postclose `post'
use "`out'/pwcorr-output.dta", clear
format rho p n %21.0g
export delimited using "`out'/pwcorr-output.csv", replace
erase "`out'/pwcorr-output.dta"

* tab2 r c, chi2 V (missing rows excluded, as tabulate does by default).
import delimited using "`out'/pwcorr-input.csv", clear asdouble
tempname chi
postfile `chi' str4 wt double(N chi2 p cramers_v) ///
  using "`out'/tab-chi2.dta", replace
foreach wt in none fw {
  local w = cond("`wt'" == "none", "", "[fw=fw]")
  quietly tabulate r c `w', chi2 V
  post `chi' ("`wt'") (r(N)) (r(chi2)) (r(p)) (r(CramersV))
}
postclose `chi'
use "`out'/tab-chi2.dta", clear
format N chi2 p cramers_v %21.0g
export delimited using "`out'/tab-chi2.csv", replace
erase "`out'/tab-chi2.dta"
