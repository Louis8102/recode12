version 19.5
clear
set more off

use example_data.dta, clear

* Source 1 means Yes for female.
recode12 female, yesvalue(1)

* Source 2 means Yes for these No/Yes propositions.
recode12 employed owns_home uses_smartphone, yesvalue(2)

list id female female_01 employed employed_01 owns_home owns_home_01 ///
    uses_smartphone uses_smartphone_01 in 1/10, separator(0)

return list
