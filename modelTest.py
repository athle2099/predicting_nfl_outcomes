import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# Remark) file is to plot the returns of models wrt time
combined = 0 # 0 is just local
weeks = 0 # 0 for all; 1 if we just want the first three week; # 2 if we want weeks 4-15; 3 for 15-end

local = 'C:/Users/journ/OneDrive/Desktop/ICERM/nflData/Jupyter/localResults.csv'
results = pd.read_csv(local)

if combined == 1:
    # we take the subset on which the two models predict the same direction from the 'spread_line'
    hodge = 'C:/Users/journ/OneDrive/Desktop/ICERM/nflData/Jupyter/Global_CLEAN.csv'
    dfGlobal = pd.read_csv(hodge)
    dfLocal = results[['time', 'year', 'week', 'home_id', 'away_id', 'spread', 'spread_line', 'home_spread_odds', 'away_spread_odds', 'predicted']]
    
    dfGlobal = dfGlobal[dfGlobal['year'] > 2016] # keeps subset 2017 and after, years for which local exists
    dfGlobal = dfGlobal[['hodgepredspread', 'year', 'week', 'home_id']] # keeps the wanted variable and the variables to merge on 

    results = pd.merge(dfLocal, dfGlobal, on = ['year', 'week', 'home_id'])
    resulst = results.sort_values(by=['year', 'week', 'home_id'])

    results['disjoint'] = 0
    results.loc[(results['predicted'] > results['spread_line']) & (results['hodgepredspread'] > results['spread_line']), 'disjoint'] = 1
    results.loc[(results['predicted'] < results['spread_line']) & (results['hodgepredspread'] < results['spread_line']), 'disjoint'] = 1

    results.loc[(results['predicted'] > results['spread_line']) & (results['hodgepredspread'] < results['spread_line']), 'disjoint'] = -1
    results.loc[(results['predicted'] < results['spread_line']) & (results['hodgepredspread'] > results['spread_line']), 'disjoint'] = -1

    results = results[results['disjoint'] == 1] # keep the games in which global and local predict the same side

    # calculating follows for just one since the predicted directions from the 'spread_line' are the same
    results['bet_spr'] = 0 
    results['spr'] = 0 
    results.loc[(results['predicted'] - results['spread_line'] > 0) & (results['home_spread_odds'] > 0) & (results['spread'] - results['spread_line'] > 0), 'bet_spr'] = results['home_spread_odds']/100
    results.loc[(results['predicted'] - results['spread_line'] > 0) & (results['home_spread_odds'] <= 0) & (results['spread'] - results['spread_line'] > 0), 'bet_spr'] = -100/results['home_spread_odds']
    results.loc[(results['predicted'] - results['spread_line'] < 0) & (results['away_spread_odds'] > 0) & (results['spread'] - results['spread_line'] < 0), 'bet_spr'] = results['away_spread_odds']/100
    results.loc[(results['predicted'] - results['spread_line'] < 0) & (results['away_spread_odds'] <= 0) & (results['spread'] - results['spread_line'] < 0), 'bet_spr'] = -100/results['away_spread_odds']
    results.loc[(results['predicted'] - results['spread_line'] > 0 ) & (results['spread'] - results['spread_line'] < 0), 'bet_spr'] = -1
    results.loc[(results['predicted'] - results['spread_line'] < 0 ) & (results['spread'] - results['spread_line'] > 0), 'bet_spr'] = -1
    results['spr'] = results['bet_spr']
    results.loc[(results['bet_spr'] > 0), 'spr'] = 1

    results['returns'] = results['bet_spr'].cumsum()
    results['noTransCost'] = results['spr'].cumsum()


plt.figure(figsize=(10, 6))
plt.plot(results['time'], results['returns'], marker='o', linestyle='-')
plt.xlabel('Time')
plt.ylabel('Returns')
title = 'Returns of Combined == ' + str(combined)
plt.title(title)
plt.grid(True)
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()

plt.figure(figsize=(10, 6))
plt.plot(results['time'], results['noTransCost'], marker='o', linestyle='-')
plt.xlabel('Time')
plt.ylabel('Returns')
plt.title('Returns: Equal Odds')
plt.grid(True)
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()