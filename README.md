# recode12 1.0.3

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

## What recode12 does

`recode12` performs one of the most common data-management operations in data science: it converts variables coded 1/2 into labeled 0/1 indicators.

The command can process one variable, several variables, or—when no variable list is supplied—all numeric variables in the dataset.

### Variables that are processed

A numeric variable is processed only when:

- every observation is 1, 2, or ordinary system missing (`.`); and
- both 1 and 2 are observed among its nonmissing values.

### Variables that are not processed

A variable is skipped when it:

- contains an extended missing value (`.a`–`.z`);
- contains any numeric value other than 1, 2, or `.`;
- contains only one of the two values 1 and 2;
- contains no nonmissing observations; or
- is a string variable when the command examines the dataset automatically.

This rule is determined entirely from the observed values. The command does not infer the substantive meaning of a variable from its name or label.

## Direct, reproducible use

For do-files, batch jobs, and reproducible analysis, specify which source value should become Yes/1 with `yesvalue()`.

```stata
recode12 married employed insured, yesvalue(2)
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

## Interactive use

The module can also be used interactively. Omit `yesvalue()` and choose one of the two complete recoding rules shown on screen:

```stata
recode12 married employed insured
```

```text
Please choose the recoding rule:

1 - Source 1 -> 0 (No);  Source 2 -> 1 (Yes)
2 - Source 1 -> 1 (Yes); Source 2 -> 0 (No)

Enter rule 1 or 2 [default 1]:
```

- Rule 1 maps source 1 to No/0 and source 2 to Yes/1.
- Rule 2 maps source 1 to Yes/1 and source 2 to No/0.
- Pressing Enter selects rule 1.

## Output and options

By default, `recode12` leaves each source variable unchanged and creates a new byte variable with the neutral suffix `_01`. Generated variables receive the shared value label `recode12_NoYes`, which defines 0 as No and 1 as Yes.

```stata
recode12 married employed, yesvalue(2) suffix(_indicator)
```

Use `replace` only when the eligible source variables should be changed in place:

```stata
recode12 married employed, yesvalue(2) replace
```

`replace` cannot be combined with `suffix()`.

After recoding, the command verifies the mapping, preservation of ordinary system missing values, and the 0/1 range before reporting success. Results are returned in `r()`; see `help recode12` for the complete list.

## Requirements and verification

- StataNow 19.5
- Tested with StataNow/MP 19.5 on 12 July 2026
- Mapping, missing values, skipped variables, `suffix()`, `replace`, invalid options, stored results, example execution, `net install`, and `net get` were tested.

## Citation

If you use `recode12` in published work, please cite:

> Ma, Hao. 2026. “recode12: A Stata command for standardizing 1/2-coded variables as labeled 0/1 indicators.” Version 1.0.3.

GitHub-compatible citation metadata are provided in [`CITATION.cff`](CITATION.cff).

## Author

Hao Ma  
Email: [shouhuoxiwang2027@gmail.com](mailto:shouhuoxiwang2027@gmail.com)

## License

This project is released under the [MIT License](LICENSE). Copyright © 2026 Hao Ma.
