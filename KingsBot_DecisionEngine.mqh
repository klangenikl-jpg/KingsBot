#pragma once
#include "KB_StrategySignal.mqh"
class CKingsBotDecisionEngine
{
public:
   bool BuildDecision(KBStrategySignal &signals[],KBStrategySignal &decision,const double min_confidence=0.55)
   {
      decision.Reset();
      double buy=0.0,sell=0.0;
      int n=ArraySize(signals);
      for(int i=0;i<n;i++)
      {
         if(signals[i].direction==KB_SIGNAL_BUY) buy+=signals[i].confidence;
         if(signals[i].direction==KB_SIGNAL_SELL) sell+=signals[i].confidence;
      }
      if(buy>=min_confidence && buy>sell){decision.direction=KB_SIGNAL_BUY;decision.confidence=MathMin(1.0,buy/MathMax(1,n));decision.strategy="Decision";decision.reason="Bullish consensus";return true;}
      if(sell>=min_confidence && sell>buy){decision.direction=KB_SIGNAL_SELL;decision.confidence=MathMin(1.0,sell/MathMax(1,n));decision.strategy="Decision";decision.reason="Bearish consensus";return true;}
      return false;
   }
};
