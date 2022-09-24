//+------------------------------------------------------------------+
//|                        Zeng Currency Relative Strength Index.mq4 |
//|                                   Copyright 2016, Rony Nofrianto |
//+------------------------------------------------------------------+
#property copyright   "2016, Rony Nofrianto, Indonesia."
#property link        ""
#property description "Zeng Currency Relative Strength Index"
#property version   "1.03" //Build 010416
#property strict
/*
v1.01
   + Added custom indicator path input parameter
v1.02
   + Added compatibility for currency with postfix
v1.03
   + Added automatic symbol detection
*/

//---- Expiry Date
#define ENABLE_EXPIRATION_DATE false
#define EXPIRATION_DATE D'02.04.2016' //Format (D'dd.mm.yyyy) 
#define ALERT_ON_ERROR false
#define MINIMUM_HISTORY 10

extern bool inpShowAllCurrencyIndex=true; //Tampilkan Index Semua Mata Uang
extern bool inpUseTB=true; //Gunakan Test Break
extern int    inpTBPeriod=10;   //Test Break LookBack
extern int    inpRSIPeriod=14;   //RSI Period
extern int    inpRSIOSLevel=25;   //Level OverSell RSI
extern int    inpRSIOBLevel=75;   //Level OverBuy RSI
extern ENUM_APPLIED_PRICE inpPrice=PRICE_CLOSE;   //Applied Price RSI
extern int     inpMaxBar=100;//Bar Maksimum
extern string inpTBPath="";//Path Indicator Testing Break

const string CustomIndicatorFile=inpTBPath+"TESTING BREAK";
const string MyShortName="Zeng Currency Relative Strength Index";
const string MyID="Rz_ZCRSI";
const int FontSize=6;
int MySubWindow=WindowFind(MyShortName);
const string FontType="Arial";
const color FontColor=clrWhite;
const int xPosShift=1;
const int hDist=14; //Horizontal/Vertical Space
const int vDist=13; //Horizontal/Vertical Space
const int Corner=1;//0=Top Left - 1=Top Right - 2=Bottom Left - 3=Bottom Right

#property indicator_separate_window
#property indicator_buffers 8
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1     50
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT

//Deklarasi Variabel dan Konstan
const string PairGroup[8]={"USD","EUR","GBP","AUD","CAD","JPY","CHF","NZD"};
const color PairGroupColor[8]={clrWhite,clrDarkOrange,clrLimeGreen,clrDodgerBlue,clrYellow,clrRed,clrBrown,clrMagenta};
string sAllSymbols[];
string sRequiredSymbols[28]=
  {
   "AUDCAD","AUDCHF","AUDJPY","AUDNZD","AUDUSD",
   "CADCHF","CADJPY",
   "CHFJPY",
   "EURAUD","EURCAD","EURCHF","EURGBP","EURJPY","EURNZD","EURUSD",
   "GBPAUD","GBPCAD","GBPCHF","GBPJPY","GBPUSD","GBPNZD",
   "NZDCAD","NZDCHF","NZDJPY","NZDUSD",
   "USDCAD","USDCHF","USDJPY"
  };
string sAUD[],sCAD[],sCHF[],sEUR[],sGBP[],sNZD[],sUSD[],sJPY[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct IndicatorSign
  {
   string            name;
   double            value;
   int               sign;
   color             clr;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct SymRTS
  {
   string            Name;
   double            RTS;
   color             Color;
   bool              Default;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct SymGroup
  {
   string            Name;
   SymRTS            PairRTS[];
   double            RTSAvg;
   color             RTSColor;
   color             CurrencyColor;
  };

double ExtBuff1[],ExtBuff2[],ExtBuff3[],ExtBuff4[],ExtBuff5[],ExtBuff6[],ExtBuff7[],ExtBuff8[];
SymGroup InsPairs[];
int LoadedPairs=0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0,ExtBuff1);
   SetIndexBuffer(1,ExtBuff2);
   SetIndexBuffer(2,ExtBuff3);
   SetIndexBuffer(3,ExtBuff4);
   SetIndexBuffer(4,ExtBuff5);
   SetIndexBuffer(5,ExtBuff6);
   SetIndexBuffer(6,ExtBuff7);
   SetIndexBuffer(7,ExtBuff8);

   for(int i=0;i<ArraySize(PairGroup);i++)
     {
      SetIndexDrawBegin(i,0);
      SetIndexLabel(i,PairGroup[i]);

      if(inpShowAllCurrencyIndex)
         SetIndexStyle(i,DRAW_LINE,STYLE_DOT,1,PairGroupColor[i]);
      else
         SetIndexStyle(i,DRAW_NONE);
     }

   HLineCreate(0,"OBLine",WindowFind(MyShortName),inpRSIOBLevel,clrDodgerBlue);
   HLineCreate(0,"OSLine",WindowFind(MyShortName),inpRSIOSLevel,clrRed);

   IndicatorShortName(MyShortName);
   IndicatorDigits(2);

   if(ENABLE_EXPIRATION_DATE && (TimeCurrent()>EXPIRATION_DATE))
     {
      Print(TimeCurrent()," ",EXPIRATION_DATE);
      return(INIT_FAILED);
     }

   CheckAvailableSymbols();

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print(__FUNCTION__,"_UninitReason = ",getUninitReasonText(_UninitReason),"(",reason,")");
   ObjectsDeleteAll(WindowFind(MyShortName));
   EventKillTimer();
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
      ArrayInitialize(ExtBuff3,0);
      ArrayInitialize(ExtBuff4,0);
      ArrayInitialize(ExtBuff5,0);
      ArrayInitialize(ExtBuff6,0);
      ArrayInitialize(ExtBuff7,0);
      ArrayInitialize(ExtBuff8,0);

      //---- Setting the indicator limit count         
      limit=Bars;
     }
   else
     {
      //---- Setting the indicator limit count
      limit=Bars-(prev_calculated-1);
     }

   for(int i=0; i<limit && i<inpMaxBar && !IsStopped(); i++)
     {

      CreateAllPairs(InsPairs,inpPrice,i);

      if(ArraySize(InsPairs)==ArraySize(PairGroup))
        {
         ExtBuff1[i]=InsPairs[0].RTSAvg;
         ExtBuff2[i]=InsPairs[1].RTSAvg;
         ExtBuff3[i]=InsPairs[2].RTSAvg;
         ExtBuff4[i]=InsPairs[3].RTSAvg;
         ExtBuff5[i]=InsPairs[4].RTSAvg;
         ExtBuff6[i]=InsPairs[5].RTSAvg;
         ExtBuff7[i]=InsPairs[6].RTSAvg;
         ExtBuff8[i]=InsPairs[7].RTSAvg;

         if(i==0)
           {
            for(int j=0;j<ArraySize(InsPairs);j++)
              {
               ShowPairGroupRTS(InsPairs[j],j*xPosShift);

               if(StringFind(Symbol(),InsPairs[j].Name)!=-1)
                  SetIndexStyle(j,DRAW_LINE,STYLE_SOLID,3);
              }
           }
        }
     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateMultiIndicator(
                               string cSymbol,
                               int cTimeframe,
                               int shift,
                               int linputPrice
                               )
  {
   IndicatorSign MySign[];
   string mTrend[]; //Indicators count
   double RTS=0;

   ArrayResize(mTrend,1);

   int i;

   mTrend[0]="RSI "+(string)inpRSIPeriod;

   ArrayResize(MySign,ArraySize(mTrend));

   for(i=0; i<ArraySize(mTrend);i++)

     {
      MySign[i].name=mTrend[i];

      //---- RSI
      if(i==0)
        {
         MySign[i].value=iRSI(cSymbol,cTimeframe,inpRSIPeriod,linputPrice,shift);

         if(inpUseTB)
           {
            double iPrice=iClose(cSymbol,cTimeframe,shift);
            double iTB=iCustom(cSymbol,cTimeframe,CustomIndicatorFile,inpTBPeriod,0,shift);

            if((iPrice>iTB && MySign[i].value<50) || (iPrice<iTB && MySign[i].value>50))
               MySign[i].value=100-MySign[i].value;
           }

         RTS=MySign[i].value;
        }

      //Print(MySign[i].name," shift=",shift,": MySign[i].value=",MySign[i].value);

     }

//---- Entry Sign
   for(i=0; i<ArraySize(mTrend);i++)

     {
      if(MySign[i].value>0)
        {
         MySign[i].sign=1;
         MySign[i].clr=GetColor(MySign[i].value,0);
        }
      else if(MySign[i].value<0)
        {
         MySign[i].sign=-1;
         MySign[i].clr=GetColor(MySign[i].value,0);
        }
      else
        {
         MySign[i].sign=0;
         MySign[i].clr=GetColor(MySign[i].value,0);
        }

     }

   return RTS;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetPairRTSIndex(
                    SymRTS &arrAllRTS[],
                    string symbol,
                    string &defaultSymbol
                    )
  {
   int idxPair=EMPTY_VALUE;
   string offPair;

   for(int i=0;i<ArraySize(arrAllRTS);i++)
     {

      offPair=StringSubstr(symbol,3,3)+StringSubstr(symbol,0,3)+StringSubstr(symbol,6);

      //First Pair
      if(StringFind(arrAllRTS[i].Name,symbol,0)==0)
        {
         arrAllRTS[i].Default=true;
         defaultSymbol=symbol;
         idxPair=i;
         break;
        }
      //Second Pair
      else if(StringFind(arrAllRTS[i].Name,offPair)==0)
        {
         arrAllRTS[i].Name=offPair;
         arrAllRTS[i].Default=false;
         defaultSymbol=offPair;
         idxPair=i;
         break;
        }
     }

   return idxPair;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreatePairs(SymGroup &lInsPair,string symName,SymRTS &AllRTS[])
  {
   double RTS=0;
   double dValues=0;

   string aPairs[];

   if(symName=="AUD")
      ArrayCopy(aPairs,sAUD);
   else if(symName=="CAD")
      ArrayCopy(aPairs,sCAD);
   else if(symName=="CHF")
      ArrayCopy(aPairs,sCHF);
   else if(symName=="EUR")
      ArrayCopy(aPairs,sEUR);
   else if(symName=="GBP")
      ArrayCopy(aPairs,sGBP);
   else if(symName=="NZD")
      ArrayCopy(aPairs,sNZD);
   else if(symName=="USD")
      ArrayCopy(aPairs,sUSD);
   else if(symName=="JPY")
      ArrayCopy(aPairs,sJPY);
   else
      return;

   lInsPair.Name=symName;

   ArrayResize(lInsPair.PairRTS,ArraySize(aPairs));

   int idxFound;
   int idxHighest,idxLowest;
   double dHighest= -999;
   double dLowest = 999;
   string lDefaultSymbol;

   for(int i=0;i<ArraySize(lInsPair.PairRTS);i++)
     {
      idxFound=GetPairRTSIndex(AllRTS,aPairs[i],lDefaultSymbol);

      lInsPair.PairRTS[i].Name=aPairs[i];

      if(MarketInfo(lDefaultSymbol,MODE_TRADEALLOWED)==false) continue;

      if(AllRTS[idxFound].Default==true)
         lInsPair.PairRTS[i].RTS=AllRTS[idxFound].RTS;
      else
         lInsPair.PairRTS[i].RTS=100-AllRTS[idxFound].RTS;

      //Recalculating RTS depending on pair reversion
      lInsPair.PairRTS[i].Color=GetColor(lInsPair.PairRTS[i].RTS,0);
      lInsPair.PairRTS[i].Default=AllRTS[idxFound].Default;

      RTS+=lInsPair.PairRTS[i].RTS;

      if(lInsPair.PairRTS[i].RTS>dHighest)
        {
         idxHighest=i;
         dHighest=lInsPair.PairRTS[i].RTS;
        }

      if(lInsPair.PairRTS[i].RTS<dLowest)
        {
         idxLowest=i;
         dLowest=lInsPair.PairRTS[i].RTS;
        }

     }

   lInsPair.PairRTS[idxHighest].Color=clrDodgerBlue;
   lInsPair.PairRTS[idxLowest].Color=clrRed;

//Print(__FUNCTION__," : ",lInsPair.Name," RTS=",RTS," lInsPair.PairRTS=",ArraySize(lInsPair.PairRTS));
   lInsPair.RTSAvg=RTS/ArraySize(lInsPair.PairRTS);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateAllPairs(
                    SymGroup &lInsPairs[],
                    int linputPrice,
                    const int shift=0
                    )
  {
   int i;
   SymRTS AllRTS[];

   ArrayResize(AllRTS,ArraySize(sAllSymbols));

   for(i=0;i<ArraySize(sAllSymbols);i++)
     {
      AllRTS[i].Name=sAllSymbols[i];
      AllRTS[i].RTS=CalculateMultiIndicator(sAllSymbols[i],PERIOD_CURRENT,shift,linputPrice);
     }

   ArrayResize(lInsPairs,ArraySize(PairGroup));
   int idxHighestGrp,idxLowestGrp;
   double dHighest=-999;
   double dLowest=999;

   for(i=0;i<ArraySize(PairGroup);i++)
     {

      CreatePairs(lInsPairs[i],PairGroup[i],AllRTS);

      lInsPairs[i].RTSColor=GetColor(lInsPairs[i].RTSAvg,0);
      lInsPairs[i].CurrencyColor=PairGroupColor[i];

      if(lInsPairs[i].RTSAvg>dHighest)
        {
         dHighest=lInsPairs[i].RTSAvg;
         idxHighestGrp=i;
        }
      if(lInsPairs[i].RTSAvg<dLowest)
        {
         dLowest=lInsPairs[i].RTSAvg;
         idxLowestGrp=i;
        }

     }

   lInsPairs[idxHighestGrp].RTSColor= clrDodgerBlue;
   lInsPairs[idxLowestGrp].RTSColor = clrRed;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateColName(const int iSubWindow,string lblName,string txt,color clr,int xDist,int yDist,int lFontSize)
  {
   ObjectCreate(lblName,OBJ_LABEL,iSubWindow,0,0);
   ObjectSetText(lblName,txt,lFontSize,FontType,clr);
   ObjectSet(lblName,OBJPROP_CORNER,Corner);
   ObjectSet(lblName,OBJPROP_XDISTANCE,xDist*hDist);
   ObjectSet(lblName,OBJPROP_YDISTANCE,yDist*vDist);
   ObjectSet(lblName,OBJPROP_HIDDEN,true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateLabel(const int iSubWindow,string lblText,string lblName,int fontSize,string fontType,color fontColor,int lblCorner,int xDist,int yDist)
  {
   ObjectCreate(lblName,OBJ_LABEL,iSubWindow,0,0);
   ObjectSetText(lblName,lblText,fontSize,fontType,fontColor);
   ObjectSet(lblName,OBJPROP_CORNER,lblCorner);
   ObjectSet(lblName,OBJPROP_XDISTANCE,xDist);
   ObjectSet(lblName,OBJPROP_YDISTANCE,yDist*vDist);
   ObjectSet(lblName,OBJPROP_HIDDEN,true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
color GetColor(double dPositiveVal,double dMediumVal,const double dLowVal=NULL,const double dHighVal=NULL,
               int compType=0 //0 : Default Comparison, 1 : Reverse Comparison, 2 : Exact Comparison
               )
  {
   color clrHigher= clrLawnGreen;
   color clrLower = clrDarkOrange;
   color clrHighest= clrDodgerBlue;
   color clrLowest = clrRed;

   if(compType==1)
     {
      clrHigher= clrDarkOrange;
      clrLower = clrLawnGreen;
      clrHighest= clrRed;
      clrLowest = clrDodgerBlue;
     }

   if(compType!=2)
     {
      if(dHighVal!=NULL && dLowVal!=NULL)
        {
         if(dPositiveVal>dHighVal)
            return clrHighest;
         else if(dPositiveVal<dLowVal)
            return clrLowest;
        }

      if(dPositiveVal>dMediumVal)
         return clrHigher;
      else if(dPositiveVal<dMediumVal)
         return clrLower;

      return clrWhite;
     }

   else
     {
      if(dPositiveVal==dHighVal)
         return clrHigher;
      else if(dPositiveVal==dLowVal)
         return clrLower;

      return clrWhite;

     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getUninitReasonText(int reasonCode)
  {
   string text="";
//---
   switch(reasonCode)
     {
      case REASON_ACCOUNT:
         text="Account was changed";break;
      case REASON_CHARTCHANGE:
         text="Symbol or timeframe was changed";break;
      case REASON_CHARTCLOSE:
         text="Chart was closed";break;
      case REASON_PARAMETERS:
         text="Input-parameter was changed";break;
      case REASON_RECOMPILE:
         text="Program "+__FILE__+" was recompiled";break;
      case REASON_REMOVE:
         text="Program "+__FILE__+" was removed from chart";break;
      case REASON_TEMPLATE:
         text="New template was applied to chart";break;
      default:text="Another reason";
     }
//---
   return text;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ShowPairGroupRTS(SymGroup &InsRTS,int xPos,const int lFontSize=8)
  {

   if(StringFind(Symbol(),InsRTS.Name)!=-1)
      CreateMTFSignSymbol(MySubWindow,MyID+InsRTS.Name+"Sign",InsRTS.CurrencyColor,6,xPos,108);

   CreateColName(MySubWindow,MyID+InsRTS.Name+"Currency",InsRTS.Name+" : ",InsRTS.CurrencyColor,3,xPos,lFontSize);
   CreateColName(MySubWindow,MyID+InsRTS.Name+"RTS",DoubleToStr(InsRTS.RTSAvg,2),InsRTS.RTSColor,1,xPos,lFontSize);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//SignChar : 108 Circle, 110 Rectangle
void CreateMTFSignSymbol(const int iSubWindow,string lblName,color clr,int xDist,int yDist,const uchar SignChar=110,const int SignSize=8)
  {
   ObjectCreate(lblName,OBJ_LABEL,iSubWindow,0,0);
   ObjectSetText(lblName,CharToStr(SignChar),SignSize,"Wingdings",clr);
   ObjectSet(lblName,OBJPROP_CORNER,Corner);
   ObjectSet(lblName,OBJPROP_XDISTANCE,xDist*hDist);
   ObjectSet(lblName,OBJPROP_YDISTANCE,yDist*vDist);
   ObjectSet(lblName,OBJPROP_HIDDEN,true);
  }
//+------------------------------------------------------------------+
//| Convert to symbol with postfix                                   |
//+------------------------------------------------------------------+
void ConvertSymbols(string &Pairs[],string PostFix)
  {
   Print("Converting ",ArraySize(Pairs)," Pairs with Postfix ",PostFix," .");
   for(int i=0;i<ArraySize(Pairs);i++)
     {
      Pairs[i]+=PostFix;
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
                 const ENUM_LINE_STYLE style=STYLE_DOT,// line style
                 const int             width=1,// line width
                 const bool            back=true,// in the background
                 const bool            selection=false,// highlight to move
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

void CheckAvailableSymbols()
  {
   int j=0;

   ConvertSymbols(sRequiredSymbols,StringSubstr(Symbol(),6));

   for(int i=0;i<ArraySize(sRequiredSymbols);i++)
     {
      bool SymbolAvailable=SymbolSelect(sRequiredSymbols[i],true);
      if(SymbolAvailable)
        {
         j++;
         ArrayResize(sAllSymbols,j);
         sAllSymbols[j-1]=sRequiredSymbols[i];
        }
     }

   int jAUD,jCAD,jCHF,jEUR,jGBP,jNZD,jUSD,jJPY;
   jAUD=jCAD=jCHF=jEUR=jGBP=jNZD=jUSD=jJPY=0;

   for(int i=0;i<ArraySize(sAllSymbols);i++)
     {
      string offPair=StringSubstr(sAllSymbols[i],3,3)+StringSubstr(sAllSymbols[i],0,3)+StringSubstr(sAllSymbols[i],6);

      if(StringFind(sAllSymbols[i],"AUD")!=-1)
        {
         jAUD++;
         ArrayResize(sAUD,jAUD);
         if(StringFind(sAllSymbols[i],"AUD")==0)
            sAUD[jAUD-1]=sAllSymbols[i];
         else if(StringFind(offPair,"AUD")==0)
            sAUD[jAUD-1]=offPair;
        }
      if(StringFind(sAllSymbols[i],"CAD")!=-1)
        {
         jCAD++;
         ArrayResize(sCAD,jCAD);
         if(StringFind(sAllSymbols[i],"CAD")==0)
            sCAD[jCAD-1]=sAllSymbols[i];
         else if(StringFind(offPair,"CAD")==0)
            sCAD[jCAD-1]=offPair;
        }
      if(StringFind(sAllSymbols[i],"CHF")!=-1)
        {
         jCHF++;
         ArrayResize(sCHF,jCHF);
         if(StringFind(sAllSymbols[i],"CHF")==0)
            sCHF[jCHF-1]=sAllSymbols[i];
         else if(StringFind(offPair,"CHF")==0)
            sCHF[jCHF-1]=offPair;
        }
      if(StringFind(sAllSymbols[i],"EUR")!=-1)
        {
         jEUR++;
         ArrayResize(sEUR,jEUR);
         if(StringFind(sAllSymbols[i],"EUR")==0)
            sEUR[jEUR-1]=sAllSymbols[i];
         else if(StringFind(offPair,"EUR")==0)
            sEUR[jEUR-1]=offPair;
        }
      if(StringFind(sAllSymbols[i],"GBP")!=-1)
        {
         jGBP++;
         ArrayResize(sGBP,jGBP);
         if(StringFind(sAllSymbols[i],"GBP")==0)
            sGBP[jGBP-1]=sAllSymbols[i];
         else if(StringFind(offPair,"GBP")==0)
            sGBP[jGBP-1]=offPair;
        }
      if(StringFind(sAllSymbols[i],"NZD")!=-1)
        {
         jNZD++;
         ArrayResize(sNZD,jNZD);
         if(StringFind(sAllSymbols[i],"NZD")==0)
            sNZD[jNZD-1]=sAllSymbols[i];
         else if(StringFind(offPair,"NZD")==0)
            sNZD[jNZD-1]=offPair;
        }
      if(StringFind(sAllSymbols[i],"USD")!=-1)
        {
         jUSD++;
         ArrayResize(sUSD,jUSD);
         if(StringFind(sAllSymbols[i],"USD")==0)
            sUSD[jUSD-1]=sAllSymbols[i];
         else if(StringFind(offPair,"USD")==0)
            sUSD[jUSD-1]=offPair;
        }
      if(StringFind(sAllSymbols[i],"JPY")!=-1)
        {
         jJPY++;
         ArrayResize(sJPY,jJPY);
         if(StringFind(sAllSymbols[i],"JPY")==0)
            sJPY[jJPY-1]=sAllSymbols[i];
         else if(StringFind(offPair,"JPY")==0)
            sJPY[jJPY-1]=offPair;
        }
     }

   Print("Loaded Symbols=",ArraySize(sAllSymbols),
         " AUD=",ArraySize(sAUD),
         " CAD=",ArraySize(sCAD),
         " CHF=",ArraySize(sCHF),
         " EUR=",ArraySize(sEUR),
         " GBP=",ArraySize(sGBP),
         " NZD=",ArraySize(sNZD),
         " USD=",ArraySize(sUSD),
         " JPY=",ArraySize(sJPY)
         );

  }
//+------------------------------------------------------------------+
