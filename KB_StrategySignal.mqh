#pragma once

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
};
