

#include<Trade/Trade.mqh>
#include <Trade\DealInfo.mqh>
CTrade trade;
CDealInfo m_deal; 

input double LotSize = 0.1;
input int Slippage = 20;
input double TakeProfit = 3;
input double StopLoss = 3;
input int MagicNumber = 12345;
bool isTrading = false;
datetime lastBarTime = 0; 
bool isInsideCandle = false;
double breakoutHigh;
double breakoutLow;
int tradeStatus =0;


int OnInit()
  {
   lastBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   trade.SetExpertMagicNumber(MagicNumber);
   return(INIT_SUCCEEDED);
  }

void OnTick()
  {
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(currentBarTime != lastBarTime && (tradeStatus==0 || tradeStatus==1))
     {

      Print("New bar detected! Time: ", TimeToString(currentBarTime, TIME_DATE | TIME_MINUTES));
      double previousHigh = iHigh(_Symbol, PERIOD_CURRENT, 1);
      double previousLow = iLow(_Symbol, PERIOD_CURRENT, 1);
      double previouspreviousHigh = iHigh(_Symbol, PERIOD_CURRENT, 2);
      double previouspreviousLow = iLow(_Symbol, PERIOD_CURRENT, 2);
      Print(previouspreviousHigh ,"----   ", previouspreviousLow,"----   ", previousHigh,"-----   ", previousLow);
      isInsideCandle = (previousHigh < previouspreviousHigh && previousLow > previouspreviousLow);
      if(isInsideCandle && tradeStatus==0)
        {
         tradeStatus=1;
        }
      if(isInsideCandle)
        {
         breakoutHigh = previouspreviousHigh;
         breakoutLow = previouspreviousLow;
        }
      lastBarTime = currentBarTime;
     }
   
   if (FindPositionsWithMagicNumber(MagicNumber)){return;}
   if(tradeStatus==1)
     {
      double sl;
      double tp;
      if(SymbolInfoDouble(_Symbol, SYMBOL_ASK) > breakoutHigh)
        {
         sl = breakoutHigh - StopLoss;
         tp = breakoutHigh + TakeProfit;
         trade.Buy(LotSize,_Symbol, 0, sl,tp);
         tradeStatus=2;
        }

      if(SymbolInfoDouble(_Symbol, SYMBOL_BID) < breakoutLow)
        {
          sl = breakoutLow + StopLoss;
          tp = breakoutLow - TakeProfit;
         trade.Sell(LotSize,_Symbol, 0, sl,tp);
         tradeStatus=2;
        }
     }
  }

void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
   ENUM_TRADE_TRANSACTION_TYPE type=trans.type;
   if(type==TRADE_TRANSACTION_DEAL_ADD)
     {
      if(HistoryDealSelect(trans.deal))
         m_deal.Ticket(trans.deal);
      else
        {
         Print(__FILE__," ",__FUNCTION__,", ERROR: HistoryDealSelect(",trans.deal,")");
         return;
        }
      //---
      long reason=-1;
      if(!m_deal.InfoInteger(DEAL_REASON,reason))
        {
         Print(__FILE__," ",__FUNCTION__,", ERROR: InfoInteger(DEAL_REASON,reason)");
         return;
        }
      if((ENUM_DEAL_REASON)reason==DEAL_REASON_SL)
         {
         if(m_deal.Magic()==MagicNumber){tradeStatus=0;}
         isInsideCandle=false;
         }
      else
        {
         if((ENUM_DEAL_REASON)reason==DEAL_REASON_TP)
            if(m_deal.Magic()==MagicNumber){tradeStatus=0;}
            isInsideCandle=false;
        }
         
     }
  }

bool FindPositionsWithMagicNumber(int magicNumber)
  {
   int totalPositions = PositionsTotal();
   if(totalPositions == 0)
     {
      return false;
     }

   for(int i = 0; i < totalPositions; i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         long positionMagicNumber = PositionGetInteger(POSITION_MAGIC);
         if(positionMagicNumber == magicNumber)
           {
            return true;
           }
        }
     }
     return false;
  }


