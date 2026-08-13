#pragma once

#include "KB_StrategySignal.mqh"

class CKingsBotDecisionEngine
{
public:
   bool BuildDecision(
      KBStrategySignal &signals[],
      KBStrategySignal &decision,
      double min_confidence
   )
   {
      decision.Reset();

      double buy_score = 0.0;
      double sell_score = 0.0;

      int count = ArraySize(signals);

      if(count <= 0)
         return false;

      for(int i = 0; i < count; i++)
      {
         if(signals[i].direction == KB_SIGNAL_BUY)
            buy_score += signals[i].confidence;

         if(signals[i].direction == KB_SIGNAL_SELL)
            sell_score += signals[i].confidence;
      }

      if(buy_score >= min_confidence && buy_score > sell_score)
      {
         decision.direction = KB_SIGNAL_BUY;
         decision.confidence = buy_score / count;

         if(decision.confidence > 1.0)
            decision.confidence = 1.0;

         decision.strategy = "Decision";
         decision.reason = "Bullish consensus";

         return true;
      }

      if(sell_score >= min_confidence && sell_score > buy_score)
      {
         decision.direction = KB_SIGNAL_SELL;
         decision.confidence = sell_score / count;

         if(decision.confidence > 1.0)
            decision.confidence = 1.0;

         decision.strategy = "Decision";
         decision.reason = "Bearish consensus";

         return true;
      }

      return false;
   }
};
