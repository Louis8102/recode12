*! version 1.0.0  12jul2026
program define recode12, rclass
    version 16.0
    syntax [anything(name=vars)] [, YESValue(string) SUFfix(name) REPlace]

    if `"`yesvalue'"' == "" {
        di as txt _newline "Please choose the mapping rule:" _newline
        di as txt "1 - Source 1 -> 0 (No);  Source 2 -> 1 (Yes)"
        di as txt "2 - Source 1 -> 1 (Yes); Source 2 -> 0 (No)" _newline
        local choice
        while !inlist(`"`choice'"', "1", "2") {
            display as txt "Enter 1 or 2 [default 1]:" _continue
            display _request(_choice)
            if `"`choice'"' == "" local choice 1
            if !inlist(`"`choice'"', "1", "2") {
                di as err "Please enter either 1 or 2."
            }
        }
        if `"`choice'"' == "1" local yesvalue 2
        else local yesvalue 1
    }
    else if !inlist(`"`yesvalue'"', "1", "2") {
        di as err "yesvalue() must be 1 or 2"
        exit 198
    }

    local suffix_given = (`"`suffix'"' != "")
    if `"`replace'"' != "" & `suffix_given' {
        di as err "suffix() may not be combined with replace"
        exit 198
    }
    if `"`suffix'"' == "" local suffix "_01"

    if `"`vars'"' == "" {
        quietly ds, has(type numeric)
        local varlist `r(varlist)'
    }
    else {
        unab varlist : `vars'
        foreach v of local varlist {
            confirm numeric variable `v'
        }
    }
    if `"`varlist'"' == "" {
        di as txt "no numeric variables found"
        return local skipped ""
        return local recoded ""
        return scalar n_recoded = 0
        exit
    }

    local eligible
    local skipped
    quietly foreach v of local varlist {
        count if !inlist(`v', 1, 2, .)
        local bad = r(N)
        count if `v' == 1
        local n1 = r(N)
        count if `v' == 2
        local n2 = r(N)
        if (`bad' == 0 & `n1' > 0 & `n2' > 0) {
            local eligible `eligible' `v'
        }
        else {
            local skipped `skipped' `v'
        }
    }

    if `"`eligible'"' == "" {
        di as txt "no variables met the 1/2 coding rule"
        return local skipped `"`skipped'"'
        return local recoded ""
        return scalar n_recoded = 0
        exit
    }

    if `"`replace'"' == "" {
        foreach v of local eligible {
            local new `v'`suffix'
            confirm new variable `new'
        }
    }

    local vallab "recode12_NoYes"
    capture quietly label list `vallab'
    if _rc {
        label define `vallab' 0 "No" 1 "Yes"
    }
    else {
        local lab0 : label `vallab' 0
        local lab1 : label `vallab' 1
        if `"`lab0'"' != "No" | `"`lab1'"' != "Yes" {
            di as err "value label `vallab' already exists with incompatible definitions"
            exit 110
        }
    }

    local recoded
    if `yesvalue' == 1 {
        di as txt "mapping: source 1 -> 1 (Yes); source 2 -> 0 (No)"
    }
    else {
        di as txt "mapping: source 1 -> 0 (No); source 2 -> 1 (Yes)"
    }
    foreach v of local eligible {
        if `"`replace'"' != "" {
            tempvar original
            quietly clonevar `original' = `v'
            if `yesvalue' == 1 quietly replace `v' = 0 if `v' == 2
            else quietly replace `v' = (`v' == 2) if !missing(`v')
            label values `v' `vallab'
            if `yesvalue' == 1 {
                assert `v' == 1 if `original' == 1
                assert `v' == 0 if `original' == 2
            }
            else {
                assert `v' == 0 if `original' == 1
                assert `v' == 1 if `original' == 2
            }
            assert `v' == `original' if missing(`original')
            assert inlist(`v', 0, 1) | missing(`v')
            local recoded `recoded' `v'
        }
        else {
            local new `v'`suffix'
            quietly generate byte `new' = `v'
            if `yesvalue' == 1 quietly replace `new' = 0 if `new' == 2
            else quietly replace `new' = (`new' == 2) if !missing(`new')
            local vl : variable label `v'
            if `"`vl'"' != "" label variable `new' `"`vl'"'
            label values `new' `vallab'
            if `yesvalue' == 1 {
                assert `new' == 1 if `v' == 1
                assert `new' == 0 if `v' == 2
            }
            else {
                assert `new' == 0 if `v' == 1
                assert `new' == 1 if `v' == 2
            }
            assert `new' == `v' if missing(`v')
            assert inlist(`new', 0, 1) | missing(`new')
            local recoded `recoded' `new'
        }
    }

    local n_recoded : word count `recoded'
    di as txt "standardized `n_recoded' variable(s):" as result " `recoded'"
    di as txt "verification passed: all recoded values match the selected mapping rule"
    return local value_label "`vallab'"
    return scalar yesvalue = `yesvalue'
    return scalar verified = 1
    return local skipped `"`skipped'"'
    return local source `"`eligible'"'
    return local recoded `"`recoded'"'
    return scalar n_recoded = `n_recoded'
end
