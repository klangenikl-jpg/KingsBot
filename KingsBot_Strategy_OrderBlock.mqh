#ifndef KINGSBOT_STRATEGY_ORDERBLOCK_MQH
#define KINGSBOT_STRATEGY_ORDERBLOCK_MQH

#include "KB_StrategySignal.mqh"

class CKingsBotOrderBlockStrategy
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

      double body =
         MathAbs(rates[1].close - rates[1].open);

      double range =
         rates[1].high - rates[1].low;

      if(range <= 0.0)
         return false;

      if(body / range > 0.65)
      {
         signal.direction =
            (rates[1].close > rates[1].open)
            ? KB_SIGNAL_BUY
            : KB_SIGNAL_SELL;

         signal.confidence = 0.50;
         signal.strategy   = "OrderBlock";
         signal.reason     = "Strong displacement candle";

         return true;
      }

      return false;
   }
};

#endif
