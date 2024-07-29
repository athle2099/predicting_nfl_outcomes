# Local and global approaches for predicting week-to-week NFL outcomes

This repository contains code from the paper *Local and global approaches for predicting week-to-week NFL outcomes*. 

## Data

We use play-by-play and weekly roster data from `nflverse` in R. See the [user guide](https://nflverse.nflverse.com/) for more info on the scraping functions.

We also use player grades from **Pro Football Focus** (PFF). *PFF grades are proprietary and require a subscription*. As a result, some of the code on this repository will not run, as the input data is not available. See PFF's [tutorial](https://www.pff.com/grades) for more info on grades.

See the [data_files](data_files) folder for our relevant input/output data.

## Local and Global Models

We include code and data files to reproduce the local and global models discussed in our paper. We provide a description of each code file below.

`global_model.wl`: global model implementation.

`nflverse_scraping.R`: scrapes relevant play-by-play and roster data from `nflverse` for use in local and global models.

`public_predicting_individual_grades.Rmd`: predicts upcoming season grades using PFF grades from previous seasons.

`regression_PFF_grades.R`: linear regression and elastic net regularization of PFF grades against modified Massey ratings.

`spreadsDO.do`: cleans game-by-game spread data for local model.

`weeklyDO.do`: cleans/organizes week-to-week dynamic data changes.

`yearlyDO.do`: cleans/organizes year-to-year dynamic data changes.

`epaDO.do`: cleans play-by-play data and calculates quarterback dynamic EPA.

`localDO.do`: organizes relevant predictor variables for use in the local XGBoost model.

`masseyDO.do`: cleans modified Massey ratings and shifts Massey ratings based on week.

`offense_massey.wl`: generates modified Massey ratings for offensive output/scores.

`pass_rush_rhino_massey.wl`: generates modified Massey ratings for pass rush impact (or P-RHINO).

`localModel.py`: local XGBoost model implementation.

`modelTest.py`: graphs returns of local model.
