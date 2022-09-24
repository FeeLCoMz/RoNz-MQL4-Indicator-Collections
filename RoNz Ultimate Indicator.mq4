//+---------------------------------------------------+
//| RoNz Indicator.mq4        v1.0 (14.12.02) by RoNz |
//| Agu 2014 - Des 2014                               |
//+---------------------------------------------------+
#property copyright   "2014, Rony Nofrianto, Indonesia."
#property link        "http://www.feelcomz.com"
#property description "RoNz Trading Indicator"
#property version   "1.0"
#property strict
#include <stdlib.mqh>
#include <RoNzIndicatorFunctions.mqh>
#property indicator_chart_window

int    TimeOffset=6; //EST to Server Timezone Offset
const double   MaxRisk=0.02; //Max. Risk of account balance
int    InpStopPointShift=0; // Stop Point Shift
const bool bTrackIndicatorOP=false;//Show indicator order history
//---- Label Setting
int iYPos=1;
int FontSize=8;

//---- Indicator Buffers
double ExtMA1[],ExtMA2[];
double ExtMA3[],ExtMA4[];
double ExtShortBuyBuffer[],ExtShortSellBuffer[];
double ExtUpperStopBuffer[],ExtLowerStopBuffer[];
double ExtResistBuff[],ExtSupportBuff[];
double ExtOpenBuff[],ExtCloseBuff[];
double ExtResistBuff2,ExtSupportBuff2;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_ENTRYSIGNLEVEL
  {
   NoEntry=0,MA1=1,MA2=2,MA3=3,MA4=4
  };
enum ENUM_EXITSIGNLEVEL
  {
   StopLoss_Exit=0,MA1_Exit=1,MA2_Exit=2,MA3_Exit=3,MA4_Exit=4,RSI_Exit=5
  };
  

//----  Indicator Inputs
extern ENUM_MA_METHOD inpMethod=MODE_SMA; // Moving Average Method
extern ENUM_APPLIED_PRICE inpPrice=PRICE_CLOSE;   // Applied Price
extern int MAShift=0; //MA Period Addictive/Subtractive
extern string MACDPeriod="12,26,9";   // MACD Period (FastEMA,SlowEMA,Signal)
extern string STOCHPeriod="5,3,3";   // Stochastic Period (K,D,Slowing)
extern int    RSIPeriod=3;//RSI Period (RSI EntrySignLevel Only)
extern int    RSILevel=30;//RSI Level
extern int    InpShift=0;  // Shift
extern ENUM_ENTRYSIGNLEVEL    FastMA=MA1;    //Fast MA
extern ENUM_ENTRYSIGNLEVEL    SlowMA=MA2;    //Slow MA
extern ENUM_EXITSIGNLEVEL    ExitSignLevel=StopLoss_Exit;    //Exit Sign Level
extern bool   InpUseRSI=true;//Use RSI for Entry Sign
extern int    inpStopLoss=200;//Stop Loss
extern int    inpTakeProfit=600;//Take Profit
extern bool   UseCloseTime=false; //Use Close Time to Exit Order
extern bool   InpShowProfitLabel=true;      // Show profit label on entry sign
extern bool   ShowOrderHistoryOnChart=false; // Show order history on chart
//----
string MyShortName="RoNz Trading Indicator";
const string MyID="RZI";

#property indicator_buffers 12

#property indicator_label1  "MA1"
#property indicator_color1 clrRed
#property  indicator_type1 DRAW_LINE

#property indicator_label2  "MA2"
#property indicator_color2 clrYellow
#property  indicator_type2 DRAW_LINE

#property indicator_label3  "MA3"
#property indicator_color3 clrDodgerBlue 
#property  indicator_type3 DRAW_LINE

#property indicator_label4  "MA4"
#property indicator_color4 clrLimeGreen
#property  indicator_type4 DRAW_LINE

#property indicator_label5  "Buy Sign"
#property indicator_color5 clrWhite
#property  indicator_type5 DRAW_ARROW

#property indicator_label6  "Sell Sign"
#property indicator_color6 clrWhite
#property  indicator_type6 DRAW_ARROW

#property indicator_label7  "Upper Period High Price"
#property indicator_color7 clrDarkGreen
#property  indicator_type7 DRAW_LINE
#property  indicator_style7 STYLE_DOT

#property indicator_label8  "Upper Period Low Price"
#property indicator_color8 clrMaroon
#property  indicator_type8 DRAW_LINE
#property  indicator_style8 STYLE_DOT

#property indicator_label9  "Resistance"
#property indicator_color9 clrDodgerBlue
#property  indicator_type9 DRAW_ARROW
#property  indicator_width9 1

#property indicator_label10  "Support"
#property indicator_color10 clrRed
#property  indicator_type10 DRAW_ARROW
#property  indicator_width10 1

#property indicator_label11  "Session Close"
#property indicator_color11 clrOrangeRed
#property  indicator_type11 DRAW_ARROW
#property  indicator_width11 1

#property indicator_label12  "Session Open"
#property indicator_color12 clrLime
#property  indicator_type12 DRAW_ARROW
#property  indicator_width12 1

//----
double accTP = 0; double accSL = 0;
double symTP = 0; double symSL = 0;
double Old_Bid=0;
//---- Indicator Profit Summary

struct IndOrder
  {
   int               Index;
   string            Name;
   int               Type;
   datetime          OpenTime;
   datetime          CloseTime;
   double            OpenPrice;
   double            ClosePrice;
   double            Profit;
   double            Loss;
  };

IndOrder CurrentOP;
IndOrder LastOP;

int indWinCount=0; int indLossCount=0;
double indProfit=0; double indLoss=0;
double LowestSL=0; double HighestTP=0;
string IndStartTime,IndStopTime;
int iDayCount=0;
//----
int RZIMAPeriods[];
int UpperPeriods[];

double ExtProfitLossBuff[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   ChangeBestInputParams();
   CalculateMAPeriods(Period(),UpperPeriods,RZIMAPeriods);
   InpStopPointShift=RZIMAPeriods[0];

   ShiftMAPeriods(RZIMAPeriods,MAShift);

   MyShortName=MyShortName+" ("+(string)RZIMAPeriods[0]+","+(string)RZIMAPeriods[1]+","+(string)RZIMAPeriods[2]+","+(string)RZIMAPeriods[3]+")";

   CurrentOP.Type=LastOP.Type=-1;
   CurrentOP.Profit=0;
   CurrentOP.Loss=0;
   CurrentOP.Name="";
   indLossCount=indWinCount=0;
   indProfit=indLoss=0;
   LowestSL=HighestTP=0;
   IndStartTime=IndStopTime="";
   iDayCount=0;

   for(int i=0; i<4; i++)
      SetIndexStyle(i,DRAW_LINE,STYLE_SOLID,1);

   switch(FastMA)
     {
      case 1:
         RSIPeriod=RZIMAPeriods[0];
         SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2);
         break;
      case 2:
         RSIPeriod=RZIMAPeriods[1];
         SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2);
         break;
      case 3:
         RSIPeriod=RZIMAPeriods[2];
         SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,2);
         break;
      case 4:
         RSIPeriod=RZIMAPeriods[3];
         SetIndexStyle(3,DRAW_LINE,STYLE_SOLID,2);
         break;
     }
     
   switch(SlowMA)
     {
      case 1:
         RSIPeriod=RZIMAPeriods[0];
         SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2);
         break;
      case 2:
         RSIPeriod=RZIMAPeriods[1];
         SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2);
         break;
      case 3:
         RSIPeriod=RZIMAPeriods[2];
         SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,2);
         break;
      case 4:
         RSIPeriod=RZIMAPeriods[3];
         SetIndexStyle(3,DRAW_LINE,STYLE_SOLID,2);
         break;
     }     

   ChartSetInteger(0,CHART_SHIFT,true);
   ChartSetInteger(0,CHART_SHOW_ASK_LINE,true);

//ObjectsDeleteAll(WindowFind(MyShortName));
//----   
   IndicatorShortName(MyShortName);
   IndicatorDigits(Digits());
   IndicatorBuffers(13);

//---- 
   SetIndexBuffer(0,ExtMA1);
   SetIndexLabel(0,"MA1 "+(string)RZIMAPeriods[0]);
   SetIndexShift(0,InpShift);
   SetIndexDrawBegin(0,InpShift+RZIMAPeriods[0]);

   SetIndexBuffer(1,ExtMA2);
   SetIndexLabel(1,"MA2 "+(string)RZIMAPeriods[1]);
   SetIndexShift(1,InpShift);
   SetIndexDrawBegin(1,InpShift+RZIMAPeriods[1]);

   SetIndexBuffer(2,ExtMA3);
   SetIndexLabel(2,"MA3 "+(string)RZIMAPeriods[2]);
   SetIndexShift(2,InpShift);
   SetIndexDrawBegin(2,InpShift+RZIMAPeriods[2]);

   SetIndexBuffer(3,ExtMA4);
   SetIndexLabel(3,"MA4 "+(string)RZIMAPeriods[3]);
   SetIndexShift(3,InpShift);
   SetIndexDrawBegin(3,InpShift+RZIMAPeriods[3]);

   SetIndexBuffer(4,ExtShortBuyBuffer);
   SetIndexLabel(4,"Short Buy");
   SetIndexArrow(4,233);
   SetIndexDrawBegin(4,0);

   SetIndexBuffer(5,ExtShortSellBuffer);
   SetIndexLabel(5,"Short Sell");
   SetIndexArrow(5,234);
   SetIndexDrawBegin(5,0);

   SetIndexBuffer(6,ExtUpperStopBuffer);
   SetIndexLabel(6,"Upper Period High Price");
   SetIndexShift(6,InpStopPointShift);
   SetIndexDrawBegin(6,InpStopPointShift); // Upper Stop Point

   SetIndexBuffer(7,ExtLowerStopBuffer);
   SetIndexLabel(7,"Upper Period Low Price");
   SetIndexShift(7,InpStopPointShift);
   SetIndexDrawBegin(7,InpStopPointShift); // Lower Stop Point

   SetIndexBuffer(8,ExtResistBuff);
   SetIndexLabel(8,"Resistance");
   SetIndexArrow(8,159);//108
   SetIndexDrawBegin(8,0);

   SetIndexBuffer(9,ExtSupportBuff);
   SetIndexLabel(9,"Support");
   SetIndexArrow(9,159);
   SetIndexDrawBegin(9,0);

   SetIndexBuffer(10,ExtCloseBuff);
   SetIndexLabel(10,"Close Time");
   SetIndexArrow(10,251);
   SetIndexDrawBegin(10,0);

   SetIndexBuffer(11,ExtOpenBuff);
   SetIndexLabel(11,"Open Time");
   SetIndexArrow(11,252);
   SetIndexDrawBegin(11,0);

   SetIndexBuffer(12,ExtProfitLossBuff);

//---- Invisible Value
   for(int i=0; i<13; i++)
      SetIndexEmptyValue(i,0);

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
void OnTimer()
  {
   string mSession=StringConcatenate((string)TimeCurrent());
   CreateLabel(0,mSession,"Lbl_Session",7,FontType,FontColor,3,150,0);
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

//---- Return if no data was calculated before
   if(prev_calculated<0) return(-1);

   int limit;

//---- Setting Array Direction for Entry, Stop Point, and Support/Resistance Indicator. False = Array Not Series
   ArraySetAsSeries(ExtShortBuyBuffer,false);
   ArraySetAsSeries(ExtShortSellBuffer,false);

   ArraySetAsSeries(ExtUpperStopBuffer,false);
   ArraySetAsSeries(ExtLowerStopBuffer,false);

   ArraySetAsSeries(ExtResistBuff,false);
   ArraySetAsSeries(ExtSupportBuff,false);

   ArraySetAsSeries(ExtOpenBuff,false);
   ArraySetAsSeries(ExtCloseBuff,false);

   ArraySetAsSeries(ExtProfitLossBuff,false);

   ArraySetAsSeries(open,false);
   ArraySetAsSeries(close,false);
   ArraySetAsSeries(high,false);
   ArraySetAsSeries(low,false);
   ArraySetAsSeries(time,false);
   ArraySetAsSeries(spread,false);

   if(prev_calculated==0)
     {
      ArrayInitialize(ExtMA1,0);
      ArrayInitialize(ExtMA2,0);
      ArrayInitialize(ExtMA3,0);
      ArrayInitialize(ExtMA4,0);

      ArrayInitialize(ExtShortBuyBuffer,0);
      ArrayInitialize(ExtShortSellBuffer,0);

      ArrayInitialize(ExtUpperStopBuffer,0);
      ArrayInitialize(ExtLowerStopBuffer,0);

      ArrayInitialize(ExtResistBuff,0);
      ArrayInitialize(ExtSupportBuff,0);

      ArrayInitialize(ExtOpenBuff,0);
      ArrayInitialize(ExtCloseBuff,0);

      ArrayInitialize(ExtProfitLossBuff,0);

      //---- Setting the indicator limit count         
      limit=Bars;
     }
   else
      limit=Bars-(prev_calculated-1);

//---- Calculating MA indicator
   for(int i=0; i<limit && !IsStopped(); i++)
     {
      //---- Calculating Moving Average for each indicator      
      ExtMA1[i] = iMA(NULL, 0, RZIMAPeriods[0], 0, inpMethod, inpPrice, i);
      ExtMA2[i] = iMA(NULL, 0, RZIMAPeriods[1], 0, inpMethod, inpPrice, i);
      ExtMA3[i] = iMA(NULL, 0, RZIMAPeriods[2], 0, inpMethod, inpPrice, i);
      ExtMA4[i] = iMA(NULL, 0, RZIMAPeriods[3], 0, inpMethod, inpPrice, i);
     }

//---- Calculating Entry Sign and Stop Point Indicator
   if(prev_calculated==0)
     {
      limit=0;
      ExtResistBuff2=high[0];
      ExtSupportBuff2=low[0];
     }
   else
     {
      limit=prev_calculated-1;
     }

//---- Calculating entry, Stop Point, and Support/Resistance indicator
   for(int i=limit; i<rates_total && !IsStopped(); i++)
     {
      int x=rates_total-(i+1);

      Draw_PriceStopIndicator(i,time[i]);

      Draw_SupportnResistIndicator(i,x,ExtResistBuff,ExtSupportBuff,high[i],low[i]);

      if(i>0)
         Draw_BuySell_Entry(rates_total,i,x,time[i],open[i],close[i],high[i],low[i],high[i-1],low[i-1]);

      if(i==0)
         IndStartTime=TimeToString(time[i],TIME_DATE);

      if(TimeToString(time[i],TIME_MINUTES)=="12:00")
         CreateDayLabel("Day"+(string)i,time[i],ExtLowerStopBuffer[i],Days[TimeDayOfWeek(time[i])]);

      CalculateIndicatorProfit(i,time[i],ExtProfitLossBuff[i],indWinCount,indLossCount,indProfit,indLoss);

      if(i==(rates_total-1))
         IndStopTime=TimeToString(time[i],TIME_DATE);

     }

   Show_InfoLabel();

//---- Return calculated bar
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // Event identifier  
                  const long& lparam,   // Event parameter of long type
                  const double& dparam, // Event parameter of double type
                  const string& sparam) // Event parameter of string type
  {
//--- the mouse has been clicked on the graphic object
   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      if(sparam=="Lbl_IndProfit1" || sparam=="Lbl_IndProfit2" || sparam=="Lbl_IndProfit3")
        {

         //--- delete all objects
         int obj_total=ObjectsTotal();
         PrintFormat("Total %d objects",obj_total);
         for(int i=obj_total-1;i>=0;i--)
           {
            string sObjNameSplit[];

            StringSplit(ObjectName(i),StringGetCharacter("_",0),sObjNameSplit);

            if(ArraySize(sObjNameSplit)>1)
              {
               if(sObjNameSplit[0]=="lProfit")
                 {
                  //PrintFormat("object %d: %s",i,ObjectName(i));
                  //ObjectDelete(ObjectName(i));
                  if(ObjectGetInteger(0,ObjectName(i),OBJPROP_BACK)==true)
                     ObjectSetInteger(0,ObjectName(i),OBJPROP_BACK,false);
                  else
                     ObjectSetInteger(0,ObjectName(i),OBJPROP_BACK,true);
                 }
              }

           }

         ChartRedraw();
        }

      //Print("Clicked : ",sparam);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CreateProfitLabel(string lblName,datetime time,double price,string lblText)
  {
   if(!InpShowProfitLabel) return -1;
   int profit=(int)lblText;
   if(profit==0) return false;
   int clr=GetColor(profit,0);

   lblName="lProfit_"+lblName;

   ObjectDelete(lblName);
   ObjectCreate(lblName,OBJ_TEXT,0,time,price);
   ObjectSetText(lblName,lblText,FontSize-2,FontType,clr);
   ObjectSetInteger(0,lblName,OBJPROP_SELECTABLE,false);
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CreateDayLabel(string lblName,datetime time,double price,string lblText)
  {
   ObjectDelete(lblName);
   ObjectCreate(lblName,OBJ_TEXT,0,time,price);
   ObjectSetText(lblName,lblText,FontSize-3,FontType,clrGray);
   ObjectSetInteger(0,lblName,OBJPROP_SELECTABLE,false);
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CalculateCurrentOrders(double &dCurProfit)
  {
   int buys=0,sells=0;
   double buyProfit=0,sellProfit=0;
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
            buyProfit=buyProfit+OrderProfit();
            symSL += (OrderStopLoss()==0)?0:((OrderOpenPrice()-OrderStopLoss())/Point)*OrderLots();
            symTP += (OrderTakeProfit()==0)?0:((OrderTakeProfit()-OrderOpenPrice())/Point)*OrderLots();

            if(ShowOrderHistoryOnChart)
               CreateEntrySign(0,"oBuy"+(string)i,0,OrderOpenTime(),OrderOpenPrice(),1);
           }
         if(OrderType()==OP_SELL)
           {
            sells++;
            sellProfit=sellProfit+OrderProfit();
            symSL += (OrderStopLoss()==0)?0:((OrderStopLoss()-OrderOpenPrice())/Point)*OrderLots();
            symTP += (OrderTakeProfit()==0)?0:((OrderOpenPrice()-OrderTakeProfit())/Point)*OrderLots();

            if(ShowOrderHistoryOnChart)
               CreateEntrySign(0,"oSell"+(string)i,0,OrderOpenTime(),OrderOpenPrice(),1,Red);
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

   dCurProfit=dCurProfit+buyProfit+sellProfit;

   return StringFormat("Buys : %d Sells : %d", buys, sells);

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
void Draw_PriceStopIndicator(int i,datetime dtTime)
  {
//---- Setting Upper/Lower Stop Indicator   
   int UpperPeriod=PERIOD_CURRENT;

   int HigherPeriod[],MAPeriods[];
   CalculateMAPeriods(0,HigherPeriod,MAPeriods);

   UpperPeriod=HigherPeriod[0];

   int shift=iBarShift(NULL,UpperPeriod,dtTime,true);

   ExtUpperStopBuffer[i]=iHigh(NULL,UpperPeriod, shift);
   ExtLowerStopBuffer[i]=iLow(NULL,UpperPeriod, shift);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Draw_SupportnResistIndicator(int shift,int shiftRev,double &RBuff[],double &SBuff[],double high,double low)
  {
   double RSI=iRSI(NULL,0,RSIPeriod,inpPrice,shiftRev);

   bool RPoint=RSI>(100-RSILevel);
   bool SPoint=RSI<(RSILevel);

   if(RPoint)
     {
      RBuff[shift]=high;
      ExtResistBuff2=RBuff[shift];
     }
   if(SPoint)
     {
      SBuff[shift]=low;
      ExtSupportBuff2=SBuff[shift];
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Draw_BuySell_Entry(int rates_total,int i,int x,datetime lCurrentTime,double open,double close,double high,double low,double pHigh,double pLow)
  {

//---- Creating short term entry indicator
   double dSpread=MarketInfo(NULL,MODE_SPREAD)*Point;

   bool supportUp,supportDown,resistUp,resistDown,OverBought,OverSell;

   supportUp=supportDown=resistUp=resistDown=true;

   OverBought=OverSell=false;

   double pRSI= iRSI(NULL,0,RSIPeriod,inpPrice,x+1);
   double RSI = iRSI(NULL,0,RSIPeriod,inpPrice,x);

   if(InpUseRSI)
     {
      //RSI Overbuy/Oversell Settings
      supportUp=RSI>pRSI;
      resistDown=RSI<pRSI;

      OverBought=RSI>(100-RSILevel);
      OverSell=RSI<(RSILevel);

      //RSI Break Setting
      supportDown=pRSI<=(RSILevel) && RSI<pRSI;//&& low<pHigh //Break the RSI support
      resistUp=pRSI>=(100-RSILevel) && RSI>pRSI;//&& high>pHigh //Break the RSI resistance
     }

   bool ShortBuy,ShortSell,CloseBuy,CloseSell;
   double SignFastMA=0;
   double SignSlowMA=0;
   double pSignFastMA=0;
   double pSignSlowMA=0;   

   ShortBuy=ShortSell=false;
   CloseBuy=CloseSell=false;

   switch(FastMA)
     {
      case 1://MA1
         SignFastMA=ExtMA1[x];
         pSignFastMA=ExtMA1[x+1];
         break;
      case 2://MA2
         SignFastMA=ExtMA2[x];
         pSignFastMA=ExtMA2[x+1];
         break;
      case 3://MA3
         SignFastMA=ExtMA3[x];
         pSignFastMA=ExtMA3[x+1];
         break;
      case 4://MA4
         SignFastMA=ExtMA4[x];
         pSignFastMA=ExtMA4[x+1];
         break;
     }

   switch(SlowMA)
     {
      case 1://MA1
         SignSlowMA=ExtMA1[x];
         pSignSlowMA=ExtMA1[x+1];
         break;
      case 2://MA2
         SignSlowMA=ExtMA2[x];
         pSignSlowMA=ExtMA2[x+1];
         break;
      case 3://MA3
         SignSlowMA=ExtMA3[x];
         pSignSlowMA=ExtMA3[x+1];
         break;
      case 4://MA4
         SignSlowMA=ExtMA4[x];
         pSignSlowMA=ExtMA4[x+1];
         break;
     }
     
   ShortBuy = SignFastMA>SignSlowMA && pSignFastMA<pSignSlowMA;
   ShortSell=SignFastMA<SignSlowMA && pSignFastMA>pSignSlowMA;

   if(CurrentOP.Type==-1)
     {
      CurrentOP.Name="";
      CurrentOP.Index=0;
      CurrentOP.Profit=0;
      CurrentOP.Loss=0;

     }
   else if(CurrentOP.Type==OP_BUY)
     {
      if(inpPrice==PRICE_OPEN)
         CurrentOP.ClosePrice=open;
      else
         CurrentOP.ClosePrice=close;

      CurrentOP.Profit=(CurrentOP.ClosePrice-CurrentOP.OpenPrice)/Point;
      CurrentOP.Loss=(CurrentOP.OpenPrice-low)/Point;

     }
   else if(CurrentOP.Type==OP_SELL)
     {
      if(inpPrice==PRICE_OPEN)
         CurrentOP.ClosePrice=open;
      else
         CurrentOP.ClosePrice=close;

      CurrentOP.Profit=(CurrentOP.OpenPrice-CurrentOP.ClosePrice)/Point;
      CurrentOP.Loss=(high-CurrentOP.OpenPrice)/Point;

     }

//Print(i," LastOP.Index=",LastOP.Index," LastOP.Name=",LastOP.Name," LastOP.Type=",LastOP.Type," CurrentOP.Type=",CurrentOP.Type);      
//Print(i," "," OpType=",CurrentOP.Type," OpName=",CurrentOP.Name," Loss=",CurrentOP.Loss);

//EA Purposes
   if(IsExpertEnabled() || IsTesting())
     {
      if(CurrentOP.Type==-1)
        {
         ExtShortBuyBuffer[i]=0;
         ExtShortSellBuffer[i]=0;
        }
      else if(CurrentOP.Type==OP_BUY)
        {
         ExtShortBuyBuffer[i]=ExtShortBuyBuffer[i-1];
         ExtShortSellBuffer[i]=0;
        }
      else if(CurrentOP.Type==OP_SELL)
        {
         ExtShortSellBuffer[i]=ExtShortSellBuffer[i-1];
         ExtShortBuyBuffer[i]=0;
        }
     }

//---- Assigning LastOP
   LastOP.Type=CurrentOP.Type;
   LastOP.Name=CurrentOP.Name;
   LastOP.Type=CurrentOP.Type;
   LastOP.Index=CurrentOP.Index;
   LastOP.OpenTime=CurrentOP.OpenTime;
   LastOP.OpenPrice=CurrentOP.OpenPrice;
   LastOP.OpenTime=CurrentOP.OpenTime;
   LastOP.Profit=NormalizeDouble(CurrentOP.Profit,0);
   LastOP.Loss=NormalizeDouble(CurrentOP.Loss,0);

   Draw_SessionIndicator(lCurrentTime,i);

//----
   if(ExtCloseBuff[i]!=0 && CurrentOP.Type!=-1)
     {
      LastOP.Name=CurrentOP.Name+"_CloseTime";
      LastOP.CloseTime=lCurrentTime;
      LastOP.ClosePrice=CurrentOP.ClosePrice;
      ExtProfitLossBuff[i]=LastOP.Profit;
      CurrentOP.Type=-1;
     }

   if(LastOP.Loss>=inpStopLoss && inpStopLoss>0 && CurrentOP.Type!=-1)
     {
      LastOP.Name=CurrentOP.Name+"_SL";
      LastOP.CloseTime=lCurrentTime;
      LastOP.ClosePrice=CurrentOP.ClosePrice;
      LastOP.Profit=-inpStopLoss;
      ExtProfitLossBuff[i]=LastOP.Profit;

      if(LastOP.Type==OP_BUY)
        {
         LastOP.ClosePrice=LastOP.OpenPrice+(LastOP.Profit*Point);
        }
      else if(LastOP.Type==OP_SELL)
        {
         LastOP.ClosePrice=LastOP.OpenPrice-(LastOP.Profit*Point);
        }

      CurrentOP.Type=-1;
     }

   else if(LastOP.Profit>=inpTakeProfit && inpTakeProfit>0 && CurrentOP.Type!=-1)
     {
      LastOP.Name=CurrentOP.Name+"_TP";
      LastOP.CloseTime=lCurrentTime;
      LastOP.ClosePrice=CurrentOP.ClosePrice;
      LastOP.Profit=inpTakeProfit;
      ExtProfitLossBuff[i]=LastOP.Profit;

      if(LastOP.Type==OP_BUY)
        {
         LastOP.ClosePrice=LastOP.OpenPrice+(LastOP.Profit*Point);
        }
      else if(LastOP.Type==OP_SELL)
        {
         LastOP.ClosePrice=LastOP.OpenPrice-(LastOP.Profit*Point);
        }
      CurrentOP.Type=-1;
     }
//----
   if(CloseSell && CurrentOP.Type==OP_SELL)
     {
      LastOP.Name=CurrentOP.Name+"_Close";
      LastOP.ClosePrice=CurrentOP.ClosePrice;
      ExtProfitLossBuff[i]=LastOP.Profit;
      LastOP.CloseTime=lCurrentTime;
      CurrentOP.Type=-1;
     }
   else if(CloseBuy && CurrentOP.Type==OP_BUY)
     {
      LastOP.Name=CurrentOP.Name+"_Close";
      ExtProfitLossBuff[i]=LastOP.Profit;
      LastOP.ClosePrice=CurrentOP.ClosePrice;
      LastOP.CloseTime=lCurrentTime;
      CurrentOP.Type=-1;
     }
//----
   if(ShortBuy && CurrentOP.Type!=OP_BUY)
     {
      if(LastOP.Type==OP_SELL)
        {
         LastOP.Name=CurrentOP.Name+"toBuy";
         LastOP.CloseTime=lCurrentTime;
         LastOP.ClosePrice=CurrentOP.ClosePrice;
         ExtProfitLossBuff[i]=LastOP.Profit;
        }
      if(inpPrice==PRICE_OPEN)
         CurrentOP.OpenPrice=open;
      else
         CurrentOP.OpenPrice=close;
      OpenNewOrder(OP_BUY,i,CurrentOP.OpenPrice,lCurrentTime);
     }
   else if(ShortSell && CurrentOP.Type!=OP_SELL)
     {
      if(LastOP.Type==OP_BUY)
        {
         LastOP.Name=CurrentOP.Name+"toSell";
         LastOP.CloseTime=lCurrentTime;
         LastOP.ClosePrice=CurrentOP.ClosePrice;
         ExtProfitLossBuff[i]=LastOP.Profit;
        }
      if(inpPrice==PRICE_OPEN)
         CurrentOP.OpenPrice=open;
      else
         CurrentOP.OpenPrice=close;
      OpenNewOrder(OP_SELL,i,CurrentOP.OpenPrice,lCurrentTime);
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateIndicatorProfit(int i,datetime lCurrentTime,double dLastProfit,int &iWinCount,int &iLossCount,double &iWinPoint,double &iLossPoint)
  {

   if(IsExpertEnabled() || IsTesting()) return 0;

//---- Calculating indicator win/loss
   if(i>=Bars-1) return 0;

//Print(i,"=",indProfit);

   if(bTrackIndicatorOP)
     {
      if(CurrentOP.Type==OP_BUY)
         CreateEntrySign(0,"cEntry"+CurrentOP.Name,0,CurrentOP.OpenTime,CurrentOP.OpenPrice,1,Blue);
      else if(CurrentOP.Type==OP_SELL)
         CreateEntrySign(0,"cEntry"+CurrentOP.Name,0,CurrentOP.OpenTime,CurrentOP.OpenPrice,1,Red);
     }

   if(LastOP.Type==-1)
      return 0;

   if(bTrackIndicatorOP && CurrentOP.Type!=LastOP.Type)
     {

      if(LastOP.Type==OP_BUY && (LastOP.CloseTime>=LastOP.OpenTime))
        {
         color signColor=clrBlue;
         TrendCreate(0,"trend"+LastOP.Name,0,LastOP.OpenTime,LastOP.OpenPrice,LastOP.CloseTime,LastOP.ClosePrice,signColor,2);
         CreateEntrySign(0,"close"+LastOP.Name,0,LastOP.CloseTime,LastOP.ClosePrice,3,signColor);
        }
      else if(LastOP.Type==OP_SELL && (LastOP.CloseTime>=LastOP.OpenTime))
        {
         color signColor=clrRed;
         TrendCreate(0,"trend"+LastOP.Name,0,LastOP.OpenTime,LastOP.OpenPrice,LastOP.CloseTime,LastOP.ClosePrice,signColor,2);
         CreateEntrySign(0,"close"+LastOP.Name,0,LastOP.CloseTime,LastOP.ClosePrice,3,signColor);
        }
     }

   if(dLastProfit>0)
     {
      iWinCount++;
      iWinPoint+=dLastProfit;

      if(dLastProfit>HighestTP)
         HighestTP=dLastProfit;
     }
   else if(dLastProfit<0)
     {
      iLossCount++;
      iLossPoint+=dLastProfit;

      if(dLastProfit<LowestSL)
         LowestSL=dLastProfit;
     }

   double yShift = 150*Point;
   if(LastOP.Type==OP_SELL)
      yShift=-(50*Point);

   CreateProfitLabel(LastOP.Name,lCurrentTime,priceShift(i)+yShift,(string)dLastProfit);
//Print("iWinPoint=",iWinPoint,"(",iWinCount,") iLossPoint=",iLossPoint,"(",iLossCount,") dLastProfit=",dLastProfit);
//Print("HighestTP=",HighestTP," LowestSL=",LowestSL);
   return iWinPoint-iLossPoint;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Draw_SessionIndicator(datetime lCurrentTime,int i)
  {
//--- Draw Session Open n Close Indicator
   string OpenTime[2],CloseTime[2];

   OpenTime[0]=GetSession(Symbol(),TimeOffset,lCurrentTime,"openzone");
   CloseTime[0]=GetSession(Symbol(),TimeOffset,lCurrentTime,"closezone");
   OpenTime[1]=GetSession(Symbol(),TimeOffset,lCurrentTime,"open");
   CloseTime[1]=GetSession(Symbol(),TimeOffset,lCurrentTime,"close");

   if(Period()>PERIOD_H1)
      UseCloseTime=false;

   if(!UseCloseTime)
     {
      OpenTime[1]="";
      CloseTime[1]="";
     }

   if(OpenTime[1]!="")
     {
      ExtOpenBuff[i]=priceShift(i);
      CreateDayLabel("SessionO"+(string)i,lCurrentTime,priceShift(i)+(priceShift(i)*(100*Point)),OpenTime[0]);
     }
   if(CloseTime[1]!="")
     {
      int yShift=100;

      ExtCloseBuff[i]=priceShift(i);

      if(ExtOpenBuff[i]!=0)
         yShift=200;

      CreateDayLabel("SessionC"+(string)i,lCurrentTime,priceShift(i)+(priceShift(i)*(yShift*Point)),CloseTime[0]);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double priceShift(int i)
  {
   double dPoint=0.20;
   switch(Period())
     {
      case PERIOD_M1:
      case PERIOD_M5:
      case PERIOD_M15:
         dPoint=0.10;
         break;

     }
   double yShift=(ExtUpperStopBuffer[i]-ExtLowerStopBuffer[i])*dPoint;

   if(LastOP.Type==OP_BUY || CurrentOP.Type==OP_SELL || CurrentOP.Type==-1)
      return ExtUpperStopBuffer[i]+yShift;
   else if(LastOP.Type==OP_SELL || CurrentOP.Type==OP_BUY)
      return ExtLowerStopBuffer[i]-yShift;


   return 0;
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
   double iCurProfit;
   string mOpenedOrder=CalculateCurrentOrders(iCurProfit);
   string mProfits=StringFormat("Profits: $%G ($%G)",iCurProfit,AccountProfit());
   string mSymSLnTP=StringFormat("SL/TP : %G/%G (%G/%G)",symSL,symTP,accSL,accTP);
   string mMaxRisk=StringFormat("Max. Risk : $%G",NormalizeDouble(AccountBalance()*MaxRisk,2));

   string mIndicatorProfit=StringConcatenate("Date : ",IndStartTime," - ",IndStopTime);
   string mIndicatorProfit2=StringFormat("Win : %G/%d (%G) | Loss : %G/%d (%G)",indProfit,indWinCount,HighestTP,MathAbs(indLoss),indLossCount,LowestSL);
   if((indWinCount+indLossCount)==0) indWinCount=indLossCount=1;
   string mIndicatorProfit3=StringFormat("Profits : %G pips (%G%%)",NormalizeDouble(indProfit-MathAbs(indLoss),0),NormalizeDouble((double)indWinCount/(double)(indWinCount+indLossCount)*100,2));

   string IndMAPeriods=(string)RZIMAPeriods[0]+","+(string)RZIMAPeriods[1]+","+(string)RZIMAPeriods[2]+","+(string)RZIMAPeriods[3];

//---- Coloring the spread and price info label
   BidColor=GetColor(dPrice,Old_Bid);
   IndProfitColor=GetColor(indProfit,MathAbs(indLoss));
   IndWinColor=GetColor(indWinCount,indLossCount);

//---- Change old price value for coloring next price info label 
   Old_Bid=dPrice;
   int ProfitColor=GetColor(iCurProfit,0);
   int TotalProfitColor=GetColor(AccountProfit(),0);
   int EntryColor=GetColor(CurrentOP.Type,-1,1,0,2);
   int SLTPColor=GetColor(accTP,accSL);
   int SymSLTPColor=GetColor(symTP,symSL);

//---- Show the labels

   DeleteObject(0,"BestOpenPrice");

   if(LastOP.Type!=-1)
      CreateEntrySign(0,"BestOpenPrice",0,TimeCurrent(),LastOP.OpenPrice,6,EntryColor,0,1,false,false,false,0,"Recommended Open Price");

/*
   DeleteObject(0,"TodayLow");
   createEntrySign(0,"TodayLow",0,TimeCurrent(),dLow,6,FontColor,0,1,false,false,false,0,"Today Low");
*/
//---- Show price label
   CreateLabel(0,mHigh,"Lbl_High",FontSize,FontType,FontColor,Corner,1,iYPos+0);
   CreateLabel(0,mBid,"Lbl_Bid",FontSize,FontType,BidColor,Corner,1,iYPos+1);
   CreateLabel(0,mLow,"Lbl_Low",FontSize,FontType,FontColor,Corner,1,iYPos+2);
   CreateLabel(0,mPRange,"Lbl_Range",FontSize,FontType,FontColor,Corner,1,iYPos+3);

//---- Show entry sign and profit label
   CreateLabel(0,mOpenedOrder,"Lbl_OpenedOrder",FontSize,FontType,ProfitColor,Corner,1,iYPos+4);
   CreateLabel(0,mProfits,"Lbl_Profit",FontSize,FontType,ProfitColor,Corner,1,iYPos+5);
   CreateLabel(0,mSymSLnTP,"Lbl_symSLTP",FontSize,FontType,SymSLTPColor,Corner,1,iYPos+6);
   CreateLabel(0,mMaxRisk,"Lbl_maxRisk",FontSize,FontType,FontColor,Corner,1,iYPos+7);

   CreateMTFSign(NULL,MACDPeriod,STOCHPeriod,0,iYPos+11,inpMethod,inpPrice,0,MyID,true,false);

   CreateLabel(0,mIndicatorProfit,"Lbl_IndProfit",FontSize-1,FontType,IndProfitColor,2,1,0);
   CreateLabel(0,mIndicatorProfit2,"Lbl_IndProfit2",FontSize-1,FontType,IndWinColor,2,200,0);
   CreateLabel(0,mIndicatorProfit3,"Lbl_IndProfit3",FontSize-1,FontType,IndProfitColor,2,400,0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OpenNewOrder(int lOrderType,int i,double openPrice,datetime openTime)
  {
   double dSpread=MarketInfo(NULL,MODE_SPREAD)*Point;

   if(dSpread>(50*Point))
     {
      CreateLabel(0,"Spread too high "+(string)(dSpread/Point)+"! Reduced to 20 for calculation.","lblWarning",7,FontType,clrRed,1,200,0);
      dSpread=20*Point;
     }

   CurrentOP.Type=lOrderType;
   CurrentOP.Index=i;
   CurrentOP.OpenTime=openTime;

   if(lOrderType==OP_BUY)
     {
      CurrentOP.OpenPrice=openPrice+dSpread;
      CurrentOP.Name="Buy"+(string)CurrentOP.Index;
      ExtShortBuyBuffer[i]=priceShift(i);
     }
   else if(lOrderType==OP_SELL)
     {
      CurrentOP.OpenPrice=openPrice-dSpread;
      CurrentOP.Name="Sell"+(string)CurrentOP.Index;
      ExtShortSellBuffer[i]=priceShift(i);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ShiftMAPeriods(int &lRZIMAPeriods[],int lMAShift)
  {
   for(int i=0;i<ArraySize(lRZIMAPeriods);i++)
     {
      lRZIMAPeriods[i]=lRZIMAPeriods[i]+lMAShift;
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ChangeBestInputParams()
  {
   if(Period()==PERIOD_M5)
     {
      if(Symbol()=="USDJPYxx")
        {

        }
     }
  }
//+------------------------------------------------------------------+
