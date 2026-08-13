#pragma once

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
      decision.direction   = KB_SIGNAL_NONE;
      decision.confidence  = 0.0;
      decision.entry       = 0.0;
      decision.stop_loss   = 0.0;
      decision.take_profit = 0.0;
      decision.strategy    = "";
      decision.reason      = "";

      int count = ArraySize(signals);

      if(signal_count <= 0 || count <= 0)
         return false;

      if(signal_count < count)
         count = signal_count;

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
