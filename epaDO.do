* This file graps EPA data for QBS from "player_stats_RAW". We then calculate "weightedEPA" which is the porduct of that week's EPA and the normalized (tranformed between zero and one) massey of the opposing team. A "dynamic" EPA is then created by taking the weighted sum of "weightedEPA"s before, weighted by exp(-log(.5)/21*t) where t is the number of games played since. This is divided by the sum of said weights.

// appened player stats from 2013 to 2023
import delimited  "...\player_stats_RAW.csv"

* Cleaning
rename player_display_name player
drop player_name // lots of missing entries
drop headshot_url
rename recent_team team
rename position_group group
drop position

rename season year
rename opponent_team opponent
rename passing_tds td
rename passing_yards yards
rename interceptions ints
// not needed for QB
drop passing_2pt_conversions passing_air_yards passing_first_downs passing_yards_after_catch pacr carries rushing_yards rushing_tds rushing_first_downs rushing_epa rushing_fumbles rushing_2pt_conversions receptions targets receiving_yards receiving_tds receiving_fumbles receiving_fumbles_lost receiving_air_yards receiving_yards_after_catch receiving_first_downs receiving_epa receiving_2pt_conversions racr target_share air_yards_share wopr special_teams_tds fantasy_points fantasy_points_ppr

gen teamid = 0
local teams "ARI ATL BAL BUF CAR CHI CIN CLE DAL DEN DET GB HOU IND JAX KC MIA MIN NE NO NYG NYJ LV PHI PIT LA LAC SF SEA TB TEN WAS"
local ids "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32"
local N : word count `teams'
forvalues i = 1/`N' {
    local team : word `i' of `teams'
    local id : word `i' of `ids'
    replace teamid = `id' if team == "`team'"
}

// sort by passing attempts then drop all but the highest
sort year teamid week attempts
by year teamid week: gen weekly_count = _n
gen counter = 1
by year teamid week: egen week_total = total(counter)
drop if weekly_count != week_total
// 2013 Tyrelle Pryor and 2020 Kendall Hinton are WRs but played QB
gen non = 0
replace non = 1 if group != "QB"
replace group = "QB" if group != "QB"
// 1082 teams with 2 that week, 24 with 3

tempfile qbCLEAN
save `qbCLEAN'

use "...\spreadsCLEAN.dta"

// split the games (the matchups) into each team
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

// get the 'normalizedmassey' for weighting
merge 1:1 year week teamid using "...\weeklyMasseyCLEAN.dta"
drop if _merge == 2
drop _merge teamname
* to identify the massey of the QB's team and that of the opponent, we first reshape wide to each game being a single observation, get both Massey's, then split back again to look at the QBs:
gen side = 0 // 0 is home, 1 is away
replace side = 1 if away_id == teamid
reshape wide teamid massey normalizedmassey, i(game_id) j(side)
rename massey0 massey_home
rename massey1 massey_away
rename normalizedmassey0 normalizedmasseyhome
rename normalizedmassey1 normalizedmasseyaway
drop teamid1 teamid0 // just home_id/away_id

// now we do it again!
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
merge 1:1 year week teamid using `qbCLEAN'
// all merged
drop _merge week_total counter non weekly_count
order year teamid week spread_line player passing_epa
sort year player week

// name discrepencies; only a few so fine manually:
replace player = "A.J. McCarron" if player == "AJ McCarron"
replace player = "Robert Griffin III" if player == "Robert Griffin"
replace player = "E.J. Manuel" if player == "EJ Manuel"
replace player = "Michael Vick" if player == "Mike Vick"
replace player = "Thaddeus Lewis" if player == "Thad Lewis"
replace player = "Phillip Walker" if player == "P.J. Walker"

// weighted epa:
gen opp_norm_massey = 0
replace opp_norm_massey = normalizedmasseyhome if teamid == away_id
replace opp_norm_massey = normalizedmasseyaway if teamid == home_id
gen weighted_epa = passing_epa*opp_norm_massey

// we now need to get a rolling weighted_epa
sort player year week
* this gets a total games played by QB which we will then use to weigh their "dynamic" EPA
gen playertime = 0
gen counter = 1
by player: replace playertime = sum(counter)
by player: egen playertotal = total(counter) // to get the total games played per player

gen dynamicEPA = .
qui levelsof(player), local(unique_players) // to get the total players
* loop through each player, then for each index in that player (from start to start+"player"total") we loop from the start of that player to the end
local counter = 1
foreach guy of local unique_players {
	local end = playertotal[`counter'] + `counter' - 1
	local begin = `counter'
	//replace dynamicEPA = playertotal if player == "`guy'"
	forval i = `begin'/`end' {
		local sum_epas = 0
		local sum_weights = 0
		forval j = `begin'/`i' {
			local weight = exp(-0.033007 * (playertime[`i']-playertime[`j']))  
			local sum_epas = `sum_epas' + weighted_epa[`j']*`weight'
			local sum_weights = `sum_weights' + `weight'
		}  
		replace dynamicEPA = `sum_epas'/`sum_weights' in `i'
		local counter = `counter' + 1
	}
}

* NOTE: since we start in 2013 week 1, the beggining of that season will not be weighted-down with averages from the past, so are misleading; in the same way, QBs entering the league post-2013 will suffer the same problem early-on. Hence, we now find the league averages in the previous year and imput them. We do not need 2013, so for rookies that year it does not matter.

keep year teamid week player weighted_epa dynamicEPA playertime passing_epa opp_norm_massey playertotal

tempfile temp
save `temp', replace // save so we can collapse to find league averages for imputations

// yearly averages
collapse (mean) league_epa = weighted_epa, by(year)
// need to shift the years now:
gen laggedYear = year[_n+1] // saves 2013-2023 as 2014-2023 averages 
drop year
rename laggedYear year 
drop if year == .
tempfile avgs
save `avgs', replace 


use `temp'
by player: gen laggedEPA = dynamicEPA[_n-1] // shifts
drop if year == 2013
save `temp', replace

// identify the obervations we need to impute
keep if laggedEPA == .
merge m:m year using `avgs'
// matches the missing shifted epas (that player's first game if it was after 2013) with the average from the previous year
tempfile rookies
save `rookies', replace

use `temp' // still has rookies with missing epas, so need to drop before appending `rookies'
drop if laggedEPA == .
append using `rookies'

sort player year week

replace laggedEPA = league_epa if laggedEPA == .
drop league_epa _merge

// no longer need what is currently listed as "dynamicEPA"
drop dynamicEPA
rename laggedEPA dynamicepa
drop passing_epa opp_norm_massey weighted_epa playertime playertotal

save "...\dynamicEPA.dta", replace
