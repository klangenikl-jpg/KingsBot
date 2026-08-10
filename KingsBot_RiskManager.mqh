#pragma once
class CKingsBotRiskManager
{
private:
   double m_daily_loss_pct;
   int m_max_positions;
public:
   CKingsBotRiskManager():m_daily_loss_pct(2.0),m_max_positions(1){}
   void Configure(const double daily_loss_pct,const int max_positions){m_daily_loss_pct=daily_loss_pct;m_max_positions=max_positions;}
   bool CanOpenNewPosition(const string symbol)
   {
      int count=0;
      for(int i=PositionsTotal()-1;i>=0;i--)
      {
         ulong ticket=PositionGetTicket(i);
         if(ticket>0 && PositionGetString(POSITION_SYMBOL)==symbol) count++;
      }
      return count<m_max_positions;
   }
   bool DailyLossLimitReached(const double baseline,const double current) const
   {
      if(baseline<=0.0) return false;
      return ((baseline-current)/baseline*100.0)>=m_daily_loss_pct;
   }
};
