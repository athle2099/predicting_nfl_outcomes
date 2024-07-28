* The Massey scores are calculated after each week, so are stored in "weekssofar". For predicting, the week we predict is the week after "weekssofar", hence we need to shift up by a week and shift the year for end-of-season scores.

import delimited "...\weeklyMasseyRAW.csv"

sort year weekssofar teamid
gen week = weekssofar + 1 // correspond with the actual week
* now the weeks are 2-22 before 2021, and 2-23 afer 2021, so we can manually put week 22/23 as week 1 uniquely, then move the year forward
replace week = 1 if week == 22 & year < 2021
replace week = 1 if week == 23 & year >= 2021
replace year = year + 1 if week == 1

drop weekssofar
order year week teamid
sort year week teamid

save "...\weeklyMasseyCLEAN.dta", replace
