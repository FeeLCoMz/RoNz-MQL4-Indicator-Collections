//+------------------------------------------------------------------+
//|                                                 TradeSession.mqh |
//|                                    Copyright 2015,Rony Nofrianto |
//|                                          http://www.feelcomz.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015,Rony Nofrianto"
#property link      "http://www.feelcomz.com"
#property version   "1.00"
#property strict

#define SHOW_FLOATINGPL false
#define SHOW_MAXMIN_PL_VLINE false
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_STRATEGY_SESSION
  {
   SESSION_NONE=0,
   SESSION_LONG=1,
   SESSION_SHORT=2
  };
string STR_STRATEGY_SESSION[]={"None","Buy","Sell"};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSession
  {
private:
   ENUM_STRATEGY_SESSION m_Session;
   double            m_LastProfit;

public:
   int               Number;
   int               Bar;
   int               Count;
   double            MaxProfit;
   double            MaxLoss;
   double            MaxLots;
   double            MinLots;
   int               MaxPoints;
   int               MinPoints;
   int               MaxOpened;
   int               MinOpened;

   int               BarMaxPoints;
   int               BarMinPoints;

   double            SessionStopLoss;
   double            SessionOpenPrice;
   double            SessionClosePrice;
   int               SessionCurrentPips;
   int               SessionClosedPips;
   int               SessionMaxPips;
   int               SessionMinPips;
   double            SessionMaxPL;
   double            SessionMinPL;

   double            MaxPL;
   double            MinPL;
   int               MaxFloatingPips;
   int               MinFloatingPips;

   void SetLastProfit(double pLastProfit) { m_LastProfit=pLastProfit;}
   double GetLastProfit() { return m_LastProfit; }

   void SetSession(ENUM_STRATEGY_SESSION pSession) { m_Session=pSession; }
   ENUM_STRATEGY_SESSION GetSession() { return m_Session; }

   void SessionDeInit()
     {
      MyObjects.MoveFloatingLabel(1);

      Number++;      
      AOCT.SessionClosedPips=AOCT.SessionCurrentPips;
      AOCT.SetMaxMinSessionPoints();
      AOCT.SessionMaxPL=AOCT.SessionMinPL=0;
      AOCT.SessionCurrentPips=AOCT.SessionMinPips=AOCT.SessionMaxPips=0;
     }

   void SetMaxMinSessionPoints()
     {
      if(AOCT.SessionClosedPips>AOCT.MaxPoints)
        {
         AOCT.MaxPoints=AOCT.SessionClosedPips;
         AOCT.BarMaxPoints=Bars;
         //ObjectDelete("VLineMaxPips");
         //Draw.VLineCreate(0,"VLineMaxPips",0,Time[0],clrBlue,STYLE_DOT,2);
        }

      if(AOCT.SessionClosedPips<AOCT.MinPoints)
        {
         AOCT.MinPoints=AOCT.SessionClosedPips;
         AOCT.BarMinPoints=Bars;
         //ObjectDelete("VLineMinPips");
         //Draw.VLineCreate(0,"VLineMinPips",0,Time[0],clrRed,STYLE_DOT,2);
        }
     }

   void SetMaxMinClosedOrders()
     {
      if(MyStrategy.LastClosedOrders.Profit!=0 && MyEA.LastClosedOrders.Bar!=Bars)
        {
         AOCT.SetLastProfit(MyEA.LastClosedOrders.Profit);

         if(MyEA.LastClosedOrders.Profit>AOCT.MaxProfit)
           {
            if(SHOW_MAXMIN_PL_VLINE)
              {
               ObjectDelete("VLine.MaxProfit");
               Draw.VLineCreate(0,"VLine.MaxProfit",0,Time[0],clrBlue,STYLE_DOT,2);
              }
            AOCT.MaxProfit=MyEA.LastClosedOrders.Profit;
           }

         if(MyEA.LastClosedOrders.Profit<AOCT.MaxLoss)
           {
            if(SHOW_MAXMIN_PL_VLINE)
              {
               ObjectDelete("VLine.MaxLoss");
               Draw.VLineCreate(0,"VLine.MaxLoss",0,Time[0],clrRed,STYLE_DOT,2);
              }
            AOCT.MaxLoss=MyEA.LastClosedOrders.Profit;
           }

         if(MyEA.LastClosedOrders.Count>AOCT.MaxOpened)
            AOCT.MaxOpened=MyEA.LastClosedOrders.Count;

         if(AOCT.MinOpened==0)
            AOCT.MinOpened=MyEA.LastClosedOrders.Count;
         else if(MyEA.LastClosedOrders.Count<AOCT.MinOpened)
            AOCT.MinOpened=MyEA.LastClosedOrders.Count;

         if(MyEA.LastClosedOrders.Lots>AOCT.MaxLots)
            AOCT.MaxLots=MyEA.LastClosedOrders.Lots;

         if(AOCT.MinLots==0)
            AOCT.MinLots=MyEA.LastClosedOrders.Lots;
         else if(MyEA.LastClosedOrders.Lots<AOCT.MinLots)
            AOCT.MinLots=MyEA.LastClosedOrders.Lots;

        }
     }

   void GetSessionPips()
     {
      //Calculating Session Floating PL         
      double FloatingPPos=0;
      double FloatingLPos=0;
      double FloatingLPosStart=0;
      double FloatingPPosStart=0;
      double FloatingLPosEnd=0;
      double FloatingPPosEnd=0;
      bool CalculatePL=true;

      //Min/Max Floating Profit/Loss Label
      if(MyStrategy.AllOrders.Opened.Profit<AOCT.MinPL)
         AOCT.MinPL=MyStrategy.AllOrders.Opened.Profit;
      if(MyStrategy.AllOrders.Opened.Profit>AOCT.MaxPL)
         AOCT.MaxPL=MyStrategy.AllOrders.Opened.Profit;

      if(AOCT.GetSession()==SS_BUY)
        {
         FloatingPPos=High[0]-(10*Point);
         FloatingLPos=Low[0]+(30*Point);

         FloatingPPosStart=High[0];//+(10*Point);
         FloatingLPosStart=Low[0];//-(10*Point);

         FloatingPPosEnd=FloatingPPos;//-(50*Point);
         FloatingLPosEnd=FloatingLPos;

         AOCT.SessionClosePrice=Bid;
         AOCT.SessionCurrentPips=(int)((AOCT.SessionClosePrice-AOCT.SessionOpenPrice)/Point);

         if(MyStrategy.AllOrders.Sells.Counts>0)
           {
            CalculatePL=false;
            AOCT.SessionMaxPL=AOCT.SessionMinPL=0;
           }

        }

      if(AOCT.GetSession()==SS_SELL)
        {
         FloatingPPos=Low[0]+(30*Point);
         FloatingLPos=High[0]-(10*Point);

         FloatingPPosStart=Low[0];//-(10*Point);
         FloatingLPosStart=High[0];//+(10*Point);

         FloatingPPosEnd=FloatingPPos;
         FloatingLPosEnd=FloatingLPos;//-(50*Point);

         AOCT.SessionClosePrice=Ask;
         AOCT.SessionCurrentPips=(int)((AOCT.SessionOpenPrice-AOCT.SessionClosePrice)/Point);

         if(MyStrategy.AllOrders.Buys.Counts>0)
           {
            CalculatePL=false;
            AOCT.SessionMaxPL=AOCT.SessionMinPL=0;
           }

        }

      MyLabel.MoveFloatingLabel(1);

      //AOCT Info
      if(AOCT.SessionCurrentPips<AOCT.MinFloatingPips)
         AOCT.MinFloatingPips=AOCT.SessionCurrentPips;

      if(AOCT.SessionCurrentPips>AOCT.MaxFloatingPips)
         AOCT.MaxFloatingPips=AOCT.SessionCurrentPips;

      if(AOCT.SessionCurrentPips<AOCT.SessionMinPips)
        {
         AOCT.SessionMinPips=AOCT.SessionCurrentPips;

         if(inpShowOnPriceInfo)
           {
            string sFloatingL=DoubleToStr(AOCT.SessionMinPL,2)+" $ ("+(string)AOCT.SessionMinPips+" Pips)";
            MyLabel.CreateOnPriceLabel("minpips"+(string)AOCT.Number,Time[0],FloatingLPos,sFloatingL,clrYellow,8);
            ObjectDelete(0,"trendminp"+(string)AOCT.Number);
            Draw.TrendCreate(0,"trendminp"+(string)AOCT.Number,0,Time[0],FloatingLPosStart,Time[0],FloatingLPosEnd,clrYellow,STYLE_SOLID);
           }
        }

      if(AOCT.SessionCurrentPips>AOCT.SessionMaxPips)
        {
         AOCT.SessionMaxPips=AOCT.SessionCurrentPips;

         if(inpShowOnPriceInfo)
           {
            string sFloatingP=DoubleToStr(AOCT.SessionMaxPL,2)+" $ ("+(string)AOCT.SessionMaxPips+" Pips)";
            MyLabel.CreateOnPriceLabel("maxpips"+(string)AOCT.Number,Time[0],FloatingPPos,sFloatingP,clrWhite,8);
            ObjectDelete(0,"trendmaxp"+(string)AOCT.Number);
            Draw.TrendCreate(0,"trendmaxp"+(string)AOCT.Number,0,Time[0],FloatingPPosStart,Time[0],FloatingPPosEnd,clrWhite,STYLE_SOLID);
           }
        }

      if(CalculatePL)
        {
         if(MyStrategy.AllOrders.Opened.Profit<AOCT.SessionMinPL)
           {
            AOCT.SessionMinPL=MyStrategy.AllOrders.Opened.Profit;

            string sFloatingL=DoubleToStr(AOCT.SessionMinPL,2)+" $";

            if(SHOW_FLOATINGPL && inpShowOnPriceInfo)
              {
               MyLabel.CreateOnPriceLabel("floatingl"+(string)AOCT.Number,Time[0],FloatingLPos,sFloatingL,clrYellow,8);
               ObjectDelete(0,"trendl"+(string)AOCT.Number);
               Draw.TrendCreate(0,"trendl"+(string)AOCT.Number,0,Time[0],FloatingLPosStart,Time[0],FloatingLPosEnd,clrYellow,STYLE_SOLID);
              }

            if(inpShowOnPriceInfo)
              {
               //Updating Label   
               sFloatingL=DoubleToStr(AOCT.SessionMinPL,2)+" $ ("+(string)AOCT.SessionMinPips+" Pips)";

               if(ObjectGet("minpips"+(string)AOCT.Number,OBJPROP_PRICE1)!=0)
                  FloatingLPos=ObjectGet("minpips"+(string)AOCT.Number,OBJPROP_PRICE1);

               MyLabel.CreateOnPriceLabel("minpips"+(string)AOCT.Number,Time[0],FloatingLPos,sFloatingL,clrYellow,8);
              }
           }

         if(MyStrategy.AllOrders.Opened.Profit>AOCT.SessionMaxPL)
           {
            AOCT.SessionMaxPL=MyStrategy.AllOrders.Opened.Profit;

            string sFloatingP=DoubleToStr(AOCT.SessionMaxPL,2)+" $";

            if(SHOW_FLOATINGPL && inpShowOnPriceInfo)
              {
               MyLabel.CreateOnPriceLabel("floatingp"+(string)AOCT.Number,Time[0],FloatingPPos,sFloatingP,clrWhite,8);
               ObjectDelete(0,"trendp"+(string)AOCT.Number);
               Draw.TrendCreate(0,"trendp"+(string)AOCT.Number,0,Time[0],FloatingPPosStart,Time[0],FloatingPPosEnd,clrWhite,STYLE_SOLID);
              }

            if(inpShowOnPriceInfo)
              {
               //Updating Label   
               sFloatingP=DoubleToStr(AOCT.SessionMaxPL,2)+" $ ("+(string)AOCT.SessionMaxPips+" Pips)";

               if(ObjectGet("maxpips"+(string)AOCT.Number,OBJPROP_PRICE1)!=0)
                  FloatingPPos=ObjectGet("maxpips"+(string)AOCT.Number,OBJPROP_PRICE1);

               MyLabel.CreateOnPriceLabel("maxpips"+(string)AOCT.Number,Time[0],FloatingPPos,sFloatingP,clrWhite,8);
              }

           }
        }
     }

  };