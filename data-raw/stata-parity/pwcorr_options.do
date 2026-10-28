* Reference values for pwcorr() options and spearman(): analytic weights,
* listwise deletion, Bonferroni and Sidak adjustment, and Spearman with
* casewise or pairwise deletion. Run from this directory, or pass the
* repository root as the first argument. Run pwcorr_tab.do first.
version 19
clear all
set more off
args root
if "`root'" == "" local root "../.."
local out "`root'/tests/testthat/fixtures/stata"
import delimited using "`out'/pwcorr-input.csv", clear asdouble

tempfile reference
tempname post
global post `post'
postfile `post' str16 cmd str4 wt str1 v1 str1 v2 double(rho p n) ///
  using `reference', replace

* Post the lower triangle of the stored rho, p-value and count matrices.
capture program drop record
program define record
  args cmd wt rmat pmat
  matrix R = r(`rmat')
  matrix S = r(`pmat')
  matrix N = r(Nobs)
  local names x y z
  forvalues i = 1/2 {
    local first = `i' + 1
    forvalues j = `first'/3 {
      post $post ("`cmd'") ("`wt'") ///
        ("`: word `i' of `names''") ("`: word `j' of `names''") ///
        (R[`j', `i']) (S[`j', `i']) (N[`j', `i'])
    }
  }
end

quietly pwcorr x y z [aw=fw], sig obs
record pwcorr aw C sig
quietly pwcorr x y z, sig obs listwise
record listwise none C sig
quietly pwcorr x y z [fw=fw], sig obs listwise
record listwise fw C sig
quietly pwcorr x y z, sig obs bonferroni
record bonferroni none C sig
quietly pwcorr x y z, sig obs sidak
record sidak none C sig
quietly spearman x y z, stats(rho obs p)
record spearman none Rho P
quietly spearman x y z, stats(rho obs p) pw
record spearman_pw none Rho P
quietly spearman x y z, stats(rho obs p) pw bonferroni
record spearman_pw_bon none Rho P
quietly spearman x y z, stats(rho obs p) sidak
record spearman_sidak none Rho P
postclose `post'
use `reference', clear
format rho p n %21.0g
export delimited using "`out'/pwcorr-options-output.csv", replace

* Spearman with ties, small groups (n = 3 uses the normal approximation) and
* a negative correlation.
clear
input a b g
1 2 1
2 2 1
3 1 1
1 4 2
2 3 2
2 1 2
4 1 2
5 9 3
3 7 3
3 7 3
1 8 3
2 6 3
end
export delimited using "`out'/spearman-ties-input.csv", replace
tempfile ties
postfile `post' byte group double(rho p n) using `ties', replace
forvalues group = 0/3 {
  local sample = cond(`group' == 0, "", "if g == `group'")
  quietly spearman a b `sample'
  post `post' (`group') (r(rho)) (r(p)) (r(N))
}
postclose `post'
use `ties', clear
format rho p n %21.0g
export delimited using "`out'/spearman-ties-output.csv", replace
