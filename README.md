# recode12 1.0.0

`recode12` is a Stata utility for standardizing 1/2-coded binary variables as
0/1 indicators with a common No/Yes value label.

## What the command does

For every numeric variable requested, `recode12` verifies that:

- both nonmissing values 1 and 2 are observed; and
- no other nonmissing numeric value is observed.

With the default `yesvalue(1)`, variables satisfying both conditions are mapped
as follows:

| Source value | Result | Displayed label |
|---:|---:|---|
| 1 | 1 | Yes |
| 2 | 0 | No |
| `.`, `.a`–`.z` | unchanged | missing |

Variables containing only 1, only 2, only missing values, or any other
nonmissing value are skipped. If no varlist is supplied, the command examines
all numeric variables and ignores string variables.

By default, new byte variables are generated with suffix `_01`; source
variables remain unchanged. The `replace` option must be specified explicitly
to change source variables in place.

Coding direction is user-selectable. `yesvalue(1)` maps source value 1 to
Yes/1; `yesvalue(2)` maps source value 2 to Yes/1 and source value 1 to No/0.

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
recode12
return list
```

Stata classifies the dataset and example do-file as ancillary files. Retrieve
them from GitHub with:

```stata
net get recode12, from("https://raw.githubusercontent.com/Louis8102/recode12/main") replace
```

To examine only named variables and choose another suffix:

```stata
recode12 female married employed insured, suffix(_bin)
```

To make the category originally coded 2 the Yes/1 category:

```stata
recode12 female, yesvalue(2) suffix(_male)
```

To overwrite eligible source variables intentionally:

```stata
recode12 married employed insured, replace
```

Common goals can therefore be expressed directly:

| Goal | Command |
|---|---|
| Scan all numeric variables; source 1 becomes Yes/1 | `recode12` |
| Recode only selected variables | `recode12 female married employed` |
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
`r(yesvalue)`, and the common value-label name is returned in `r(value_label)`.

## Distribution files

- `recode12.ado` — command implementation
- `recode12.sthlp` — official Stata help file
- `recode12.pkg` and `stata.toc` — net-install metadata
- `example_data.dta` — 10,000-observation simulated example dataset covering
  eligible and ineligible coding patterns, numeric storage types, ordinary and
  extended missing values, labels, continuous values, and a string variable
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
