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


input ulong InpMagic = 260610;
input int InpDeviationPoints = 20;
input int InpMaxSpreadPoints = 30;
input double InpDailyLossPct = 2.0;
input int InpMaxPositions = 1;
input double InpLots = 0.01;
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M15;


CKingsBotSwingStrategy       g_swing;
CKingsBotStructureStrategy   g_structure;
CKingsBotLiquidityStrategy   g_liquidity;
CKingsBotOrderBlockStrategy  g_orderblock;
CKingsBotFVGStrategy         g_fvg;

CKingsBotDecisionEngine      g_decision;
CKingsBotRiskManager         g_risk;
CKingsBotExecutionManager    g_execution;


datetime g_last_bar = 0;
double   g_day_start_equity = 0.0;
int      g_day_of_year = -1;


void RefreshDailyEquityBaseline()
{
   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);

   if(now.day_of_year != g_day_of_year)
   {
      g_day_of_year = now.day_of_year;
      g_day_start_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   }
}


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

   g_day_start_equity = AccountInfoDouble(
      ACCOUNT_EQUITY
   );

   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);

   g_day_of_year = now.day_of_year;
   g_last_bar = 0;

   return INIT_SUCCEEDED;
}


void OnTick()
{
   datetime bar = iTime(
      _Symbol,
      InpTimeframe,
      0
   );

   if(bar == 0)
      return;

   if(bar == g_last_bar)
      return;

   g_last_bar = bar;

   RefreshDailyEquityBaseline();


   double equity = AccountInfoDouble(
      ACCOUNT_EQUITY
   );

   if(g_risk.DailyLossLimitReached(
      g_day_start_equity,
      equity
   ))
      return;


   if(!g_risk.CanOpenNewPosition(
      _Symbol
   ))
      return;


   if(!g_execution.SpreadOK(
      _Symbol
   ))
      return;


   KBStrategySignal signals[5];
   int count = 0;

   KBStrategySignal signal;


   signal.Reset();

   if(g_swing.Evaluate(
      _Symbol,
      InpTimeframe,
      signal
   ))
   {
      signals[count] = signal;
      count++;
   }


   signal.Reset();

   if(g_structure.Evaluate(
      _Symbol,
      InpTimeframe,
      signal
   ))
   {
      signals[count] = signal;
      count++;
   }


   signal.Reset();

   if(g_liquidity.Evaluate(
      _Symbol,
      InpTimeframe,
      signal
   ))
   {
      signals[count] = signal;
      count++;
   }


   signal.Reset();

   if(g_orderblock.Evaluate(
      _Symbol,
      InpTimeframe,
      signal
   ))
   {
      signals[count] = signal;
      count++;
   }


   signal.Reset();

   if(g_fvg.Evaluate(
      _Symbol,
      InpTimeframe,
      signal
   ))
   {
      signals[count] = signal;
      count++;
   }


   if(count <= 0)
      return;


   KBStrategySignal decision;
   decision.Reset();


   if(!g_decision.BuildDecision(
      signals,
      count,
      decision,
      0.55
   ))
      return;


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


  
