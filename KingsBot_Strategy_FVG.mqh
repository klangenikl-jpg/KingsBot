#pragma once
#include "KB_StrategySignal.mqh"
class CKingsBotFVGStrategy
{
public:
   bool Evaluate(const string symbol,const ENUM_TIMEFRAMES tf,KBStrategySignal &signal)
   {
      signal.Reset();
      MqlRates r[3];
      if(CopyRates(symbol,tf,0,3,r)!=3) return false;
      if(r[0].low>r[2].high)
      {
         signal.direction=KB_SIGNAL_BUY;signal.confidence=0.55;
         signal.strategy="FVG";signal.reason="Bullish fair value gap";return true;
      }
      if(r[0].high<r[2].low)
      {
         signal.direction=KB_SIGNAL_SELL;signal.confidence=0.55;
         signal.strategy="FVG";signal.reason="Bearish fair value gap";return true;
      }
      return false;
   }
};
