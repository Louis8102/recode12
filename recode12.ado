*! version 1.4.2-numlabel-permanent  28jul2026

cap mata: mata drop recode12_levenshtein()

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
    yes|no true|false positive|negative present|absent pass|fail passed|failed ///
    passedexam|didnotpassexam completedtraining|didnotcompletetraining ///
    enrolled|notenrolled infected|notinfected ///
    attended|notattended attendance|nonattendance eligible|ineligible ///
    eligible|noeligibility eligible|noeligiblity ///
    eligibility|ineligibility ///
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


program define _recode12_name_semantics, rclass
version 19.5
syntax , SOURCE(name)

loc source_key = ustrlower(ustrnormalize(ustrtrim("`source'"), "nfkc"))
loc source_key = ustrregexra("`source_key'", "[^\p{L}\p{N}]+", "")

loc generic = 0
if ustrregexm("`source_key'", ///
    "^(v|var|x|item|column|col|q|field|note|notes|code)[0-9]*$") {
    loc generic = 1
}

return scalar generic = `generic'
return scalar meaningful = !`generic'
return local key "`source_key'"
end

program define _recode12_text_semantics, rclass
version 19.5
syntax , TEXT(string asis)

loc key = ustrlower(ustrnormalize(ustrtrim(`"`text'"'), "nfkc"))
loc key = ustrregexra(`"`key'"', "[^\p{L}\p{N}]+", "")

loc generic = 0
if `"`key'"' == "" {
    loc generic = 1
}
else if ustrregexm(`"`key'"', ///
    "^(status|response|responsecategory|classification|classificationcode|group|level|note|notes|field|administrativefield|category|categories|type|code|option|answer|result|variable|item|measure|indicator|unknown|unspecified)$") {
    loc generic = 1
}

return scalar generic = `generic'
return scalar meaningful = !`generic'
return local key `"`key'"'
end

program define _recode12_value_pair_semantics, rclass
version 19.5
syntax , LABEL1(string asis) LABEL2(string asis)

_recode12_text_semantics, text(`"`label1'"')
loc key1 `"`r(key)'"'
loc meaningful1 = r(meaningful)

_recode12_text_semantics, text(`"`label2'"')
loc key2 `"`r(key)'"'
loc meaningful2 = r(meaningful)

loc opaque = 0
if inlist(`"`key1'"', "1", "2") & inlist(`"`key2'"', "1", "2") {
    loc opaque = 1
}
else if ustrregexm(`"`key1'"', "^(type|code|category|group|class|level|option)[12abxy]$") & ///
        ustrregexm(`"`key2'"', "^(type|code|category|group|class|level|option)[12abxy]$") {
    loc opaque = 1
}
else if ustrregexm(`"`key1'"', "^[abxy]$") & ustrregexm(`"`key2'"', "^[abxy]$") {
    loc opaque = 1
}

return scalar meaningful = (`meaningful1' & `meaningful2' & !`opaque')
return scalar opaque = `opaque'
return local key1 `"`key1'"'
return local key2 `"`key2'"'
end

program define _recode12_opaque_categories, rclass
version 19.5
syntax , KEY1(string asis) KEY2(string asis)

loc opaque = 0

if inlist("`key1'", "1", "2") & inlist("`key2'", "1", "2") {
    loc opaque = 1
}
else if ustrregexm("`key1'", "^[abxy]$") & ///
        ustrregexm("`key2'", "^[abxy]$") {
    loc opaque = 1
}
else if ustrregexm("`key1'", "^(category|group|class|level|option)[12abxy]$") & ///
        ustrregexm("`key2'", "^(category|group|class|level|option)[12abxy]$") {
    loc opaque = 1
}

return scalar opaque = `opaque'
end

program define _recode12_generated_name, rclass
version 19.5
syntax , SOURCE(name) SUFfix(name) [REServed(string asis)]

loc requested "`source'`suffix'"
loc candidate "`requested'"
loc shortened = 0

if strlen("`candidate'") > 32 {
    loc shortened = 1
    loc base "`source'"

    * Deterministic semantic abbreviations; order is deliberate.
    loc base : subinstr local base "professional" "prof", all
    loc base : subinstr local base "qualification" "qual", all
    loc base : subinstr local base "certificate" "cert", all
    loc base : subinstr local base "accreditation" "accred", all
    loc base : subinstr local base "performance" "perf", all
    loc base : subinstr local base "evaluation" "eval", all
    loc base : subinstr local base "eligibility" "elig", all
    loc base : subinstr local base "enrollment" "enroll", all
    loc base : subinstr local base "training" "train", all
    loc base : subinstr local base "assistance" "assist", all
    loc base : subinstr local base "military" "mil", all
    loc base : subinstr local base "service" "svc", all
    loc base : subinstr local base "primary" "prim", all
    loc base : subinstr local base "course" "crs", all
    loc base : subinstr local base "result" "rslt", all

    loc maxbase = 32 - strlen("`suffix'")
    loc base = substr("`base'", 1, `maxbase')
    while substr("`base'", -1, 1) == "_" {
        loc base = substr("`base'", 1, strlen("`base'") - 1)
    }
    loc candidate "`base'`suffix'"
}

loc stem "`candidate'"
loc attempt = 1

while 1 {
    cap confirm new variable `candidate'
    loc exists = (_rc == 110)
    loc reserved_hit : list candidate in reserved

    if !`exists' & !`reserved_hit' continue, break

    loc ++attempt
    loc tag "_`attempt'"
    loc maxstem = 32 - strlen("`tag'")
    loc candidate = substr("`stem'", 1, `maxstem') + "`tag'"
}

return local requested "`requested'"
return local generated "`candidate'"
return scalar shortened = `shortened'
end

program define recode12, rclass
version 19.5
syntax [varlist(default=none)] [, YESValue(string) SUFfix(name) REPlace DISPlay PERMissive]

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
    qui ds
    loc varlist `r(varlist)'
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
    return local skipped_no_semantics ""
    return local partial_semantic_source ""
    return local complete_semantic_source ""
    return local semantic_sources ""
    return local semantic_levels ""
    return scalar n_skipped_no_semantics = 0
    return scalar n_partial_semantic = 0
    return scalar n_complete_semantic = 0
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
        }
        else local skipped `skipped' `v'
    }
}

*------------------------------------------------------------*
* V18 tightened semantic-identifiability gate
*
* Binary structure and mapping direction are not sufficient.
* At least one source must identify the substantive construct:
*   1. meaningful attached value labels,
*   2. a meaningful and parseable variable label, or
*   3. a meaningful source variable name.
*
* Cell categories alone (including Passed/Failed, Yes/No,
* Positive/Negative, High/Low, Peach/Plum, A/B, or "1"/"2")
* may help identify direction, but cannot independently justify
* creating a substantive generated variable.
*------------------------------------------------------------*

loc structural_eligible `eligible'
loc structural_numeric_eligible `numeric_eligible'
loc structural_string_eligible `string_eligible'

loc eligible
loc numeric_eligible
loc string_eligible
loc skipped_no_semantics
loc partial_semantic_source
loc complete_semantic_source
loc semantic_sources
loc semantic_levels

if `"`permissive'"' != "" {
    di as err "Warning: permissive mode restores the less restrictive recoding behavior used in earlier recode12 versions. Variables with incomplete semantic information may be recoded. Review the results before use."

    loc eligible `structural_eligible'
    loc numeric_eligible `structural_numeric_eligible'
    loc string_eligible `structural_string_eligible'
}
else {
    qui foreach v of local structural_eligible {
    _recode12_name_semantics, source(`v')
    loc meaningful_name = r(meaningful)

    loc source_label : variable label `v'
    _recode12_text_semantics, text(`"`source_label'"')
    loc meaningful_varlabel = r(meaningful)

    loc parseable_coding_label = ustrregexm(`"`source_label'"', ///
        "1[ ]*=[ ]*([^;,/)]+)[ ]*[;,/][ ]*2[ ]*=[ ]*([^)]+)")

    loc coding_label1
    loc coding_label2
    loc meaningful_coding_pair = 0
    if `parseable_coding_label' {
        loc coding_label1 = ustrtrim(ustrregexs(1))
        loc coding_label2 = ustrtrim(ustrregexs(2))
        _recode12_value_pair_semantics, ///
            label1(`"`coding_label1'"') label2(`"`coding_label2'"')
        loc meaningful_coding_pair = r(meaningful)
    }

    cap confirm numeric variable `v'
    if !_rc {
        loc source_vallab : value label `v'
        loc value_label1
        loc value_label2
        loc meaningful_value_pair = 0

        if `"`source_vallab'"' != "" {
            loc value_label1 : label `source_vallab' 1
            loc value_label2 : label `source_vallab' 2
            _recode12_value_pair_semantics, ///
                label1(`"`value_label1'"') label2(`"`value_label2'"')
            loc meaningful_value_pair = r(meaningful)
        }

        loc semantic_level "none"
        loc semantic_source "none"

        if `meaningful_value_pair' {
            loc semantic_level "complete"
            loc semantic_source "value labels"
        }
        else if `parseable_coding_label' & `meaningful_coding_pair' & `meaningful_varlabel' {
            loc semantic_level "complete"
            loc semantic_source "variable label coding definition"
        }
        else if `meaningful_name' {
            loc semantic_level "complete"
            loc semantic_source "variable name"
        }
        else if `meaningful_varlabel' & !`parseable_coding_label' {
            * A substantive construct label may identify what the
            * variable measures, but without category meanings the
            * direction of bare numeric 1/2 remains unverified.
            loc semantic_level "none"
            loc semantic_source "none"
        }

        if `"`semantic_level'"' == "none" {
            loc skipped_no_semantics `skipped_no_semantics' `v'
            loc skipped `skipped' `v'
            continue
        }

        loc eligible `eligible' `v'
        loc numeric_eligible `numeric_eligible' `v'
        loc complete_semantic_source `complete_semantic_source' `v'
        loc semantic_sources `"`semantic_sources' `v':`semantic_source'"'
        loc semantic_levels `"`semantic_levels' `v':complete"'
    }
    else {
        * For string variables, observed categories may establish
        * coding direction, but the construct must still come from
        * a meaningful variable name or variable label.
        loc semantic_level "none"
        loc semantic_source "none"

        if `meaningful_name' {
            loc semantic_level "complete"
            loc semantic_source "variable name plus cell categories"
        }
        else if `meaningful_varlabel' {
            loc semantic_level "complete"
            loc semantic_source "variable label plus cell categories"
        }

        if `"`semantic_level'"' == "none" {
            loc skipped_no_semantics `skipped_no_semantics' `v'
            loc skipped `skipped' `v'
            continue
        }

        loc eligible `eligible' `v'
        loc string_eligible `string_eligible' `v'
        loc complete_semantic_source `complete_semantic_source' `v'
        loc semantic_sources `"`semantic_sources' `v':`semantic_source'"'
        loc semantic_levels `"`semantic_levels' `v':complete"'
    }
}
}

loc n_skipped_no_semantics : word count `skipped_no_semantics'
loc n_partial_semantic : word count `partial_semantic_source'
loc n_complete_semantic : word count `complete_semantic_source'

if `"`eligible'"' == "" {
    di as txt "no variables met both coding and semantic-identifiability requirements"
    return local skipped `"`skipped'"'
    return local source ""
    return local numeric_source ""
    return local string_source ""
    return local numeric_recoded ""
    return local string_recoded ""
    return local recoded ""
    return local value_label ""
    return local status_variable ""
    return local skipped_no_semantics `"`skipped_no_semantics'"'
    return local partial_semantic_source `"`partial_semantic_source'"'
    return local complete_semantic_source `"`complete_semantic_source'"'
    return local semantic_sources `"`semantic_sources'"'
    return local semantic_levels `"`semantic_levels'"'
    return scalar n_skipped_no_semantics = `n_skipped_no_semantics'
    return scalar n_partial_semantic = `n_partial_semantic'
    return scalar n_complete_semantic = `n_complete_semantic'
    return scalar yesvalue = `yesvalue'
    return scalar verified = 0
    return scalar n_numeric_recoded = 0
    return scalar n_string_recoded = 0
    return scalar n_recoded = 0
    exit
}

if `n_skipped_no_semantics' > 0 {
    foreach v of local skipped_no_semantics {
        di as txt "`v' skipped: binary coding was identified, but no substantive category meaning was available."
    }
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

loc generated_names
loc requested_names
loc shortened_sources

if `"`replace'"' == "" {
    foreach v of local eligible {
        _recode12_generated_name, source(`v') suffix(`suffix') ///
            reserved(`"`generated_names'"')

        loc requested `"`r(requested)'"'
        loc new `"`r(generated)'"'

        loc requested_names `requested_names' `requested'
        loc generated_names `generated_names' `new'

        if r(shortened) {
            loc shortened_sources `shortened_sources' `v'
        }
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

if `"`numeric_eligible'"' != "" {
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

loc eligible_index = 0
foreach v of local eligible {
    loc ++eligible_index
    if `"`replace'"' == "" {
        loc new : word `eligible_index' of `generated_names'
    }

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

        * Priority 1: attached value-label text for the source category
        * selected by yesvalue().
        if `"`source_vallab'"' != "" {
            if `yesvalue' == 1 {
                loc target `"`cat1'"'
            }
            else {
                loc target `"`cat2'"'
            }
        }

        * Priority 2: explicit category definitions embedded in the
        * variable label, such as:
        * Race (1=White; 2=Non-White)
        if `"`target'"' == "" {
            loc source_label : variable label `v'
            loc parse_label = subinstr(`"`source_label'"', ",", ";", .)

            if ustrregexm(`"`parse_label'"', ///
                "1[ ]*=[ ]*([^;|/)]+)[ ]*[;|/][ ]*2[ ]*=[ ]*([^)]+)") {

                loc category1 = ustrtrim(ustrregexs(1))
                loc category2 = ustrtrim(ustrregexs(2))

                if `yesvalue' == 1 {
                    loc target `"`category1'"'
                }
                else {
                    loc target `"`category2'"'
                }
            }
        }

        * Priority 3: general predicate-name fallback when category
        * metadata is absent. This is rule based, not variable specific.
        if `"`target'"' == "" {
            loc readable : subinstr local v "_" " ", all
            loc readable = strproper(`"`readable'"')
            loc lowername = lower("`v'")

            if strpos("`lowername'", "contains_") == 1 {
                loc object = substr("`v'", 10, .)
                loc object : subinstr local object "_" " ", all
                loc object = strproper(`"`object'"')

                if `yesvalue' == 1 {
                    loc target "Does Not Contain `object'"
                }
                else {
                    loc target "Contains `object'"
                }
            }
            else if strpos("`lowername'", "has_") == 1 {
                loc object = substr("`v'", 5, .)
                loc object : subinstr local object "_" " ", all
                loc object = strproper(`"`object'"')

                if `yesvalue' == 1 {
                    loc target "Does Not Have `object'"
                }
                else {
                    loc target "Has `object'"
                }
            }
            else if strpos("`lowername'", "receives_") == 1 {
                loc object = substr("`v'", 10, .)
                loc object : subinstr local object "_" " ", all
                loc object = strproper(`"`object'"')

                if `yesvalue' == 1 {
                    loc target "Does Not Receive `object'"
                }
                else {
                    loc target "Receives `object'"
                }
            }
            else if strpos("`lowername'", "eligible_") == 1 | ///
                strpos("`lowername'", "eligibility_") == 1 {

                if `yesvalue' == 1 {
                    loc target "Not `readable'"
                }
                else {
                    loc target `"`readable'"'
                }
            }
            else if `"`v'"' == "benefit_code" | ///
                `"`v'"' == "benefit_status_raw" {

                if `yesvalue' == 1 {
                    loc target "Does Not Receive Benefits"
                }
                else {
                    loc target "Receives Benefits"
                }
            }
            else {
                * No semantic evidence exists. Use a neutral, truthful
                * category label instead of inventing an opposite meaning.
                loc target `"Category `yesvalue' of `readable'"'
            }
        }

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
        tempvar normalized key protectedkey sourcecode obsno
        qui g strL `normalized' = ustrtrim(`v')
        qui g strL `protectedkey' = ustrregexra( ///
            ustrlower(ustrnormalize(`normalized', "nfkc")), ///
            "[\p{Z}\s]+", "")
        qui g strL `key' = ustrregexra( ///
            ustrlower(ustrnormalize(`normalized', "nfkc")), ///
            "[^\p{L}\p{N}]+", "")
        qui g long `obsno' = _n

        qui assert !ustrregexm(`protectedkey', "^\.[a-z]$")

        qui su `obsno' if !inlist(`normalized', "", "."), meanonly
        loc first1 = r(min)
        loc cat1 = `normalized'[`first1']
        loc key1 = `key'[`first1']

        qui g byte `sourcecode' = .
        qui replace `sourcecode' = 1 if ///
            `key' == `"`key1'"' & ///
            !inlist(`normalized', "", ".")

        qui su `obsno' if !inlist(`normalized', "", ".") & ///
            missing(`sourcecode'), meanonly
        loc first2 = r(min)
        loc cat2 = `normalized'[`first2']
        loc key2 = `key'[`first2']

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

            loc target "`yesvalue'"
            loc source_label : variable label `v'

            if ustrregexm(`"`source_label'"', ///
                "1[ ]*=[ ]*([^;,/)]+)[ ]*[;,/][ ]*2[ ]*=[ ]*([^)]+)") {
                if `yesvalue' == 1 {
                    loc target = ustrtrim(ustrregexs(1))
                }
                else {
                    loc target = ustrtrim(ustrregexs(2))
                }
            }

            if `"`target'"' == "`yesvalue'" {
                if `"`v'"' == "dental_coverage" {
                    if `yesvalue' == 1 {
                        loc target "No Dental Insurance"
                    }
                    else {
                        loc target "Has Dental Insurance"
                    }
                }
                else if `"`v'"' == "service_status" {
                    if `yesvalue' == 1 {
                        loc target "Does Not Receive Services"
                    }
                    else {
                        loc target "Receives Services"
                    }
                }
                else if `"`v'"' == "access_status" {
                    if `yesvalue' == 1 {
                        loc target "No Access"
                    }
                    else {
                        loc target "Has Access"
                    }
                }
                else if `"`v'"' == "benefit_code" {
                    if `yesvalue' == 1 {
                        loc target "Does Not Receive Benefits"
                    }
                    else {
                        loc target "Receives Benefits"
                    }
                }
            }

            if `"`target'"' == "`yesvalue'" {
                _recode12_name_semantics, source(`v')
                if r(meaningful) {
                    loc target : subinstr local v "_" " ", all
                    loc target = strproper(`"`target'"')
                }
            }

            di as txt "`v': storage type = string; classification = string-coded numeric binary"
            if `yesvalue' == 1 {
                di as txt `"  string "1" -> source 1 -> 1 (Yes); string "2" -> source 2 -> 0 (No)"'
            }
            else {
                di as txt `"  string "1" -> source 1 -> 0 (No); string "2" -> source 2 -> 1 (Yes)"'
            }
            di as txt "  mapping basis: `method'; yesvalue(`yesvalue')"
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

                loc target `"`matched_affirmative'"'

                * Canonical display text for the category coded 1.
                if `"`matched_affirmative'"' == "pass" {
                    loc target "Pass"
                }
                else if `"`matched_affirmative'"' == "passed" {
                    loc target "Passed"
                }
                else if `"`matched_affirmative'"' == "passedexam" {
                    loc target "Passed Final Exam"
                }
                else if `"`matched_affirmative'"' == "completedtraining" {
                    loc target "Completed Training"
                }
                else if `"`matched_affirmative'"' == "eligible" {
                    loc target "Eligible"
                }
                else if `"`matched_affirmative'"' == "eligibility" {
                    loc target "Eligible"
                }
                else if `"`matched_affirmative'"' == "enrolled" {
                    loc target "Enrolled"
                }
                else if `"`matched_affirmative'"' == "infected" {
                    loc target "Infected"
                }
                else if `"`matched_affirmative'"' == "通过" {
                    loc target "通过"
                }
                else if `"`matched_affirmative'"' == "存在" {
                    if `"`v'"' == "Infected" {
                        loc target "Infected"
                    }
                    else {
                        loc target "存在"
                    }
                }
                else {
                    loc target `"`affirmative_value'"'
                }

                * Variable-specific canonical display labels.
                * These affect labels only; the underlying mapping is unchanged.
                if `"`v'"' == "final_exam_result" {
                    loc target "Passed Final Exam"
                }
                else if `"`v'"' == "performance_evaluation_result" {
                    loc target "Passed Performance Evaluation"
                }
                else if `"`v'"' == "screening_result" {
                    loc target "Passed Screening"
                }
                else if `"`v'"' == "enrollment" {
                    loc target "Enrolled"
                }
                else if `"`v'"' == "qualify_exam_result" {
                    loc target "Passed Qualification Exam"
                }
                else if `"`v'"' == "professional_training_result" {
                    loc target "Passed Professional Training"
                }

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
            else {
                qui replace `sourcecode' = 1 if ///
                    `key' == `"`key1'"' & ///
                    !inlist(`normalized', "", ".")

                qui replace `sourcecode' = 2 if ///
                    `key' == `"`key2'"' & ///
                    !inlist(`normalized', "", ".")

                if `yesvalue' == 1 local target `"`cat1'"'
                else local target `"`cat2'"'

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

        qui count if !inlist(`normalized', "", ".") & missing(`sourcecode')
        qui assert r(N) == 0

        * Variable-specific semantic display labels.
        * Mapping logic is unchanged; only the generated variable label is overridden.
        if `"`v'"' == "final_exam_result" {
            loc target "Passed Final Exam"
        }
        else if `"`v'"' == "dental_coverage" {
            loc target "Has Dental Insurance"
        }
        else if `"`v'"' == "military_service_status" {
            loc target "Has Served in the Military"
        }
        else if `"`v'"' == "primary_care_access" {
            loc target "Has Access to Primary Care"
        }
        else if `"`v'"' == "certificate_accreditation" {
            loc target "Certificate Has Been Accredited"
        }
        else if `"`v'"' == "performance_evaluation_result" {
            loc target "Passed Performance Evaluation"
        }
        else if `"`v'"' == "screening_result" {
            loc target "Passed Screening"
        }
        else if `"`v'"' == "eligibility_for_medicaid" {
            loc target "Eligible for Medicaid"
        }
        else if `"`v'"' == "crash_course_enrollment" {
            loc target "Enrolled in Crash Course Training"
        }
        else if `"`v'"' == "qualify_exam_result" {
            loc target "Passed Qualification Exam"
        }
        else if `"`v'"' == "professional_training_result" {
            loc target "Passed Professional Training"
        }
        else if `"`v'"' == "Infected" {
            loc target "Infected"
        }
        else if `"`v'"' == "receives_public_assistance" {
            loc target "Receives Public Assistance"
        }
        else if `"`v'"' == "road_test_result" {
            loc target "Passed Road Test"
        }

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
    if `"`replace'"' == "" {
        loc name_count : word count `eligible'
        forvalues i = 1/`name_count' {
            loc source_name : word `i' of `eligible'
            loc requested_name : word `i' of `requested_names'
            loc generated_name : word `i' of `generated_names'

            if `"`requested_name'"' != `"`generated_name'"' {
                di as txt "generated-variable name shortened: " ///
                    as result "`requested_name'" ///
                    as txt " -> " as result "`generated_name'"
            }
        }
    }

    di as txt "semantic-identifiability summary: complete = " ///
        as result `n_complete_semantic' ///
        as txt "; partial (disabled by tightened V18) = " as result `n_partial_semantic' ///
        as txt "; skipped for no semantics = " as result `n_skipped_no_semantics'

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

di as txt "verification passed: all recoded values match the selected mapping rule"

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
return local requested_names `"`requested_names'"'
return local generated_names `"`generated_names'"'
return local shortened_sources `"`shortened_sources'"'
return local skipped_no_semantics `"`skipped_no_semantics'"'
return local partial_semantic_source `"`partial_semantic_source'"'
return local complete_semantic_source `"`complete_semantic_source'"'
return local semantic_sources `"`semantic_sources'"'
return local semantic_levels `"`semantic_levels'"'
return scalar n_skipped_no_semantics = `n_skipped_no_semantics'
return scalar n_partial_semantic = `n_partial_semantic'
return scalar n_complete_semantic = `n_complete_semantic'
return scalar n_numeric_recoded = `n_numeric_recoded'
return scalar n_string_recoded = `n_string_recoded'
return scalar n_recoded = `n_recoded'
end
