# Dual Confirmation Indicator Testers  
Moving on from single confirmation indicator tests, I needed to start testing the ones that showed promise together. In addition to some other indicators, my final trading EA will be using 2 confirmation incicators.  
> In order to streamline the creation of Test EAs, I created a more advanced template to use which includes some lookback functions to give some leeway. In addition to that, while not within the template, I found it necessary to also add a dominance option which is present within most files.  
## Disclaimer:  
The Expert Advisors within this repository are intended to be used within MT5's backtester and not for live trading. **You have been warned**.  
## Dual Confirmation Indicator Tests:  
Initial testing was done with these files. Once I found a combination I like, I would take it into a more of a deep dive and start adding other indicators into the mix, such as a baseline indicator.  
## Dual Confirmation Deep Dives:  
I quite like the results I got from using DSLU RSI and Trendflex so I began testing it with various baselines.  
## Where I'm at now:  
While I did like the initial results, I later learned that Trendflex is somewhat problematic for what I want it out of a confirmation indicator. In addition to that, I have been optimising these for EURUSD 30 minute timeframe. In order to make a more consistent strategy, I have decided to move up to a higher timeframe. Also, I am currently creating a new method for entering trades that involves splitting trades into 2. Yes, I know that PositionClosePartial() exists. I want to use 2 seperate trades instead.