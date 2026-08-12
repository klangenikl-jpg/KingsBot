#ifndef KB_STRATEGY_SIGNAL_MQH
#define KB_STRATEGY_SIGNAL_MQH

enum KBSignalDirection
{
   KB_SIGNAL_NONE = 0,
   KB_SIGNAL_BUY  = 1,
   KB_SIGNAL_SELL = -1
};

struct KBStrategySignal
{
   KBSignalDirection direction;
   double confidence;
   double entry;
   double stop_loss;
   double take_profit;
   string strategy;
   string reason;

   void Reset()
   {
      direction   = KB_SIGNAL_NONE;
      confidence  = 0.0;
      entry       = 0.0;
      stop_loss   = 0.0;
      take_profit = 0.0;
      strategy    = "";
      reason      = "";
   }
};

#endif // KB_STRATEGY_SIGNAL_MQH
