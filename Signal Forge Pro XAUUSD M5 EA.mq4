//+------------------------------------------------------------------+
//| Signal Forge Pro XAUUSD M5 EA - Enhanced Engine                 |
//| Based on Signal Forge [LuxAlgo]                                  |
//| Original work (c) LuxAlgo, CC BY-NC-SA 4.0                      |
//| https://creativecommons.org/licenses/by-nc-sa/4.0/               |
//|                                                                  |
//| Non-commercial ShareAlike MT4 EA port. Test on demo first.       |
//+------------------------------------------------------------------+
#property strict
#include <Canvas\Canvas.mqh>
#resource "\\Images\\SignalForgePro13\\logo.bmp"
#resource "\\Images\\SignalForgePro13\\corner.bmp"
#resource "\\Images\\SignalForgePro13\\gauge_ring.bmp"
#resource "\\Images\\SignalForgePro13\\orb_buy.bmp"
#resource "\\Images\\SignalForgePro13\\orb_sell.bmp"
#resource "\\Images\\SignalForgePro13\\orb_neutral.bmp"

//--- Trading
input int    MagicNumber       = 26051601;
input double FixedLots         = 0.01;
input int    SlippagePoints    = 50;
input int    MaximumSpreadPoints = 100;
input bool   OnePositionOnly   = true;
input bool   CloseOnOppositeSignal = true;
input bool   TradeOnClosedBar  = true;

//--- SL: selectable ATR or account-risk distance
//--- TP: selectable fixed points or ATR. There is deliberately NO R:R mode.
enum EA_SL_MODE { SL_By_ATR=0, SL_By_Risk_Percent=1 };
enum EA_TP_MODE { TP_By_Points=0, TP_By_ATR=1 };
input EA_SL_MODE StopLossMode  = SL_By_ATR;
input EA_TP_MODE TakeProfitMode= TP_By_Points;
input int    ATRLength         = 14;
input double StopLossATR       = 1.8;
input double TakeProfitATR     = 2.4;
input double TakeProfitPoints  = 5000.0;
input double RiskPercent       = 0.5;
input double RiskReferenceBalance = 0.0; // 0 = current account balance

//--- Point trailing stop (requested defaults)
input bool   EnableTrailingStop = true;
input double TrailingStartPoints = 700.0;
input double TrailingDistancePoints = 700.0;
input double TrailingStepPoints = 100.0;

//--- Enhanced weighted score aggregation (closed candles only)
input bool   UseSignalScore = true;
input double MinimumSignalScore = 5.0;
input int    SignalShift = 1;
input double SMAWeight=1.0;
input double RSIWeight=1.0;
input double MACDWeight=1.0;
input double SupertrendWeight=1.0;
input double StochasticWeight=1.0;
input double BollingerWeight=1.0;
input double EMAWeight=1.0;
input double AOWeight=1.0;
input double SARWeight=1.0;
input double CCIWeight=1.0;
input double ADXWeight=1.0;

//--- ATR-relative strong-candle confirmation
input bool   UseCandleConfirmation = true;
input int    MinimumCandleScore = 3;
input double MinBodyATR = 0.50;
input double MinBodyPercent = 60.0;
input double MinCloseLocation = 75.0;
input double MinRangeATR = 0.80;
input bool   UseVolumeConfirmation = false;
input int    VolumeLookback = 20;
input double VolumeMultiplier = 1.20;

//--- Enhanced risk and protection
input bool   UseRiskPercentLot = false;
input bool   UseMaximumMoneyRisk = true;
input double MaximumRiskPerTradeMoney = 12.00; // practical Exness 0.01-lot cap; lower values can reject every ATR trade
input double RiskSafetyBufferPercent = 5.0;    // reserves part of the selected money-risk ceiling
input double MaximumLotLimit = 1.00;
input double MinimumMarginLevelPercent = 150.0;
input bool   UseMinimumRiskRewardFilter = false;
input double MinimumRiskReward = 1.00;
input bool   UseBreakEven = true;
input double BreakEvenStartPoints = 400.0;
input double BreakEvenOffsetPoints = 50.0;
input bool   UseTradingSession = false;
input bool   UseNewsFilter = false; // no reliable native MT4 calendar; enabling blocks entries safely
input int    SessionStartHour = 0;
input int    SessionStartMinute = 0;
input int    SessionEndHour = 23;
input int    SessionEndMinute = 59;
input bool   StopTradingAfterDailyLoss = true;
input double MaximumDailyLossMoney = 10.0;
input double MaximumDailyLossPercent = 10.0;
input bool   StopTradingAfterConsecutiveLosses = true;
input int    MaximumConsecutiveLosses = 3;
input bool   CloseTradesOnDailyLoss = false;
input bool   UseRiskRewardTP = false;
input double RiskRewardRatio = 2.0;

//--- XAUUSD M5 conservative filter preset
input bool EnableSMA = true;
input int  SMAFastLength = 9;
input int  SMASlowLength = 30;
input bool EnableRSI = true;
input int  RSILength = 14;
input double RSILongAbove = 52.0;
input double RSIShortBelow = 48.0;
input bool EnableMACD = true;
input int  MACDFastLength = 8;
input int  MACDSlowLength = 21;
input int  MACDSignalLength = 5;
input bool EnableSupertrend = true;
input double SupertrendFactor = 2.5;
input int  SupertrendLength = 10;
input bool EnableStochastic = true;
input int  StochasticKLength = 14;
input int  StochasticDLength = 3;
input int  StochasticSmooth = 3;
input bool EnableBollinger = true;
input int  BollingerLength = 20;
input bool EnableEMA = true;
input int  EMAFastLength = 9;
input int  EMASlowLength = 21;
input bool EnableAO = true;
input bool EnableSAR = true;
input double SARStep = 0.02;
input double SARMaximum = 0.2;
input bool EnableCCI = true;
input int  CCILength = 20;
input double CCILongAbove = 50.0;
input double CCIShortBelow = -50.0;
input bool EnableADX = true;
input int  ADXPeriod = 14;
input double ADXThreshold = 22.0;

//--- Display
enum EA_CORNER { EA_Top_Right=0, EA_Bottom_Right=1, EA_Bottom_Left=2, EA_Top_Left=3 };
enum FILTER_PANEL_MODE { Show_All_Filters=0, Show_Activated_Filters_Only=1 };
input bool ApplyProfessionalChartTheme = true;
input bool ShowDashboard = true;
input bool UseOption13SapphireBitmapSkin = true;
input bool ShowLeftPanel = true;
input bool ShowRightPanel = true;
input bool ShowBottomPanel = true;
input bool AutoSizeDashboard = true;
input int  MinimumVisibleChartWidth = 300;
input bool ShowProtectionResetButton = true;
input int  LeftPanelWidth = 580;
input int  LeftPanelHeight = 370;
input int  RightPanelWidth = 470;
input int  RightPanelHeight = 370;
input int  BottomPanelWidth = 600;
input int  BottomPanelHeight = 220;
input int  LeftMargin = 15;
input int  RightMargin = 15;
input int  TopMargin = 20;
input int  BottomMargin = 20;
input int  PositionPanelStackGap = 10;
input int  EquityPositionGap = 10;
input int  PanelFontSize = 8;
input int  ValueFontSize = 9;
input double DailyProfitTargetDisplay = 30.0; // dashboard reference only; does not affect trading
input color PanelBackground = C'11,16,32';
input color PanelBorder = C'48,67,94';
input color HeaderColor = C'17,31,52';
input color TextColor = C'245,247,250';
input color SecondaryTextColor = C'148,163,184';
input color AccentColor = C'0,229,255';
input color ProfitColor = C'0,230,118';
input color LossColor = C'255,82,82';
input color WarningColor = C'255,193,7';
input color NeutralColor = C'100,116,139';
input bool KeepVisualsAfterBacktest = true;
input bool ShowAccountProfitPanel = false; // legacy panel disabled by modern three-panel UI
input int  AccountPanelX = 10;
input int  AccountPanelY = 10;
input EA_CORNER SignalPanelPosition = EA_Top_Right;
input EA_CORNER PerformancePanelPosition = EA_Bottom_Right;
input FILTER_PANEL_MODE InitialFilterPanelMode = Show_Activated_Filters_Only;
// Independent chart-drawing defaults. These affect visuals only and do not
// enable or disable an indicator in the trading signal calculation.
input bool DrawSMAOnChart         = false;
input bool DrawRSIOnChart         = false;
input bool DrawMACDOnChart        = false;
input bool DrawSupertrendOnChart  = true;
input bool DrawStochasticOnChart  = false;
input bool DrawBollingerOnChart   = false;
input bool DrawEMAOnChart         = false;
input bool DrawAOOnChart          = false;
input bool DrawSAROnChart         = false;
input bool DrawCCIOnChart         = false;
input bool DrawADXOnChart         = false;
input int  FilterDrawingBars = 150;
input bool DrawBuySellSignalOrbs = true;
input int  SignalHistoryBars = 300;
input int  SignalCircleSize = 16;
input int  SignalCircleShadowSize = 1;
input int  SignalLetterFontSize = 12;
input int DashboardFontSize = 9;
input bool ShowEquityCurve = true; // lower management panel automatically reserves this canvas area
input int  EquityCurveX = 10;
input int  EquityCurveY = 10;
input int  EquityCurveHeight = 126;
input bool DrawEntrySLTPLines = true;
input bool   DrawClosedTradeResults = true;
input bool   DetailedResultCards = true;
input int  MaximumResultBoxes = 50;
input int  ResultBoxPaddingPixels = 8;
input int  ResultCardCandleGapPixels = 20;
input bool MoveResultCardsEveryTick = true;
input int  ResultMovementRefreshMs = 100; // fallback when every-tick mode is off

string PREFIX="SF_EA_";
datetime gLastBar=0;
datetime gLastProcessedSignalCandle=0;
bool gBull[11],gBear[11];
bool gLongSignal=false,gShortSignal=false;
double gBuyScore=0,gSellScore=0;
int gCandleScore=0;
bool gVolumePassed=true;
string gLastAction="EA INITIALIZED";
bool gShowEnabledOnly=false;
bool gDrawFilter[11];
CCanvas gEquityCanvas;
bool gEquityCanvasReady=false;
int gEquityCanvasWidth=0,gEquityCanvasHeight=0;
int gEquityChartHeight=0,gEquityHistoryTotal=-1;
int gKnownResultHistory=-1;
int gLastResultCleanupHistory=-1;
bool gChartLayoutDirty=false;
bool gLegacyDashboardCleared=false;
uint gLastChartResultRefresh=0;
// Incremental Supertrend cache: after one seed pass, only one bar is
// calculated per new candle instead of replaying 600 bars twice.
bool gSTReady=false;
double gSTUpper=0,gSTLower=0,gSTLine=0,gSTClose=0;
int gSTDirection=0,gSTPreviousDirection=0;
datetime gSTTime=0,gSTPreviousTime=0;
datetime gSignalHistoryBuiltBar=0;
// Cached account/trade tracker statistics; rebuilt only when history/day changes.
int gTrackerHistory=-1,gTrackerTrades=0,gTrackerWins=0;
int gPersistentSyncHistory=-1;
datetime gTrackerDay=0;
double gTrackerGrossProfit=0,gTrackerGrossLoss=0,gTrackerMaxDD=0;
double gTrackerDaily=0,gTrackerWeekly=0,gTrackerMonthly=0,gTrackerTotal=0;
double gTrackerDayProfit[5],gTrackerDayLots[5],gTrackerDayGross[5],gTrackerDayCommission[5];
datetime gProtectionResetTime=0;
bool gShowProfitTracker=false;
string FILTER_BUTTON_NAME="SF_EA_SIG_FILTER_BUTTON";
string RESET_BUTTON_NAME="",TRACKER_BUTTON_NAME="";
string gBuyOrbResource="",gSellOrbResource="";

int ResponsiveRightPanelWidth(int chartWidth)
{
   int available=chartWidth-LeftMargin-RightMargin-20;
   return (int)MathMin(MathMax(400,RightPanelWidth),available*0.45);
}

int ResponsiveRightPanelLeft(int chartWidth)
{
   return chartWidth-RightMargin-ResponsiveRightPanelWidth(chartWidth);
}

//+------------------------------------------------------------------+
int CornerValue(EA_CORNER p)
{
   if(p==EA_Top_Right) return CORNER_RIGHT_UPPER;
   if(p==EA_Bottom_Right) return CORNER_RIGHT_LOWER;
   if(p==EA_Bottom_Left) return CORNER_LEFT_LOWER;
   return CORNER_LEFT_UPPER;
}

void DrawPanel(string group,EA_CORNER pos,int x,int y,int width,int height)
{
   string n=PREFIX+group+"_PANEL";
   if(ObjectFind(0,n)<0) ObjectCreate(0,n,OBJ_RECTANGLE_LABEL,0,0,0);
   bool right=(pos==EA_Top_Right || pos==EA_Bottom_Right);
   bool bottom=(pos==EA_Bottom_Right || pos==EA_Bottom_Left);
   ObjectSetInteger(0,n,OBJPROP_CORNER,CornerValue(pos));
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,right?x+width:x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,bottom?y+height:y);
   ObjectSetInteger(0,n,OBJPROP_XSIZE,width);
   ObjectSetInteger(0,n,OBJPROP_YSIZE,height);
   ObjectSetInteger(0,n,OBJPROP_BGCOLOR,C'8,14,26');
   ObjectSetInteger(0,n,OBJPROP_COLOR,C'90,105,255');
   ObjectSetInteger(0,n,OBJPROP_BORDER_TYPE,BORDER_RAISED);
   ObjectSetInteger(0,n,OBJPROP_BACK,false);
   ObjectSetInteger(0,n,OBJPROP_ZORDER,100);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,n,OBJPROP_HIDDEN,true);
}

void DrawCell(string group,string id,EA_CORNER pos,
              int panelX,int panelY,int panelW,int panelH,
              int left,int top,int width,int height,string text,
              color textColor,color bgColor,int fontSize)
{
   bool right=(pos==EA_Top_Right || pos==EA_Bottom_Right);
   bool bottom=(pos==EA_Bottom_Right || pos==EA_Bottom_Left);
   int corner=CornerValue(pos);
   int rx=right?panelX+panelW-left:panelX+left;
   int ry=bottom?panelY+panelH-top:panelY+top;
   string r=PREFIX+group+"_C_"+id;
   if(ObjectFind(0,r)<0) ObjectCreate(0,r,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,r,OBJPROP_CORNER,corner);
   ObjectSetInteger(0,r,OBJPROP_XDISTANCE,rx);
   ObjectSetInteger(0,r,OBJPROP_YDISTANCE,ry);
   ObjectSetInteger(0,r,OBJPROP_XSIZE,width);
   ObjectSetInteger(0,r,OBJPROP_YSIZE,height);
   ObjectSetInteger(0,r,OBJPROP_BGCOLOR,bgColor);
   ObjectSetInteger(0,r,OBJPROP_COLOR,C'80,95,125');
   ObjectSetInteger(0,r,OBJPROP_BORDER_TYPE,BORDER_RAISED);
   ObjectSetInteger(0,r,OBJPROP_BACK,false);
   ObjectSetInteger(0,r,OBJPROP_ZORDER,101);
   ObjectSetInteger(0,r,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,r,OBJPROP_HIDDEN,true);

   int tx=right?panelX+panelW-left-width/2:panelX+left+width/2;
   int ty=bottom?panelY+panelH-top-height/2:panelY+top+height/2;
   string l=PREFIX+group+"_T_"+id;
   if(ObjectFind(0,l)<0) ObjectCreate(0,l,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,l,OBJPROP_CORNER,corner);
   ObjectSetInteger(0,l,OBJPROP_ANCHOR,ANCHOR_CENTER);
   ObjectSetInteger(0,l,OBJPROP_XDISTANCE,tx);
   ObjectSetInteger(0,l,OBJPROP_YDISTANCE,ty);
   ObjectSetInteger(0,l,OBJPROP_COLOR,textColor);
   ObjectSetInteger(0,l,OBJPROP_FONTSIZE,fontSize);
   ObjectSetString(0,l,OBJPROP_FONT,"Arial Bold");
   ObjectSetString(0,l,OBJPROP_TEXT,text);
   ObjectSetInteger(0,l,OBJPROP_ZORDER,102);
   ObjectSetInteger(0,l,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,l,OBJPROP_HIDDEN,true);
}

void DrawFilterToggle(EA_CORNER pos,int panelX,int panelY,int panelW,int panelH,
                      int left,int top,int width,int height)
{
   bool right=(pos==EA_Top_Right || pos==EA_Bottom_Right);
   bool bottom=(pos==EA_Bottom_Right || pos==EA_Bottom_Left);
   int x=right?panelX+panelW-left:panelX+left;
   int y=bottom?panelY+panelH-top:panelY+top;
   if(ObjectFind(0,FILTER_BUTTON_NAME)<0) ObjectCreate(0,FILTER_BUTTON_NAME,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,FILTER_BUTTON_NAME,OBJPROP_CORNER,CornerValue(pos));
   ObjectSetInteger(0,FILTER_BUTTON_NAME,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,FILTER_BUTTON_NAME,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,FILTER_BUTTON_NAME,OBJPROP_XSIZE,width);
   ObjectSetInteger(0,FILTER_BUTTON_NAME,OBJPROP_YSIZE,height);
   ObjectSetInteger(0,FILTER_BUTTON_NAME,OBJPROP_BGCOLOR,gShowEnabledOnly?C'0,105,80':C'44,63,105');
   ObjectSetInteger(0,FILTER_BUTTON_NAME,OBJPROP_COLOR,C'255,255,255');
   ObjectSetInteger(0,FILTER_BUTTON_NAME,OBJPROP_BORDER_COLOR,C'100,180,255');
   ObjectSetInteger(0,FILTER_BUTTON_NAME,OBJPROP_FONTSIZE,MathMax(7,DashboardFontSize-1));
   ObjectSetString(0,FILTER_BUTTON_NAME,OBJPROP_FONT,"Arial Bold");
   ObjectSetString(0,FILTER_BUTTON_NAME,OBJPROP_TEXT,gShowEnabledOnly?"ACTIVE ONLY":"ALL FILTERS");
   ObjectSetInteger(0,FILTER_BUTTON_NAME,OBJPROP_STATE,false);
   ObjectSetInteger(0,FILTER_BUTTON_NAME,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,FILTER_BUTTON_NAME,OBJPROP_HIDDEN,true);
}

bool IsTradingFilterEnabled(int index)
{
   if(index==0)return EnableSMA;if(index==1)return EnableRSI;if(index==2)return EnableMACD;
   if(index==3)return EnableSupertrend;if(index==4)return EnableStochastic;if(index==5)return EnableBollinger;
   if(index==6)return EnableEMA;if(index==7)return EnableAO;if(index==8)return EnableSAR;
   if(index==9)return EnableCCI;if(index==10)return EnableADX;
   return false;
}

void DrawPerFilterButton(int index,EA_CORNER pos,int panelX,int panelY,int panelW,int panelH,
                         int left,int top,int width,int height)
{
   string name=PREFIX+"FILTER_DRAW_"+IntegerToString(index);
   bool right=(pos==EA_Top_Right || pos==EA_Bottom_Right);
   bool bottom=(pos==EA_Bottom_Right || pos==EA_Bottom_Left);
   int x=right?panelX+panelW-left:panelX+left;
   int y=bottom?panelY+panelH-top:panelY+top;
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_BUTTON,0,0,0);
   bool active=IsTradingFilterEnabled(index);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CornerValue(pos));
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,width);ObjectSetInteger(0,name,OBJPROP_YSIZE,height);
   // Only active trading filters can be drawn. Blue means shown, gold means
   // manually hidden, and gray identifies an inactive filter.
   color bg=!active?C'55,60,72':(gDrawFilter[index]?C'0,125,215':C'170,100,0');
   color border=!active?C'105,112,128':(gDrawFilter[index]?C'105,215,255':C'255,205,70');
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,name,OBJPROP_COLOR,C'255,255,255');
   ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,border);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,MathMax(7,DashboardFontSize-1));
   ObjectSetString(0,name,OBJPROP_FONT,"Arial Black");
   ObjectSetString(0,name,OBJPROP_TEXT,!active?"INACTIVE":(gDrawFilter[index]?"SHOWN":"HIDDEN"));
   ObjectSetInteger(0,name,OBJPROP_STATE,false);ObjectSetInteger(0,name,OBJPROP_SELECTABLE,active);
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);ObjectSetInteger(0,name,OBJPROP_ZORDER,110);
}

void DeleteSignalRow(string id)
{
   string parts[3]={"N","S","E"};
   for(int i=0;i<3;i++)
   {
      ObjectDelete(0,PREFIX+"SIG_C_"+parts[i]+id);
      ObjectDelete(0,PREFIX+"SIG_T_"+parts[i]+id);
   }
   ObjectDelete(0,PREFIX+"FILTER_DRAW_"+id);
}

void BuildSupertrendSeries(int maxShift,int &dirs[],double &lines[])
{
   ArrayResize(dirs,maxShift+1);ArrayResize(lines,maxShift+1);
   ArrayInitialize(dirs,0);ArrayInitialize(lines,EMPTY_VALUE);
   bool ready=false;double prevUpper=0,prevLower=0,prevLine=0,prevClose=0;
   int oldest=MathMin(Bars-2,maxShift+600);
   for(int i=oldest;i>=0;i--)
   {
      double atr=iATR(NULL,0,MathMax(1,SupertrendLength),i);
      double upper=(High[i]+Low[i])*0.5+SupertrendFactor*atr;
      double lower=(High[i]+Low[i])*0.5-SupertrendFactor*atr;
      double finalUpper=upper,finalLower=lower,line=upper;int direction=1;
      if(!ready || atr<=0){if(atr>0)ready=true;}
      else
      {
         finalUpper=(upper<prevUpper || prevClose>prevUpper)?upper:prevUpper;
         finalLower=(lower>prevLower || prevClose<prevLower)?lower:prevLower;
         if(prevLine==prevUpper)line=(Close[i]>finalUpper)?finalLower:finalUpper;
         else line=(Close[i]<finalLower)?finalUpper:finalLower;
         direction=(line==finalLower)?-1:1;
      }
      prevUpper=finalUpper;prevLower=finalLower;prevLine=line;prevClose=Close[i];
      if(i<=maxShift){dirs[i]=ready?direction:0;lines[i]=ready?line:EMPTY_VALUE;}
   }
}

void PlotFilterSegment(int filter,int line,int shift,double olderValue,double newerValue,color c,int width)
{
   string name=PREFIX+"FILTER_PLOT_"+IntegerToString(filter)+"_"+IntegerToString(line)+"_"+IntegerToString(shift);
   if(ObjectFind(0,name)<0)ObjectCreate(0,name,OBJ_TREND,0,Time[shift+1],olderValue,Time[shift],newerValue);
   ObjectMove(0,name,0,Time[shift+1],olderValue);ObjectMove(0,name,1,Time[shift],newerValue);
   ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,false);ObjectSetInteger(0,name,OBJPROP_COLOR,c);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,width);ObjectSetInteger(0,name,OBJPROP_BACK,true);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,1);ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
}

double OscillatorValue(int filter,int line,int shift)
{
   if(filter==1)return iRSI(NULL,0,RSILength,PRICE_CLOSE,shift);
   if(filter==2)return iMACD(NULL,0,MACDFastLength,MACDSlowLength,MACDSignalLength,PRICE_CLOSE,line==0?MODE_MAIN:MODE_SIGNAL,shift);
   if(filter==4)return iStochastic(NULL,0,StochasticKLength,StochasticDLength,StochasticSmooth,MODE_SMA,0,line==0?MODE_MAIN:MODE_SIGNAL,shift);
   if(filter==7)return iAO(NULL,0,shift);
   if(filter==9)return iCCI(NULL,0,CCILength,PRICE_CLOSE,shift);
   if(filter==10)return iADX(NULL,0,ADXPeriod,PRICE_CLOSE,line==0?MODE_MAIN:(line==1?MODE_PLUSDI:MODE_MINUSDI),shift);
   return 0;
}

void UpdateFilterChartDrawings()
{
   int bars=MathMax(10,MathMin(FilterDrawingBars,Bars-3));
   int stDir[];double stLine[];
   if(EnableSupertrend && gDrawFilter[3])BuildSupertrendSeries(bars+1,stDir,stLine);
   double chartMin=WindowPriceMin(),chartMax=WindowPriceMax();
   double bandLow=chartMin+(chartMax-chartMin)*0.05;
   double bandHigh=chartMin+(chartMax-chartMin)*0.22;
   for(int filter=0;filter<11;filter++)
   {
      ObjectsDeleteAll(0,PREFIX+"FILTER_PLOT_"+IntegerToString(filter)+"_");
      ObjectDelete(0,PREFIX+"FILTER_CHART_"+IntegerToString(filter)); // old text-only drawing
      // The Pro chart is intentionally Supertrend-only. Enforce this here,
      // independent of any old MT4 input preset retained by the terminal.
      if(filter!=3)continue;
      if(!EnableSupertrend || !gDrawFilter[3])continue;
      if(filter==0 || filter==6)
      {
         int method=(filter==0)?MODE_SMA:MODE_EMA;
         int fast=(filter==0)?SMAFastLength:EMAFastLength;
         int slow=(filter==0)?SMASlowLength:EMASlowLength;
         for(int s=bars;s>=1;s--)
         {
            PlotFilterSegment(filter,0,s,iMA(NULL,0,fast,0,method,PRICE_CLOSE,s+1),iMA(NULL,0,fast,0,method,PRICE_CLOSE,s),C'0,255,190',2);
            PlotFilterSegment(filter,1,s,iMA(NULL,0,slow,0,method,PRICE_CLOSE,s+1),iMA(NULL,0,slow,0,method,PRICE_CLOSE,s),C'255,170,40',2);
         }
      }
      else if(filter==3)
      {
         for(int s=bars;s>=1;s--)if(stLine[s]!=EMPTY_VALUE && stLine[s+1]!=EMPTY_VALUE)
            PlotFilterSegment(filter,0,s,stLine[s+1],stLine[s],stDir[s]==-1?C'0,255,170':C'255,64,96',2);
      }
      else if(filter==5)
      {
         for(int s=bars;s>=1;s--)for(int line=0;line<3;line++)
         {
            int mode=line==0?MODE_UPPER:(line==1?MODE_MAIN:MODE_LOWER);
            double old=iBands(NULL,0,BollingerLength,2.0,0,PRICE_CLOSE,mode,s+1),now=iBands(NULL,0,BollingerLength,2.0,0,PRICE_CLOSE,mode,s);
            PlotFilterSegment(filter,line,s,old,now,line==1?C'255,210,60':C'80,145,255',1);
         }
      }
      else if(filter==8)
      {
         for(int s=bars;s>=1;s--)
         {
            string name=PREFIX+"FILTER_PLOT_8_0_"+IntegerToString(s);double sar=iSAR(NULL,0,SARStep,SARMaximum,s);
            if(ObjectFind(0,name)<0)ObjectCreate(0,name,OBJ_ARROW,0,Time[s],sar);
            ObjectMove(0,name,0,Time[s],sar);ObjectSetInteger(0,name,OBJPROP_ARROWCODE,159);ObjectSetInteger(0,name,OBJPROP_WIDTH,1);
            ObjectSetInteger(0,name,OBJPROP_COLOR,Close[s]>sar?C'0,255,170':C'255,64,96');ObjectSetInteger(0,name,OBJPROP_BACK,true);
         }
      }
      else
      {
         int lineCount=(filter==2||filter==4)?2:(filter==10?3:1);
         double rawMin=1e100,rawMax=-1e100;
         if(filter==1||filter==4||filter==10){rawMin=0;rawMax=100;}
         else if(filter==9){rawMin=-200;rawMax=200;}
         else for(int s=1;s<=bars+1;s++){double v=OscillatorValue(filter,0,s);rawMin=MathMin(rawMin,v);rawMax=MathMax(rawMax,v);}
         if(rawMax-rawMin<0.000001){rawMax+=1;rawMin-=1;}
         for(int line=0;line<lineCount;line++)for(int s=bars;s>=1;s--)
         {
            double old=OscillatorValue(filter,line,s+1),now=OscillatorValue(filter,line,s);
            old=MathMax(rawMin,MathMin(rawMax,old));now=MathMax(rawMin,MathMin(rawMax,now));
            double mappedOld=bandLow+(old-rawMin)/(rawMax-rawMin)*(bandHigh-bandLow);
            double mappedNow=bandLow+(now-rawMin)/(rawMax-rawMin)*(bandHigh-bandLow);
            color lc=line==0?C'80,155,255':(line==1?C'255,190,40':C'255,64,140');
            PlotFilterSegment(filter,line,s,mappedOld,mappedNow,lc,line==0?2:1);
         }
      }
   }
}

void CreateSignalOrbResource(bool buy)
{
   int side=MathMax(24,SignalCircleSize*2);
   int center=side/2;double radius=center-1;
   int shadow=MathMax(1,MathMin(3,SignalCircleShadowSize));
   uint pixels[];ArrayResize(pixels,side*side);ArrayInitialize(pixels,0);
   uint outer=ColorToARGB(buy?C'0,62,52':C'85,12,30',255);
   uint main=ColorToARGB(buy?C'0,225,145':C'235,42,76',255);
   uint light=ColorToARGB(buy?C'80,255,205':C'255,120,145',255);
   for(int y=0;y<side;y++)for(int x=0;x<side;x++)
   {
      double dx=x-center+0.5,dy=y-center+0.5,d=MathSqrt(dx*dx+dy*dy);
      if(d<=radius)
      {
         uint value=(d>radius-shadow)?outer:main;
         if(d>radius-shadow-1 && x<center && y<center)value=light;
         pixels[y*side+x]=value;
      }
   }
   string pattern[7];
   if(buy)
   {
      pattern[0]="11110";pattern[1]="10001";pattern[2]="10001";pattern[3]="11110";
      pattern[4]="10001";pattern[5]="10001";pattern[6]="11110";
   }
   else
   {
      pattern[0]="01111";pattern[1]="10000";pattern[2]="10000";pattern[3]="01110";
      pattern[4]="00001";pattern[5]="00001";pattern[6]="11110";
   }
   // A two-pixel raster stroke keeps the letter crisp and leaves balanced
   // space inside the circle; the earlier three-pixel glyph looked distorted.
   int scale=MathMax(1,MathMin(3,SignalLetterFontSize/6));
   int startX=(side-5*scale)/2,startY=(side-7*scale)/2;
   uint white=ColorToARGB(C'255,255,255',255);
   for(int row=0;row<7;row++)for(int col=0;col<5;col++)if(StringSubstr(pattern[row],col,1)=="1")
      for(int py=0;py<scale;py++)for(int px=0;px<scale;px++)
      {
         int drawX=startX+col*scale+px,drawY=startY+row*scale+py;
         if(drawX>=0&&drawX<side&&drawY>=0&&drawY<side)pixels[drawY*side+drawX]=white;
      }
   string resource=buy?gBuyOrbResource:gSellOrbResource;
   ResourceFree(resource);
   if(!ResourceCreate(resource,pixels,side,side,0,0,side,COLOR_FORMAT_ARGB_NORMALIZE))
      Print("Signal orb resource error: ",GetLastError());
}

void DrawSignalOrb(bool buy,int shift)
{
   datetime when=Time[shift];double atr=iATR(NULL,0,MathMax(1,ATRLength),shift);
   double price=buy?Low[shift]-atr*0.65:High[shift]+atr*0.65;
   string id=IntegerToString((int)when)+(buy?"_B":"_S");string base=PREFIX+"SIGNAL_ORB_"+id;
   color vivid=buy?C'0,255,170':C'255,64,96';
   string bitmap=base+"_BMP",link=base+"_LINK";
   // Remove legacy separate circle/text objects. The replacement is one
   // bitmap, so the B/S pixels can never drift outside the circle.
   ObjectDelete(0,base+"_OUT");ObjectDelete(0,base+"_IN");ObjectDelete(0,base+"_TXT");
   if(ObjectFind(0,bitmap)<0)ObjectCreate(0,bitmap,OBJ_BITMAP,0,when,price);
   ObjectMove(0,bitmap,0,when,price);
   ObjectSetString(0,bitmap,OBJPROP_BMPFILE,0,buy?gBuyOrbResource:gSellOrbResource);
   ObjectSetInteger(0,bitmap,OBJPROP_ANCHOR,ANCHOR_CENTER);
   // Signal bitmap and connector remain behind every foreground dashboard and
   // the opaque equity canvas, while still visible in the chart area.
   ObjectSetInteger(0,bitmap,OBJPROP_BACK,true);ObjectSetInteger(0,bitmap,OBJPROP_ZORDER,0);
   ObjectSetInteger(0,bitmap,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,bitmap,OBJPROP_HIDDEN,true);
   double candlePoint=buy?Low[shift]:High[shift];
   if(ObjectFind(0,link)<0)ObjectCreate(0,link,OBJ_TREND,0,when,candlePoint,when,price);
   ObjectMove(0,link,0,when,candlePoint);ObjectMove(0,link,1,when,price);
   ObjectSetInteger(0,link,OBJPROP_RAY_RIGHT,false);ObjectSetInteger(0,link,OBJPROP_STYLE,STYLE_DOT);ObjectSetInteger(0,link,OBJPROP_COLOR,vivid);
   ObjectSetInteger(0,link,OBJPROP_BACK,true);ObjectSetInteger(0,link,OBJPROP_ZORDER,1);ObjectSetInteger(0,link,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,link,OBJPROP_HIDDEN,true);
}

void HistoricalConditions(int shift,int supertrendDirection,bool &bull[],bool &bear[])
{
   double a=iMA(NULL,0,SMAFastLength,0,MODE_SMA,PRICE_CLOSE,shift),b=iMA(NULL,0,SMASlowLength,0,MODE_SMA,PRICE_CLOSE,shift);
   bull[0]=a>b;bear[0]=a<b;
   double r=iRSI(NULL,0,RSILength,PRICE_CLOSE,shift);bull[1]=r>RSILongAbove;bear[1]=r<RSIShortBelow;
   double m=iMACD(NULL,0,MACDFastLength,MACDSlowLength,MACDSignalLength,PRICE_CLOSE,MODE_MAIN,shift);
   double ms=iMACD(NULL,0,MACDFastLength,MACDSlowLength,MACDSignalLength,PRICE_CLOSE,MODE_SIGNAL,shift);bull[2]=m>ms;bear[2]=m<ms;
   bull[3]=supertrendDirection==-1;bear[3]=supertrendDirection==1;
   double k=iStochastic(NULL,0,StochasticKLength,StochasticDLength,StochasticSmooth,MODE_SMA,0,MODE_MAIN,shift);bull[4]=k>50;bear[4]=k<50;
   double mid=iMA(NULL,0,BollingerLength,0,MODE_SMA,PRICE_CLOSE,shift);bull[5]=Close[shift]>mid;bear[5]=Close[shift]<mid;
   double ef=iMA(NULL,0,EMAFastLength,0,MODE_EMA,PRICE_CLOSE,shift),es=iMA(NULL,0,EMASlowLength,0,MODE_EMA,PRICE_CLOSE,shift);bull[6]=ef>es;bear[6]=ef<es;
   double ao=iAO(NULL,0,shift);bull[7]=ao>0;bear[7]=ao<0;
   double sar=iSAR(NULL,0,SARStep,SARMaximum,shift);bull[8]=Close[shift]>sar;bear[8]=Close[shift]<sar;
   double cci=iCCI(NULL,0,CCILength,PRICE_CLOSE,shift);bull[9]=cci>CCILongAbove;bear[9]=cci<CCIShortBelow;
   double adx=iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_MAIN,shift),dp=iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_PLUSDI,shift),dm=iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_MINUSDI,shift);
   bull[10]=adx>ADXThreshold&&dp>dm;bear[10]=adx>ADXThreshold&&dm>dp;
}

void DrawHistoricalSignalOrbs()
{
   if(!DrawBuySellSignalOrbs||gSignalHistoryBuiltBar!=0)return;
   double savedBuy=gBuyScore,savedSell=gSellScore;int savedCandle=gCandleScore;bool savedVolume=gVolumePassed;
   int maximum=(int)MathMax(10,MathMin(SignalHistoryBars,Bars-3));
   int dirs[];double lines[];BuildSupertrendSeries(maximum+1,dirs,lines);
   for(int shift=maximum;shift>=1;shift--)
   {
      bool bull[11],bear[11];HistoricalConditions(shift,dirs[shift],bull,bear);
      bool lng=false,sht=false;CombinedSignal(bull,bear,lng,sht);int direction=lng?1:(sht?-1:0);
      if(direction==0)continue;
      int candle=CandleConfirmationScore(shift,direction);
      if(UseCandleConfirmation&&candle<MinimumCandleScore)continue;
      DrawSignalOrb(direction>0,shift);
   }
   gBuyScore=savedBuy;gSellScore=savedSell;gCandleScore=savedCandle;gVolumePassed=savedVolume;
   gSignalHistoryBuiltBar=Time[0];
}

color StatusColor(bool bull,bool bear)
{
   if(bull) return C'0,255,170';
   if(bear) return C'255,64,96';
   return C'255,214,64';
}
string StatusText(bool bull,bool bear)
{
   if(bull) return "BULLISH";
   if(bear) return "BEARISH";
   return "NEUTRAL";
}

void ApplyChartTheme()
{
   if(!ApplyProfessionalChartTheme) return;
   ChartSetInteger(0,CHART_MODE,CHART_CANDLES);
   ChartSetInteger(0,CHART_SHOW_GRID,false);
   ChartSetInteger(0,CHART_COLOR_BACKGROUND,C'7,11,19');
   ChartSetInteger(0,CHART_COLOR_FOREGROUND,C'180,195,220');
   ChartSetInteger(0,CHART_COLOR_GRID,C'24,32,48');
   ChartSetInteger(0,CHART_COLOR_CHART_UP,C'0,225,190');
   ChartSetInteger(0,CHART_COLOR_CHART_DOWN,C'255,64,85');
   ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,C'0,225,190');
   ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,C'255,64,85');
   ChartSetInteger(0,CHART_COLOR_BID,C'90,180,255');
   ChartSetInteger(0,CHART_COLOR_ASK,C'255,90,120');
   ChartSetInteger(0,CHART_COLOR_STOP_LEVEL,C'255,210,65');
   ChartSetInteger(0,CHART_SHOW_OHLC,true);
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
void AdvanceSupertrend(int shift)
{
   double atr=iATR(NULL,0,MathMax(1,SupertrendLength),shift);
   double upper=(High[shift]+Low[shift])*0.5+SupertrendFactor*atr;
   double lower=(High[shift]+Low[shift])*0.5-SupertrendFactor*atr;
   double finalUpper=upper,finalLower=lower,st=upper;
   int direction=1;
   if(!gSTReady || atr<=0)
   {
      if(atr>0) gSTReady=true;
   }
   else
   {
      finalUpper=(upper<gSTUpper || gSTClose>gSTUpper)?upper:gSTUpper;
      finalLower=(lower>gSTLower || gSTClose<gSTLower)?lower:gSTLower;
      if(gSTLine==gSTUpper) st=(Close[shift]>finalUpper)?finalLower:finalUpper;
      else st=(Close[shift]<finalLower)?finalUpper:finalLower;
      direction=(st==finalLower)?-1:1;
   }
   gSTPreviousTime=gSTTime;
   gSTPreviousDirection=gSTDirection;
   gSTUpper=finalUpper;gSTLower=finalLower;gSTLine=st;gSTClose=Close[shift];
   gSTDirection=gSTReady?direction:0;
   gSTTime=Time[shift];
}

int SupertrendDirection(int shift)
{
   if(Time[shift]==gSTTime) return gSTDirection;
   if(Time[shift]==gSTPreviousTime) return gSTPreviousDirection;
   // Normal sequential tester/live path: advance only the newly closed bar.
   if(gSTTime!=0 && shift+1<Bars && Time[shift+1]==gSTTime)
   {
      AdvanceSupertrend(shift);
      return gSTDirection;
   }
   // First call or a history/timeframe jump: seed once from older history.
   gSTReady=false;gSTUpper=0;gSTLower=0;gSTLine=0;gSTClose=0;
   gSTDirection=0;gSTPreviousDirection=0;gSTTime=0;gSTPreviousTime=0;
   int oldest=MathMin(Bars-2,shift+600);
   for(int i=oldest;i>=shift;i--) AdvanceSupertrend(i);
   return gSTDirection;
}

void GetConditions(int shift,bool &bull[],bool &bear[])
{
   double a=iMA(NULL,0,MathMax(1,SMAFastLength),0,MODE_SMA,PRICE_CLOSE,shift);
   double b=iMA(NULL,0,MathMax(1,SMASlowLength),0,MODE_SMA,PRICE_CLOSE,shift);
   bull[0]=(a>b); bear[0]=(a<b);
   double r=iRSI(NULL,0,MathMax(1,RSILength),PRICE_CLOSE,shift);
   bull[1]=(r>RSILongAbove); bear[1]=(r<RSIShortBelow);
   double m=iMACD(NULL,0,MACDFastLength,MACDSlowLength,MACDSignalLength,PRICE_CLOSE,MODE_MAIN,shift);
   double s=iMACD(NULL,0,MACDFastLength,MACDSlowLength,MACDSignalLength,PRICE_CLOSE,MODE_SIGNAL,shift);
   bull[2]=(m>s); bear[2]=(m<s);
   int sd=SupertrendDirection(shift); bull[3]=(sd==-1); bear[3]=(sd==1);
   double k=iStochastic(NULL,0,StochasticKLength,StochasticDLength,StochasticSmooth,MODE_SMA,0,MODE_MAIN,shift);
   bull[4]=(k>50); bear[4]=(k<50);
   double mid=iMA(NULL,0,BollingerLength,0,MODE_SMA,PRICE_CLOSE,shift);
   bull[5]=(Close[shift]>mid); bear[5]=(Close[shift]<mid);
   double ef=iMA(NULL,0,EMAFastLength,0,MODE_EMA,PRICE_CLOSE,shift);
   double es=iMA(NULL,0,EMASlowLength,0,MODE_EMA,PRICE_CLOSE,shift);
   bull[6]=(ef>es); bear[6]=(ef<es);
   double ao=iAO(NULL,0,shift); bull[7]=(ao>0); bear[7]=(ao<0);
   double sar=iSAR(NULL,0,SARStep,SARMaximum,shift); bull[8]=(Close[shift]>sar); bear[8]=(Close[shift]<sar);
   double cci=iCCI(NULL,0,CCILength,PRICE_CLOSE,shift); bull[9]=(cci>CCILongAbove); bear[9]=(cci<CCIShortBelow);
   double adx=iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_MAIN,shift);
   double dp=iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_PLUSDI,shift);
   double dm=iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_MINUSDI,shift);
   bull[10]=(adx>ADXThreshold && dp>dm); bear[10]=(adx>ADXThreshold && dm>dp);
}

void CombinedSignal(bool &bull[],bool &bear[],bool &lng,bool &sht)
{
   bool enabled[11];double weight[11];
   enabled[0]=EnableSMA;enabled[1]=EnableRSI;enabled[2]=EnableMACD;enabled[3]=EnableSupertrend;
   enabled[4]=EnableStochastic;enabled[5]=EnableBollinger;enabled[6]=EnableEMA;enabled[7]=EnableAO;
   enabled[8]=EnableSAR;enabled[9]=EnableCCI;enabled[10]=EnableADX;
   weight[0]=SMAWeight;weight[1]=RSIWeight;weight[2]=MACDWeight;weight[3]=SupertrendWeight;
   weight[4]=StochasticWeight;weight[5]=BollingerWeight;weight[6]=EMAWeight;weight[7]=AOWeight;
   weight[8]=SARWeight;weight[9]=CCIWeight;weight[10]=ADXWeight;
   gBuyScore=0;gSellScore=0;
   for(int i=0;i<11;i++)if(enabled[i]&&weight[i]>0)
   {
      if(bull[i])gBuyScore+=weight[i];
      if(bear[i])gSellScore+=weight[i];
   }
   lng=UseSignalScore&&gBuyScore>=MinimumSignalScore&&gBuyScore>gSellScore;
   sht=UseSignalScore&&gSellScore>=MinimumSignalScore&&gSellScore>gBuyScore;
}

bool VolumeConfirmation(int shift)
{
   if(!UseVolumeConfirmation)return true;
   int lookback=(int)MathMax(1,VolumeLookback);double average=0;
   for(int i=shift+1;i<=shift+lookback;i++)average+=(double)iVolume(NULL,0,i);
   average/=lookback;
   return average>0&&(double)iVolume(NULL,0,shift)>=average*VolumeMultiplier;
}

int CandleConfirmationScore(int shift,int direction)
{
   double atr=iATR(NULL,0,MathMax(1,ATRLength),shift);
   double body=MathAbs(Close[shift]-Open[shift]),range=High[shift]-Low[shift];
   gVolumePassed=VolumeConfirmation(shift);
   if(atr<=0||range<=0)return 0;
   if((direction>0&&Close[shift]<=Open[shift])||(direction<0&&Close[shift]>=Open[shift]))return 0;
   int score=0;
   if(body/atr>=MinBodyATR)score++;
   if(body/range*100.0>=MinBodyPercent)score++;
   double location=direction>0?(Close[shift]-Low[shift])/range*100.0:(High[shift]-Close[shift])/range*100.0;
   if(location>=MinCloseLocation)score++;
   if(range/atr>=MinRangeATR)score++;
   if(UseVolumeConfirmation&&gVolumePassed)score++;
   return score;
}

//+------------------------------------------------------------------+
int LotPrecision()
{
   double step=MarketInfo(Symbol(),MODE_LOTSTEP);
   if(step>=1)return 0;if(step>=0.1)return 1;if(step>=0.01)return 2;if(step>=0.001)return 3;return 4;
}

double NormalizeLots(double lots)
{
   double minLot=MarketInfo(Symbol(),MODE_MINLOT),maxLot=MarketInfo(Symbol(),MODE_MAXLOT),step=MarketInfo(Symbol(),MODE_LOTSTEP);
   if(step<=0)step=0.01;
   lots=MathMin(maxLot,MathFloor((lots+1e-10)/step)*step);
   if(lots<minLot-1e-10)return 0;
   return NormalizeDouble(lots,LotPrecision());
}

double BrokerTickSizePrice()
{
   double tickSize=MarketInfo(Symbol(),MODE_TICKSIZE);
   if(tickSize<=0)return Point;
   if(tickSize>=1.0)tickSize*=Point;
   return tickSize;
}

double MoneyRiskAtStop(double lots,double entry,double sl)
{
   double tickSize=BrokerTickSizePrice(),tickValue=MarketInfo(Symbol(),MODE_TICKVALUE);
   if(lots<=0||tickSize<=0||tickValue<=0)return -1;
   return MathAbs(entry-sl)/tickSize*tickValue*lots;
}

double RiskStopDistance(double lots)
{
   double balance=(RiskReferenceBalance>0)?RiskReferenceBalance:AccountBalance();
   double money=balance*MathMax(0.0,RiskPercent)/100.0;
   double tickSize=BrokerTickSizePrice(),tickValue=MarketInfo(Symbol(),MODE_TICKVALUE);
   if(money<=0||tickValue<=0||lots<=0)return 0;
   return MathMax(Point,money*tickSize/(lots*tickValue));
}

double RiskAdjustedLots(double requested,double entry,double sl,double &moneyRisk)
{
   double riskPerLot=MoneyRiskAtStop(1.0,entry,sl);
   if(riskPerLot<=0){moneyRisk=-1;return 0;}
   double lots=UseRiskPercentLot?(AccountBalance()*MathMax(0,RiskPercent)/100.0)/riskPerLot:requested;
   double safetyFactor=1.0-MathMax(0,MathMin(95,RiskSafetyBufferPercent))/100.0;
   if(UseMaximumMoneyRisk&&MaximumRiskPerTradeMoney>0)lots=MathMin(lots,MaximumRiskPerTradeMoney*safetyFactor/riskPerLot);
   if(MaximumLotLimit>0)lots=MathMin(lots,MaximumLotLimit);
   lots=NormalizeLots(lots);
   if(lots<=0)
   {
      double minLot=MarketInfo(Symbol(),MODE_MINLOT);moneyRisk=riskPerLot*minLot;
      return 0;
   }
   moneyRisk=riskPerLot*lots;
   return lots;
}

int ActiveTicket(int &type)
{
   type=-1;
   for(int i=OrdersTotal()-1;i>=0;i--) if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
   {
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber && (OrderType()==OP_BUY || OrderType()==OP_SELL))
      { type=OrderType(); return OrderTicket(); }
   }
   return -1;
}

bool CloseActivePosition()
{
   bool allClosed=true;
   for(int i=OrdersTotal()-1;i>=0;i--) if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
   {
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=MagicNumber) continue;
      RefreshRates();
      bool ok=false;
      if(OrderType()==OP_BUY) ok=OrderClose(OrderTicket(),OrderLots(),Bid,SlippagePoints,C'255,80,100');
      if(OrderType()==OP_SELL) ok=OrderClose(OrderTicket(),OrderLots(),Ask,SlippagePoints,C'0,240,180');
      if(!ok) { Print("Signal Forge close failed: ",GetLastError()); allClosed=false; }
   }
   return allClosed;
}

bool OpenPosition(int type)
{
   if(!IsTradeAllowed()){gLastAction="BLOCKED: TRADE NOT ALLOWED";return false;}
   RefreshRates();double spread=(Ask-Bid)/Point;
   if(MaximumSpreadPoints>0&&spread>MaximumSpreadPoints){gLastAction="BLOCKED: SPREAD "+DoubleToString(spread,0)+" PTS";return false;}
   double entry=type==OP_BUY?Ask:Bid,atr=iATR(NULL,0,MathMax(1,ATRLength),MathMax(1,SignalShift));
   double provisionalLots=MathMax(MarketInfo(Symbol(),MODE_MINLOT),FixedLots);
   double slDistance=StopLossMode==SL_By_Risk_Percent?RiskStopDistance(provisionalLots):atr*MathMax(0.1,StopLossATR);
   double minimum=(MathMax(MarketInfo(Symbol(),MODE_STOPLEVEL),MarketInfo(Symbol(),MODE_FREEZELEVEL))+2)*Point;
   slDistance=MathMax(slDistance,minimum);
   double sl=NormalizeDouble(type==OP_BUY?entry-slDistance:entry+slDistance,Digits);
   double tpDistance=TakeProfitMode==TP_By_Points?MathMax(Point,TakeProfitPoints*Point):atr*MathMax(0.1,TakeProfitATR);
   double tp=UseRiskRewardTP?(type==OP_BUY?entry+slDistance*RiskRewardRatio:entry-slDistance*RiskRewardRatio):(type==OP_BUY?entry+MathMax(tpDistance,minimum):entry-MathMax(tpDistance,minimum));
   tp=NormalizeDouble(tp,Digits);
   double plannedRR=slDistance>0?MathAbs(tp-entry)/slDistance:0;
   if(UseMinimumRiskRewardFilter&&plannedRR<MinimumRiskReward){gLastAction="BLOCKED: R:R "+DoubleToString(plannedRR,2);return false;}
   if(AccountMargin()>0&&MinimumMarginLevelPercent>0&&AccountEquity()/AccountMargin()*100.0<MinimumMarginLevelPercent){gLastAction="BLOCKED: MARGIN LEVEL";return false;}
   double moneyRisk=0,lots=RiskAdjustedLots(FixedLots,entry,sl,moneyRisk);
   if(lots<=0){gLastAction="BLOCKED: MIN LOT RISK $"+DoubleToString(moneyRisk,2);Print(gLastAction);return false;}
   if(AccountFreeMarginCheck(Symbol(),type,lots)<=0){gLastAction="BLOCKED: FREE MARGIN";Print(gLastAction," Error=",GetLastError());return false;}
   // Immediate final spread check before OrderSend.
   RefreshRates();spread=(Ask-Bid)/Point;
   if(MaximumSpreadPoints>0&&spread>MaximumSpreadPoints){gLastAction="BLOCKED: FINAL SPREAD";return false;}
   entry=type==OP_BUY?Ask:Bid;sl=NormalizeDouble(type==OP_BUY?entry-slDistance:entry+slDistance,Digits);
   tp=UseRiskRewardTP?(type==OP_BUY?entry+slDistance*RiskRewardRatio:entry-slDistance*RiskRewardRatio):(type==OP_BUY?entry+MathMax(tpDistance,minimum):entry-MathMax(tpDistance,minimum));tp=NormalizeDouble(tp,Digits);
   moneyRisk=MoneyRiskAtStop(lots,entry,sl);
   if(UseMaximumMoneyRisk&&MaximumRiskPerTradeMoney>0&&moneyRisk>MaximumRiskPerTradeMoney+0.01){gLastAction="BLOCKED: RISK CHANGED";return false;}
   string comment=type==OP_BUY?"Signal Forge Pro BUY":"Signal Forge Pro SELL";color arrow=type==OP_BUY?C'0,255,170':C'255,64,96';
   ResetLastError();int ticket=OrderSend(Symbol(),type,lots,entry,SlippagePoints,sl,tp,comment,MagicNumber,0,arrow);
   int firstError=GetLastError();
   if(ticket<0&&firstError==130)
   {
      RefreshRates();entry=type==OP_BUY?Ask:Bid;ResetLastError();ticket=OrderSend(Symbol(),type,lots,entry,SlippagePoints,0,0,comment,MagicNumber,0,arrow);
      if(ticket>0&&OrderSelect(ticket,SELECT_BY_TICKET))
      {
         sl=NormalizeDouble(type==OP_BUY?OrderOpenPrice()-slDistance:OrderOpenPrice()+slDistance,Digits);
         tp=UseRiskRewardTP?(type==OP_BUY?OrderOpenPrice()+slDistance*RiskRewardRatio:OrderOpenPrice()-slDistance*RiskRewardRatio):(type==OP_BUY?OrderOpenPrice()+MathMax(tpDistance,minimum):OrderOpenPrice()-MathMax(tpDistance,minimum));tp=NormalizeDouble(tp,Digits);
         ResetLastError();if(!OrderModify(ticket,OrderOpenPrice(),sl,tp,0,arrow))
         {
            int modifyError=GetLastError();Print("ECN protection modify failed. Error=",modifyError," Ticket=",ticket," SL=",DoubleToString(sl,Digits)," TP=",DoubleToString(tp,Digits));
            RefreshRates();if(!OrderClose(ticket,OrderLots(),type==OP_BUY?Bid:Ask,SlippagePoints,arrow))Print("Emergency close failed. Error=",GetLastError()," Ticket=",ticket);
            return false;
         }
      }
   }
   if(ticket<0){int err=GetLastError();gLastAction="ORDER ERROR "+IntegerToString(err);Print("OrderSend failed. Error=",err," Symbol=",Symbol()," Lots=",DoubleToString(lots,LotPrecision())," Price=",DoubleToString(entry,Digits)," SL=",DoubleToString(sl,Digits)," TP=",DoubleToString(tp,Digits)," Spread=",DoubleToString(spread,1));return false;}
   GlobalVariableSet("SFP.ISL."+IntegerToString(AccountNumber())+"."+IntegerToString(MagicNumber)+"."+IntegerToString(ticket),sl);
   gLastAction=(type==OP_BUY?"BUY":"SELL")+" OPENED | RISK $"+DoubleToString(moneyRisk,2);
   return true;
}

datetime ProtectionPeriodStart()
{
   datetime day=StrToTime(TimeToString(TimeCurrent(),TIME_DATE));
   return (gProtectionResetTime>=day&&gProtectionResetTime<=TimeCurrent())?gProtectionResetTime:day;
}

string ProtectionResetKey()
{
   return "SFP.RESET."+IntegerToString(AccountNumber())+"."+IntegerToString(MagicNumber)+"."+Symbol();
}

string ProcessedSignalKey()
{
   return "SFP.SIGNAL."+IntegerToString(AccountNumber())+"."+IntegerToString(MagicNumber)+"."+Symbol()+"."+IntegerToString(Period());
}

double ClosedPLFrom(datetime start)
{
   double total=0;
   for(int i=OrdersHistoryTotal()-1;i>=0;i--)if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
      if(OrderSymbol()==Symbol()&&OrderMagicNumber()==MagicNumber&&(OrderType()==OP_BUY||OrderType()==OP_SELL)&&OrderCloseTime()>=start)total+=OrderProfit()+OrderSwap()+OrderCommission();
   return total;
}

double TodayClosedPL(){return ClosedPLFrom(StrToTime(TimeToString(TimeCurrent(),TIME_DATE)));}
double ProtectionClosedPL(){return ClosedPLFrom(ProtectionPeriodStart());}

int CurrentConsecutiveLosses()
{
   int losses=0;
   for(int i=OrdersHistoryTotal()-1;i>=0;i--)if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
   {
      if(OrderSymbol()!=Symbol()||OrderMagicNumber()!=MagicNumber||(OrderType()!=OP_BUY&&OrderType()!=OP_SELL))continue;
      if(OrderCloseTime()<ProtectionPeriodStart())break;
      double result=OrderProfit()+OrderSwap()+OrderCommission();if(result<0)losses++;else if(result>0)break;
   }
   return losses;
}

bool SessionAllowed()
{
   if(!UseTradingSession)return true;
   int now=TimeHour(TimeCurrent())*60+TimeMinute(TimeCurrent());
   int start=SessionStartHour*60+SessionStartMinute,finish=SessionEndHour*60+SessionEndMinute;
   if(start<=finish)return now>=start&&now<=finish;
   return now>=start||now<=finish;
}

bool DailyLossReached()
{
   if(!StopTradingAfterDailyLoss)return false;
   double daily=ProtectionClosedPL(),loss=MathMax(0,-daily),dayStartBalance=AccountBalance()-daily;
   return (MaximumDailyLossMoney>0&&loss>=MaximumDailyLossMoney)||(MaximumDailyLossPercent>0&&dayStartBalance>0&&loss/dayStartBalance*100.0>=MaximumDailyLossPercent);
}

bool ProtectionAllowsEntry()
{
   if(UseNewsFilter){gLastAction="BLOCKED: NEWS FILTER HAS NO NATIVE DATA";return false;}
   if(!SessionAllowed()){gLastAction="BLOCKED: SESSION";return false;}
   if(DailyLossReached()){gLastAction="BLOCKED: DAILY LOSS";return false;}
   if(StopTradingAfterConsecutiveLosses&&MaximumConsecutiveLosses>0&&CurrentConsecutiveLosses()>=MaximumConsecutiveLosses){gLastAction="BLOCKED: LOSS STREAK";return false;}
   return true;
}

void ManageBreakEven()
{
   if(!UseBreakEven)return;double minimum=(MathMax(MarketInfo(Symbol(),MODE_STOPLEVEL),MarketInfo(Symbol(),MODE_FREEZELEVEL))+1)*Point;
   for(int i=OrdersTotal()-1;i>=0;i--)if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
   {
      if(OrderSymbol()!=Symbol()||OrderMagicNumber()!=MagicNumber)continue;RefreshRates();
      if(OrderType()==OP_BUY&&(Bid-OrderOpenPrice())/Point>=BreakEvenStartPoints)
      {
         double next=NormalizeDouble(MathMin(OrderOpenPrice()+BreakEvenOffsetPoints*Point,Bid-minimum),Digits);
         if(next>OrderOpenPrice()&&(OrderStopLoss()==0||next>OrderStopLoss()))if(!OrderModify(OrderTicket(),OrderOpenPrice(),next,OrderTakeProfit(),0,C'0,255,170'))Print("Break-even BUY error: ",GetLastError());
      }
      if(OrderType()==OP_SELL&&(OrderOpenPrice()-Ask)/Point>=BreakEvenStartPoints)
      {
         double next=NormalizeDouble(MathMax(OrderOpenPrice()-BreakEvenOffsetPoints*Point,Ask+minimum),Digits);
         if(next<OrderOpenPrice()&&(OrderStopLoss()==0||next<OrderStopLoss()))if(!OrderModify(OrderTicket(),OrderOpenPrice(),next,OrderTakeProfit(),0,C'0,255,170'))Print("Break-even SELL error: ",GetLastError());
      }
   }
}

void EnforceDailyLossClose()
{
   if(!CloseTradesOnDailyLoss||!DailyLossReached())return;
   for(int i=OrdersTotal()-1;i>=0;i--)if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
   {
      if(OrderSymbol()!=Symbol()||OrderMagicNumber()!=MagicNumber||(OrderType()!=OP_BUY&&OrderType()!=OP_SELL))continue;
      RefreshRates();if(!OrderClose(OrderTicket(),OrderLots(),OrderType()==OP_BUY?Bid:Ask,SlippagePoints,C'255,64,96'))Print("Daily-loss close error: ",GetLastError());
   }
}

void ManageTrailing()
{
   if(!EnableTrailingStop) return;
   double start=MathMax(0,TrailingStartPoints)*Point;
   double distance=MathMax(1,TrailingDistancePoints)*Point;
   double step=MathMax(1,TrailingStepPoints)*Point;
   double minStop=(MarketInfo(Symbol(),MODE_STOPLEVEL)+1)*Point;
   for(int i=OrdersTotal()-1;i>=0;i--) if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
   {
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=MagicNumber) continue;
      RefreshRates();
      if(OrderType()==OP_BUY && Bid-OrderOpenPrice()>=start)
      {
         double next=NormalizeDouble(Bid-MathMax(distance,minStop),Digits);
         if((OrderStopLoss()==0 || next-OrderStopLoss()>=step) && next>OrderOpenPrice())
            if(!OrderModify(OrderTicket(),OrderOpenPrice(),next,OrderTakeProfit(),0,C'41,150,255')) Print("Trailing BUY error: ",GetLastError());
      }
      if(OrderType()==OP_SELL && OrderOpenPrice()-Ask>=start)
      {
         double next=NormalizeDouble(Ask+MathMax(distance,minStop),Digits);
         if((OrderStopLoss()==0 || OrderStopLoss()-next>=step) && next<OrderOpenPrice())
            if(!OrderModify(OrderTicket(),OrderOpenPrice(),next,OrderTakeProfit(),0,C'41,150,255')) Print("Trailing SELL error: ",GetLastError());
      }
   }
}

void SetTradeLine(string id,double price,color c,int style,int width,string description)
{
   string n=PREFIX+"LINE_"+id;
   if(price<=0) { ObjectDelete(0,n); return; }
   if(ObjectFind(0,n)<0) ObjectCreate(0,n,OBJ_HLINE,0,0,price);
   ObjectSetDouble(0,n,OBJPROP_PRICE1,price);
   ObjectSetInteger(0,n,OBJPROP_COLOR,c);
   ObjectSetInteger(0,n,OBJPROP_STYLE,style);
   ObjectSetInteger(0,n,OBJPROP_WIDTH,width);
   ObjectSetString(0,n,OBJPROP_TEXT,description);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,n,OBJPROP_HIDDEN,true);
}

void DrawTradeLines()
{
   if(!DrawEntrySLTPLines) { ObjectDelete(0,PREFIX+"LINE_ENTRY");ObjectDelete(0,PREFIX+"LINE_SL");ObjectDelete(0,PREFIX+"LINE_TP"); return; }
   int type; int ticket=ActiveTicket(type);
   if(ticket<0 || !OrderSelect(ticket,SELECT_BY_TICKET))
   { SetTradeLine("ENTRY",0,clrNONE,0,1,"");SetTradeLine("SL",0,clrNONE,0,1,"");SetTradeLine("TP",0,clrNONE,0,1,""); return; }
   SetTradeLine("ENTRY",OrderOpenPrice(),C'80,170,255',STYLE_DASH,1,"ENTRY #"+IntegerToString(ticket));
   SetTradeLine("SL",OrderStopLoss(),C'255,64,96',STYLE_SOLID,2,"STOP LOSS #"+IntegerToString(ticket));
   SetTradeLine("TP",OrderTakeProfit(),C'0,255,170',STYLE_SOLID,2,"TAKE PROFIT #"+IntegerToString(ticket));
}

void EnsureResultCardObject(string name,int type)
{
   if(ObjectFind(0,name)>=0 && (int)ObjectGetInteger(0,name,OBJPROP_TYPE)!=type)
      ObjectDelete(0,name);
}

void ResultCardRow(string rect,string label,int x,int y,int width,int height,
                   string text,color bg,color border,int fontSize,int padding)
{
   EnsureResultCardObject(rect,OBJ_RECTANGLE_LABEL);
   if(ObjectFind(0,rect)<0) ObjectCreate(0,rect,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,rect,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,rect,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,rect,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,rect,OBJPROP_XSIZE,width);
   ObjectSetInteger(0,rect,OBJPROP_YSIZE,height);
   ObjectSetInteger(0,rect,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,rect,OBJPROP_COLOR,border);
   ObjectSetInteger(0,rect,OBJPROP_BORDER_TYPE,BORDER_RAISED);
   // Result cards stay behind all dashboard/equity panels.
   ObjectSetInteger(0,rect,OBJPROP_BACK,true);
   ObjectSetInteger(0,rect,OBJPROP_ZORDER,0);
   ObjectSetInteger(0,rect,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,rect,OBJPROP_HIDDEN,true);

   EnsureResultCardObject(label,OBJ_LABEL);
   if(ObjectFind(0,label)<0) ObjectCreate(0,label,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,label,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,label,OBJPROP_ANCHOR,ANCHOR_LEFT);
   ObjectSetInteger(0,label,OBJPROP_XDISTANCE,x+padding);
   ObjectSetInteger(0,label,OBJPROP_YDISTANCE,y+height/2);
   ObjectSetInteger(0,label,OBJPROP_COLOR,C'255,255,255');
   ObjectSetInteger(0,label,OBJPROP_FONTSIZE,fontSize);
   ObjectSetString(0,label,OBJPROP_FONT,"Consolas Bold");
   ObjectSetString(0,label,OBJPROP_TEXT,text);
   ObjectSetInteger(0,label,OBJPROP_BACK,true);
   ObjectSetInteger(0,label,OBJPROP_ZORDER,0);
   ObjectSetInteger(0,label,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,label,OBJPROP_HIDDEN,true);
}

string SignedValue(double value,int digits)
{
   return (value>=0?"+":"")+DoubleToString(value,digits);
}

bool PixelBoxesOverlap(int x1,int y1,int w1,int h1,int x2,int y2,int w2,int h2)
{
   return (x1<x2+w2+3 && x1+w1+3>x2 && y1<y2+h2+3 && y1+h1+3>y2);
}

void MoveResultObjectOffscreen(string name)
{
   if(ObjectFind(0,name)>=0)
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,100000);
}

void HideResultCardOffscreen(string base)
{
   // Use direct runtime calls—no aggregate string initializer is involved.
   MoveResultObjectOffscreen(base+"MAIN");
   MoveResultObjectOffscreen(base+"SUB");
   MoveResultObjectOffscreen(base+"TITLE");
   MoveResultObjectOffscreen(base+"DETAIL");
   MoveResultObjectOffscreen(base+"EXTRA");MoveResultObjectOffscreen(base+"EXTRA_TEXT");
   MoveResultObjectOffscreen(base+"FEES");MoveResultObjectOffscreen(base+"FEES_TEXT");
   ObjectDelete(0,base+"LINK_V");
   ObjectDelete(0,base+"LINK_H");
}

void DottedResultLink(string name,datetime t1,double p1,datetime t2,double p2,color c)
{
   EnsureResultCardObject(name,OBJ_TREND);
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_TREND,0,t1,p1,t2,p2);
   ObjectMove(0,name,0,t1,p1);ObjectMove(0,name,1,t2,p2);
   ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_DOT);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,1);
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,0);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
}

int ResultCandleBoundaryY(int cardLeft,int cardWidth,int closeShift,bool above,int fallbackY)
{
   int sub1=0,sub2=0;datetime time1=0,time2=0;double price1=0,price2=0;
   if(!ChartXYToTimePrice(0,cardLeft,fallbackY,sub1,time1,price1) ||
      !ChartXYToTimePrice(0,cardLeft+cardWidth,fallbackY,sub2,time2,price2)) return fallbackY;
   int shift1=iBarShift(Symbol(),Period(),time1,false);
   int shift2=iBarShift(Symbol(),Period(),time2,false);
   if(shift1<0 || shift2<0) return fallbackY;
   int first=MathMax(0,MathMin(shift1,shift2)-1);
   int last=MathMin(Bars-1,MathMax(shift1,shift2)+1);
   first=MathMin(first,closeShift);last=MathMax(last,closeShift);
   double boundary=above?High[first]:Low[first];int boundaryShift=first;
   for(int i=first+1;i<=last;i++)
   {
      if(above && High[i]>boundary){boundary=High[i];boundaryShift=i;}
      if(!above && Low[i]<boundary){boundary=Low[i];boundaryShift=i;}
   }
   int px=0,py=fallbackY;
   if(!ChartTimePriceToXY(0,0,Time[boundaryShift],boundary,px,py)) return fallbackY;
   return py;
}

void DrawOneClosedResult(int &usedX[],int &usedY[],int &usedW[],int &usedH[],int &usedCount)
{
   int ticket=OrderTicket();
   datetime closeTime=OrderCloseTime();
   if(ticket<=0 || closeTime<=0) return;
   string base=PREFIX+"RESULT_"+IntegerToString(ticket)+"_";

   // Remove objects created by the previous time/price rectangle version.
   ObjectDelete(0,base+"MAIN_EDGE");
   ObjectDelete(0,base+"SUB_EDGE");

   int anchorX=0,anchorY=0;
   if(!ChartTimePriceToXY(0,0,closeTime,OrderClosePrice(),anchorX,anchorY))
   {
      // Preserve object creation order but move off-chart cards out of view;
      // otherwise they remain frozen at the edge when the chart scrolls.
      HideResultCardOffscreen(base);
      return;
   }

   double net=OrderProfit()+OrderSwap()+OrderCommission();
   bool won=(net>0);
   double points=(OrderType()==OP_BUY)?(OrderClosePrice()-OrderOpenPrice())/Point:(OrderOpenPrice()-OrderClosePrice())/Point;
   string side=(OrderType()==OP_BUY)?"BUY ":"SELL ";
   string headline=(won?"WIN  ":"LOSS  ")+SignedValue(net,2);
   string detail=side+DoubleToString(OrderLots(),2)+"  "+SignedValue(MathRound(points),0)+" pts";
   string initialKey="SFP.ISL."+IntegerToString(AccountNumber())+"."+IntegerToString(MagicNumber)+"."+IntegerToString(ticket);
   double initialSL=GlobalVariableCheck(initialKey)?GlobalVariableGet(initialKey):OrderStopLoss();
   double initialDistance=initialSL>0?MathAbs(OrderOpenPrice()-initialSL):0;
   double rMultiple=initialDistance>0?((OrderType()==OP_BUY?OrderClosePrice()-OrderOpenPrice():OrderOpenPrice()-OrderClosePrice())/initialDistance):0;
   string extra="E "+DoubleToString(OrderOpenPrice(),Digits)+"  X "+DoubleToString(OrderClosePrice(),Digits)+"  R "+SignedValue(rMultiple,2);
   string fees="SL "+DoubleToString(initialSL,Digits)+" TP "+DoubleToString(OrderTakeProfit(),Digits)+" C "+SignedValue(OrderCommission(),2)+" N "+SignedValue(net,2);

   int mainFont=MathMax(8,DashboardFontSize);
   int subFont=MathMax(7,DashboardFontSize-1);
   int padding=MathMax(5,ResultBoxPaddingPixels);
   // Consolas is monospaced. This sizing keeps both strings inside the card
   // and avoids the oversized chart-time rectangles used previously.
   int charPixels=MathMax(6,(mainFont*7)/10);
   int longest=MathMax(StringLen(headline),StringLen(detail));
   if(DetailedResultCards)longest=MathMax(longest,MathMax(StringLen(extra),StringLen(fees)));
   int width=longest*charPixels+padding*2+4;
   int mainHeight=mainFont+14;
   int subHeight=subFont+12;
   int extraHeight=DetailedResultCards?subFont+11:0;
   int feesHeight=DetailedResultCards?subFont+11:0;
   int height=mainHeight+subHeight+extraHeight+feesHeight;

   long chartWidth=0,chartHeight=0;
   ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0,chartWidth);
   ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0,chartHeight);
   // ChartTimePriceToXY can return true for a time/price that has already
   // scrolled beyond the visible viewport. Never clamp such a card to an edge.
   if(anchorX<0 || anchorX>(int)chartWidth || anchorY<0 || anchorY>(int)chartHeight)
   {
      HideResultCardOffscreen(base);
      return;
   }
   // BUY results stay above all candles covered by the card. SELL results
   // stay below them. The boundary is recalculated every tick while scrolling.
   bool placeAbove=(OrderType()==OP_BUY);
   int closeShift=iBarShift(Symbol(),Period(),closeTime,false);
   if(closeShift<0) closeShift=0;
   int left=anchorX+16;
   if(left+width>(int)chartWidth-8) left=anchorX-width-16;
   left=MathMax(8,MathMin(left,(int)chartWidth-width-8));
   int associatedX=anchorX,associatedY=anchorY;
   double associatedBoundary=placeAbove?High[closeShift]:Low[closeShift];
   ChartTimePriceToXY(0,0,Time[closeShift],associatedBoundary,associatedX,associatedY);
   int candleBoundaryY=ResultCandleBoundaryY(left,width,closeShift,placeAbove,associatedY);
   int candleGap=MathMax(8,ResultCardCandleGapPixels);
   int top=placeAbove?(candleBoundaryY-candleGap-height):(candleBoundaryY+candleGap);
   top=MathMax(8,MathMin(top,(int)chartHeight-height-8));

   // BUY cards stack farther upward; SELL cards stack farther downward. If the
   // chart edge prevents that movement, use a neighboring horizontal slot.
   for(int pass=0;pass<100;pass++)
   {
      bool moved=false;
      for(int i=0;i<usedCount;i++)
      {
         if(!PixelBoxesOverlap(left,top,width,height,usedX[i],usedY[i],usedW[i],usedH[i])) continue;
         int candidate=placeAbove?(usedY[i]-height-5):(usedY[i]+usedH[i]+5);
         if(candidate>=8 && candidate+height<=(int)chartHeight-8) top=candidate;
         else
         {
            int right=usedX[i]+usedW[i]+5;
            int leftSide=usedX[i]-width-5;
            if(right+width<=(int)chartWidth-8) left=right;
            else if(leftSide>=8) left=leftSide;
            else top=placeAbove?8:(int)chartHeight-height-8;
         }
         moved=true;
         break;
      }
      if(!moved) break;
   }
   // Recheck the candle envelope after any horizontal collision shift.
   candleBoundaryY=ResultCandleBoundaryY(left,width,closeShift,placeAbove,associatedY);
   int safeTop=placeAbove?(candleBoundaryY-candleGap-height):(candleBoundaryY+candleGap);
   top=placeAbove?MathMin(top,safeTop):MathMax(top,safeTop);
   top=MathMax(8,MathMin(top,(int)chartHeight-height-8));

   color mainBg=won?C'0,82,185':C'145,20,48';
   color subBg=won?C'0,124,230':C'210,32,68';
   color border=won?C'90,205,255':C'255,115,135';
   color linkColor=won?C'55,205,255':C'255,90,115';

   // Dotted L connector: exact close -> vertical knee -> nearest card edge.
   int kneeY=top+height/2;
   int edgeX=(left>=anchorX)?left:left+width;
   int kneeSub=0,edgeSub=0;datetime kneeTime=0,edgeTime=0;double kneePrice=0,edgePrice=0;
   if(ChartXYToTimePrice(0,anchorX,kneeY,kneeSub,kneeTime,kneePrice) &&
      ChartXYToTimePrice(0,edgeX,kneeY,edgeSub,edgeTime,edgePrice))
   {
      DottedResultLink(base+"LINK_V",closeTime,OrderClosePrice(),kneeTime,kneePrice,linkColor);
      DottedResultLink(base+"LINK_H",kneeTime,kneePrice,edgeTime,edgePrice,linkColor);
   }
   else {ObjectDelete(0,base+"LINK_V");ObjectDelete(0,base+"LINK_H");}
   ResultCardRow(base+"MAIN",base+"TITLE",left,top,width,mainHeight,headline,mainBg,border,mainFont,padding);
   ResultCardRow(base+"SUB",base+"DETAIL",left,top+mainHeight,width,subHeight,detail,subBg,border,subFont,padding);
   if(DetailedResultCards)
   {
      ResultCardRow(base+"EXTRA",base+"EXTRA_TEXT",left,top+mainHeight+subHeight,width,extraHeight,extra,C'19,46,78',border,subFont,padding);
      ResultCardRow(base+"FEES",base+"FEES_TEXT",left,top+mainHeight+subHeight+extraHeight,width,feesHeight,fees,C'12,31,55',border,subFont,padding);
   }
   else
   {
      MoveResultObjectOffscreen(base+"EXTRA");MoveResultObjectOffscreen(base+"EXTRA_TEXT");MoveResultObjectOffscreen(base+"FEES");MoveResultObjectOffscreen(base+"FEES_TEXT");
   }

   string marker=base+"MARK";
   EnsureResultCardObject(marker,OBJ_ARROW);
   if(ObjectFind(0,marker)<0) ObjectCreate(0,marker,OBJ_ARROW,0,closeTime,OrderClosePrice());
   ObjectMove(0,marker,0,closeTime,OrderClosePrice());
   ObjectSetInteger(0,marker,OBJPROP_ARROWCODE,159);
   ObjectSetInteger(0,marker,OBJPROP_COLOR,won?C'255,225,60':C'255,64,96');
   ObjectSetInteger(0,marker,OBJPROP_WIDTH,2);
   ObjectSetInteger(0,marker,OBJPROP_BACK,true);
   ObjectSetInteger(0,marker,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,marker,OBJPROP_HIDDEN,true);

   if(usedCount<ArraySize(usedX))
   {
      usedX[usedCount]=left; usedY[usedCount]=top;
      usedW[usedCount]=width; usedH[usedCount]=height;
      usedCount++;
   }
}

void UpdateClosedTradeResults()
{
   if(!DrawClosedTradeResults)
   {
      ObjectsDeleteAll(0,PREFIX+"RESULT_");
      gKnownResultHistory=OrdersHistoryTotal();
      return;
   }
   int maximum=MathMax(1,MathMin(200,MaximumResultBoxes));
   int usedX[],usedY[],usedW[],usedH[];
   ArrayResize(usedX,maximum); ArrayResize(usedY,maximum);
   ArrayResize(usedW,maximum); ArrayResize(usedH,maximum);
   ArrayInitialize(usedX,0); ArrayInitialize(usedY,0);
   ArrayInitialize(usedW,0); ArrayInitialize(usedH,0);
   int usedCount=0,drawn=0;
   int total=OrdersHistoryTotal();
   // When history grows, clear cards that have fallen outside the newest
   // MaximumResultBoxes set. Otherwise they are never visited again and can
   // remain frozen along the top/left edge during a visual backtest.
   if(total!=gLastResultCleanupHistory)
   {
      ObjectsDeleteAll(0,PREFIX+"RESULT_");
      gLastResultCleanupHistory=total;
   }
   if(total==gKnownResultHistory) return;
   gKnownResultHistory=total;
   for(int i=total-1;i>=0 && drawn<maximum;i--)
   {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)) continue;
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=MagicNumber) continue;
      if(OrderType()!=OP_BUY && OrderType()!=OP_SELL) continue;
      DrawOneClosedResult(usedX,usedY,usedW,usedH,usedCount);
      drawn++;
   }
   ChartRedraw(0);
}

// Persistent terminal statistics survive EA removal/re-attachment even when
// MT4's Account History tab is later set to a shorter display range.
string PersistentStatKey(string suffix)
{
   return "SFH."+IntegerToString(AccountNumber())+"."+IntegerToString(MagicNumber)+"."+Symbol()+"."+suffix;
}

double PersistentGet(string suffix)
{
   string key=PersistentStatKey(suffix);
   if(!GlobalVariableCheck(key)) GlobalVariableSet(key,0.0);
   return GlobalVariableGet(key);
}

void PersistentAdd(string suffix,double value)
{
   string key=PersistentStatKey(suffix);
   GlobalVariableSet(key,PersistentGet(suffix)+value);
}

void SyncPersistentTradeHistory()
{
   if(IsTesting()) return; // tester runs must remain isolated and repeatable
   int history=OrdersHistoryTotal();
   if(history==gPersistentSyncHistory) return;
   gPersistentSyncHistory=history;
   for(int i=0;i<history;i++) if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
   {
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=MagicNumber || (OrderType()!=OP_BUY && OrderType()!=OP_SELL)) continue;
      string marker=PersistentStatKey("T"+IntegerToString(OrderTicket()));
      if(GlobalVariableCheck(marker)){GlobalVariableGet(marker);continue;}
      double result=OrderProfit()+OrderSwap()+OrderCommission();
      PersistentAdd("TR",1.0);
      if(result>0){PersistentAdd("WN",1.0);PersistentAdd("GP",result);}
      else PersistentAdd("GL",MathAbs(result));
      PersistentAdd("NET",result);
      GlobalVariableSet(marker,(double)OrderCloseTime());
   }
}

//+------------------------------------------------------------------+
void HistoryStats(int &trades,int &wins,int &losses,double &net)
{
   if(!IsTesting())
   {
      SyncPersistentTradeHistory();
      trades=(int)PersistentGet("TR");wins=(int)PersistentGet("WN");
      losses=trades-wins;if(losses<0)losses=0;net=PersistentGet("NET");
      return;
   }
   static int cachedHistory=-1,cachedTrades=0,cachedWins=0,cachedLosses=0;
   static double cachedNet=0;
   int history=OrdersHistoryTotal();
   if(history!=cachedHistory)
   {
      cachedHistory=history;cachedTrades=0;cachedWins=0;cachedLosses=0;cachedNet=0;
      for(int i=history-1;i>=0;i--) if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
      {
         if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=MagicNumber) continue;
         if(OrderType()!=OP_BUY && OrderType()!=OP_SELL) continue;
         double result=OrderProfit()+OrderSwap()+OrderCommission();
         cachedTrades++; cachedNet+=result; if(result>0) cachedWins++; else cachedLosses++;
      }
   }
   trades=cachedTrades;wins=cachedWins;losses=cachedLosses;net=cachedNet;
}

void DestroyEquityCurve()
{
   if(gEquityCanvasReady) gEquityCanvas.Destroy();
   gEquityCanvasReady=false;
   gEquityCanvasWidth=0; gEquityCanvasHeight=0;
   ObjectDelete(0,PREFIX+"EQUITY_CANVAS");
}

void UpdateEquityCurve()
{
   if(!ShowEquityCurve) { DestroyEquityCurve(); return; }
   long chartW=0,chartH=0;
   ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0,chartW);
   ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0,chartH);
   // Match the Performance panel width to the 390 px Signal panel.
   int gap=(int)MathMax(1,EquityPositionGap);
   // End the equity canvas before the right-side position stack. This keeps
   // an exact horizontal gap and prevents either panel from covering it.
   int width=ResponsiveRightPanelLeft((int)chartW)-gap-MathMax(0,EquityCurveX);
   int height=MathMax(90,EquityCurveHeight);
   int x=MathMax(0,EquityCurveX);
   int y=(int)chartH-MathMax(0,EquityCurveY)-height;
   if(width<220 || y<0) { DestroyEquityCurve(); return; }
   int historyTotal=OrdersHistoryTotal();
   if(gEquityCanvasReady && width==gEquityCanvasWidth && height==gEquityCanvasHeight &&
      (int)chartH==gEquityChartHeight && historyTotal==gEquityHistoryTotal) return;

   string canvasName=PREFIX+"EQUITY_CANVAS";
   if(!gEquityCanvasReady || width!=gEquityCanvasWidth || height!=gEquityCanvasHeight)
   {
      DestroyEquityCurve();
      if(!gEquityCanvas.CreateBitmapLabel(0,0,canvasName,x,y,width,height,COLOR_FORMAT_ARGB_NORMALIZE)) return;
      gEquityCanvasReady=true; gEquityCanvasWidth=width; gEquityCanvasHeight=height;
   }
   ObjectSetInteger(0,canvasName,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,canvasName,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,canvasName,OBJPROP_BACK,false);
   ObjectSetInteger(0,canvasName,OBJPROP_ZORDER,100);

   // Fully opaque equity card: no alpha transparency.
   uint bg=ColorToARGB(C'8,14,26',255);
   uint grid=ColorToARGB(C'42,56,82',210);
   uint bright=ColorToARGB(C'110,150,255',255);
   uint text=ColorToARGB(C'220,232,255',255);
   gEquityCanvas.Erase(bg);
   // Solid raised card border.
   gEquityCanvas.Line(0,0,width-1,0,ColorToARGB(C'130,155,220',255));
   gEquityCanvas.Line(0,0,0,height-1,ColorToARGB(C'130,155,220',255));
   gEquityCanvas.Line(0,height-1,width-1,height-1,ColorToARGB(C'2,5,12',255));
   gEquityCanvas.Line(width-1,0,width-1,height-1,ColorToARGB(C'2,5,12',255));

   int count=0; double historyNet=0;
   for(int i=0;i<historyTotal;i++) if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
   {
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=MagicNumber || (OrderType()!=OP_BUY && OrderType()!=OP_SELL)) continue;
      count++;
      historyNet+=OrderProfit()+OrderSwap()+OrderCommission();
   }
   double startEquity=(RiskReferenceBalance>0)?RiskReferenceBalance:AccountBalance()-historyNet;
   double curve[]; ArrayResize(curve,count+1); ArrayInitialize(curve,startEquity);
   int n=0; double cumulative=startEquity,minV=startEquity,maxV=startEquity;
   for(int j=0;j<historyTotal;j++) if(OrderSelect(j,SELECT_BY_POS,MODE_HISTORY))
   {
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=MagicNumber || (OrderType()!=OP_BUY && OrderType()!=OP_SELL)) continue;
      cumulative+=OrderProfit()+OrderSwap()+OrderCommission();
      n++; curve[n]=cumulative;
      minV=MathMin(minV,cumulative); maxV=MathMax(maxV,cumulative);
   }
   if(maxV-minV<0.01) { maxV+=1.0; minV-=1.0; }

   int plotL=45,plotR=width-10,plotT=27,plotB=height-20;
   for(int g=0;g<=3;g++)
   {
      int gy=plotT+(plotB-plotT)*g/3;
      gEquityCanvas.Line(plotL,gy,plotR,gy,grid);
   }
   int baseY=plotB-(int)MathRound((startEquity-minV)/(maxV-minV)*(plotB-plotT));
   baseY=MathMax(plotT,MathMin(plotB,baseY));
   gEquityCanvas.Line(plotL,baseY,plotR,baseY,bright);

   if(n>0)
   {
      // Catmull-Rom interpolation creates one continuous, smooth equity curve
      // instead of bars or sharp straight segments between closed trades.
      int plotWidth=MathMax(1,plotR-plotL);
      int prevX=plotL;
      int prevY=plotB-(int)MathRound((curve[0]-minV)/(maxV-minV)*(plotB-plotT));
      uint curveColor=ColorToARGB(C'45,105,255',255);
      for(int pixel=2;pixel<=plotWidth;pixel+=2)
      {
         double u=(double)pixel*n/plotWidth;
         int index=MathMin(n-1,(int)MathFloor(u));
         double t=u-index;
         double p0=curve[MathMax(0,index-1)];
         double p1=curve[index];
         double p2=curve[MathMin(n,index+1)];
         double p3=curve[MathMin(n,index+2)];
         double t2=t*t,t3=t2*t;
         double smooth=0.5*((2.0*p1)+(-p0+p2)*t+(2.0*p0-5.0*p1+4.0*p2-p3)*t2+(-p0+3.0*p1-3.0*p2+p3)*t3);
         smooth=MathMax(minV,MathMin(maxV,smooth));
         int cx=plotL+pixel;
         int cy=plotB-(int)MathRound((smooth-minV)/(maxV-minV)*(plotB-plotT));
         gEquityCanvas.Line(prevX,prevY,cx,cy,curveColor);
         gEquityCanvas.Line(prevX,prevY+1,cx,cy+1,curveColor);
         prevX=cx;prevY=cy;
      }
   }
   gEquityCanvas.FontSet("Arial",11,FW_BOLD);
   gEquityCanvas.TextOut(10,7,"EA EQUITY CURVE",text);
   double netResult=cumulative-startEquity;
   string netText="NET "+(netResult>=0?"+":"")+DoubleToString(netResult,2);
   gEquityCanvas.TextOut(width-105,7,netText,netResult>=0?ColorToARGB(C'0,255,170',255):ColorToARGB(C'255,64,96',255));
   gEquityCanvas.FontSet("Arial",8,0);
   gEquityCanvas.TextOut(7,plotT-3,DoubleToString(maxV,0),text);
   gEquityCanvas.TextOut(7,plotB-8,DoubleToString(minV,0),text);
   gEquityCanvas.Update();
   gEquityHistoryTotal=historyTotal;
   gEquityChartHeight=(int)chartH;
}

string CurrentTimeframeText()
{
   int tf=Period();
   if(tf<60) return "M"+IntegerToString(tf);
   if(tf<1440) return "H"+IntegerToString(tf/60);
   if(tf==1440) return "D1";
   if(tf==10080) return "W1";
   if(tf==43200) return "MN1";
   return IntegerToString(tf);
}

string CurrentCandleCountdown()
{
   int barSeconds=MathMax(60,Period()*60);
   int remaining=(int)(Time[0]+barSeconds-TimeCurrent());
   remaining=MathMax(0,MathMin(barSeconds,remaining));
   int hours=remaining/3600;
   int minutes=(remaining%3600)/60;
   int seconds=remaining%60;
   if(hours>0) return StringFormat("%02d:%02d:%02d",hours,minutes,seconds);
   return StringFormat("%02d:%02d",minutes,seconds);
}

datetime StartOfDay(datetime when)
{
   MqlDateTime d; TimeToStruct(when,d);
   d.hour=0;d.min=0;d.sec=0;
   return StructToTime(d);
}

datetime StartOfMonth(datetime when)
{
   MqlDateTime d; TimeToStruct(when,d);
   d.day=1;d.hour=0;d.min=0;d.sec=0;
   return StructToTime(d);
}

void UpdateTrackerCache()
{
   datetime now=TimeCurrent();
   datetime day=StartOfDay(now);
   int history=OrdersHistoryTotal();
   if(history==gTrackerHistory && day==gTrackerDay) return;
   gTrackerHistory=history;gTrackerDay=day;gTrackerTrades=0;gTrackerWins=0;
   gTrackerGrossProfit=0;gTrackerGrossLoss=0;gTrackerMaxDD=0;
   gTrackerDaily=0;gTrackerWeekly=0;gTrackerMonthly=0;gTrackerTotal=0;
   ArrayInitialize(gTrackerDayProfit,0.0);ArrayInitialize(gTrackerDayLots,0.0);
   ArrayInitialize(gTrackerDayGross,0.0);ArrayInitialize(gTrackerDayCommission,0.0);
   int weekday=TimeDayOfWeek(day); // Sunday=0
   int daysFromMonday=(weekday==0)?6:weekday-1;
   datetime weekStart=day-daysFromMonday*86400;
   datetime monthStart=StartOfMonth(now);

   // First pass collects period totals and the total used to reconstruct the
   // EA's starting balance for its closed-equity drawdown calculation.
   for(int i=0;i<history;i++) if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
   {
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=MagicNumber || (OrderType()!=OP_BUY && OrderType()!=OP_SELL)) continue;
      double result=OrderProfit()+OrderSwap()+OrderCommission();
      datetime closed=OrderCloseTime();
      gTrackerTrades++;gTrackerTotal+=result;
      if(result>0){gTrackerWins++;gTrackerGrossProfit+=result;}else gTrackerGrossLoss+=MathAbs(result);
      if(closed>=day) gTrackerDaily+=result;
      if(closed>=weekStart) gTrackerWeekly+=result;
      if(closed>=monthStart) gTrackerMonthly+=result;
      for(int d=0;d<5;d++)
      {
         datetime ds=day-d*86400;
         if(closed>=ds && closed<ds+86400)
         {
            gTrackerDayGross[d]+=OrderProfit()+OrderSwap();gTrackerDayCommission[d]+=OrderCommission();
            gTrackerDayProfit[d]+=result;gTrackerDayLots[d]+=OrderLots();break;
         }
      }
   }

   double running=AccountBalance()-gTrackerTotal;
   double peak=running;
   for(int j=0;j<history;j++) if(OrderSelect(j,SELECT_BY_POS,MODE_HISTORY))
   {
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=MagicNumber || (OrderType()!=OP_BUY && OrderType()!=OP_SELL)) continue;
      running+=OrderProfit()+OrderSwap()+OrderCommission();
      peak=MathMax(peak,running);
      if(peak>0) gTrackerMaxDD=MathMax(gTrackerMaxDD,(peak-running)/peak*100.0);
   }
   if(!IsTesting())
   {
      SyncPersistentTradeHistory();
      double savedDD=PersistentGet("DD");
      if(gTrackerMaxDD>savedDD) GlobalVariableSet(PersistentStatKey("DD"),gTrackerMaxDD);
      else gTrackerMaxDD=savedDD;
      gTrackerTrades=(int)PersistentGet("TR");gTrackerWins=(int)PersistentGet("WN");
      gTrackerGrossProfit=PersistentGet("GP");gTrackerGrossLoss=PersistentGet("GL");
      gTrackerTotal=PersistentGet("NET");
   }
}

color ProfitColor(double value)
{
   if(value>0) return C'0,255,170';
   if(value<0) return C'255,64,96';
   return C'205,215,235';
}

void DrawAccountProfitPanel()
{
   if(!ShowAccountProfitPanel){ObjectsDeleteAll(0,PREFIX+"ACCOUNT_");return;}
   UpdateTrackerCache();
   int fs=MathMax(7,DashboardFontSize);
   // Remove the previous combined clock row after upgrading to two cards.
   ObjectDelete(0,PREFIX+"ACCOUNT_C_CLOCK");ObjectDelete(0,PREFIX+"ACCOUNT_T_CLOCK");
   int x=MathMax(0,AccountPanelX),y=MathMax(0,AccountPanelY),w=440,h=442;
   DrawPanel("ACCOUNT",EA_Top_Left,x,y,w,h);
   DrawCell("ACCOUNT","TITLE",EA_Top_Left,x,y,w,h,6,6,428,27,"ACCOUNT & PROFIT TRACKER",C'255,255,255',C'25,90,175',fs+1);

   double floating=AccountEquity()-AccountBalance();
   string accountText[4];
   accountText[0]="BAL  "+DoubleToString(AccountBalance(),2);
   accountText[1]="EQUITY  "+DoubleToString(AccountEquity(),2);
   accountText[2]="FREE  "+DoubleToString(AccountFreeMargin(),2);
   accountText[3]="FLOAT  "+DoubleToString(floating,2);
   color accountColor[4];accountColor[0]=C'120,210,255';accountColor[1]=ProfitColor(AccountEquity()-AccountBalance());
   accountColor[2]=C'120,210,255';accountColor[3]=ProfitColor(floating);
   for(int a=0;a<4;a++) DrawCell("ACCOUNT","A"+IntegerToString(a),EA_Top_Left,x,y,w,h,6+a*107,35,107,27,accountText[a],accountColor[a],C'24,35,55',fs);

   DrawCell("ACCOUNT","TRADE_HEAD",EA_Top_Left,x,y,w,h,6,64,428,19,"ACTIVE TRADE LEVELS",C'120,210,255',C'28,48,88',fs);
   int type;int ticket=ActiveTicket(type);double entry=0,sl=0,tp=0,lots=0;
   if(ticket>=0 && OrderSelect(ticket,SELECT_BY_TICKET)){entry=OrderOpenPrice();sl=OrderStopLoss();tp=OrderTakeProfit();lots=OrderLots();}
   string tradeText[4];
   tradeText[0]="ENTRY  "+(entry>0?DoubleToString(entry,Digits):"--");
   tradeText[1]="SL  "+(sl>0?DoubleToString(sl,Digits):"--");
   tradeText[2]="TP  "+(tp>0?DoubleToString(tp,Digits):"--");
   tradeText[3]="LOT  "+(lots>0?DoubleToString(lots,2):"--");
   color tradeColor[4]={C'90,180,255',C'255,64,96',C'0,255,170',C'255,214,64'};
   for(int t=0;t<4;t++) DrawCell("ACCOUNT","T"+IntegerToString(t),EA_Top_Left,x,y,w,h,6+t*107,85,107,25,tradeText[t],tradeColor[t],C'24,35,55',fs);

   DrawCell("ACCOUNT","STAT_HEAD",EA_Top_Left,x,y,w,h,6,112,428,19,"TRADING STATISTICS",C'120,210,255',C'28,48,88',fs);
   double wr=gTrackerTrades>0?100.0*gTrackerWins/gTrackerTrades:0;
   double pf=gTrackerGrossLoss>0?gTrackerGrossProfit/gTrackerGrossLoss:(gTrackerGrossProfit>0?999.0:0.0);
   string statText[4];statText[0]="WINRATE "+DoubleToString(wr,1)+"%";statText[1]="DD "+DoubleToString(gTrackerMaxDD,1)+"%";
   statText[2]="PF "+(pf>=999?"MAX":DoubleToString(pf,2));statText[3]="TRADES "+IntegerToString(gTrackerTrades);
   color statColor[4];statColor[0]=(wr>=50?C'0,255,170':C'255,64,96');statColor[1]=(gTrackerMaxDD<=10?C'0,255,170':C'255,64,96');
   statColor[2]=(pf>1?C'0,255,170':C'255,64,96');statColor[3]=C'120,210,255';
   for(int s=0;s<4;s++) DrawCell("ACCOUNT","S"+IntegerToString(s),EA_Top_Left,x,y,w,h,6+s*107,133,107,25,statText[s],statColor[s],C'24,35,55',fs);

   DrawCell("ACCOUNT","PERF_HEAD",EA_Top_Left,x,y,w,h,6,160,428,19,"DAILY / WEEKLY / MONTHLY / TOTAL",C'120,210,255',C'28,48,88',fs);
   string periodHead[4]={"DAILY","WEEKLY","MONTHLY","TOTAL"};
   double periodValue[4];periodValue[0]=gTrackerDaily;periodValue[1]=gTrackerWeekly;periodValue[2]=gTrackerMonthly;periodValue[3]=gTrackerTotal;
   for(int p=0;p<4;p++)
   {
      string id=IntegerToString(p);
      DrawCell("ACCOUNT","PH"+id,EA_Top_Left,x,y,w,h,6+p*107,181,107,18,periodHead[p],C'170,205,255',C'34,45,68',fs-1);
      DrawCell("ACCOUNT","PV"+id,EA_Top_Left,x,y,w,h,6+p*107,200,107,24,(periodValue[p]>=0?"+":"")+DoubleToString(periodValue[p],2),ProfitColor(periodValue[p]),periodValue[p]>=0?C'0,65,54':C'82,20,37',fs);
   }

   DrawCell("ACCOUNT","TRACK_HEAD",EA_Top_Left,x,y,w,h,6,226,428,18,"PROFIT TRACKER — LAST 5 DAYS",C'255,255,255',C'72,48,160',fs);
   int widths[4]={110,70,120,128};string headers[4]={"DATE","LOTS","PROFIT","GAIN %"};int left=6;
   for(int hh=0;hh<4;hh++){DrawCell("ACCOUNT","DH"+IntegerToString(hh),EA_Top_Left,x,y,w,h,left,246,widths[hh],19,headers[hh],C'120,210,255',C'28,48,88',fs-1);left+=widths[hh];}
   double gainBase=(RiskReferenceBalance>0)?RiskReferenceBalance:MathMax(1.0,AccountBalance());
   for(int d=0;d<5;d++)
   {
      int top=266+d*21;string id=IntegerToString(d);datetime date=gTrackerDay-d*86400;
      double gain=gTrackerDayProfit[d]/gainBase*100.0;color pc=ProfitColor(gTrackerDayProfit[d]);
      string values[4];values[0]=TimeToString(date,TIME_DATE);values[1]=DoubleToString(gTrackerDayLots[d],2);
      values[2]=(gTrackerDayProfit[d]>=0?"+":"")+DoubleToString(gTrackerDayProfit[d],2);values[3]=(gain>=0?"+":"")+DoubleToString(gain,2)+"%";
      left=6;
      for(int c=0;c<4;c++){DrawCell("ACCOUNT","D"+id+IntegerToString(c),EA_Top_Left,x,y,w,h,left,top,widths[c],20,values[c],c>=2?pc:C'220,230,245',C'20,29,45',fs-1);left+=widths[c];}
   }

   // Separate raised clock and candle-timer cards below the five-day tracker.
   DrawCell("ACCOUNT","CLOCK_H",EA_Top_Left,x,y,w,h,6,372,214,21,"SERVER TIME",C'255,255,255',C'168,108,0',fs);
   DrawCell("ACCOUNT","COUNT_H",EA_Top_Left,x,y,w,h,220,372,214,21,CurrentTimeframeText()+" CANDLE COUNTDOWN",C'255,255,255',C'78,48,165',fs);
   DrawCell("ACCOUNT","CLOCK_TIME",EA_Top_Left,x,y,w,h,6,394,214,40,TimeToString(TimeCurrent(),TIME_SECONDS),C'255,255,255',C'96,61,0',12);
   DrawCell("ACCOUNT","COUNT_TIME",EA_Top_Left,x,y,w,h,220,394,214,40,CurrentCandleCountdown(),C'255,255,255',C'45,24,100',14);
   ObjectSetString(0,PREFIX+"ACCOUNT_T_CLOCK_H",OBJPROP_FONT,"Arial Black");
   ObjectSetString(0,PREFIX+"ACCOUNT_T_COUNT_H",OBJPROP_FONT,"Arial Black");
   ObjectSetString(0,PREFIX+"ACCOUNT_T_CLOCK_TIME",OBJPROP_FONT,"Arial Black");
   ObjectSetString(0,PREFIX+"ACCOUNT_T_COUNT_TIME",OBJPROP_FONT,"Arial Black");
}

bool UIEnsureObject(string name,ENUM_OBJECT type)
{
   if(ObjectFind(0,name)>=0)return true;
   ResetLastError();
   if(!ObjectCreate(0,name,type,0,0,0))
   {
      Print("UI Object creation failed: ",name," Error=",GetLastError());
      return false;
   }
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,200);
   return true;
}

void UIBitmap(string id,int x,int y,string resource)
{
   if(!UseOption13SapphireBitmapSkin)return;
   string name=PREFIX+"UI_BMP_"+id;
   if(!UIEnsureObject(name,OBJ_BITMAP_LABEL))return;
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,MathMax(0,x));ObjectSetInteger(0,name,OBJPROP_YDISTANCE,MathMax(0,y));
   ObjectSetString(0,name,OBJPROP_BMPFILE,0,resource);
   ObjectSetInteger(0,name,OBJPROP_COLOR,C'9,24,47');ObjectSetInteger(0,name,OBJPROP_ZORDER,230);
}

void UIRect(string id,int x,int y,int width,int height,color background,color border)
{
   string name=PREFIX+"UI_"+id;if(!UIEnsureObject(name,OBJ_RECTANGLE_LABEL))return;
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,MathMax(0,x));ObjectSetInteger(0,name,OBJPROP_YDISTANCE,MathMax(0,y));
   ObjectSetInteger(0,name,OBJPROP_XSIZE,MathMax(1,width));ObjectSetInteger(0,name,OBJPROP_YSIZE,MathMax(1,height));
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,background);ObjectSetInteger(0,name,OBJPROP_COLOR,border);
   ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
}

void CreatePanel(string id,int x,int y,int width,int height)
{
   UIRect(id+"_GLOW",x-2,y-2,width+4,height+4,C'5,14,30',C'0,92,190');
   UIRect(id+"_SHADOW",x+3,y+3,width,height,C'4,7,14',C'4,7,14');
   UIRect(id+"_PANEL",x,y,width,height,PanelBackground,PanelBorder);
   ObjectSetInteger(0,PREFIX+"UI_"+id+"_PANEL",OBJPROP_BORDER_TYPE,BORDER_RAISED);
   UIRect(id+"_ACCENT",x,y,4,height,AccentColor,AccentColor);
   UIBitmap(id+"_CORNER",x+width-30,y+height-30,"::Images\\SignalForgePro13\\corner.bmp");
}

void CreateRightPanel(string id,int rightDistance,int absoluteX,int y,int width,int height)
{
   UIRect(id+"_GLOW",absoluteX-2,y-2,width+4,height+4,C'5,14,30',C'0,145,170');
   string shadow=PREFIX+"UI_"+id+"_SHADOW",panel=PREFIX+"UI_"+id+"_PANEL";
   if(UIEnsureObject(shadow,OBJ_RECTANGLE_LABEL))
   {
      ObjectSetInteger(0,shadow,OBJPROP_CORNER,CORNER_RIGHT_UPPER);ObjectSetInteger(0,shadow,OBJPROP_XDISTANCE,MathMax(0,rightDistance-3));ObjectSetInteger(0,shadow,OBJPROP_YDISTANCE,y+3);
      ObjectSetInteger(0,shadow,OBJPROP_XSIZE,width);ObjectSetInteger(0,shadow,OBJPROP_YSIZE,height);ObjectSetInteger(0,shadow,OBJPROP_BGCOLOR,C'4,7,14');ObjectSetInteger(0,shadow,OBJPROP_COLOR,C'4,7,14');
   }
   if(UIEnsureObject(panel,OBJ_RECTANGLE_LABEL))
   {
      ObjectSetInteger(0,panel,OBJPROP_CORNER,CORNER_RIGHT_UPPER);ObjectSetInteger(0,panel,OBJPROP_XDISTANCE,rightDistance);ObjectSetInteger(0,panel,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(0,panel,OBJPROP_XSIZE,width);ObjectSetInteger(0,panel,OBJPROP_YSIZE,height);ObjectSetInteger(0,panel,OBJPROP_BGCOLOR,PanelBackground);ObjectSetInteger(0,panel,OBJPROP_COLOR,PanelBorder);ObjectSetInteger(0,panel,OBJPROP_BORDER_TYPE,BORDER_RAISED);
   }
   UIRect(id+"_ACCENT",absoluteX,y,4,height,AccentColor,AccentColor);
   UIBitmap(id+"_CORNER",absoluteX+width-30,y+height-30,"::Images\\SignalForgePro13\\corner.bmp");
}

void UILabel(string id,int x,int y,string text,color clr,int size,string font="Segoe UI")
{
   string name=PREFIX+"UI_"+id;if(!UIEnsureObject(name,OBJ_LABEL))return;
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,MathMax(0,x));ObjectSetInteger(0,name,OBJPROP_YDISTANCE,MathMax(0,y));
   ObjectSetString(0,name,OBJPROP_TEXT,text);ObjectSetString(0,name,OBJPROP_FONT,font);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,MathMax(6,size));ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
}

void UIWingdings(string id,int x,int y,int code,color clr,int size)
{
   UILabel(id,x,y,CharToString((uchar)code),clr,size,"Wingdings");
}

void CreateHeader(string panelId,int x,int y,int width,string title,string subtitle)
{
   UIRect(panelId+"_HEADER",x+5,y+5,width-10,38,HeaderColor,HeaderColor);
   ObjectSetInteger(0,PREFIX+"UI_"+panelId+"_HEADER",OBJPROP_BORDER_TYPE,BORDER_RAISED);
   UIBitmap(panelId+"_LOGO",x+8,y+4,"::Images\\SignalForgePro13\\logo.bmp");
   UILabel(panelId+"_TITLE",x+53,y+10,title,TextColor,PanelFontSize+2,"Segoe UI Semibold");
   UILabel(panelId+"_SUB",x+53,y+26,subtitle,SecondaryTextColor,PanelFontSize-1);
}

void CreateStatusIndicator(string id,int x,int y,string status,color clr)
{
   UIRect(id+"_DOT",x,y+3,7,7,clr,clr);UILabel(id+"_TEXT",x+13,y,status,clr,PanelFontSize,"Segoe UI Semibold");
}

void UIButton(string name,int x,int y,int width,int height,string text,color background,color border)
{
   if(!UIEnsureObject(name,OBJ_BUTTON))return;
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,width);ObjectSetInteger(0,name,OBJPROP_YSIZE,height);ObjectSetInteger(0,name,OBJPROP_BGCOLOR,background);
   ObjectSetInteger(0,name,OBJPROP_COLOR,TextColor);ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,border);ObjectSetInteger(0,name,OBJPROP_STATE,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,true);ObjectSetString(0,name,OBJPROP_FONT,"Arial Bold");ObjectSetInteger(0,name,OBJPROP_FONTSIZE,7);ObjectSetString(0,name,OBJPROP_TEXT,text);
}

void CreateValueLabel(string id,int x,int y,string label,string value,color valueColor)
{
   UILabel(id+"_LABEL",x,y,label,SecondaryTextColor,PanelFontSize-1);
   UILabel(id+"_VALUE",x,y+11,value,valueColor,ValueFontSize,"Segoe UI Semibold");
}

string CurrentSessionText()
{
   if(!UseTradingSession)return "ALL SESSIONS";
   string start=StringFormat("%02d:%02d",SessionStartHour,SessionStartMinute);
   string finish=StringFormat("%02d:%02d",SessionEndHour,SessionEndMinute);
   return start+" - "+finish;
}

int UIOpenTrades(double &floating)
{
   int count=0;floating=0;
   for(int i=OrdersTotal()-1;i>=0;i--)if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
   {
      if(OrderSymbol()!=Symbol()||OrderMagicNumber()!=MagicNumber||(OrderType()!=OP_BUY&&OrderType()!=OP_SELL))continue;
      count++;floating+=OrderProfit()+OrderSwap()+OrderCommission();
   }
   return count;
}

void DeletePanelObjects()
{
   ObjectsDeleteAll(0,PREFIX+"UI_");
}

void UICard(string id,int x,int y,int width,int height)
{
   UIRect(id,x,y,width,height,C'10,25,49',C'21,82,145');
   // Solid native MT4 raised cards provide an opaque, tactile terminal look.
   ObjectSetInteger(0,PREFIX+"UI_"+id,OBJPROP_BORDER_TYPE,BORDER_RAISED);
}

void UIProgressBar(string id,int x,int y,int width,double value,double maximum,color fill)
{
   double ratio=maximum>0?MathMax(0,MathMin(1,value/maximum)):0;
   string track=PREFIX+"UI_"+id+"_TRACK",filled=PREFIX+"UI_"+id+"_FILL";
   // Both components are fully opaque native raised objects—not flat paint.
   UIRect(id+"_TRACK",x,y,width,12,C'18,48,91',C'64,94,140');
   ObjectSetInteger(0,track,OBJPROP_BORDER_TYPE,BORDER_RAISED);
   UIRect(id+"_FILL",x+1,y+1,(int)MathMax(2,(width-2)*ratio),10,fill,fill);
   ObjectSetInteger(0,filled,OBJPROP_BORDER_TYPE,BORDER_RAISED);
}

double EnabledWeightTotal()
{
   double total=0;
   if(EnableSMA)total+=SMAWeight;if(EnableRSI)total+=RSIWeight;if(EnableMACD)total+=MACDWeight;if(EnableSupertrend)total+=SupertrendWeight;
   if(EnableStochastic)total+=StochasticWeight;if(EnableBollinger)total+=BollingerWeight;if(EnableEMA)total+=EMAWeight;if(EnableAO)total+=AOWeight;
   if(EnableSAR)total+=SARWeight;if(EnableCCI)total+=CCIWeight;if(EnableADX)total+=ADXWeight;
   return MathMax(1,total);
}

string UIDuration(datetime opened)
{
   if(opened<=0)return "--:--:--";int seconds=(int)MathMax(0,TimeCurrent()-opened);
   return StringFormat("%02d:%02d:%02d",seconds/3600,(seconds%3600)/60,seconds%60);
}

void UpdateDashboard()
{
   if(!gLegacyDashboardCleared)
   {
      ObjectsDeleteAll(0,PREFIX+"SIG_");ObjectsDeleteAll(0,PREFIX+"PERF_");ObjectsDeleteAll(0,PREFIX+"ACCOUNT_");
      gLegacyDashboardCleared=true;
   }
   if(!ShowDashboard){DeletePanelObjects();return;}

   long cw=0,ch=0;ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0,cw);ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0,ch);
   int chartW=(int)cw,chartH=(int)ch;if(chartW<600||chartH<400)return;
   int leftW=(int)MathMin(MathMax(440,LeftPanelWidth),(chartW-LeftMargin-RightMargin-20)*0.55);
   int rightW=ResponsiveRightPanelWidth(chartW);
   if(AutoSizeDashboard)
   {
      int maximumCombined=(int)MathMax(760,chartW-LeftMargin-RightMargin-MathMax(180,MinimumVisibleChartWidth));
      if(leftW+rightW>maximumCombined)
      {
         double scale=(double)maximumCombined/(leftW+rightW);
         leftW=(int)MathMax(420,leftW*scale);rightW=(int)MathMax(340,rightW*scale);
      }
   }
   int leftH=(int)MathMax(340,LeftPanelHeight),rightH=(int)MathMax(300,RightPanelHeight);
   if(AutoSizeDashboard)rightH=(int)MathMin(rightH,MathMax(300,chartH-TopMargin-BottomMargin-PositionPanelStackGap-150));
   int leftX=LeftMargin,leftY=TopMargin,rightX=chartW-RightMargin-rightW,rightY=TopMargin;
   // Stack Active Position directly beneath Account & Performance. It uses
   // exactly the same X coordinate and width, opening the chart center.
   int stackGap=(int)MathMax(4,PositionPanelStackGap);
   int bottomW=rightW,bottomX=rightX,bottomY=rightY+rightH+stackGap;
   int remainingHeight=chartH-MathMax(4,BottomMargin)-bottomY;
   int bottomH=(int)MathMin(MathMax(150,BottomPanelHeight),MathMax(110,remainingHeight));

   double spread=(Ask-Bid)/Point,floating=0;int openTrades=UIOpenTrades(floating);
   double today=TodayClosedPL(),marginLevel=AccountMargin()>0?AccountEquity()/AccountMargin()*100.0:0;
   bool marketOpen=MarketInfo(Symbol(),MODE_TRADEALLOWED)>0&&Bid>0&&Ask>0;
   bool streakSafe=!StopTradingAfterConsecutiveLosses||MaximumConsecutiveLosses<=0||CurrentConsecutiveLosses()<MaximumConsecutiveLosses;
   bool tradeSafe=marketOpen&&SessionAllowed()&&!DailyLossReached()&&streakSafe;
   int activeType=-1,activeTicket=ActiveTicket(activeType);double lot=FixedLots,sl=0,tp=0,entry=0,current=Bid,riskMoney=0,rr=0,tradePL=0;datetime opened=0;
   if(activeTicket>0&&OrderSelect(activeTicket,SELECT_BY_TICKET,MODE_TRADES))
   {
      lot=OrderLots();sl=OrderStopLoss();tp=OrderTakeProfit();entry=OrderOpenPrice();opened=OrderOpenTime();current=activeType==OP_BUY?Bid:Ask;tradePL=OrderProfit()+OrderSwap()+OrderCommission();
      string riskKey="SFP.ISL."+IntegerToString(AccountNumber())+"."+IntegerToString(MagicNumber)+"."+IntegerToString(activeTicket);
      double initialSL=GlobalVariableCheck(riskKey)?GlobalVariableGet(riskKey):sl;riskMoney=MoneyRiskAtStop(lot,entry,initialSL);
      if(initialSL>0&&tp>0)rr=MathAbs(tp-entry)/MathAbs(entry-initialSL);
   }
   UpdateTrackerCache();double profitFactor=gTrackerGrossLoss>0?gTrackerGrossProfit/gTrackerGrossLoss:(gTrackerGrossProfit>0?999:0);
   double winRate=gTrackerTrades>0?100.0*gTrackerWins/gTrackerTrades:0;

   if(ShowLeftPanel)
   {
      CreatePanel("LEFT",leftX,leftY,leftW,leftH);CreateHeader("LEFT",leftX,leftY,leftW,"SIGNAL FORGE PRO",Symbol()+"  •  "+CurrentTimeframeText());
      UILabel("LEFT_DATE",leftX+leftW-105,leftY+10,TimeToString(TimeCurrent(),TIME_DATE),SecondaryTextColor,PanelFontSize-1);
      UILabel("LEFT_COUNTDOWN",leftX+leftW-225,leftY+27,"CANDLE "+CurrentCandleCountdown(),WarningColor,PanelFontSize,"Segoe UI Semibold");
      CreateStatusIndicator("LEFT_RUN",leftX+leftW-105,leftY+27,tradeSafe?"EA RUNNING":"EA PAUSED",tradeSafe?ProfitColor:WarningColor);
      int cardY=leftY+54,scoreW=(int)(leftW*0.35),marketW=(int)(leftW*0.29),indicatorW=leftW-scoreW-marketW-38;
      UICard("LEFT_SCORE",leftX+12,cardY,scoreW,leftH-132);UICard("LEFT_MARKET",leftX+18+scoreW,cardY,marketW,leftH-132);UICard("LEFT_IND",leftX+24+scoreW+marketW,cardY,indicatorW,leftH-132);
      int sx=leftX+25,sy=cardY+17,barW=scoreW-26;
      UILabel("LEFT_BUYL",sx,sy,"BUY SCORE",TextColor,PanelFontSize,"Segoe UI Semibold");UILabel("LEFT_BUYV",sx+barW-55,sy,DoubleToString(gBuyScore,1)+" / "+DoubleToString(EnabledWeightTotal(),0),ProfitColor,PanelFontSize);
      UIProgressBar("LEFT_BUYBAR",sx,sy+22,barW,gBuyScore,EnabledWeightTotal(),C'0,205,180');sy+=60;
      UILabel("LEFT_SELLL",sx,sy,"SELL SCORE",TextColor,PanelFontSize,"Segoe UI Semibold");UILabel("LEFT_SELLV",sx+barW-55,sy,DoubleToString(gSellScore,1)+" / "+DoubleToString(EnabledWeightTotal(),0),LossColor,PanelFontSize);
      UIProgressBar("LEFT_SELLBAR",sx,sy+22,barW,gSellScore,EnabledWeightTotal(),C'255,38,91');sy+=60;
      UILabel("LEFT_CANDLEL",sx,sy,"CANDLE SCORE",TextColor,PanelFontSize,"Segoe UI Semibold");UILabel("LEFT_CANDLEV",sx+barW-42,sy,IntegerToString(gCandleScore)+" / 5",WarningColor,PanelFontSize);
      UIProgressBar("LEFT_CANDLEBAR",sx,sy+22,barW,gCandleScore,5,WarningColor);
      int mx=leftX+30+scoreW,my=cardY+14;UILabel("LEFT_MHEAD",mx,my,"MARKET INFO",TextColor,PanelFontSize,"Segoe UI Semibold");my+=25;
      string ml[8]={"Bid","Ask","Spread","ATR (14)","Volume","Trend","Market","Session"};string mv[8];
      mv[0]=DoubleToString(Bid,Digits);mv[1]=DoubleToString(Ask,Digits);mv[2]=DoubleToString(spread,1);mv[3]=DoubleToString(iATR(NULL,0,ATRLength,1),Digits);mv[4]=IntegerToString((int)Volume[0]);mv[5]=gBuyScore>gSellScore?"BULLISH":(gSellScore>gBuyScore?"BEARISH":"NEUTRAL");mv[6]=marketOpen?"OPEN":"CLOSED";mv[7]=UseTradingSession?CurrentSessionText():"ALL DAY";
      for(int m=0;m<8;m++){UILabel("LEFT_ML"+IntegerToString(m),mx,my,ml[m],SecondaryTextColor,PanelFontSize-1);color vc=(m==5?(mv[m]=="BULLISH"?ProfitColor:(mv[m]=="BEARISH"?LossColor:NeutralColor)):(m==6?(marketOpen?ProfitColor:LossColor):TextColor));UILabel("LEFT_MV"+IntegerToString(m),mx+marketW-78,my,mv[m],vc,PanelFontSize);my+=22;}
      int ix=leftX+36+scoreW+marketW,iy=cardY+14;UILabel("LEFT_IHEAD",ix,iy,"INDICATORS",TextColor,PanelFontSize,"Segoe UI Semibold");iy+=23;
      string indicatorNames[11]={"SMA","RSI","MACD","Supertrend","Stochastic","Bollinger","EMA","AO","SAR","CCI","ADX"};
      for(int q=0;q<11;q++){string state=gBull[q]?"UP":(gBear[q]?"DOWN":"-");color stateColor=gBull[q]?ProfitColor:(gBear[q]?LossColor:NeutralColor);UILabel("LEFT_IN"+IntegerToString(q),ix,iy,indicatorNames[q],SecondaryTextColor,PanelFontSize-1);UILabel("LEFT_IS"+IntegerToString(q),ix+indicatorW-46,iy,state,stateColor,PanelFontSize-1,"Segoe UI Semibold");iy+=17;}
      int stateY=leftY+leftH-66;string signalCard=PREFIX+"UI_LEFT_STATECARD";
      color signalBg=gLongSignal?C'0,112,72':(gShortSignal?C'156,28,45':C'10,25,49');
      color signalBorder=gLongSignal?ProfitColor:(gShortSignal?LossColor:C'21,82,145');
      UIRect("LEFT_STATECARD",leftX+12,stateY,leftW-24,52,signalBg,signalBorder);
      ObjectSetInteger(0,signalCard,OBJPROP_BORDER_TYPE,BORDER_RAISED);
      string signal=gLongSignal?"BUY SIGNAL":(gShortSignal?"SELL SIGNAL":"NO SIGNAL");
      if(UseOption13SapphireBitmapSkin)
      {
         string orbResource=gLongSignal?"::Images\\SignalForgePro13\\orb_buy.bmp":(gShortSignal?"::Images\\SignalForgePro13\\orb_sell.bmp":"::Images\\SignalForgePro13\\orb_neutral.bmp");
         UIBitmap("LEFT_SIGNAL_ORB",leftX+20,stateY-2,orbResource);
         UILabel("LEFT_SIGNAL",leftX+82,stateY+12,signal,TextColor,ValueFontSize+5,"Segoe UI Semibold");
      }
      else
      {
         if(gLongSignal||gShortSignal)UIWingdings("LEFT_SIGNAL_ICON",leftX+30,stateY+8,gLongSignal?241:242,TextColor,22);
         else if(ObjectFind(0,PREFIX+"UI_LEFT_SIGNAL_ICON")>=0)ObjectSetString(0,PREFIX+"UI_LEFT_SIGNAL_ICON",OBJPROP_TEXT,"");
         UILabel("LEFT_SIGNAL",leftX+(gLongSignal||gShortSignal?64:34),stateY+12,signal,TextColor,ValueFontSize+5,"Segoe UI Semibold");
      }
      UILabel("LEFT_WAIT",leftX+245,stateY+18,gLongSignal||gShortSignal?"Valid closed-candle setup":"Waiting for a valid setup...",gLongSignal||gShortSignal?TextColor:SecondaryTextColor,PanelFontSize);
   }
   else ObjectsDeleteAll(0,PREFIX+"UI_LEFT");

   if(ShowRightPanel)
   {
      CreateRightPanel("RIGHT",RightMargin,rightX,rightY,rightW,rightH);CreateHeader("RIGHT",rightX,rightY,rightW,"ACCOUNT & PERFORMANCE","RISK CONTROL / STATISTICS");
      CreateStatusIndicator("RIGHT_LIVE",rightX+rightW-70,rightY+18,"LIVE",ProfitColor);
      UIButton(TRACKER_BUTTON_NAME,rightX+rightW-170,rightY+10,82,24,gShowProfitTracker?"STATISTICS":"TRACKER",C'20,70,125',AccentColor);
      int gap=8,inner=rightW-24,half=(inner-gap)/2,top=rightY+54;
      UICard("RIGHT_ACCOUNT",rightX+12,top,half,112);UICard("RIGHT_RISK",rightX+12+half+gap,top,half,112);
      int ax=rightX+24,ay=top+12;UILabel("RIGHT_AHEAD",ax,ay,"ACCOUNT",TextColor,PanelFontSize,"Segoe UI Semibold");ay+=24;
      string al[4]={"Balance","Equity","Free Margin","Margin Level"};string av[4];av[0]=DoubleToString(AccountBalance(),2);av[1]=DoubleToString(AccountEquity(),2);av[2]=DoubleToString(AccountFreeMargin(),2);av[3]=AccountMargin()>0?DoubleToString(marginLevel,1)+"%":"N/A";
      for(int a=0;a<4;a++){UILabel("RIGHT_AL"+IntegerToString(a),ax,ay,al[a],SecondaryTextColor,PanelFontSize-1);UILabel("RIGHT_AV"+IntegerToString(a),ax+half-90,ay,av[a],a==1?(floating>=0?ProfitColor:LossColor):TextColor,PanelFontSize);ay+=18;}
      int rx=rightX+24+half+gap,ry=top+12;UILabel("RIGHT_RHEAD",rx,ry,"RISK CONTROL",TextColor,PanelFontSize,"Segoe UI Semibold");ry+=24;
      double riskPct=AccountBalance()>0&&riskMoney>0?riskMoney/AccountBalance()*100.0:0;
      UILabel("RIGHT_RL0",rx,ry,"Trade Risk",SecondaryTextColor,PanelFontSize-1);UILabel("RIGHT_RV0",rx+half-75,ry,DoubleToString(riskPct,2)+"%",riskPct<2?ProfitColor:WarningColor,PanelFontSize);ry+=18;
      UILabel("RIGHT_RL1",rx,ry,"Max Risk",SecondaryTextColor,PanelFontSize-1);UILabel("RIGHT_RV1",rx+half-75,ry,"$"+DoubleToString(MaximumRiskPerTradeMoney,2),TextColor,PanelFontSize);ry+=18;
      UILabel("RIGHT_RL2",rx,ry,"Consec. Losses",SecondaryTextColor,PanelFontSize-1);UILabel("RIGHT_RV2",rx+half-75,ry,IntegerToString(CurrentConsecutiveLosses())+" / "+IntegerToString(MaximumConsecutiveLosses),CurrentConsecutiveLosses()>=MaximumConsecutiveLosses?LossColor:TextColor,PanelFontSize);ry+=18;
      bool protectionPaused=DailyLossReached()||(StopTradingAfterConsecutiveLosses&&MaximumConsecutiveLosses>0&&CurrentConsecutiveLosses()>=MaximumConsecutiveLosses);
      UILabel("RIGHT_RL3",rx,ry,"Trade Lock",SecondaryTextColor,PanelFontSize-1);
      if(ShowProtectionResetButton)UIButton(RESET_BUTTON_NAME,rx+half-96,ry-3,90,19,protectionPaused?"RESET PAUSE":"RESET READY",protectionPaused?C'145,35,45':C'32,65,95',protectionPaused?LossColor:AccentColor);
      else UILabel("RIGHT_RV3",rx+half-75,ry,protectionPaused?"ON":"OFF",protectionPaused?LossColor:NeutralColor,PanelFontSize);
      int middle=top+120,statsH=142;
      if(!gShowProfitTracker)
      {
      UICard("RIGHT_STATS",rightX+12,middle,half,statsH);UICard("RIGHT_DAILY",rightX+12+half+gap,middle,half,78);UICard("RIGHT_HOURS",rightX+12+half+gap,middle+86,half,56);
      int tx=rightX+24,ty=middle+12;UILabel("RIGHT_SHEAD",tx,ty,"STATISTICS",TextColor,PanelFontSize,"Segoe UI Semibold");ty+=23;
      string tl[6]={"Total Trades","Win Rate","Profit Factor","Net Profit","Avg Win","Avg Loss"};string tv[6];tv[0]=IntegerToString(gTrackerTrades);tv[1]=DoubleToString(winRate,1)+"%";tv[2]=DoubleToString(profitFactor,2);tv[3]=SignedValue(gTrackerTotal,2);tv[4]=gTrackerWins>0?"+"+DoubleToString(gTrackerGrossProfit/gTrackerWins,2):"0.00";int losses=gTrackerTrades-gTrackerWins;tv[5]=losses>0?"-"+DoubleToString(gTrackerGrossLoss/losses,2):"0.00";
      for(int t=0;t<6;t++){UILabel("RIGHT_TL"+IntegerToString(t),tx,ty,tl[t],SecondaryTextColor,PanelFontSize-1);UILabel("RIGHT_TV"+IntegerToString(t),tx+half-90,ty,tv[t],t==3?(gTrackerTotal>=0?ProfitColor:LossColor):(t==4?ProfitColor:(t==5?LossColor:TextColor)),PanelFontSize);ty+=17;}
      int dx=rightX+24+half+gap,dy=middle+12;UILabel("RIGHT_DHEAD",dx,dy,"DAILY",TextColor,PanelFontSize,"Segoe UI Semibold");dy+=22;UILabel("RIGHT_DPL",dx,dy,"Daily P/L",SecondaryTextColor,PanelFontSize-1);UILabel("RIGHT_DPV",dx+half-82,dy,SignedValue(today,2),today>=0?ProfitColor:LossColor,PanelFontSize);dy+=19;UIProgressBar("RIGHT_DAYBAR",dx,dy,half-24,MathMax(0,today),MathMax(1,DailyProfitTargetDisplay),ProfitColor);
      int hx=rightX+24+half+gap,hy=middle+98;UILabel("RIGHT_HHEAD",hx,hy,"TRADING HOURS",TextColor,PanelFontSize,"Segoe UI Semibold");UILabel("RIGHT_HVAL",hx,hy+22,CurrentSessionText(),SecondaryTextColor,PanelFontSize);
      }
      else
      {
         UICard("RIGHT_TRACKER",rightX+12,middle,rightW-24,statsH);
         UILabel("RIGHT_TRACK_TITLE",rightX+22,middle+8,"PROFIT TRACKER — LAST 5 DAYS",AccentColor,PanelFontSize,"Segoe UI Semibold");
         int widths[6]={70,35,52,45,55,55};string heads[6]={"DATE","LOT","GROSS","GAIN","COMM","NET"};int cx=rightX+20;
         for(int h=0;h<6;h++){UILabel("RIGHT_TRACK_H"+IntegerToString(h),cx,middle+28,heads[h],SecondaryTextColor,PanelFontSize-2);cx+=widths[h];}
         double gainBase=MathMax(1,AccountBalance());
         for(int d=0;d<5;d++)
         {
            int rowY=middle+47+d*17;datetime date=gTrackerDay-d*86400;double gain=gTrackerDayProfit[d]/gainBase*100.0;cx=rightX+20;
            string vals[6];vals[0]=TimeToString(date,TIME_DATE);vals[1]=DoubleToString(gTrackerDayLots[d],2);vals[2]=SignedValue(gTrackerDayGross[d],2);vals[3]=SignedValue(gain,1)+"%";vals[4]=SignedValue(gTrackerDayCommission[d],2);vals[5]=SignedValue(gTrackerDayProfit[d],2);
            for(int c=0;c<6;c++){UILabel("RIGHT_TRACK_"+IntegerToString(d)+"_"+IntegerToString(c),cx,rowY,vals[c],c>=2?(gTrackerDayProfit[d]>=0?ProfitColor:LossColor):TextColor,PanelFontSize-2);cx+=widths[c];}
         }
      }
      int riskY=rightY+rightH-57;UICard("RIGHT_RISKBAR",rightX+12,riskY,rightW-24,43);UILabel("RIGHT_RISKLEVEL",rightX+24,riskY+8,"RISK LEVEL",TextColor,PanelFontSize,"Segoe UI Semibold");UILabel("RIGHT_RISKPCT",rightX+rightW-65,riskY+8,DoubleToString(riskPct,2)+"%",riskPct<2?ProfitColor:WarningColor,PanelFontSize);UIProgressBar("RIGHT_LEVELBAR",rightX+24,riskY+26,rightW-48,riskPct,MathMax(2,MaximumDailyLossPercent),riskPct<2?ProfitColor:WarningColor);
   }
   else ObjectsDeleteAll(0,PREFIX+"UI_RIGHT");

   if(ShowBottomPanel)
   {
      CreatePanel("BOTTOM",bottomX,bottomY,bottomW,bottomH);CreateHeader("BOTTOM",bottomX,bottomY,bottomW,"ACTIVE POSITION","TRADE MANAGEMENT");
      CreateStatusIndicator("BOTTOM_MANAGED",bottomX+bottomW-100,bottomY+18,activeTicket>0?"MANAGED":"WAITING",activeTicket>0?ProfitColor:NeutralColor);
      int contentY=bottomY+48,leftCardW=(int)(bottomW*0.55),rightCardW=bottomW-leftCardW-32,cardH=(int)MathMax(54,MathMin(76,bottomH-113));
      color positionBg=activeTicket>0?(activeType==OP_BUY?C'0,88,61':C'125,24,40'):C'10,25,49';
      color positionBorder=activeTicket>0?(activeType==OP_BUY?ProfitColor:LossColor):C'21,82,145';
      UIRect("BOTTOM_POSITION",bottomX+12,contentY,leftCardW,cardH,positionBg,positionBorder);
      ObjectSetInteger(0,PREFIX+"UI_BOTTOM_POSITION",OBJPROP_BORDER_TYPE,BORDER_RAISED);
      UICard("BOTTOM_PROFIT",bottomX+20+leftCardW,contentY,rightCardW,cardH);
      string side=activeTicket>0?(activeType==OP_BUY?"BUY SIGNAL":"SELL SIGNAL"):"WAITING FOR SIGNAL";
      if(UseOption13SapphireBitmapSkin)
      {
         string positionOrb=activeTicket>0?(activeType==OP_BUY?"::Images\\SignalForgePro13\\orb_buy.bmp":"::Images\\SignalForgePro13\\orb_sell.bmp"):"::Images\\SignalForgePro13\\orb_neutral.bmp";
         UIBitmap("BOTTOM_SIGNAL_ORB",bottomX+14,contentY-1,positionOrb);
         UILabel("BOTTOM_SIDE",bottomX+76,contentY+9,side,TextColor,ValueFontSize+3,"Segoe UI Semibold");
      }
      else
      {
         if(activeTicket>0)UIWingdings("BOTTOM_SIDE_ICON",bottomX+22,contentY+5,activeType==OP_BUY?241:242,TextColor,18);
         else if(ObjectFind(0,PREFIX+"UI_BOTTOM_SIDE_ICON")>=0)ObjectSetString(0,PREFIX+"UI_BOTTOM_SIDE_ICON",OBJPROP_TEXT,"");
         UILabel("BOTTOM_SIDE",bottomX+(activeTicket>0?50:24),contentY+9,side,TextColor,ValueFontSize+3,"Segoe UI Semibold");
      }
      int levelY=contentY+36,levelCol=(leftCardW-24)/3;string pl[3]={"ENTRY","SL","TP"};string pv[3];pv[0]=entry>0?DoubleToString(entry,Digits):"-";pv[1]=sl>0?DoubleToString(sl,Digits):"-";pv[2]=tp>0?DoubleToString(tp,Digits):"-";
      for(int p=0;p<3;p++){int lx=bottomX+24+p*levelCol;UILabel("BOTTOM_PL"+IntegerToString(p),lx,levelY,pl[p],SecondaryTextColor,PanelFontSize-1);UILabel("BOTTOM_PV"+IntegerToString(p),lx,levelY+13,pv[p],p==1?LossColor:(p==2?ProfitColor:TextColor),PanelFontSize);}
      int px=bottomX+32+leftCardW;UILabel("BOTTOM_CURPL",px,contentY+9,"CURRENT P/L",SecondaryTextColor,PanelFontSize);UILabel("BOTTOM_CURPV",px+rightCardW-95,contentY+7,activeTicket>0?SignedValue(tradePL,2):"0.00",tradePL>=0?ProfitColor:LossColor,ValueFontSize+3,"Segoe UI Semibold");
      double riskPct=AccountBalance()>0&&riskMoney>0?riskMoney/AccountBalance()*100.0:0;
      UILabel("BOTTOM_RISK",px,contentY+38,"RISK $"+DoubleToString(riskMoney,2),TextColor,PanelFontSize);UILabel("BOTTOM_RP",px+74,contentY+38,"RISK "+DoubleToString(riskPct,2)+"%",TextColor,PanelFontSize);UILabel("BOTTOM_RR",px+150,contentY+38,"R:R "+(rr>0?DoubleToString(rr,2):"-"),TextColor,PanelFontSize);
      int lineY=contentY+cardH+6;
      UILabel("BOTTOM_SLL",bottomX+16,lineY,"SL "+(sl>0?DoubleToString(sl,Digits):"-"),LossColor,PanelFontSize-1);UILabel("BOTTOM_ENTRYL",bottomX+bottomW/2-42,lineY,"ENTRY "+(entry>0?DoubleToString(entry,Digits):"-"),TextColor,PanelFontSize-1);UILabel("BOTTOM_TPL",bottomX+bottomW-120,lineY,"TP "+(tp>0?DoubleToString(tp,Digits):"-"),ProfitColor,PanelFontSize-1);
      UIRect("BOTTOM_RANGE",bottomX+16,lineY+17,bottomW-32,7,C'16,58,92',C'21,82,145');
      double range=(sl>0&&tp>0)?MathAbs(tp-sl):0,progress=range>0?(current-MathMin(sl,tp))/range:0;progress=activeType==OP_SELL?1-progress:progress;
      UIRect("BOTTOM_PROGRESS",bottomX+16,lineY+17,(int)MathMax(2,(bottomW-32)*MathMax(0,MathMin(1,progress))),7,activeType==OP_SELL?LossColor:ProfitColor,activeType==OP_SELL?LossColor:ProfitColor);
      int footerY=bottomY+bottomH-31,col=(bottomW-24)/4;
      UICard("BOTTOM_BE",bottomX+12,footerY,col-6,24);UICard("BOTTOM_TRAIL",bottomX+12+col,footerY,col-6,24);UICard("BOTTOM_DIST",bottomX+12+col*2,footerY,col-6,24);UICard("BOTTOM_TIME",bottomX+12+col*3,footerY,col-6,24);
      double slDistance=activeTicket>0&&sl>0?MathAbs(current-sl)/Point:0;
      UILabel("BOTTOM_BEV",bottomX+18,footerY+5,"B/E "+(UseBreakEven?"ON":"OFF"),UseBreakEven?ProfitColor:NeutralColor,PanelFontSize-1);
      UILabel("BOTTOM_TRV",bottomX+18+col,footerY+5,"TRAIL "+(EnableTrailingStop?"ON":"OFF"),EnableTrailingStop?ProfitColor:NeutralColor,PanelFontSize-1);
      UILabel("BOTTOM_DSV",bottomX+18+col*2,footerY+5,"SL "+(slDistance>0?DoubleToString(slDistance,0)+" pts":"-"),TextColor,PanelFontSize-1);
      UILabel("BOTTOM_TMV",bottomX+18+col*3,footerY+5,UIDuration(opened),TextColor,PanelFontSize-1);
   }
   else ObjectsDeleteAll(0,PREFIX+"UI_BOTTOM");
   ChartRedraw(0);
}

void UpdatePanelPositions(){UpdateDashboard();}

void FinalEquityPixel(string id,int x,int y,int width,int height,color c)
{
   string name=PREFIX+"FINAL_EQ_"+id;
   if(ObjectFind(0,name)<0)ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,width);ObjectSetInteger(0,name,OBJPROP_YSIZE,height);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,c);ObjectSetInteger(0,name,OBJPROP_COLOR,c);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
}

void DrawPersistentFinalEquityCurve()
{
   ObjectsDeleteAll(0,PREFIX+"FINAL_EQ_");
   long chartW=0,chartH=0;ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0,chartW);ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0,chartH);
   int gap=(int)MathMax(1,EquityPositionGap);
   int width=ResponsiveRightPanelLeft((int)chartW)-gap-MathMax(0,EquityCurveX);
   int height=MathMax(90,EquityCurveHeight),panelX=MathMax(0,EquityCurveX),panelY=MathMax(0,EquityCurveY);
   if(width<220)return;
   DrawPanel("FINAL_EQ",EA_Bottom_Left,panelX,panelY,width,height);
   DrawCell("FINAL_EQ","TITLE",EA_Bottom_Left,panelX,panelY,width,height,6,5,width-12,20,"FINAL EA EQUITY CURVE",C'225,235,255',C'15,30,55',9);

   int count=0;double totalNet=0;
   for(int i=0;i<OrdersHistoryTotal();i++)if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
      if(OrderSymbol()==Symbol()&&OrderMagicNumber()==MagicNumber&&(OrderType()==OP_BUY||OrderType()==OP_SELL)){count++;totalNet+=OrderProfit()+OrderSwap()+OrderCommission();}
   double start=AccountBalance()-totalNet,cumulative=start,minV=start,maxV=start;
   double curve[];ArrayResize(curve,count+1);ArrayInitialize(curve,start);int n=0;
   for(int j=0;j<OrdersHistoryTotal();j++)if(OrderSelect(j,SELECT_BY_POS,MODE_HISTORY))
   {
      if(OrderSymbol()!=Symbol()||OrderMagicNumber()!=MagicNumber||(OrderType()!=OP_BUY&&OrderType()!=OP_SELL))continue;
      cumulative+=OrderProfit()+OrderSwap()+OrderCommission();n++;curve[n]=cumulative;minV=MathMin(minV,cumulative);maxV=MathMax(maxV,cumulative);
   }
   if(maxV-minV<0.01){maxV+=1;minV-=1;}
   int left=panelX+45,right=panelX+width-10,top=(int)chartH-panelY-height+27,bottom=(int)chartH-panelY-20;
   for(int g=0;g<=3;g++)FinalEquityPixel("GRID"+IntegerToString(g),left,top+(bottom-top)*g/3,right-left,1,C'42,56,82');
   if(n>0)
   {
      int plotWidth=MathMax(1,right-left),dot=0;
      for(int pixel=0;pixel<=plotWidth;pixel+=2)
      {
         double u=(double)pixel*n/plotWidth;int index=MathMin(n-1,(int)MathFloor(u));double t=u-index,t2=t*t,t3=t2*t;
         double p0=curve[MathMax(0,index-1)],p1=curve[index],p2=curve[MathMin(n,index+1)],p3=curve[MathMin(n,index+2)];
         double value=0.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t2+(-p0+3*p1-3*p2+p3)*t3);
         value=MathMax(minV,MathMin(maxV,value));int py=bottom-(int)MathRound((value-minV)/(maxV-minV)*(bottom-top));
         FinalEquityPixel("DOT"+IntegerToString(dot++),left+pixel,py,3,3,C'45,105,255');
      }
   }
   DrawCell("FINAL_EQ","NET",EA_Bottom_Left,panelX,panelY,width,height,width-135,5,129,20,"NET "+(totalNet>=0?"+":"")+DoubleToString(totalNet,2),totalNet>=0?C'0,255,170':C'255,64,96',C'15,30,55',9);
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
int OnInit()
{
   RESET_BUTTON_NAME=PREFIX+"UI_RESET_PROTECTION";
   TRACKER_BUTTON_NAME=PREFIX+"UI_TRACKER_TOGGLE";
   if(GlobalVariableCheck(ProtectionResetKey()))gProtectionResetTime=(datetime)GlobalVariableGet(ProtectionResetKey());
   if(gProtectionResetTime<StrToTime(TimeToString(TimeCurrent(),TIME_DATE))||gProtectionResetTime>TimeCurrent())gProtectionResetTime=0;
   // Remove stale UI objects from a previous preserved tester run, then create
   // the current layout once with the latest responsive geometry.
   DeletePanelObjects();
   ObjectsDeleteAll(0,PREFIX+"FINAL_EQ_");
   ObjectsDeleteAll(0,PREFIX+"FILTER_PLOT_");
   gBuyOrbResource="::SF_BUY_ORB_"+IntegerToString((int)ChartID());
   gSellOrbResource="::SF_SELL_ORB_"+IntegerToString((int)ChartID());
   CreateSignalOrbResource(true);CreateSignalOrbResource(false);
   ArrayInitialize(gBull,false);ArrayInitialize(gBear,false);ArrayInitialize(gDrawFilter,false);
   // Drawing policy is fixed to Supertrend only; trading-filter enables and
   // weighted signal calculations remain completely independent.
   for(int drawIndex=0;drawIndex<11;drawIndex++)gDrawFilter[drawIndex]=false;
   gDrawFilter[3]=EnableSupertrend&&DrawSupertrendOnChart;
   gShowEnabledOnly=(InitialFilterPanelMode==Show_Activated_Filters_Only);
   if(!IsTesting() || IsVisualMode()){ApplyChartTheme();UpdateFilterChartDrawings();UpdateDashboard();}
   // Timer-driven graphics are disabled in Strategy Tester. Visual tests
   // update once per bar/trade instead, allowing the Skip button to work.
   if(!IsTesting()) EventSetTimer(1);
   // Attach/recompile/input changes must never replay the already-closed
   // candle as a fresh entry signal. Seed both guards to the current chart.
   gLastBar=iTime(NULL,0,0);
   int initialShift=(int)MathMax(1,SignalShift);
   gLastProcessedSignalCandle=iTime(NULL,0,initialShift);
   if(gLastProcessedSignalCandle>0)GlobalVariableSet(ProcessedSignalKey(),(double)gLastProcessedSignalCandle);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   if(IsTesting() && IsVisualMode() && KeepVisualsAfterBacktest)
   {
      // Preserve the responsive dashboards and regular chart drawings at the
      // end of a visual test.
      UpdateDashboard();
      UpdateFilterChartDrawings();
      gKnownResultHistory=-1;UpdateClosedTradeResults();
      UpdatePanelPositions();
      DestroyEquityCurve();
      // Do not explicitly free signal bitmap resources in preserve mode.
      ChartRedraw(0);
      return;
   }
   DestroyEquityCurve();
   ObjectsDeleteAll(0,PREFIX);
   if(gBuyOrbResource!="")ResourceFree(gBuyOrbResource);
   if(gSellOrbResource!="")ResourceFree(gSellOrbResource);
}

void OnTimer()
{
   DrawTradeLines();
   // Live charts advance continuously; force screen cards to follow their
   // time/price anchors even when order history has not changed.
   gKnownResultHistory=-1;
   UpdateClosedTradeResults();
   UpdateDashboard();
   UpdateEquityCurve();
}

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   if(id==CHARTEVENT_OBJECT_CLICK&&sparam==RESET_BUTTON_NAME)
   {
      gProtectionResetTime=TimeCurrent();GlobalVariableSet(ProtectionResetKey(),(double)gProtectionResetTime);
      gLastAction="LOSS PROTECTION RESET";ObjectSetInteger(0,sparam,OBJPROP_STATE,false);DeletePanelObjects();UpdateDashboard();return;
   }
   if(id==CHARTEVENT_OBJECT_CLICK&&sparam==TRACKER_BUTTON_NAME)
   {
      gShowProfitTracker=!gShowProfitTracker;ObjectSetInteger(0,sparam,OBJPROP_STATE,false);DeletePanelObjects();UpdateDashboard();return;
   }
   if(id==CHARTEVENT_OBJECT_CLICK && sparam==FILTER_BUTTON_NAME)
   {
      gShowEnabledOnly=!gShowEnabledOnly;
      ObjectSetInteger(0,FILTER_BUTTON_NAME,OBJPROP_STATE,false);
      UpdateDashboard();
   }
   string drawPrefix=PREFIX+"FILTER_DRAW_";
   if(id==CHARTEVENT_OBJECT_CLICK && StringFind(sparam,drawPrefix,0)==0)
   {
      int index=(int)StringToInteger(StringSubstr(sparam,StringLen(drawPrefix)));
      if(index>=0 && index<11 && IsTradingFilterEnabled(index))
      {
         gDrawFilter[index]=!gDrawFilter[index];
         ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
         UpdateFilterChartDrawings();
         UpdateDashboard();
      }
   }
   if(id==CHARTEVENT_CHART_CHANGE)
   {
      // Screen-space result cards must follow chart scrolling immediately.
      // In Visual Tester cap refreshes at five per second so Skip remains fast
      // while perceived card movement stays effectively delay-free.
      uint now=GetTickCount();
      bool refreshNow=(!IsTesting() || now-gLastChartResultRefresh>=(uint)MathMax(25,ResultMovementRefreshMs));
      if(refreshNow)
      {
         gKnownResultHistory=-1;
         gEquityHistoryTotal=-1;
         UpdateClosedTradeResults();
         UpdateEquityCurve();
         gLastChartResultRefresh=now;
         gChartLayoutDirty=false;
      }
      else gChartLayoutDirty=true;
      UpdatePanelPositions();
   }
}

void OnTick()
{
   ManageBreakEven();
   ManageTrailing();
   EnforceDailyLossClose();
   if(Bars<100) return;
   bool allowGraphics=(!IsTesting() || IsVisualMode());
   bool historyChanged=(OrdersHistoryTotal()!=gKnownResultHistory);
   if(allowGraphics && historyChanged)
   {
      // Create/update result cards first, then recreate foreground panels so
      // cards remain behind those panels for the rest of their lifetime.
      UpdateClosedTradeResults();
      ObjectsDeleteAll(0,PREFIX+"SIG_");
      ObjectsDeleteAll(0,PREFIX+"PERF_");
      ObjectsDeleteAll(0,PREFIX+"ACCOUNT_");
      DestroyEquityCurve();gEquityHistoryTotal=-1;
      UpdateDashboard();
      UpdateEquityCurve();
      DrawTradeLines();
   }
   else if(allowGraphics)
   {
      // Keep every result card locked to its trade-close time/price as the
      // live chart or Visual Tester advances. Every-tick mode has no delay.
      uint motionNow=GetTickCount();
      uint refreshDelay=(uint)MathMax(25,ResultMovementRefreshMs);
      if(MoveResultCardsEveryTick || motionNow-gLastChartResultRefresh>=refreshDelay)
      {
         gKnownResultHistory=-1;
         UpdateClosedTradeResults();
         gLastChartResultRefresh=motionNow;
      }
   }
   if(Time[0]==gLastBar)
   {
      if(allowGraphics)UpdateDashboard();
      return;
   }
   gLastBar=Time[0];
   if(gChartLayoutDirty)
   {
      gKnownResultHistory=-1;
      gEquityHistoryTotal=-1;
      gChartLayoutDirty=false;
   }

   int shift=(int)MathMax(1,SignalShift); // closed candle only; never repaint with shift 0
   datetime signalCandleTime=iTime(NULL,0,shift);
   datetime sharedProcessed=GlobalVariableCheck(ProcessedSignalKey())?(datetime)GlobalVariableGet(ProcessedSignalKey()):0;
   if(sharedProcessed>gLastProcessedSignalCandle)gLastProcessedSignalCandle=sharedProcessed;
   if(signalCandleTime<=0||signalCandleTime<=gLastProcessedSignalCandle)
   {
      if(allowGraphics)UpdateDashboard();
      return;
   }
   // Claim this closed candle before evaluating or sending. Reinitialization,
   // duplicate charts and failed entry attempts cannot replay it later.
   gLastProcessedSignalCandle=signalCandleTime;
   GlobalVariableSet(ProcessedSignalKey(),(double)signalCandleTime);
   GetConditions(shift,gBull,gBear);
   CombinedSignal(gBull,gBear,gLongSignal,gShortSignal);
   int direction=gLongSignal?1:(gShortSignal?-1:0);
   gCandleScore=direction==0?0:CandleConfirmationScore(shift,direction);
   if(UseCandleConfirmation&&gCandleScore<MinimumCandleScore){gLongSignal=false;gShortSignal=false;}
   bool enterLong=gLongSignal;
   bool enterShort=gShortSignal;
   if(allowGraphics)
   {
      DrawHistoricalSignalOrbs();
      UpdateFilterChartDrawings();
      if(DrawBuySellSignalOrbs && enterLong) DrawSignalOrb(true,shift);
      if(DrawBuySellSignalOrbs && enterShort) DrawSignalOrb(false,shift);
   }

   int currentType;int ticket=ActiveTicket(currentType);
   if(CloseOnOppositeSignal && ticket>=0)
   {
      if((currentType==OP_BUY && gShortSignal) || (currentType==OP_SELL && gLongSignal))
      {
         if(CloseActivePosition()) { gLastAction="CLOSED ON OPPOSITE"; ticket=-1; }
      }
   }
   if((!OnePositionOnly || ticket<0)&&!(enterLong&&enterShort)&&(enterLong||enterShort)&&ProtectionAllowsEntry())
   {
      if(enterLong)OpenPosition(OP_BUY);
      else if(enterShort)OpenPosition(OP_SELL);
   }
   if(allowGraphics)
   {
      DrawTradeLines();
      UpdateClosedTradeResults();
      UpdateDashboard();
      UpdateEquityCurve();
   }
}
//+------------------------------------------------------------------+
