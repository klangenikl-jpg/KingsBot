#ifndef KINGSBOT_STRATEGY_FVG_MQH
#define KINGSBOT_STRATEGY_FVG_MQH

#include "KB_StrategySignal.mqh"

class CKingsBotFVGStrategy
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

      if(rates[0].low > rates[2].high)
      {
         signal.direction  = KB_SIGNAL_BUY;
         signal.confidence = 0.55;
         signal.strategy   = "FVG";
         signal.reason     = "Bullish fair value gap";

         return true;
      }

      if(rates[0].high < rates[2].low)
      {
         signal.direction  = KB_SIGNAL_SELL;
         signal.confidence = 0.55;
         signal.strategy   = "FVG";
         signal.reason     = "Bearish fair value gap";

         return true;
      }

      return false;
   }
};

#endif
