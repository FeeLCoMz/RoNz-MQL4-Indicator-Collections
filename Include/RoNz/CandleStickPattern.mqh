//+------------------------------------------------------------------+
//|                                           CandleStickPattern.mqh |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_SINGLECANDLESTICKPATTERN
  {
   CANDLE_NONE=0,
   CANDLE_SPINNING_TOPS=1,
   CANDLE_BULLISH_MARUBOZU=2,
   CANDLE_BEARISH_MARUBOZU=3,
   CANDLE_DOJI=4,
   CANDLE_HAMMER=5,
   CANDLE_HANGING_MAN=6,
   CANDLE_INVERTED_HAMMER=7,
   CANDLE_SHOOTING_STAR=8
  };
string STR_SINGLECANDLEPATTERN[9]=
  {
   "NONE",
   "SPINNING_TOPS (Neutral)",
   "BULLISH MARUBOZU (Strong Buy)",
   "BEARISH MARUBOZU (Strong Sell)",
   "DOJI (Neutral)",
   "HAMMER (Bullish)",
   "HANGING_MAN (Bearish)",
   "INVERTED_HAMMER (Bullish)",
   "SHOOTING_STAR (Bearish)"
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_DOUBLECANDLESTICKPATTERN
  {
   CANDLE_BULLISH_ENGULFING=0,
   CANDLE_BEARISH_ENGULFING=1,
   CANDLE_TWEEZER_TOPS=2,
   CANDLE_TWEEZER_BOTTOMS=3,

  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_TRIPLECANDLESTICKPATTERN
  {
   CANDLE_MORNING_STAR=0,
   CANDLE_EVENING_STAR=1,
   CANDLE_THREE_WHITE_SOLDIERS=2,
   CANDLE_THREE_BLACK_CROWS=3,
   CANDLE_THREE_INSIDE_UP=4,
   CANDLE_THREE_INSIDE_BOTTOM=5,
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CandleStickPattern
  {
private:

public:
                     CandleStickPattern();
                    ~CandleStickPattern();
   ENUM_SINGLECANDLESTICKPATTERN SingleCandlestickPattern(int shift);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CandleStickPattern::CandleStickPattern()
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CandleStickPattern::~CandleStickPattern()
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_SINGLECANDLESTICKPATTERN CandleStickPattern::SingleCandlestickPattern(int shift)
  {
   ENUM_SINGLECANDLESTICKPATTERN Candle;

   double high=High[shift];
   double close=Close[shift];
   double open=Open[shift];
   double low=Low[shift];

   bool bullish = close>open;
   bool bearish = close<open;

   double uppershadow=0;
   double lowershadow=0;
   double realbodies=0;
   double candlesize=NormalizeDouble((high-low)/Point,0);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(bullish)
     {
      uppershadow=(high-close)/Point;
      lowershadow=(open-low)/Point;
      realbodies=(close-open)/Point;
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   else if(bearish)
     {
      uppershadow=(high-open)/Point;
      lowershadow=(close-low)/Point;
      realbodies=(open-close)/Point;
     }

   if(candlesize!=0)
     {
      uppershadow=NormalizeDouble(uppershadow/candlesize*100,0);
      lowershadow=NormalizeDouble(lowershadow/candlesize*100,0);
      realbodies=NormalizeDouble(realbodies/candlesize*100,0);
     }

   if(realbodies<uppershadow && realbodies<lowershadow && realbodies>20)
      Candle=CANDLE_SPINNING_TOPS;
   else if(bullish && realbodies>=60 && realbodies>uppershadow+lowershadow)
                                  Candle=CANDLE_BULLISH_MARUBOZU;
   else if(bearish && realbodies>=60 && realbodies>uppershadow+lowershadow)
                                  Candle=CANDLE_BEARISH_MARUBOZU;
   else if(realbodies<10)
      Candle=CANDLE_DOJI;
   else if(bullish && lowershadow>=60 && realbodies>uppershadow)
                                   Candle=CANDLE_HAMMER;
   else if(bearish && lowershadow>=60 && realbodies>uppershadow)
                                   Candle=CANDLE_HANGING_MAN;
   else if(bullish && uppershadow>=60 && realbodies>lowershadow)
                                   Candle=CANDLE_INVERTED_HAMMER;
   else if(bearish && uppershadow>=60 && realbodies>lowershadow)
                                   Candle=CANDLE_SHOOTING_STAR;

   return Candle;

  }
//+------------------------------------------------------------------+
