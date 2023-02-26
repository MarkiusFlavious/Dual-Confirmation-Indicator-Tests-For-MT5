#include <Trade/Trade.mqh>

// Custom enums:
enum enum_trade_signal {
   buy_signal,
   sell_signal,
   no_signal,
   bullish,
   bearish
};

enum enum_entry_type {
   go_long,
   go_short
};

enum enum_indicator_dominance {
   c1_dominance,
   c2_dominance,
   dual_dominance
};


class DualConfirmationBase : public CObject {
   
private:   
   
   // Private Input Variables:
   string Pair;
   ENUM_TIMEFRAMES Timeframe;
   
   double Risk_Percent;
   double Profit_Factor;
   int ATR_Period;
   double ATR_Factor;
   ENUM_APPLIED_PRICE ATR_Applied_Price;
   
   // Put Indicator Input Variables Here
   
   int Indicator1_Tolerance;
   int Indicator2_Tolerance;
   
   enum_indicator_dominance Dominance_Type;
   
   //Indicator Handles:
   int ATR_Channel_Handle;
   
   
   int Bar_Total;
   ulong Ticket_Number;
   bool Is_In_Trade;
   CTrade trade;
   
   // Private Function Declarations:
   
   enum_trade_signal               LookForTradeSignal();
   enum_trade_signal               CheckConfirmationIndicators();
   enum_trade_signal               C1Signal();
   enum_trade_signal               C2Signal();
   bool                            C1Lookback(int tolerance);
   bool                            C2Lookback(int tolerance);
   double                          CalculateLotSize(double risk_percent, double sl_distance);
   void                            EnterPosition(enum_entry_type Entry_Type);
   void                            PositionCheckModify(enum_trade_signal Trade_Signal);
   
   
public:
   
   int                             OnInitEvent();
   void                            OnDeinitEvent(const int reason);
   void                            OnTickEvent();
   
   DualConfirmationBase(string input_pair, ENUM_TIMEFRAMES input_timeframe, double input_risk_percent, double input_profit_factor, 
                        int input_atr_period, double input_atr_factor,ENUM_APPLIED_PRICE input_atr_applied_price, 
                        int input_indi1_tolerance, int input_indi2_tolerance, enum_indicator_dominance input_dominance_type){
      
      Pair = input_pair;
      Timeframe = input_timeframe;
      
      Risk_Percent = input_risk_percent;
      Profit_Factor = input_profit_factor;
      ATR_Period = input_atr_period;
      ATR_Factor = input_atr_factor;
      ATR_Applied_Price = input_atr_applied_price;
      
      // indicator inputs go here
      
      Indicator1_Tolerance = input_indi1_tolerance;
      Indicator2_Tolerance = input_indi2_tolerance;
      Dominance_Type = input_dominance_type;
   
   }
   
   ~DualConfirmationBase(){}  
};

// Look for Trade Signal Function
enum_trade_signal DualConfirmationBase::LookForTradeSignal(){
   
   enum_trade_signal Confirmation_Signals = CheckConfirmationIndicators();
   
   if (Confirmation_Signals == buy_signal){
      return buy_signal;
   }
   
   else if (Confirmation_Signals == sell_signal){
      return sell_signal;
   }
   
   return no_signal;
}

// Check Confirmation Indicators Function
enum_trade_signal DualConfirmationBase::CheckConfirmationIndicators(){
   
   if (Dominance_Type == c1_dominance){
      
      if (C1Signal() == buy_signal && (C2Signal() == buy_signal || bullish)){
         if (C2Lookback(Indicator2_Tolerance)){
            return buy_signal;
         }
      }
      
      else if (C1Signal() == sell_signal && (C2Signal() == sell_signal || bearish)){
         if(C2Lookback(Indicator2_Tolerance)){
            return sell_signal;
         }
      }
      else return no_signal;
   }
   
   else if (Dominance_Type == c2_dominance){
      
      if (C2Signal() == buy_signal && (C1Signal() == buy_signal || bullish)){
         if (C1Lookback(Indicator1_Tolerance)){
            return buy_signal;
         }
      }
      
      else if (C2Signal() == sell_signal && (C1Signal() == sell_signal || bearish)){
         if(C1Lookback(Indicator1_Tolerance)){
            return sell_signal;
         }
      }
      else return no_signal;
   }
   
   else if (Dominance_Type == dual_dominance){
      if (C1Signal() || C2Signal() == buy_signal){
         
         if (C1Signal() && C2Signal() == buy_signal){
            return buy_signal;
         }
         else if (C1Signal() == bullish){
            if (C1Lookback(Indicator1_Tolerance)){
               return buy_signal;
            }
         }
         else if (C2Signal() == bullish){
            if (C2Lookback(Indicator2_Tolerance)){
               return buy_signal;
            }
         }
      }
      else if (C1Signal() || C2Signal() == sell_signal){
         
         if (C1Signal() && C2Signal() == sell_signal){
            return sell_signal;
         }
         else if (C1Signal() == bearish){
            if (C1Lookback(Indicator1_Tolerance)){
               return sell_signal;
            }
         }
         else if (C2Signal() == bearish){
            if (C2Lookback(Indicator2_Tolerance)){
               return sell_signal;
            }
         }
      }
      else return no_signal;
   }
   return no_signal;
}

// Check C1 Signal Function
enum_trade_signal DualConfirmationBase::C1Signal(){
   
   return no_signal;
}
// Check C2 Signal Function
enum_trade_signal DualConfirmationBase::C2Signal(){
   
   return no_signal;
}
// C1 Lookback Function
bool DualConfirmationBase::C1Lookback(int tolerance){
   int candleLookbackCount = tolerance + 2;
   
   // For long signals
   /*
   if (){
      for (int candlePos = 0; candlePos <= tolerance; candlePos++){
         if (() && ()){
            return true;
         }
      } 
   }
   */
   
   // For short signals
   
   return false;
}

// C2 Lookback Function
bool DualConfirmationBase::C2Lookback(int tolerance){
   int candleLookbackCount = tolerance + 2;
   
   // For long signals
   /*
   if (){
      for (int candlePos = 0; candlePos <= tolerance; candlePos++){
         if (() && ()){
            return true;
         }
      } 
   }
   */
   
   // For short signals
   
   return false;
}

// Calculate Lot Size Function
double DualConfirmationBase::CalculateLotSize(double risk_percent,double sl_distance){
   
   double tickSize = SymbolInfoDouble(Pair,SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(Pair,SYMBOL_TRADE_TICK_VALUE);
   double lotStep = SymbolInfoDouble(Pair,SYMBOL_VOLUME_STEP);
   
   if (tickSize == 0 || tickValue == 0 || lotStep == 0){
      Print("Lot Size Could not be calculated");
      return 0;
   }
   
   double riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * risk_percent / 100;
   double moneyLotStep = (sl_distance / tickSize) * tickValue * lotStep;
   
   if (moneyLotStep == 0){
      Print("Lot Size could not be calculated.");
      return 0;
   }
   
   double lots = MathFloor(riskMoney / moneyLotStep) * lotStep;
   return lots;

}

// Enter Position Function
void DualConfirmationBase::EnterPosition(enum_entry_type Entry_Type){
   
   double ATRChannelUpper[];
   CopyBuffer(ATR_Channel_Handle,1,1,1,ATRChannelUpper);
   double ATRChannelLower[];
   CopyBuffer(ATR_Channel_Handle,2,1,1,ATRChannelLower);
   
   int digits = (int)SymbolInfoInteger(Pair,SYMBOL_DIGITS);
   double askPrice = NormalizeDouble(SymbolInfoDouble(Pair,SYMBOL_ASK),digits);
   double bidPrice = NormalizeDouble(SymbolInfoDouble(Pair,SYMBOL_BID),digits);
   
   if (Entry_Type == go_long){
      double stopLossDistance = askPrice - ATRChannelLower[0];
      double takeProfitDistance = stopLossDistance * Profit_Factor;
      double stopPrice = NormalizeDouble(ATRChannelLower[0],digits);
      double profitPrice = NormalizeDouble((askPrice + takeProfitDistance),digits);
      double lotSize = CalculateLotSize(Risk_Percent,stopLossDistance);
    
      if (trade.Buy(lotSize,Pair,askPrice,stopPrice,profitPrice)){
         if (trade.ResultRetcode() == TRADE_RETCODE_DONE){
            Ticket_Number = trade.ResultOrder();
            Is_In_Trade = true;
         }
      }
   }
   
   if (Entry_Type == go_short){
      double stopLossDistance = ATRChannelUpper[0] - bidPrice;
      double takeProfitDistance = stopLossDistance * Profit_Factor;
      double stopPrice = NormalizeDouble(ATRChannelUpper[0],digits);
      double profitPrice = NormalizeDouble((bidPrice - takeProfitDistance),digits);
      double lotSize = CalculateLotSize(Risk_Percent,stopLossDistance);
      
      if (trade.Sell(lotSize,Pair,bidPrice,stopPrice,profitPrice)){
         if (trade.ResultRetcode() == TRADE_RETCODE_DONE){
            Ticket_Number = trade.ResultOrder();
            Is_In_Trade = true;
         }
      }
   }
}

// Position Check/Modify Function
void DualConfirmationBase::PositionCheckModify(enum_trade_signal Trade_Signal){
   
   if (Is_In_Trade){
      if (PositionSelectByTicket(Ticket_Number)){
      
         if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
            if (Trade_Signal == sell_signal){
               if (trade.PositionClose(Ticket_Number)){
                  Is_In_Trade = false;
                  Ticket_Number = NULL;
               }
            }
         }
     
         if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
            if (Trade_Signal == buy_signal){
               if (trade.PositionClose(Ticket_Number)){
                  Is_In_Trade = false;
                  Ticket_Number = NULL;
               }
            }
         } 
      }
      
      else{ // If we cannot select the trade, it has either hit the tp or sl.
         Is_In_Trade = false;
         Ticket_Number = NULL;
      }
   }
}

// OnInit Event Function
int DualConfirmationBase::OnInitEvent(){
   
   Bar_Total = iBars(Pair,Timeframe);
   ATR_Channel_Handle = iCustom(Pair,Timeframe,"ATR Channel.ex5",MODE_SMA,1,ATR_Period,ATR_Factor,ATR_Applied_Price);
   
   
   return INIT_SUCCEEDED;
}

// OnDeinit Event Function
void DualConfirmationBase::OnDeinitEvent(const int reason){

}

// OnTick Event Function
void DualConfirmationBase::OnTickEvent(){
   
   int Bar_Total_Updated = iBars(Pair,Timeframe);
   
   if (Bar_Total != Bar_Total_Updated){
      
      Bar_Total = Bar_Total_Updated;
      enum_trade_signal tradeSignal = LookForTradeSignal();
      PositionCheckModify(tradeSignal);
    
      if (!Is_In_Trade){
         
         if (tradeSignal == buy_signal){
            EnterPosition(go_long);
         }
         if (tradeSignal == sell_signal){
            EnterPosition(go_short);
         }
      } 
   }
}