//+---------------------------------------------------+
//| RoNz Indicator.mq4        v1.0 (14.08.29) by RoNz |
//+---------------------------------------------------+
#property copyright   "2014, Rony Nofrianto, Indonesia."
#property link        "http://www.feelcomz.com"
#property description "RoNz Trading Indicator"
#property version   "1.0"
#property strict
#include <stdlib.mqh>
#include <RoNzIndicatorFunctions.mqh>
#property indicator_separate_window

int FontSize=8;
int iYPos=1;

//---- Indicator Buffers
double ExtMA1[],ExtMA2[];
double ExtMA3[],ExtMA4[];
//----  Indicator Inputs
extern ENUM_MA_METHOD inpMethod=MODE_EMA; // Moving Average Method
extern ENUM_APPLIED_PRICE inpPrice=PRICE_CLOSE;   // Applied Price
extern int    InpShift=0;  // Shift
//----
string MyShortName="RoNz Period Relative MA";
const string MyID="RPRMA";

#property indicator_level1 0
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT

#property indicator_buffers 4

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

//----
int RZIMAPeriods[],HigherPeriod[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnInit(void)
  {
   CalculateMAPeriods(Period(),HigherPeriod,RZIMAPeriods);

   MyShortName=MyShortName+" ("+(string)RZIMAPeriods[0]+","+(string)RZIMAPeriods[1]+","+(string)RZIMAPeriods[2]+","+(string)RZIMAPeriods[3]+")";
//----   
   IndicatorShortName(MyShortName);
   IndicatorDigits(Digits);
//---- Setting Indicator Label
   SetIndexLabel(0,"MA1 "+(string)RZIMAPeriods[0]);
   SetIndexLabel(1,"MA2 "+(string)RZIMAPeriods[1]);
   SetIndexLabel(2,"MA3 "+(string)RZIMAPeriods[2]);
   SetIndexLabel(3,"MA4 "+(string)RZIMAPeriods[3]);
//---- Set Index Buffer
   SetIndexBuffer(0,ExtMA1);
   SetIndexBuffer(1,ExtMA2);
   SetIndexBuffer(2,ExtMA3);
   SetIndexBuffer(3,ExtMA4);
//---- MA Indicator Shift
   SetIndexShift(0,InpShift);
   SetIndexShift(1,InpShift);
   SetIndexShift(2,InpShift);
   SetIndexShift(3,InpShift);
//---- MA Indicator
   SetIndexDrawBegin(0,InpShift+RZIMAPeriods[0]);
   SetIndexDrawBegin(1,InpShift+RZIMAPeriods[1]);
   SetIndexDrawBegin(2,InpShift+RZIMAPeriods[2]);
   SetIndexDrawBegin(3,InpShift+RZIMAPeriods[3]);

//---- Invisible Value
   for(int i=0; i<4; i++)
      SetIndexEmptyValue(i,0);

   EventSetTimer(1);
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

//---- Return if no data was calculated before
   if(prev_calculated<0) return(-1);

   int limit;

   if(prev_calculated==0)
     {
      ArrayInitialize(ExtMA1,0);
      ArrayInitialize(ExtMA2,0);
      ArrayInitialize(ExtMA3,0);
      ArrayInitialize(ExtMA4,0);

      //---- Setting the indicator limit count         
      limit=Bars;
     }
   else
      limit=Bars-(prev_calculated-1);

//---- Calculating MA indicator
   for(int i=0; i<limit && !IsStopped(); i++)
     {
      //---- Calculating Moving Average for each indicator      
      ExtMA4[i] = iMA(NULL, 0, RZIMAPeriods[2], 0, inpMethod, inpPrice, i)-iMA(NULL, 0, RZIMAPeriods[3], 0, inpMethod, inpPrice, i);
      ExtMA3[i] = iMA(NULL, 0, RZIMAPeriods[1], 0, inpMethod, inpPrice, i)-iMA(NULL, 0, RZIMAPeriods[3], 0, inpMethod, inpPrice, i);
      ExtMA2[i] = iMA(NULL, 0, RZIMAPeriods[0], 0, inpMethod, inpPrice, i)-iMA(NULL, 0, RZIMAPeriods[3], 0, inpMethod, inpPrice, i);
      ExtMA1[i] = iMA(NULL, 0, RZIMAPeriods[0]/2, 0, inpMethod, inpPrice, i)-iMA(NULL, 0, RZIMAPeriods[3], 0, inpMethod, inpPrice, i); 

     }

//---- Return calculated bar
   return(rates_total);
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
