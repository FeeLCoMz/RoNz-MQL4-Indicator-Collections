//+------------------------------------------------------------------+
//|                                          RoNz Trend Strength.mq4 |
//|                              Copyright 2014-2016, Rony Nofrianto |
//|                                          http://www.feelcomz.com |
//+------------------------------------------------------------------+
#property copyright   "2014-2016, Rony Nofrianto, Indonesia."
#property link        "http://www.feelcomz.com"
#property description "RoNz Trend Strength"
#property version   "1.00" //Build 020416
#property strict

#include  <MovingAverages.mqh>
#include  <RoNzIndicatorFunctions.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum EN_VIEWMODE { Single,Multi,Both };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum EN_LINEMODE { Line, Histogram_Line };

extern string              MACDPeriod="12,26,9";   // MACD Period (FastEMA,SlowEMA,Signal)
extern string              STOCHPeriod="5,3,3";   // Stochasthic Period (K,D,Slowing)
extern ENUM_MA_METHOD      inpMethod=MODE_SMA; // Moving Average Method
extern ENUM_APPLIED_PRICE  inpPrice=PRICE_CLOSE;   // Applied Price
extern EN_STD_TIMEFRAMES   inp2ndTimeframe=DEFAULT; //Secondary Timeframe Indicator
extern int                 MultiTimeFrameLimit=256; //Multi Timeframe Indicator Bar Limit
extern EN_VIEWMODE         ViewMode=Single;
extern EN_LINEMODE         LineMode=Histogram_Line;

const string MyShortName="RoNz Trend Strength";
const string MyID="RTS";
const int StyleWidth=1;

#property indicator_separate_window
#property indicator_minimum -100
#property indicator_maximum 100
#property indicator_buffers 7
#property indicator_plots   7

#property indicator_level1     -40
#property indicator_level2     40
#property indicator_level3     0
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT

//--- plot Single Up
#property indicator_label1  "Single Up"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Single Down
#property indicator_label2  "Single Down"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot Multi Up
#property indicator_label3  "Secondary Up"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrDodgerBlue
#property indicator_style3  STYLE_DASHDOT
#property indicator_width3  2
//--- plot Multi Down
#property indicator_label4  "Secondary Down"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrDarkOrange
#property indicator_style4  STYLE_DASHDOT
#property indicator_width4  2
//--- plot Slower Up
#property indicator_label5  "Multi Up"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrGreen
#property indicator_style5  STYLE_SOLID
#property indicator_width5  2
//--- plot Slower Down
#property indicator_label6  "Multi Down"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrMaroon
#property indicator_style6  STYLE_SOLID
#property indicator_width6  2
//--- plot Price Position
#property indicator_label7  "RSI"
#property indicator_type7   DRAW_LINE
#property indicator_color7  clrSilver
#property indicator_style7  STYLE_SOLID
#property indicator_width7  1


//--- indicator buffers
double   UpBuffer[],DownBuffer[];
double   UpBuffer2[],DownBuffer2[];
double   MultiUpBuffer[],MultiDownBuffer[];
double   RSIBuff[];

int RZIMAPeriods[4];
int UpperPeriods[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   CalculateMAPeriods(0,UpperPeriods,RZIMAPeriods);
//ObjectsDeleteAll(WindowFind(MyShortName));

//--- indicator buffers mapping
   SetIndexBuffer(0,UpBuffer);
   SetIndexBuffer(1,DownBuffer);
   SetIndexBuffer(2,UpBuffer2);
   SetIndexBuffer(3,DownBuffer2);
   SetIndexBuffer(4,MultiUpBuffer);
   SetIndexBuffer(5,MultiDownBuffer);
   SetIndexBuffer(6,RSIBuff);

   SetIndexDrawBegin(0,0);
   SetIndexDrawBegin(1,0);
   SetIndexDrawBegin(2,0);
   SetIndexDrawBegin(3,0);
   SetIndexDrawBegin(4,0);
   SetIndexDrawBegin(5,0);

   if(LineMode==Line)
     {
      SetIndexStyle(0,DRAW_LINE,0,1);
      SetIndexStyle(1,DRAW_LINE,0,1);
      SetIndexStyle(2,DRAW_LINE,0,StyleWidth);
      SetIndexStyle(3,DRAW_LINE,0,StyleWidth);
     }
   else if(LineMode==Histogram_Line)
     {
      SetIndexStyle(0,DRAW_HISTOGRAM,0,StyleWidth);
      SetIndexStyle(1,DRAW_HISTOGRAM,0,StyleWidth);
      SetIndexStyle(2,DRAW_LINE,0,StyleWidth);
      SetIndexStyle(3,DRAW_LINE,0,StyleWidth);
     }

   if(ViewMode==Single && ViewMode!=Both)
     {
      SetIndexStyle(4,DRAW_NONE);
      SetIndexStyle(5,DRAW_NONE);
     }
   else if(ViewMode==Multi && ViewMode!=Both)
     {
      SetIndexStyle(0,DRAW_NONE);
      SetIndexStyle(1,DRAW_NONE);
      SetIndexStyle(2,DRAW_NONE);
      SetIndexStyle(3,DRAW_NONE);
     }

   IndicatorShortName(MyShortName);
   IndicatorDigits(2);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print(__FUNCTION__,"_Uninitalization reason code = ",reason);
   Print(__FUNCTION__,"_UninitReason = ",getUninitReasonText(_UninitReason));
   if(reason==3)
      ObjectsDeleteAll(WindowFind(MyShortName));

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
      ArrayInitialize(UpBuffer,0);
      ArrayInitialize(DownBuffer,0);
      ArrayInitialize(UpBuffer2,0);
      ArrayInitialize(DownBuffer2,0);
      ArrayInitialize(MultiUpBuffer,0);
      ArrayInitialize(MultiDownBuffer,0);
      ArrayInitialize(RSIBuff,0);

      //---- Setting the indicator limit count         
      limit=Bars;
     }
   else
     {
      //---- Setting the indicator limit count
      limit=Bars-(prev_calculated-1);
     }

//Print("Bars=",Bars," limit=",limit," prev_calculated=",prev_calculated," rates_total=",rates_total);
   double percentage[2],tfPercentage[2];
   MultiTimeframeSign multiSign;
   MultiTimeframeSign aMultiSign[];
   IndicatorSign indSign[];

//---- Calculating MA indicator
   for(int i=0; i<limit && !IsStopped(); i++)
     {

      if(ViewMode==Single || ViewMode==Both)
        {         
         CalculateMultiIndicator(NULL,0,MACDPeriod,STOCHPeriod,i,multiSign,indSign,inpMethod,inpPrice);
         UpBuffer[i]=multiSign.UpPercentage-multiSign.DownPercentage;
         
         if(LineMode==Histogram_Line)
           {
            DownBuffer[i]=multiSign.UpPercentage-multiSign.DownPercentage;
            if(UpBuffer[i]>=0) DownBuffer[i]=0;
            else if(UpBuffer[i]<=0) UpBuffer[i]=0;
           }
         else
         {
         DownBuffer[i]=multiSign.DownPercentage-multiSign.UpPercentage;
         }

         Draw_SecondaryPeriodIndicator(i,time[i],close[i]);

        }

      if(ViewMode==Multi || ViewMode==Both)
        {

         if(i<=MultiTimeFrameLimit)
           {
            CalculateMultiTimeIndicator(NULL,time[i],MACDPeriod,STOCHPeriod,tfPercentage,aMultiSign,inpMethod,inpPrice);

            MultiUpBuffer[i]=tfPercentage[1];
            MultiDownBuffer[i]=tfPercentage[0];

            Draw_SecondaryPeriodIndicator(i,time[i],close[i]);

           }
        }
     }

   CreateMTFSign(NULL,MACDPeriod,STOCHPeriod,1,0,inpMethod,inpPrice,WindowFind(MyShortName),MyID);

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Draw_SecondaryPeriodIndicator(int i,datetime dtTime,double price)
  {
   double percentage[3];
   MultiTimeframeSign MyMultiSign;
   IndicatorSign indSign[];

   if(inp2ndTimeframe==0)
     {
      inp2ndTimeframe=D1;

      switch(Period())
        {
         case 1:inp2ndTimeframe=M5;break;
         case 5:inp2ndTimeframe=M15;break;
         case 15: inp2ndTimeframe=M30;break;
         case 30:inp2ndTimeframe=H1;break;
         case 60: inp2ndTimeframe=H4;break;
         case PERIOD_H4: inp2ndTimeframe=D1;break;
         case PERIOD_D1: inp2ndTimeframe=W1;break;
         case PERIOD_W1: inp2ndTimeframe=MN1;break;
        }
     }

   SetIndexLabel(2,"2nd Up ("+(string)inp2ndTimeframe+")");
   SetIndexLabel(3,"2nd Down ("+(string)inp2ndTimeframe+")");
   SetIndexLabel(6,"RSI ("+(string)RZIMAPeriods[0]+")");

   int shift=iBarShift(NULL,inp2ndTimeframe,dtTime,false);
   double dHigh= iHigh(NULL,inp2ndTimeframe,shift);
   double dLow = iLow(NULL,inp2ndTimeframe,shift);
   double dPRange=NormalizeDouble((dHigh-dLow),Digits());
   if(dPRange==0) dPRange=Point();
   double dPricePos=NormalizeDouble(100 -((dHigh-price)/dPRange)*100,0);
   
   if (price>iHigh(NULL,inp2ndTimeframe,shift+1))
      dPricePos = dPricePos;
   else if (price<iLow(NULL,inp2ndTimeframe,shift+1))
      dPricePos = dPricePos-100;      
   else
      dPricePos = (dPricePos*2)-100;
            
   CalculateMultiIndicator(NULL,inp2ndTimeframe,MACDPeriod,STOCHPeriod,shift,MyMultiSign,indSign, inpMethod,inpPrice);

   UpBuffer2[i]=MyMultiSign.UpPercentage-MyMultiSign.DownPercentage;
   DownBuffer2[i]=MyMultiSign.DownPercentage-MyMultiSign.UpPercentage;   
   
   RSIBuff[i]=(iRSI(NULL,0,RZIMAPeriods[0],inpPrice,i)*2)-100;
  }
//+------------------------------------------------------------------+
