//+---------------------------------------------------+
//| RoNz Indicator.mq4        v1.1 (16.04.29) by RoNz |
//| April-Des 2016                                    |
//+---------------------------------------------------+
#property copyright   "2016, Rony Nofrianto, Indonesia."
#property link        "https://www.mql5.com/en/users/ronz"
#property description "RoNz Trade Info"
#property version   "1.1"
#property strict
#include <stdlib.mqh>
#include <RoNzIndicatorFunctions.mqh>
#property indicator_chart_window
//#property indicator_separate_window

#property indicator_buffers 1

#property indicator_label1  "Profits"
#property indicator_color1 clrWhite
#property  indicator_type1 DRAW_LINE

double ExtProfitBuff[];

const double   MaxRisk=0.02; //Max. Risk of account balance
//---- Label Setting
int iYPos=1;
int FontSize=8;

//----  Indicator Inputs

extern bool inpShowOnPriceInfo=true;//Show Orders Profit
extern bool   ShowOrderHistoryOnChart=false; // Show order history on chart
//----
string MyShortName="RoNz Trade Info";
const string MyID="RTI";

//----
double accTP = 0; double accSL = 0;
double symTP = 0; double symSL = 0;
double Old_Bid=0;
//---- Indicator Profit Summary

double indProfit=0; double indLoss=0;
double LowestSL=0; double HighestTP=0;
//----

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   LowestSL=HighestTP=0;

   ChartSetInteger(0,CHART_SHIFT,true);
   ChartSetInteger(0,CHART_SHOW_ASK_LINE,true);

//ObjectsDeleteAll(WindowFind(MyShortName));
//----   
   IndicatorShortName(MyShortName);
   IndicatorDigits(Digits());
   IndicatorBuffers(1);

   SetIndexBuffer(0,ExtProfitBuff);

//---- Check wether Show History on Chart option is set to true/false
   if(ShowOrderHistoryOnChart)
      CalculateCloseOrders();

   EventSetTimer(1);

//--- initialization done
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(IsTesting()) return;

   Print(__FUNCTION__,"_UninitReason = ",getUninitReasonText(_UninitReason),"(",reason,")");
   ObjectsDeleteAll(WindowFind(MyShortName));
   EventKillTimer();

   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {

   symTP=symSL=0;
   accTP=accSL=0;

   Show_InfoLabel();
/*  
//---- Return if no data was calculated before
   if(prev_calculated<0) return(-1);

   int limit;
   
 


   if(prev_calculated==0)
     {
      ArrayInitialize(ExtProfitBuff,0);

      //---- Setting the indicator limit count         
      limit=Bars;
     }
   else
      limit=Bars-(prev_calculated-1); 
       
    

//---- Calculating MA indicator
   for(int i=0; i<limit && !IsStopped(); i++)
     {
      //---- Calculating Moving Average for each indicator            
      ExtProfitBuff[i]=AccountProfit();
     }   
*/
//---- Return calculated bar
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CalculateCurrentOrders(double &dCurProfit,double &dBuyProfit,
                              double &dSellProfit,double &dBuyLots,double &dSellLots,
                              double &dBuyStopLots,double &dSellStopLots)
  {
   int buys=0,sells=0,buystop=0,sellstop=0;
   dCurProfit=0;

   for(int i=0;i<OrdersTotal();i++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol())
        {
         if(OrderType()==OP_BUY)
           {
            buys++;
            dBuyProfit=dBuyProfit+OrderProfit();
            dBuyLots=dBuyLots+OrderLots();
            symSL += (OrderStopLoss()==0)?0:((OrderOpenPrice()-OrderStopLoss())/Point)*OrderLots();
            symTP += (OrderTakeProfit()==0)?0:((OrderTakeProfit()-OrderOpenPrice())/Point)*OrderLots();

            CreateOnPriceLabel("O"+string(OrderTicket()),Time[10],OrderOpenPrice(),DoubleToStr(OrderProfit(),2)+" "+AccountCurrency(),GetColor(OrderProfit(),0));

            if(ShowOrderHistoryOnChart)
               CreateEntrySign(0,"oBuy"+(string)i,0,OrderOpenTime(),OrderOpenPrice(),1);
           }
         if(OrderType()==OP_SELL)
           {
            sells++;
            dSellProfit=dSellProfit+OrderProfit();
            dSellLots=dSellLots+OrderLots();
            symSL += (OrderStopLoss()==0)?0:((OrderStopLoss()-OrderOpenPrice())/Point)*OrderLots();
            symTP += (OrderTakeProfit()==0)?0:((OrderOpenPrice()-OrderTakeProfit())/Point)*OrderLots();

            CreateOnPriceLabel("O"+string(OrderTicket()),Time[10],OrderOpenPrice(),DoubleToStr(OrderProfit(),2)+" "+AccountCurrency(),GetColor(OrderProfit(),0));

            if(ShowOrderHistoryOnChart)
               CreateEntrySign(0,"oSell"+(string)i,0,OrderOpenTime(),OrderOpenPrice(),1,Red);
           }
         if(OrderType()==OP_BUYSTOP)
           {
            buystop++;
            dBuyStopLots=dBuyStopLots+OrderLots();
           }
         if(OrderType()==OP_SELLSTOP)
           {
            sellstop++;
            dSellStopLots=dSellStopLots+OrderLots();
           }           
        }

      double vpoint=MarketInfo(OrderSymbol(),MODE_POINT);

      if(OrderType()==OP_BUY)
        {
         accSL += (OrderStopLoss()==0)?0:((OrderOpenPrice()-OrderStopLoss())/vpoint)*OrderLots();
         accTP += (OrderTakeProfit()==0)?0:((OrderTakeProfit()-OrderOpenPrice())/vpoint)*OrderLots();
        }
      if(OrderType()==OP_SELL)
        {
         accSL += (OrderStopLoss()==0)?0:((OrderStopLoss()-OrderOpenPrice())/vpoint)*OrderLots();
         accTP += (OrderTakeProfit()==0)?0:((OrderOpenPrice()-OrderTakeProfit())/vpoint)*OrderLots();
        }

     }

   dCurProfit=dCurProfit+dBuyProfit+dSellProfit;

   return StringFormat("Buys : %d (%d) Sells : %d (%d)", buys, buystop, sells, sellstop);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CalculateCloseOrders()
  {
   int buys=0,sells=0;
   double buyProfit=0,sellProfit=0;

   for(int i=0;i<OrdersHistoryTotal();i++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false) break;
      if(OrderSymbol()==Symbol())
        {
         if(OrderType()==OP_BUY)
           {
            buys++;
            buyProfit=buyProfit+OrderProfit();
            CreateEntrySign(0,"cEntryTP"+(string)i,0,OrderOpenTime(),OrderTakeProfit(),4,Blue);
            CreateEntrySign(0,"cEntrySL"+(string)i,0,OrderOpenTime(),OrderStopLoss(),4,Red);
            CreateEntrySign(0,"cEntry"+(string)i,0,OrderOpenTime(),OrderOpenPrice(),1);
            TrendCreate(0,"trend"+(string)i,0,OrderOpenTime(),OrderOpenPrice(),OrderCloseTime(),OrderClosePrice(),Blue,2);
            CreateEntrySign(0,"close"+(string)i,0,OrderCloseTime(),OrderClosePrice(),3);
           }
         if(OrderType()==OP_SELL)
           {
            sells++;
            sellProfit=sellProfit+OrderProfit();
            CreateEntrySign(0,"cEntryTP"+(string)i,0,OrderOpenTime(),OrderTakeProfit(),4,Blue);
            CreateEntrySign(0,"cEntrySL"+(string)i,0,OrderOpenTime(),OrderStopLoss(),4,Red);
            CreateEntrySign(0,"cEntry"+(string)i,0,OrderOpenTime(),OrderOpenPrice(),1,Red);
            TrendCreate(0,"trend"+(string)i,0,OrderOpenTime(),OrderOpenPrice(),OrderCloseTime(),OrderClosePrice(),Red,2);
            CreateEntrySign(0,"close"+(string)i,0,OrderCloseTime(),OrderClosePrice(),3,Red);
           }
        }
     }

   return StringFormat("Buys : %d ($%G) Sells : %d ($%G)", buys, buyProfit, sells, sellProfit);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Show_InfoLabel()
  {

//if(IsExpertEnabled() || IsTesting()) return;

//---- Setting all label color to default color
   int SpreadColor=FontColor;
   int BidColor=FontColor;
   int IndProfitColor=FontColor;
   int IndWinColor=FontColor;

//---- Calculating Day of Week Pips Average in 90 Days
   double pips=0;
   int weeks=0;

   for(int i=1;i<=90;i++)
      if(TimeDayOfWeek(iTime(NULL,PERIOD_D1,i))==TimeDayOfWeek(iTime(NULL,PERIOD_D1,0)))
        {
         weeks++;
         pips+=iHigh(NULL,PERIOD_D1,i)-iLow(NULL,PERIOD_D1,i);
        }

   double dPipsAvg=NormalizeDouble((pips/weeks)/Point,0);
//----
   double dSpread=MarketInfo(NULL,MODE_SPREAD);
   double dHigh= MarketInfo(NULL,MODE_HIGH);
   double dLow = MarketInfo(NULL,MODE_LOW);
   double dPRange=NormalizeDouble((dHigh-dLow),Digits());
   double dPrice=MarketInfo(NULL,MODE_BID);
   if((dPRange/Point)==0) dPRange=1*Point;
   double dPricePos=NormalizeDouble(100 -((dHigh-dPrice)/dPRange)*100,0);

//---- Setting price info label
   string mHigh=StringFormat("H : %G (%G)",dHigh,(dHigh-dPrice)/Point);
   string mLow=StringFormat("L : %G (%G)",dLow,(dPrice-dLow)/Point);
   string mPRange=StringFormat("Day Pips : %G/%G",NormalizeDouble(dPRange/Point,0),dPipsAvg);
   string mBid=StringFormat("(Pos: %G%%) C : %G",dPricePos,dPrice);

//---- Setting entry info label
   double iCurProfit,iBuyProfit,iSellProfit,iBuyLots,iSellLots,iBuyStopLots,iSellStopLots;
   string mOpenedOrder=CalculateCurrentOrders(iCurProfit,iBuyProfit,iSellProfit,iBuyLots,iSellLots,iBuyStopLots,iSellStopLots);
   string mProfits=StringFormat("Profits: $%G ($%G)",iCurProfit,AccountProfit());
   string mBProfits=StringFormat("Buy Profits: $%G",iBuyProfit);
   string mSProfits=StringFormat("Sell Profits : $%G",iSellProfit);
   string mBLots=StringFormat("Buy Lots: %G (%G)",iBuyLots,iBuyStopLots);
   string mSLots=StringFormat("Sell Lots: %G (%G)",iSellLots,iSellStopLots);
   string mSymSLnTP=StringFormat("SL/TP : %G/%G (%G/%G)",symSL,symTP,accSL,accTP);
   string mMaxRisk=StringFormat("Max. Risk : $%G",NormalizeDouble(AccountBalance()*MaxRisk,2));

//---- Coloring the spread and price info label
   BidColor=GetColor(dPrice,Old_Bid);
   IndProfitColor=GetColor(indProfit,MathAbs(indLoss));

//---- Change old price value for coloring next price info label 
   Old_Bid=dPrice;
   int ProfitColor=GetColor(iCurProfit,0);
   int BProfitColor=GetColor(iBuyProfit,0);
   int SProfitColor=GetColor(iSellProfit,0);
   int TotalProfitColor=GetColor(AccountProfit(),0);
   int SLTPColor=GetColor(accTP,accSL);
   int SymSLTPColor=GetColor(symTP,symSL);

//---- Show the labels

//---- Show price label
   CreateLabel(0,mHigh,"Lbl_High",FontSize,FontType,FontColor,Corner,1,iYPos+0);
   CreateLabel(0,mBid,"Lbl_Bid",FontSize,FontType,BidColor,Corner,1,iYPos+1);
   CreateLabel(0,mLow,"Lbl_Low",FontSize,FontType,FontColor,Corner,1,iYPos+2);
   CreateLabel(0,mPRange,"Lbl_Range",FontSize,FontType,FontColor,Corner,1,iYPos+3);

//---- Show entry sign and profit label
   CreateLabel(0,mOpenedOrder,"Lbl_OpenedOrder",FontSize,FontType,ProfitColor,Corner,1,iYPos+4);
   CreateLabel(0,mProfits,"Lbl_Profit",FontSize,FontType,ProfitColor,Corner,1,iYPos+5);
   CreateLabel(0,mBProfits,"Lbl_BProfit",FontSize,FontType,BProfitColor,Corner,1,iYPos+6);
   CreateLabel(0,mSProfits,"Lbl_SProfit",FontSize,FontType,SProfitColor,Corner,1,iYPos+7);
   CreateLabel(0,mBLots,"Lbl_BLots",FontSize,FontType,ProfitColor,Corner,1,iYPos+8);
   CreateLabel(0,mSLots,"Lbl_SLots",FontSize,FontType,ProfitColor,Corner,1,iYPos+9);
   CreateLabel(0,mSymSLnTP,"Lbl_symSLTP",FontSize,FontType,SymSLTPColor,Corner,1,iYPos+10);
   CreateLabel(0,mMaxRisk,"Lbl_maxRisk",FontSize,FontType,FontColor,Corner,1,iYPos+11);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CreateOnPriceLabel(string lblName,datetime time,double price,string lblText,color clr=clrWhite,int lFontSize=8)
  {
   if(!inpShowOnPriceInfo) return false;

   lblName="l_"+lblName;

   ObjectDelete(lblName);
   ObjectCreate(0,lblName,OBJ_TEXT,0,time,price);
   ObjectSetText(lblName,lblText,lFontSize,FontType,clr);
   ObjectSetInteger(0,lblName,OBJPROP_SELECTABLE,true);
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteOnPriceLabel(string lblName)
  {

   lblName="l_"+lblName;
   ObjectDelete(lblName);
  }

//+------------------------------------------------------------------+
