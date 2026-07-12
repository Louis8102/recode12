version 19.5
clear
input byte(id female employed insured)
1 1 2 1
2 2 1 2
3 1 1 .
4 2 2 1
end

label variable female   "Sex: 1 Female, 2 Male"
label variable employed "Employment: 1 No, 2 Yes"
label variable insured  "Insurance: 1 No, 2 Yes"

* Noninteractive use recommended for reproducible do-files.
recode12 female, yesvalue(1)
recode12 employed insured, yesvalue(2)

list, separator(0)
return list
