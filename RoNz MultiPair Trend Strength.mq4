//+------------------------------------------------------------------+
//|                               RoNz Multi Pair Trend Strength.mq4 |
//|                              Copyright 2014-2016, Rony Nofrianto |
//+------------------------------------------------------------------+
#property copyright   "2014-2016, Rony Nofrianto, Indonesia."
#property link "https://www.mql5.com/en/users/ronz"
#property description "RoNz MultiPair Trend Strength"
#property version   "1.1" //Build 250316
#property strict
#property indicator_chart_window
#property show_inputs 
#include  <MovingAverages.mqh>
#include  <RoNzIndicatorFunctions.mqh>

extern string inpInstruments="EURUSD USDJPY GBPUSD USDCHF USDCAD AUDUSD EURJPY AUDJPY CADJPY CADCHF EURAUD EURGBP";
extern ENUM_MA_METHOD inpMethod=MODE_SMA; // Moving Average Method
extern ENUM_APPLIED_PRICE inpPrice=PRICE_CLOSE;   // Applied Price
extern int    FastPeriod=12;    // Fast MA Period
extern string    MACDPeriod="12,26,9";   // MACD Period (FastEMA,SlowEMA,Signal)
extern string    STOCHPeriod="5,3,3";   // Stochasthic Period (K,D,Slowing)
extern bool    inpShowPricePos=false; //Show Daily Price Position

const string MyShortName="RoNz Multi Pair Trend Strength";
const string MyID="Rz_MPTS";
const int FontSize=5;

double ExtBuff1[];
#property indicator_buffers 1

#property indicator_label1  "Buff1"
#property indicator_color1 clrGray
#property  indicator_type1 DRAW_LINE

int RZIMAPeriods[];
int UpperPeriods[];
int RZIMACDPeriods[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   CalculateMAPeriods(0,UpperPeriods,RZIMAPeriods);
   SetIndexBuffer(0,ExtBuff1);
   SetIndexDrawBegin(0,0);

   IndicatorShortName(MyShortName);

   EventSetTimer(2);

   ChartSetInteger(0,CHART_VISIBLE_BARS,0);
   ChartSetInteger(0,CHART_SHOW_PERIOD_SEP,false);
   ChartSetInteger(0,CHART_SHOW_GRID,false);
   ChartSetInteger(0,CHART_SHOW_ASK_LINE,false);
   ChartSetInteger(0,CHART_SHOW_BID_LINE,false);
   ChartSetInteger(0,CHART_SHOW_DATE_SCALE,false);
   ChartSetInteger(0,CHART_SHOW_PRICE_SCALE,false);
   ChartSetInteger(0,CHART_SHOW_OHLC,false);
   ChartSetInteger(0,CHART_COLOR_STOP_LEVEL,clrNONE);
   ChartSetInteger(0,CHART_COLOR_CHART_LINE,clrNONE);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print(__FUNCTION__,"_Uninitalization reason code = ",reason);
   ObjectsDeleteAll(WindowFind(MyShortName));
   EventKillTimer();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   string instrument[];
   StringSplit(inpInstruments,StringGetCharacter(" ",0),instrument);

   int x=0;
   int y=0;
   int MaxRow=6;

   for(int i=0;i<ArraySize(instrument);i++)
     {
      int insRemain=ArraySize(instrument)-(i+1);      
      y=insRemain/MaxRow;

      x=y*MaxRow+i-(MaxRow-2);

      //Print("i=",i," insRemain=",insRemain,"(",instrument[insRemain],")"," y=",y," x=",x);
      CreateMTFSign(instrument[insRemain],MACDPeriod,STOCHPeriod,(x)*12,y*13,inpMethod,inpPrice,0,MyID);

     }

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
//---
   int limit;

//---- Return if no data was calculated before
   if(prev_calculated<0) return(-1);

   if(prev_calculated==0)
     {
      ArrayInitialize(ExtBuff1,0);
      //---- Setting the indicator limit count         
      limit=Bars;
     }
   else
     {
      //---- Setting the indicator limit count
      limit=Bars-(prev_calculated-1);
     }

   for(int i=0; i<limit && !IsStopped(); i++)
     {
      ExtBuff1[i]=close[i];
     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
