#pragma once
#include "KB_StrategySignal.mqh"

class CKingsBotSwingStrategy
{
public:
   bool Evaluate(const string symbol,const ENUM_TIMEFRAMES tf,KBStrategySignal &signal)
   {
      signal.Reset();
      double fast[2], slow[2];
      int hFast=iMA(symbol,tf,20,0,MODE_EMA,PRICE_CLOSE);
      int hSlow=iMA(symbol,tf,50,0,MODE_EMA,PRICE_CLOSE);
      if(hFast==INVALID_HANDLE || hSlow==INVALID_HANDLE)
      {
         if(hFast!=INVALID_HANDLE) IndicatorRelease(hFast);
         if(hSlow!=INVALID_HANDLE) IndicatorRelease(hSlow);
         return false;
      }
      bool ok=(CopyBuffer(hFast,0,0,2,fast)==2 && CopyBuffer(hSlow,0,0,2,slow)==2);
      IndicatorRelease(hFast);
      IndicatorRelease(hSlow);
      if(!ok) return false;

      if(fast[0]>slow[0])
      {
         signal.direction=KB_SIGNAL_BUY;
         signal.confidence=0.60;
         signal.strategy="Swing";
         signal.reason="20 EMA above 50 EMA";
         return true;
      }
      if(fast[0]<slow[0])
      {
         signal.direction=KB_SIGNAL_SELL;
         signal.confidence=0.60;
         signal.strategy="Swing";
         signal.reason="20 EMA below 50 EMA";
         return true;
      }
      return false;
   }
};
