# recode12 1.0.3

`recode12` is a Stata command for standardizing 1/2-coded binary variables as labeled 0/1 indicators.

## What the command does

The command processes numeric variables whose values are 1, 2, or ordinary system missing (`.`), with both 1 and 2 observed. Variables containing extended missing values (`.a`–`.z`), other numeric values, only one category, or no nonmissing observations are skipped.

```stata
recode12 female
recode12 female married employed
recode12
```

## Interactive mapping

If `yesvalue()` is omitted, the command displays two complete recoding rules:

```text
Please choose the recoding rule:

1 - Source 1 -> 0 (No);  Source 2 -> 1 (Yes)
2 - Source 1 -> 1 (Yes); Source 2 -> 0 (No)

Enter rule 1 or 2 [default 1]:
```

- Rule 1 maps source 1 to No/0 and source 2 to Yes/1.
- Rule 2 maps source 1 to Yes/1 and source 2 to No/0.
- Pressing Enter selects rule 1.

For reproducible do-files and batch jobs, specify the mapping explicitly:

```stata
recode12 married employed, yesvalue(2)
recode12 female, yesvalue(1)
```

## Installation

```stata
net install recode12, from("https://raw.githubusercontent.com/Louis8102/recode12/main") replace
```

To retrieve the example and test do-files:

```stata
net get recode12, from("https://raw.githubusercontent.com/Louis8102/recode12/main") replace
```

## Options

- `yesvalue(1)` maps source 1 to Yes/1 and source 2 to No/0.
- `yesvalue(2)` maps source 1 to No/0 and source 2 to Yes/1.
- `suffix(name)` selects a suffix for generated variables; the neutral default is `_01`.
- `replace` recodes eligible source variables in place and cannot be combined with `suffix()`.

## Requirements and verification

- StataNow 19.5
- Tested with StataNow/MP 19.5 on 12 July 2026
- Mapping, missing values, skipped variables, `suffix()`, `replace`, invalid options, stored results, example execution, `net install`, and `net get` were tested.

## Citation

If you use `recode12` in published work, please cite:

> Ma, Hao. 2026. “recode12: A Stata command for standardizing 1/2-coded binary variables as labeled 0/1 indicators.” Version 1.0.3.

GitHub-compatible citation metadata are provided in [`CITATION.cff`](CITATION.cff).

## Author

Hao Ma  
Email: [shouhuoxiwang2027@gmail.com](mailto:shouhuoxiwang2027@gmail.com)

## License

This project is released under the [MIT License](LICENSE). Copyright © 2026 Hao Ma.

## Changes in 1.0.3

- Clarified the interactive rule selection and default.
- Kept generated names neutral and made generated labels state the selected mapping.
- Added the MIT License and `CITATION.cff`.
- Corrected the contact email.
- Synchronized the program, help, package metadata, examples, and tests.
