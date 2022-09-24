//+------------------------------------------------------------------+
//|                                          RoNz Trend Strength.mq4 |
//|                                   Copyright 2014, Rony Nofrianto |
//|                                          http://www.feelcomz.com |
//+------------------------------------------------------------------+
#property copyright   "2014, Rony Nofrianto, Indonesia."
#property link        "http://www.feelcomz.com"
#property description "RoNz Pips Average"
#property version   "1.00" //Build 140924
#property strict

#include  <MovingAverages.mqh>
#include  <RoNzIndicatorFunctions.mqh>

extern int inpPeriod=2; //Period
extern ENUM_MA_METHOD inpMethod=MODE_EMA; //Method
extern ENUM_APPLIED_PRICE inpPrice=PRICE_CLOSE; //Applied Price

const string MyShortName="RoNz Relative Volume Index";
const string MyID="RVI";
int FontSize=8;

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2

#property indicator_level1 0
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT

#property indicator_label1  "Pips"
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrWhite
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_label2  "Pips Average"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDodgerBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

//--- indicator buffers
double   PipsBuff[],PipsAvgBuff[];
int HPeriods[],MAPeriods[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
  CalculateMAPeriods(0,HPeriods,MAPeriods);

//--- indicator buffers mapping
   SetIndexBuffer(0,PipsBuff);
   SetIndexBuffer(1,PipsAvgBuff);

   SetIndexShift(0,0);
   SetIndexShift(1,0);

   SetIndexDrawBegin(0,0);
   SetIndexDrawBegin(1,0);

   IndicatorShortName(MyShortName);
   IndicatorDigits(Digits);

//---
   return(INIT_SUCCEEDED);
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
     
      ArrayInitialize(PipsBuff,0);
      ArrayInitialize(PipsAvgBuff,0);     

      limit=rates_total;
     }
   else
     {
      limit=rates_total-(prev_calculated-1);
     }

   for(int i=0; i<limit && !IsStopped(); i++)
     {      
      PipsBuff[i]=(iMA(NULL,0,inpPeriod,0,inpMethod,inpPrice,i)-iMA(NULL,0,MAPeriods[2],0,inpMethod,inpPrice,i))+(Volume[i]*Point*Point);      
     }
 
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+