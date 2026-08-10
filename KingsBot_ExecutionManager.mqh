#pragma once
#include <Trade/Trade.mqh>
class CKingsBotExecutionManager
{
private:
   CTrade m_trade;
   ulong m_magic;
   int m_deviation;
   int m_max_spread;
public:
   void Configure(const ulong magic,const int deviation,const int max_spread)
   {
      m_magic=magic;m_deviation=deviation;m_max_spread=max_spread;
      m_trade.SetExpertMagicNumber(m_magic);
      m_trade.SetDeviationInPoints(m_deviation);
   }
   bool SpreadOK(const string symbol) const
   {
      long spread=0;
      if(!SymbolInfoInteger(symbol,SYMBOL_SPREAD,spread)) return false;
      return (m_max_spread<=0 || spread<=m_max_spread);
   }
   bool Buy(const string symbol,const double volume,const double sl,const double tp,const string comment)
   {
      return m_trade.Buy(volume,symbol,0.0,sl,tp,comment);
   }
   bool Sell(const string symbol,const double volume,const double sl,const double tp,const string comment)
   {
      return m_trade.Sell(volume,symbol,0.0,sl,tp,comment);
   }
};
