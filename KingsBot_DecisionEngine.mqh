#pragma once

#include "KB_StrategySignal.mqh"

class CKingsBotDecisionEngine
{
public:

   bool BuildDecision(
      KBStrategySignal &signals[],
      const int signal_count,
      KBStrategySignal &decision,
      const double min_confidence = 0.55
   )
   {
      // Reset decision explicitly because KBStrategySignal
      // does not contain a Reset() method.
      decision.direction   = KB_SIGNAL_NONE;
      decision.confidence  = 0.0;
      decision.entry       = 0.0;
      decision.stop_loss   = 0.0;
      decision.take_profit = 0.0;
      decision.strategy    = "";
      decision.reason      = "";

      if(signal_count <= 0)
         return false;

      int count = signal_count;

      // Never read beyond the actual signal array.
      int available = ArraySize(signals);
      if(count > available)
         count = available;

      if(count <= 0)
         return false;

      double buy  = 0.0;
      double sell = 0.0;

      for(int i = 0; i < count; i++)
      {
         if(signals[i].direction == KB_SIGNAL_BUY)
            buy += signals[i].confidence;

         else if(signals[i].direction == KB_SIGNAL_SELL)
            sell += signals[i].confidence;
      }

      if(buy >= min_confidence && buy > sell)
      {
         decision.direction  = KB_SIGNAL_BUY;
         decision.confidence = MathMin(1.0, buy / count);
         decision.strategy   = "Decision";
         decision.reason     = "Bullish consensus";
         return true;
      }

      if(sell >= min_confidence && sell > buy)
      {
         decision.direction  = KB_SIGNAL_SELL;
         decision.confidence = MathMin(1.0, sell / count);
         decision.strategy   = "Decision";
         decision.reason     = "Bearish consensus";
         return true;
      }

      return false;
   }
};
