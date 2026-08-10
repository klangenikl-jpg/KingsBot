#pragma once
#include "KB_StrategySignal.mqh"
class CKingsBotOrderBlockStrategy
{
public:
   bool Evaluate(const string symbol,const ENUM_TIMEFRAMES tf,KBStrategySignal &signal)
   {
      signal.Reset();
      MqlRates r[3];
      if(CopyRates(symbol,tf,0,3,r)!=3) return false;
      double body=MathAbs(r[1].close-r[1].open);
      double range=r[1].high-r[1].low;
      if(range<=0.0) return false;
      if(body/range>0.65)
      {
         signal.direction=(r[1].close>r[1].open)?KB_SIGNAL_BUY:KB_SIGNAL_SELL;
         signal.confidence=0.50;
         signal.strategy="OrderBlock";
         signal.reason="Strong displacement candle";
         return true;
      }
      return false;
   }
};
