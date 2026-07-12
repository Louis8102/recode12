# recode12 1.0.0

`recode12` is a Stata utility for standardizing 1/2-coded binary variables as
0/1 indicators with a common No/Yes value label.

## What the command does

`recode12` processes numeric variables whose values are 1, 2, or ordinary
system missing (`.`), with both 1 and 2 observed. Variables containing extended
missing values (`.a`–`.z`), other numeric values, only one category, or no
nonmissing observations are skipped.

The command accepts one variable, several variables, or all numeric variables:

```stata
recode12 female
recode12 female married employed
recode12
```

If `yesvalue()` is omitted, the user chooses the mapping before processing:

```text
Please choose the mapping rule:

1 - Source 1 -> 0 (No);  Source 2 -> 1 (Yes)
2 - Source 1 -> 1 (Yes); Source 2 -> 0 (No)

Enter 1 or 2 [default 1]:
```

Pressing Enter selects rule 1. In a do-file or batch job, bypass the menu with
`yesvalue(1)` or `yesvalue(2)`.

By default, new byte variables are created with suffix `_01`; source variables
remain unchanged. Use `suffix()` to choose another suffix or `replace` to modify
eligible source variables in place. Every conversion is verified against the
selected mapping before success is reported.

## Installation

Install the current release directly from GitHub:

```stata
net install recode12, from("https://raw.githubusercontent.com/Louis8102/recode12/main") replace
```

After installation, open the complete help file with:

```stata
help recode12
```

## Quick example

When working from the distribution directory, type:

```stata
use example_data.dta, clear
recode12, yesvalue(2)
return list
```

Stata classifies the dataset and example do-file as ancillary files. Retrieve
them from GitHub with:

```stata
net get recode12, from("https://raw.githubusercontent.com/Louis8102/recode12/main") replace
```

Common goals:

| Goal | Command |
|---|---|
| Scan all numeric variables and choose on screen | `recode12` |
| Recode one variable and choose on screen | `recode12 female` |
| Recode several variables and choose on screen | `recode12 female married employed` |
| Source 2 becomes Yes/1 | `recode12 female, yesvalue(2)` |
| Use a custom suffix | `recode12 female, suffix(_bin)` |
| Source 2 becomes Yes/1 with a custom suffix | `recode12 female, yesvalue(2) suffix(_male)` |
| Overwrite eligible source variables | `recode12 female married, replace` |
| Overwrite and make source 2 Yes/1 | `recode12 female, yesvalue(2) replace` |

## Interpretation

The source category selected by `yesvalue()` becomes the Yes/true category; the
other source category becomes No/false. A variable name or variable label should
state what the selected source category represents.

The command identifies coding patterns from observed values. It does not infer
the substantive meaning of a variable and does not rewrite its variable label.

## Returned results

`recode12` returns the number of converted variables in `r(n_recoded)` and the
converted, source, and skipped variable lists in `r(recoded)`, `r(source)`, and
`r(skipped)`. The selected source value mapped to Yes/1 is returned in
`r(yesvalue)`, successful verification is returned as `r(verified)=1`, and the
common value-label name is returned in `r(value_label)`.

## Distribution files

- `recode12.ado` — command implementation
- `recode12.sthlp` — official Stata help file
- `recode12.pkg` and `stata.toc` — net-install metadata
- `example_data.dta` — 10,000-observation simulated example dataset containing
  22 eligible 1/2-coded binary variables (including `item01`–`item20`) plus
  ineligible coding patterns, multiple numeric storage types, ordinary and
  extended missing values (the latter intentionally skipped), labels,
  continuous values, and a string variable
- `recode12_examples.do` — reproducible examples
- `recode12_test.do` — functional and boundary tests
- `README.md` — distribution overview

## Requirements

Stata 16 or newer. The release was executed and verified under StataNow 19.5 MP.

## Author

Hao Ma  
Email: shouhuoxiwang2021@gmail.com

## Suggested citation

Ma, Hao. 2026. *recode12: Stata module to standardize 1/2-coded binary
variables as labeled 0/1 indicators*. Version 1.0.0.
