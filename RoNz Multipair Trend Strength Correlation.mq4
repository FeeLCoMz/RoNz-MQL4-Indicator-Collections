//+------------------------------------------------------------------+
//|                    RoNz MultiPair Trend Strength Correlation.mq4 |
//|                              Copyright 2014-2016, Rony Nofrianto |
//+------------------------------------------------------------------+
/*
v1.1
   + Added GBPNZD pair
   + Removed USDSGD pair
v1.2
   + Automatically detect pairs postfix
   + Automatically remove unavailable pairs
v1.3
   + Added option for Showing Pair Group Only   
   + Added option for Calculating Current Pair Only
*/

#property copyright   "2014-2016, Rony Nofrianto, Indonesia."
#property link "https://www.mql5.com/en/users/ronz"
#property description "RoNz MultiPair Trend Strength Correlation"
#property version   "1.3" //Build 010416
#property strict
#property indicator_separate_window
#include  <RoNzIndicatorFunctions.mqh>

int FontSize=5;

extern bool ShowRTSOnly=true; //Show RTS / Percentage
extern bool ShowPairGroupOnly=false; //Show Pair Group Only
extern bool inpUseCurrentPairOnly=false; //Use Current Pair Only
extern bool inpCalculateAllTimeFrame=true; //Calculate All / Current Timeframe
extern ENUM_MA_METHOD inpMethod=MODE_EMA; //Moving Average Method
extern ENUM_APPLIED_PRICE inpPrice=PRICE_CLOSE;   //Applied Price
extern string    MACDPeriod="12,26,9";   //MACD Period (FastEMA,SlowEMA,Signal)
extern string    STOCHPeriod="5,3,3";   //Stochasthic Period (K,D,Slowing)
extern int  inpRefreshInterval=3;//Refresh Interval (Seconds)

const string MyShortName="RoNz MultiPair Trend Strength Correlation";
const string MyID="Rz_MPTSC";
int MySubWindow=WindowFind(MyShortName);

//Indicator Buffers
double ExtBuff1[],ExtBuff2[];
#property indicator_buffers 2
#property indicator_minimum -100
#property indicator_maximum 100
#property indicator_level1     0
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT

#property indicator_label1  "Buff1"
#property indicator_color1 clrDarkBlue
#property  indicator_type1 DRAW_LINE
#property indicator_width1 1

#property indicator_label2  "Buff2"
#property indicator_color2 clrDarkRed
#property  indicator_type2 DRAW_LINE
#property indicator_width2 1

int RZIMAPeriods[];
int UpperPeriods[];
SymGroup InsPairs[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   CalculateMAPeriods(0,UpperPeriods,RZIMAPeriods);

   SetIndexBuffer(0,ExtBuff1);
   SetIndexBuffer(1,ExtBuff2);
   SetIndexDrawBegin(0,0);
   SetIndexDrawBegin(1,0);
   SetIndexLabel(0,StringSubstr(Symbol(),0,3));
   SetIndexLabel(1,StringSubstr(Symbol(),3,3));

   IndicatorShortName(MyShortName);
   IndicatorDigits(2);

/*
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
   ChartSetInteger(0,CHART_SHIFT,true);
   */
   ChartSetInteger(0,CHART_COLOR_FOREGROUND,clrDarkGray);

   if(inpUseCurrentPairOnly)
      CheckAvailableSymbols(Symbol());
   else
      CheckAvailableSymbols();

   ShowAllPairRTS();

   EventSetTimer(inpRefreshInterval);
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
   ShowAllPairRTS();
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(prev_calculated==0)
     {
      ArrayInitialize(ExtBuff1,0);
      ArrayInitialize(ExtBuff2,0);
      //---- Setting the indicator limit count         
      limit=Bars;
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   else
     {
      //---- Setting the indicator limit count
      limit=Bars-(prev_calculated-1);
     }

   for(int i=0; i<Bars && !IsStopped(); i++)
     {      
      for(int j=0;j<ArraySize(InsPairs);j++)
        {
         if(StringSubstr(Symbol(),0,3)==InsPairs[j].Name)
            ExtBuff1[i]=InsPairs[j].RTSAvg;
         if(StringSubstr(Symbol(),3,3)==InsPairs[j].Name)
            ExtBuff2[i]=InsPairs[j].RTSAvg;
        }
     }

   if(ShowRTSOnly)
     {
      int MTFxPos=75;
      if(ShowPairGroupOnly)
         MTFxPos=11;

      CreateMTFSign(NULL,MACDPeriod,STOCHPeriod,MTFxPos,2,inpMethod,inpPrice,WindowFind(MyShortName),MyID);
     }

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
      string sObjNameSplit[];

      StringSplit(sparam,StringGetCharacter("_",0),sObjNameSplit);

      if(ArraySize(sObjNameSplit)>3)
        {

         if(sObjNameSplit[3]=="LblTitle")
           {
            ChartSetSymbolPeriod(0,sObjNameSplit[2],0);
            Print("Clicked LblTitle: ",sObjNameSplit[2]);
           }

         ChartRedraw();

        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ShowRTSLabel(SymGroup &InsRTS,int xPos,bool ShowRTSAvg=true,const int lFontSize=8)
  {
   if(ShowRTSAvg)
     {
      CreateColName(MySubWindow,MyID+InsRTS.Name+"RTS",InsRTS.Name+" : "+(string)NormalizeDouble(InsRTS.RTSAvg,0)+"%",InsRTS.RTSColor,xPos+2,0*1,lFontSize);
      CreateColName(MySubWindow,MyID+InsRTS.Name+"PointsAvg",(string)NormalizeDouble(InsRTS.ValueAvg,0),InsRTS.RTSColor,xPos,0*1,lFontSize-1);
     }

   for(int i=0;i<ArraySize(InsRTS.PairRTS);i++)
      ShowSimpleMTFSign(InsRTS,InsRTS.PairRTS[i],xPos,i+2,MySubWindow,MyID+InsRTS.Name,ShowRTSOnly);

//Statistics

   if(InsRTS.Strongest)
      CreateColName(MySubWindow,MyID+"StrongestCurrency","Strongest : "+InsRTS.Name+" ("+(string)NormalizeDouble(InsRTS.RTSAvg,0)+"%)",InsRTS.RTSColor,0,9,lFontSize);
   if(InsRTS.Weakest)
      CreateColName(MySubWindow,MyID+"WeakestCurrency","Weakest : "+InsRTS.Name+" ("+(string)NormalizeDouble(InsRTS.RTSAvg,0)+"%)",InsRTS.RTSColor,0,10,lFontSize);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ShowPairGroupRTS(SymGroup &InsRTS,int xPos,const int lFontSize=8)
  {
   if(StringFind(Symbol(),InsRTS.Name)!=-1)
      CreatePairGroupSignSymbol(MySubWindow,MyID+InsRTS.Name+"PGSign",InsRTS.CurrencyColor,7,xPos,108);

   CreateColName(MySubWindow,MyID+InsRTS.Name+"Currency",InsRTS.Name+" : ",InsRTS.CurrencyColor,3,xPos,lFontSize);
   CreateColName(MySubWindow,MyID+InsRTS.Name+"RTS",DoubleToStr(InsRTS.RTSAvg,2),InsRTS.RTSColor,1,xPos,lFontSize);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ShowAllPairRTS(int Shift=0)
  {

   int xPosShift=1;

   CalculateAllPairs(InsPairs,RZIMAPeriods,inpMethod,inpPrice,Shift);

//Print(__FUNCTION__," : ",(string)ArraySize(InsPairs)," currency calculated.");

   if(ShowPairGroupOnly)
     {
      for(int j=0;j<ArraySize(InsPairs);j++)
         ShowPairGroupRTS(InsPairs[j],j*xPosShift);
     }
   else
     {
      xPosShift=7;

      if(!ShowRTSOnly)
         xPosShift+=2;

      for(int i=0;i<ArraySize(InsPairs);i++)
         ShowRTSLabel(InsPairs[i],i*xPosShift);

     }
  }
//+------------------------------------------------------------------+
