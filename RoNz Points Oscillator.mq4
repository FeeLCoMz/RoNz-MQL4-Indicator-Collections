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


extern int inpPeriod=1; //Period
extern int inpSlowing=2; //Slowing
extern ENUM_MA_METHOD inpMethod=MODE_EMA; //Method

const string MyShortName="RoNz Points Oscillator";
const string MyID="RPO";

#property indicator_separate_window
#property indicator_buffers 4

#property indicator_level1 0
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT

#property indicator_label1  "Low/High"
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrWhite
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_label2  "High/Low"
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

#property indicator_label3  "Open"
#property indicator_type3   DRAW_HISTOGRAM
#property indicator_color3  clrWhite
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2

#property indicator_label4  "Close"
#property indicator_type4   DRAW_HISTOGRAM
#property indicator_color4  clrRed
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2

//--- indicator buffers
double   ExtLowHighBuff[],ExtHighLowBuff[],ExtOpenBuff[],ExtCloseBuff[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtLowHighBuff);
   SetIndexBuffer(1,ExtHighLowBuff);
   SetIndexBuffer(2,ExtOpenBuff);
   SetIndexBuffer(3,ExtCloseBuff);

   for(int i=0;i<4;i++)
     {
      SetIndexShift(i,0);
      SetIndexDrawBegin(i,0);
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

      double FastHighMA = iMA(NULL,0,inpPeriod,0,inpMethod,PRICE_HIGH,i);
      double SlowHighMA = iMA(NULL,0,inpPeriod+inpSlowing,0,inpMethod,PRICE_HIGH,i);
      double FastLowMA = iMA(NULL,0,inpPeriod,0,inpMethod,PRICE_LOW,i);
      double SlowLowMA = iMA(NULL,0,inpPeriod+inpSlowing,0,inpMethod,PRICE_LOW,i);
      double FastOpenMA = iMA(NULL,0,inpPeriod,0,inpMethod,PRICE_OPEN,i);
      double SlowOpenMA = iMA(NULL,0,inpPeriod+inpSlowing,0,inpMethod,PRICE_OPEN,i);
      double FastCloseMA = iMA(NULL,0,inpPeriod,0,inpMethod,PRICE_CLOSE,i);
      double SlowCloseMA = iMA(NULL,0,inpPeriod+inpSlowing,0,inpMethod,PRICE_CLOSE,i);

      ExtOpenBuff[i]=FastOpenMA-SlowOpenMA;
      ExtCloseBuff[i]=FastCloseMA-SlowCloseMA;

      if(ExtCloseBuff[i]>ExtOpenBuff[i])
        {
         ExtLowHighBuff[i]=FastHighMA-SlowHighMA;
         ExtHighLowBuff[i]=FastLowMA-SlowLowMA;
        }
      else
        {
         ExtHighLowBuff[i]=FastHighMA-SlowHighMA;
         ExtLowHighBuff[i]=FastLowMA-SlowLowMA;
        }

     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
