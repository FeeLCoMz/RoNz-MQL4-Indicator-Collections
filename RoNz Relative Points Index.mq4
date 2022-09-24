//+------------------------------------------------------------------+
//|                                          RoNz Trend Strength.mq4 |
//|                                   Copyright 2014, Rony Nofrianto |
//|                                          http://www.feelcomz.com |
//+------------------------------------------------------------------+
#property copyright   "2014, Rony Nofrianto, Indonesia."
#property link        "http://www.feelcomz.com"
#property description "RoNz Pips Average"
#property version   "1.00" //Build 140826
#property strict

#include  <MovingAverages.mqh>
#include  <RoNzIndicatorFunctions.mqh>

extern int inpDayShift=1; //Day Shift

const string MyShortName="RoNz Relative Points Index";
const string MyID="RPA";

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

#property indicator_label2  "Previous Day Relative Pips"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDodgerBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

//--- indicator buffers
double   PipsBuff[],PrevDayPipsBuff[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   IndicatorShortName(MyShortName+" ("+(string)inpDayShift+" Days)");
//--- indicator buffers mapping
   SetIndexBuffer(0,PipsBuff);
   SetIndexBuffer(1,PrevDayPipsBuff);

   int pShift=(PERIOD_D1*inpDayShift)/Period();
   
   SetIndexShift(0,0);
   SetIndexShift(1,pShift);

   SetIndexDrawBegin(0,0);
   SetIndexDrawBegin(1,pShift);
   
   IndicatorDigits(0);

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
      ArrayInitialize(PrevDayPipsBuff,0);

      limit=rates_total;
     }
   else
     {
      limit=rates_total-(prev_calculated-1);
     }

   int shift=0;

   for(int i=0; i<limit && !IsStopped(); i++)
     {
      shift=iBarShift(NULL,PERIOD_D1,Time[i]);
            
      PipsBuff[i]=(Close[i]-iOpen(NULL,PERIOD_D1,shift))/Point;      
      //PrevDayPipsBuff[i]=(Close[i]-iOpen(NULL,PERIOD_D1,shift+inpDayShift))/Point;
      PrevDayPipsBuff[i]=(Close[i]-iOpen(NULL,PERIOD_D1,shift))/Point;      
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
