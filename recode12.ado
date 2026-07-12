*! version 1.0.0  12jul2026
program define recode12, rclass
    version 16.0
    syntax [anything(name=vars)] [, SUFfix(name) REPlace]

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
        count if !missing(`v') & !inlist(`v', 1, 2)
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
    foreach v of local eligible {
        if `"`replace'"' != "" {
            quietly replace `v' = 0 if `v' == 2
            label values `v' `vallab'
            local recoded `recoded' `v'
        }
        else {
            local new `v'`suffix'
            quietly generate byte `new' = `v'
            quietly replace `new' = 0 if `new' == 2
            local vl : variable label `v'
            if `"`vl'"' != "" label variable `new' `"`vl'"'
            label values `new' `vallab'
            local recoded `recoded' `new'
        }
    }

    local n_recoded : word count `recoded'
    di as txt "standardized `n_recoded' variable(s):" as result " `recoded'"
    return local value_label "`vallab'"
    return local skipped `"`skipped'"'
    return local source `"`eligible'"'
    return local recoded `"`recoded'"'
    return scalar n_recoded = `n_recoded'
end
