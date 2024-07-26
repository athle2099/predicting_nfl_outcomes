# clear environment

rm(list = ls())

# set directory for file imports

direc <- "/Users/totam/Downloads/"

# libraries used

library(nflverse)
library(data.table)
library(tidyverse)

# **We load schedules to obtain spread data for each NFL game from the 2013 - 2023 seasons.**
# load spread data from week-to-week NFL games
# seasons: 2013 - 2023

spread_data <- load_schedules(c(2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023))
write.csv(spread_data, paste0(direc, "gameSpreadInfo.csv"))

#**We load snap counts to obtain weekly rosters for each NFL team from the 2013 - 2023 seasons.**
# load weekly NFL rosters
# seasons: 2013 - 2023

weekly_rosters <- load_snap_counts(c(2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023))
write.csv(weekly_rosters, paste0(direc, "weeklyRosters.csv"))

# **We load player stats to obtain quarterbacks in playoffs and to determine their playoff win percentage from the 2016 - 2023 NFL seasons.**
# load quarterback playoff wins/losses
# seasons: 2016 - 2023

rosters <- load_player_stats(c(2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023))

# filter for only the postsesason and players who play primarily quarterback

rosters <- rosters[(rosters$season_type != "REG" & rosters$position == "QB"),]
rosters <- rosters[order(rosters$season, rosters$recent_team),]
rosters <- rosters[,c(1,3,4,7,8,9,11,14)]
rosters <- rosters[rosters$passing_yards != 0,]
rosters["playoff_wins"] <- 0
rosters["playoff_losses"] <- 0
head(rosters)

# initialize quarterback historial win-loss record in playoffs in 2016

rosters["playoff_wins"][rosters["player_display_name"] == "Matt Ryan" & rosters["season"] == 2016] <- 1
rosters["playoff_losses"][rosters["player_display_name"] == "Matt Ryan" & rosters["season"] == 2016] <- 4

rosters["playoff_wins"][rosters["player_display_name"] == "Dak Prescott" & rosters["season"] == 2016] <- 0
rosters["playoff_losses"][rosters["player_display_name"] == "Dak Prescott" & rosters["season"] == 2016] <- 0

rosters["playoff_wins"][rosters["player_display_name"] == "Matthew Stafford" & rosters["season"] == 2016] <- 0
rosters["playoff_losses"][rosters["player_display_name"] == "Matthew Stafford" & rosters["season"] == 2016] <- 2

rosters["playoff_wins"][rosters["player_display_name"] == "Aaron Rodgers" & rosters["season"] == 2016] <- 7
rosters["playoff_losses"][rosters["player_display_name"] == "Aaron Rodgers" & rosters["season"] == 2016] <- 6

rosters["playoff_wins"][rosters["player_display_name"] == "Brock Osweiler" & rosters["season"] == 2016] <- 0
rosters["playoff_losses"][rosters["player_display_name"] == "Brock Osweiler" & rosters["season"] == 2016] <- 0

rosters["playoff_wins"][rosters["player_display_name"] == "Alex Smith" & rosters["season"] == 2016] <- 2
rosters["playoff_losses"][rosters["player_display_name"] == "Alex Smith" & rosters["season"] == 2016] <- 3

rosters["playoff_wins"][rosters["player_display_name"] == "Connor Cook" & rosters["season"] == 2016] <- 0
rosters["playoff_losses"][rosters["player_display_name"] == "Connor Cook" & rosters["season"] == 2016] <- 0

rosters["playoff_wins"][rosters["player_display_name"] == "Matt Moore" & rosters["season"] == 2016] <- 0
rosters["playoff_losses"][rosters["player_display_name"] == "Matt Moore" & rosters["season"] == 2016] <- 2

rosters["playoff_wins"][rosters["player_display_name"] == "Tom Brady" & rosters["season"] == 2016] <- 22
rosters["playoff_losses"][rosters["player_display_name"] == "Tom Brady" & rosters["season"] == 2016] <- 9

rosters["playoff_wins"][rosters["player_display_name"] == "Eli Manning" & rosters["season"] == 2016] <- 8
rosters["playoff_losses"][rosters["player_display_name"] == "Eli Manning" & rosters["season"] == 2016] <- 4

rosters["playoff_wins"][rosters["player_display_name"] == "Ben Roethlisberger" & rosters["season"] == 2016] <- 11
rosters["playoff_losses"][rosters["player_display_name"] == "Ben Roethlisberger" & rosters["season"] == 2016] <- 6

rosters["playoff_wins"][rosters["player_display_name"] == "Russell Wilson" & rosters["season"] == 2016] <- 7
rosters["playoff_losses"][rosters["player_display_name"] == "Russell Wilson" & rosters["season"] == 2016] <- 3

# identify which quarterbacks won the Super Bowl in a given season

rosters["lost_bowl"] <- TRUE
rosters["lost_bowl"][rosters["season"] == 2016 & rosters$player_display_name == "Tom Brady"] <- FALSE
rosters["lost_bowl"][rosters["season"] == 2017 & rosters$player_display_name == "Nick Foles"] <- FALSE
rosters["lost_bowl"][rosters["season"] == 2018 & rosters$player_display_name == "Tom Brady"] <- FALSE
rosters["lost_bowl"][rosters["season"] == 2019 & rosters$player_display_name == "Patrick Mahomes"] <- FALSE
rosters["lost_bowl"][rosters["season"] == 2020 & rosters$player_display_name == "Tom Brady"] <- FALSE
rosters["lost_bowl"][rosters["season"] == 2021 & rosters$player_display_name == "Matthew Stafford"] <- FALSE
rosters["lost_bowl"][rosters["season"] == 2022 & rosters$player_display_name == "Patrick Mahomes"] <- FALSE
rosters["lost_bowl"][rosters["season"] == 2023 & rosters$player_display_name == "Patrick Mahomes"] <- FALSE

# iterate through quarterback data to update wins and losses over the years

final.roster <- rosters[rosters$player_display_name == "",]
for(it in rosters$player_display_name) {
  subset <- rosters[rosters$player_display_name == it,]
  if(length(subset$player_id) > 1) {
    for(num in 2:length(subset$player_id)) {
      if(subset[num - 1, 5] < subset[num, 5] && subset[num - 1, 11] == TRUE) {
        subset[num, 9] <- subset[num - 1, 9]
        subset[num, 10] <- subset[num - 1, 10] + 1
      }
      else if(subset[num - 1, 5] < subset[num, 5] && subset[num - 1, 11] == FALSE) {
        subset[num, 9] <- subset[num - 1, 9] + 1
        subset[num, 10] <- subset[num - 1, 10]
      }
      else {
        subset[num, 9] <- subset[num - 1, 9] + 1
        subset[num, 10] <- subset[num - 1, 10]
      }
    }
  }
  
  df_list <- list(final.roster, subset)
  
  final.roster <- df_list %>% reduce(full_join, by = c("player_id", "player_display_name", "position", "recent_team", "season", "week", "opponent_team", "passing_yards", "playoff_wins", "playoff_losses", "lost_bowl"))
  
}

head(final.roster)
write.csv(final.roster, paste0(direc, "playoff_qbs.csv"))

# **We load play-by-play data to classify offensive plays as run or pass plays. We also wish to identify sacks.**

# load play-by-play data
# seasons: 2013 - 2023
# simplification: on the offensive end, only consider pass and run plays

data <- load_pbp(c(2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023))
cleaned <- data[,c(1,2,4,5,6,7,8,10,11,12,29,31,32,154,286)]
cleaned <- cleaned[(cleaned$play_type == "pass" | cleaned$play_type == "run") & !is.na(cleaned$play_type),]
head(cleaned)

# initialize lists recording the run play percentages of each team per game

ARI.run <- c()
ATL.run <- c()
BAL.run <- c()
BUF.run <- c()
CAR.run <- c()
CHI.run <- c()
CIN.run <- c()
CLE.run <- c()
DAL.run <- c()
DEN.run <- c()
DET.run <- c()
GB.run <- c()
HOU.run <- c()
IND.run <- c()
JAX.run <- c()
KC.run <- c()
LA.run <- c()
LAC.run <- c()
LV.run <- c()
MIA.run <- c()
MIN.run <- c()
NE.run <- c()
NO.run <- c()
NYG.run <- c()
NYJ.run <- c()
PHI.run <- c()
PIT.run <- c()
SEA.run <- c()
SF.run <- c()
TB.run <- c()
TEN.run <- c()
WAS.run <- c()

# initialize lists recording the sack percentages of each team per game

ARI.sack <- c()
ATL.sack <- c()
BAL.sack <- c()
BUF.sack <- c()
CAR.sack <- c()
CHI.sack <- c()
CIN.sack <- c()
CLE.sack <- c()
DAL.sack <- c()
DEN.sack <- c()
DET.sack <- c()
GB.sack <- c()
HOU.sack <- c()
IND.sack <- c()
JAX.sack <- c()
KC.sack <- c()
LA.sack <- c()
LAC.sack <- c()
LV.sack <- c()
MIA.sack <- c()
MIN.sack <- c()
NE.sack <- c()
NO.sack <- c()
NYG.sack <- c()
NYJ.sack <- c()
PHI.sack <- c()
PIT.sack <- c()
SEA.sack <- c()
SF.sack <- c()
TB.sack <- c()
TEN.sack <- c()
WAS.sack <- c()

result <- data.frame("gameID", "HomeOrAway", "team", 2050, "season_type", 23, 1000, 1000, 1000, 1000, 1000)
colnames(result) <- c("gameID", "home_away", "team", "season", "season_type", "week", "run_pct", "pass_pct", "sack_pct", "shotgun_pct", "no_huddle_pct")

# quantify number of pass plays, run plays, and sacks as a percentage
# also quantify shotgun and no_huddle as percentages

for(it in unique(cleaned$game_id)) {
  temp <- cleaned[cleaned$game_id == it,]
  hometeam <- temp[[1,3]]
  awayteam <- temp[[1,4]]
  seasontemp <- temp[[1,15]]
  seasontypetemp <- temp[[1,5]]
  weektemp <- temp[[1,6]]
  home.plays <- temp[temp$posteam == hometeam,]
  away.plays <- temp[temp$posteam == awayteam,]
  home.run.percentage <- length(home.plays[home.plays$play_type == "run",]$play_id)/length(home.plays$play_id)
  home.shotgun.percentage <- mean(home.plays$shotgun)
  home.no.huddle.percentage <- mean(home.plays$no_huddle)
  away.sack.percentage <- mean(home.plays[home.plays$play_type == "pass",]$sack)
  away.run.percentage <- length(away.plays[away.plays$play_type == "run",]$play_id)/length(away.plays$play_id)
  away.shotgun.percentage <- mean(away.plays$shotgun)
  away.no.huddle.percentage <- mean(away.plays$no_huddle)
  home.sack.percentage <- mean(away.plays[away.plays$play_type == "pass",]$sack)
  
  result <- result %>% add_row(gameID = it, home_away = "home", team = hometeam, season = seasontemp, season_type = seasontypetemp, week = weektemp,
                               run_pct = home.run.percentage, pass_pct = 1-home.run.percentage, 
                               sack_pct = home.sack.percentage, shotgun_pct = home.shotgun.percentage,
                               no_huddle_pct = home.no.huddle.percentage)
  result <- result %>% add_row(gameID = it, home_away = "away", team = awayteam, season = seasontemp, season_type = seasontypetemp, week = weektemp,
                               run_pct = away.run.percentage, pass_pct = 1-away.run.percentage, 
                               sack_pct = away.sack.percentage, shotgun_pct = away.shotgun.percentage,
                               no_huddle_pct = away.no.huddle.percentage)
  
  if(hometeam == "ARI") {ARI.run <- c(ARI.run, home.run.percentage); ARI.sack <- c(ARI.sack, home.sack.percentage)}
  else if(hometeam == "ATL") {ATL.run <- c(ATL.run, home.run.percentage); ATL.sack <- c(ATL.sack, home.sack.percentage)}
  else if(hometeam == "BAL") {BAL.run <- c(BAL.run, home.run.percentage); BAL.sack <- c(BAL.sack, home.sack.percentage)}
  else if(hometeam == "BUF") {BUF.run <- c(BUF.run, home.run.percentage); BUF.sack <- c(BUF.sack, home.sack.percentage)}
  else if(hometeam == "CAR") {CAR.run <- c(CAR.run, home.run.percentage); CAR.sack <- c(CAR.sack, home.sack.percentage)}
  else if(hometeam == "CHI") {CHI.run <- c(CHI.run, home.run.percentage); CHI.sack <- c(CHI.sack, home.sack.percentage)}
  else if(hometeam == "CIN") {CIN.run <- c(CIN.run, home.run.percentage); CIN.sack <- c(CIN.sack, home.sack.percentage)}
  else if(hometeam == "CLE") {CLE.run <- c(CLE.run, home.run.percentage); CLE.sack <- c(CLE.sack, home.sack.percentage)}
  else if(hometeam == "DAL") {DAL.run <- c(DAL.run, home.run.percentage); DAL.sack <- c(DAL.sack, home.sack.percentage)}
  else if(hometeam == "DEN") {DEN.run <- c(DEN.run, home.run.percentage); DEN.sack <- c(DEN.sack, home.sack.percentage)}
  else if(hometeam == "DET") {DET.run <- c(DET.run, home.run.percentage); DET.sack <- c(DET.sack, home.sack.percentage)}
  else if(hometeam == "GB") {GB.run <- c(GB.run, home.run.percentage); GB.sack <- c(GB.sack, home.sack.percentage)}
  else if(hometeam == "HOU") {HOU.run <- c(HOU.run, home.run.percentage); HOU.sack <- c(HOU.sack, home.sack.percentage)}
  else if(hometeam == "IND") {IND.run <- c(IND.run, home.run.percentage); IND.sack <- c(IND.sack, home.sack.percentage)}
  else if(hometeam == "JAX") {JAX.run <- c(JAX.run, home.run.percentage); JAX.sack <- c(JAX.sack, home.sack.percentage)}
  else if(hometeam == "KC") {KC.run <- c(KC.run, home.run.percentage); KC.sack <- c(KC.sack, home.sack.percentage)}
  else if(hometeam == "LA") {LA.run <- c(LA.run, home.run.percentage); LA.sack <- c(LA.sack, home.sack.percentage)}
  else if(hometeam == "LAC") {LAC.run <- c(LAC.run, home.run.percentage); LAC.sack <- c(LAC.sack, home.sack.percentage)}
  else if(hometeam == "LV") {LV.run <- c(LV.run, home.run.percentage); LV.sack <- c(LV.sack, home.sack.percentage)}
  else if(hometeam == "MIA") {MIA.run <- c(MIA.run, home.run.percentage); MIA.sack <- c(MIA.sack, home.sack.percentage)}
  else if(hometeam == "MIN") {MIN.run <- c(MIN.run, home.run.percentage); MIN.sack <- c(MIN.sack, home.sack.percentage)}
  else if(hometeam == "NE") {NE.run <- c(NE.run, home.run.percentage); NE.sack <- c(NE.sack, home.sack.percentage)}
  else if(hometeam == "NO") {NO.run <- c(NO.run, home.run.percentage); NO.sack <- c(NO.sack, home.sack.percentage)}
  else if(hometeam == "NYG") {NYG.run <- c(NYG.run, home.run.percentage); NYG.sack <- c(NYG.sack, home.sack.percentage)}
  else if(hometeam == "NYJ") {NYJ.run <- c(NYJ.run, home.run.percentage); NYJ.sack <- c(NYJ.sack, home.sack.percentage)}
  else if(hometeam == "PHI") {PHI.run <- c(PHI.run, home.run.percentage); PHI.sack <- c(PHI.sack, home.sack.percentage)}
  else if(hometeam == "PIT") {PIT.run <- c(PIT.run, home.run.percentage); PIT.sack <- c(PIT.sack, home.sack.percentage)}
  else if(hometeam == "SEA") {SEA.run <- c(SEA.run, home.run.percentage); SEA.sack <- c(SEA.sack, home.sack.percentage)}
  else if(hometeam == "SF") {SF.run <- c(SF.run, home.run.percentage); SF.sack <- c(SF.sack, home.sack.percentage)}
  else if(hometeam == "TB") {TB.run <- c(TB.run, home.run.percentage); TB.sack <- c(TB.sack, home.sack.percentage)}
  else if(hometeam == "TEN") {TEN.run <- c(TEN.run, home.run.percentage); TEN.sack <- c(TEN.sack, home.sack.percentage)}
  else if(hometeam == "WAS") {WAS.run <- c(WAS.run, home.run.percentage); WAS.sack <- c(WAS.sack, home.sack.percentage)}
  
  if(awayteam == "ARI") {ARI.run <- c(ARI.run, away.run.percentage); ARI.sack <- c(ARI.sack, away.sack.percentage)}
  else if(awayteam == "ATL") {ATL.run <- c(ATL.run, away.run.percentage); ATL.sack <- c(ATL.sack, away.sack.percentage)}
  else if(awayteam == "BAL") {BAL.run <- c(BAL.run, away.run.percentage); BAL.sack <- c(BAL.sack, away.sack.percentage)}
  else if(awayteam == "BUF") {BUF.run <- c(BUF.run, away.run.percentage); BUF.sack <- c(BUF.sack, away.sack.percentage)}
  else if(awayteam == "CAR") {CAR.run <- c(CAR.run, away.run.percentage); CAR.sack <- c(CAR.sack, away.sack.percentage)}
  else if(awayteam == "CHI") {CHI.run <- c(CHI.run, away.run.percentage); CHI.sack <- c(CHI.sack, away.sack.percentage)}
  else if(awayteam == "CIN") {CIN.run <- c(CIN.run, away.run.percentage); CIN.sack <- c(CIN.sack, away.sack.percentage)}
  else if(awayteam == "CLE") {CLE.run <- c(CLE.run, away.run.percentage); CLE.sack <- c(CLE.sack, away.sack.percentage)}
  else if(awayteam == "DAL") {DAL.run <- c(DAL.run, away.run.percentage); DAL.sack <- c(DAL.sack, away.sack.percentage)}
  else if(awayteam == "DEN") {DEN.run <- c(DEN.run, away.run.percentage); DEN.sack <- c(DEN.sack, away.sack.percentage)}
  else if(awayteam == "DET") {DET.run <- c(DET.run, away.run.percentage); DET.sack <- c(DET.sack, away.sack.percentage)}
  else if(awayteam == "GB") {GB.run <- c(GB.run, away.run.percentage); GB.sack <- c(GB.sack, away.sack.percentage)}
  else if(awayteam == "HOU") {HOU.run <- c(HOU.run, away.run.percentage); HOU.sack <- c(HOU.sack, away.sack.percentage)}
  else if(awayteam == "IND") {IND.run <- c(IND.run, away.run.percentage); IND.sack <- c(IND.sack, away.sack.percentage)}
  else if(awayteam == "JAX") {JAX.run <- c(JAX.run, away.run.percentage); JAX.sack <- c(JAX.sack, away.sack.percentage)}
  else if(awayteam == "KC") {KC.run <- c(KC.run, away.run.percentage); KC.sack <- c(KC.sack, away.sack.percentage)}
  else if(awayteam == "LA") {LA.run <- c(LA.run, away.run.percentage); LA.sack <- c(LA.sack, away.sack.percentage)}
  else if(awayteam == "LAC") {LAC.run <- c(LAC.run, away.run.percentage); LAC.sack <- c(LAC.sack, away.sack.percentage)}
  else if(awayteam == "LV") {LV.run <- c(LV.run, away.run.percentage); LV.sack <- c(LV.sack, away.sack.percentage)}
  else if(awayteam == "MIA") {MIA.run <- c(MIA.run, away.run.percentage); MIA.sack <- c(MIA.sack, away.sack.percentage)}
  else if(awayteam == "MIN") {MIN.run <- c(MIN.run, away.run.percentage); MIN.sack <- c(MIN.sack, away.sack.percentage)}
  else if(awayteam == "NE") {NE.run <- c(NE.run, away.run.percentage); NE.sack <- c(NE.sack, away.sack.percentage)}
  else if(awayteam == "NO") {NO.run <- c(NO.run, away.run.percentage); NO.sack <- c(NO.sack, away.sack.percentage)}
  else if(awayteam == "NYG") {NYG.run <- c(NYG.run, away.run.percentage); NYG.sack <- c(NYG.sack, away.sack.percentage)}
  else if(awayteam == "NYJ") {NYJ.run <- c(NYJ.run, away.run.percentage); NYJ.sack <- c(NYJ.sack, away.sack.percentage)}
  else if(awayteam == "PHI") {PHI.run <- c(PHI.run, away.run.percentage); PHI.sack <- c(PHI.sack, away.sack.percentage)}
  else if(awayteam == "PIT") {PIT.run <- c(PIT.run, away.run.percentage); PIT.sack <- c(PIT.sack, away.sack.percentage)}
  else if(awayteam == "SEA") {SEA.run <- c(SEA.run, away.run.percentage); SEA.sack <- c(SEA.sack, away.sack.percentage)}
  else if(awayteam == "SF") {SF.run <- c(SF.run, away.run.percentage); SF.sack <- c(SF.sack, away.sack.percentage)}
  else if(awayteam == "TB") {TB.run <- c(TB.run, away.run.percentage); TB.sack <- c(TB.sack, away.sack.percentage)}
  else if(awayteam == "TEN") {TEN.run <- c(TEN.run, away.run.percentage); TEN.sack <- c(TEN.sack, away.sack.percentage)}
  else if(awayteam == "WAS") {WAS.run <- c(WAS.run, away.run.percentage); WAS.sack <- c(WAS.sack, away.sack.percentage)}
}

result <- result[result$team != "team",]
result
write.csv(result, paste0(direc, "PlayByPlayOffensePlays.csv"))
