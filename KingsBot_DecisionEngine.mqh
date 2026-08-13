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
      decision.Reset();

      double buy = 0.0;
      double sell = 0.0;

      if(signal_count <= 0)
         return false;

      for(int i = 0; i < signal_count; i++)
      {
         if(signals[i].direction == KB_SIGNAL_BUY)
            buy += signals[i].confidence;

         if(signals[i].direction == KB_SIGNAL_SELL)
            sell += signals[i].confidence;
      }

      if(buy >= min_confidence && buy > sell)
      {
         decision.direction = KB_SIGNAL_BUY;
         decision.confidence = MathMin(1.0, buy / signal_count);
         decision.strategy = "Decision";
         decision.reason = "Bullish consensus";
         return true;
      }

      if(sell >= min_confidence && sell > buy)
      {
         decision.direction = KB_SIGNAL_SELL;
         decision.confidence = MathMin(1.0, sell / signal_count);
         decision.strategy = "Decision";
         decision.reason = "Bearish consensus";
         return true;
      }

      return false;
   }
};
