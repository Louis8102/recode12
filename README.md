# recode12 1.0.0

## Overview

`recode12` is a Stata module for standardizing variables coded 1/2 as labeled 0/1 indicators. This is a routine but consequential data-management task: inconsistent mappings can reverse the meaning of an indicator and affect summaries, models, and interpretation.

The module identifies eligible variables, applies an explicitly specified mapping, preserves ordinary system missing values, assigns uniform No/Yes value labels, and verifies the results after recoding. It can process one variable, several variables, or all eligible numeric variables in a dataset. The required `yesvalue()` option records the mapping directly in the command for reproducible workflows.

## Installation and example data

Install the module directly from GitHub:

```stata
net install recode12, from("https://raw.githubusercontent.com/Louis8102/recode12/main") replace
```

Retrieve the example dataset and example do-files:

```stata
net get recode12, from("https://raw.githubusercontent.com/Louis8102/recode12/main") replace
```

Load the example dataset:

```stata
use example_data.dta, clear
```

## Eligible variables

A variable is eligible for recoding when it is numeric, its nonmissing values consist of both 1 and 2 and no other values, and any missing observations are ordinary system missing (`.`).

Variables that do not meet this rule are skipped and left unchanged. Eligibility is determined entirely from the observed values; the module does not infer substantive meaning from a variable's name or label.

## Reproducible use

For do-files, batch jobs, and reproducible analysis, specify which source value should become Yes/1 with `yesvalue()`.

```stata
recode12 employed owns_home insured, yesvalue(2)
```

This maps source 1 to No/0 and source 2 to Yes/1.

```stata
recode12 female, yesvalue(1)
```

This maps source 1 to Yes/1 and source 2 to No/0.

If the variable list is omitted, all numeric variables are examined and only eligible variables are processed:

```stata
recode12, yesvalue(2)
```

## Output and options

By default, `recode12` leaves each source variable unchanged and creates a new byte variable with the neutral suffix `_01`. Every generated variable uses the shared value label `recode12_NoYes`, defining 0 as `No` and 1 as `Yes`. Its variable label begins with `Recoded`, names the source category mapped to Yes/1, and ends with `(0=No; 1=Yes)`. For example, under `yesvalue(2)`, `Children (1=No children, 2=Has children)` produces `Recoded Has children (0=No; 1=Yes)`. If the selected source value has no category label, the generated label states the numeric condition explicitly, such as `Recoded x == 1 (0=No; 1=Yes)`.

```stata
recode12 employed owns_home, yesvalue(2) suffix(_indicator)
```

Use `replace` only when the eligible source variables should be changed in place:

```stata
recode12 employed owns_home, yesvalue(2) replace
```

`replace` cannot be combined with `suffix()`.

After recoding, the command verifies the mapping, preservation of ordinary system missing values, and the 0/1 range before reporting success. Only after every check passes, it creates or updates the string variable `recode12_status` and fills it with `confirmed` for every observation. If verification fails, the command reports an error and does not write `confirmed`. This status confirms computational consistency with the specified mapping; it does not establish that the selected direction is substantively correct for the research question. Results are returned in `r()`; see `help recode12` for the complete list.

## Requirements and verification

- StataNow 19.5
- Tested with StataNow/MP 19.5 on 12 July 2026
- Mapping, missing values, skipped variables, `suffix()`, `replace`, invalid options, stored results, example execution, `net install`, and `net get` were tested.

## Citation

If you use `recode12` in published work, please cite:

> Ma, Hao. 2026. “recode12: A Stata command for standardizing 1/2-coded variables as labeled 0/1 indicators.” Version 1.0.0.

GitHub-compatible citation metadata are provided in [`CITATION.cff`](CITATION.cff).

## Author

Hao Ma  
Email: [shouhuoxiwang2027@gmail.com](mailto:shouhuoxiwang2027@gmail.com)

## License

This project is released under the [MIT License](LICENSE). Copyright © 2026 Hao Ma.
