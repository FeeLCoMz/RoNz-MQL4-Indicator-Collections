//+------------------------------------------------------------------+
//|                                                      Objects.mqh |
//|                                    Copyright 2015,Rony Nofrianto |
//|                                          http://www.feelcomz.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015,Rony Nofrianto"
#property link      "http://www.feelcomz.com"
#property version   "1.00"
#property strict

//---- Label Config
#define FONT_TYPE "Arial"
#define FONT_SIZE 8
#define FONT_COLOR clrWhite
#define CORNER 1
#define V_DIST 13 //Vertical Space

#define SHOW_SESSIONCLOSEDVLINE false
#define RIGHT_LABEL_NAME "RZ_R_LABEL"
#define ALERTSOUNDFILE "alert2.wav"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CObjects
  {
private:
   void ChangeTrendEmptyPoints(datetime &time1,double &price1,
                               datetime &time2,double &price2)
     {
      if(!time1)
         time1=TimeCurrent();

      if(!price1)
         price1=SymbolInfoDouble(Symbol(),SYMBOL_BID);

      if(!time2)
        {
         datetime temp[10];
         CopyTime(Symbol(),Period(),time1,10,temp);
         time2=temp[0];
        }

      if(!price2)
         price2=price1;
     }
   void ShowAlertAndProfitLabel(int Bar,int Counts,double dProfit,double dLots,int dProfitPoint,string HitTPSL,string sOpType)
     {
      if(dLots==0) return;


      dProfit=NormalizeDouble(dProfit,2);

      string sProfit=(string)DoubleToStr(dProfit,2)+" $";
      sProfit+=" ("+(string)dProfitPoint+" Pips)"+HitTPSL;

      if(Volume[0]<2)
         ShowAlert("Closed all "+sOpType+". Profit: "+sProfit);

      CreateProfitLabel(sOpType+(string)Bars,Time[0],Close[0],dProfit,sProfit);

      sProfit=(string)(Counts)+" orders";
      sProfit+=" / "+(string)DoubleToStr(dLots,2)+" lots";
      CreateProfitLabel(sOpType+"ordersnlots"+(string)Bars,Time[0],Close[0]-(50*Point),dProfit,sProfit);

      if(SHOW_SESSIONCLOSEDVLINE) VLineCreate(0,"Vline"+(string)Bars,0,Time[0],clrWhite,STYLE_DOT);

      Bar=Bars;
     }
public:
   bool SoundAlert;
   bool MessageAlert;
   bool ShowOnPriceInfo;
   
   void ShowAlert(string Txt)
     {
      if(IsTesting())
        {
         Print(Txt);
         return;
        }
      if(SoundAlert) PlaySound(ALERTSOUNDFILE);
      if(MessageAlert) Alert(AccountNumber()," : (",Symbol(),") ",Txt);
     }

   void LvMonitor(string labelName,string text,int y,color fontColor=clrWhite)
     {
      AutoLabel(labelName,text,5,y,fontColor);
     }
   void AutoLabel(string labelName,string text,int xDist,int yDist,color fontColor=clrWhite)
     {
      CreateLabel(0,text,labelName,FONT_SIZE,FONT_TYPE,fontColor,CORNER,xDist,yDist);
     }
   void CreateButton(string labelName,string text,color clr,int xDist,int yDist)
     {
      CreateLabel(0,text,labelName,15,"Impact",clr,2,xDist,yDist);
     }
   void CreateLabel(const int iSubWindow,string lblText,string lblName,int fontSize,string fontType,color fontColor,int lblCorner,int xDist,int yDist)
     {
      ObjectCreate(lblName,OBJ_LABEL,iSubWindow,0,0);
      ObjectSetText(lblName,lblText,fontSize,fontType,fontColor);
      ObjectSet(lblName,OBJPROP_CORNER,lblCorner);
      ObjectSet(lblName,OBJPROP_XDISTANCE,xDist);
      ObjectSet(lblName,OBJPROP_YDISTANCE,yDist*V_DIST);
      ObjectSet(lblName,OBJPROP_HIDDEN,false);
     }
   bool CreateProfitLabel(string lblName,datetime time,double price,double profit,string lblText)
     {
      if(profit==0) return false;
      int clr=GetColor(profit,0);

      lblName="lProfit_"+lblName;

      ObjectDelete(lblName);
      ObjectCreate(lblName,OBJ_TEXT,0,time,price-(100*Point));
      ObjectSetText(lblName,lblText,FONT_SIZE+2,FONT_TYPE,clr);
      ObjectSetInteger(0,lblName,OBJPROP_SELECTABLE,false);
      return true;
     }
   bool CreateOnPriceLabel(string lblName,datetime time,double price,string lblText,color clr=clrWhite,int lFontSize=8)
     {
      if(!ShowOnPriceInfo) return false;

      lblName="l_"+lblName;

      ObjectDelete(lblName);
      ObjectCreate(lblName,OBJ_TEXT,0,time,price);
      ObjectSetText(lblName,lblText,lFontSize,FONT_TYPE,clr);
      ObjectSetInteger(0,lblName,OBJPROP_SELECTABLE,true);
      return true;
     }
     
   color GetColor(double dPositiveVal,double dMediumVal,const double dLowVal=NULL,const double dHighVal=NULL,
                  int compType=0 //0 : Default Comparison, 1 : Reverse Comparison, 2 : Exact Comparison
                  )
     {
      color clrHigher= clrDodgerBlue;
      color clrLower = clrDarkOrange;
      color clrHighest= clrLawnGreen;
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

   void MoveFloatingLabel(int index=0)
     {
      string LblName;

      if(index==1 || index==0)
        {
         //Move Max/Min Pips Label
         LblName="l_"+"minpips"+(string)AOCT.Number;
         ObjectMove(LblName,0,Time[0],ObjectGet(LblName,OBJPROP_PRICE1));

         LblName="l_"+"maxpips"+(string)AOCT.Number;
         ObjectMove(LblName,0,Time[0],ObjectGet(LblName,OBJPROP_PRICE1));

         LblName="trendminp"+(string)AOCT.Number;
         ObjectMove(LblName,1,Time[1],ObjectGet(LblName,OBJPROP_PRICE1));

         LblName="trendmaxp"+(string)AOCT.Number;
         ObjectMove(LblName,1,Time[1],ObjectGet(LblName,OBJPROP_PRICE1));
        }

      if(index==2 || index==0)
        {
         //Move Floating P/L Label
         LblName="l_"+"floatingp"+(string)AOCT.Number;
         ObjectMove(LblName,0,Time[0],ObjectGet(LblName,OBJPROP_PRICE1));

         LblName="l_"+"floatingl"+(string)AOCT.Number;
         ObjectMove(LblName,0,Time[0],ObjectGet(LblName,OBJPROP_PRICE1));

         LblName="trendl"+(string)AOCT.Number;
         ObjectMove(LblName,1,Time[0],ObjectGet(LblName,OBJPROP_PRICE1));

         LblName="trendp"+(string)AOCT.Number;
         ObjectMove(LblName,1,Time[0],ObjectGet(LblName,OBJPROP_PRICE1));
        }

      LblName="SessionSL"+(string)AOCT.Number;
      ObjectMove(LblName,1,Time[0],ObjectGet(LblName,OBJPROP_PRICE1));
     }

   void ShowDateTime()
     {
      string mSession=TimeToStr(TimeCurrent(),TIME_DATE)+"  ("+TimeToStr(TimeCurrent(),TIME_SECONDS)+")";
      CreateLabel(0,mSession,RIGHT_LABEL_NAME+"0",9,FONT_TYPE,FONT_COLOR,1,10,2);
     }

   void ShowProfitLabel(string txt="")
     {
      if(!inpShowOnPriceInfo) return;
      MyStrategy.AllOrders.Get_ClosedOrderInfo(iBarShift(Symbol(),Period(),Time[0],true));

      int OpType=-1;
      string sOpType="";

      if(AOCT.GetSession()==SS_LONG) sOpType=STR_OPTYPE[OP_BUY];
      else if(AOCT.GetSession()==SS_SHORT) sOpType=STR_OPTYPE[OP_SELL];

      ShowAlertAndProfitLabel(LastClosedOrders.Profit,MyEA.LastClosedOrders.Lots,AOCT.SessionClosedPips,+" "+txt);
     }

   void ShowTradeButton()
     {
      MyLabel.CreateButton("btnBuy","BUY",clrDodgerBlue,10,0);
      MyLabel.CreateButton("btnSell","SELL",clrSell,50,0);
      MyLabel.CreateButton("btnBL","BUY LIMIT",clrDodgerBlue,100,0);
      MyLabel.CreateButton("btnBS","BUY STOP",clrDodgerBlue,200,0);
      MyLabel.CreateButton("btnSL","SELL LIMIT",clrSell,300,0);
      MyLabel.CreateButton("btnSS","SELL STOP",clrSell,400,0);
     }
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
                    const bool            hidden=false,// hidden in the object list
                    const long            z_order=0) // priority for mouse click
     {

      ChangeTrendEmptyPoints(time1,price1,time2,price2);

      ResetLastError();

      if(!ObjectCreate(chart_ID,name,OBJ_TREND,sub_window,time1,price1,time2,price2))
        {
         //Print(__FUNCTION__,": failed to create a trend line ",name,"! ",ErrorDescription(GetLastError()));
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

   bool VLineCreate(const long            chart_ID=0,// chart's ID
                    const string          name="VLine",      // line name
                    const int             sub_window=0,      // subwindow index
                    datetime              time=0,            // line time
                    const color           clr=clrRed,        // line color
                    const ENUM_LINE_STYLE style=STYLE_SOLID, // line style
                    const int             width=1,           // line width
                    const bool            back=false,        // in the background
                    const bool            selection=true,    // highlight to move
                    const bool            hidden=true,       // hidden in the object list
                    const long            z_order=0)         // priority for mouse click
     {
      //--- if the line time is not set, draw it via the last bar
      if(!time)
         time=TimeCurrent();
      //--- reset the error value
      ResetLastError();
      //--- create a vertical line
      if(!ObjectCreate(chart_ID,name,OBJ_VLINE,sub_window,time,0))
        {
         //Print(__FUNCTION__, ": failed to create a vertical line! Error code = ",GetLastError());
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
     
  };