//+-------------------------------------------------+
//| RoNz OHCL Indicator.mq4 v1.0 (15.01.25) by RoNz |
//+-------------------------------------------------+
#property copyright   "2015, Rony Nofrianto, Indonesia."
#property link        "https://www.mql5.com/en/users/ronz"
#property description "Show OHCL for Selected Timeframe"
#property version   "1.0"
#property strict

#property indicator_chart_window

const string FontType="Arial";
const int FontSize=8;

const string Days[7]={"SUN","MON","TUE","WED","THU","FRI","SAT"};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum EN_PRICE_MODE
  {
   PM_None=0,//None
   PM_LowHigh=1,//Low High
   PM_OpenCLose=2 //Open Close
  };

//---- Indicator Buffers
double ExtUpperStopBuffer[],ExtLowerStopBuffer[],ExtMiddleStopBuffer[];

//----  Indicator Inputs
extern ENUM_TIMEFRAMES inpHigherPeriod=PERIOD_W1;//Higher Timeframe
extern EN_PRICE_MODE inpPrice=PM_OpenCLose;//Price Mode
extern bool inpUseAutoShift=false;//Use Auto Shift
extern bool inpShowPriceLine=true;//Show Price Line
extern bool inpShowHLine=true;//Show Horizontal Line
extern color inpHLineColor=clrGreenYellow;//Middle HLine Color
extern bool inpShowDayLabel=true;//Show Day Label

int inpStopPointShift=0;//Shift
//----
string MyShortName="RoNz OHCL";

#property indicator_buffers 3

//High/Close
#property indicator_color1 clrBlue
#property  indicator_type1 DRAW_LINE
#property  indicator_style1 STYLE_DOT
//Low/Open
#property indicator_color2 clrRed
#property  indicator_type2 DRAW_LINE
#property  indicator_style2 STYLE_DOT
//Middle
#property indicator_color3 clrWhite
#property  indicator_type3 DRAW_LINE
#property  indicator_style3 STYLE_DOT
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   MyShortName=MyShortName;

   HLineDelete(0,"HLineMidPoint");

   if(inpUseAutoShift)
      inpStopPointShift=inpHigherPeriod/Period();
   else
      inpStopPointShift=0;

   ChartSetInteger(0,CHART_SHIFT,true);
   ChartSetInteger(0,CHART_SHOW_ASK_LINE,true);
   ChartSetInteger(0,CHART_SHOW_PERIOD_SEP,true);

//ObjectsDeleteAll(WindowFind(MyShortName));
//----   
   IndicatorShortName(MyShortName);
   IndicatorDigits(Digits());
   IndicatorBuffers(3);

   SetIndexBuffer(0,ExtUpperStopBuffer);
   SetIndexShift(0,inpStopPointShift);
   SetIndexDrawBegin(0,inpStopPointShift); // Upper/Close Point

   SetIndexBuffer(1,ExtLowerStopBuffer);
   SetIndexShift(1,inpStopPointShift);
   SetIndexDrawBegin(1,inpStopPointShift); // Lower/Open Point

   SetIndexBuffer(2,ExtMiddleStopBuffer);
   SetIndexShift(2,inpStopPointShift);
   SetIndexDrawBegin(2,inpStopPointShift); // Middle Point   

   if(inpPrice==PM_OpenCLose)
     {
      SetIndexLabel(0,"Close Price");
      SetIndexLabel(1,"Open Price");
      SetIndexLabel(2,"Open to Close Middle Price");
     }
   else
     {
      SetIndexLabel(0,"High Price");
      SetIndexLabel(1,"Low Price");
      SetIndexLabel(2,"Low to High Middle Price");
     }

//---- Invisible Value
   for(int i=0; i<3; i++)
     {
      SetIndexEmptyValue(i,0);

      if(!inpShowPriceLine)
         SetIndexStyle(i,DRAW_NONE);
     }

//--- initialization done
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(IsTesting()) return;

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

//---- Return if no data was calculated before
   if(prev_calculated<0) return(-1);

   int limit;

//---- Calculating Entry Sign and Stop Point Indicator
   if(prev_calculated==0)
      limit=rates_total;
   else
      limit=rates_total;//-(prev_calculated-1);

//---- Calculating entry, Stop Point, and Support/Resistance indicator
   for(int i=0; i<limit && !IsStopped(); i++)
     {
      Draw_PriceStopIndicator(i,time[i]);

      if(TimeToString(time[i],TIME_MINUTES)=="00:00")
         CreateDayLabel("Day"+(string)i,time[i],ExtLowerStopBuffer[i],Days[TimeDayOfWeek(time[i])]);
     }

   if(inpShowHLine)
     {
      if(!HLineCreate(0,"HLineMidPoint",0,ExtMiddleStopBuffer[inpStopPointShift],inpHLineColor))
        {
         HLineMove(0,"HLineMidPoint",ExtMiddleStopBuffer[inpStopPointShift]);
        }
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
   if(inpShowDayLabel)
     {
      ObjectCreate(lblName,OBJ_TEXT,0,time,price);
      ObjectSetText(lblName,lblText,FontSize-3,FontType,clrGray);
      ObjectSetInteger(0,lblName,OBJPROP_SELECTABLE,false);
     }
   return true;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Draw_PriceStopIndicator(int i,datetime dtTime)
  {
//---- Setting Upper/Lower or Open/Close Points
   int UpperPeriod=inpHigherPeriod;

   int shift=iBarShift(NULL,UpperPeriod,dtTime);

   if(inpPrice==PM_LowHigh)
     {
      ExtUpperStopBuffer[i]=iHigh(NULL,UpperPeriod, shift);
      ExtLowerStopBuffer[i]=iLow(NULL,UpperPeriod, shift);
      ExtMiddleStopBuffer[i]=ExtLowerStopBuffer[i]+((ExtUpperStopBuffer[i]-ExtLowerStopBuffer[i])/2);
     }
   if(inpPrice==PM_OpenCLose)
     {
      ExtUpperStopBuffer[i]=iClose(NULL,UpperPeriod, shift);
      ExtLowerStopBuffer[i]=iOpen(NULL,UpperPeriod, shift);

      double pHigh=ExtUpperStopBuffer[i];
      double pLow=ExtLowerStopBuffer[i];

      if(pLow>pHigh)
        {
         pHigh=ExtLowerStopBuffer[i];
         pLow=ExtUpperStopBuffer[i];
        }

      ExtMiddleStopBuffer[i]=ExtLowerStopBuffer[i]+((ExtUpperStopBuffer[i]-ExtLowerStopBuffer[i])/2);
     }

  }
//+------------------------------------------------------------------+
//| Create the horizontal line                                       |
//+------------------------------------------------------------------+
bool HLineCreate(const long            chart_ID=0,        // chart's ID
                 const string          name="HLine",      // line name
                 const int             sub_window=0,      // subwindow index
                 double                price=0,           // line price
                 const color           clr=clrRed,        // line color
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style
                 const int             width=1,           // line width
                 const bool            back=false,        // in the background
                 const bool            selection=true,    // highlight to move
                 const bool            hidden=true,       // hidden in the object list
                 const long            z_order=0)         // priority for mouse click
  {
//--- if the price is not set, set it at the current Bid price level
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value
   ResetLastError();
//--- create a horizontal line
   if(!ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price))
     {
      //Print(__FUNCTION__,
      //": failed to create a horizontal line! Error code = ",GetLastError());
      return(false);
     }
//--- set line color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set line display style
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set line width
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the line by mouse
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Move horizontal line                                             |
//+------------------------------------------------------------------+
bool HLineMove(const long   chart_ID=0,   // chart's ID
               const string name="HLine", // line name
               double       price=0)      // line price
  {
//--- if the line price is not set, move it to the current Bid price level
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value
   ResetLastError();
//--- move a horizontal line
   if(!ObjectMove(chart_ID,name,0,0,price))
     {
      Print(__FUNCTION__,
            ": failed to move the horizontal line! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Delete a horizontal line                                         |
//+------------------------------------------------------------------+
bool HLineDelete(const long   chart_ID=0,   // chart's ID
                 const string name="HLine") // line name
  {
//--- reset the error value
   ResetLastError();
//--- delete a horizontal line
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": failed to delete a horizontal line! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+