version 16.0
clear all
set more off

findfile example_data.dta
use `"`r(fn)'"', clear

describe
recode12
return list
tab1 female female_01, missing

* Variables containing only one category or another valid value are skipped.
confirm variable only_yes
capture confirm variable only_yes_01
assert _rc == 111
capture confirm variable invalid_01
assert _rc == 111
