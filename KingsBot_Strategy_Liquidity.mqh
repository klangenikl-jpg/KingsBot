#ifndef KINGSBOT_STRATEGY_LIQUIDITY_MQH
#define KINGSBOT_STRATEGY_LIQUIDITY_MQH

#include "KB_StrategySignal.mqh"

class CKingsBotLiquidityStrategy
{
public:
   bool Evaluate(
      const string symbol,
      const ENUM_TIMEFRAMES tf,
      KBStrategySignal &signal
   )
   {
      signal.Reset();

      MqlRates rates[10];

      if(CopyRates(symbol, tf, 1, 10, rates) != 10)
         return false;

      double hi = rates[1].high;
      double lo = rates[1].low;

      for(int i = 2; i < 10; i++)
      {
         if(rates[i].high > hi)
            hi = rates[i].high;

         if(rates[i].low < lo)
            lo = rates[i].low;
      }

      double bid = SymbolInfoDouble(
         symbol,
         SYMBOL_BID
      );

      if(bid > hi)
      {
         signal.direction  = KB_SIGNAL_BUY;
         signal.confidence = 0.50;
         signal.strategy   = "Liquidity";
         signal.reason     = "High sweep";

         return true;
      }

      if(bid < lo)
      {
         signal.direction  = KB_SIGNAL_SELL;
         signal.confidence = 0.50;
         signal.strategy   = "Liquidity";
         signal.reason     = "Low sweep";

         return true;
      }

      return false;
   }
};

#endif
