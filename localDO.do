* This file is to merge all relevant data for the local model to export to a .csv file for the boosting method. It combines predicted rosters, the weekly masseys, rhinos, and quarterback epas, all on top of the game matchups and the game information stored in "spreadsCLEAN".

* We first need to transform the predicted rosters per the paper.
import delimited "...\predictedRosters.csv"

rename team_number teamid
rename season year
rename position group
rename full_name name
replace group = trim(group)
drop week // not from the current year

keep year teamid group name grade team years_exp rookie_year

order year teamid group grade name
gsort year teamid group -grade
bysort year teamid group: gen group_count = _n

// take the highest n grades per the paper
gen drop = 0
by year teamid group: replace drop = 1 if group_count > 1 & group == "QB"
by year teamid group: replace drop = 1 if group_count > 1 & group == "K"
by year teamid group: replace drop = 1 if group_count > 1 & group == "P"
by year teamid group: replace drop = 1 if group_count > 3 & group == "OL"
by year teamid group: replace drop = 1 if group_count > 2 & group == "WR"
by year teamid group: replace drop = 1 if group_count > 3 & group == "DB"
by year teamid group: replace drop = 1 if group_count > 1 & group == "LB"
by year teamid group: replace drop = 1 if group_count > 3 & group == "DL"
by year teamid group: replace drop = 1 if group_count > 1 & group == "RB"

drop if drop == 1
drop group_count

collapse (mean) avg_grade=grade, by(year teamid group)
reshape wide avg_grade, i(year teamid) j(group) string
rename avg_gradeDB DB
rename avg_gradeDL DL
rename avg_gradeK K
rename avg_gradeLB LB
rename avg_gradeOL OL
rename avg_gradeP P
rename avg_gradeQB QB
rename avg_gradeRB RB
rename avg_gradeWR WR
replace DL = DL/100
replace DB = DB/100
replace K = K/100
replace LB = LB/100
replace OL = OL/100
replace P = P/100
replace QB = QB/100
replace RB = RB/100
replace WR = WR/100

tempfile predictGroups
save `predictGroups', replace

* We now need to shift the weeks of the transformed rhino data, now the Massey solutions for each offense/defense (ive lines) from the Mathematica file.
clear
import delimited using "...\rhinoMassey.csv"
sort year weeksofar id
gen week = weeksofar + 1
replace week = 1 if week == 22 & year < 2021
replace week = 1 if week == 23 & year >= 2021
replace year = year + 1 if week == 1
drop if week == 22 & year < 2021 // 8*32 = 256 changes
drop if week == 23 & year > 2020
drop weeksofar

tempfile rhinoMasseyTemp1
save `rhinoMasseyTemp1', replace
keep if id <= 32 // offenses
gen off_rhino = .
replace off_rhino = massey
drop massey team

tempfile rhinoMasseyTemp2
save `rhinoMasseyTemp2', replace
clear

use `rhinoMasseyTemp1'
keep if id >= 33 // defenses
gen def_rhino = massey
replace def_rhino = massey
drop massey team
replace id = id - 32 // set to just the team's id

merge m:m year week id using `rhinoMasseyTemp2'
drop _merge // all == 3
rename id teamid

tempfile rhinoMassey
save `rhinoMassey', replace

* Now we need to load-in the games played to merge to them.
clear 
use "...\spreadsCLEAN.dta"
drop home_moneyline away_moneyline location total_line under_odds over_odds // not needed
levelsof year, local(years) 
foreach y of local years {
	forvalues i = 1/32 {
		expand 2 if year == `y' & home_id == `i'
	}
}
gen tagSurplus = 0
sort year week game_id
by year week game_id: replace tagSurplus = 1 if _n > 1
by year week game_id: gen tag = sum(tagSurplus)
gen teamid = 0
replace teamid = home_id if tag == 0
replace teamid = away_id if tag == 1
drop tagSurplus tag

merge m:m year week teamid using "...\weeklyMasseyCLEAN.dta"
drop if _merge == 2 // bye weeks and playoffs
drop _merge
drop normalizedmassey teamname

// now narrow to 2016-2023
drop if year < 2016
merge m:m year teamid using `predictGroups'
drop if _merge == 2
drop _merge
merge m:m year week teamid using `rhinoMassey'
drop if _merge == 1 // 2016 week 1 
drop if _merge == 2 // bye weeks and playoffs
drop _merge

merge 1:1 year week teamid using"...\dynamicEPA.dta"
// _merge == 2 comes from 2013-14
drop if _merge == 2
drop _merge
drop player

* Now we reshape back into the games/matchups.
gen side = 0 // 0 is home, 1 is away
replace side = 1 if away_id == teamid
reshape wide teamid massey dynamicepa off_rhino def_rhino DB DL K LB OL P QB RB WR, i(game_id) j(side)
drop teamid0 teamid1 // home_id and away_id
rename massey0 masseyhome
rename massey1 masseyaway
rename DB0 db_home
rename DL0 dl_home
rename K0 k_home
rename LB0 lb_home
rename OL0 ol_home
rename P0 p_home
rename QB0 qb_home
rename RB0 rb_home
rename WR0 wr_home
rename DB1 db_away
rename DL1 dl_away
rename K1 k_away
rename LB1 lb_away
rename OL1 ol_away
rename P1 p_away
rename QB1 qb_away
rename RB1 rb_away
rename WR1 wr_away
rename dynamicepa0 dynamicepa_home
rename dynamicepa1 dynamicepa_away
rename def_rhino0 def_rhino_home
rename def_rhino1 def_rhino_away
rename off_rhino0 off_rhino_home
rename off_rhino1 off_rhino_away
// per the paper
gen home_rhino = def_rhino_home - off_rhino_away
gen away_rhino = def_rhino_away - off_rhino_home
order year week home_id away_id
sort year week home_id away_id

export delimited using "...\footballData.csv", replace
// this is what the .py file will read
