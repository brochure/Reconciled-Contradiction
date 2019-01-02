//+------------------------------------------------------------------+
//|                                                      Gorilla2018 |
//|                                  Copyright 2018, Robert L. Zhang |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <stdlib.mqh>
#define SYMBOL "USDJPY"

//input double   minActEqt=100;
input int magicNum=517;

input bool dynamicLotSize=true;
input double fixedLotSize=0.01;
input double singleEquityPercent=2;
input double totalEquityPercent=5;
input int stopLoss=28; // 30 by origin

input double trailingOpen=1;
input double trailingStop=50;
double trOpPips,trClPips;
int PivotStartHour=0;
int PivotStartMinute=0;
int PivotDaysToPlot=15;
color PivotSupportLabelColor=DodgerBlue;
color PivotResistanceLabelColor=OrangeRed;
color PivotPivotLabelColor=Green;
int Pivotfontsize=8;
int PivotLabelShift=0;

double point=0.01;
int buyTkt,sellTkt;
int slippage=5;
double digits=3.0; //MarketInfo(SYMBOL,MODE_DIGITS)
int ErrorCode;
string ErrDesc,ErrAlert,ErrLog;
string EmailSubject, EmailBody;

int init()
  {
  SendMail("EA init",Symbol());
  Print("Symbol: "+Symbol());
  trOpPips=trailingOpen*point;
  trClPips=trailingStop*point;
   return 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

// trailing stop if close to the TP (eg. reached s2)
int start()
  {
   double ema_30=iMA(SYMBOL, PERIOD_H1, 30, 0, MODE_EMA, PRICE_CLOSE, 0);
   double ema_15=iMA(SYMBOL, PERIOD_H1, 15, 0, MODE_EMA, PRICE_CLOSE, 0);
   double ema_4=iMA(SYMBOL,PERIOD_H1,4,0,MODE_EMA,PRICE_CLOSE,0);
   Print("ema_30: "+ema_30+", ema_15: "+ema_15+", ema_4: "+ema_4);
   for(int i=OrdersTotal()-1;i>=0;i--){
    if(OrderSelect(i,SELECT_BY_POS)&&OrderSymbol()==SYMBOL&&OrderMagicNumber()==magicNum){
    double slideDistance=0.0;
    double maxStopLoss,currentStop;
      if(OrderType()==OP_BUYSTOP){
        // trailing
        if((Ask+trOpPips)<ema_30){
          slideDistance=OrderOpenPrice()-Ask-trOpPips;
          if(slideDistance>0){
            OrderModify(OrderTicket(),Ask+trOpPips,OrderStopLoss()-slideDistance,OrderTakeProfit()-slideDistance,0);
        }
      }
      }
      else if(OrderType()==OP_SELLSTOP){
          // trailing
         if((Bid+trOpPips)>ema_30){
            slideDistance=Bid-OrderOpenPrice()-trOpPips;
            if(slideDistance>0){
            OrderModify(OrderTicket(),Bid-trOpPips,OrderStopLoss()+slideDistance,OrderTakeProfit()+slideDistance,0);
            }
         }
      }
      else if(OrderType()==OP_BUY){
      ;
      /*
           maxStopLoss=NormalizeDouble(Bid-trClPips,digits);
           currentStop=NormalizeDouble(OrderStopLoss(),digits);
           if((OrderTakeProfit()-Bid)<trClPips&&maxStopLoss>((OrderOpenPrice()+OrderTakeProfit())*0.54)&&currentStop<maxStopLoss){               
           // Error Handling
            if(!OrderModify(OrderTicket(),OrderOpenPrice(),maxStopLoss,OrderTakeProfit(),0))
            {
              ErrorCode = GetLastError();
              ErrDesc = ErrorDescription(ErrorCode);
              ErrAlert = StringConcatenate("Buy Trailing Stop -  Error ",ErrorCode,": ",ErrDesc);
              Alert(ErrAlert);
              ErrLog = StringConcatenate("Bid: ", MarketInfo(SYMBOL,MODE_BID), " Ticket: ",OrderTicket()," Stop: ",OrderStopLoss()," Trail: ", maxStopLoss);
              Print(ErrLog);
            }
         }
         */
      }
      else if(OrderType()==OP_SELL){
      ;
      /*
           maxStopLoss=NormalizeDouble(Ask+trClPips,digits);
           currentStop=NormalizeDouble(OrderStopLoss(),digits);
           if((Ask-OrderTakeProfit())>trClPips&&maxStopLoss<((OrderOpenPrice()+OrderTakeProfit())*0.46)&&currentStop>maxStopLoss){               
           // Error Handling
            if(!OrderModify(OrderTicket(),OrderOpenPrice(),maxStopLoss,OrderTakeProfit(),0))
            {
              ErrorCode = GetLastError();
              ErrDesc = ErrorDescription(ErrorCode);
              ErrAlert = StringConcatenate("Buy Trailing Stop -  Error ",ErrorCode,": ",ErrDesc);
              Alert(ErrAlert);
              ErrLog = StringConcatenate("Bid: ", MarketInfo(SYMBOL,MODE_BID), " Ticket: ",OrderTicket()," Stop: ",OrderStopLoss()," Trail: ", maxStopLoss);
              Print(ErrLog);
            }
         }
         */
      }
      else return 0; // error report
      return 0;
    }
  }
   if(DayOfWeek()<=1||DayOfWeek()>=6) return 0;
   //Print("The week day: "+weekDay);
   double pivot_lastday=iCustom(SYMBOL,PERIOD_H4,"Pivots_Daily",PivotStartHour,PivotStartMinute,PivotDaysToPlot,PivotSupportLabelColor,PivotResistanceLabelColor,PivotPivotLabelColor,Pivotfontsize,PivotLabelShift,0,6);
   double pivot_today=iCustom(SYMBOL,PERIOD_H4,"Pivots_Daily",PivotStartHour,PivotStartMinute,PivotDaysToPlot,PivotSupportLabelColor,PivotResistanceLabelColor,PivotPivotLabelColor,Pivotfontsize,PivotLabelShift,0,0);
   Print("pivot_lastday: "+pivot_lastday+", pivot_today: "+pivot_today);

   if(pivot_today>pivot_lastday)
     {  // long position
      if(ema_30>pivot_today&&ema_15>pivot_today&&ema_4>pivot_today&&(Ask+trOpPips)<ema_30)
        {
         double buyTP=iCustom(SYMBOL,PERIOD_H4,"Pivots_Daily",PivotStartHour,PivotStartMinute,PivotDaysToPlot,PivotSupportLabelColor,PivotResistanceLabelColor,PivotPivotLabelColor,Pivotfontsize,PivotLabelShift,6,0)+trOpPips; // r3
         while(IsTradeContextBusy()) Sleep(10);
         RefreshRates();
         double buySL=Ask-(stopLoss*point)+trOpPips;
         double buyStopPrice=Ask+trOpPips;
         buyTkt=OrderSend(SYMBOL,OP_BUYSTOP,getLotSize(),buyStopPrice,slippage,buySL,buyTP,"Buy Stop Order",magicNum,0,Green);
         EmailSubject = "Buy stop order placed";
         EmailBody = "Buy stop order "+buyTkt+" placed on "+Symbol()+" at "+buyStopPrice;
         SendMail(EmailSubject,EmailBody);
        }
        }else{ // short position
          if(ema_30<pivot_today&&ema_15<pivot_today&&ema_4<pivot_today&&(Bid-trOpPips)>ema_30){
            double sellTP = iCustom(SYMBOL,PERIOD_H4,"Pivots_Daily",PivotStartHour,PivotStartMinute,PivotDaysToPlot,PivotSupportLabelColor,PivotResistanceLabelColor,PivotPivotLabelColor,Pivotfontsize,PivotLabelShift,5,0)-trOpPips; // s3
            while(IsTradeContextBusy()) Sleep(10);
            RefreshRates();
            double sellSL=Bid+(stopLoss*point)-trOpPips;
            double sellStopPrice=Bid-trOpPips;
            sellTkt=OrderSend(SYMBOL,OP_SELLSTOP,getLotSize(),sellStopPrice,slippage,sellSL,sellTP,"Sell Stop Order",magicNum,0,Cyan);
            EmailSubject = "Sell stop order placed";
            EmailBody = "Sell stop order "+sellTkt+" placed on "+Symbol()+" at "+sellStopPrice;
            SendMail(EmailSubject,EmailBody);
         }
     }
   return 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

double getLotSize()
{
   double lotSize=0.0;
   if(dynamicLotSize){
      double modifiedFactor=AccountEquity()/stopLoss/MarketInfo(Symbol(),MODE_TICKVALUE)/1000;
      double singleLotSize=modifiedFactor*singleEquityPercent;
      double totalLotSize=modifiedFactor*totalEquityPercent-openPosSizeCount();
      lotSize=(singleLotSize<totalLotSize)?singleLotSize:totalLotSize;
   }else lotSize=fixedLotSize;
/*
   if(dynamicLotSize)
   {
     double riskAmount=AccountEquity()*(equityPercent/100);
     double tickValue=MarketInfo(Symbol(),MODE_TICKVALUE)*10;
     //if(Point == 0.001 || Point == 0.00001) tickValue *= 10;
     lotSize=(riskAmount/stopLoss)/tickValue;
   }else lotSize=fixedLotSize;
*/
   if(lotSize < MarketInfo(SYMBOL,MODE_MINLOT)) lotSize=MarketInfo(SYMBOL,MODE_MINLOT);
   if(lotSize > MarketInfo(SYMBOL,MODE_MAXLOT)) lotSize=MarketInfo(SYMBOL,MODE_MAXLOT);
   return (MarketInfo(SYMBOL,MODE_LOTSTEP)==0.1)?NormalizeDouble(lotSize,1):NormalizeDouble(lotSize,2);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double openPosSizeCount()
{
   Print("OrdersTotal: "+OrdersTotal());
   double totalBuyLots=0.0,totalSellLots=0.0;
   //int a = OrdersTotal();
   for(int counter=0; counter<OrdersTotal(); counter++)
     {
      if(OrderSelect(counter,SELECT_BY_POS,MODE_TRADES)){
         if(OrderSymbol()==SYMBOL)
           {
            if(OrderType()==OP_BUY) totalBuyLots+=OrderLots();
            if(OrderType()==OP_SELL) totalSellLots+=OrderLots();
           }
      }
     }
   return totalBuyLots + totalSellLots;
}

/*
void beroutine(){
   bool breakEven;
   for(int counterbreakeven=0;counterbreakeven<OrdersTotal();counterbreakeven++){
      if(OrderSelect(counterbreakeven,SELECT_BY_POS,MODE_TRADES)&&OrderSymbol()==SYMBOL&&OrderMagicNumber()==magicNum){
         if(OrderType()==OP_SELL&&OrderStopLoss()>OrderOpenPrice()){
            // sellbepoint = OrderOpenPrice() - (3 * point);
            if(Ask < OrderOpenPrice()) breakEven=OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0);
         }
         else if(OrderType()==OP_BUY&&OrderStopLoss()<OrderOpenPrice()){
            // buybepoint = OrderOpenPrice() + (3*point);
            if(Bid > OrderOpenPrice()) breakEven=OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0);
         }else continue;
         if(!breakEven)
         {
           ErrorCode = GetLastError();
           string ErrDesc = ErrorDescription(ErrorCode);
           string ErrAlert = StringConcatenate("Buy Break Even - Error ",ErrorCode,": ",ErrDesc);
           Alert(ErrAlert);
           string ErrLog = StringConcatenate("Bid: ",Bid,", Ask: ",Ask,", Ticket: ",OrderTicket(),", Stop: ",OrderStopLoss(),", Break: ", "NULL");
           Print(ErrLog);
         }
         return;
      }
   }
}
*/

//+------------------------------------------------------------------+
