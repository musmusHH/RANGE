//+------------------------------------------------------------------+
//| Signal Forge [LuxAlgo] - MetaTrader 4 port                       |
//| Original work (c) LuxAlgo, CC BY-NC-SA 4.0                      |
//| https://creativecommons.org/licenses/by-nc-sa/4.0/               |
//|                                                                  |
//| Non-commercial ShareAlike port of the supplied Pine v6 script.   |
//+------------------------------------------------------------------+
#property strict
#property indicator_chart_window
#property indicator_buffers 11

#property indicator_color1  C'8,153,129'
#property indicator_color2  C'8,153,129'
#property indicator_color3  C'8,153,129'
#property indicator_color4  C'242,54,69'
#property indicator_color5  C'242,54,69'
#property indicator_color6  C'242,54,69'
#property indicator_color7  C'242,54,69'
#property indicator_color8  C'8,153,129'
#property indicator_color9  C'242,54,69'
#property indicator_color10 C'8,153,129'
#property indicator_color11 C'41,98,255'

// Signal logic
input bool RequireAllEnabledIndicatorsToAlign = true;

// Risk management (ATR)
input int    ATRLength          = 14;
input bool   EnableTakeProfit   = false;
input double TakeProfitATR      = 2.0;
input bool   EnableStopLoss     = false;
input double StopLossATR        = 1.5;
input bool   EnableTrailingStop = false;
input double TrailingStopATR    = 1.0;

// Visuals
input double OrbDistanceATR     = 1.5;
input int    OrbBaseSize        = 10;
input bool   EnableAlerts       = true;
input bool   AlertOnClosedBar   = true;

// SMA crossover
input bool EnableSMA = true;
input int  SMAFastLength = 10;
input int  SMASlowLength = 20;
// RSI filter
input bool   EnableRSI = false;
input int    RSILength = 14;
input double RSILongAbove = 50.0;
input double RSIShortBelow = 50.0;
// MACD crossover
input bool EnableMACD = false;
input int  MACDFastLength = 12;
input int  MACDSlowLength = 26;
input int  MACDSignalLength = 9;
// Supertrend
input bool   EnableSupertrend = false;
input double SupertrendFactor = 3.0;
input int    SupertrendLength = 10;
// Stochastic
input bool EnableStochastic = false;
input int  StochasticKLength = 14;
input int  StochasticDLength = 3;
input int  StochasticSmooth = 3;
// Bollinger trend (the Pine logic uses the middle band only)
input bool   EnableBollinger = false;
input int    BollingerLength = 20;
input double BollingerMultiplier = 2.0;
// EMA crossover
input bool EnableEMA = false;
input int  EMAFastLength = 10;
input int  EMASlowLength = 20;
// Awesome Oscillator
input bool EnableAO = false;
// Parabolic SAR
input bool   EnableSAR = false;
input double SARStart = 0.02;
input double SARIncrement = 0.02;
input double SARMaximum = 0.2;
// CCI filter
input bool   EnableCCI = false;
input int    CCILength = 20;
input double CCILongAbove = 0.0;
input double CCIShortBelow = 0.0;
// ADX filter
input bool   EnableADX = false;
input int    ADXSmoothing = 14;
input int    DILength = 14;
input double ADXThreshold = 20.0;

// Dashboard
input bool ShowDashboards = true;
enum SF_CORNER { Top_Right=0, Bottom_Right=1, Bottom_Left=2 };
input SF_CORNER IndicatorDashboardPosition = Top_Right;
input SF_CORNER PerformanceDashboardPosition = Bottom_Right;
input int DashboardFontSize = 9;

// Output buffers
double LongGlow1[], LongGlow2[], LongGlow3[];
double ShortGlow1[], ShortGlow2[], ShortGlow3[];
double ExitLongBuffer[], ExitShortBuffer[];
double StopBuffer[], TargetBuffer[], TrailBuffer[];

string PREFIX="SF_LUX_MT4_";
datetime lastAlertBar=0;

int CornerValue(SF_CORNER p)
{
   if(p==Top_Right) return CORNER_RIGHT_UPPER;
   if(p==Bottom_Right) return CORNER_RIGHT_LOWER;
   return CORNER_LEFT_LOWER;
}

int AnchorValue(SF_CORNER p)
{
   // The label anchor must match its chart corner. Without this, a label on
   // the right edge grows outside the chart and the dashboard is invisible.
   if(p==Top_Right) return ANCHOR_RIGHT_UPPER;
   if(p==Bottom_Right) return ANCHOR_RIGHT_LOWER;
   return ANCHOR_LEFT_LOWER;
}

void PutDashboard(string name, SF_CORNER pos, int x, int y, string text)
{
   // MT4's OBJ_LABEL does not render newline characters as separate lines.
   // Create one label per row so the complete dashboard remains on-screen.
   string oldName=PREFIX+name;
   if(ObjectFind(0,oldName)>=0) ObjectDelete(0,oldName); // remove pre-fix label

   string rows[];
   ushort separator=(ushort)StringGetCharacter("\n",0);
   int rowCount=StringSplit(text,separator,rows);
   if(rowCount<1)
   {
      ArrayResize(rows,1);
      rows[0]=text;
      rowCount=1;
   }

   int fontSize=MathMax(7,DashboardFontSize);
   int lineHeight=fontSize+5;
   int corner=CornerValue(pos);
   int anchor=AnchorValue(pos);

   for(int i=0;i<rowCount;i++)
   {
      string n=PREFIX+name+"_"+IntegerToString(i);
      if(ObjectFind(0,n)<0) ObjectCreate(0,n,OBJ_LABEL,0,0,0);

      // For lower corners, build upward from the 10-pixel bottom edge while
      // preserving the normal top-to-bottom order of the supplied text.
      int rowY=(pos==Top_Right) ? y+i*lineHeight : y+(rowCount-1-i)*lineHeight;
      ObjectSetInteger(0,n,OBJPROP_CORNER,corner);
      ObjectSetInteger(0,n,OBJPROP_ANCHOR,anchor);
      ObjectSetInteger(0,n,OBJPROP_XDISTANCE,x);
      ObjectSetInteger(0,n,OBJPROP_YDISTANCE,rowY);
      ObjectSetInteger(0,n,OBJPROP_COLOR,C'219,219,219');
      ObjectSetInteger(0,n,OBJPROP_FONTSIZE,fontSize);
      ObjectSetString(0,n,OBJPROP_FONT,"Consolas");
      ObjectSetString(0,n,OBJPROP_TEXT,rows[i]);
      ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,n,OBJPROP_HIDDEN,true);
   }

   // Delete surplus rows if a future dashboard update contains fewer lines.
   for(int stale=rowCount;stale<40;stale++)
   {
      string staleName=PREFIX+name+"_"+IntegerToString(stale);
      if(ObjectFind(0,staleName)>=0) ObjectDelete(0,staleName);
   }
}

string StatusText(bool bull, bool bear)
{
   if(bull) return "Bullish";
   if(bear) return "Bearish";
   return "Neutral";
}

string OnOff(bool v) { return v ? "ON" : "OFF"; }

int OnInit()
{
   IndicatorShortName("LuxAlgo - Signal Forge (MT4)");
   SetIndexBuffer(0,LongGlow1);  SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,MathMin(5,MathMax(1,OrbBaseSize/2))); SetIndexArrow(0,159); SetIndexLabel(0,"Long signal");
   SetIndexBuffer(1,LongGlow2);  SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,MathMin(4,MathMax(1,(OrbBaseSize-3)/2))); SetIndexArrow(1,159); SetIndexLabel(1,NULL);
   SetIndexBuffer(2,LongGlow3);  SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,MathMin(3,MathMax(1,(OrbBaseSize-6)/2))); SetIndexArrow(2,159); SetIndexLabel(2,NULL);
   SetIndexBuffer(3,ShortGlow1); SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,MathMin(5,MathMax(1,OrbBaseSize/2))); SetIndexArrow(3,159); SetIndexLabel(3,"Short signal");
   SetIndexBuffer(4,ShortGlow2); SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,MathMin(4,MathMax(1,(OrbBaseSize-3)/2))); SetIndexArrow(4,159); SetIndexLabel(4,NULL);
   SetIndexBuffer(5,ShortGlow3); SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,MathMin(3,MathMax(1,(OrbBaseSize-6)/2))); SetIndexArrow(5,159); SetIndexLabel(5,NULL);
   SetIndexBuffer(6,ExitLongBuffer);  SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,1); SetIndexArrow(6,251); SetIndexLabel(6,"Exit long");
   SetIndexBuffer(7,ExitShortBuffer); SetIndexStyle(7,DRAW_ARROW,STYLE_SOLID,1); SetIndexArrow(7,251); SetIndexLabel(7,"Exit short");
   SetIndexBuffer(8,StopBuffer);   SetIndexStyle(8,DRAW_LINE,STYLE_SOLID,1); SetIndexLabel(8,"Stop loss");
   SetIndexBuffer(9,TargetBuffer); SetIndexStyle(9,DRAW_LINE,STYLE_SOLID,1); SetIndexLabel(9,"Take profit");
   SetIndexBuffer(10,TrailBuffer); SetIndexStyle(10,DRAW_LINE,STYLE_SOLID,2); SetIndexLabel(10,"Trailing stop");
   for(int b=0;b<11;b++) SetIndexEmptyValue(b,EMPTY_VALUE);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0,PREFIX);
}

int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],const double &open[],const double &high[],
                const double &low[],const double &close[],const long &tick_volume[],
                const long &volume[],const int &spread[])
{
   int minBars=MathMax(MathMax(SMASlowLength,MACDSlowLength+MACDSignalLength),
               MathMax(34,MathMax(BollingerLength,MathMax(CCILength,MathMax(DILength+ADXSmoothing,SupertrendLength)))))+10;
   if(rates_total<minBars) return 0;

   ArrayInitialize(LongGlow1,EMPTY_VALUE); ArrayInitialize(LongGlow2,EMPTY_VALUE); ArrayInitialize(LongGlow3,EMPTY_VALUE);
   ArrayInitialize(ShortGlow1,EMPTY_VALUE); ArrayInitialize(ShortGlow2,EMPTY_VALUE); ArrayInitialize(ShortGlow3,EMPTY_VALUE);
   ArrayInitialize(ExitLongBuffer,EMPTY_VALUE); ArrayInitialize(ExitShortBuffer,EMPTY_VALUE);
   ArrayInitialize(StopBuffer,EMPTY_VALUE); ArrayInitialize(TargetBuffer,EMPTY_VALUE); ArrayInitialize(TrailBuffer,EMPTY_VALUE);

   // Combined backtester state
   int tradeState=0,totalTrades=0,winTrades=0;
   double entryPrice=0,slLevel=0,tpLevel=0,tsLevel=0;
   double netProfitPct=0,grossProfit=0,grossLoss=0;
   bool prevLong=false,prevShort=false;

   // Standalone indicator states/statistics. Explicit initializers are used
   // because MetaEditor's static analyser does not infer initialization from
   // a loop when a fixed-size local array is subsequently indexed by another
   // loop variable.
   int indState[11] = {0,0,0,0,0,0,0,0,0,0,0};
   int indTotal[11] = {0,0,0,0,0,0,0,0,0,0,0};
   int indWins[11]  = {0,0,0,0,0,0,0,0,0,0,0};
   double indEntry[11] = {0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0};
   double indSL[11]    = {0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0};
   double indTP[11]    = {0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0};
   double indTS[11]    = {0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0};
   bool indPrevBull[11] = {false,false,false,false,false,false,false,false,false,false,false};
   bool indPrevBear[11] = {false,false,false,false,false,false,false,false,false,false,false};

   bool curBull[11] = {false,false,false,false,false,false,false,false,false,false,false};
   bool curBear[11] = {false,false,false,false,false,false,false,false,false,false,false};
   bool currentLong=false,currentShort=false;

   // Custom DMI/ADX Wilder state (Pine supports separate DI and ADX lengths).
   int diCount=0,dxCount=0;
   double trRma=0,plusRma=0,minusRma=0,adxRma=0,dxSum=0;

   // Supertrend state.
   bool stReady=false;
   double prevFinalUpper=0,prevFinalLower=0,prevST=0,prevClose=0;

   // Process oldest to newest, matching Pine's bar-by-bar persistent state.
   for(int i=rates_total-2;i>=0;i--)
   {
      double atr=iATR(NULL,0,MathMax(1,ATRLength),i);
      bool bull[11],bear[11];

      double smaFast=iMA(NULL,0,MathMax(1,SMAFastLength),0,MODE_SMA,PRICE_CLOSE,i);
      double smaSlow=iMA(NULL,0,MathMax(1,SMASlowLength),0,MODE_SMA,PRICE_CLOSE,i);
      bull[0]=(smaFast>smaSlow); bear[0]=(smaFast<smaSlow);

      double rsi=iRSI(NULL,0,MathMax(1,RSILength),PRICE_CLOSE,i);
      bull[1]=(rsi>RSILongAbove); bear[1]=(rsi<RSIShortBelow);

      double macd=iMACD(NULL,0,MathMax(1,MACDFastLength),MathMax(1,MACDSlowLength),MathMax(1,MACDSignalLength),PRICE_CLOSE,MODE_MAIN,i);
      double macdSig=iMACD(NULL,0,MathMax(1,MACDFastLength),MathMax(1,MACDSlowLength),MathMax(1,MACDSignalLength),PRICE_CLOSE,MODE_SIGNAL,i);
      bull[2]=(macd>macdSig); bear[2]=(macd<macdSig);

      // TradingView-compatible Supertrend recurrence.
      double stAtr=iATR(NULL,0,MathMax(1,SupertrendLength),i);
      double basicUpper=(high[i]+low[i])*0.5+SupertrendFactor*stAtr;
      double basicLower=(high[i]+low[i])*0.5-SupertrendFactor*stAtr;
      double finalUpper=basicUpper,finalLower=basicLower,st=0;
      int stDirection=0;
      if(!stReady || stAtr<=0)
      {
         st=basicUpper; stDirection=1;
         if(stAtr>0) stReady=true;
      }
      else
      {
         finalUpper=(basicUpper<prevFinalUpper || prevClose>prevFinalUpper) ? basicUpper : prevFinalUpper;
         finalLower=(basicLower>prevFinalLower || prevClose<prevFinalLower) ? basicLower : prevFinalLower;
         if(prevST==prevFinalUpper)
            st=(close[i]>finalUpper) ? finalLower : finalUpper;
         else
            st=(close[i]<finalLower) ? finalUpper : finalLower;
         stDirection=(st==finalLower) ? -1 : 1;
      }
      prevFinalUpper=finalUpper; prevFinalLower=finalLower; prevST=st; prevClose=close[i];
      bull[3]=(stReady && stDirection==-1); bear[3]=(stReady && stDirection==1);

      double stoK=iStochastic(NULL,0,MathMax(1,StochasticKLength),MathMax(1,StochasticDLength),MathMax(1,StochasticSmooth),MODE_SMA,0,MODE_MAIN,i);
      bull[4]=(stoK>50.0); bear[4]=(stoK<50.0);

      double bbMid=iMA(NULL,0,MathMax(1,BollingerLength),0,MODE_SMA,PRICE_CLOSE,i);
      bull[5]=(close[i]>bbMid); bear[5]=(close[i]<bbMid);

      double emaFast=iMA(NULL,0,MathMax(1,EMAFastLength),0,MODE_EMA,PRICE_CLOSE,i);
      double emaSlow=iMA(NULL,0,MathMax(1,EMASlowLength),0,MODE_EMA,PRICE_CLOSE,i);
      bull[6]=(emaFast>emaSlow); bear[6]=(emaFast<emaSlow);

      double ao=iAO(NULL,0,i);
      bull[7]=(ao>0); bear[7]=(ao<0);

      double sar=iSAR(NULL,0,SARStart,SARMaximum,i); // MT4 has step/max; Pine start is normally equal to increment.
      bull[8]=(close[i]>sar); bear[8]=(close[i]<sar);

      double cci=iCCI(NULL,0,MathMax(1,CCILength),PRICE_CLOSE,i);
      bull[9]=(cci>CCILongAbove); bear[9]=(cci<CCIShortBelow);

      // DMI then ADX, using Wilder RMAs and separate lengths.
      int older=i+1;
      double tr=MathMax(high[i]-low[i],MathMax(MathAbs(high[i]-close[older]),MathAbs(low[i]-close[older])));
      double up=high[i]-high[older], down=low[older]-low[i];
      double plusDM=(up>down && up>0) ? up : 0;
      double minusDM=(down>up && down>0) ? down : 0;
      diCount++;
      if(diCount<=MathMax(1,DILength)) { trRma+=tr; plusRma+=plusDM; minusRma+=minusDM; }
      else
      {
         int dl=MathMax(1,DILength);
         trRma=trRma-trRma/dl+tr; plusRma=plusRma-plusRma/dl+plusDM; minusRma=minusRma-minusRma/dl+minusDM;
      }
      double diPlus=0,diMinus=0,adx=0;
      if(diCount>=MathMax(1,DILength) && trRma>0)
      {
         diPlus=100.0*plusRma/trRma; diMinus=100.0*minusRma/trRma;
         double denom=diPlus+diMinus;
         double dx=(denom>0) ? 100.0*MathAbs(diPlus-diMinus)/denom : 0;
         dxCount++;
         if(dxCount<=MathMax(1,ADXSmoothing)) { dxSum+=dx; if(dxCount==MathMax(1,ADXSmoothing)) adxRma=dxSum/MathMax(1,ADXSmoothing); }
         else adxRma=(adxRma*(MathMax(1,ADXSmoothing)-1)+dx)/MathMax(1,ADXSmoothing);
         if(dxCount>=MathMax(1,ADXSmoothing)) adx=adxRma;
      }
      bull[10]=(adx>ADXThreshold && diPlus>diMinus); bear[10]=(adx>ADXThreshold && diMinus>diPlus);

      // Standalone performance tracking for all eleven indicators.
      for(int j=0;j<11;j++)
      {
         bool exL=false,exS=false; double exPrice=0;
         if(indState[j]==1)
         {
            if(EnableStopLoss && low[i]<=indSL[j]) { exL=true; exPrice=indSL[j]; }
            else if(EnableTakeProfit && high[i]>=indTP[j]) { exL=true; exPrice=indTP[j]; }
            else if(EnableTrailingStop && low[i]<=indTS[j]) { exL=true; exPrice=indTS[j]; }
            else if(bear[j]) { exL=true; exPrice=close[i]; }
         }
         if(indState[j]==-1)
         {
            if(EnableStopLoss && high[i]>=indSL[j]) { exS=true; exPrice=indSL[j]; }
            else if(EnableTakeProfit && low[i]<=indTP[j]) { exS=true; exPrice=indTP[j]; }
            else if(EnableTrailingStop && high[i]>=indTS[j]) { exS=true; exPrice=indTS[j]; }
            else if(bull[j]) { exS=true; exPrice=close[i]; }
         }
         if(exL || exS)
         {
            double rr=exL ? (exPrice-indEntry[j])/indEntry[j]*100.0 : (indEntry[j]-exPrice)/indEntry[j]*100.0;
            indTotal[j]++; if(rr>0) indWins[j]++;
            indState[j]=0; indSL[j]=0; indTP[j]=0; indTS[j]=0;
         }
         bool newL=bull[j] && !indPrevBull[j] && indState[j]!=1;
         bool newS=bear[j] && !indPrevBear[j] && indState[j]!=-1;
         if(newL)
         {
            indState[j]=1; indEntry[j]=close[i];
            if(EnableStopLoss) indSL[j]=close[i]-atr*StopLossATR;
            if(EnableTakeProfit) indTP[j]=close[i]+atr*TakeProfitATR;
            if(EnableTrailingStop) indTS[j]=close[i]-atr*TrailingStopATR;
         }
         if(newS)
         {
            indState[j]=-1; indEntry[j]=close[i];
            if(EnableStopLoss) indSL[j]=close[i]+atr*StopLossATR;
            if(EnableTakeProfit) indTP[j]=close[i]-atr*TakeProfitATR;
            if(EnableTrailingStop) indTS[j]=close[i]+atr*TrailingStopATR;
         }
         if(indState[j]==1 && !newL && EnableTrailingStop) indTS[j]=MathMax(indTS[j],close[i]-atr*TrailingStopATR);
         if(indState[j]==-1 && !newS && EnableTrailingStop) indTS[j]=MathMin(indTS[j],close[i]+atr*TrailingStopATR);
         indPrevBull[j]=bull[j]; indPrevBear[j]=bear[j];
      }

      // Enabled-indicator AND/OR aggregation.
      bool lng=RequireAllEnabledIndicatorsToAlign;
      bool sht=RequireAllEnabledIndicatorsToAlign;
      bool any=false;
      bool enabled[11];
      enabled[0]=EnableSMA; enabled[1]=EnableRSI; enabled[2]=EnableMACD; enabled[3]=EnableSupertrend;
      enabled[4]=EnableStochastic; enabled[5]=EnableBollinger; enabled[6]=EnableEMA; enabled[7]=EnableAO;
      enabled[8]=EnableSAR; enabled[9]=EnableCCI; enabled[10]=EnableADX;
      for(int e=0;e<11;e++) if(enabled[e])
      {
         if(RequireAllEnabledIndicatorsToAlign) { lng=(lng && bull[e]); sht=(sht && bear[e]); }
         else { lng=(lng || bull[e]); sht=(sht || bear[e]); }
         any=true;
      }
      if(!any) { lng=false; sht=false; }

      // Exits have Pine's SL -> TP -> trailing stop -> opposite signal priority.
      bool exitL=false,exitS=false; double exitPrice=0;
      if(tradeState==1)
      {
         if(EnableStopLoss && low[i]<=slLevel) { exitL=true; exitPrice=slLevel; }
         else if(EnableTakeProfit && high[i]>=tpLevel) { exitL=true; exitPrice=tpLevel; }
         else if(EnableTrailingStop && low[i]<=tsLevel) { exitL=true; exitPrice=tsLevel; }
         else if(sht) { exitL=true; exitPrice=close[i]; }
      }
      if(tradeState==-1)
      {
         if(EnableStopLoss && high[i]>=slLevel) { exitS=true; exitPrice=slLevel; }
         else if(EnableTakeProfit && low[i]<=tpLevel) { exitS=true; exitPrice=tpLevel; }
         else if(EnableTrailingStop && high[i]>=tsLevel) { exitS=true; exitPrice=tsLevel; }
         else if(lng) { exitS=true; exitPrice=close[i]; }
      }
      if(exitL || exitS)
      {
         double ret=exitL ? (exitPrice-entryPrice)/entryPrice*100.0 : (entryPrice-exitPrice)/entryPrice*100.0;
         netProfitPct+=ret; totalTrades++;
         if(ret>0) { winTrades++; grossProfit+=ret; } else grossLoss+=MathAbs(ret);
         tradeState=0; slLevel=0; tpLevel=0; tsLevel=0;
      }

      bool enterL=lng && !prevLong && tradeState!=1;
      bool enterS=sht && !prevShort && tradeState!=-1;
      if(enterL)
      {
         tradeState=1; entryPrice=close[i];
         if(EnableStopLoss) slLevel=close[i]-atr*StopLossATR;
         if(EnableTakeProfit) tpLevel=close[i]+atr*TakeProfitATR;
         if(EnableTrailingStop) tsLevel=close[i]-atr*TrailingStopATR;
      }
      if(enterS)
      {
         tradeState=-1; entryPrice=close[i];
         if(EnableStopLoss) slLevel=close[i]+atr*StopLossATR;
         if(EnableTakeProfit) tpLevel=close[i]-atr*TakeProfitATR;
         if(EnableTrailingStop) tsLevel=close[i]+atr*TrailingStopATR;
      }
      if(tradeState==1 && !enterL && EnableTrailingStop) tsLevel=MathMax(tsLevel,close[i]-atr*TrailingStopATR);
      if(tradeState==-1 && !enterS && EnableTrailingStop) tsLevel=MathMin(tsLevel,close[i]+atr*TrailingStopATR);

      double gap=MathMax(Point*10,atr*OrbDistanceATR);
      if(enterL) { LongGlow1[i]=low[i]-gap; LongGlow2[i]=LongGlow1[i]; LongGlow3[i]=LongGlow1[i]; }
      if(enterS) { ShortGlow1[i]=high[i]+gap; ShortGlow2[i]=ShortGlow1[i]; ShortGlow3[i]=ShortGlow1[i]; }
      if(exitL && !enterS) ExitLongBuffer[i]=high[i]+MathMax(Point*5,atr*0.15);
      if(exitS && !enterL) ExitShortBuffer[i]=low[i]-MathMax(Point*5,atr*0.15);
      if(tradeState!=0 && !enterL && !enterS)
      {
         if(EnableStopLoss) StopBuffer[i]=slLevel;
         if(EnableTakeProfit) TargetBuffer[i]=tpLevel;
         if(EnableTrailingStop) TrailBuffer[i]=tsLevel;
      }

      prevLong=lng; prevShort=sht;
      if(i==0)
      {
         currentLong=lng; currentShort=sht;
         for(int q=0;q<11;q++){curBull[q]=bull[q];curBear[q]=bear[q];}
      }
   }

   if(ShowDashboards)
   {
      string names[11]; names[0]="SMA Cross"; names[1]="RSI"; names[2]="MACD"; names[3]="Supertrend"; names[4]="Stochastic";
      names[5]="Bollinger"; names[6]="EMA Cross"; names[7]="AO"; names[8]="SAR"; names[9]="CCI"; names[10]="ADX Filter";
      bool en[11]; en[0]=EnableSMA;en[1]=EnableRSI;en[2]=EnableMACD;en[3]=EnableSupertrend;en[4]=EnableStochastic;en[5]=EnableBollinger;
      en[6]=EnableEMA;en[7]=EnableAO;en[8]=EnableSAR;en[9]=EnableCCI;en[10]=EnableADX;
      string dash="INDICATOR DASHBOARD\n-------------------------------\nIndicator       Status     Enabled\n";
      for(int d=0;d<11;d++)
      {
         string wr=(indTotal[d]>0)?DoubleToString(100.0*indWins[d]/indTotal[d],1)+"%":"0.0%";
         dash+=StringFormat("%-14s %-8s %s  WR %s\n",names[d],StatusText(curBull[d],curBear[d]),OnOff(en[d]),wr);
      }
      dash+="-------------------------------\nCURRENT SIGNAL: "+(currentLong?"LONG":(currentShort?"SHORT":"NEUTRAL"));
      PutDashboard("IND",IndicatorDashboardPosition,10,10,dash);

      int losses=totalTrades-winTrades;
      double winRate=(totalTrades>0)?100.0*winTrades/totalTrades:0;
      string pf=(grossLoss>0)?DoubleToString(grossProfit/grossLoss,2):((grossProfit>0)?"MAX":"0.00");
      string perf="BACKTEST RESULTS [LuxAlgo]\n-----------------------------\n";
      perf+="Total trades : "+IntegerToString(totalTrades)+"\nWins         : "+IntegerToString(winTrades)+"\nLosses       : "+IntegerToString(losses)+"\n";
      perf+="Win rate     : "+DoubleToString(winRate,2)+"%\nProfit factor: "+pf+"\nPNL          : "+DoubleToString(netProfitPct,2)+"%";
      PutDashboard("PERF",PerformanceDashboardPosition,10,10,perf);
   }
   else ObjectsDeleteAll(0,PREFIX);

   // One alert per selected signal bar. Closed-bar mode avoids intrabar changes.
   int as=AlertOnClosedBar?1:0;
   if(EnableAlerts && rates_total>as+2 && time[as]!=lastAlertBar)
   {
      if(LongGlow1[as]!=EMPTY_VALUE) { Alert(Symbol()," ",Period(),": Signal Forge LONG"); lastAlertBar=time[as]; }
      else if(ShortGlow1[as]!=EMPTY_VALUE) { Alert(Symbol()," ",Period(),": Signal Forge SHORT"); lastAlertBar=time[as]; }
   }
   return rates_total;
}
