//+------------------------------------------------------------------+
//|                                   RoNz Stochastic Oscillator.mq4 |
//|                                   Copyright 2014, Rony Nofrianto |
//|                                          http://www.feelcomz.com |
//+------------------------------------------------------------------+
#property copyright   "2014, Rony Nofrianto, Indonesia."
#property link        "http://www.feelcomz.com"
#property description "RoNz Stochastic Oscillator"
#property version   "1.00" //Build 140924
#property strict

#include  <MovingAverages.mqh>
#include  <RoNzIndicatorFunctions.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_ST_PRICE
  {
   ST_HIGH,//High
   ST_LOW,//Low
   ST_OPEN,//Open
   ST_CLOSE,//Close
   ST_HIGHLOW,//High/Low
   ST_OPENCLOSE//Open/Close
  };

enum EN_LINEMODE { Line,Histogram };

extern int inpPeriod=4; //Period
extern int inpSlowing=2; //Slowing
extern ENUM_MA_METHOD inpMethod=MODE_EMA; //Method
extern ENUM_ST_PRICE inpStoPrice=ST_CLOSE; //Price
extern EN_LINEMODE inpLineMode=Histogram;//Line Mode

const string MyShortName="RoNz Stochastic Oscillator";
const string MyID="ROA";
int FontSize=8;

#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   4

#property indicator_level1 0
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT

#property indicator_label1  "High"
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_label2  "Low"
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1


//--- indicator buffers
double   ExtHighBuff[],ExtLowBuff[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {

//--- indicator buffers mapping
   SetIndexBuffer(0,ExtHighBuff);
   SetIndexBuffer(1,ExtLowBuff);

   for(int i=0;i<2;i++)
     {
      SetIndexShift(i,0);
      SetIndexDrawBegin(i,0);
      
      if(inpLineMode==Line)
         SetIndexStyle(i,DRAW_LINE);
      else if(inpLineMode==Histogram)
         SetIndexStyle(i,DRAW_HISTOGRAM);
     }
   IndicatorShortName(MyShortName+" ("+(string)inpPeriod+","+(string)inpSlowing+")");
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
      limit=rates_total;
     }
   else
     {
      limit=rates_total-(prev_calculated-1);
     }

   for(int i=0; i<limit && !IsStopped(); i++)
     {

      int p[2];

      switch(inpStoPrice)
        {
         case ST_HIGH:
            p[0]=p[1]=PRICE_HIGH;
            break;
         case ST_LOW:
            p[0]=p[1]=PRICE_LOW;
            break;
         case ST_OPEN:
            p[0]=p[1]=PRICE_OPEN;
            break;
         case ST_CLOSE:
            p[0]=p[1]=PRICE_CLOSE;
            break;
         case ST_HIGHLOW:
            p[0]=PRICE_HIGH;
            p[1]=PRICE_LOW;
            break;
         case ST_OPENCLOSE:
            p[0]=PRICE_OPEN;
            p[1]=PRICE_CLOSE;
            break;
        }

      ExtHighBuff[i]=iMA(NULL,0,inpPeriod,0,inpMethod,p[0],i)-iMA(NULL,0,inpPeriod+inpSlowing,0,inpMethod,p[1],i);
     }
     
     SimpleMAOnBuffer(rates_total,prev_calculated,0,inpSlowing*2,ExtHighBuff,ExtLowBuff);

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
