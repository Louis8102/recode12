version 16.0
clear all
set more off
set varabbrev off

findfile example_data.dta
use `"`r(fn)'"', clear

describe
assert _N == 10000
recode12, yesvalue(2)
assert r(n_recoded) == 22
return list
tab1 female female_01, missing

* Reverse direction: source value 2 becomes Yes/1.
recode12 female, yesvalue(2) suffix(_male)
assert female_male == 1 if female == 2
assert female_male == 0 if female == 1
assert item01_01 == 0 if item01 == 1
assert item01_01 == 1 if item01 == 2
assert item20_01 == 0 if item20 == 1
assert item20_01 == 1 if item20 == 2
capture confirm variable white_01
assert _rc == 111
capture confirm variable older21_01
assert _rc == 111
capture confirm variable married_01
assert _rc == 111
capture confirm variable insured_01
assert _rc == 111

* Variables containing only one category or another valid value are skipped.
confirm variable only_yes
capture confirm variable only_yes_01
assert _rc == 111
capture confirm variable only_no_01
assert _rc == 111
capture confirm variable contains_zero_01
assert _rc == 111
capture confirm variable contains_three_01
assert _rc == 111
