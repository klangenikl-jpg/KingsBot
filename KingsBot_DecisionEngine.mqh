#pragma once

class CKingsBotDecisionEngine
{
public:
   bool BuildDecision(
      KBStrategySignal &signals[],
      int signal_count,
      KBStrategySignal &decision,
      double min_confidence = 0.55
   )
   {
      decision.direction   = KB_SIGNAL_NONE;
      decision.confidence  = 0.0;
      decision.entry       = 0.0;
      decision.stop_loss   = 0.0;
      decision.take_profit = 0.0;
      decision.strategy    = "";
      decision.reason      = "";

      if(signal_count <= 0)
         return false;

      double buy_score  = 0.0;
      double sell_score = 0.0;

      for(int i = 0; i < signal_count; i++)
      {
         if(signals[i].direction == KB_SIGNAL_BUY)
            buy_score += signals[i].confidence;
         else
         if(signals[i].direction == KB_SIGNAL_SELL)
            sell_score += signals[i].confidence;
      }

      if(buy_score >= min_confidence && buy_score > sell_score)
      {
         decision.direction  = KB_SIGNAL_BUY;
         decision.confidence = MathMin(1.0, buy_score / signal_count);
         decision.strategy   = "Decision";
         decision.reason     = "Bullish consensus";
         return true;
      }

      if(sell_score >= min_confidence && sell_score > buy_score)
      {
         decision.direction  = KB_SIGNAL_SELL;
         decision.confidence = MathMin(1.0, sell_score / signal_count);
         decision.strategy   = "Decision";
         decision.reason     = "Bearish consensus";
         return true;
      }

      return false;
   }
};
