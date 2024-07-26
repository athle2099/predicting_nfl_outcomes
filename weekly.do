* This file contains all relevant code for weekly, non-predicting regressions to motivate predictions. It will start with the raw weekly dataset from fastR, clean it and PFF data, then will put all merging as part of this file by using intermediate files.

use "C:\Users\journ\OneDrive\Desktop\ICERM\nflData\Jupyter\weeklyRostersRAW.dta"

* we want to extract the home and away teams from "game_id"
gen away = substr(game_id, 9, 3) // away; some are two digits:
gen two = 0
replace two = 1 if away == "GB_" | away == "KC_" | away == "LA_" | away == "LV_" | away == "NE_" | away == "NO_" | away == "SD_" | away == "SF_" | away == "TB_"
replace away = "GB" if away == "GB_"
replace away = "KC" if away == "KC_"
replace away = "LA" if away == "LA_" | away == "STL"
replace away = "LV" if away == "LV_"
replace away = "NE" if away == "NE_"
replace away = "NO" if away == "NO_"
replace away = "LAC" if away == "SD_"
replace away = "SF" if away == "SF_"
replace away = "TB" if away == "TB_"
replace away = "LV" if away == "OAK"
gen home = "" // home, split into cases depending upon `two'
replace home = substr(game_id, 13, 3) if two == 0
**# Bookmark #1
replace home = substr(game_id, 12, 3) if two == 1
drop two
replace home = "LV" if home == "OAK"
replace home = "LAC" if home == "SD"
replace home = "LA" if home == "STL"

drop if game_id == "game_id"
destring season week, replace
destring offense_snaps offense_pct defense_snaps defense_pct st_snaps st_pct, replace

* shortening names
rename offense_snaps off_snaps
rename offense_pct off_pct
rename defense_snaps def_snaps
rename defense_pct def_pct
rename season year

* deletes potential copying errors from excel
local first18vars ""
local count = 0
foreach var of varlist _all {
    local count = `count' + 1
    if `count' <= 18 {
        local first18vars "`first18vars' `var'"
    }
}
keep `first18vars'

* player names are not standardized between NFLfastR and PFF; ex) the DL/ST player for TB, "Patrick O'Connor" is "Pat O'Connor" in fastR but full in PFF
* since only one observation for each player in each game, most issues go away by dropping the primarily ST-non-K/P players (also dropping under 5 off./def. and hoping positional thresholds can still be met)

* there is one irregularity in K/P, and he just kicked; also is "K" in PFF
replace position = "K" if position == "K/P"

drop if (off_snaps < 5 & def_snaps < 5) & position != "K" & position != "P"

* DOUBLE POSITIONS
replace position = "CB" if position == "CB/R" // Chris Claybrooks
replace position = "C" if position == "C/G" // all centers  
replace position = "SS" if position == "DB/L" // Anthony Levine
replace position = "DL" if position == "DE/D" // Margus Hunt
replace position = "LB" if position == "DE/L" 
replace position = "DL" if position == "DT/D" // all DLmen
replace position = "FB" if position == "FB/D" | position == "FB/R"
replace position = "TE" if position == "FB/T" // Andrew Beck
replace position = "G" if position == "G/C" | position == "G/OT" | position == "G/T" // all Gs
replace position = "FB" if position == "LB/F" // Jason Cabinda, only played FB
replace position = "WR" if position == "RB/W" //receiving backs; should be counted with receivers
replace position = "T" if position == "T/G" // Braden Smith
replace position = "LB" if position == "TE/D" // Rashod Beryy
replace position = "WR" if position == "WR/R"

*GROUPING POSITIONS
gen group = "."
replace group = "OL" if position == "T" | position == "G" | position == "C" | position == "OT" | position == "OL"
replace group = "DL" if position == "DE" | position == "DL" | position == "DT" | position == "NT"
replace group = "WR" if position == "WR" | position == "TE"
replace group = "RB" if position == "RB" | position == "HB"
replace group = "DB" if position == "CB" | position == "DB" | position == "FS" | position == "S" | position == "SS"
replace group = "K" if position == "K"
replace group = "P" if position == "P"
replace group = "QB" if position == "QB"
replace group = "LB" if position == "ILB" | position == "LB" | position == "MLB" | position == "OLB"
drop if group == "." // the long snappers

* PLAYER CORRECTIONS
* two connor McGoverns: two n's will be the one for the Broncos/Jets, one n will be for Cowboys/bills
replace player = "Connor McGovernn" if player == "Connor McGovern" & (team == "DEN" | team == "NYJ")

* FBs listed as RBs
drop if player == "Alec Ingold" & group =="RB"
drop if player == "Alex Armah"
drop if player == "Andy Janovich"
drop if player == "Anthony Sherman"
drop if player == "Brad Smelley"
drop if player == "Buddy Howell"
drop if player == "Chandler Cox" & group == "RB"
drop if player == "C.J. Ham"
drop if player == "Danny Vitale" & group == "RB"
drop if player == "Derek Watt" & group == "RB"
drop if player == "Elijhaa Penny"
drop if player == "Gabe Nabers"
drop if player == "Giovanni Ricci"
drop if player == "Hunter Luepke"
drop if player == "Jalston Fowler"
drop if player == "James Develin" & group == "RB"
drop if player == "Jamie Olawale"
drop if player == "Khari Blasingame"
drop if player == "Kyle Juszczyk" // might keep him idk
drop if player == "Marquez Williams" & group == "RB"
drop if player == "Michael Burton" & group == "RB"
drop if player == "Nick Bawden"
drop if player == "Nick Bellore"
drop if player == "Patrick DiMarco" // same as kyle juszczyk
drop if player == "Will Tukuafu"
drop if player == "Zander Horvath"

* weekly errors
replace group = "WR" if player == "Alan Cross"
replace group = "WR" if player == "Demetric Felton"
replace group = "WR" if player == "Equanimeous St. Brown"
replace group = "RB" if player == "J.D. McKissic"
replace player = "Kerrith Whyte" if player == "Kerrith Whyte Jr"
replace group = "WR" if player == "Lynn Bowden Jr."
replace player = "Matt Dayes" if player == "Matthew Dayes"
drop if player == "Shane Smith"
replace group = "WR" if player == "Tavon Austin" & group == "RB"
replace group = "RB" if player == "Ty Montgomery"
replace group = "WR" if player == "Taysom Hill" // will be replaced later because we only have one grade under "WR" each year


* no PFF grade
drop if player == "Buddy Howell"
drop if player == "Jeremy Cox"
drop if player == "Tony Jones" & team == "NO" & year == 2020
drop if player == "Trey Edmunds" & team == "PIT" & year == 2020
drop if player == "Robert Hughes" & year == 2013

* STANDARDIZING NAMES
* take away all "III, II," and "IV": ex) "AJ Cole III" to "AJ Cole"
gen has_IV = strpos(player, "IV")
replace player = subinstr(player, "IV", "", .)
gen has_III = strpos(player, "III")
replace player = subinstr(player, "III", "", .)
gen has_II = strpos(player, "II")
replace player = subinstr(player, "II", "", .)
drop has_II has_III has_IV
* take away all regular "Sr." and "Jr."
replace player = subinstr(player, "Sr.", "", .)
replace player = subinstr(player, "Jr.", "", .)
* take away apostrophes "'": ex) "Dont'a Hightower" to "Donta Hightower"
replace player = subinstr(player, "'", "", .)
* take away all ".": ex) "A.J. Green" to "AJ Green"
replace player = subinstr(player, ".", "", .)
* take away dashes "-": ex) "Evan Dietrich-Smith" to 
replace player = subinstr(player, "-", "", .)
gen player_clean = subinstr(player, " ", "", .)
drop player
rename player_clean player
gen player_lower = lower(player)
drop player
rename player_lower player

* nicknames listed
replace player = "valentinoblake" if player == "antwonblake"
replace player = "dejiolatoye" if player == "ayodejiolatoye"
replace player = "dwightbentley" if player == "billbentley"
replace player = "bryndentrawick" if player == "bryndentrawick"
replace player = "camlewis" if player == "cameronlewis"
replace player = "cjgardnerjohnson" if player =="chaunceygardnerjohnson"
replace player = "chrismilton" if player == "christophermilton"
replace player = "chrissmith" if player == "christophersmith"
replace player = "daxhill" if player == "daxtonhill"
replace player = "deealford" if player == "deaundrealford"
replace player = "edwardreed" if player == "edreed"
replace player = "isaiahsimmons" if player == "isaiahsimmons"
replace player = "janorisjenkins" if player == "jackrabbitjenkins"
replace player = "jujubrents" if player == "juliusbrents"
replace player = "delanohill" if player == "lanohill"
replace player = "louisyoung" if player == "louyoung"
replace player = "miketyson" if player == "michaeltyson"
//??? replace player = "mileskillebrew" if player == "mileskillebrew"
replace player = "patsurtain" if player == "patricksurtain"
replace player = "tariqwoolen" if player == "riqwoolen"
replace player = "seanbaker" if player == "sambaker"
replace player = "starlingthomasv" if player == "starlingthomas"
replace player = "bopetekeyes" if player == "thakariuskeyes"
replace player = "trentonrobinson" if player == "trentrobinson"
replace player = "tretomlinson" if player == "treviustomlinson"

* originally DBs
replace player = "decobiedurant" if player == "cobiedurant"
replace group = "LB" if player == "deonebucannon"
drop if player == "marcusharris" // no PFF data, but played 5 games
replace group = "LB" if player == "markbarron"
replace group = "LB" if player == "nathangerry"
replace player = "jartaviusmartin" if player == "quanmartin"
replace group = "LB" if player == "isaiahsimmons"

* no pff
drop if player == "tommystevens"
drop if player == "jordangay"
drop if player == "billycundiff" & year == 2015 //only 13/14
drop if player == "nickrose" & year == 2018
drop if player == "ramizahmed"
replace group = "P" if player == "ryansantoso"
drop if player == "ryansantoso" & year != 2021 //only in PFFF
drop if player == "jjunga"
drop if player == "jordanwillis" & (group == "LB" | group == "OL")
drop if player == "kahlilmckenzie" & group == "OL"

* QB problems
replace player = "phillipwalker" if player == "pjwalker"
replace group = "WR" if player == "joewebb"

* DL name switching to PFF ones
replace player = "carlosbasham" if player == "boogiebasham"
drop if player == "jeremiahledbetter" & year == 2021 // no pff in 2021
drop if player == "lawrencethomas" & year == 2017 // no pff
drop if player == "patrickricard" & group == "DL" // hes a FB
replace player = "sebastianjosephday" if player == "sebastianjoseph"
replace player = "joshallenn" if player == "joshallen" & group != "QB" // makes the DL/LB "joshallen" have two n's. QB has one 

* K/P problems, will switch later when they played their non-primary position, mainly the other K/P got injured
replace group = "P" if player == "tylong"
replace player = "samuelsloman" if player == "samsloman"
replace group = "K" if player == "camerondicker"
replace player = "jacobschum" if player == "jakeschum"
replace player = "lachlanedwards" if player == "lacedwards"
replace group = "P" if player == "mattwile"

* OL problems
replace group = "DL" if player == "bengarland" & year == 2016 // plays both
replace group = "OL" if player == "bryanwitzmann"
replace player = "michaelharris" if player == "mikeharris" & group == "OL"
replace player = "olisaemekaudoh" if player == "oliudoh"
replace player = "rickwagner" if player == "rickywagner"
replace player = "sambaker" if player == "seanbaker" & team == "ATL" & year == 2013 // recorded name wrong
replace player = "deioncalhoun" if player == "shaqcalhoun"
replace group = "DL" if player == "sionefua"
replace player = "vladimirducasse" if player == "vladducasse"
replace player = "yosuahnijman" if player == "yoshnijman"
replace player = "iosuaopeta" if player == "suaopeta"

* WR problems
drop if player == "alancross" & year == 2017 // no pff
drop if player == "andrewbeck" & year != 2019 // he is a FB
replace player = "benjaminwatson" if player == "benwatson"
replace player = "christopherharper" if player == "chrisharper" & group == "WR"
drop if player == "coryharkey"
drop if player == "darrelldaniels" & year == 2023
drop if player == "deanteburton" & group == "WR"
replace group = "DL" if player == "demarcusdobbs" // listed as WR
replace group = "RB" if player == "denardrobinson"
replace player = "deonteharty" if player == "deonteharris"
replace player = "dhaquillewilliams" if player == "dukewilliams" & group == "WR" // theres a DB named dukewilliams
replace group = "QB" if player == "feleipefranks"
replace player = "haroldhoskins" if player == "gatorhoskins"
replace group = "RB" if player == "georgefarmer"
drop if player == "gerrellrobinson"
drop if player == "henrypearson"
replace group = "RB" if player == "jackiebattle"
drop if player == "javonwims" & year == 2022 // no pff
replace player = "josephanderson" if player == "joeanderson"
replace player = "jodyfortson" if player == "joefortson"
replace player = "joshuacribbs" if player == "joshcribbs"
replace player = "joshuapalmer" if player == "joshpalmer"
drop if player == "keithsmith" & group == "WR" // LB
drop if player == "maxmccaffrey" & year == 2018
drop if player == "michaelbandy" & year == 2021
drop if player == "nathanieldell"
drop if player == "orsoncharles" & year == 2013
drop if player == "rhettellison" & year == 2013
drop if player == "richiebrockel" // FB
replace player = "robbieanderson" if player == "robbiechosen" | player == "robbyanderson" // name change
drop if player == "ryanhewitt" & (year == 2014 | year == 2016)
drop if player == "tonypoljan"
drop if player == "torycarter" //FB
replace player = "walterpowell" if player == "waltpowell"
drop if player == "jackiebattle" & year == 2014
replace player = "michaelmorgan" if player == "mikemorgan" & group == "LB"
replace player = "robertfrancois" if player == "robfrancois"
replace group = "DB" if player == "ronnieharrison" & group == "LB"
replace group = "DB" if player == "suacravens"
replace player = "zacharyorr" if player == "zachorr"
replace player = "ezekielturner" if player == "zeketurner"
replace group = "WR" if player == "cordarrellepatterson"

* LB problems
replace group = "DB" if player == "jeremychinn"
replace group = "DB" if player == "jimmysmith"
drop if player == "josephjones"
replace player = "justinmarchlillard" if player == "justinmarch"
replace group = "DB" if player == "keanuneal" & year == 2022
replace group = "DB" if player == "martemapu"
replace player = "matthewjudon" if player == "mattjudon"
replace group = "DL" if player == "matthewjudon"
replace group = "LB" if player == "dontahightower"
replace player = "dariusleonard" if player == "shaquilleleonard"
replace player = "yannikcudjoevirgil" if player == "yannickcudjoevirgil" // spelling error

order player group year

tempfile weeklySnapsTemp
/*save "C:\Users\journ\OneDrive\Desktop\ICERM\nflData\Jupyter\weeklySnapsTemp", replace */
save `weeklySnapsTemp'

* PFF CLEANING, "pffNoDups.dta" is from "yearlyDO.do"
clear
use "C:\Users\journ\OneDrive\Desktop\ICERM\nflData\Jupyter\pffNoDups.dta"
rename position group

* Remark) A lot of this code is redundant as the changes are the same for both datasets, but it would require appending and treating them separetly anyway, so we repeat a lot of code.

replace player = "Connor McGovernn" if player == "Connor McGovern" & (team_name == "DEN" | team_name == "NYJ")

* PFF positional errors:
replace group = "RB" if player == "Rex Burkhead"
replace group = "RB" if player == "Adrian Killins Jr."
replace group = "RB" if player == "J.D. McKissic"
replace group = "RB" if player == "Tyler Ervin" & team_name == "HST"
replace group = "RB" if player == "Ty Montgomery"
replace group = "WR" if player == "Taysom Hill" // edited later

gen has_IV = strpos(player, "IV")
replace player = subinstr(player, "IV", "", .)
gen has_III = strpos(player, "III")
replace player = subinstr(player, "III", "", .)
gen has_II = strpos(player, "II")
replace player = subinstr(player, "II", "", .)
drop has_II has_III has_IV
replace player = subinstr(player, "Sr.", "", .)
replace player = subinstr(player, "Jr.", "", .)
replace player = subinstr(player, " Jr", "", .)
replace player = subinstr(player, "'", "", .)
replace player = subinstr(player, ".", "", .)
replace player = subinstr(player, "-", "", .)
gen player_clean = subinstr(player, " ", "", .)
drop player
rename player_clean player
gen player_lower = lower(player)
drop player
rename player_lower player

* position/group errors in PFF for DBs/LBs
replace group = "DB" if player == "mileskillebrew"
replace group = "DB" if player == "bryndentrawick"
replace group = "LB" if player == "deonebucannon"
replace group = "LB" if player == "isaiahsimmons"
replace group = "DB" if player == "jahleeladdae"
replace group = "DB" if player == "jamalcarter"
replace player = "joelefeged" if player == "joeyoung" & year == 2013 // name change
replace player = "decobiedurant" if player == "cobiedurant"
replace group = "DB" if player == "kurtcoleman"
replace group = "LB" if player == "markbarron"
replace group = "DB" if player == "markquesebell"
//replace group = "LB" if player == "nathangerry"
replace group = "DB" if player == "ronnieharrison"
replace group = "DB" if player == "suacravens"
replace group = "LB" if player == "dontahightower"
replace player = "joshallenn" if player == "joshallen" & group != "QB" // makes the DL/LB "joshallen" have two n's. QB has one 
replace player = "robertkelley" if player == "robkelley"

* discrepencies for DLs:
replace player = "sebastianjoseph" if player == "sebastianjosephday"
replace player = "cameronsample" if player == "camsample"
replace player = "bunmirotimi" if player == "olubunmirotimi"
replace player = "carlosbasham" if player == "boogiebasham"
replace player = "danielmccullers" if player == "danmccullers"
replace player = "evanderhood" if player == "ziggyhood"
replace player = "gregoryrousseau" if player == "gregrousseau"
replace player = "hebronfangupo" if player == "lonifangupo"
replace player = "joshbrent" if player == "joshpricebrent"
replace player = "leterriuswalton" if player == "ltwalton"
replace player = "matthewioannidis" if player == "mattioannidis"
replace player = "michaeldanna" if player == "mikedanna"
replace player = "nordlycapi" if player == "capcapi"
replace player = "ogbonniaokoronkwo" if player == "ogbookoronkwo"
replace player = "owamagbeodighizuwa" if player == "owaodighizuwa"
replace player = "patoconnor" if player == "patrickoconnor"
replace player = "patrickjones" if player == "patjones"
replace player = "patrickricard" if player == "patricard"
replace player = "sebastianjosephday" if player == "sebastianjosephday" | player == "sebastianjoseph"
replace player = "takkaristmckinley" if player == "takkmckinley"
replace player = "tedarrellslaton" if player == "tjslaton"
replace player = "williambradleyking" if player == "willbradleyking"
replace player = "zacharycarter" if player  == "zachcarter"

* discrepencies for OLs:
replace group = "OL" if player == "bryanwitzmann"
replace player = "cameronfleming" if player == "camfleming"
replace player = "evandietrichsmith" if player == "evansmith"
replace player = "iosuaopeta" if player == "suaopeta"
replace player = "josephnoteboom" if player == "joenoteboom"
replace player = "michaelonwenu" if player == "mikeonwenu"
replace player = "michaelotto" if player == "mikeotto"
replace player = "michaelperson" if player == "mikeperson"
replace player = "ronaldleary" if player == "ronleary"
replace player = "samuelcosmi" if player == "samcosmi"
replace player = "stephenschilling" if player == "steveschilling"
replace player = "trentonscott" if player == "trentscott"
replace player = "trystancoloncastillo" if player == "trystancolon"
replace player = "xaviernewmanjohnson" if player == "xaviernewman"
replace player = "yosuahnijman" if player == "yoshnijman"
replace player = "zacharythomas" if player == "zachthomas" & team_name == "LA"
replace group = "OL" if player == "cyruskouandjio"
replace group = "OL" if player == "danskipper"
replace group = "OL" if player == "michaelola"

* discrepencies for QBs:
replace player = "mitchelltrubisky" if player == "mitchtrubisky"
replace player = "phillipwalker" if player == "pjwalker"
replace group = "WR" if player == "joewebb"

* discrepencies for Ks:
replace player = "matthewmccrane" if player == "mattmccrane"

*discrepencies for Ps:
replace player = "matthewbosher" if player == "mattbosher"
replace group = "P" if player == "mattwile"
replace group = "K" if player == "kaarevedvik"
 
 * discrepencies for WRs
replace group = "WR" if player == "cordarrellepatterson"
replace player = "davidsills" if player == "davidsillsv" // cannot filter just a capital "v"
replace player = "gabrieldavis" if player == "gabedavis"
replace player = "michaelpreston" if player == "mikepreston"
replace player = "willfuller" if player == "willfullerv"
replace player = "robbieanderson" if player == "robbiechosen"
 
* discrepencies for LBs/DLs
replace player = "andrewjackson" if player == "drewjackson" 
replace group = "LB" if player == "chriscovington"
replace player = "dariusleonard" if player == "shaquilleleonard"
replace group = "LB" if player == "deweymcdonald" & year == 2016
replace player = "jonathanbostic" if player == "jonbostic"
replace group = "LB" if player == "marcusallen" & year == 2020
replace player = "nathanlandman" if player == "natelandman"
replace player = "nathanstupar" if player == "natestupar"
replace player = "samueleguavoen" if player == "sameguavoen"
replace player = "williamcompton" if player == "willcompton"
replace group = "LB" if player == "yannikcudjoevirgil"
replace group = "LB" if player == "samueleguavoen"

gen pff_group = group
order player pff_group year
format pff_group %8s
format group %8s

save "C:\Users\journ\OneDrive\Desktop\ICERM\nflData\Jupyter\pffNameEdit.dta", replace

* now we start merging and, going from the name/group changes above, merge what we can; the unmerged will be discrepencies from PFF and roster labelling of positions, here all DL/LB. PFF leans heavily towards grouping 4-3 and, nowadays, 4-2 OLBs as DL, which we agree with. Hence, for this we default to DLs, which is somewhat the reason why our models have much more listed DLs than LBs. It is a subjective decision.
clear
/*use "C:\Users\journ\OneDrive\Desktop\ICERM\nflData\Jupyter\weeklySnapsTemp.dta" */
use `weeklySnapsTemp'

merge m:m year player group using "C:\Users\journ\OneDrive\Desktop\ICERM\nflData\Jupyter\pffNameEdit.dta"
drop if _merge != 1 // keeps the from weekly that did not merge
drop _merge

tempfile temp
save `temp', replace
/*save "C:\Users\journ\OneDrive\Desktop\ICERM\nflData\Jupyter\Temp.dta", replace */
* have now saved the players with DL/LB positional changes; since I want to keep the weekly "group" the same, need to create an intermediate dataset from "pffNameEdit" that does not contain group (but the variable is pff_group)
use "C:\Users\journ\OneDrive\Desktop\ICERM\nflData\Jupyter\pffNameEdit.dta"

drop group
tempfile pffNameEditTemp
save `pffNameEditTemp', replace
/* save "C:\Users\journ\OneDrive\Desktop\ICERM\nflData\Jupyter\pffNameEditTemp.dta", replace */

use `temp'
/* use "C:\Users\journ\OneDrive\Desktop\ICERM\nflData\Jupyter\Temp.dta" */
format group %8s
* dropping the pff variables:
drop pff_group player_id team_name player_game_count grade franchise_id
// do not merge by team since this includes team changes
/*merge m:m player year using"C:\Users\journ\OneDrive\Desktop\ICERM\nflData\Jupyter\pffNameEditTemp.dta" */
merge m:m player year using `pffNameEditTemp'

drop if _merge != 3 // since names are correct, it matches all in this
replace group = pff_group // set groups to their PFF ones
drop pff_group
/*save "C:\Users\journ\OneDrive\Desktop\ICERM\nflData\Jupyter\Temp.dta", replace // this is the set of players with DL/LB discrepencies */
save `temp', replace

* now have matched the unmatched positions, so load the original matches, drop the unmatched, then append with the above:
/*use "C:\Users\journ\OneDrive\Desktop\ICERM\nflData\Jupyter\weeklySnapsTemp.dta" */
use `weeklySnapsTemp'
merge m:m year player group using "C:\Users\journ\OneDrive\Desktop\ICERM\nflData\weeklyPlayerCounts\pffNameEdit.dta"
drop if _merge != 3 // keep the original merges
/*append using "C:\Users\journ\OneDrive\Desktop\ICERM\nflData\Jupyter\Temp.dta" */
append using `temp'
drop _merge

* this is now the weekly information for both home and away with the merged grades
// can reference this week with "weeklyMerged.dta"
replace team = "LA" if team == "STL" // updating teams from weekly
replace team = "LAC" if team == "SD"
replace team = "LV" if team == "OAK"

* creating ids for home/away that are the same as teamids
drop position pfr_game_id pfr_player_id player_game_count franchise_id team_name // pff variables 
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

order player year week game_id team
sort year week game_id team

* Taysom Hill and missing players. Needs to be manually entered
replace group = "QB" if player == "taysomhill" & year == 2020 & (week == 11 | week == 12 | week == 13 | week == 14)
replace group = "QB" if player == "taysomhill" & year == 2021 & (week == 13 | week == 14 | week == 15 | week == 17)

// braden mann
insobs 1 
local count = _N //adds obs. to the end;does not fix where this ends
replace player = "bradenmann" in `count' // `' identifies the value
replace year = 2021 in `count'
replace week = 10 in `count'
replace game_id = "2021_10_BUF_NYJ" in `count'
replace team = "NYJ" in `count'
replace group = "P" in `count'
replace away = "BUF" in `count'
replace home = "NYJ" in `count'
replace game_type = "REG" in `count'
replace opponent = "BUF" in `count'
replace off_snaps = 0 in `count'
replace off_pct = 0 in `count'
replace def_snaps = 0 in `count'
replace def_pct = 0 in `count'
replace st_snaps = 24 in `count' 
replace st_pct = 1 in `count' // since we filter st by group, > 0 is all
replace player_id = 44664 in `count'
replace team = "NYJ" in `count'
replace grade = 57.1 in `count' 
replace home_id = 22 in `count'
replace away_id = 4 in `count'
// mitchell wishnowsky
insobs 1
local count = _N
replace player = "mitchwishnowky" in `count' 
replace year = 2023 in `count'
replace week = 5 in `count'
replace game_id = "2023_5_DAL_SF" in `count'
replace team = "SF" in `count'
replace group = "P" in `count'
replace away = "DAL" in `count' 
replace home = "SF" in `count'
replace game_type = "REG" in `count'
replace opponent = "DAL" in `count'
replace off_snaps = 0 in `count'
replace off_pct = 0 in `count'
replace def_snaps = 0 in `count'
replace def_pct = 0 in `count'
replace st_snaps = 24 in `count'
replace st_pct = 1 in `count'
replace player_id = 44663 in `count'
replace team = "SF" in `count'
replace grade = 71.2 in `count'
replace home_id = 28 in `count'
replace away_id = 9 in `count'
// Aldrick Rosas; K and P this week
insobs 1 
local count = _N
replace player = "aldrickrosas" in `count'
replace year = 2020 in `count'
replace week = 15 in `count'
replace game_id = "2020_15_JAX_BAL" in `count'
replace team = "JAX" in `count'
replace group = "P" in `count'
replace away = "JAX" in `count'
replace home = "BAL" in `count'
replace game_type = "REG" in `count'
replace opponent = "BUF" in `count'
replace off_snaps = 0 in `count'
replace off_pct = 0 in `count'
replace def_snaps = 0 in `count'
replace def_pct = 0 in `count'
replace st_snaps = 15 in `count' 
replace st_pct = 1 in `count'
replace player_id = 44664 in `count'
replace team = "JAX" in `count'
replace grade = 63.8 in `count' // this is his K grade; nothing else
replace home_id = 3 in `count'
replace away_id = 15 in `count'

* K problems also, typically playing both K and P:
// johnny hekker:
expand 2 if year == 2018 & week == 2 & team == "LA" & group == "P"
local count = _N
replace group = "K" in `count'
// ty long
expand 2 if year == 2019 & week == 1 & team == "LAC" & group == "P"
local count = _N
replace group = "K" in `count'
expand 2 if year == 2019 & week == 3 & team == "LAC" & group == "P"
local count = _N
replace group = "K" in `count'
expand 2 if year == 2019 & week == 2 & team == "LAC" & group == "P"
local count = _N
replace group = "K" in `count'
expand 2 if year == 2019 & week == 4 & team == "LAC" & group == "P"
local count = _N
replace group = "K" in `count'

expand 2 if year == 2021 & week == 4 & team == "SF" & group == "P"
local count = _N
replace group = "K" in `count'
expand 2 if year == 2023 & week == 5 & team == "SF" & group == "P"
local count = _N
replace group = "K" in `count'

replace group = "K" if player == "ryansantoso" & year == 2021 & (week == 1 | week == 3 | week == 4 | week == 10)

order year week home_id away_id team group
sort year week home_id away_id team group

* to collapse into the "dynamic" weighted averages it is easier to separate into the opposing teams, so home and away:

// we want one snap count to reference to
gen snap = 0 
gen snap_pct = 0
replace snap = off_snap if group == "QB" | group == "RB" | group == "WR" | group == "OL"
replace snap = def_snap if group == "DL" | group == "DB" | group == "LB"
replace snap = st_snap if group == "P" | group == "K"
replace snap_pct = off_snap if group == "QB" | group == "RB" | group == "WR" | group == "OL"
replace snap_pct = def_pct if group == "DL" | group == "DB" | group == "LB"
replace snap_pct = st_pct if group == "P" | group == "K"
replace st_pct = 0 if (group != "P" & group != "K") // we do not care about non K/P st players, so to evaluate who played more we set the non K/P st snaps to zero

gen teamid = 0 // could not just convert from franchise_id because that was seasonal
replace teamid = home_id if home == team
replace teamid = away_id if away == team

sort year week teamid group snap_pct
by year week teamid group: egen snap_sum = total(snap_pct)
* taking the weighted grade for each player
gen grade_dyn = 0
replace grade_dyn = grade*snap_pct if group != "P" & group != "K"

* P/Ks will proceed as before because we only need one, and they never play the full game; overdone for just K/P but saves us time :)
gen drop = 0
by year week teamid group: gen group_count = _n
bysort year week teamid group: gen half_count = sum(snap_pct > .48)
gen eligible = snap_pct > .48
gen counter = 1
by year week teamid group: egen half = total(eligible)
by year week teamid group: egen total_group = total(counter)
drop eligible counter
by year week teamid group: replace drop = 1 if group == "P" & snap_pct <= .48 & half >= 1
by year week teamid group: replace drop = 1 if group == "K" & snap_pct <= .48 & half >= 1
by year week teamid group: replace drop = 1 if group == "P" & total_group - group_count >= 1
by year week teamid group: replace drop = 1 if group == "K" & total_group - group_count >= 1
drop if drop == 1
sort year week teamid group grade
drop half half_count total_group group_count
by year week teamid group: gen group_count = _n
gen counter = 1
by year week teamid group: egen total_group = total(counter)
gen diff = total_group - group_count
by year week teamid group: replace drop = 1 if group == "P" & diff >= 1
by year week teamid group: replace drop = 1 if group == "K" & diff >= 1
drop if drop == 1

replace grade_dyn = grade if group == "P" | group == "K"
drop drop group_count counter total_group diff
replace snap_sum = 1 if group == "K" | group == "P"

sort year week teamid group snap_sum
drop pff_group 

gen side = 0 // home team
replace side = 1 if teamid == away_id 
collapse (sum) sum_grade=grade_dyn, by(year week teamid group game_id snap_sum side)
// check: gen counter = 1 ; by year week teamid: egen total = total(counter)
gen grade = sum_grade/snap_sum
drop sum_grade snap_sum
// random errors:
replace game_id = "2023_05_DAL_SF" if game_id == "2023_5_DAL_SF"
reshape wide grade, i(year week teamid) j(group) string
rename gradeDB DB
rename gradeDL DL
rename gradeK K
rename gradeLB LB
rename gradeOL OL
rename gradeP P
rename gradeQB QB
rename gradeRB RB
rename gradeWR WR

reshape wide DB DL K LB OL P QB RB WR teamid, i(game_id) j(side)
rename teamid0 home_id
rename teamid1 away_id

rename DB0 DB_home
rename DL0 DL_home
rename K0 K_home
rename LB0 LB_home
rename OL0 OL_home
rename P0 P_home
rename QB0 QB_home
rename RB0 RB_home
rename WR0 WR_home
rename DB1 DB_away
rename DL1 DL_away
rename K1 K_away
rename LB1 LB_away
rename OL1 OL_away
rename P1 P_away
rename QB1 QB_away
rename RB1 RB_away
rename WR1 WR_away

order year week home_id away_id game_id 
sort year week away_id

* now need to merge the spreads
merge m:m year week home_id away_id using "C:\Users\journ\OneDrive\Desktop\ICERM\nflData\Jupyter\spreadsCLEAN.dta"
drop _merge 
gen spread = home_score - away_score

save "C:\Users\journ\OneDrive\Desktop\ICERM\nflData\Jupyter\regReadyDyn.dta", replace

reg spread QB_home QB_away RB_home RB_away WR_home WR_away OL_home OL_away DB_home DB_away DL_home DL_away LB_home LB_away P_home P_away K_home K_away