//+------------------------------------------------------------------+
//|                                     RoNz Indicator Functions.mqh |
//|                                    Copyright 2012-2016, FeeLCoMz |
//+------------------------------------------------------------------+
#include <stdlib.mqh>

//Font Setting
const int FontSize=5;
const string FontType="Arial";
const color FontColor=clrWhite;

//Label Space
const int hDist=14; //Horizontal
const int vDist=13; //Vertical Space
const int MTFhDist=11; //MultiTimeframe Horizontal
const int MTFvDist=10; //MultiTimeframe Vertical
const int Corner=1; //0=Top Left - 1=Top Right - 2=Bottom Left - 3=Bottom Right

                    //Multi MA Factor
const int MultiMAFactor[]={1,2,4,6,8,10,14,20,30,40};

//TimeFrames Init
string tfName[]={"M1","5","15","30","H1","H4","D","W"};
int timeframe[]={1,5,15,30,PERIOD_H1,PERIOD_H4,PERIOD_D1,PERIOD_W1};

//Days Init
//const string Days[7]={"Minggu","Senin","Selasa","Rabu","Kamis","Jum'at","Sabtu"};
//const string sSessionZone[4]={"London","New York","Sydney","Tokyo"};
const string Days[7]={"SUN","MON","TUE","WED","THU","FRI","SAT"};
const string sSessionZone[4]={"LON","NY","SYD","JPN"};

//Symbols Init
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
const string PairGroup[8]={"USD","EUR","GBP","AUD","CAD","JPY","CHF","NZD"};
const color PairGroupColor[8]={clrWhite,clrDarkOrange,clrLimeGreen,clrDodgerBlue,clrYellow,clrRed,clrBrown,clrMagenta};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum EN_STD_TIMEFRAMES
  {
   DEFAULT=0,M1=1,M5=5,M15=15,M30=30,H1=60,H4=240,D1=PERIOD_D1,W1=PERIOD_W1,MN1=PERIOD_MN1
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct SymRTS
  {
   string            Name;
   double            UpRTS;
   double            DownRTS;
   double            RTS;
   color             Color;
   bool              Default;
   int               Value;
   double            Spread;
   double            Price;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct SymGroup
  {
   string            Name;
   SymRTS            PairRTS[];
   double            RTSAvg;
   color             Color;
   double            ValueAvg;
   bool              Strongest;
   bool              Weakest;
  };
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
struct MultiTimeframeSign
  {
   string            name;
   int               period;
   IndicatorSign     indSign[];
   double            UpPercentage;
   double            DownPercentage;
   double            FlatPercentage;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateMultiIndicator(
                               string cSymbol,
                               int cTimeframe,
                               string lMACDPeriod,
                               string lSTOCHPeriod,
                               int shift,
                               //double &trendPercentages[],
                               MultiTimeframeSign &MyMultiSign,
                               IndicatorSign &MySign[],
                               int linputMethod,
                               int linputPrice
                               )
  {
   string mTrend[]; //Indicators count

   int dLBuy=0;
   int dLSell=0;
   double RTS=0;
   double symPoint=MarketInfo(cSymbol,MODE_POINT);
   int lUpperPeriods[],lMAPeriod[];

   CalculateMAPeriods(cTimeframe,lUpperPeriods,lMAPeriod);

   string MACDPeriods[],StochPeriods[];
   StringSplit(lMACDPeriod,StringGetCharacter(",",0),MACDPeriods);
   StringSplit(lSTOCHPeriod,StringGetCharacter(",",0),StochPeriods);

   ArrayResize(mTrend,ArraySize(lMAPeriod)+5);

   int i;

   for(i=0;i<ArraySize(lMAPeriod);i++)
      mTrend[i]="MA "+(string)lMAPeriod[i];

   mTrend[4]="MACD";//+(string)lMACDPeriod;
   mTrend[5] = "ADX "+(string)lMAPeriod[1];
   mTrend[6] = "AO";
   mTrend[7]="STO";//+(string)lSTOCHPeriod;
   mTrend[8]= "RSI "+(string)lMAPeriod[0];

   ArrayResize(MySign,ArraySize(mTrend));

   for(i=0; i<ArraySize(mTrend);i++)

     {
      double appPrice=iClose(cSymbol,cTimeframe,shift);
      MySign[i].name=mTrend[i];

      //---- MA
      if(i<ArraySize(lMAPeriod))
        {

         if(i>0) appPrice=iMA(cSymbol,cTimeframe,(int)lMAPeriod[i-1],0,linputMethod,linputPrice,shift);
         MySign[i].value=appPrice-iMA(cSymbol,cTimeframe,(int)lMAPeriod[i],0,linputMethod,linputPrice,shift);
         MySign[i].value=NormalizeDouble(MySign[i].value/symPoint,0);
        }

      //---- MACD      
      if(i==ArraySize(lMAPeriod))
        {
         MySign[i].value=iMACD(cSymbol,cTimeframe,(int)MACDPeriods[0],(int)MACDPeriods[1],(int)MACDPeriods[0],linputPrice,MODE_MAIN,shift);//-iMACD(cSymbol,cTimeframe,12,26,9,inpPrice,MODE_SIGNAL,shift);
         MySign[i].value=NormalizeDouble(MySign[i].value/symPoint,0);
        }

      //---- ADX
      if(i==ArraySize(lMAPeriod)+1)
        {
         MySign[i].value=iADX(cSymbol,cTimeframe,lMAPeriod[1],linputPrice,MODE_PLUSDI,shift)-iADX(cSymbol,cTimeframe,lMAPeriod[1],linputPrice,MODE_MINUSDI,shift);
         MySign[i].value=NormalizeDouble(MySign[i].value,2);
        }

      //---- AO
      if(i==ArraySize(lMAPeriod)+2)
        {
         MySign[i].value=iAO(cSymbol,cTimeframe,shift)-iAO(cSymbol,cTimeframe,shift+1);
         MySign[i].value=NormalizeDouble(MySign[i].value/symPoint,0);
        }

      //---- Stochastic
      if(i==ArraySize(lMAPeriod)+3)
        {
         MySign[i].value=iStochastic(cSymbol,cTimeframe,(int)StochPeriods[0],(int)StochPeriods[1],(int)StochPeriods[2],linputMethod,0,MODE_MAIN,shift)-iStochastic(cSymbol,cTimeframe,5,3,3,MODE_SMA,0,MODE_SIGNAL,shift);
         MySign[i].value=NormalizeDouble(MySign[i].value,0);
        }
      //---- RSI
      if(i==ArraySize(lMAPeriod)+4)
        {
         MySign[i].value=iRSI(cSymbol,cTimeframe,lMAPeriod[1],linputPrice,shift);//-iRSI(cSymbol,cTimeframe,lMAPeriod[1],linputPrice,shift+1);
         MySign[i].value=NormalizeDouble(MySign[i].value,2);

         if(MySign[i].value>50)
            MySign[i].value=MySign[i].value;
         else if(MySign[i].value<50)
            MySign[i].value=-(MySign[i].value);

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
         dLBuy++;
        }
      else if(MySign[i].value<0)
        {
         MySign[i].sign=-1;
         MySign[i].clr=GetColor(MySign[i].value,0);
         dLSell++;
        }
      else
        {
         MySign[i].sign=0;
         MySign[i].clr=GetColor(MySign[i].value,0);
        }

     }

//---- Calculating entry percentage based on MA Indicator
   double indSignSize=ArraySize(mTrend);
   double dBuyPos = (dLBuy/indSignSize) * 100;
   double dSellPos= (dLSell/indSignSize)*100;
   double dNeutralPos=100 -(dBuyPos+dSellPos);

   if(dBuyPos==100)
     {
      for(i=0;i<ArraySize(MySign);i++)
        {
         MySign[i].clr=clrBlue;
        }
     }
   else   if(dSellPos==100)
     {
      for(i=0;i<ArraySize(MySign);i++)
        {
         MySign[i].clr=clrRed;
        }
     }

//Print(__FUNCTION__," : cTimeframe=", cTimeframe," dBuyPos=",dBuyPos," dSellPos=",dSellPos, " RTS=", RTS, " indSignSize=", indSignSize);

   MyMultiSign.DownPercentage=dSellPos;
   MyMultiSign.UpPercentage=dBuyPos;
   MyMultiSign.FlatPercentage=dNeutralPos;

   RTS=dBuyPos-dSellPos;

   return RTS;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateMultiMAIndicator(
                                 string cSymbol,
                                 int cTimeframe,
                                 string lsMAPeriod,
                                 int shift,
                                 MultiTimeframeSign &MyMultiSign,
                                 IndicatorSign &MySign[],
                                 int linputMethod,
                                 int linputPrice
                                 )
  {
   string mTrend[]; //Indicators count

   int dLBuy=0;
   int dLSell=0;
   double RTS=0;
   double symPoint=MarketInfo(cSymbol,MODE_POINT);

   string lMAPeriod[];

   StringSplit(lsMAPeriod,StringGetCharacter(",",0),lMAPeriod);
//Print(__FUNCTION__,": lsMAPeriod=",lsMAPeriod, " lMAPeriod=",lMAPeriod[0]);

   ArrayResize(mTrend,ArraySize(lMAPeriod));
   int i;

   for(i=0;i<ArraySize(lMAPeriod);i++)
      mTrend[i]="MA "+(string)lMAPeriod[i];

   ArrayResize(MySign,ArraySize(mTrend));

   for(i=0; i<ArraySize(mTrend);i++)

     {
      double appPrice=iClose(cSymbol,cTimeframe,shift);
      MySign[i].name=mTrend[i];

      //---- MA
      if(i<ArraySize(lMAPeriod))
        {

         if(i>0) appPrice=iMA(cSymbol,cTimeframe,(int)lMAPeriod[i-1],0,linputMethod,linputPrice,shift);
         MySign[i].value=appPrice-iMA(cSymbol,cTimeframe,(int)lMAPeriod[i],0,linputMethod,linputPrice,shift);
         MySign[i].value=NormalizeDouble(MySign[i].value/symPoint,0);
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
         dLBuy++;
        }
      else if(MySign[i].value<0)
        {
         MySign[i].sign=-1;
         MySign[i].clr=GetColor(MySign[i].value,0);
         dLSell++;
        }
      else
        {
         MySign[i].sign=0;
         MySign[i].clr=GetColor(MySign[i].value,0);
        }

     }

//---- Calculating entry percentage based on MA Indicator
   double indSignSize=ArraySize(mTrend);
   double dBuyPos = (dLBuy/indSignSize) * 100;
   double dSellPos= (dLSell/indSignSize)*100;
   double dNeutralPos=100 -(dBuyPos+dSellPos);

   if(dBuyPos==100)
     {
      for(i=0;i<ArraySize(MySign);i++)
        {
         MySign[i].clr=clrBlue;
        }
     }
   else   if(dSellPos==100)
     {
      for(i=0;i<ArraySize(MySign);i++)
        {
         MySign[i].clr=clrRed;
        }
     }

//Print(__FUNCTION__," : cTimeframe=", cTimeframe," dBuyPos=",dBuyPos," dSellPos=",dSellPos, " RTS=", RTS, " indSignSize=", indSignSize);

   MyMultiSign.DownPercentage=dSellPos;
   MyMultiSign.UpPercentage=dBuyPos;
   MyMultiSign.FlatPercentage=dNeutralPos;

   RTS=dBuyPos-dSellPos;

   return RTS;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateMultiTimeIndicator(
                                   string cSymbol,
                                   datetime time,
                                   string lMACDPeriod,
                                   string lSTOCHPeriod,
                                   double &trendPercentages[],
                                   MultiTimeframeSign &MyMultiSign[],
                                   int linputMethod,
                                   int linputPrice,
                                   bool UseCustomMA=false,
                                   string lsMAPeriod=""
                                   )
  {
   double RTS=0;
   double buySign=0;
   double sellSign=0;
   double tfPercentage[3];
//   MultiTimeframeSign MyMultiSign[];

   ArrayResize(trendPercentages,3);
   ArrayResize(MyMultiSign,ArraySize(timeframe));

   for(int i=0;i<ArraySize(timeframe);i++)
     {
      int shift=iBarShift(cSymbol,timeframe[i],time);

      if(UseCustomMA)
         CalculateMultiMAIndicator(cSymbol,timeframe[i],lsMAPeriod,shift,MyMultiSign[i],MyMultiSign[i].indSign,linputMethod,linputPrice);
      else
         CalculateMultiIndicator(cSymbol,timeframe[i],lMACDPeriod,lSTOCHPeriod,shift,MyMultiSign[i],MyMultiSign[i].indSign,linputMethod,linputPrice);

      MyMultiSign[i].name=tfName[i];
      MyMultiSign[i].period=timeframe[i];
      sellSign+=MyMultiSign[i].DownPercentage;
      buySign+=MyMultiSign[i].UpPercentage;
      //Print(__FUNCTION__," : timeframe[i]=",timeframe[i]," periodRTS+=",periodRTS," buySign+=",buySign, " sellSign+=", sellSign," tfPercentage[1]=", tfPercentage[1], " tfPercentage[0]=", tfPercentage[0]);      
     }

//---- Calculating entry percentage based on MA Indicator
   double indSignSize=ArraySize(timeframe)*100;
   double dBuyPos = (buySign/indSignSize) * 100;
   double dSellPos= (sellSign/indSignSize)*100;
   double dNeutralPos=100 -(dBuyPos+dSellPos);

//Print(__FUNCTION__," : dBuyPos=",dBuyPos," dSellPos=",dSellPos, " dNeutralPos=", dNeutralPos," periodRTS=", periodRTS, " indSignSize=", indSignSize);

   RTS=dBuyPos-dSellPos;

   trendPercentages[0] = dSellPos;
   trendPercentages[1] = dBuyPos;
   trendPercentages[2] = dNeutralPos;

   return RTS;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateMTFSign(
                   string symbol,
                   string lMACDPeriod,
                   string lSTOCHPeriod,
                   int xPos,
                   int yPos,
                   int linputMethod,
                   int linputPrice,
                   const int iSubWindow=0,
                   const string MyIDPrefix="",
                   const bool lShowRTSOnly= true,
                   const bool lShowSymbol=true,
                   const int cFontSize=5
                   )
  {
   int j;
   double percentage[2],tfPercentage[2];

   MultiTimeframeSign multiSign[];
   IndicatorSign indSign[];

   string IDPrefix;

   if(MyIDPrefix!="")
      IDPrefix=MyIDPrefix+"_"+symbol+"_";
   else
      IDPrefix="RTS_";

   if(symbol==NULL) symbol=Symbol();

//---- Current Indicator Data
   double RTS=CalculateMultiTimeIndicator(symbol,TimeCurrent(),lMACDPeriod,lSTOCHPeriod,tfPercentage,multiSign,linputMethod,linputPrice);

   double spread=MarketInfo(symbol,MODE_SPREAD);
   color clrSpread=GetColor(spread,20,16,30,1);

   if(lShowSymbol)
      CreateMTFColName(iSubWindow,IDPrefix+"LblTitle",symbol,clrYellow,xPos+ArraySize(multiSign),yPos,cFontSize+2);

   CreateMTFColName(iSubWindow,IDPrefix+"Lbl_RTS","RTS : "+(string)NormalizeDouble(RTS,0)+"%",GetColor(RTS,0),xPos,yPos,cFontSize+2);
   CreateMTFColName(iSubWindow,IDPrefix+"Lbl_Spread","Spread : "+(string)spread,clrSpread,xPos,yPos+1,cFontSize+2);

   int idxVal=0;
//---- Multi timeframe column label   
   for(int k=0;k<ArraySize(multiSign);k++)
     {
      color clrCurPeriod=clrWhite;

      if(multiSign[k].period==Period())
        {
         clrCurPeriod=clrLime;
         idxVal=k;
        }

      CreateMTFColName(iSubWindow,IDPrefix+"LblCol_"+(string)multiSign[k].name,multiSign[k].name,clrCurPeriod,xPos-1+ArraySize(multiSign)-k,yPos+3,cFontSize);
      //---- Multi Indicator sign
      for(j=0; j<ArraySize(multiSign[k].indSign);j++)
         CreateMTFSignSymbol(iSubWindow,IDPrefix+"Lbl_"+multiSign[k].name+"_"+multiSign[k].indSign[j].name,multiSign[k].indSign[j].clr,xPos-1+ArraySize(multiSign)-k,yPos+4+j);
     }
//---- Multi indicator row label

   for(j=0; j<ArraySize(multiSign[idxVal].indSign);j++)
     {
      CreateMTFColName(iSubWindow,IDPrefix+"Lbl_Ind"+(string)j,multiSign[idxVal].indSign[j].name,clrWhite,xPos+ArraySize(multiSign),yPos+4+j,cFontSize);
      CreateMTFColName(iSubWindow,IDPrefix+"Lbl_IndVal"+(string)j,(string)multiSign[idxVal].indSign[j].value,multiSign[idxVal].indSign[j].clr,xPos+3+ArraySize(multiSign),yPos+4+j,cFontSize);
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateMTFMASign(
                     string symbol,
                     string lsMAPeriod,
                     int xPos,
                     int yPos,
                     int linputMethod,
                     int linputPrice,
                     const int iSubWindow=0,
                     const string MyIDPrefix="",
                     const bool lShowRTSOnly= true,
                     const bool lShowSymbol=true,
                     const int cFontSize=5
                     )
  {
   int j;
   double percentage[2],tfPercentage[2];

   MultiTimeframeSign multiSign[];
   IndicatorSign indSign[];

   string IDPrefix;

   if(MyIDPrefix!="")
      IDPrefix=MyIDPrefix+"_"+symbol+"_";
   else
      IDPrefix="RTS_";

   if(symbol==NULL) symbol=Symbol();

//---- Current Indicator Data
   double RTS=CalculateMultiTimeIndicator(symbol,TimeCurrent(),"12,26,9","8,3,3",tfPercentage,multiSign,linputMethod,linputPrice,true,lsMAPeriod);

   double spread=MarketInfo(symbol,MODE_SPREAD);
   color clrSpread=GetColor(spread,20,16,30,1);

   if(lShowSymbol)
      CreateMTFColName(iSubWindow,IDPrefix+"LblTitle",symbol,clrYellow,xPos+ArraySize(multiSign),yPos,cFontSize+2);

   CreateMTFColName(iSubWindow,IDPrefix+"Lbl_RTS","RTS : "+(string)NormalizeDouble(RTS,0)+"%",GetColor(RTS,0),xPos,yPos,cFontSize+2);
   CreateMTFColName(iSubWindow,IDPrefix+"Lbl_Spread","Spread : "+(string)spread,clrSpread,xPos,yPos+1,cFontSize+2);

   int idxVal=0;
//---- Multi timeframe column label   
   for(int k=0;k<ArraySize(multiSign);k++)
     {
      color clrCurPeriod=clrWhite;

      if(multiSign[k].period==Period())
        {
         clrCurPeriod=clrLime;
         idxVal=k;
        }

      CreateMTFColName(iSubWindow,IDPrefix+"LblCol_"+(string)multiSign[k].name,multiSign[k].name,clrCurPeriod,xPos-1+ArraySize(multiSign)-k,yPos+3,cFontSize);
      //---- Multi Indicator sign
      for(j=0; j<ArraySize(multiSign[k].indSign);j++)
         CreateMTFSignSymbol(iSubWindow,IDPrefix+"Lbl_"+multiSign[k].name+"_"+multiSign[k].indSign[j].name,multiSign[k].indSign[j].clr,xPos-1+ArraySize(multiSign)-k,yPos+4+j);
     }
//---- Multi indicator row label

   for(j=0; j<ArraySize(multiSign[idxVal].indSign);j++)
     {
      CreateMTFColName(iSubWindow,IDPrefix+"Lbl_Ind"+(string)j,multiSign[idxVal].indSign[j].name,clrWhite,xPos+ArraySize(multiSign),yPos+4+j,cFontSize);
      CreateMTFColName(iSubWindow,IDPrefix+"Lbl_IndVal"+(string)j,(string)multiSign[idxVal].indSign[j].value,multiSign[idxVal].indSign[j].clr,xPos+3+ArraySize(multiSign),yPos+4+j,cFontSize);
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateMTFSimpleSign(
                         string symbol,
                         bool contrapair,
                         int &lMAPeriod[],
                         string lMACDPeriod,
                         string lSTOCHPeriod,
                         int lADXPeriod,
                         int linputMethod,
                         int linputPrice,
                         int xPos,
                         int yPos,
                         const int iSubWindow=0,
                         const string MyIDPrefix="",
                         const int cFontSize=5
                         )
  {
   double percentage[2],tfPercentage[2];
   MultiTimeframeSign multiSign[];
   IndicatorSign indSign[];
   string IDPrefix;
   if(MyIDPrefix!="") IDPrefix=MyIDPrefix+"_"+symbol+"_";
   else IDPrefix="RTS_";

   if(symbol==NULL) symbol=Symbol();

//---- Current Indicator Data
   CalculateMultiTimeIndicator(symbol,TimeCurrent(),lMACDPeriod,lSTOCHPeriod,tfPercentage,multiSign,linputMethod,linputPrice);

   double spread=MarketInfo(symbol,MODE_SPREAD);
   color clrSpread=GetColor(spread,20,16,30,1);

   if(contrapair)
     {
      string symPair[2];

      symPair[0] = StringSubstr(symbol,0,3);
      symPair[1] = StringSubstr(symbol,3,3);
      symbol=symPair[1]+symPair[0];
     }

   double UpPercentage=tfPercentage[1];
   double DownPercentage=tfPercentage[0];

   if(contrapair)
     {
      UpPercentage=tfPercentage[0];
      DownPercentage=tfPercentage[1];
     }

   CreateColName(iSubWindow,IDPrefix+"LblTitle",symbol,clrWhite,xPos-5+ArraySize(multiSign[0].indSign),yPos,cFontSize+2);
   CreateColName(iSubWindow,IDPrefix+"Lbl_BuyPercentage",""+(string)UpPercentage+"%",clrLime,xPos+2,yPos,cFontSize+2);
   CreateColName(iSubWindow,IDPrefix+"Lbl_SellPercentage",""+(string)DownPercentage+"%",clrRed,xPos,yPos,cFontSize+2);

//CreateColName(iSubWindow,IDPrefix+"Lbl_Spread","Spread : "+(string)spread,clrSpread,xPos,yPos+1,cFontSize+2);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateSimpleMTF(
                        SymRTS &AllRTS,
                        string symbol,
                        int &lMAPeriod[],
                        string lMACDPeriod,
                        string lSTOCHPeriod,
                        int lADXPeriod,
                        int linputMethod,
                        int linputPrice,
                        const int shift=0
                        )
  {
   double percentage[2],tfPercentage[2];
   MultiTimeframeSign multiSign[];
   IndicatorSign indSign[];

   if(symbol==NULL) symbol=Symbol();
   if(MarketInfo(symbol,MODE_TRADEALLOWED) == false) return;

//---- Current Indicator Data

   int tF[];
   datetime lTime;

   if(shift>0)
      lTime=Time[shift];
   else
      lTime=TimeCurrent();

//Print(lTime);
   CalculateMultiTimeIndicator(symbol,lTime,lMACDPeriod,lSTOCHPeriod,tfPercentage,multiSign,linputMethod,linputPrice);

   AllRTS.UpRTS=tfPercentage[1];
   AllRTS.DownRTS=tfPercentage[0];
   AllRTS.RTS=AllRTS.UpRTS-AllRTS.DownRTS;
   AllRTS.Value=(int)((iClose(symbol,0,0)-iOpen(symbol,0,0))/MarketInfo(symbol,MODE_POINT));
   AllRTS.Spread=MarketInfo(symbol,MODE_SPREAD);
   AllRTS.Price=MarketInfo(symbol,MODE_BID);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double ShowSimpleMTFSign(
                         SymGroup &lInsPair,
                         SymRTS &lSymRTS,
                         int xPos,
                         int yPos,
                         const int iSubWindow=0,
                         const string MyIDPrefix="",
                         const bool lShowRTSOnly= false,
                         const int cFontSize=5
                         )
  {
   string IDPrefix;
   if(MyIDPrefix!="") IDPrefix=MyIDPrefix+"_"+lSymRTS.Name+"_";
   else IDPrefix="RTS_";

   int xPosShift=3;

   if(!lShowRTSOnly)
      xPosShift+=2;

   color clrPair=clrWhite;

   if(lSymRTS.Default==false)
      clrPair=clrGray;

   int iOpType=OpType(lSymRTS.Name);

   if(iOpType!=-1)
      clrPair = GetColor(iOpType,-1,1,0,2);

   CreateSign(iSubWindow,IDPrefix+"Sign",GetColor(lSymRTS.Spread,20,16,30,1),xPos+3+xPosShift,yPos,108,6);
   CreateColName(iSubWindow,IDPrefix+"LblTitle",StringSubstr(lSymRTS.Name,0,6),clrPair,xPos+xPosShift,yPos,cFontSize+2);

   if(lShowRTSOnly)
     {
      CreateColName(iSubWindow,IDPrefix+"Lbl_RTS",""+(string)NormalizeDouble(lSymRTS.RTS,0)+"%",lSymRTS.Color,xPos+1,yPos,cFontSize+2);
     }
   else
     {
      CreateColName(iSubWindow,IDPrefix+"Lbl_BuyPercentage",""+(string)NormalizeDouble(lSymRTS.UpRTS,0)+"%",clrLime,xPos+3,yPos,cFontSize+2);
      CreateColName(iSubWindow,IDPrefix+"Lbl_SellPercentage",""+(string)NormalizeDouble(lSymRTS.DownRTS,0)+"%",clrRed,xPos+1,yPos,cFontSize+2);
     }

   CreateColName(iSubWindow,IDPrefix+"Lbl_Val",""+DoubleToStr(lSymRTS.Value,0),GetColor(lSymRTS.Value,0),xPos,yPos,cFontSize+1);
//CreateColName(iSubWindow,IDPrefix+"Lbl_Price",""+(string)lSymRTS.Price,FontColor,xPos,yPos,cFontSize+1);

   return lSymRTS.RTS;
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
void CalculatePairsGroup(SymGroup &lInsPair,string symName,SymRTS &AllRTS[])
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

      //Print("#631 : ",lInsPair.PairRTS[i].Name);

      if(AllRTS[idxFound].Default==true)
        {
         lInsPair.PairRTS[i].UpRTS=AllRTS[idxFound].UpRTS;
         lInsPair.PairRTS[i].DownRTS=AllRTS[idxFound].DownRTS;
         lInsPair.PairRTS[i].Value=AllRTS[idxFound].Value;
         lInsPair.PairRTS[i].Price=NormalizeDouble(AllRTS[idxFound].Price,(int)MarketInfo(lInsPair.PairRTS[i].Name,MODE_DIGITS));
        }
      else
        {
         lInsPair.PairRTS[i].UpRTS=AllRTS[idxFound].DownRTS;
         lInsPair.PairRTS[i].DownRTS=AllRTS[idxFound].UpRTS;
         lInsPair.PairRTS[i].Value=AllRTS[idxFound].Value*(-1);
         lInsPair.PairRTS[i].Price=NormalizeDouble(AllRTS[idxFound].Price,(int)MarketInfo(lDefaultSymbol,MODE_DIGITS));
        }
      //Recalculating RTS depending on pair reversion
      lInsPair.PairRTS[i].RTS=lInsPair.PairRTS[i].UpRTS-lInsPair.PairRTS[i].DownRTS;
      lInsPair.PairRTS[i].Color=GetColor(lInsPair.PairRTS[i].RTS,0);
      lInsPair.PairRTS[i].Default=AllRTS[idxFound].Default;
      lInsPair.PairRTS[i].Spread=AllRTS[idxFound].Spread;

      RTS+=lInsPair.PairRTS[i].RTS;
      dValues+=lInsPair.PairRTS[i].Value;

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

   lInsPair.RTSAvg=RTS/ArraySize(lInsPair.PairRTS);
   lInsPair.ValueAvg=dValues/ArraySize(lInsPair.PairRTS);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateAllPairs(
                    SymGroup &lInsPairs[],
                    int &lMAPeriods[],
                    int linputMethod,
                    int linputPrice,
                    const int shift=0,
                    const string lMACDPeriods="12,26,9",
                    const string lSTOCHPeriods="5,3,3"
                    )
  {
   int i;
   SymRTS AllRTS[];

//Print(__FUNCTION__," : Calculating all pairs.");
   
   ArrayResize(AllRTS,ArraySize(sAllSymbols));

   for(i=0;i<ArraySize(sAllSymbols);i++)
     {
      AllRTS[i].Name=sAllSymbols[i];
      CalculateSimpleMTF(AllRTS[i],sAllSymbols[i],lMAPeriods,lMACDPeriods,lSTOCHPeriods,lMAPeriods[2],linputMethod,linputPrice,shift);
     }

   ArrayResize(lInsPairs,ArraySize(PairGroup));
   int idxHighestGrp,idxLowestGrp;
   double dHighest=-999;
   double dLowest=999;

   for(i=0;i<ArraySize(PairGroup);i++)
     {
      CalculatePairsGroup(lInsPairs[i],PairGroup[i],AllRTS);
      lInsPairs[i].Color=GetColor(lInsPairs[i].RTSAvg,0);
      lInsPairs[i].Strongest=false;
      lInsPairs[i].Weakest=false;

      if(lInsPairs[i].Name!="MAJ")
        {
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
     }

   lInsPairs[idxHighestGrp].Color= clrDodgerBlue;
   lInsPairs[idxLowestGrp].Color = clrRed;
   lInsPairs[idxHighestGrp].Strongest=true;
   lInsPairs[idxLowestGrp].Weakest=true;
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
//SignChar : 108 Circle, 110 Rectangle
void CreateSign(const int iSubWindow,string lblName,color clr,int xDist,int yDist,const uchar SignChar=110,const int SignSize=8)
  {
   ObjectCreate(lblName,OBJ_LABEL,iSubWindow,0,0);
   ObjectSetText(lblName,CharToStr(SignChar),SignSize,"Wingdings",clr);
   ObjectSet(lblName,OBJPROP_CORNER,Corner);
   ObjectSet(lblName,OBJPROP_XDISTANCE,xDist*hDist);
   ObjectSet(lblName,OBJPROP_YDISTANCE,yDist*vDist);
   ObjectSet(lblName,OBJPROP_HIDDEN,true);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateMTFColName(const int iSubWindow,string lblName,string txt,color clr,int xDist,int yDist,int lFontSize)
  {
   ObjectCreate(lblName,OBJ_LABEL,iSubWindow,0,0);
   ObjectSetText(lblName,txt,lFontSize,FontType,clr);
   ObjectSet(lblName,OBJPROP_CORNER,Corner);
   ObjectSet(lblName,OBJPROP_XDISTANCE,xDist*MTFhDist);
   ObjectSet(lblName,OBJPROP_YDISTANCE,yDist*MTFvDist);
   ObjectSet(lblName,OBJPROP_HIDDEN,true);
   ObjectSet(lblName,OBJPROP_SELECTABLE,false);
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
   ObjectSet(lblName,OBJPROP_XDISTANCE,xDist*MTFhDist);
   ObjectSet(lblName,OBJPROP_YDISTANCE,yDist*MTFvDist);
   ObjectSet(lblName,OBJPROP_HIDDEN,true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateMTFRowLabel(const int iSubWindow,string lblName,string lblText,color fontColor,int xDist,int yDist)
  {
   ObjectCreate(lblName,OBJ_LABEL,iSubWindow,0,0);
   ObjectSetText(lblName,lblText,FontSize,FontType,fontColor);
   ObjectSet(lblName,OBJPROP_CORNER,Corner);
   ObjectSet(lblName,OBJPROP_XDISTANCE,xDist*MTFhDist);
   ObjectSet(lblName,OBJPROP_YDISTANCE,yDist*MTFvDist);
   ObjectSet(lblName,OBJPROP_HIDDEN,true);
   ObjectSet(lblName,OBJPROP_SELECTABLE,false);
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
bool DeleteObject(const long   chart_ID=0,// chart's ID
                  const string name="Obj") // line name
  {
   ResetLastError();
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(!ObjectDelete(chart_ID,name))
     {
      int errCode = GetLastError();
      if(errCode !=4202)
         Print(__FUNCTION__,
               ": failed to delete ",name,"! ",ErrorDescription(errCode));
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TrendCreate(const long            chart_ID=0,// chart's ID
                 const string          name="TrendLine",  // line name
                 const int             sub_window=0,      // subwindow index
                 datetime              time1=0,           // first point time
                 double                price1=0,          // first point price
                 datetime              time2=0,           // second point time
                 double                price2=0,          // second point price
                 const color           clr=clrRed,        // line color
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style
                 const int             width=1,           // line width
                 const bool            back=false,        // in the background
                 const bool            selection=false,// highlight to move
                 const bool            ray_left=false,    // line's continuation to the left
                 const bool            ray_right=false,   // line's continuation to the right
                 const bool            hidden=true,       // hidden in the object list
                 const long            z_order=0)         // priority for mouse click
  {

   ChangeTrendEmptyPoints(time1,price1,time2,price2);

   ResetLastError();
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(!ObjectCreate(chart_ID,name,OBJ_TREND,sub_window,time1,price1,time2,price2))
     {
      Print(__FUNCTION__,": failed to create a trend line ",name,"! ",ErrorDescription(GetLastError()));
      return(false);
     }

   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_LEFT,ray_left);
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_RIGHT,ray_right);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);

   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TrendPointChange(const long   chart_ID=0,       // chart's ID
                      const string name="TrendLine", // line name
                      const int    point_index=0,    // anchor point index
                      datetime     time=0,           // anchor point time coordinate
                      double       price=0)          // anchor point price coordinate
  {
   if(!time)
      time=TimeCurrent();
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);

   ResetLastError();
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(!ObjectMove(chart_ID,name,point_index,time,price))
     {
      Print(__FUNCTION__,
            ": failed to move the anchor point! ",ErrorDescription(GetLastError()));
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ChangeTrendEmptyPoints(datetime &time1,double &price1,
                            datetime &time2,double &price2)
  {
   if(!time1)
      time1=TimeCurrent();

   if(!price1)
      price1=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(!time2)
     {
      datetime temp[10];
      CopyTime(Symbol(),Period(),time1,10,temp);
      time2=temp[0];
     }

   if(!price2)
      price2=price1;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CreateEntrySign(const long            chart_ID=0,// chart's ID
                     const string          name="ArrowBuy",   // sign name
                     const int             sub_window=0,      // subwindow index
                     datetime              time=0,            // anchor point time
                     double                price=0,           // anchor point price
                     const uchar           arrow_code=1,
                     const color           clr=C'3,95,172',   // sign color
                     const ENUM_LINE_STYLE style=STYLE_SOLID, // line style (when highlighted)
                     const int             width=1,           // line size (when highlighted)
                     const bool            back=false,        // in the background
                     const bool            selection=false,   // highlight to move
                     const bool            hidden=false,// hidden in the object list
                     const long            z_order=0,// priority for mouse click
                     const string          desc=""
                     )
  {

   if(!time)
      time=TimeCurrent();
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);

   ResetLastError();
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(!ObjectCreate(chart_ID,name,OBJ_ARROW_BUY,sub_window,time,price))
     {
      if(GetLastError()!=4202 && GetLastError()!=0)
         Print(__FUNCTION__,": ",name,"! ",ErrorDescription(GetLastError()));
      return(false);
     }

   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
   ObjectSetInteger(chart_ID,name,OBJPROP_ARROWCODE,arrow_code);
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,desc);
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,ANCHOR_TOP);
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetSessionTime(string symbol,int iTimeOffset,datetime lTime,string &sHOpenTime[],string &sHCloseTime[])
  {
//Initialize Closetime variable
   string hour24[24];
   string sSydney[2],sTokyo[2],sLondon[2],sNewYork[2];
   ArrayResize(sHOpenTime,ArraySize(sSessionZone));
   ArrayResize(sHCloseTime,ArraySize(sSessionZone));

   ConvertSessionTimeOffset(hour24,sSydney,sTokyo,sLondon,sNewYork,iTimeOffset);

   int iWeekDay=TimeDayOfWeek(lTime);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   switch(iWeekDay)
     {
      case 1 : //Senin
      case 2 : //Selasa
      case 3 : //Rabu
      case 4 : //Kamis
      case 5 : //Jum'at
         sHOpenTime[0]=sLondon[0]; sHCloseTime[0]=sLondon[1]; //London
         sHOpenTime[1]=sNewYork[0]; sHCloseTime[1]=sNewYork[1]; //New York
         sHOpenTime[2]=sSydney[0]; sHCloseTime[2]=sSydney[1]; //Sydney
         sHOpenTime[3]=sTokyo[0]; sHCloseTime[3]=sTokyo[1]; //Tokyo
         break;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ConvertSessionTimeOffset(string &hour24[24],
                             string &sSydney[2],string &sTokyo[2],string &sLondon[2],string &sNewYork[2],
                             const int iTimeOffset=0)
  {
   const string hourStd24[24]=
     {
      "00","01","02","03","04","05","06","07","08","09","10","11","12",
      "13","14","15","16","17","18","19","20","21","22","23"
     };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(iTimeOffset<0)
     {
      ArrayCopy(hour24,hourStd24,0,ArraySize(hourStd24)-MathAbs(iTimeOffset),MathAbs(iTimeOffset));
      ArrayCopy(hour24,hourStd24,MathAbs(iTimeOffset),0,ArraySize(hourStd24)-MathAbs(iTimeOffset));
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   else if(iTimeOffset>0)
     {
      ArrayCopy(hour24,hourStd24,0,MathAbs(iTimeOffset),ArraySize(hourStd24)-MathAbs(iTimeOffset));
      ArrayCopy(hour24,hourStd24,ArraySize(hourStd24)-MathAbs(iTimeOffset),0,MathAbs(iTimeOffset));
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   else
     {
      ArrayCopy(hour24,hourStd24,0,0);
     }
/*
      for(int i=0;i<24;i++)
        {
         Print("hour[",i,"]","=",hour24[i]);
        }
        */
/*
Sydney opens at 5:00 pm to 2:00 am EST (EDT)
Tokyo opens at 7:00 pm to 4:00 am EST (EDT)
London opens at 3:00 am to 12:00 noon EST (EDT)
New York opens at 8:00 am to 5:00 pm EST (EDT)
FBS = UTC+3 = GMT+4 = EST+7; UTC=EST+4;
*/

   sTokyo[0] = hour24[19]+":00";sTokyo[1] = hour24[4]+":00";
   sSydney[0]= hour24[17]+":00";sSydney[1]= hour24[2]+":00";
   sNewYork[0]= hour24[8]+":00";sNewYork[1]= hour24[17]+":00";
   sLondon[0] = hour24[3]+":00";sLondon[1] = hour24[12]+":00";

   return iTimeOffset;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetSession(string symbol,int lTimeOffset,datetime lTime,string Type)
  {
   int i=0;
   string sHOpenTime[4],sHCloseTime[4];
   string sCurTimeMinutes=TimeToString(lTime,TIME_MINUTES);

   GetSessionTime(symbol,lTimeOffset,lTime,sHOpenTime,sHCloseTime);

   if(Type=="open")
     {
      for(i=0;i<4;i++)
         if(sCurTimeMinutes==sHOpenTime[i])
            return sHOpenTime[i];
     }
   else if(Type=="close")
     {
      for(i=0;i<4;i++)
         if(sCurTimeMinutes==sHCloseTime[i])
            return sHCloseTime[i];
     }
   else if(Type=="openzone")
     {
      for(i=0;i<4;i++)
         if(sCurTimeMinutes==sHOpenTime[i])
            return sSessionZone[i];
     }
   else if(Type=="closezone")
     {
      for(i=0;i<4;i++)
         if(sCurTimeMinutes==sHCloseTime[i])
            return sSessionZone[i];
     }

   return "";

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OpType(string symbol)
  {
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==symbol)
        {
         if(OrderType()==OP_BUY)
            return OP_BUY;
         else if(OrderType()==OP_SELL)
            return OP_SELL;
        }
     }
   return -1;
  }
//+------------------------------------------------------------------+
//|                                                                  |
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
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateMAPeriods(int iTimeFrame,int &lHigherPeriod[],int &lMAPeriods[])
  {
   int UpperPeriod[4];

   if(iTimeFrame==0) iTimeFrame=Period();

   ArrayInitialize(UpperPeriod,0);
   ArrayInitialize(lHigherPeriod,0);
   ArrayResize(lMAPeriods,ArraySize(UpperPeriod));
   ArrayResize(lHigherPeriod,ArraySize(UpperPeriod));

   switch(iTimeFrame)
     {
      case PERIOD_M1:
         lHigherPeriod[0] = PERIOD_M5;
         lHigherPeriod[1] = PERIOD_M15;
         lHigherPeriod[2] = PERIOD_M30;
         lHigherPeriod[3] = PERIOD_H1;
         UpperPeriod[0] = PERIOD_M5;
         UpperPeriod[1] = PERIOD_M15;
         UpperPeriod[2] = PERIOD_H4;
         UpperPeriod[3] = PERIOD_H12;
         break;
      case PERIOD_M5:
         lHigherPeriod[0] = PERIOD_M15;
         lHigherPeriod[1] = PERIOD_M30;
         lHigherPeriod[2] = PERIOD_H1;
         lHigherPeriod[3] = PERIOD_H4;
         UpperPeriod[0] = PERIOD_M15;
         UpperPeriod[1] = PERIOD_M30;
         UpperPeriod[2] = PERIOD_H2;
         UpperPeriod[3] = PERIOD_H8;
         break;
      case PERIOD_M15:
         lHigherPeriod[0] = PERIOD_M30;
         lHigherPeriod[1] = PERIOD_H1;
         lHigherPeriod[2] = PERIOD_H4;
         lHigherPeriod[3] = PERIOD_D1;
         UpperPeriod[0] = PERIOD_M30;
         UpperPeriod[1] = PERIOD_H2;
         UpperPeriod[2] = PERIOD_H4;
         UpperPeriod[3] = PERIOD_H12;
         break;
      case PERIOD_M30:
         lHigherPeriod[0] = PERIOD_H1;
         lHigherPeriod[1] = PERIOD_H4;
         lHigherPeriod[2] = PERIOD_D1;
         lHigherPeriod[3] = PERIOD_W1;
         UpperPeriod[0] = PERIOD_H1;
         UpperPeriod[1] = PERIOD_H4;
         UpperPeriod[2] = PERIOD_H8;
         UpperPeriod[3] = PERIOD_W1;
         break;
      case PERIOD_H1:
         lHigherPeriod[0] = PERIOD_H4;
         lHigherPeriod[1] = PERIOD_D1;
         lHigherPeriod[2] = PERIOD_W1;
         lHigherPeriod[3] = PERIOD_MN1;
         UpperPeriod[0] = PERIOD_H4;
         UpperPeriod[1] = PERIOD_H8;
         UpperPeriod[2] = PERIOD_D1;
         UpperPeriod[3] = PERIOD_W1;
         break;
      case PERIOD_H4:
         lHigherPeriod[0] = PERIOD_D1;
         lHigherPeriod[1] = PERIOD_W1;
         lHigherPeriod[2] = PERIOD_MN1;
         lHigherPeriod[3] = PERIOD_MN1;
         UpperPeriod[0] = PERIOD_H8;
         UpperPeriod[1] = PERIOD_D1;
         UpperPeriod[2] = PERIOD_W1;
         UpperPeriod[3] = PERIOD_W1*2;
         break;
      case PERIOD_D1:
         lHigherPeriod[0] = PERIOD_W1;
         lHigherPeriod[1] = PERIOD_MN1;
         lHigherPeriod[2] = PERIOD_MN1;
         lHigherPeriod[3] = PERIOD_MN1;
         UpperPeriod[0] = PERIOD_D1*3;
         UpperPeriod[1] = PERIOD_D1*8;
         UpperPeriod[2] = PERIOD_D1*14;
         UpperPeriod[3] = PERIOD_MN1;
         break;
      case PERIOD_W1:
         lHigherPeriod[0] = PERIOD_MN1;
         lHigherPeriod[1] = PERIOD_MN1;
         lHigherPeriod[2] = PERIOD_MN1;
         lHigherPeriod[3] = PERIOD_MN1;
         UpperPeriod[0] = PERIOD_W1*4;
         UpperPeriod[1] = PERIOD_MN1*2;
         UpperPeriod[2] = PERIOD_MN1*6;
         UpperPeriod[3] = PERIOD_MN1*12;
         break;
      case PERIOD_MN1:
         lHigherPeriod[0] = PERIOD_MN1;
         lHigherPeriod[1] = PERIOD_MN1;
         lHigherPeriod[2] = PERIOD_MN1;
         lHigherPeriod[3] = PERIOD_MN1;
         UpperPeriod[0] = PERIOD_MN1*3;
         UpperPeriod[1] = PERIOD_MN1*6;
         UpperPeriod[2] = PERIOD_MN1*12;
         UpperPeriod[3] = (PERIOD_MN1*12)*4;
         break;
     }

   lMAPeriods[0]=UpperPeriod[0]/iTimeFrame;
   lMAPeriods[1]=UpperPeriod[1]/iTimeFrame;
   lMAPeriods[2]=UpperPeriod[2]/iTimeFrame;
   lMAPeriods[3]=UpperPeriod[3]/iTimeFrame;
  }

//+------------------------------------------------------------------+

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
*/

#property copyright   "2014-2016, Rony Nofrianto, Indonesia."
#property link "https://www.mql5.com/en/users/ronz"
#property description "RoNz MultiPair Trend Strength Correlation"
#property version   "1.2" //Build 010416
#property strict
#property indicator_separate_window
//#include  <RoNzIndicatorFunctions.mqh>

extern bool ShowRTSOnly=true; //Show RTS / Percentage
extern ENUM_MA_METHOD inpMethod=MODE_EMA; // Moving Average Method
extern ENUM_APPLIED_PRICE inpPrice=PRICE_CLOSE;   // Applied Price
extern string    MACDPeriod="12,26,9";   // MACD Period (FastEMA,SlowEMA,Signal)
extern string    STOCHPeriod="5,3,3";   // Stochasthic Period (K,D,Slowing)
extern int    inpShift=0;   //Shift

const string MyShortName="RoNz MultiPair Trend Strength Correlation";
const string MyID="Rz_MPTSC";
int MySubWindow=WindowFind(MyShortName);

//Indicator Buffers
double ExtBuff1[],ExtBuff2[];
#property indicator_buffers 2

#property indicator_label1  "Buff1"
#property indicator_color1 clrGray
#property  indicator_type1 DRAW_LINE

#property indicator_label2  "Buff2"
#property indicator_color2 clrDarkRed
#property  indicator_type2 DRAW_LINE

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

   IndicatorShortName(MyShortName);

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

   CheckAvailableSymbols();
   ShowAllPairRTS();

   EventSetTimer(1);
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

   for(int i=0; i<limit && !IsStopped(); i++)
     {
      ExtBuff1[i]=iMA(NULL,0,(int)RZIMAPeriods[0],0,inpMethod,inpPrice,i);
      ExtBuff2[i]=iMA(NULL,0,(int)RZIMAPeriods[1],0,inpMethod,inpPrice,i);
     }

   if(ShowRTSOnly)
      CreateMTFSign(NULL,MACDPeriod,STOCHPeriod,75,2,inpMethod,inpPrice,WindowFind(MyShortName),MyID);

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
      CreateColName(MySubWindow,MyID+InsRTS.Name+"RTS",InsRTS.Name+" : "+(string)NormalizeDouble(InsRTS.RTSAvg,0)+"%",InsRTS.Color,xPos+2,0*1,lFontSize);
      CreateColName(MySubWindow,MyID+InsRTS.Name+"PipsAvg",(string)NormalizeDouble(InsRTS.ValueAvg,0),InsRTS.Color,xPos,0*1,lFontSize-1);
     }

   for(int i=0;i<ArraySize(InsRTS.PairRTS);i++)
      ShowSimpleMTFSign(InsRTS,InsRTS.PairRTS[i],xPos,i+2,MySubWindow,MyID+InsRTS.Name,ShowRTSOnly);

//Statistics

   if(InsRTS.Strongest)
      CreateColName(MySubWindow,MyID+"StrongestCurrency","Strongest : "+InsRTS.Name+" ("+(string)NormalizeDouble(InsRTS.RTSAvg,0)+"%)",InsRTS.Color,0,9,lFontSize);
   if(InsRTS.Weakest)
      CreateColName(MySubWindow,MyID+"WeakestCurrency","Weakest : "+InsRTS.Name+" ("+(string)NormalizeDouble(InsRTS.RTSAvg,0)+"%)",InsRTS.Color,0,10,lFontSize);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ShowAllPairRTS()
  {
   int xPosShift=7;

   if(!ShowRTSOnly)
      xPosShift+=2;

   CalculateAllPairs(InsPairs,RZIMAPeriods,inpMethod,inpPrice,inpShift);

//Print(__FUNCTION__," : ",(string)ArraySize(InsPairs)," currency calculated.");

   for(int i=0;i<ArraySize(InsPairs);i++)
      ShowRTSLabel(InsPairs[i],i*xPosShift);
  }
//+------------------------------------------------------------------+
