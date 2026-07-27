* recode12 1.2.5 integrated entity-data regression test
* Parent dataset: recode12_example_data.dta
* Required ado:     recode12_v1_2_5.ado
*
* This test keeps the original 10,000-observation dataset intact in memory,
* adds fault-injection variables, runs recode12 in one batch, and verifies:
*   1. variables that must be recoded;
*   2. variables that must be skipped;
*   3. final mappings;
*   4. preservation of ordinary missing values;
*   5. observation-order invariance for directed strings;
*   6. matching-key and protected-key behavior.
*
* Put all three files in the same folder and run:
*     do "test_recode12_entity_data_v1_2_5.do"

confirm file "recode12_example_data.dta"
confirm file "recode12_v1_2_5.ado"

do "recode12_v1_2_5.ado"
use "recode12_example_data.dta", clear

assert _N == 10000

*============================================================*
* A. Add fault-injection variables to the original dataset
*============================================================*

*------------------------------------------------------------*
* A1. String-coded numeric 1/2: order, whitespace, NFKC
*------------------------------------------------------------*
g str12 fx_str12_order = cond(mod(_n, 2), "2", "1")
replace fx_str12_order = "." if mod(_n, 101) == 0
replace fx_str12_order = ""  if mod(_n, 137) == 0

g str12 fx_str12_space = cond(mod(_n, 2), " 1 ", " 2 ")
replace fx_str12_space = "." if mod(_n, 103) == 0

g str12 fx_str12_nfkc = cond(mod(_n, 2), "１", "２")
replace fx_str12_nfkc = " １ " if mod(_n, 11) == 0
replace fx_str12_nfkc = " ２ " if mod(_n, 13) == 0
replace fx_str12_nfkc = "." if mod(_n, 107) == 0

*------------------------------------------------------------*
* A2. English directed strings: order, case, separators, NFKC
*------------------------------------------------------------*
g str40 fx_pass_fail = cond(mod(_n, 2), "Fail", "Pass")
replace fx_pass_fail = "." if mod(_n, 109) == 0

g str40 fx_pass_fail_case = cond(mod(_n, 4) == 0, "PASS", ///
    cond(mod(_n, 4) == 1, "fail", ///
    cond(mod(_n, 4) == 2, "Pass", "FAIL")))
replace fx_pass_fail_case = "" if mod(_n, 113) == 0

g str40 fx_pass_fail_punct = cond(mod(_n, 4) == 0, "P-a_s.s", ///
    cond(mod(_n, 4) == 1, "f-a_i.l", ///
    cond(mod(_n, 4) == 2, " P a s s ", " F a i l ")))
replace fx_pass_fail_punct = "." if mod(_n, 127) == 0

g str40 fx_pass_fail_nfkc = cond(mod(_n, 2), "Ｆａｉｌ", "Ｐａｓｓ")
replace fx_pass_fail_nfkc = "." if mod(_n, 131) == 0

*------------------------------------------------------------*
* A3. Equivalent spellings collapse to two normalized keys
*------------------------------------------------------------*
g str50 fx_eligibility_forms = ""
replace fx_eligibility_forms = "Eligible" if mod(_n, 5) == 0
replace fx_eligibility_forms = "No eligibility" if mod(_n, 5) == 1
replace fx_eligibility_forms = "no-eligibility" if mod(_n, 5) == 2
replace fx_eligibility_forms = "no_eligibility" if mod(_n, 5) == 3
replace fx_eligibility_forms = "n o e l i g i b i l i t y" if mod(_n, 5) == 4
replace fx_eligibility_forms = "." if mod(_n, 139) == 0

* Minor spelling error intended for conservative fuzzy matching
g str40 fx_eligibility_typo = cond(mod(_n, 2), "noeligiblity", "Eligible")
replace fx_eligibility_typo = "." if mod(_n, 149) == 0

*------------------------------------------------------------*
* A4. Additional English directed pairs
*------------------------------------------------------------*
g str30 fx_present_absent = cond(mod(_n, 2), "Absent", "Present")
g str30 fx_crime_nocrime = cond(mod(_n, 2), "No crime", "Crime")
g str30 fx_employed_unemployed = cond(mod(_n, 2), "Unemployed", "Employed")
g str30 fx_yes_no = cond(mod(_n, 2), "No", "Yes")
g str30 fx_positive_negative = cond(mod(_n, 2), "Negative", "Positive")

*------------------------------------------------------------*
* A5. Chinese directed pairs and normalized spacing
*------------------------------------------------------------*
g str30 fx_zh_pass = cond(mod(_n, 2), "不通过", "通过")
g str30 fx_zh_pass_space = cond(mod(_n, 2), "不 通 过", "通 过")
g str30 fx_zh_attend = cond(mod(_n, 2), "未出勤", "出勤")
g str30 fx_zh_have = cond(mod(_n, 2), "无", "有")
g str30 fx_zh_exist = cond(mod(_n, 2), "不存在", "存在")
g str30 fx_zh_occur = cond(mod(_n, 2), "未发生", "发生")
g str30 fx_zh_vaccine = cond(mod(_n, 2), "未接种", "接种")
g str30 fx_zh_detected = cond(mod(_n, 2), "未检出", "检出")

*------------------------------------------------------------*
* A6. Unordered pairs: must retain first-appearance behavior
*------------------------------------------------------------*
g str30 fx_fruit_order = cond(mod(_n, 2), "Peach", "Plum")
replace fx_fruit_order = "." if mod(_n, 151) == 0

g str30 fx_gender_unordered = cond(mod(_n, 2), "Female", "Male")
g str30 fx_region_unordered = cond(mod(_n, 2), "Urban", "Rural")

*------------------------------------------------------------*
* A7. Variables that MUST be skipped
*------------------------------------------------------------*

* One normalized category only
g str30 fx_one_key = cond(mod(_n, 3) == 0, "PASS", ///
    cond(mod(_n, 3) == 1, "Pass", "P-a_s.s"))

* Three normalized text categories
g str30 fx_three_keys = cond(mod(_n, 3) == 0, "Pass", ///
    cond(mod(_n, 3) == 1, "Fail", "Unknown"))

* Protected-key extended missing forms
g str20 fx_dot_a = cond(mod(_n, 2), "Pass", "Fail")
replace fx_dot_a = ".a" if _n == 1

g str20 fx_dot_A = cond(mod(_n, 2), "Pass", "Fail")
replace fx_dot_A = ".A" if _n == 1

g str20 fx_dot_space_a = cond(mod(_n, 2), "Pass", "Fail")
replace fx_dot_space_a = ". a" if _n == 1

g str20 fx_fullwidth_dot_A = cond(mod(_n, 2), "Pass", "Fail")
replace fx_fullwidth_dot_A = "．Ａ" if _n == 1

* Other numeric strings
g str20 fx_str_1_3 = cond(mod(_n, 2), "1", "3")
g str20 fx_str_1_decimal = cond(mod(_n, 2), "1", "1.0")
g str20 fx_str_1_negative = cond(mod(_n, 2), "1", "-1")
g str20 fx_str_1_scientific = cond(mod(_n, 2), "1", "2e0")

* Mixed numeric and text strings
g str20 fx_mixed_1_pass = cond(mod(_n, 2), "1", "Pass")

* Numeric variables with prohibited values
g byte fx_num_ext_a = cond(mod(_n, 2), 1, 2)
replace fx_num_ext_a = .a in 1

g byte fx_num_zero = cond(mod(_n, 2), 1, 2)
replace fx_num_zero = 0 in 1

g byte fx_num_three = cond(mod(_n, 2), 1, 2)
replace fx_num_three = 3 in 1

*============================================================*
* B. Define expected eligibility sets
*============================================================*

loc must_recode ///
    fx_str12_order fx_str12_space fx_str12_nfkc ///
    fx_pass_fail fx_pass_fail_case fx_pass_fail_punct fx_pass_fail_nfkc ///
    fx_eligibility_forms fx_eligibility_typo ///
    fx_present_absent fx_crime_nocrime fx_employed_unemployed ///
    fx_yes_no fx_positive_negative ///
    fx_zh_pass fx_zh_pass_space fx_zh_attend fx_zh_have ///
    fx_zh_exist fx_zh_occur fx_zh_vaccine fx_zh_detected ///
    fx_fruit_order fx_gender_unordered fx_region_unordered

loc must_skip ///
    fx_one_key fx_three_keys ///
    fx_dot_a fx_dot_A fx_dot_space_a fx_fullwidth_dot_A ///
    fx_str_1_3 fx_str_1_decimal fx_str_1_negative fx_str_1_scientific ///
    fx_mixed_1_pass ///
    fx_num_ext_a fx_num_zero fx_num_three

*============================================================*
* C. Run one integrated batch recode
*============================================================*

recode12 `must_recode' `must_skip', yesvalue(2) suffix(_r)

loc got_recoded `"`r(recoded)'"'
loc got_skipped `"`r(skipped)'"'

* Every expected eligible variable must be recoded.
foreach v of loc must_recode {
    cap confirm variable `v'_r
    if _rc {
        di as err "FAILED: expected result variable `v'_r was not generated"
        exit 9
    }

    if strpos(" `got_recoded' ", " `v'_r ") == 0 {
        di as err "FAILED: `v'_r is absent from r(recoded)"
        exit 9
    }
}

* Every expected invalid variable must be skipped.
foreach v of loc must_skip {
    cap confirm variable `v'_r
    if !_rc {
        di as err "FAILED: ineligible variable `v' generated `v'_r"
        exit 9
    }

    if strpos(" `got_skipped' ", " `v' ") == 0 {
        di as err "FAILED: `v' is absent from r(skipped)"
        exit 9
    }
}

*============================================================*
* D. Verify final mappings
*============================================================*

* String-coded numeric
assert fx_str12_order_r == 0 if ustrtrim(fx_str12_order) == "1"
assert fx_str12_order_r == 1 if ustrtrim(fx_str12_order) == "2"
assert missing(fx_str12_order_r) if inlist(ustrtrim(fx_str12_order), "", ".")

assert fx_str12_space_r == 0 if ustrtrim(fx_str12_space) == "1"
assert fx_str12_space_r == 1 if ustrtrim(fx_str12_space) == "2"
assert missing(fx_str12_space_r) if inlist(ustrtrim(fx_str12_space), "", ".")

g str12 __nfkc_digit = ustrregexra( ///
    ustrlower(ustrnormalize(ustrtrim(fx_str12_nfkc), "nfkc")), ///
    "[^\p{L}\p{N}]+", "")
assert fx_str12_nfkc_r == 0 if __nfkc_digit == "1"
assert fx_str12_nfkc_r == 1 if __nfkc_digit == "2"
assert missing(fx_str12_nfkc_r) if inlist(ustrtrim(fx_str12_nfkc), "", ".")
drop __nfkc_digit

* English directed strings
assert fx_pass_fail_r == 1 if fx_pass_fail == "Pass"
assert fx_pass_fail_r == 0 if fx_pass_fail == "Fail"
assert missing(fx_pass_fail_r) if inlist(fx_pass_fail, "", ".")

g str40 __key = ustrregexra( ///
    ustrlower(ustrnormalize(ustrtrim(fx_pass_fail_case), "nfkc")), ///
    "[^\p{L}\p{N}]+", "")
assert fx_pass_fail_case_r == 1 if __key == "pass"
assert fx_pass_fail_case_r == 0 if __key == "fail"
drop __key

g str40 __key = ustrregexra( ///
    ustrlower(ustrnormalize(ustrtrim(fx_pass_fail_punct), "nfkc")), ///
    "[^\p{L}\p{N}]+", "")
assert fx_pass_fail_punct_r == 1 if __key == "pass"
assert fx_pass_fail_punct_r == 0 if __key == "fail"
drop __key

g str40 __key = ustrregexra( ///
    ustrlower(ustrnormalize(ustrtrim(fx_pass_fail_nfkc), "nfkc")), ///
    "[^\p{L}\p{N}]+", "")
assert fx_pass_fail_nfkc_r == 1 if __key == "pass"
assert fx_pass_fail_nfkc_r == 0 if __key == "fail"
drop __key

* Equivalent eligibility forms
g str50 __key = ustrregexra( ///
    ustrlower(ustrnormalize(ustrtrim(fx_eligibility_forms), "nfkc")), ///
    "[^\p{L}\p{N}]+", "")
assert fx_eligibility_forms_r == 1 if __key == "eligible"
assert fx_eligibility_forms_r == 0 if __key == "noeligibility"
assert missing(fx_eligibility_forms_r) if inlist(ustrtrim(fx_eligibility_forms), "", ".")
drop __key

assert fx_eligibility_typo_r == 1 if fx_eligibility_typo == "Eligible"
assert fx_eligibility_typo_r == 0 if fx_eligibility_typo == "noeligiblity"
assert missing(fx_eligibility_typo_r) if fx_eligibility_typo == "."

* Additional English directed pairs
assert fx_present_absent_r == 1 if fx_present_absent == "Present"
assert fx_present_absent_r == 0 if fx_present_absent == "Absent"

assert fx_crime_nocrime_r == 1 if fx_crime_nocrime == "Crime"
assert fx_crime_nocrime_r == 0 if fx_crime_nocrime == "No crime"

assert fx_employed_unemployed_r == 1 if fx_employed_unemployed == "Employed"
assert fx_employed_unemployed_r == 0 if fx_employed_unemployed == "Unemployed"

assert fx_yes_no_r == 1 if fx_yes_no == "Yes"
assert fx_yes_no_r == 0 if fx_yes_no == "No"

assert fx_positive_negative_r == 1 if fx_positive_negative == "Positive"
assert fx_positive_negative_r == 0 if fx_positive_negative == "Negative"

* Chinese directed pairs
assert fx_zh_pass_r == 1 if fx_zh_pass == "通过"
assert fx_zh_pass_r == 0 if fx_zh_pass == "不通过"

g str30 __key = ustrregexra( ///
    ustrlower(ustrnormalize(ustrtrim(fx_zh_pass_space), "nfkc")), ///
    "[^\p{L}\p{N}]+", "")
assert fx_zh_pass_space_r == 1 if __key == "通过"
assert fx_zh_pass_space_r == 0 if __key == "不通过"
drop __key

assert fx_zh_attend_r == 1 if fx_zh_attend == "出勤"
assert fx_zh_attend_r == 0 if fx_zh_attend == "未出勤"

assert fx_zh_have_r == 1 if fx_zh_have == "有"
assert fx_zh_have_r == 0 if fx_zh_have == "无"

assert fx_zh_exist_r == 1 if fx_zh_exist == "存在"
assert fx_zh_exist_r == 0 if fx_zh_exist == "不存在"

assert fx_zh_occur_r == 1 if fx_zh_occur == "发生"
assert fx_zh_occur_r == 0 if fx_zh_occur == "未发生"

assert fx_zh_vaccine_r == 1 if fx_zh_vaccine == "接种"
assert fx_zh_vaccine_r == 0 if fx_zh_vaccine == "未接种"

assert fx_zh_detected_r == 1 if fx_zh_detected == "检出"
assert fx_zh_detected_r == 0 if fx_zh_detected == "未检出"

* Unordered variables: first observation determines source category 1.
* Observation 1 is Peach/Female/Urban, so yesvalue(2) gives those 0.
assert fx_fruit_order_r == 0 if fx_fruit_order == "Peach"
assert fx_fruit_order_r == 1 if fx_fruit_order == "Plum"
assert missing(fx_fruit_order_r) if fx_fruit_order == "."

assert fx_gender_unordered_r == 0 if fx_gender_unordered == "Female"
assert fx_gender_unordered_r == 1 if fx_gender_unordered == "Male"

assert fx_region_unordered_r == 0 if fx_region_unordered == "Urban"
assert fx_region_unordered_r == 1 if fx_region_unordered == "Rural"

*============================================================*
* E. Confirm original parent data remain present
*============================================================*

assert _N == 10000
confirm variable id
confirm variable female
confirm variable exam_result_text
confirm variable contains_ext_m
confirm variable contains_ext_n

di as result _newline ///
    "ALL INTEGRATED ENTITY-DATA RECODE12 TESTS PASSED"
