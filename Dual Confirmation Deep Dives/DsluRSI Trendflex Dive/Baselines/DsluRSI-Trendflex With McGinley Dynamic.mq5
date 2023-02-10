//+------------------------------------------------------------------+
//| Includes                                                         |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
//+------------------------------------------------------------------+
//| ENUMS                                                            |
//+------------------------------------------------------------------+
enum enLookbackReturn
  {
   lookback_pass,
   lookback_fail
  };

enum enConfirmationSignal
  {
   confirmation_buy,
   confirmation_sell,
   confirmation_none
  };

enum enTradeSignal
  {
   buy_signal,
   sell_signal,
   no_signal
  };

enum enTradeEntryType
  {
   go_long,
   go_short
  };

enum enMcgType
  {
   mcg_original, // Original formula
   mcg_faster,   // "Improved" formula
  };
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "Use Current or Different Timeframe:"
input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT; // Timeframe

input group "Risk Inputs"
input double inpRiskPerTrade = 1.0; // Risk Percent Per Trade
input double inpProfitFactor = 1.5; // Profit factor
input uint inpATRPeriod = 25; // ATR Period
input double inpATRChannelFactor =1.5; // ATR Channel Factor
input ENUM_APPLIED_PRICE inpATRChannelAppPrice = PRICE_TYPICAL; // ATR Channel Applied Price

input group "Dslu of RSI Inputs"
input int dsluInpRsiPeriod = 14; // RSI period
input int dsluInpMaPeriod = 34; // Average period
input ENUM_MA_METHOD dsluInpMaMethod = MODE_EMA; // Average method
input ENUM_APPLIED_PRICE dsluInpPrice = PRICE_CLOSE; // Price
input double dsluInpSignalPeriod = 9.4; // Dsl signal period

input group "Trendflex Inputs"
input int trendflexInpFastPeriod = 40; // Fast trend-flex period
input int trendflexInpSlowPeriod = 55; // Slow trend-flex period

input group "Lookback"
input ushort DsluRSITolerance = 5; // Dslu of RSI Lookback Tolerance
input ushort TrendflexTolerance = 5; // Trendflex Lookback Tolerance

input group "McGinley Dynamic Inputs"
input int inpMcGinleyPeriod = 14; // Period
input ENUM_APPLIED_PRICE inpMcGinleyPrice  = PRICE_CLOSE; // Price
input enMcgType inpMcGinleyType = mcg_original; // Calculation type
input ushort McGinley_DsluRSITolerance = 5; // Dslu of RSI Lookback Tolerance
input ushort McGinley_TrendflexTolerance = 5; // Trendflex Lookback Tolerance
//+------------------------------------------------------------------+
//| Handles                                                          |
//+------------------------------------------------------------------+
int ATRChannelHandle;
int DsluRSIHandle;
int TrendflexHandle;
int BaselineHandle;
//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
int barTotal;
ulong posTicket;
bool inTrade = false;

//+------------------------------------------------------------------+
//| Objects                                                          |
//+------------------------------------------------------------------+
CTrade trade;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   barTotal = iBars(_Symbol,Timeframe);
   
   ATRChannelHandle = iCustom(_Symbol,Timeframe,"ATR Channel.ex5",MODE_SMA,1,inpATRPeriod,inpATRChannelFactor,inpATRChannelAppPrice);
   DsluRSIHandle = iCustom(_Symbol,Timeframe,"Dslu RSI of average.ex5",dsluInpRsiPeriod,dsluInpMaPeriod,dsluInpMaMethod,dsluInpPrice,dsluInpSignalPeriod);
   TrendflexHandle = iCustom(_Symbol,Timeframe,"TrendFlex x 2.ex5",trendflexInpFastPeriod,trendflexInpSlowPeriod);
   BaselineHandle = iCustom(_Symbol,Timeframe,"McGinley dynamic average (official).ex5",inpMcGinleyPeriod,inpMcGinleyPrice,inpMcGinleyType);
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   int barTotalUpdated = iBars(_Symbol,Timeframe);
   
   if (barTotal != barTotalUpdated)
   {
    barTotal = barTotalUpdated;
    
    enTradeSignal tradeSignal = CheckForSignal();
    PositionCheckModify(tradeSignal);
    
    if (inTrade == false)
    {
     if (tradeSignal == buy_signal)
     {
      EnterPosition(go_long);
     }
     if (tradeSignal == sell_signal)
     {
      EnterPosition(go_short);
     }
    }
    
   }
   
  }

//+------------------------------------------------------------------+
//| Trade Signal Function                                            |
//+------------------------------------------------------------------+
enTradeSignal CheckForSignal()
  {
   enConfirmationSignal ConfirmationSignal = CheckConfirmationIndicators();
   
   if (ConfirmationSignal == confirmation_buy)
   {
    return buy_signal;
   }
   
   if (ConfirmationSignal == confirmation_sell)
   {
    return sell_signal;
   }
   
   return no_signal;
  }

//+------------------------------------------------------------------+
//| Check Confirmation Indicators Function                           |
//+------------------------------------------------------------------+
enConfirmationSignal CheckConfirmationIndicators()
  {
   // Indicator values:
   double DsluRSIColourValues[];
   CopyBuffer(DsluRSIHandle,5,1,2,DsluRSIColourValues);
   ArrayReverse(DsluRSIColourValues);
   
   double TrendflexFastValues[];
   CopyBuffer(TrendflexHandle,0,1,2,TrendflexFastValues);
   ArrayReverse(TrendflexFastValues);
   
   double TrendflexSlowValues[];
   CopyBuffer(TrendflexHandle,1,1,2,TrendflexSlowValues);
   ArrayReverse(TrendflexSlowValues);
   
   double BaselineValues[];
   CopyBuffer(BaselineHandle,0,1,2,BaselineValues);
   ArrayReverse(BaselineValues);
   
   // Price Close Values
   double closePrice1 = iClose(_Symbol,Timeframe,1);
   double closePrice2 = iClose(_Symbol,Timeframe,2);
   
   // On Dslu RSI
   if ((DsluRSIColourValues[0] == 1) && ((DsluRSIColourValues[1] == 0) || (DsluRSIColourValues[1] == 2)))
   {
    if (TrendflexFastValues[0] > TrendflexSlowValues[0])
    {
     if (TrendflexLookback(TrendflexTolerance) == lookback_pass)
     {
      if (closePrice1 > BaselineValues[0])
      {
       return confirmation_buy;
      }
     }
    }
   }
   
   if ((DsluRSIColourValues[0] == 2) && ((DsluRSIColourValues[1] == 0) || (DsluRSIColourValues[1] == 1)))
   {
    if (TrendflexFastValues[0] < TrendflexSlowValues[0])
    {
     if (TrendflexLookback(TrendflexTolerance) == lookback_pass)
     {
      if (closePrice1 < BaselineValues[0])
      {
       return confirmation_sell;
      }
     }
    }
   }
   
   // On Trendflex
   if ((TrendflexFastValues[0] > TrendflexSlowValues[0]) && (TrendflexFastValues[1] < TrendflexSlowValues[1]))
   {
    if (DsluRSIColourValues[0] == 1)
    {
     if (DsluRSILookback(DsluRSITolerance) == lookback_pass)
     {
      if (closePrice1 > BaselineValues[0])
      {
       return confirmation_buy;
      }
     }
    }
   }
   
   if ((TrendflexFastValues[0] < TrendflexSlowValues[0]) && (TrendflexFastValues[1] > TrendflexSlowValues[1]))
   {
    if (DsluRSIColourValues[0] == 2)
    {
     if (DsluRSILookback(DsluRSITolerance) == lookback_pass)
     {
      if (closePrice1 < BaselineValues[0])
      {
       return confirmation_sell;
      }
     }
    }
   }
   
   // On Baseline Cross
   if ((closePrice1 > BaselineValues[0]) && (closePrice2 < BaselineValues[1]))
   {
    if ((DsluRSIColourValues[0] == 1) && (TrendflexFastValues[0] > TrendflexSlowValues[0]))
    {
     if ((DsluRSILookback(McGinley_DsluRSITolerance) == lookback_pass) && (TrendflexLookback(McGinley_TrendflexTolerance) == lookback_pass))
     {
      return confirmation_buy;
     }
    }
   }
   
   if ((closePrice1 < BaselineValues[0]) && (closePrice2 > BaselineValues[1]))
   {
    if ((DsluRSIColourValues[0] == 2) && (TrendflexFastValues[0] < TrendflexSlowValues[0]))
    {
     if ((DsluRSILookback(McGinley_DsluRSITolerance) == lookback_pass) && (TrendflexLookback(McGinley_TrendflexTolerance) == lookback_pass))
     {
      return confirmation_sell;
     }
    }
   }
   
   return confirmation_none;
  }

//+------------------------------------------------------------------+
//| Dslu of RSI lookback Function                                    |
//+------------------------------------------------------------------+
enLookbackReturn DsluRSILookback(int tolerance)
  {
   int lookbackCount = tolerance + 2;
   
   double DsluRSIColourValues[];
   CopyBuffer(DsluRSIHandle,5,1,lookbackCount,DsluRSIColourValues);
   ArrayReverse(DsluRSIColourValues);
   
   // For long signals
   if (DsluRSIColourValues[0] == 1)
   {
    for (int candlePos = 0; candlePos <= tolerance; candlePos++)
    {
     if ((DsluRSIColourValues[candlePos] == 1) && ((DsluRSIColourValues[candlePos + 1] == 0) || (DsluRSIColourValues[candlePos + 1] == 2)))
     {
      return lookback_pass;
     }
    }
   }
   
   // For short signals
   if (DsluRSIColourValues[0] == 2)
   {
    for (int candlePos = 0; candlePos <= tolerance; candlePos++)
    {
     if ((DsluRSIColourValues[candlePos] == 2) && ((DsluRSIColourValues[candlePos + 1] == 0) || (DsluRSIColourValues[candlePos + 1] == 1)))
     {
      return lookback_pass;
     }
    }
   }
   
   return lookback_fail;
  }

//+------------------------------------------------------------------+
//| Trendflex lookback Function                                      |
//+------------------------------------------------------------------+
enLookbackReturn TrendflexLookback(int tolerance)
  {
   int lookbackCount = tolerance + 2;
   
   double TrendflexFastValues[];
   CopyBuffer(TrendflexHandle,0,1,lookbackCount,TrendflexFastValues);
   ArrayReverse(TrendflexFastValues);
   
   double TrendflexSlowValues[];
   CopyBuffer(TrendflexHandle,1,1,lookbackCount,TrendflexSlowValues);
   ArrayReverse(TrendflexSlowValues);
   
   // For long signals
   if (TrendflexFastValues[0] > TrendflexSlowValues[0])
   {
    for (int candlePos = 0; candlePos <= tolerance; candlePos++)
    {
     if ((TrendflexFastValues[candlePos] > TrendflexSlowValues[candlePos]) && (TrendflexFastValues[candlePos + 1] < TrendflexSlowValues[candlePos + 1]))
     {
      return lookback_pass;
     }
    }
   }
   
   // For short signals
   if (TrendflexFastValues[0] < TrendflexSlowValues[0])
   {
    for (int candlePos = 0; candlePos <= tolerance; candlePos++)
    {
     if ((TrendflexFastValues[candlePos] < TrendflexSlowValues[candlePos]) && (TrendflexFastValues[candlePos + 1] > TrendflexSlowValues[candlePos + 1]))
     {
      return lookback_pass;
     }
    }
   }
   
   return lookback_fail;
  }

//+------------------------------------------------------------------+
//| Lot Size Calculation Function                                    |
//+------------------------------------------------------------------+
double calcLots(double riskPercentage, double slDistance)
  {
   double tickSize = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double lotStep = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   
   if (tickSize == 0 || tickValue == 0 || lotStep == 0)
   {
    Print("Lot Size Could not be calculated");
    return 0;
   }
   
   double riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * riskPercentage / 100;
   double moneyLotStep = (slDistance / tickSize) * tickValue * lotStep;
   
   if (moneyLotStep == 0)
   {
    Print("Lot Size could not be calculated.");
    return 0;
   }
   double lots = MathFloor(riskMoney / moneyLotStep) * lotStep;
   
   return lots;
  }

//+------------------------------------------------------------------+
//| Enter Position Function                                          |
//+------------------------------------------------------------------+
void EnterPosition(enTradeEntryType entryType)
  {
   double ATRChannelUpper[];
   CopyBuffer(ATRChannelHandle,1,1,1,ATRChannelUpper);
   
   double ATRChannelLower[];
   CopyBuffer(ATRChannelHandle,2,1,1,ATRChannelLower);
   
   double askPrice = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   double bidPrice = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   
   if (entryType == go_long)
   {
    double stopLossDistance = askPrice - ATRChannelLower[0];
    double takeProfitDistance = stopLossDistance * inpProfitFactor;
    double stopPrice = NormalizeDouble(ATRChannelLower[0],_Digits);
    double profitPrice = NormalizeDouble((askPrice + takeProfitDistance),_Digits);
    double lotSize = calcLots(inpRiskPerTrade,stopLossDistance);
    if (trade.Buy(lotSize,_Symbol,askPrice,stopPrice,profitPrice))
    {
     if (trade.ResultRetcode() == TRADE_RETCODE_DONE)
     {
      posTicket = trade.ResultOrder();
      inTrade = true;
     }
    }
   }
   
   if (entryType == go_short)
   {
    double stopLossDistance = ATRChannelUpper[0] - bidPrice;
    double takeProfitDistance = stopLossDistance * inpProfitFactor;
    double stopPrice = NormalizeDouble(ATRChannelUpper[0],_Digits);
    double profitPrice = NormalizeDouble((bidPrice - takeProfitDistance),_Digits);
    double lotSize = calcLots(inpRiskPerTrade,stopLossDistance);
    if (trade.Sell(lotSize,_Symbol,bidPrice,stopPrice,profitPrice))
    {
     if (trade.ResultRetcode() == TRADE_RETCODE_DONE)
     {
      posTicket = trade.ResultOrder();
      inTrade = true;
     }
    }
   }
   
  }

//+------------------------------------------------------------------+
//| Position Check/Modify function                                   |
//+------------------------------------------------------------------+
void PositionCheckModify(enTradeSignal tradeSignal)
  {
   double closePrice = iClose(_Symbol,Timeframe,1);
   double BaselineValue[];
   CopyBuffer(BaselineHandle,0,1,1,BaselineValue);
   
   if (inTrade == true)
   {
    if (PositionSelectByTicket(posTicket))
    {
     
     if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
     {
      if ((tradeSignal == sell_signal) || (closePrice < BaselineValue[0]))
      {
       if (trade.PositionClose(posTicket))
       {
        inTrade = false;
        posTicket = 0;
       }
      }
     }
     
     if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
     {
      if ((tradeSignal == buy_signal) || (closePrice > BaselineValue[0]))
      {
       if (trade.PositionClose(posTicket))
       {
        inTrade = false;
        posTicket = 0;
       }
      }
     }
     
    }
    else
    {
     inTrade = false;
     posTicket = 0;
    }
   }
   
  }

//+------------------------------------------------------------------+
