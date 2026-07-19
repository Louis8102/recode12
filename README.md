# recode12 1.1.0

## Overview

`recode12` is a Stata module for standardizing eligible numeric variables coded 1/2 and eligible two-category string variables as labeled 0/1 indicators. For a string variable, its first and second distinct nonmissing categories are treated as the counterparts of numeric source codes 1 and 2. The module therefore applies the same mapping logic to both storage types, automates a routine but consequential data-management step, assigns uniform No/Yes value labels, and verifies every converted value.

The same concise syntax handles three common situations: eligible numeric variables only, eligible string variables only, or both types in the same dataset.

## Installation and example data

Version 1.1.0 is an updated GitHub release and has not yet been accepted as an SSC update. Install it from GitHub:

```stata
net install recode12, from("https://raw.githubusercontent.com/Louis8102/recode12/main") replace
```

Retrieve the updated example data and do-files:

```stata
net get recode12, from("https://raw.githubusercontent.com/Louis8102/recode12/main") replace
```

Load the example dataset:

```stata
use recode12_example_data.dta, clear
```

## Eligible variables

An eligible numeric variable contains both 1 and 2, may contain ordinary system missing (`.`), and contains no other values. A variable containing only `1` plus `.`, only `2` plus `.`, an extended missing value such as `.m` or `.n`, any other numeric value, or no nonmissing observations is ineligible.

An eligible string variable contains exactly two distinct nonmissing categories, and both must be observed. For string-variable eligibility, `recode12` treats an empty string, a whitespace-only string, and the trimmed literal string `"."` as missing. It scans observations in their current order, ignores these missing representations and repeated categories, treats the first distinct nonmissing category as source category 1, and treats the second as source category 2. A variable containing only one category plus missing values, no nonmissing categories, or any additional distinct value—including markers such as `m`, `n`, `.m`, or `.n`—is skipped.

For example, the sequence `"."`, `Plum`, blank, `Plum`, `Peach` defines `Plum` as source category 1 and `Peach` as source category 2; the dot and blank are preserved as missing in the numeric result. Sorting the dataset before recoding may therefore change string-category order.

## Use

Only eligible numeric variables:

```stata
recode12 female employed, yesvalue(2)
```

Only eligible string variables:

```stata
recode12 exam_result_text preferred_fruit, yesvalue(2)
```

Eligible numeric and string variables together:

```stata
recode12 female employed exam_result_text preferred_fruit, yesvalue(2)
```

If the variable list is omitted, every variable is examined and only eligible numeric and string variables are processed:

```stata
recode12, yesvalue(2)
```

The character-string rule corresponds directly to the numeric rule. Numeric
source values 1 and 2 are literal. For a string variable, its first and second
distinct nonmissing categories are treated as the counterparts of numeric source
values 1 and 2. The same `yesvalue()` is then applied to both types, with no
separate string mapping:

```text
yesvalue(1): source category 1 -> 1 (Yes); source category 2 -> 0 (No)
yesvalue(2): source category 1 -> 0 (No);  source category 2 -> 1 (Yes)
```

For numeric variables, source categories 1 and 2 are the literal values 1 and 2. For string variables, they are the first and second distinct nonmissing categories encountered. The command does not infer whether a category is affirmative, negative, favorable, or unfavorable.

## Output and verification

By default, each source variable remains unchanged and a new numeric byte variable with suffix `_01` is created. Every result uses the value label `recode12_NoYes`, defining 0 as `No` and 1 as `Yes`. The variable label begins with `Recoded`, identifies the category mapped to 1, and states `(0=No; 1=Yes)`.

Use `suffix()` to choose another suffix:

```stata
recode12 employed exam_result_text, yesvalue(2) suffix(_indicator)
```

Use `replace` only when the eligible source variables should be overwritten by their numeric 0/1 results:

```stata
recode12 employed exam_result_text, yesvalue(2) replace
```

For a string source, `replace` changes the variable to numeric while retaining its name. `replace` cannot be combined with `suffix()`.

After recoding, the command verifies the selected mapping, preservation of missing observations, and the 0/1 range. Only after every check passes does it create or update `recode12_status` with `confirmed`. This confirms computational consistency, not the substantive suitability of the chosen direction.

By default, the Results window displays only the mapping rule and the verification result. Add `display` to report numeric and string-source results separately, including the number standardized and their resulting variable names:

```stata
recode12, yesvalue(2) display
```

In `display` mode, resulting names are printed in groups of no more than seven per line. Under `replace`, the displayed names are the retained source-variable names. The same detailed results are always available in `r()` whether or not `display` is specified.

## Requirements and verification

- StataNow 19.5
- Numeric-only, string-only, mixed-type, all-variable, generated-variable, `suffix()`, `replace`, missing-value, ineligible-variable, mapping, label, stored-result, example-data, and regression tests are included.

## Version history

- **1.1.0 (19 July 2026):** Added eligible two-category string variables, mixed numeric/string processing, first-occurrence string category ordering, explicit string-missing rules, and type-specific stored results. The original numeric 1/2 eligibility and `yesvalue()` mapping rules remain unchanged.
- **1.0.0 (12 July 2026):** Initial SSC release for eligible numeric variables coded 1/2.

## Citation

> Ma, Hao. 2026. “recode12: A Stata command for standardizing numeric 1/2 variables and corresponding two-category string variables as labeled 0/1 indicators.” Version 1.1.0.

## Author

Hao Ma  
Email: [shouhuoxiwang2027@gmail.com](mailto:shouhuoxiwang2027@gmail.com)

## License

This project is released under the [MIT License](LICENSE). Copyright © 2026 Hao Ma.
