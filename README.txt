recode12 version 1.0.3 (12jul2026)

License
-------
MIT License. Copyright (c) 2026 Hao Ma.

Citation
--------
If you use recode12 in published work, please cite:

Ma, Hao. 2026. "recode12: A Stata command for standardizing 1/2-coded binary
variables as labeled 0/1 indicators." Version 1.0.3.

Changes in 1.0.3
----------------
- Added the MIT License and machine-readable CITATION.cff metadata.
- Added citation and license information to the README and Stata help file.

Changes in 1.0.2
----------------
- The interactive prompt now explicitly selects a recoding rule:
  rule 1 maps source 1 to 0 and source 2 to 1;
  rule 2 maps source 1 to 1 and source 2 to 0.
- The default interactive selection is rule 1.
- Generated variable names use the neutral default suffix _01.
- Generated variable labels state the source variable and selected Yes value.
- Contact email corrected to shouhuoxiwang2027@gmail.com.
- Program, help, examples, package metadata, and tests synchronized for
  StataNow 19.5.

Files
-----
recode12.ado        Command implementation
recode12.sthlp      Stata help file
recode12.pkg        Package manifest for net install/net get
stata.toc           Stata download-site index
recode12_example.do Reproducible usage example
recode12_test.do    Automated functional tests
LICENSE             MIT License
CITATION.cff        Citation metadata for GitHub and reference managers

Installation from this directory
--------------------------------
net install recode12, from("path/to/recode12-revised") replace

To retrieve ancillary do-files
------------------------------
net get recode12, from("path/to/recode12-revised") replace

Verification
------------
Tested with StataNow/MP 19.5 on 12 July 2026. Functional mapping,
missing-value handling, skipped variables, suffix(), replace, invalid options,
stored results, example execution, net install, and net get all passed.

Interactive input
-----------------
At the Results-window prompt, rule 1 maps source 1 to No/0 and source 2 to
Yes/1; rule 2 maps source 1 to Yes/1 and source 2 to No/0. Pressing Enter
defaults to rule 1.
For do-files and batch jobs, specify yesvalue(1) or yesvalue(2).
