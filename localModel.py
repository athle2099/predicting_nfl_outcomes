import numpy as np
import pandas as pd
import xgboost as xgb
import math
from time import perf_counter
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score

file = '.../footballData.csv'
alpha = .033007 # roughly log(.5)/21, the coeffficient alpha satisfying exp(-alpha*21) = .5

df = pd.read_csv(file) # output file from "...\localDO.do"

def train_and_predict(df, start_time, end_time, side):
    if side == 1:
        dependent = 'home_score'
        line = 'home_line'
    elif side == 2:
        dependent = 'away_score'
        line = 'away_line'
    predictions = []
    actuals = []
    times = []
    weeks = []
    years = []
    spreads = []
    spread_lines = []
    home_odds = []
    away_odds = []
    home_ids = []
    away_ids = []
    df['time_diff'] = 0 # time differential
    df['weights'] = 0
    df['outlier'] = abs(df[dependent] - df[line])

    df['sin_week'] = 0 # to account for "seasonal" data
    df['cos_week'] = 0
    df.loc[df['year'] < 2021, 'sin_week'] = np.sin(2*np.pi*df.loc[df['year'] < 2021, 'week']/84)
    df.loc[df['year'] < 2021, 'cos_week'] = np.cos(2*np.pi*df.loc[df['year'] < 2021, 'week']/84)
    df.loc[df['year'] > 2020, 'sin_week'] = np.sin(2*np.pi*df.loc[df['year'] > 2020, 'week']/88)
    df.loc[df['year'] > 2020, 'cos_week'] = np.cos(2*np.pi*df.loc[df['year'] > 2020, 'week']/88)

    df['qb_home'] = df['cos_week']*df['qb_home']
    df['qb_away'] = df['cos_week']*df['qb_away']
    df['rb_home'] = df['cos_week']*df['rb_home']
    df['rb_away'] = df['cos_week']*df['rb_away']
    df['ol_home'] = df['cos_week']*df['ol_home']
    df['ol_away'] = df['cos_week']*df['ol_away']
    df['wr_home'] = df['cos_week']*df['wr_home']
    df['wr_away'] = df['cos_week']*df['wr_away']
    df['dl_home'] = df['cos_week']*df['dl_home']
    df['dl_away'] = df['cos_week']*df['dl_away']
    df['db_home'] = df['cos_week']*df['db_home']
    df['db_away'] = df['cos_week']*df['db_away']
    df['lb_home'] = df['cos_week']*df['lb_home']
    df['lb_away'] = df['cos_week']*df['lb_away']

    df['masseyhome'] = df['sin_week']*df['masseyhome']
    df['masseyaway'] = df['sin_week']*df['masseyaway']
    df['massey_home'] = df['sin_week']*df['massey_home']
    df['massey_away'] = df['sin_week']*df['massey_away']

    for t in range(start_time, end_time + 1):

        for x in range(1, t + 1):
            df.loc[(df['time'] == x), 'time_diff'] = t - x
            df.loc[(df['time'] == x), 'weights'] = np.exp(alpha*(x-t))

        train_data = df[(df['time'] < t) & (df['outlier'] < 11)]
        predict_data = df[df['time'] == t]

        if side == 1: # home is on offense
            dropping = [dependent, 'year','time','week','home_score','away_score','away_line', 'spread','spread_line','home_spread_odds','away_spread_odds','game_id','home_id','away_id','home','away','db_home','dl_home',
                'lb_home','p_home','qb_away','rb_away','ol_away','wr_away','k_away','time_diff', 'weights', 'outlier','dynamicepa_away', 'masseyaway', 'massey_away', 'home_line', 'whale_away','whale_home', 'rhino_home', 
                'husky_away', 'badger_away', 'badger_home'] 
            X_train = train_data.drop(columns=dropping)
            #print(X_train)
            X_predict = predict_data.drop(columns=dropping)
            mon_constraints = {'qb_home':1, 'wr_home':1,'rb_home':1,'ol_home':1,'dl_away':-1,'db_away':-1,'lb_away':-1, 'k_home':1, 'p_away':-1, 'dynamicepa_home':1, 'masseyhome':1, 'massey_home':1, 'rhino_away':-1, 'husky_home':1}

        elif side == 2: # away is on offense
            dropping = [dependent, 'year','week','time','home_score','away_score','home_line','spread','spread_line','home_spread_odds','away_spread_odds','game_id','home_id','away_id','home','away','db_away','dl_away',
                'lb_away','p_away','qb_home','rb_home','ol_home','wr_home','k_home','time_diff', 'weights', 'outlier','dynamicepa_home','masseyhome','massey_home','away_line', 'whale_home','whale_away', 'rhino_away', 
                'husky_home', 'badger_home', 'badger_away']
            X_train = train_data.drop(columns=dropping)
            X_predict = predict_data.drop(columns=dropping)
            mon_constraints = {'qb_away':1,'wr_away':1,'rb_away':1,'ol_away':1,'k_away':1,'dl_home':-1,'db_home':-1,'lb_home':-1,'p_home':-1, 'dynamicepa_away':1, 'masseyaway':1, 'massey_away':1, 'rhino_home':-1, 'husky_away':1}

        y_train = train_data[dependent]

        sample_weights = train_data['weights']
        dtrain = xgb.DMatrix(X_train, label=y_train, weight = sample_weights)

        params = {'objective':'reg:squarederror','max_depth': 8,'eta': 0.1, 'verbosity': 1, 'monotone_constraints': mon_constraints}
        num_boost_round = 10
        model = xgb.train(params, dtrain, num_boost_round)

        y_actual = predict_data[dependent]
        time_current = predict_data['time']
        week_current = predict_data['week']
        year_current = predict_data['year']
        spread_current = predict_data['spread']
        spread_line_current = predict_data['spread_line']
        home_spread_odds = predict_data['home_spread_odds']
        away_spread_odds = predict_data['away_spread_odds']
        home_id = predict_data['home_id']
        away_id = predict_data['away_id']

        dpredict = xgb.DMatrix(X_predict)

        y_predict = model.predict(dpredict)

        predictions.extend(y_predict)
        actuals.extend(y_actual)
        times.extend(time_current)
        weeks.extend(week_current)
        years.extend(year_current)
        spreads.extend(spread_current)
        spread_lines.extend(spread_line_current)
        home_odds.extend(home_spread_odds)
        away_odds.extend(away_spread_odds)
        home_ids.extend(home_id)
        away_ids.extend(away_id)

    return predictions, actuals, times, weeks, years, spreads, spread_lines, home_odds, away_odds, home_ids, away_ids

if __name__ == "__main__":
    starttime = perf_counter()
    results = pd.DataFrame() # combines the home and away results for analysis
    for i in range(1,3): # just loops home/away, no consideration of model here
        predictions, actuals, times, weeks, years, spreads, spread_lines, home_odds, away_odds, home_ids, away_ids = train_and_predict(df, start_time = 22, end_time = 171, side = i) # 2 is 2016 wk 2; 22 is 2017 wk 1; 171 is 2023 wk 23
        mse = mean_squared_error(actuals, predictions)
        r2 = r2_score(actuals, predictions)
        print(f'Mean Squared Error: {mse}')
        print(f'r^2: {r2}')
        if i == 1:
            results_df = pd.DataFrame({'home_score': actuals, 'home_predicted': predictions, 'time': times, 'week': weeks, 'year': years, 'home_id': home_ids, 'away_id': away_ids })
            results['time'] = results_df['time']
            results['week'] = results_df['week']
            results['year'] = results_df['year']
            results['home_id'] = results_df['home_id']
            results['away_id'] = results_df['away_id']
            results['home_predicted'] = results_df['home_predicted']
            results['home_score'] = results_df['home_score']  
        if i == 2:
            results_df = pd.DataFrame({'away_score': actuals, 'away_predicted': predictions, 'spread': spreads, 'spread_line': spread_lines, 'home_spread_odds': home_odds, 'away_spread_odds': away_odds})
            results['away_predicted'] = results_df['away_predicted']
            results['away_score'] = results_df['away_score']  
            results['spread'] = results_df['spread']
            results['spread_line'] = results_df['spread_line']
            results['home_spread_odds'] = results_df['home_spread_odds']
            results['away_spread_odds'] = results_df['away_spread_odds']

    # calculating returns
    results['predicted'] = results['home_predicted'] - results['away_predicted'] # home - away predicted scores
    results['bet_spr'] = 0 # setting default to zero and using strict inequalities auto. sets pushes to a zero return, `bet_spr == 0`
    results['spr'] = 0 #
    # betting over (predict home wins by at least 'spread_line') and winning ('spread' > 'spread_line')
    results.loc[(results['predicted'] - results['spread_line'] > 0) & (results['home_spread_odds'] > 0) & (results['spread'] - results['spread_line'] > 0), 'bet_spr'] = results['home_spread_odds']/100
    results.loc[(results['predicted'] - results['spread_line'] > 0) & (results['home_spread_odds'] <= 0) & (results['spread'] - results['spread_line'] > 0), 'bet_spr'] = -100/results['home_spread_odds']
    # betting under (predict away wins by at least -'srpead_line') and winning ('spread' < 'spread_line')
    results.loc[(results['predicted'] - results['spread_line'] < 0) & (results['away_spread_odds'] > 0) & (results['spread'] - results['spread_line'] < 0), 'bet_spr'] = results['away_spread_odds']/100
    results.loc[(results['predicted'] - results['spread_line'] < 0) & (results['away_spread_odds'] <= 0) & (results['spread'] - results['spread_line'] < 0), 'bet_spr'] = -100/results['away_spread_odds']

    # losing, either bet the over and under hits or vise-versa; in either case we lose -1, so only one case for each wrong bet
    results.loc[(results['predicted'] - results['spread_line'] > 0 ) & (results['spread'] - results['spread_line'] < 0), 'bet_spr'] = -1
    results.loc[(results['predicted'] - results['spread_line'] < 0 ) & (results['spread'] - results['spread_line'] > 0), 'bet_spr'] = -1
    results['spr'] = results['bet_spr']
    results.loc[(results['bet_spr'] > 0), 'spr'] = 1 # losses are already -1, and any correct bets are positive

    results['returns'] = results['bet_spr'].cumsum()
    results['noTransCost'] = results['spr'].cumsum()
    
    output = '.../localResults.csv'
    
    results.to_csv(output)

    endtime = perf_counter()
    print(endtime - starttime)
