{smcl}
{* *! version 1.0.0  12jul2026}{...}
{vieweralsosee "recode" "help recode"}{...}
{vieweralsosee "label values" "help label_values"}{...}
{title:Title}

{phang}
{bf:recode12} {hline 2} Standardize 1/2-coded binary variables as labeled 0/1 indicators

{title:Syntax}

{p 8 17 2}
{cmd:recode12} [{varlist}] [{cmd:,} {opt yesvalue(#)} {opt suffix(name)} {opt replace}]

{title:Installation}

{phang2}{cmd:. net install recode12, from("https://raw.githubusercontent.com/Louis8102/recode12/main") replace}{p_end}

{pstd}
To retrieve the example dataset and example do-file:

{phang2}{cmd:. net get recode12, from("https://raw.githubusercontent.com/Louis8102/recode12/main") replace}{p_end}

{title:Description}

{pstd}
{cmd:recode12} identifies numeric variables whose observed nonmissing values are
exactly 1 and 2. Numeric missing values, including extended missing values, are
allowed. Variables containing any other nonmissing value, variables containing
only one of the two values, and variables containing no nonmissing observations
are skipped.

{pstd}
For each eligible variable, {cmd:recode12} maps the source value selected by
{opt yesvalue()} to 1 and the other source value to 0, preserves numeric missing
values, and assigns the value label 0 {it:No} and 1 {it:Yes}. The default is
{cmd:yesvalue(1)}. By default, it creates a new byte variable and leaves the
source variable unchanged.

{pstd}
If {it:varlist} is omitted, all numeric variables in the dataset are examined.

{title:Options}

{phang}
{opt yesvalue(#)} specifies which source value becomes 1 ({it:Yes}). The
argument must be 1 or 2. The default is {cmd:yesvalue(1)}. Specify
{cmd:yesvalue(2)} to map source value 2 to 1 and source value 1 to 0.

{phang}
{opt suffix(name)} specifies the suffix for generated variables. The default is
{cmd:suffix(_01)}. The resulting name must be a legal, unused Stata variable
name.

{phang}
{opt replace} changes eligible source variables in place. It may not be combined
with {opt suffix()}. Because this operation overwrites values and replaces the
attached value label, users should normally retain the default behavior.

{title:Remarks}

{pstd}
The command determines eligibility from values, not from the meaning of a
variable. The category selected by {opt yesvalue()} becomes the Yes/true
category, and the other category becomes the No/false category. The variable
name or variable label should state the proposition represented by the selected
source value.

{pstd}
For example, if {cmd:sex} is coded 1 Female and 2 Male, {cmd:yesvalue(1)}
generates 1 for Female and 0 for Male, whereas {cmd:yesvalue(2)} generates 1 for
Male and 0 for Female. {cmd:recode12} preserves the source variable label but
does not infer or rewrite its meaning.

{pstd}
The shared value label is named {cmd:recode12_NoYes}. If a label with that name
already exists, it must define 0 as {it:No} and 1 as {it:Yes}; otherwise the
command stops without recoding variables.

{title:Examples}

{pstd}
After retrieving the ancillary files with {cmd:net get}, the example dataset
supplied with this package can be loaded as follows:

{phang2}{cmd:. use example_data.dta, clear}{p_end}
{phang2}{cmd:. recode12}{p_end}

{phang2}{cmd:. recode12 married employed insured}{p_end}
{phang2}{cmd:. recode12}{p_end}
{phang2}{cmd:. recode12 male white married, suffix(_bin)}{p_end}
{phang2}{cmd:. recode12 female, yesvalue(2) suffix(_male)}{p_end}
{phang2}{cmd:. recode12 married employed, replace}{p_end}
{phang2}{cmd:. recode12 female, yesvalue(2) replace}{p_end}

{title:Stored results}

{pstd}
{cmd:recode12} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{synopt:{cmd:r(n_recoded)}}number of variables recoded{p_end}
{synopt:{cmd:r(yesvalue)}}source value mapped to 1 ({it:Yes}){p_end}
{synopt:{cmd:r(recoded)}}generated or replaced variables{p_end}
{synopt:{cmd:r(source)}}eligible source variables{p_end}
{synopt:{cmd:r(skipped)}}examined variables not meeting the rule{p_end}
{synopt:{cmd:r(value_label)}}name of the attached value label{p_end}

{title:Author}

{pstd}
Hao Ma{break}
Email: {browse "mailto:shouhuoxiwang2021@gmail.com":shouhuoxiwang2021@gmail.com}

{title:Also see}

{psee}
Manual: {manhelp recode D}, {manhelp label D}
