#pragma once
#include "KB_StrategySignal.mqh"
class CKingsBotStructureStrategy
{
public:
   bool Evaluate(const string symbol,const ENUM_TIMEFRAMES tf,KBStrategySignal &signal)
   {
      signal.Reset();
      MqlRates r[3];
      if(CopyRates(symbol,tf,0,3,r)!=3) return false;
      if(r[0].close>r[1].high)
      {
         signal.direction=KB_SIGNAL_BUY; signal.confidence=0.55;
         signal.strategy="Structure"; signal.reason="Break above prior high"; return true;
      }
      if(r[0].close<r[1].low)
      {
         signal.direction=KB_SIGNAL_SELL; signal.confidence=0.55;
         signal.strategy="Structure"; signal.reason="Break below prior low"; return true;
      }
      return false;
   }
};
