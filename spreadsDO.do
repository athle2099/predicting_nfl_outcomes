import delimited "...\spreadsRAW.csv"

drop game_type gametime weekday gameday total overtime old_game_id gsis nfl_detail_id pfr pff espn ftn away_rest home_rest result

rename season year
drop if year == 2024 // not the best data for now
destring spread_line, replace
destring away_score, replace
destring home_score, replace

rename away_team away
rename home_team home

* all the name changes:
replace home = "LA" if home == "STL"
replace home = "LAC" if home == "SD"
replace home = "LV" if home == "OAK"
replace away = "LA" if away == "STL"
replace away = "LAC" if away == "SD"
replace away = "LV" if away == "OAK"

* home/away_id s
gen home_id = 0
gen away_id = 0
local team_names "ARI ATL BAL BUF CAR CHI CIN CLE DAL DEN DET GB HOU IND JAX KC MIA MIN NE NO NYG NYJ LV PHI PIT LA LAC SF SEA TB TEN WAS"
local ids "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32"
local N : word count `team_names'
forvalues i = 1/`N' {
    local team : word `i' of `team_names'
    local id : word `i' of `ids'
    replace home_id = `id' if home == "`team'"
	replace away_id = `id' if away == "`team'"
}

* extrapolating the market's expected scores for both teams from the "spread_line" and the "total_line"; system of two equations: h - a = s, h + a = t, so 2h = s + t, and a = t - (s+t)/2
gen home_line = 0
gen away_line = 0
replace home_line = spread_line + total_line // currently 2h
replace away_line = total_line - home_line/2 // t - h
replace home_line = home_line/2

* one week is missing home/away_spread_odds; we impute to the average
replace home_spread_odds = "-108" if home_spread_odds == "NA"
replace away_spread_odds = "-108" if away_spread_odds == "NA"

destring home_spread_odds, replace
destring away_spread_odds, replace

save "...\spreadsCLEAN.dta", replace
