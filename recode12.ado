*! version 1.1.2  29jul2026

capture mata: mata drop _recode12_vl_exact()
mata:
void _recode12_vl_exact(string scalar name)
{
    real colvector values
    string colvector text
    real scalar ok

    pragma unset values
    pragma unset text
    st_vlload(name, values, text)
    ok = rows(values) == 2
    if (ok) {
        ok = values[1] == 0 & values[2] == 1
        ok = ok & text[1] == "No" & text[2] == "Yes"
    }
    st_local("vl_exact", strofreal(ok))
}
end

program define recode12, rclass
    version 19.5
    syntax [varlist(default=none)] [, YESValue(string) SUFfix(name) ///
        REPlace DISPlay PERMissive]

    if `"`yesvalue'"' == "" {
        display as error "yesvalue() is required; specify yesvalue(1) or yesvalue(2)"
        exit 198
    }
    if !inlist(`"`yesvalue'"', "1", "2") {
        display as error "yesvalue() must be 1 or 2"
        exit 198
    }

    local permissive_on = (`"`permissive'"' != "")
    local suffix_given = (`"`suffix'"' != "")
    if `"`replace'"' != "" & `suffix_given' {
        display as error "suffix() may not be combined with replace"
        exit 198
    }
    if `"`suffix'"' == "" local suffix "_01"

    if `"`varlist'"' == "" {
        capture quietly ds recode12_status, not
        if _rc quietly ds
        local varlist `r(varlist)'
    }

    if `"`varlist'"' == "" {
        display as text "numeric variables successfully recoded: " as result 0
        display as text "string variables successfully recoded: " as result 0
        display as text "no variables were recoded; verification was not performed"
        return local skipped ""
        return local structural_skipped ""
        return local semantic_skipped ""
        return local source ""
        return local numeric_source ""
        return local string_source ""
        return local numeric_recoded ""
        return local string_recoded ""
        return local recoded ""
        return local value_label ""
        return local status_variable ""
        return local report ""
        return scalar yesvalue = `yesvalue'
        return scalar verified = 0
        return scalar n_permissive_recoded = 0
        return scalar n_structural_skipped = 0
        return scalar n_semantic_skipped = 0
        return scalar n_numeric_recoded = 0
        return scalar n_string_recoded = 0
        return scalar n_recoded = 0
        exit
    }

    local skipped
    local structural_skipped
    local semantic_skipped
    local plan_n = 0
    local permissive_n = 0
    local scan_string_vars
    local scan_key_vars
    capture quietly ds `varlist', has(type string)
    if !_rc {
        local scan_string_vars `r(varlist)'
        foreach scan_string of local scan_string_vars {
            tempvar scan_key
            local scan_key_vars `scan_key_vars' `scan_key'
        }
        mata: _recode12_scan_strings( ///
            `"`scan_string_vars'"', `"`scan_key_vars'"')
    }

    /*
    Analysis creates an explicit plan.  No output variable is changed until
    every candidate has passed structural and semantic analysis.
    */
    quietly foreach v of local varlist {
        if `"`v'"' == "recode12_status" {
            local skipped `skipped' `v'
            local structural_skipped `structural_skipped' `v'
            continue
        }

        local structural = 0
        local semantic = 0
        local source_kind
        local source1
        local source2
        local display1
        local display2
        local label1
        local label2
        local directed = 0
        local keyvar
        local skip_reason

        local original_varlabel : variable label `v'
        local original_vallabel : value label `v'

        capture confirm numeric variable `v'
        if !_rc {
            local source_kind numeric
            local display1 "1"
            local display2 "2"
            count if !inlist(`v', 1, 2, .)
            local n_bad = r(N)
            count if `v' == 1
            local n_one = r(N)
            count if `v' == 2
            local n_two = r(N)

            if (`n_bad' == 0 & `n_one' > 0 & `n_two' > 0) {
                local structural = 1
                local source1 1
                local source2 2

                local explicit1
                local explicit2
                if `"`original_vallabel'"' != "" {
                    local explicit1 : label `original_vallabel' 1
                    local explicit2 : label `original_vallabel' 2
                }
                if `"`explicit1'"' == "" | `"`explicit2'"' == "" {
                    _recode12_parse_codes, text(`"`original_varlabel'"')
                    if r(found) {
                        local explicit1 `"`r(category1)'"'
                        local explicit2 `"`r(category2)'"'
                    }
                }

                if `"`explicit1'"' != "" & `"`explicit2'"' != "" {
                    local display1 `"`explicit1'"'
                    local display2 `"`explicit2'"'
                    _recode12_generic_categories, ///
                        category1(`"`explicit1'"') category2(`"`explicit2'"')
                    if !r(generic) {
                        local semantic = 1
                        local label1 `"`explicit1'"'
                        local label2 `"`explicit2'"'
                    }
                }
            }
            else local skip_reason "numeric values are not exactly 1, 2, and ordinary system missing with both categories represented"
        }
        else {
            local source_kind string
            local scan_index : list posof "`v'" in scan_string_vars
            local n_reserved = `scan_n_reserved`scan_index''
            if `n_reserved' > 0 {
                local skip_reason "string variable contains a prohibited reserved missing token"
            }
            else {
                local n_keys = `scan_n_keys`scan_index''
                if `n_keys' != 2 {
                    local skip_reason "string variable does not contain exactly two normalized nonmissing categories"
                }
                else {
                    local invalid_numeric_string = ///
                        `scan_invalid_numeric_string`scan_index''
                    local n_12 = `scan_n_12`scan_index''
                    local n_nonmissing = `scan_n_nonmissing`scan_index''

                    if `invalid_numeric_string' {
                        local skip_reason "string variable contains a prohibited numeric string"
                    }
                    else if (`n_12' > 0 & `n_12' < `n_nonmissing') {
                        local skip_reason "string variable mixes string-coded 1/2 with ordinary text"
                    }
                    else {
                        local structural = 1
                        local keyvar : word `scan_index' of `scan_key_vars'

                        if `n_12' == `n_nonmissing' {
                            local source1 1
                            local source2 2
                            local display1 "1"
                            local display2 "2"

                            _recode12_parse_codes, text(`"`original_varlabel'"')
                            if r(found) {
                                local c1 `"`r(category1)'"'
                                local c2 `"`r(category2)'"'
                                local display1 `"`c1'"'
                                local display2 `"`c2'"'
                                _recode12_generic_categories, ///
                                    category1(`"`c1'"') category2(`"`c2'"')
                                if !r(generic) {
                                    local semantic = 1
                                    local label1 `"`c1'"'
                                    local label2 `"`c2'"'
                                }
                            }
                            if !`semantic' {
                                _recode12_binary_context, ///
                                    varname(`"`v'"') varlabel(`"`original_varlabel'"')
                                if r(sufficient) {
                                    local semantic = 1
                                    local label1 `"`r(category1)'"'
                                    local label2 `"`r(category2)'"'
                                    local display1 `"`r(category1)'"'
                                    local display2 `"`r(category2)'"'
                                }
                            }
                        }
                        else {
                            local first_key ///
                                `"`scan_first_key`scan_index''"'
                            local first_display ///
                                `"`scan_first_display`scan_index''"'
                            local second_key ///
                                `"`scan_second_key`scan_index''"'
                            local second_display ///
                                `"`scan_second_display`scan_index''"'

                            _recode12_directed_pair, ///
                                keya(`"`first_key'"') keyb(`"`second_key'"')
                            local directed = r(directed)

                            if `directed' {
                                local negative_key `"`r(negative_key)'"'
                                local positive_key `"`r(positive_key)'"'
                                local pair_family `"`r(family)'"'
                                if `"`first_key'"' == `"`negative_key'"' {
                                    local negative_display `"`first_display'"'
                                    local positive_display `"`second_display'"'
                                }
                                else {
                                    local negative_display `"`second_display'"'
                                    local positive_display `"`first_display'"'
                                }

                                _recode12_context, ///
                                    varname(`"`v'"') varlabel(`"`original_varlabel'"')
                                local context_sufficient = r(sufficient)
                                local context `"`r(context)'"'

                                if `context_sufficient' | r(category_complete) {
                                    local semantic = 1
                                    local source1 `"`negative_key'"'
                                    local source2 `"`positive_key'"'
                                    local display1 `"`negative_display'"'
                                    local display2 `"`positive_display'"'
                                    _recode12_directed_labels, ///
                                        family(`"`pair_family'"') ///
                                        context(`"`context'"') ///
                                        negativekey(`"`negative_key'"') ///
                                        positivekey(`"`positive_key'"') ///
                                        displaya(`"`first_display'"') ///
                                        keya(`"`first_key'"') ///
                                        displayb(`"`second_display'"') ///
                                        keyb(`"`second_key'"')
                                    local label1 `"`r(negative_label)'"'
                                    local label2 `"`r(positive_label)'"'
                                }
                                else if `permissive_on' {
                                    /*
                                    Sole approved exception: a directed but
                                    semantic-insufficient permissive pair keeps
                                    the affirmative category at output 1 under
                                    either yesvalue setting.
                                    */
                                    if `yesvalue' == 1 {
                                        local source1 `"`positive_key'"'
                                        local source2 `"`negative_key'"'
                                        local display1 `"`positive_display'"'
                                        local display2 `"`negative_display'"'
                                    }
                                    else {
                                        local source1 `"`negative_key'"'
                                        local source2 `"`positive_key'"'
                                        local display1 `"`negative_display'"'
                                        local display2 `"`positive_display'"'
                                    }
                                }
                                else {
                                    local source1 `"`negative_key'"'
                                    local source2 `"`positive_key'"'
                                    local display1 `"`negative_display'"'
                                    local display2 `"`positive_display'"'
                                }
                            }
                            else {
                                local source1 `"`first_key'"'
                                local source2 `"`second_key'"'
                                local display1 `"`first_display'"'
                                local display2 `"`second_display'"'
                                _recode12_context, ///
                                    varname(`"`v'"') varlabel(`"`original_varlabel'"')
                                if r(sufficient) {
                                    local semantic = 1
                                    local label1 `"`first_display'"'
                                    local label2 `"`second_display'"'
                                }
                            }
                        }
                    }
                }
            }
        }

        local recode_allowed = `structural' & (`semantic' | `permissive_on')
        if !`recode_allowed' {
            local skipped `skipped' `v'
            if !`structural' {
                local structural_skipped `structural_skipped' `v'
                if `"`skip_reason'"' == "" local skip_reason "structurally ineligible"
            }
            else {
                local semantic_skipped `semantic_skipped' `v'
            }
            continue
        }

        if !`semantic' {
            local ++permissive_n
            local neutral `"Recoded `v' (0=No; 1=Yes)"'
            local label1 `"`neutral'"'
            local label2 `"`neutral'"'
        }
        else {
            local label1 `"Recoded `label1' (0=No; 1=Yes)"'
            local label2 `"Recoded `label2' (0=No; 1=Yes)"'
        }
        local label1 = ustrleft(`"`label1'"', 80)
        local label2 = ustrleft(`"`label2'"', 80)

        local ++plan_n
        local p_var`plan_n' `v'
        local p_kind`plan_n' `source_kind'
        local p_source1`plan_n' `"`source1'"'
        local p_source2`plan_n' `"`source2'"'
        local p_display1`plan_n' `"`display1'"'
        local p_display2`plan_n' `"`display2'"'
        local p_label1`plan_n' `"`label1'"'
        local p_label2`plan_n' `"`label2'"'
        local p_permissive`plan_n' = !`semantic'
        local p_keyvar`plan_n' `keyvar'
    }
    if `plan_n' == 0 {
        display as text "numeric variables successfully recoded: " as result 0
        display as text "string variables successfully recoded: " as result 0
        display as text "no variables were recoded; verification was not performed"
        local n_structural_skipped : word count `structural_skipped'
        local n_semantic_skipped : word count `semantic_skipped'
        return local skipped `"`skipped'"'
        return local structural_skipped `"`structural_skipped'"'
        return local semantic_skipped `"`semantic_skipped'"'
        return local source ""
        return local numeric_source ""
        return local string_source ""
        return local numeric_recoded ""
        return local string_recoded ""
        return local recoded ""
        return local value_label ""
        return local status_variable ""
        return local report ""
        return scalar yesvalue = `yesvalue'
        return scalar verified = 0
        return scalar n_permissive_recoded = 0
        return scalar n_structural_skipped = `n_structural_skipped'
        return scalar n_semantic_skipped = `n_semantic_skipped'
        return scalar n_numeric_recoded = 0
        return scalar n_string_recoded = 0
        return scalar n_recoded = 0
        exit
    }

    if `permissive_on' & `permissive_n' > 0 {
        display as error ///
            "Warning: `permissive_n' variable(s) with incomplete semantic information will be recoded."
    }

    if `"`display'"' != "" {
        capture putdocx describe
        if !_rc {
            display as error ///
                "display cannot create its report while another putdocx document is active"
            display as error ///
                "save or clear the active putdocx document and rerun recode12"
            exit 110
        }
    }

    /*
    Preflight every generated name and the shared value label before any
    output data are written.
    */
    local planned_names
    if `"`replace'"' == "" {
        forvalues i = 1/`plan_n' {
            local v `p_var`i''
            _recode12_newname, source(`v') suffix(`"`suffix'"')
            local new `r(name)'
            if `: list new in planned_names' {
                display as error "generated variable name collision: `new'"
                exit 110
            }
            confirm new variable `new'
            local planned_names `planned_names' `new'
            local p_new`i' `new'
        }
    }

    local vallab "recode12_NoYes"
    capture quietly label list `vallab'
    if !_rc {
        _recode12_value_label_exact, name(`vallab')
        if !r(exact) {
            display as error ///
                "value label `vallab' already exists with incompatible definitions"
            exit 110
        }
    }
    else label define `vallab' 0 "No" 1 "Yes"

    local statusvar "recode12_status"
    capture confirm variable `statusvar'
    if !_rc {
        local statuslabel : variable label `statusvar'
        local statustype : type `statusvar'
        if substr(`"`statustype'"', 1, 3) != "str" | ///
            !inlist(`"`statuslabel'"', "recode12 verification status", ///
                "recode12 Verification Status") {
            display as error ///
                "variable `statusvar' already exists and was not created by recode12"
            exit 110
        }
    }
    local recoded
    local numeric_recoded
    local string_recoded
    local source
    local numeric_source
    local string_source

    forvalues i = 1/`plan_n' {
        local v `p_var`i''
        local kind `p_kind`i''
        local source1 `"`p_source1`i''"'
        local source2 `"`p_source2`i''"'
        local newvl `"`p_label`yesvalue'`i''"'
        local keyvar `p_keyvar`i''

        tempvar sourcecode
        if `"`kind'"' == "numeric" {
            quietly generate byte `sourcecode' = `v' if !missing(`v')
        }
        else {
            quietly generate byte `sourcecode' = .
            quietly replace `sourcecode' = 1 if `keyvar' == `"`source1'"' & ///
                !missing(`keyvar')
            quietly replace `sourcecode' = 2 if `keyvar' == `"`source2'"' & ///
                !missing(`keyvar')
        }

        quietly count if `sourcecode' == 1
        local source_n1 = r(N)
        if `source_n1' == 0 {
            display as error "`v': internal source category 1 is absent"
            exit 459
        }
        quietly count if `sourcecode' == 2
        local source_n2 = r(N)
        if `source_n2' == 0 {
            display as error "`v': internal source category 2 is absent"
            exit 459
        }
        quietly count if missing(`sourcecode')
        local source_nmissing = r(N)

        if `"`replace'"' == "" {
            local new `p_new`i''
            quietly generate byte `new' = (`sourcecode' == `yesvalue') ///
                if !missing(`sourcecode')
            label variable `new' `"`newvl'"'
            label values `new' `vallab'
            local output `new'
        }
        else if `"`kind'"' == "numeric" {
            quietly replace `v' = (`sourcecode' == `yesvalue') ///
                if !missing(`sourcecode')
            label variable `v' `"`newvl'"'
            label values `v' `vallab'
            local output `v'
        }
        else {
            local oldformat : format `v'
            local charlist : char `v'[]
            local char_n = 0
            foreach ch of local charlist {
                local ++char_n
                local char_name`char_n' `ch'
                local char_value`char_n' : char `v'[`ch']
            }

            tempvar newvalue
            quietly generate byte `newvalue' = (`sourcecode' == `yesvalue') ///
                if !missing(`sourcecode')
            quietly order `newvalue', before(`v')
            quietly drop `v'
            quietly rename `newvalue' `v'

            local width = 8
            if regexm(`"`oldformat'"', "^%-?([0-9]+)s$") {
                local width = real(regexs(1))
            }
            format `v' %`width'.0g
            if `char_n' > 0 {
                forvalues c = 1/`char_n' {
                    local ch `char_name`c''
                    local cv `"`char_value`c''"'
                    char `v'[`ch'] `"`cv'"'
                }
            }
            label variable `v' `"`newvl'"'
            label values `v' `vallab'
            local output `v'
        }
        local p_output`i' `output'

        quietly assert `output' == (`sourcecode' == `yesvalue') ///
            if !missing(`sourcecode')
        quietly assert missing(`output') if missing(`sourcecode')
        quietly assert inlist(`output', 0, 1) | missing(`output')
        quietly count if `output' == 0
        local output_n0 = r(N)
        if `output_n0' == 0 {
            display as error "`output': validation found no output value 0"
            exit 459
        }
        quietly count if `output' == 1
        local output_n1 = r(N)
        if `output_n1' == 0 {
            display as error "`output': validation found no output value 1"
            exit 459
        }
        quietly count if missing(`output')
        local output_nmissing = r(N)
        local expected_n0 = cond(`yesvalue' == 1, ///
            `source_n2', `source_n1')
        local expected_n1 = cond(`yesvalue' == 1, ///
            `source_n1', `source_n2')
        if `output_n0' != `expected_n0' | ///
            `output_n1' != `expected_n1' | ///
            `output_nmissing' != `source_nmissing' {
            display as error ///
                "`output': source/output frequency validation failed"
            exit 459
        }

        local checked_vallabel : value label `output'
        local checked_varlabel : variable label `output'
        local checked_lab0 : label `checked_vallabel' 0
        local checked_lab1 : label `checked_vallabel' 1
        if `"`checked_vallabel'"' != `"`vallab'"' | ///
            `"`checked_lab0'"' != "No" | `"`checked_lab1'"' != "Yes" {
            display as error "`output': value-label validation failed"
            exit 459
        }
        if `"`checked_varlabel'"' != `"`newvl'"' {
            display as error "`output': variable-label validation failed"
            exit 459
        }

        local source `source' `v'
        local recoded `recoded' `output'
        if `"`kind'"' == "numeric" {
            local numeric_source `numeric_source' `v'
            local numeric_recoded `numeric_recoded' `output'
        }
        else {
            local string_source `string_source' `v'
            local string_recoded `string_recoded' `output'
        }
    }
    capture confirm variable `statusvar'
    if _rc quietly generate str9 `statusvar' = "confirmed"
    else quietly replace `statusvar' = "confirmed"
    label variable `statusvar' "recode12 verification status"
    quietly assert `statusvar' == "confirmed"
    local checked_status_label : variable label `statusvar'
    if `"`checked_status_label'"' != "recode12 verification status" {
        display as error "status-variable validation failed"
        exit 459
    }

    local n_recoded : word count `recoded'
    local n_numeric_recoded : word count `numeric_recoded'
    local n_string_recoded : word count `string_recoded'
    local n_structural_skipped : word count `structural_skipped'
    local n_semantic_skipped : word count `semantic_skipped'

    local report_path
    if `"`display'"' != "" {
        local report_date = subinstr(`"`c(current_date)'"', " ", "", .)
        local report_time = subinstr(`"`c(current_time)'"', ":", "", .)
        local report_dir = subinstr(`"`c(pwd)'"', "\", "/", .)
        local report_stem `"recode12_display_`report_date'_`report_time'"'
        local report_path `"`report_dir'/`report_stem'.docx"'
        local report_index = 1
        capture confirm file `"`report_path'"'
        while !_rc {
            local ++report_index
            local report_path ///
                `"`report_dir'/`report_stem'_`report_index'.docx"'
            capture confirm file `"`report_path'"'
        }

        local regular_numeric_n = 0
        local regular_string_n = 0
        local permissive_numeric_n = 0
        local permissive_string_n = 0
        forvalues i = 1/`plan_n' {
            if !`p_permissive`i'' {
                if `"`p_kind`i''"' == "numeric" {
                    local ++regular_numeric_n
                }
                else if `"`p_kind`i''"' == "string" {
                    local ++regular_string_n
                }
            }
            else {
                if `"`p_kind`i''"' == "numeric" {
                    local ++permissive_numeric_n
                }
                else if `"`p_kind`i''"' == "string" {
                    local ++permissive_string_n
                }
            }
        }

        capture noisily {
        putdocx begin, landscape font("Times New Roman", 8) ///
            margin(left, 0.5in) margin(right, 0.5in)
        putdocx paragraph, halign(center) spacing(after, 12pt)
        putdocx text ("recode12: Summary of Recoding to 0/1 Binary Variables"), ///
            bold font("Times New Roman", 12, "000000")
        putdocx paragraph

        local report_sections "regular_numeric regular_string"
        if `permissive_on' {
            local report_sections "`report_sections' permissive"
        }
        local report_table_number = 0
        foreach report_section of local report_sections {
            if `"`report_section'"' == "regular_numeric" {
                local group_n = `regular_numeric_n'
                local group_title "Eligible Numeric Variables Recoding Summary"
                local report_table "recode12_numeric"
                local ordered_kinds "numeric"
                local require_permissive = 0
                local table_columns = 3
                local source_column = 1
                local type_column = 0
                local mapping_column = 2
                local result_column = 3
                local group_subtitle ""
            }
            else if `"`report_section'"' == "regular_string" {
                local group_n = `regular_string_n'
                local group_title "Eligible String Variables Recoding Summary"
                local report_table "recode12_string"
                local ordered_kinds "string"
                local require_permissive = 0
                local table_columns = 3
                local source_column = 1
                local type_column = 0
                local mapping_column = 2
                local result_column = 3
                local group_subtitle ""
            }
            else {
                local group_n = `permissive_n'
                local group_title "Recoding Summary for Variables with Unclear Semantics under Permissive Mode"
                local report_table "recode12_permissive"
                local ordered_kinds "numeric string"
                local require_permissive = 1
                local table_columns = 4
                local source_column = 1
                local type_column = 2
                local mapping_column = 3
                local result_column = 4
                local group_subtitle ""
            }
            if `group_n' == 0 & !`permissive_on' continue

            local ++report_table_number
            if `report_table_number' > 1 {
                putdocx pagebreak
            }
            putdocx paragraph, spacing(before, 10pt) spacing(after, 0pt)
            putdocx text ("Table `report_table_number'. `group_title'"), ///
                font("Times New Roman", 10, "000000")

            local group_rows = `group_n' + 1
            local note_row = `group_rows' + 1
            putdocx table `report_table' = (`note_row', `table_columns'), ///
                width(10in) layout(fixed) headerrow(1) border(all, nil) ///
                cellmargin(left, 0.04in) cellmargin(right, 0.04in) ///
                cellmargin(top, 0.02in) cellmargin(bottom, 0.02in)
            putdocx table `report_table'(1,`source_column') = ///
                ("Variable")
            if `type_column' > 0 {
                putdocx table `report_table'(1,`type_column') = ("Type")
            }
            putdocx table `report_table'(1,`mapping_column') = ///
                ("Mapping Process")
            putdocx table `report_table'(1,`result_column') = ("Result")
            local group_row = 1
            local max_source_chars = 0
            local max_mapping_chars = 0
            local max_result_chars = 0
            foreach ordered_kind of local ordered_kinds {
                forvalues i = 1/`plan_n' {
                    if `"`p_kind`i''"' != `"`ordered_kind'"' continue
                    local report_permissive = `p_permissive`i''
                    if `report_permissive' != `require_permissive' continue

                    local ++group_row
                    local report_source `p_var`i''
                    local report_output `p_output`i''
                    local report_kind = ustrtitle(`"`p_kind`i''"')
                    local report_display1 `"`p_display1`i''"'
                    local report_display2 `"`p_display2`i''"'
                    local report_label `"`p_label`yesvalue'`i''"'
                    if `yesvalue' == 1 {
                        local report_mapping1 ///
                            `"`report_display1' -> 1"'
                        local report_mapping2 ///
                            `"`report_display2' -> 0"'
                    }
                    else {
                        local report_mapping1 ///
                            `"`report_display1' -> 0"'
                        local report_mapping2 ///
                            `"`report_display2' -> 1"'
                    }
                    local report_mapping ///
                        `"`report_mapping1'; `report_mapping2'"'
                    local report_result ///
                        `"`report_output' | `report_label'"'
                    local report_source_chars = ustrlen(`"`report_source'"')
                    local report_mapping_chars = ustrlen(`"`report_mapping'"')
                    local report_result_chars = ustrlen(`"`report_result'"')
                    if `report_source_chars' > `max_source_chars' {
                        local max_source_chars = `report_source_chars'
                    }
                    if `report_mapping_chars' > `max_mapping_chars' {
                        local max_mapping_chars = `report_mapping_chars'
                    }
                    if `report_result_chars' > `max_result_chars' {
                        local max_result_chars = `report_result_chars'
                    }

                    putdocx table `report_table'(`group_row',`source_column') = ///
                        (`"`report_source'"')
                    if `type_column' > 0 {
                        putdocx table `report_table'(`group_row',`type_column') = ///
                            (`"`report_kind'"')
                    }
                    putdocx table `report_table'(`group_row',`mapping_column') = ///
                        (`"`report_mapping'"')
                    putdocx table `report_table'(`group_row',`result_column') = ///
                        (`"`report_result'"')
                }
            }
            local source_width = max(0.8, ///
                0.052 * `max_source_chars' + 0.12)
            local type_width = cond(`type_column' > 0, 0.65, 0)
            local content_width = 10 - `source_width' - `type_width'
            local mapping_need = max(1.5, ///
                0.052 * `max_mapping_chars' + 0.12)
            local result_need = max(2, ///
                0.052 * `max_result_chars' + 0.12)
            local combined_need = `mapping_need' + `result_need'
            if `combined_need' <= `content_width' {
                local spare_width = `content_width' - `combined_need'
                local mapping_width = `mapping_need' + 0.4 * `spare_width'
                local result_width = `result_need' + 0.6 * `spare_width'
            }
            else {
                local mapping_width = ///
                    `content_width' * `mapping_need' / `combined_need'
                local result_width = `content_width' - `mapping_width'
            }
            putdocx table `report_table'(.,`source_column'), ///
                width(`source_width'in)
            if `type_column' > 0 {
                putdocx table `report_table'(.,`type_column'), ///
                    width(`type_width'in)
            }
            putdocx table `report_table'(.,`mapping_column'), ///
                width(`mapping_width'in)
            putdocx table `report_table'(.,`result_column'), ///
                width(`result_width'in)
            putdocx table `report_table'(.,.), ///
                valign(center) font("Times New Roman", 8, "000000")
            putdocx table `report_table'(1,.), ///
                font("Times New Roman", 10, "000000")
            putdocx table `report_table'(.,.), halign(left)
            putdocx table `report_table'(1,.), ///
                border(top, single, "000000", 1.5pt) ///
                border(bottom, single, "000000", 0.5pt)
            forvalues report_row = 1/`note_row' {
                putdocx table `report_table'(`report_row',.), nosplit
            }

            local note_variable = cond(`group_n' == 1, ///
                "variable", "variables")
            local note_verb = cond(`group_n' == 1, "was", "were")
            if `"`report_section'"' == "regular_numeric" {
                local report_note ///
                    "`group_n' eligible numeric `note_variable' `note_verb' recoded using yesvalue(`yesvalue'). By default, generated recoded variable names use the suffix _01."
            }
            else if `"`report_section'"' == "regular_string" {
                local report_note ///
                    "`group_n' eligible string `note_variable' `note_verb' recoded using yesvalue(`yesvalue'). By default, generated recoded variable names use the suffix _01."
            }
            else {
                local report_note ///
                    "`group_n' `note_variable' with incomplete semantic information (`permissive_numeric_n' numeric and `permissive_string_n' string) `note_verb' recoded under permissive mode using yesvalue(`yesvalue'). By default, generated recoded variable names use the suffix _01."
            }
            putdocx table `report_table'(`note_row',1) = ("Note. "), ///
                italic font("Times New Roman", 8, "000000") ///
                colspan(`table_columns')
            putdocx table `report_table'(`note_row',1) = ///
                (`"`report_note'"'), append ///
                font("Times New Roman", 8, "000000")
            putdocx table `report_table'(`note_row',1), ///
                valign(top) halign(left) border(all, nil)
            if `group_n' > 0 {
                putdocx table `report_table'(`group_rows',.), ///
                    border(bottom, single, "000000", 1.5pt)
            }
            else {
                putdocx table `report_table'(1,.), ///
                    border(bottom, single, "000000", 1.5pt)
            }
        }

        putdocx save `"`report_path'"'
        }
        local report_rc = _rc
        if `report_rc' {
            capture putdocx clear
            display as error ///
                "recoding was verified, but the requested Word summary could not be created"
            exit `report_rc'
        }
    }

    display as text "numeric variables successfully recoded: " ///
        as result `n_numeric_recoded'
    display as text "string variables successfully recoded: " ///
        as result `n_string_recoded'
    display as text ///
        "verification passed: all recoded values match the selected mapping rule; missingness and output labels validated"
    return local value_label "`vallab'"
    return local status_variable "`statusvar'"
    return local report `"`report_path'"'
    return scalar yesvalue = `yesvalue'
    return scalar verified = 1
    return scalar n_permissive_recoded = `permissive_n'
    return local skipped `"`skipped'"'
    return local structural_skipped `"`structural_skipped'"'
    return local semantic_skipped `"`semantic_skipped'"'
    return local source `"`source'"'
    return local numeric_source `"`numeric_source'"'
    return local string_source `"`string_source'"'
    return local numeric_recoded `"`numeric_recoded'"'
    return local string_recoded `"`string_recoded'"'
    return local recoded `"`recoded'"'
    return scalar n_structural_skipped = `n_structural_skipped'
    return scalar n_semantic_skipped = `n_semantic_skipped'
    return scalar n_numeric_recoded = `n_numeric_recoded'
    return scalar n_string_recoded = `n_string_recoded'
    return scalar n_recoded = `n_recoded'
end


program define _recode12_value_label_exact, rclass
    version 19.5
    syntax, NAME(name)
    local vl_exact 0
    mata: _recode12_vl_exact(st_local("name"))
    return scalar exact = real(`"`vl_exact'"')
end


program define _recode12_textkey, rclass
    version 19.5
    syntax [, TEXT(string)]

    local display = ustrtrim(ustrnormalize(`"`text'"', "nfkc"))
    local protected = ustrlower(`"`display'"')
    local protected = ustrregexra(`"`protected'"', "[\p{Z}\s]+", "")
    local matching = ustrlower(`"`display'"')
    local matching = ustrregexra(`"`matching'"', ///
        "[\p{Z}\s\p{P}\p{S}]+", "")
    local reserved = ustrregexm(`"`protected'"', "^\.[a-z]$")
    local ordinary_missing = inlist(`"`protected'"', "", ".")
    local string_numeric = inlist(`"`matching'"', "1", "2")

    return local display `"`display'"'
    return local protected_key `"`protected'"'
    return local matching_key `"`matching'"'
    return scalar reserved = `reserved'
    return scalar ordinary_missing = `ordinary_missing'
    return scalar string_numeric = `string_numeric'
end


program define _recode12_parse_codes, rclass
    version 19.5
    syntax [, TEXT(string)]

    local category1
    local category2
    local normalized = ustrnormalize(`"`text'"', "nfkc")
    if ustrregexm(`"`normalized'"', "(?i)1\s*=\s*([^;,\)]+)") {
        local category1 = ustrtrim(ustrregexs(1))
    }
    if ustrregexm(`"`normalized'"', "(?i)2\s*=\s*([^;,\)]+)") {
        local category2 = ustrtrim(ustrregexs(1))
    }
    return scalar found = (`"`category1'"' != "" & `"`category2'"' != "")
    return local category1 `"`category1'"'
    return local category2 `"`category2'"'
end


program define _recode12_generic_categories, rclass
    version 19.5
    syntax, CATEGORY1(string) CATEGORY2(string)

    local k1 = ustrlower(ustrnormalize(`"`category1'"', "nfkc"))
    local k2 = ustrlower(ustrnormalize(`"`category2'"', "nfkc"))
    local k1 = ustrregexra(`"`k1'"', "[\p{Z}\s\p{P}\p{S}]+", "")
    local k2 = ustrregexra(`"`k2'"', "[\p{Z}\s\p{P}\p{S}]+", "")
    local g1 = ustrregexm(`"`k1'"', "^(category|type|code)[a-z0-9]*$")
    local g2 = ustrregexm(`"`k2'"', "^(category|type|code)[a-z0-9]*$")
    return scalar generic = (`g1' & `g2')
end


program define _recode12_context, rclass
    version 19.5
    syntax, VARNAME(string) [VARLABEL(string)]

    local context = ustrtrim(`"`varlabel'"')
    local context_key = ustrlower(ustrnormalize(`"`context'"', "nfkc"))
    local context_key = ustrregexra(`"`context_key'"', ///
        "[\p{Z}\s\p{P}\p{S}]+", "")
    local reduced = ustrregexra(`"`context_key'"', ///
        "(status|result|response|answer|generic|category|classification|administrative|field|note|code|group|level|value|variable)", "")

    local name_key = ustrlower(ustrnormalize(`"`varname'"', "nfkc"))
    local name_key = ustrregexra(`"`name_key'"', "[^a-z0-9]+", "")
    local generic_name = ustrregexm(`"`name_key'"', ///
        "^(v|var|x|item|column|q|note|field)[0-9]+$")

    local sufficient = (`"`reduced'"' != "")
    if !`sufficient' & !`generic_name' {
        local name_reduced = ustrregexra(`"`name_key'"', ///
            "(status|result|response|answer|generic|category|classification|administrative|field|note|code|group|level|value|variable)", "")
        local sufficient = (`"`name_reduced'"' != "")
        if `sufficient' & `"`context'"' == "" {
            local context = ustrtitle(ustrregexra(`"`varname'"', "_+", " "))
        }
    }

    local category_complete = 0
    if ustrregexm(`"`name_key'"', ///
        "(infected|receives|doesnotreceive|owns|doesnotown|completed|didnotcomplete)") {
        local category_complete = 1
    }

    return scalar sufficient = `sufficient'
    return scalar category_complete = `category_complete'
    return local context `"`context'"'
end


program define _recode12_binary_context, rclass
    version 19.5
    syntax, VARNAME(string) [VARLABEL(string)]

    local context = ustrtrim(`"`varlabel'"')
    if `"`context'"' == "" {
        local context = ustrtitle(ustrregexra(`"`varname'"', "_+", " "))
    }
    local sufficient = 0
    local category1
    local category2

    if ustrregexm(`"`context'"', "(?i)^(.+?)\s+Coverage$") {
        local subject = ustrtrim(ustrregexs(1))
        local category1 `"No `subject'"'
        local category2 `"Has `subject'"'
        local sufficient = 1
    }
    else if ustrregexm(`"`context'"', "(?i)^(.+?)\s+Access$") {
        local subject = ustrtrim(ustrregexs(1))
        local category1 `"Has No Access to `subject'"'
        local category2 `"Has Access to `subject'"'
        local sufficient = 1
    }
    else if ustrregexm(`"`context'"', "(?i)^(.+?)\s+Service Status$") {
        local subject = ustrtrim(ustrregexs(1))
        local article
        if ustrlower(`"`subject'"') == "military" local article "the "
        local category1 `"Has Not Served in `article'`subject'"'
        local category2 `"Has Served in `article'`subject'"'
        local sufficient = 1
    }

    return scalar sufficient = `sufficient'
    return local category1 `"`category1'"'
    return local category2 `"`category2'"'
end


program define _recode12_directed_pair, rclass
    version 19.5
    syntax, KEYA(string) KEYB(string)

    local a `"`keya'"'
    local b `"`keyb'"'
    local directed = 0
    local negative
    local positive
    local family

    if (inlist(`"`a'"', "no", "false") & inlist(`"`b'"', "yes", "true")) | ///
       (inlist(`"`b'"', "no", "false") & inlist(`"`a'"', "yes", "true")) {
        local family yesno
        if inlist(`"`a'"', "no", "false") {
            local negative `"`a'"'
            local positive `"`b'"'
        }
        else {
            local negative `"`b'"'
            local positive `"`a'"'
        }
        local directed = 1
    }
    else if (inlist(`"`a'"', "fail", "failed") & ///
             inlist(`"`b'"', "pass", "passed")) | ///
            (inlist(`"`b'"', "fail", "failed") & ///
             inlist(`"`a'"', "pass", "passed")) {
        local family passfail
        if inlist(`"`a'"', "fail", "failed") {
            local negative `"`a'"'
            local positive `"`b'"'
        }
        else {
            local negative `"`b'"'
            local positive `"`a'"'
        }
        local directed = 1
    }
    else if (inlist(`"`a'"', "negative", "absent") & ///
             inlist(`"`b'"', "positive", "present")) | ///
            (inlist(`"`b'"', "negative", "absent") & ///
             inlist(`"`a'"', "positive", "present")) {
        local family polarity
        if inlist(`"`a'"', "negative", "absent") {
            local negative `"`a'"'
            local positive `"`b'"'
        }
        else {
            local negative `"`b'"'
            local positive `"`a'"'
        }
        local directed = 1
    }
    else if (inlist(`"`a'"', "ineligible", "noteligible", "noeligibility") & ///
             `"`b'"' == "eligible") | ///
            (inlist(`"`b'"', "ineligible", "noteligible", "noeligibility") & ///
             `"`a'"' == "eligible") {
        local family eligibility
        if `"`a'"' == "eligible" {
            local negative `"`b'"'
            local positive `"`a'"'
        }
        else {
            local negative `"`a'"'
            local positive `"`b'"'
        }
        local directed = 1
    }
    else if ((`"`a'"' == "notenrolled" & `"`b'"' == "enrolled") | ///
             (`"`b'"' == "notenrolled" & `"`a'"' == "enrolled")) {
        local family enrollment
        if `"`a'"' == "notenrolled" {
            local negative `"`a'"'
            local positive `"`b'"'
        }
        else {
            local negative `"`b'"'
            local positive `"`a'"'
        }
        local directed = 1
    }
    else if ((`"`a'"' == "notinfected" & `"`b'"' == "infected") | ///
             (`"`b'"' == "notinfected" & `"`a'"' == "infected")) {
        local family infection
        if `"`a'"' == "notinfected" {
            local negative `"`a'"'
            local positive `"`b'"'
        }
        else {
            local negative `"`b'"'
            local positive `"`a'"'
        }
        local directed = 1
    }
    else if ((`"`a'"' == "notlicensed" & `"`b'"' == "licensed") | ///
             (`"`b'"' == "notlicensed" & `"`a'"' == "licensed")) {
        local family licensed
        if `"`a'"' == "notlicensed" {
            local negative `"`a'"'
            local positive `"`b'"'
        }
        else {
            local negative `"`b'"'
            local positive `"`a'"'
        }
        local directed = 1
    }
    else if ((`"`a'"' == "nonmember" & `"`b'"' == "member") | ///
             (`"`b'"' == "nonmember" & `"`a'"' == "member")) {
        local family member
        if `"`a'"' == "nonmember" {
            local negative `"`a'"'
            local positive `"`b'"'
        }
        else {
            local negative `"`b'"'
            local positive `"`a'"'
        }
        local directed = 1
    }
    else if ((`"`a'"' == "denied" & `"`b'"' == "approved") | ///
             (`"`b'"' == "denied" & `"`a'"' == "approved")) {
        local family decision
        if `"`a'"' == "denied" {
            local negative `"`a'"'
            local positive `"`b'"'
        }
        else {
            local negative `"`b'"'
            local positive `"`a'"'
        }
        local directed = 1
    }
    else {
        local negroot
        local posroot
        foreach left in a b {
            local right = cond(`"`left'"' == "a", "b", "a")
            local lv ``left''
            local rv ``right''

            if substr(`"`lv'"', 1, 14) == "doesnotreceive" & ///
                substr(`"`rv'"', 1, 8) == "receives" & ///
                substr(`"`lv'"', 15, .) == substr(`"`rv'"', 9, .) {
                local directed = 1
                local family receipt
                local negative `"`lv'"'
                local positive `"`rv'"'
            }
            if substr(`"`lv'"', 1, 14) == "didnotcomplete" & ///
                substr(`"`rv'"', 1, 9) == "completed" & ///
                substr(`"`lv'"', 15, .) == substr(`"`rv'"', 10, .) {
                local directed = 1
                local family completion
                local negative `"`lv'"'
                local positive `"`rv'"'
            }
            if substr(`"`lv'"', 1, 10) == "doesnotown" & ///
                substr(`"`rv'"', 1, 4) == "owns" & ///
                substr(`"`lv'"', 11, .) == substr(`"`rv'"', 5, .) {
                local directed = 1
                local family ownership
                local negative `"`lv'"'
                local positive `"`rv'"'
            }
        }
    }

    return scalar directed = `directed'
    return local negative_key `"`negative'"'
    return local positive_key `"`positive'"'
    return local family `"`family'"'
end


program define _recode12_directed_labels, rclass
    version 19.5
    syntax, FAMILY(string) CONTEXT(string) ///
        NEGATIVEKEY(string) POSITIVEKEY(string) ///
        DISPLAYA(string) KEYA(string) ///
        DISPLAYB(string) KEYB(string)

    local negative_display `"`displaya'"'
    local positive_display `"`displayb'"'
    if `"`keya'"' == `"`positivekey'"' {
        local negative_display `"`displayb'"'
        local positive_display `"`displaya'"'
    }
    local negative_display = ustrtitle(ustrtrim(`"`negative_display'"'))
    local positive_display = ustrtitle(ustrtrim(`"`positive_display'"'))

    local negative_label `"`negative_display'"'
    local positive_label `"`positive_display'"'
    local clean_context = ustrtrim(`"`context'"')

    if `"`family'"' == "passfail" {
        if ustrregexm(`"`clean_context'"', "(?i)^(.+?)\s+Accreditation$") {
            local subject = ustrtrim(ustrregexs(1))
            local negative_label `"`subject' Has Not Been Accredited"'
            local positive_label `"`subject' Has Been Accredited"'
        }
        else {
            local subject = ustrregexra(`"`clean_context'"', "(?i)\s+Result$", "")
            local negative_label `"Failed `subject'"'
            local positive_label `"Passed `subject'"'
        }
    }
    else if `"`family'"' == "eligibility" {
        if ustrregexm(`"`clean_context'"', "(?i)^Eligibility\s+for\s+(.+)$") {
            local subject = ustrtrim(ustrregexs(1))
            local negative_label `"Not Eligible for `subject'"'
            local positive_label `"Eligible for `subject'"'
        }
    }
    else if `"`family'"' == "enrollment" {
        if ustrregexm(`"`clean_context'"', "(?i)^Enrollment\s+for\s+(.+)$") {
            local subject = ustrtrim(ustrregexs(1))
            local negative_label `"Not Enrolled in `subject'"'
            local positive_label `"Enrolled in `subject'"'
        }
    }
    else if `"`family'"' == "infection" {
        local negative_label "Not Infected"
        local positive_label "Infected"
    }
    else if `"`family'"' == "receipt" {
        if ustrregexm(`"`clean_context'"', "(?i)^Receipt\s+of\s+(.+)$") {
            local subject = ustrtrim(ustrregexs(1))
            local negative_label `"Does Not Receive `subject'"'
            local positive_label `"Receives `subject'"'
        }
    }
    else if `"`family'"' == "completion" {
        if ustrregexm(`"`clean_context'"', "(?i)^(.+?)\s+Completion") {
            local subject = ustrtrim(ustrregexs(1))
            local negative_label `"Did Not Complete `subject'"'
            local positive_label `"Completed `subject'"'
        }
    }
    else if inlist(`"`family'"', "yesno", "polarity", "licensed", ///
        "member", "decision") & `"`clean_context'"' != "" {
        local negative_label `"`negative_display': `clean_context'"'
        local positive_label `"`positive_display': `clean_context'"'
    }

    return local negative_label `"`negative_label'"'
    return local positive_label `"`positive_label'"'
end


program define _recode12_newname, rclass
    version 19.5
    syntax, SOURCE(name) SUFFIX(string)

    local suffix_length = strlen(`"`suffix'"')
    if `suffix_length' < 1 | `suffix_length' >= 32 {
        display as error "suffix() leaves no room for a source-derived name"
        exit 198
    }
    local base_length = 32 - `suffix_length'
    local base = substr(`"`source'"', 1, `base_length')
    local new `"`base'`suffix'"'
    confirm name `new'
    return local name `"`new'"'
end


capture mata: mata drop _recode12_scan_string()
capture mata: mata drop _recode12_scan_strings()
mata:
void _recode12_scan_strings(
    string scalar varlist,
    string scalar keyvarlist)
{
    string rowvector varnames
    string rowvector keyvarnames
    string matrix raw
    string colvector raw_col
    string colvector raw_levels
    string colvector display_levels
    string colvector lower_levels
    string colvector protected_levels
    string colvector matching_levels
    string colvector key_full
    string colvector nonmissing_keys
    real colvector missing_levels
    real colvector indices
    real colvector second_indices
    real colvector numericflag
    real colvector level_indices
    real scalar n_reserved
    real scalar n_nonmissing
    real scalar n_keys
    real scalar n_12
    real scalar invalid_numeric_string
    string scalar first_key
    string scalar second_key
    string scalar first_display
    string scalar second_display
    real scalar batch_start
    real scalar batch_end
    real scalar batch_column
    real scalar global_column
    real scalar level_index
    real scalar first_level
    real scalar second_level
    real scalar n_variables
    real scalar batch_width
    string scalar suffix

    varnames = tokens(varlist)
    keyvarnames = tokens(keyvarlist)
    n_variables = cols(varnames)
    if (n_variables == 0) return
    if (cols(keyvarnames) != n_variables) {
        errprintf("internal string-key allocation mismatch\n")
        exit(498)
    }
    if (st_nobs() == 0) batch_width = n_variables
    else {
        batch_width = min((n_variables, ///
            max((1, floor(250000 / st_nobs())))))
    }

    for (batch_start = 1; batch_start <= n_variables; ///
        batch_start = batch_start + batch_width) {
        batch_end = min((batch_start + batch_width - 1, n_variables))
        raw = st_sdata(., varnames[1, batch_start..batch_end])

        for (batch_column = 1; batch_column <= cols(raw); batch_column++) {
            global_column = batch_start + batch_column - 1
            suffix = strofreal(global_column)
            raw_col = raw[, batch_column]
            raw_levels = uniqrows(sort(raw_col, 1))
            display_levels = ustrtrim(ustrnormalize(raw_levels, "nfkc"))
            lower_levels = ustrlower(display_levels)
            protected_levels = ustrregexra(lower_levels, ///
                "[\p{Z}\s]+", "")
            matching_levels = ustrregexra(lower_levels, ///
                "[\p{Z}\s\p{P}\p{S}]+", "")
            missing_levels = (display_levels :== "") :| ///
                (protected_levels :== ".")
            n_reserved = sum(ustrregexm(protected_levels, ///
                "^\.[a-z]$"))
            nonmissing_keys = select(matching_levels, ///
                missing_levels :== 0)
            n_keys = 0
            n_nonmissing = 0
            n_12 = 0
            invalid_numeric_string = 0
            first_key = ""
            second_key = ""
            first_display = ""
            second_display = ""

            if (rows(nonmissing_keys) > 0) {
                n_keys = rows(uniqrows(sort(nonmissing_keys, 1)))
                numericflag = ustrregexm(nonmissing_keys, ///
                    "^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)([eE][+-]?[0-9]+)?$")
                invalid_numeric_string = ///
                    sum(numericflag :& (nonmissing_keys :!= "1") :& ///
                        (nonmissing_keys :!= "2")) > 0
                if (n_keys == 2 & n_reserved == 0) {
                    key_full = J(rows(raw_col), 1, "")
                    for (level_index = 1; ///
                        level_index <= rows(raw_levels); ///
                        level_index++) {
                        if (missing_levels[level_index]) continue
                        level_indices = selectindex(raw_col :== ///
                            raw_levels[level_index])
                        key_full[level_indices, 1] = ///
                            J(rows(level_indices), 1, ///
                                matching_levels[level_index])
                    }
                    indices = selectindex(key_full :!= "")
                    n_nonmissing = rows(indices)
                    n_12 = sum((key_full :== "1") :| ///
                        (key_full :== "2"))
                    first_key = key_full[indices[1]]
                    level_indices = selectindex(raw_levels :== ///
                        raw_col[indices[1]])
                    first_level = level_indices[1]
                    first_display = display_levels[first_level]
                    second_indices = selectindex((key_full :!= "") :& ///
                        (key_full :!= first_key))
                    if (rows(second_indices) > 0) {
                        second_key = key_full[second_indices[1]]
                        level_indices = selectindex(raw_levels :== ///
                            raw_col[second_indices[1]])
                        second_level = level_indices[1]
                        second_display = display_levels[second_level]
                    }
                    (void) st_addvar("strL", ///
                        keyvarnames[global_column])
                    st_sstore(., keyvarnames[global_column], key_full)
                }
            }

            st_local("scan_n_reserved" + suffix, ///
                strofreal(n_reserved, "%18.0f"))
            st_local("scan_n_nonmissing" + suffix, ///
                strofreal(n_nonmissing, "%18.0f"))
            st_local("scan_n_keys" + suffix, ///
                strofreal(n_keys, "%18.0f"))
            st_local("scan_n_12" + suffix, strofreal(n_12, "%18.0f"))
            st_local("scan_invalid_numeric_string" + suffix, ///
                strofreal(invalid_numeric_string, "%18.0f"))
            st_local("scan_first_key" + suffix, first_key)
            st_local("scan_second_key" + suffix, second_key)
            st_local("scan_first_display" + suffix, first_display)
            st_local("scan_second_display" + suffix, second_display)
        }
    }
}
end
