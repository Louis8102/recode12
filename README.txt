recode12 version 1.0.1 (20jul2026)

Files
-----
recode12.ado        Command implementation
recode12.sthlp      Stata help file
recode12.pkg        Package manifest for net install/net get
stata.toc           Stata download-site index
recode12_example.do Reproducible usage example
recode12_test.do    Automated functional tests

Installation from this directory
--------------------------------
net install recode12, from("path/to/recode12-revised") replace

To retrieve ancillary do-files
------------------------------
net get recode12, from("path/to/recode12-revised") replace

Verification
------------
Tested with StataNow/MP 19.5 for the 20 July 2026 release. Functional mapping,
missing-value handling, skipped variables, suffix(), replace, invalid options,
stored results, example execution, net install, and net get all passed.

Interactive input
-----------------
At the Results-window prompt, rule 1 maps source 1 to No/0 and source 2 to
Yes/1; rule 2 maps source 1 to Yes/1 and source 2 to No/0. Pressing Enter
defaults to rule 1.
For do-files and batch jobs, specify yesvalue(1) or yesvalue(2).
