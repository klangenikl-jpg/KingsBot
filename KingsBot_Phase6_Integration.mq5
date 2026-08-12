#property strict

#include "KB_StrategySignal.mqh"
#include "KingsBot_Strategy_Swing.mqh"
#include "KingsBot_Strategy_Structure.mqh"
#include "KingsBot_Strategy_Liquidity.mqh"
#include "KingsBot_Strategy_OrderBlock.mqh"
#include "KingsBot_Strategy_FVG.mqh"
#include "KingsBot_DecisionEngine.mqh"
#include "KingsBot_RiskManager.mqh"
#include "KingsBot_ExecutionManager.mqh"

//==================================================
// INPUTS
//==================================================

input ulong InpMagic = 260610;
input int InpDeviationPoints = 20;
input int InpMaxSpreadPoints = 30;
input double InpDailyLossPct = 2.0;
input int InpMaxPositions = 1;
input double InpLots = 0.01;
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M15;

//==================================================
// STRATEGY OBJECTS
//==================================================

CKingsBotSwingStrategy       g_swing;
CKingsBotStructureStrategy   g_structure;
CKingsBotLiquidityStrategy   g_liquidity;
CKingsBotOrderBlockStrategy  g_orderblock;
CKingsBotFVGStrategy         g_fvg;
CKingsBotDecisionEngine      g_decision;
CKingsBotRiskManager         g_risk;
CKingsBotExecutionManager    g_execution;

//==================================================
// DAILY CONTROL
//==================================================

datetime g_last_bar = 0;
double g_day_start_equity = 0.0;
int g_day_of_year = -1;

//==================================================
// DAILY EQUITY BASELINE
//==================================================

void RefreshDailyEquityBaseline()
{
   MqlDateTime now;

   if(!TimeToStruct(TimeCurrent(), now))
      return;

   if(now.day_of_year != g_day_of_year)
   {
      g_day_of_year = now.day_of_year;
      g_day_start_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   }
}

//==================================================
// INITIALIZATION
//==================================================

int OnInit()
{
   g_risk.Configure(
      InpDailyLossPct,
      InpMaxPositions
   );

   g_execution.Configure(
      InpMagic,
      InpDeviationPoints,
      InpMaxSpreadPoints
   );

   g_day_start_equity = AccountInfoDouble(ACCOUNT_EQUITY);

   MqlDateTime now;

   if(TimeToStruct(TimeCurrent(), now))
      g_day_of_year = now.day_of_year;

   g_last_bar = 0;

   return INIT_SUCCEEDED;
}

//==================================================
// TICK PROCESSING
//==================================================

void OnTick()
{
   datetime current_bar = iTime(
      _Symbol,
      InpTimeframe,
      0
   );

   if(current_bar <= 0)
      return;

   if(current_bar == g_last_bar)
      return;

   g_last_bar = current_bar;

   RefreshDailyEquityBaseline();

   double equity = AccountInfoDouble(
      ACCOUNT_EQUITY
   );

   if(g_risk.DailyLossLimitReached(
      g_day_start_equity,
      equity
   ))
   {
      return;
   }

   if(!g_risk.CanOpenNewPosition(_Symbol))
      return;

   if(!g_execution.SpreadOK(_Symbol))
      return;

   //================================================
   // COLLECT STRATEGY SIGNALS
   //================================================

   KBStrategySignal signals[5];
   int signal_count = 0;

   KBStrategySignal signal;

   if(g_swing.Evaluate(
      _Symbol,
      InpTimeframe,
      signal
   ))
   {
      if(signal_count < 5)
         signals[signal_count++] = signal;
   }

   if(g_structure.Evaluate(
      _Symbol,
      InpTimeframe,
      signal
   ))
   {
      if(signal_count < 5)
         signals[signal_count++] = signal;
   }

   if(g_liquidity.Evaluate(
      _Symbol,
      InpTimeframe,
      signal
   ))
   {
      if(signal_count < 5)
         signals[signal_count++] = signal;
   }

   if(g_orderblock.Evaluate(
      _Symbol,
      InpTimeframe,
      signal
   ))
   {
      if(signal_count < 5)
         signals[signal_count++] = signal;
   }

   if(g_fvg.Evaluate(
      _Symbol,
      InpTimeframe,
      signal
   ))
   {
      if(signal_count < 5)
         signals[signal_count++] = signal;
   }

   if(signal_count <= 0)
      return;

   //================================================
   // BUILD FINAL DECISION
   //================================================

   KBStrategySignal decision;

   if(!g_decision.BuildDecision(
      signals,
      decision,
      0.55
   ))
   {
      return;
   }

   //================================================
   // MARKET DATA
   //================================================

   double point = SymbolInfoDouble(
      _Symbol,
      SYMBOL_POINT
   );

   int digits = (int)SymbolInfoInteger(
      _Symbol,
      SYMBOL_DIGITS
   );

   double bid = SymbolInfoDouble(
      _Symbol,
      SYMBOL_BID
   );

   double ask = SymbolInfoDouble(
      _Symbol,
      SYMBOL_ASK
   );

   if(point <= 0.0)
      return;

   if(bid <= 0.0 || ask <= 0.0)
      return;

   //================================================
   // INITIAL STOP/TAKE-PROFIT DISTANCES
   //================================================

   double sl_distance = 100.0 * point;
   double tp_distance = 200.0 * point;

   //================================================
   // BUY
   //================================================

   if(decision.direction == KB_SIGNAL_BUY)
   {
      double sl = NormalizeDouble(
         ask - sl_distance,
         digits
      );

      double tp = NormalizeDouble(
         ask + tp_distance,
         digits
      );

      g_execution.Buy(
         _Symbol,
         InpLots,
         sl,
         tp,
         "KingsBot Phase6"
      );

      return;
   }

   //================================================
   // SELL
   //================================================

   if(decision.direction == KB_SIGNAL_SELL)
   {
      double sl = NormalizeDouble(
         bid + sl_distance,
         digits
      );

      double tp = NormalizeDouble(
         bid - tp_distance,
         digits
      );

      g_execution.Sell(
         _Symbol,
         InpLots,
         sl,
         tp,
         "KingsBot Phase6"
      );

      return;
   }
}
