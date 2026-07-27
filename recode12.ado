*! version 1.3.0  27jul2026

cap mata: mata drop recode12_levenshtein()
cap mata: mata drop recode12_fuzzy_match()

mata:
real scalar recode12_levenshtein(string scalar a, string scalar b)
{
    real scalar i, j, m, n, cost
    real matrix d

    m = strlen(a)
    n = strlen(b)

    if (m == 0) return(n)
    if (n == 0) return(m)

    d = J(m + 1, n + 1, 0)
    for (i = 1; i <= m + 1; i++) d[i, 1] = i - 1
    for (j = 1; j <= n + 1; j++) d[1, j] = j - 1

    for (i = 2; i <= m + 1; i++) {
        for (j = 2; j <= n + 1; j++) {
            cost = (substr(a, i - 1, 1) == substr(b, j - 1, 1) ? 0 : 1)
            d[i, j] = min((d[i - 1, j] + 1, ///
                           d[i, j - 1] + 1, ///
                           d[i - 1, j - 1] + cost))
        }
    }

    return(d[m + 1, n + 1])
}

void recode12_fuzzy_match()
{
    string scalar key1, key2
    string rowvector affirmative, negative
    real scalar i, limit1, limit2
    real scalar a1, a2, b1, b2, score
    real scalar bestscore, bestcount, best_affcat, best_negcat
    real scalar best_d1, best_d2
    string scalar best_aff, best_neg

    key1 = st_local("key1")
    key2 = st_local("key2")

    affirmative = ("yes", "true", "positive", "present", "pass", "passed", ///
        "passedexam", "completedtraining", "attended", "attendance", ///
        "eligible", "eligible", "eligibility", "approved", "accepted", ///
        "complete", "completed", "employed", "active", "crime", "criminal")

    negative = ("no", "false", "negative", "absent", "fail", "failed", ///
        "didnotpassexam", "didnotcompletetraining", "notattended", ///
        "nonattendance", "ineligible", "noeligibility", "ineligibility", ///
        "denied", "rejected", "incomplete", "incomplete", "unemployed", ///
        "inactive", "nocrime", "noncriminal")

    limit1 = (strlen(key1) <= 3 ? 0 : (strlen(key1) <= 10 ? 1 : 2))
    limit2 = (strlen(key2) <= 3 ? 0 : (strlen(key2) <= 10 ? 1 : 2))

    bestscore = .
    bestcount = 0
    best_affcat = .
    best_negcat = .
    best_aff = ""
    best_neg = ""
    best_d1 = .
    best_d2 = .

    for (i = 1; i <= cols(affirmative); i++) {
        a1 = recode12_levenshtein(key1, affirmative[i])
        a2 = recode12_levenshtein(key2, negative[i])
        b1 = recode12_levenshtein(key1, negative[i])
        b2 = recode12_levenshtein(key2, affirmative[i])

        if (a1 <= limit1 & a2 <= limit2) {
            score = a1 + a2
            if (missing(bestscore) | score < bestscore) {
                bestscore = score
                bestcount = 1
                best_affcat = 1
                best_negcat = 2
                best_aff = affirmative[i]
                best_neg = negative[i]
                best_d1 = a1
                best_d2 = a2
            }
            else if (score == bestscore) {
                bestcount = bestcount + 1
            }
        }

        if (b1 <= limit1 & b2 <= limit2) {
            score = b1 + b2
            if (missing(bestscore) | score < bestscore) {
                bestscore = score
                bestcount = 1
                best_affcat = 2
                best_negcat = 1
                best_aff = affirmative[i]
                best_neg = negative[i]
                best_d1 = b1
                best_d2 = b2
            }
            else if (score == bestscore) {
                bestcount = bestcount + 1
            }
        }
    }

    if (bestcount == 1 & !missing(bestscore)) {
        st_local("fm_classified", "1")
        st_local("fm_affirmative_category", strofreal(best_affcat))
        st_local("fm_negative_category", strofreal(best_negcat))
        st_local("fm_affirmative", best_aff)
        st_local("fm_negative", best_neg)
        st_local("fm_d1", strofreal(best_d1))
        st_local("fm_d2", strofreal(best_d2))
    }
    else {
        st_local("fm_classified", "0")
        st_local("fm_affirmative_category", ".")
        st_local("fm_negative_category", ".")
        st_local("fm_affirmative", "")
        st_local("fm_negative", "")
        st_local("fm_d1", ".")
        st_local("fm_d2", ".")
    }
}
end

program define _recode12_normkey, rclass
version 19.5
syntax , TEXT(string asis)

loc key = ustrlower(ustrnormalize(ustrtrim(`"`text'"'), "nfkc"))
loc key = ustrregexra(`"`key'"', "[^\p{L}\p{N}]+", "")

return local key `"`key'"'
end

program define _recode12_classify_pair, rclass
version 19.5
syntax , CAT1(string asis) CAT2(string asis)

_recode12_normkey, text(`"`cat1'"')
loc key1 `"`r(key)'"'

_recode12_normkey, text(`"`cat2'"')
loc key2 `"`r(key)'"'

loc pairs_en ///
    yes|no true|false positive|negative present|absent pass|fail passed|failed passedexam|didnotpassexam completedtraining|didnotcompletetraining ///
    attended|notattended attendance|nonattendance eligible|ineligible ///
    eligible|noeligibility eligibility|ineligibility ///
    approved|denied accepted|rejected complete|incomplete completed|incomplete ///
    employed|unemployed active|inactive crime|nocrime criminal|noncriminal

loc pairs_zh ///
    是|否 有|无 存在|不存在 发生|未发生 已发生|未发生 ///
    通过|不通过 通过|未通过 合格|不合格 及格|不及格 达标|未达标 ///
    出勤|缺勤 出勤|未出勤 参加|未参加 参与|未参与 到场|未到场 ///
    完成|未完成 成功|失败 成功|未成功 符合|不符合 符合|未符合 ///
    满足|不满足 获得|未获得 拥有|未拥有 持有|未持有 ///
    就业|未就业 已就业|未就业 在职|失业 工作|未工作 ///
    阳性|阴性 感染|未感染 患病|未患病 确诊|未确诊 ///
    治疗|未治疗 接种|未接种 住院|未住院 使用|未使用 暴露|未暴露 ///
    检出|未检出 犯罪|不犯罪 犯罪|无犯罪 违规|未违规 违法|未违法 ///
    复发|未复发 批准|拒绝 同意|不同意 接受|不接受 支持|不支持

loc pairs `pairs_en' `pairs_zh'

loc classified = 0
loc affirmative_category = .
loc negative_category = .
loc method ""
loc matched_affirmative ""
loc matched_negative ""
loc distance1 = .
loc distance2 = .

foreach pair of local pairs {
    loc split = strpos(`"`pair'"', "|")
    loc affirmative = substr(`"`pair'"', 1, `split' - 1)
    loc negative = substr(`"`pair'"', `split' + 1, .)

    if `"`key1'"' == `"`affirmative'"' & `"`key2'"' == `"`negative'"' {
        loc classified = 1
        loc affirmative_category = 1
        loc negative_category = 2
        loc method "normalized exact match"
        loc matched_affirmative `"`affirmative'"'
        loc matched_negative `"`negative'"'
        loc distance1 = 0
        loc distance2 = 0
        continue, break
    }

    if `"`key1'"' == `"`negative'"' & `"`key2'"' == `"`affirmative'"' {
        loc classified = 1
        loc affirmative_category = 2
        loc negative_category = 1
        loc method "normalized exact match"
        loc matched_affirmative `"`affirmative'"'
        loc matched_negative `"`negative'"'
        loc distance1 = 0
        loc distance2 = 0
        continue, break
    }
}

if !`classified' {
    loc ascii1 = ustrregexm(`"`key1'"', "^[a-z0-9]+$")
    loc ascii2 = ustrregexm(`"`key2'"', "^[a-z0-9]+$")

    if `ascii1' & `ascii2' {
        loc fm_classified 0
        loc fm_affirmative_category .
        loc fm_negative_category .
        loc fm_affirmative ""
        loc fm_negative ""
        loc fm_d1 .
        loc fm_d2 .

        mata: recode12_fuzzy_match()

        if `fm_classified' {
            loc classified = 1
            loc affirmative_category = `fm_affirmative_category'
            loc negative_category = `fm_negative_category'
            loc method "conservative fuzzy match"
            loc matched_affirmative `"`fm_affirmative'"'
            loc matched_negative `"`fm_negative'"'
            loc distance1 = `fm_d1'
            loc distance2 = `fm_d2'
        }
    }
}

return scalar classified = `classified'
return scalar affirmative_category = `affirmative_category'
return scalar negative_category = `negative_category'
return scalar distance1 = `distance1'
return scalar distance2 = `distance2'
return local key1 `"`key1'"'
return local key2 `"`key2'"'
return local method `"`method'"'
return local matched_affirmative `"`matched_affirmative'"'
return local matched_negative `"`matched_negative'"'
end

program define recode12, rclass
version 19.5
syntax [varlist(default=none)] [, YESValue(string) SUFfix(name) REPlace DISPlay]

if `"`yesvalue'"' == "" {
    di as err "yesvalue() is required; specify yesvalue(1) or yesvalue(2)"
    exit 198
}
if !inlist(`"`yesvalue'"', "1", "2") {
    di as err "yesvalue() must be 1 or 2"
    exit 198
}

loc suffix_given = (`"`suffix'"' != "")
if `"`replace'"' != "" & `suffix_given' {
    di as err "suffix() may not be combined with replace"
    exit 198
}
if `"`suffix'"' == "" local suffix "_01"

if `"`varlist'"' == "" {
    unab varlist : _all
}
if `"`varlist'"' == "" {
    di as txt "no variables found"
    return local skipped ""
    return local source ""
    return local numeric_source ""
    return local string_source ""
    return local numeric_recoded ""
    return local string_recoded ""
    return local recoded ""
    return local value_label ""
    return local status_variable ""
    return scalar yesvalue = `yesvalue'
    return scalar verified = 0
    return scalar n_numeric_recoded = 0
    return scalar n_string_recoded = 0
    return scalar n_recoded = 0
    exit
}

loc eligible
loc numeric_eligible
loc string_eligible
loc skipped

qui foreach v of local varlist {
    cap confirm numeric variable `v'
    if !_rc {
        count if !inlist(`v', 1, 2, .)
        loc bad = r(N)
        count if `v' == 1
        loc n1 = r(N)
        count if `v' == 2
        loc n2 = r(N)

        if `bad' == 0 & `n1' > 0 & `n2' > 0 {
            loc eligible `eligible' `v'
            loc numeric_eligible `numeric_eligible' `v'
        }
        else local skipped `skipped' `v'
    }
    else {
        tempvar normalized matchkey protectedkey sourcecode obsno
        g strL `normalized' = ustrtrim(`v')
        g strL `protectedkey' = ustrregexra( ///
            ustrlower(ustrnormalize(`normalized', "nfkc")), ///
            "[\p{Z}\s]+", "")
        g strL `matchkey' = ustrregexra( ///
            ustrlower(ustrnormalize(`normalized', "nfkc")), ///
            "[^\p{L}\p{N}]+", "")
        g long `obsno' = _n

        count if ustrregexm(`protectedkey', "^\.[a-z]$")
        if r(N) > 0 {
            loc skipped `skipped' `v'
            continue
        }

        count if !inlist(`normalized', "", ".") & ///
            ustrregexm(`normalized', "^[+-]?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))([eE][+-]?[0-9]+)?$")
        loc n_numeric_strings = r(N)

        if `n_numeric_strings' > 0 {
            count if !inlist(`normalized', "", ".")
            loc n_nonmissing_strings = r(N)
            count if `matchkey' == "1" & !inlist(`normalized', "", ".")
            loc n_string1 = r(N)
            count if `matchkey' == "2" & !inlist(`normalized', "", ".")
            loc n_string2 = r(N)

            if `n_numeric_strings' != `n_nonmissing_strings' | ///
                `n_string1' == 0 | `n_string2' == 0 | ///
                (`n_string1' + `n_string2') != `n_nonmissing_strings' {
                loc skipped `skipped' `v'
                continue
            }
        }

        su `obsno' if !inlist(`normalized', "", "."), meanonly
        if r(N) == 0 {
            loc skipped `skipped' `v'
            continue
        }

        loc first1 = r(min)
        loc firstkey1 = `matchkey'[`first1']
        g byte `sourcecode' = .
        replace `sourcecode' = 1 if ///
            `matchkey' == `"`firstkey1'"' & ///
            !inlist(`normalized', "", ".")

        su `obsno' if !inlist(`normalized', "", ".") & ///
            missing(`sourcecode'), meanonly
        if r(N) == 0 {
            loc skipped `skipped' `v'
            continue
        }

        loc first2 = r(min)
        loc firstkey2 = `matchkey'[`first2']
        replace `sourcecode' = 2 if ///
            `matchkey' == `"`firstkey2'"' & ///
            !inlist(`normalized', "", ".")

        count if !inlist(`normalized', "", ".") & missing(`sourcecode')
        if r(N) == 0 {
            loc eligible `eligible' `v'
            loc string_eligible `string_eligible' `v'

            loc normalized_`v' `normalized'
            loc protectedkey_`v' `protectedkey'
            loc key_`v' `matchkey'
            loc sourcecode_`v' `sourcecode'
            loc obsno_`v' `obsno'
            loc first1_`v' = `first1'
            loc first2_`v' = `first2'
            loc key1_`v' `"`firstkey1'"'
            loc key2_`v' `"`firstkey2'"'
            loc cat1_`v' = `normalized'[`first1']
            loc cat2_`v' = `normalized'[`first2']
        }
        else local skipped `skipped' `v'
    }
}

if `"`eligible'"' == "" {
    di as txt "no variables met the two-category coding rule"
    return local skipped `"`skipped'"'
    return local source ""
    return local numeric_source ""
    return local string_source ""
    return local numeric_recoded ""
    return local string_recoded ""
    return local recoded ""
    return local value_label ""
    return local status_variable ""
    return scalar yesvalue = `yesvalue'
    return scalar verified = 0
    return scalar n_numeric_recoded = 0
    return scalar n_string_recoded = 0
    return scalar n_recoded = 0
    exit
}

loc statusvar "recode12_status"
cap confirm variable `statusvar'
if !_rc {
    loc statuslabel : variable label `statusvar'
    loc statustype : type `statusvar'

    if substr("`statustype'", 1, 3) != "str" | ///
        !inlist(`"`statuslabel'"', "recode12 verification status", ///
            "recode12 Verification Status") {
        di as err "variable `statusvar' already exists and was not created by recode12"
        exit 110
    }

    if "`statustype'" != "strL" {
        loc statuswidth = real(substr("`statustype'", 4, .))
        if `statuswidth' < 9 recast str9 `statusvar'
    }
}

if `"`replace'"' == "" {
    foreach v of local eligible {
        loc new `v'`suffix'
        confirm new variable `new'
    }
}

loc vallab "recode12_NoYes"
cap qui label list `vallab'
if _rc label define `vallab' 0 "No" 1 "Yes"
else {
    loc lab0 : label `vallab' 0
    loc lab1 : label `vallab' 1

    if `"`lab0'"' != "No" | `"`lab1'"' != "Yes" {
        di as err "value label `vallab' already exists with incompatible definitions"
        exit 110
    }
}

if `"`numeric_eligible'"' != "" & `"`display'"' != "" {
    if `yesvalue' == 1 {
        di as txt "numeric mapping rule: source value 1 -> 1 (Yes); source value 2 -> 0 (No)"
    }
    else {
        di as txt "numeric mapping rule: source value 1 -> 0 (No); source value 2 -> 1 (Yes)"
    }
}

loc recoded
loc numeric_recoded
loc string_recoded

foreach v of local eligible {
    loc source_label : variable label `v'
    if `"`source_label'"' == "" loc source_label "`v'"

    cap confirm numeric variable `v'

    if !_rc {
        loc source_vallab : value label `v'
        loc cat1
        loc cat2

        if `"`source_vallab'"' != "" {
            loc cat1 : label `source_vallab' 1
            loc cat2 : label `source_vallab' 2
        }

        loc target
        if `"`source_vallab'"' != "" {
            if `yesvalue' == 1 local target `"`cat1'"'
            else local target `"`cat2'"'
        }
        if `"`target'"' == "" local target "`v' == `yesvalue'"

        loc target : subinstr local target `"' "'", all
        loc newvl `"Recoded `target' (0=No; 1=Yes)"'
        loc newvl = ustrleft(`"`newvl'"', 80)

        if `"`replace'"' != "" {
            tempvar original
            qui clonevar `original' = `v'
            qui replace `v' = (`original' == `yesvalue') if !missing(`original')
            label values `v' `vallab'
            label variable `v' `"`newvl'"'

            qui assert `v' == (`original' == `yesvalue') if !missing(`original')
            qui assert missing(`v') if missing(`original')
            qui assert inlist(`v', 0, 1) | missing(`v')

            loc recoded `recoded' `v'
            loc numeric_recoded `numeric_recoded' `v'
        }
        else {
            loc new `v'`suffix'
            qui g byte `new' = (`v' == `yesvalue') if !missing(`v')
            label variable `new' `"`newvl'"'
            label values `new' `vallab'

            qui assert `new' == (`v' == `yesvalue') if !missing(`v')
            qui assert missing(`new') if missing(`v')
            qui assert inlist(`new', 0, 1) | missing(`new')

            loc recoded `recoded' `new'
            loc numeric_recoded `numeric_recoded' `new'
        }
    }
    else {
        loc normalized ``normalized_`v''
        loc protectedkey ``protectedkey_`v''
        loc key ``key_`v''
        loc sourcecode ``sourcecode_`v''
        loc obsno ``obsno_`v''
        loc first1 = ``first1_`v''
        loc first2 = ``first2_`v''
        loc cat1 `"``cat1_`v''"'
        loc cat2 `"``cat2_`v''"'
        loc key1 `"``key1_`v''"'
        loc key2 `"``key2_`v''"'

        qui assert !ustrregexm(`protectedkey', "^\.[a-z]$")

        loc classification "unordered string"
        loc method "first nonmissing appearance"
        loc affirmative_category = .
        loc negative_category = .
        loc matched_affirmative ""
        loc matched_negative ""
        loc distance1 = .
        loc distance2 = .

        qui replace `sourcecode' = .

        if inlist(`"`key1'"', "1", "2") & ///
            inlist(`"`key2'"', "1", "2") & ///
            `"`key1'"' != `"`key2'"' {

            loc classification "string-coded numeric binary"
            loc method "numeric-equivalent string coding"

            qui replace `sourcecode' = 1 if ///
                `key' == "1" & !inlist(`normalized', "", ".")

            qui replace `sourcecode' = 2 if ///
                `key' == "2" & !inlist(`normalized', "", ".")

            loc target

            * Extract the semantic meaning of source codes 1 and 2
            * from the source variable label whenever available.
            *
            * Examples supported:
            *   (1=Uninsured; 2=Insured)
            *   (1 = No Access, 2 = Has Access)
            *   (1=No/2=Yes)
            loc code1_label
            loc code2_label

            if ustrregexm(`"`source_label'"', ///
                "\([^()]*1\s*=\s*([^;,/\)]+)\s*[;,/]\s*2\s*=\s*([^\)]+)\)") {
                loc code1_label = ustrtrim(ustrregexs(1))
                loc code2_label = ustrtrim(ustrregexs(2))
            }
            else if ustrregexm(`"`source_label'"', ///
                "1\s*=\s*([^;,/]+)\s*[;,/]\s*2\s*=\s*(.+)$") {
                loc code1_label = ustrtrim(ustrregexs(1))
                loc code2_label = ustrtrim(ustrregexs(2))
            }

            if `yesvalue' == 1 & `"`code1_label'"' != "" {
                loc target `"`code1_label'"'
            }
            else if `yesvalue' == 2 & `"`code2_label'"' != "" {
                loc target `"`code2_label'"'
            }
            else {
                loc target "`yesvalue'"
            }

            if `"`display'"' != "" {
                di as txt "`v': storage type = string; classification = string-coded numeric binary"
                if `yesvalue' == 1 {
                    di as txt `"  string "1" -> source 1 -> 1 (Yes); string "2" -> source 2 -> 0 (No)"'
                }
                else {
                    di as txt `"  string "1" -> source 1 -> 0 (No); string "2" -> source 2 -> 1 (Yes)"'
                }
                di as txt "  mapping basis: `method'; yesvalue(`yesvalue')"
            }
        }
        else {
            _recode12_classify_pair, cat1(`"`cat1'"') cat2(`"`cat2'"')

            loc classified = r(classified)
            loc affirmative_category = r(affirmative_category)
            loc negative_category = r(negative_category)
            loc method `"`r(method)'"'
            loc matched_affirmative `"`r(matched_affirmative)'"'
            loc matched_negative `"`r(matched_negative)'"'
            loc distance1 = r(distance1)
            loc distance2 = r(distance2)

            if `classified' {
                loc classification "directed string"

                if `affirmative_category' == 1 {
                    loc affirmative_value `"`cat1'"'
                    loc negative_value `"`cat2'"'
                }
                else {
                    loc affirmative_value `"`cat2'"'
                    loc negative_value `"`cat1'"'
                }

                if `yesvalue' == 2 {
                    loc affirmative_key = cond(`affirmative_category' == 1, `"`key1'"', `"`key2'"')
                    loc negative_key = cond(`negative_category' == 1, `"`key1'"', `"`key2'"')

                    qui replace `sourcecode' = 2 if ///
                        `key' == `"`affirmative_key'"' & ///
                        !inlist(`normalized', "", ".")

                    qui replace `sourcecode' = 1 if ///
                        `key' == `"`negative_key'"' & ///
                        !inlist(`normalized', "", ".")
                }
                else {
                    loc affirmative_key = cond(`affirmative_category' == 1, `"`key1'"', `"`key2'"')
                    loc negative_key = cond(`negative_category' == 1, `"`key1'"', `"`key2'"')

                    qui replace `sourcecode' = 1 if ///
                        `key' == `"`affirmative_key'"' & ///
                        !inlist(`normalized', "", ".")

                    qui replace `sourcecode' = 2 if ///
                        `key' == `"`negative_key'"' & ///
                        !inlist(`normalized', "", ".")
                }

                loc target `"`affirmative_value'"'

                if `"`display'"' != "" {
                    di as txt "`v': storage type = string; classification = directed string"
                    if `yesvalue' == 2 {
                        di as txt `"  negative category: `negative_value' -> source 1 -> 0 (No)"'
                        di as txt `"  affirmative category: `affirmative_value' -> source 2 -> 1 (Yes)"'
                    }
                    else {
                        di as txt `"  affirmative category: `affirmative_value' -> source 1 -> 1 (Yes)"'
                        di as txt `"  negative category: `negative_value' -> source 2 -> 0 (No)"'
                    }

                    di as txt "  normalized keys: `key1' / `key2'"
                    di as txt "  mapping basis: `method'; yesvalue(`yesvalue')"

                    if `"`method'"' == "conservative fuzzy match" {
                        di as txt "  matched canonical pair: `matched_affirmative' / `matched_negative'"
                        di as txt "  edit distances by observed category: `distance1' / `distance2'"
                    }
                }
            }
            else {
                qui replace `sourcecode' = 1 if ///
                    `key' == `"`key1'"' & ///
                    !inlist(`normalized', "", ".")

                qui replace `sourcecode' = 2 if ///
                    `key' == `"`key2'"' & ///
                    !inlist(`normalized', "", ".")

                if `yesvalue' == 1 local target `"`cat1'"'
                else local target `"`cat2'"'

                if `"`display'"' != "" {
                    di as txt "`v': storage type = string; classification = unordered string"
                    if `yesvalue' == 1 {
                        di as txt `"  source category 1: `cat1' -> 1 (Yes)"'
                        di as txt `"  source category 2: `cat2' -> 0 (No)"'
                    }
                    else {
                        di as txt `"  source category 1: `cat1' -> 0 (No)"'
                        di as txt `"  source category 2: `cat2' -> 1 (Yes)"'
                    }
                    di as txt "  mapping basis: first nonmissing appearance; yesvalue(`yesvalue')"
                }
            }
        }

        qui count if !inlist(`normalized', "", ".") & missing(`sourcecode')
        qui assert r(N) == 0

        loc target : subinstr local target `"' "'", all
        loc newvl `"Recoded `target' (0=No; 1=Yes)"'
        loc newvl = ustrleft(`"`newvl'"', 80)

        if `"`replace'"' != "" {
            tempvar newvalue
            qui g byte `newvalue' = ///
                (`sourcecode' == `yesvalue') if !missing(`sourcecode')

            qui order `newvalue', before(`v')
            qui drop `v'
            qui rename `newvalue' `v'

            label variable `v' `"`newvl'"'
            label values `v' `vallab'

            qui assert `v' == (`sourcecode' == `yesvalue') if !missing(`sourcecode')
            qui assert missing(`v') if missing(`sourcecode')
            qui assert inlist(`v', 0, 1) | missing(`v')

            loc recoded `recoded' `v'
            loc string_recoded `string_recoded' `v'
        }
        else {
            loc new `v'`suffix'
            qui g byte `new' = ///
                (`sourcecode' == `yesvalue') if !missing(`sourcecode')

            label variable `new' `"`newvl'"'
            label values `new' `vallab'

            qui assert `new' == (`sourcecode' == `yesvalue') if !missing(`sourcecode')
            qui assert missing(`new') if missing(`sourcecode')
            qui assert inlist(`new', 0, 1) | missing(`new')

            loc recoded `recoded' `new'
            loc string_recoded `string_recoded' `new'
        }
    }
}

cap confirm variable `statusvar'
if _rc g str9 `statusvar' = "confirmed"
else qui replace `statusvar' = "confirmed"
label variable `statusvar' "recode12 Verification Status"

loc n_recoded : word count `recoded'
loc n_numeric_recoded : word count `numeric_recoded'
loc n_string_recoded : word count `string_recoded'

if `"`display'"' != "" {
    di as txt "number of numeric variables standardized: " ///
        as result `n_numeric_recoded'

    if `n_numeric_recoded' > 0 {
        di as txt "names of numeric variables standardized:"
        loc detail_line
        loc detail_count = 0
        loc detail_width = max(20, c(linesize) - 4)

        foreach name of local numeric_recoded {
            loc candidate = strtrim("`detail_line' `name'")
            loc candidate_length = strlen("`candidate'")

            if `detail_count' > 0 & ///
                (`detail_count' >= 7 | `candidate_length' > `detail_width') {
                di as result "    `detail_line'"
                loc detail_line "`name'"
                loc detail_count = 1
            }
            else {
                loc detail_line "`candidate'"
                loc ++detail_count
            }
        }
        if `"`detail_line'"' != "" di as result "    `detail_line'"
    }
    else di as txt "names of numeric variables standardized: " as result "none"

    di as txt "number of string variables standardized: " ///
        as result `n_string_recoded'

    if `n_string_recoded' > 0 {
        di as txt "names of string variables standardized:"
        loc detail_line
        loc detail_count = 0
        loc detail_width = max(20, c(linesize) - 4)

        foreach name of local string_recoded {
            loc candidate = strtrim("`detail_line' `name'")
            loc candidate_length = strlen("`candidate'")

            if `detail_count' > 0 & ///
                (`detail_count' >= 7 | `candidate_length' > `detail_width') {
                di as result "    `detail_line'"
                loc detail_line "`name'"
                loc detail_count = 1
            }
            else {
                loc detail_line "`candidate'"
                loc ++detail_count
            }
        }
        if `"`detail_line'"' != "" di as result "    `detail_line'"
    }
    else di as txt "names of string variables standardized: " as result "none"
}

if `"`display'"' != "" {
    di as txt "verification passed: all recoded values match the selected mapping rule"
}

return local value_label "`vallab'"
return local status_variable "`statusvar'"
return scalar yesvalue = `yesvalue'
return scalar verified = 1
return local skipped `"`skipped'"'
return local source `"`eligible'"'
return local numeric_source `"`numeric_eligible'"'
return local string_source `"`string_eligible'"'
return local numeric_recoded `"`numeric_recoded'"'
return local string_recoded `"`string_recoded'"'
return local recoded `"`recoded'"'
return scalar n_numeric_recoded = `n_numeric_recoded'
return scalar n_string_recoded = `n_string_recoded'
return scalar n_recoded = `n_recoded'
end
