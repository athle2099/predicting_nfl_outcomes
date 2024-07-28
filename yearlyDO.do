// upload raw pff data (if possessed)
use "...\pffRAW.dta"

//tab franchise_id // irregular ids in 2020
* puts city changes and name changes together. Washington Redskins/FT/Commanders is all "WAS"
replace team_name = "LA" if franchise_id == 26
replace team_name = "LV" if franchise_id == 23
replace team_name = "LAC" if franchise_id == 27

local team_names "ARZ ATL BLT BUF CAR CHI CIN CLV DAL DEN DET GB HST IND JAX KC MIA MIN NE NO NYG NYJ LV PHI PIT LA LAC SF SEA TB TEN WAS"
local franchise_ids "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32"
local N : word count `team_names'
forvalues i = 1/`N' {
    local team : word `i' of `team_names'
    local id : word `i' of `franchise_ids'
    replace franchise_id = `id' if team_name == "`team'"
}

drop if player_id == .

duplicates drop player_id year franchise_id, force
order player player_id year franchise_id position player_game_count grade
sort year franchise_id position player_game_count grade

save "...\pffNoDups.dta", replace

by year franchise_id position: gen position_count = _n // counts all players by year/team/position

bysort year franchise_id position: gen player_count_11 = sum(player_game_count >= 11) // counts by year/team/position players with at leat 11 games played

gen eligible = player_game_count >= 11
gen counter = 1 
by year franchise_id position: egen total_11 = total(eligible)
by year franchise_id position: egen total_position = total(counter)
drop eligible
drop counter

gen drop = 0

* Prepare to drop the players with under 11 games played if the team has enough players with 11+ games in that position
by year franchise_id position: replace drop = 1 if position == "QB" & player_game_count < 11 & total_11 >= 1
by year franchise_id  position: replace drop = 1 if position == "P" & player_game_count < 11 & total_11 >= 1
by year franchise_id position: replace drop = 1 if position == "K" & player_game_count < 11 & total_11 >= 1
by year franchise_id position: replace drop = 1 if position == "OL" & player_game_count < 11 & total_11 >= 5
by year franchise_id position: replace drop = 1 if position == "DL" & player_game_count < 11 & total_11 >= 4
by year franchise_id position: replace drop = 1 if position == "DB" & player_game_count < 11 & total_11 >= 5
by year franchise_id position: replace drop = 1 if position == "RB" & player_game_count < 11 & total_11 >= 1
by year franchise_id position: replace drop = 1 if position == "WR" & player_game_count < 11 & total_11 >= 4
by year franchise_id position: replace drop = 1 if position == "LB" & player_game_count < 11 & total_11 >= 2

* if we have an insufficient count with at least 11 games played, we need to keep the highest `n' players, QB_n = 1, RB_n = 1, ...
by year franchise_id position: replace drop = 1 if position == "QB" & total_position - position_count >= 1 & total_11 < 1
by year franchise_id position: replace drop = 1 if position == "P" & total_position - position_count >= 1 & total_11 < 1
by year franchise_id position: replace drop = 1 if position == "K" & total_position - position_count >= 1 & total_11 < 1
by year franchise_id position: replace drop = 1 if position == "OL" & total_position - position_count >= 5 & total_11 < 5
by year franchise_id position: replace drop = 1 if position == "DL" & total_position - position_count >= 4 & total_11 < 4
by year franchise_id position: replace drop = 1 if position == "DB" & total_position - position_count >= 5 & total_11 < 5
by year franchise_id position: replace drop = 1 if position == "RB" & total_position - position_count >= 1 & total_11 < 1
by year franchise_id position: replace drop = 1 if position == "WR" & total_position - position_count >= 4 & total_11 < 4
by year franchise_id position: replace drop = 1 if position == "LB" & total_position - position_count >= 2 & total_11 < 2

drop if drop == 1

* now we only have extra when there were more players with at least 11 games than needed. Hence, we now do not need to sort by player_game_count. Since we did not save exactly the 11 count ("total_11"), nor the count needed, we can delete those and recount:
sort year franchise_id position grade
drop position_count
drop player_count_11
drop total_11
drop total_position
* now, we can index through each position for each team at each year and keep the highest n grades:
by year franchise_id position: gen position_count = _n
gen counter = 1
by year franchise_id position: egen total_position = total(counter)
gen diff = total_position - position_count

by year franchise_id position: replace drop = 1 if position == "QB" & diff >=1 
by year franchise_id position: replace drop = 1 if position == "P" & diff >=1
by year franchise_id position: replace drop = 1 if position == "K" & diff >=1
by year franchise_id position: replace drop = 1 if position == "OL" & diff >=5
by year franchise_id position: replace drop = 1 if position == "DL" & diff >=4
by year franchise_id position: replace drop = 1 if position == "DB" & diff >=5
by year franchise_id position: replace drop = 1 if position == "RB" & diff >=1
by year franchise_id position: replace drop = 1 if position == "WR" & diff >=4
by year franchise_id position: replace drop = 1 if position == "LB" & diff >=2

drop if drop == 1

collapse (mean) avg_grade=grade, by(year franchise_id position)
reshape wide avg_grade, i(year franchise_id) j(position) string

* change names
rename avg_gradeDB DB
rename avg_gradeDL DL
rename avg_gradeK K
rename avg_gradeLB LB
rename avg_gradeOL OL
rename avg_gradeP P
rename avg_gradeQB QB
rename avg_gradeRB RB
rename avg_gradeWR WR
// set grades in the interval (0,1)
local group_names = "DL DB K LB OL P QB RB WR"
local N : word count `group_names'
forvalues i = 1/`N' {
	local name : word `i' of `group_names'
	replace `name' = `name'/100
}

* "weeklyMasseyRAW.dta" for each week is after that week (imn "weekssofar"), so the end-of-season is `weekssofar == 21' before 2021 and 22 after:
rename franchise_id teamid
gen weekssofar = .
replace weekssofar = 21 if year < 2021
replace weekssofar = 22 if year >= 2021

tempfile yearly
save `yearly', replace

clear
import delimited "...weeklyMasseyRAW.csv" // import the raw version to get the un-shifted
tempfile massey
save `massey', replace
clear

use `yearly'
// merge the massey rankings
merge m:m year teamid weekssofar using `massey'
drop if _merge == 2
drop _merge // should be merged

order DB DL K LB OL P QB RB WR
**# Bookmark #1
save "...\yearlyRegReady.dta", replace

reg normalizedmassey DL DB K LB OL P QB RB WR
