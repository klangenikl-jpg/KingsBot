#ifndef KINGSBOT_STRATEGY_STRUCTURE_MQH
#define KINGSBOT_STRATEGY_STRUCTURE_MQH

#include "KB_StrategySignal.mqh"

class CKingsBotStructureStrategy
{
public:
   bool Evaluate(
      const string symbol,
      const ENUM_TIMEFRAMES tf,
      KBStrategySignal &signal
   )
   {
      signal.Reset();

      MqlRates rates[3];

      if(CopyRates(symbol, tf, 0, 3, rates) != 3)
         return false;

      if(rates[0].close > rates[1].high)
      {
         signal.direction  = KB_SIGNAL_BUY;
         signal.confidence = 0.55;
         signal.strategy   = "Structure";
         signal.reason     = "Break above prior high";

         return true;
      }

      if(rates[0].close < rates[1].low)
      {
         signal.direction  = KB_SIGNAL_SELL;
         signal.confidence = 0.55;
         signal.strategy   = "Structure";
         signal.reason     = "Break below prior low";

         return true;
      }

      return false;
   }
};

#endif
