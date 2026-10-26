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


* isid() success/failure reference cases. Strings exported as empty fields
* represent Stata's empty-string missing value; keep spaces unchanged.
clear
input double id byte wave str4 code
1 1 "a"
1 2 "b"
2 1 ""
2 1 ""
. 2 "c"
3 1 " "
. 3 "d"
end
gen long row = _n
export delimited using "`out'/isid-input.csv", replace

capture program drop record_isid
program define record_isid
    args handle case rows keys missing
    preserve
    quietly keep if strpos(" `rows' ", " " + string(row) + " ")
    local option
    if `missing' local option ", missok"
    capture isid `keys' `option'
    local rc = _rc
    post `handle' ("`case'") ("`rows'") ("`keys'") (`missing') (`rc')
    restore
end

tempname checks
tempfile results
postfile `checks' str32 case str20 rows str20 keys byte missing int rc ///
    using "`results'", replace
record_isid `checks' unique_numeric "1 3 6" "id" 0
record_isid `checks' duplicate_numeric "1 2" "id" 0
record_isid `checks' missing_numeric "1 5" "id" 0
record_isid `checks' missing_numeric_allowed "1 5" "id" 1
record_isid `checks' duplicate_missing_numeric "5 7" "id" 1
record_isid `checks' composite "1 2 3 6" "id wave" 0
record_isid `checks' duplicate_composite "3 4" "id wave" 0
record_isid `checks' missing_composite_allowed "5 7" "id wave" 1
record_isid `checks' empty_string "1 3" "code" 0
record_isid `checks' empty_string_allowed "1 3" "code" 1
record_isid `checks' duplicate_empty_string "3 4" "code" 1
record_isid `checks' whitespace "1 6" "code" 0
postclose `checks'
use "`results'", clear
export delimited using "`out'/isid-output.csv", replace
