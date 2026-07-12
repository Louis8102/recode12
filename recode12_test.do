version 16.0
clear all
set more off
set varabbrev off
adopath ++ "."

clear
input byte(male white older21 numkids married varA varB theta phi psi omega)
1 2 1 0 1 1 2 1 1 1 1
2 1 . 3 2 1 2 2 . . .
1 2 2 . 1 1 2 3 2 2 4
. . . 0 1 1 2 . . . .
1 1 2 1 2 1 2 4 1 1 5
2 2 1 . 1 1 2 . 2 . 2
. 1 2 . 2 1 2 5 . . 3
2 . . 0 1 1 2 . . . .
end

label variable male "Respondent is female"
recode12, yesvalue(1)
assert r(n_recoded) == 6
assert `"`r(source)'"' == "male white older21 married phi psi"
assert `"`r(recoded)'"' == "male_01 white_01 older21_01 married_01 phi_01 psi_01"
assert male_01 == cond(missing(male), ., male == 1)
assert white_01 == cond(missing(white), ., white == 1)
assert older21_01 == cond(missing(older21), ., older21 == 1)
assert married_01 == cond(missing(married), ., married == 1)
assert male == 2 in 2
assert `"`: variable label male_01'"' == "Respondent is female"
assert `"`: value label male_01'"' == "recode12_NoYes"
assert r(yesvalue) == 1
assert r(verified) == 1

* user-selected reverse direction: source 2 becomes Yes/1
recode12 male, yesvalue(2) suffix(_rev)
assert male_rev == 0 if male == 1
assert male_rev == 1 if male == 2
assert missing(male_rev) if missing(male)
assert r(yesvalue) == 2
assert r(verified) == 1

drop *_01
replace male = .a in 4
recode12 male, yesvalue(1) suffix(_x)
assert male_x == .a in 4
assert male_x == 1 if male == 1
assert male_x == 0 if male == 2

capture noisily recode12 male, yesvalue(1) suffix(_x)
assert _rc == 110

recode12 male, yesvalue(1) replace
assert male == .a in 4
assert inlist(male, 0, 1) | missing(male)
assert `"`: value label male'"' == "recode12_NoYes"

* reverse direction also works with replace and preserves extended missing
clear
input byte x
1
2
.a
end
recode12 x, yesvalue(2) replace
assert x[1] == 0
assert x[2] == 1
assert x[3] == .a
assert r(yesvalue) == 2
assert r(verified) == 1

capture noisily recode12 x, yesvalue(3)
assert _rc == 198

clear
set obs 3
generate byte only1 = cond(_n == 3, ., 1)
generate byte only2 = cond(_n == 3, ., 2)
generate byte allmiss = .
generate byte bad = _n
recode12, yesvalue(1)
assert r(n_recoded) == 0
confirm variable only1
capture confirm variable only1_01
assert _rc == 111

* suffix() and replace are mutually exclusive
clear
input byte x
1
2
end
capture noisily recode12 x, yesvalue(1) suffix(_z) replace
assert _rc == 198
assert x[1] == 1 & x[2] == 2

* an incompatible shared label stops before changing data
label define recode12_NoYes 0 "False" 1 "True"
capture noisily recode12 x, yesvalue(1)
assert _rc == 110
capture confirm variable x_01
assert _rc == 111
assert x[1] == 1 & x[2] == 2

* an existing compatible shared label is accepted
label drop recode12_NoYes
label define recode12_NoYes 0 "No" 1 "Yes"
recode12 x, yesvalue(1)
assert x_01[1] == 1 & x_01[2] == 0

* string-only data are handled without error
clear
input str1 s
"a"
"b"
end
recode12, yesvalue(1)
assert r(n_recoded) == 0

* empty numeric data and different numeric storage types
clear
generate double x = .
recode12, yesvalue(1)
assert r(n_recoded) == 0
clear
input double x float y long z
1 1 1
2 2 2
.a .b .z
end
recode12, yesvalue(1)
assert r(n_recoded) == 3
assert x_01 == .a in 3
assert y_01 == .b in 3
assert z_01 == .z in 3

* all output-name conflicts are checked before any variable is generated
clear
input byte(a b)
1 2
2 1
end
generate byte b_01 = 42
capture noisily recode12 a b, yesvalue(1)
assert _rc == 110
capture confirm variable a_01
assert _rc == 111
assert b_01 == 42

di as result "recode12 tests passed"
