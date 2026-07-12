# recode12 1.0.0

`recode12` is a Stata utility for standardizing 1/2-coded binary variables as
0/1 indicators with a common No/Yes value label.

## What the command does

For every numeric variable requested, `recode12` verifies that:

- both nonmissing values 1 and 2 are observed; and
- no other nonmissing numeric value is observed.

Variables satisfying both conditions are mapped as follows:

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

## Installation

From a local distribution directory containing `stata.toc`, type:

```stata
net install recode12, from("C:/path/to/distribution")
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

In a net repository, Stata classifies the dataset and example do-file as
ancillary files. Retrieve them with `net get recode12` from that repository.

To examine only named variables and choose another suffix:

```stata
recode12 female married employed insured, suffix(_bin)
```

To overwrite eligible source variables intentionally:

```stata
recode12 married employed insured, replace
```

## Interpretation

The source category coded 1 becomes the Yes/true category; the source category
coded 2 becomes the No/false category. A variable name or variable label should
therefore state what value 1 represents. For example, a variable labeled
`Respondent is female` can be displayed as 0 No and 1 Yes.

The command identifies coding patterns from observed values. It does not infer
the substantive meaning of a variable and does not rewrite its variable label.

## Returned results

`recode12` returns the number of converted variables in `r(n_recoded)` and the
converted, source, and skipped variable lists in `r(recoded)`, `r(source)`, and
`r(skipped)`. The common value-label name is returned in `r(value_label)`.

## Distribution files

- `recode12.ado` — command implementation
- `recode12.sthlp` — official Stata help file
- `recode12.pkg` and `stata.toc` — net-install metadata
- `example_data.dta` — example dataset
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
