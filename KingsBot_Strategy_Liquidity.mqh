#pragma once
#include "KB_StrategySignal.mqh"
class CKingsBotLiquidityStrategy
{
public:
   bool Evaluate(const string symbol,const ENUM_TIMEFRAMES tf,KBStrategySignal &signal)
   {
      signal.Reset();
      MqlRates r[10];
      if(CopyRates(symbol,tf,1,10,r)!=10) return false;
      double hi=r[1].high, lo=r[1].low;
      for(int i=2;i<10;i++){ if(r[i].high>hi) hi=r[i].high; if(r[i].low<lo) lo=r[i].low; }
      double bid=SymbolInfoDouble(symbol,SYMBOL_BID);
      if(bid>hi){signal.direction=KB_SIGNAL_BUY;signal.confidence=0.50;signal.strategy="Liquidity";signal.reason="High sweep";return true;}
      if(bid<lo){signal.direction=KB_SIGNAL_SELL;signal.confidence=0.50;signal.strategy="Liquidity";signal.reason="Low sweep";return true;}
      return false;
   }
};
