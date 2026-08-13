#property strict

#include "KB_StrategySignal.mqh"
#include "KingsBot_Strategy_Swing.mqh"
#include "KingsBot_Strategy_Structure.mqh"
#include "KingsBot_Strategy_Liquidity.mqh"
#include "KingsBot_Strategy_OrderBlock.mqh"
#include "KingsBot_Strategy_FVG.mqh"
#include "KingsBot_DecisionEngine.mqh"
#include "KingsBot_RiskManager.mqh"

input ulong InpMagic = 260610;
input int InpDeviationPoints = 20;
input int InpMaxSpreadPoints = 30;
input double InpDailyLossPct = 2.0;
input int InpMaxPositions = 1;
input double InpLots = 0.01;
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M15;

CKingsBotSwingStrategy      g_swing;
CKingsBotStructureStrategy  g_structure;
CKingsBotLiquidityStrategy  g_liquidity;
CKingsBotOrderBlockStrategy g_orderblock;
CKingsBotFVGStrategy        g_fvg;
CKingsBotDecisionEngine     g_decision;
CKingsBotRiskManager        g_risk;

datetime g_last_bar = 0;
double   g_day_start_equity = 0.0;
int      g_day_of_year = -1;


bool SpreadOK(const string symbol)
{
   long spread = 0;

   if(!SymbolInfoInteger(
      symbol,
      SYMBOL_SPREAD,
      spread
   ))
   {
      return false;
   }

   if(InpMaxSpreadPoints <= 0)
   {
      return true;
   }

   return (spread <= InpMaxSpreadPoints);
}


void RefreshDailyEquityBaseline()
{
   MqlDateTime now;

   TimeToStruct(
      TimeCurrent(),
      now
   );

   if(now.day_of_year != g_day_of_year)
   {
      g_day_of_year = now.day_of_year;

      g_day_start_equity =
         AccountInfoDouble(
            ACCOUNT_EQUITY
         );
   }
}


bool ExecuteBuy(
   const double volume,
   const double stop_loss,
   const double take_profit
)
{
   MqlTradeRequest request;
   MqlTradeResult  result;

   ZeroMemory(request);
   ZeroMemory(result);

   request.action =
      TRADE_ACTION_DEAL;

   request.symbol =
      _Symbol;

   request.volume =
      volume;

   request.type =
      ORDER_TYPE_BUY;

   request.price =
      SymbolInfoDouble(
         _Symbol,
         SYMBOL_ASK
      );

   request.sl =
      stop_loss;

   request.tp =
      take_profit;

   request.deviation =
      InpDeviationPoints;

   request.magic =
      InpMagic;

   request.comment =
      "KingsBot Phase6 BUY";

   request.type_filling =
      ORDER_FILLING_FOK;

   if(!OrderSend(
      request,
      result
   ))
   {
      Print(
         "KingsBot BUY failed. Error=",
         GetLastError()
      );

      return false;
   }

   if(
      result.retcode != TRADE_RETCODE_DONE &&
      result.retcode != TRADE_RETCODE_PLACED &&
      result.retcode != TRADE_RETCODE_DONE_PARTIAL
   )
   {
      Print(
         "KingsBot BUY rejected. Retcode=",
         result.retcode,
         " Comment=",
         result.comment
      );

      return false;
   }

   return true;
}


bool ExecuteSell(
   const double volume,
   const double stop_loss,
   const double take_profit
)
{
   MqlTradeRequest request;
   MqlTradeResult  result;

   ZeroMemory(request);
   ZeroMemory(result);

   request.action =
      TRADE_ACTION_DEAL;

   request.symbol =
      _Symbol;

   request.volume =
      volume;

   request.type =
      ORDER_TYPE_SELL;

   request.price =
      SymbolInfoDouble(
         _Symbol,
         SYMBOL_BID
      );

   request.sl =
      stop_loss;

   request.tp =
      take_profit;

   request.deviation =
      InpDeviationPoints;

   request.magic =
      InpMagic;

   request.comment =
      "KingsBot Phase6 SELL";

   request.type_filling =
      ORDER_FILLING_FOK;

   if(!OrderSend(
      request,
      result
   ))
   {
      Print(
         "KingsBot SELL failed. Error=",
         GetLastError()
      );

      return false;
   }

   if(
      result.retcode != TRADE_RETCODE_DONE &&
      result.retcode != TRADE_RETCODE_PLACED &&
      result.retcode != TRADE_RETCODE_DONE_PARTIAL
   )
   {
      Print(
         "KingsBot SELL rejected. Retcode=",
         result.retcode,
         " Comment=",
         result.comment
      );

      return false;
   }

   return true;
}


int OnInit()
{
   g_risk.Configure(
      InpDailyLossPct,
      InpMaxPositions
   );

   g_day_start_equity =
      AccountInfoDouble(
         ACCOUNT_EQUITY
      );

   MqlDateTime now;

   TimeToStruct(
      TimeCurrent(),
      now
   );

   g_day_of_year =
      now.day_of_year;

   g_last_bar = 0;

   return INIT_SUCCEEDED;
}


void OnTick()
{
   datetime bar =
      iTime(
         _Symbol,
         InpTimeframe,
         0
      );

   if(bar == 0)
   {
      return;
   }

   if(bar == g_last_bar)
   {
      return;
   }

   g_last_bar = bar;

   RefreshDailyEquityBaseline();


   double equity =
      AccountInfoDouble(
         ACCOUNT_EQUITY
      );

   if(g_risk.DailyLossLimitReached(
      g_day_start_equity,
      equity
   ))
   {
      return;
   }


   if(!g_risk.CanOpenNewPosition(
      _Symbol
   ))
   {
      return;
   }


   if(!SpreadOK(
      _Symbol
   ))
   {
      return;
   }


   KBStrategySignal signals[5];

   int signal_count = 0;

   KBStrategySignal signal;


   signal.Reset();

   if(g_swing.Evaluate(
      _Symbol,
      InpTimeframe,
      signal
   ))
   {
      signals[signal_count] =
         signal;

      signal_count++;
   }


   signal.Reset();

   if(g_structure.Evaluate(
      _Symbol,
      InpTimeframe,
      signal
   ))
   {
      signals[signal_count] =
         signal;

      signal_count++;
   }


   signal.Reset();

   if(g_liquidity.Evaluate(
      _Symbol,
      InpTimeframe,
      signal
   ))
   {
      signals[signal_count] =
         signal;

      signal_count++;
   }


   signal.Reset();

   if(g_orderblock.Evaluate(
      _Symbol,
      InpTimeframe,
      signal
   ))
   {
      signals[signal_count] =
         signal;

      signal_count++;
   }


   signal.Reset();

   if(g_fvg.Evaluate(
      _Symbol,
      InpTimeframe,
      signal
   ))
   {
      signals[signal_count] =
         signal;

      signal_count++;
   }


   if(signal_count <= 0)
   {
      return;
   }


   KBStrategySignal decision;

   decision.Reset();


   if(!g_decision.BuildDecision(
      signals,
      signal_count,
      decision,
      0.55
   ))
   {
      return;
   }


   double point =
      SymbolInfoDouble(
         _Symbol,
         SYMBOL_POINT
      );

   int digits =
      (int)SymbolInfoInteger(
         _Symbol,
         SYMBOL_DIGITS
      );

   double bid =
      SymbolInfoDouble(
         _Symbol,
         SYMBOL_BID
      );

   double ask =
      SymbolInfoDouble(
         _Symbol,
         SYMBOL_ASK
      );


   if(point <= 0.0)
   {
      return;
   }

   if(
      bid <= 0.0 ||
      ask <= 0.0
   )
   {
      return;
   }


   double sl_dist =
      100.0 * point;

   double tp_dist =
      200.0 * point;


   if(
      decision.direction ==
      KB_SIGNAL_BUY
   )
   {
      double stop_loss =
         NormalizeDouble(
            ask - sl_dist,
            digits
         );

      double take_profit =
         NormalizeDouble(
            ask + tp_dist,
            digits
         );

      ExecuteBuy(
         InpLots,
         stop_loss,
         take_profit
      );

      return;
   }


   if(
      decision.direction ==
      KB_SIGNAL_SELL
   )
   {
      double stop_loss =
         NormalizeDouble(
            bid + sl_dist,
            digits
         );

      double take_profit =
         NormalizeDouble(
            bid - tp_dist,
            digits
         );

      ExecuteSell(
         InpLots,
         stop_loss,
         take_profit
      );

      return;
   }
}
