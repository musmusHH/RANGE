#property strict
#property version   "1.00"
#property description "Signal Forge Pro - score-based XAUUSD M5 Expert Advisor"

//====================================================================
// Signal Forge Pro XAUUSD M5 EA
// Native MT4 implementation. No DLLs, APIs, martingale, grid or averaging.
//====================================================================

enum ENUM_PRO_TP_MODE { TP_FixedPoints=0, TP_ATR=1 };
enum ENUM_PRO_PANEL_CORNER { Panel_TopLeft=0, Panel_TopRight=1, Panel_BottomLeft=2, Panel_BottomRight=3 };

//========== GENERAL ==========
input string GeneralSection="========== GENERAL ==========";
input int    MagicNumber=26051601;
input string TradeComment="Signal Forge Pro";
input bool   OneTradeAtATime=true;
input int    SlippagePoints=30;
input bool   AllowBuyTrades=true;
input bool   AllowSellTrades=true;

//========== SIGNAL ENGINE ==========
input string SignalSection="========== SIGNAL ENGINE ==========";
input bool   UseSignalScore=true;
input double MinimumSignalScore=5.0;
input int    SignalShift=1;
input bool EnableSMA=true;
input double SMAWeight=1.0;
input int SMAFastPeriod=20;
input int SMASlowPeriod=50;
input bool EnableEMA=true;
input double EMAWeight=1.0;
input int EMAFastPeriod=12;
input int EMASlowPeriod=26;
input bool EnableRSI=true;
input double RSIWeight=1.0;
input int RSIPeriod=14;
input double RSIBullLevel=55.0;
input double RSIBearLevel=45.0;
input bool EnableMACD=true;
input double MACDWeight=1.0;
input int MACDFastEMA=12;
input int MACDSlowEMA=26;
input int MACDSignalPeriod=9;
input bool EnableSupertrend=true;
input double SupertrendWeight=1.0;
input int SupertrendATRPeriod=10;
input double SupertrendMultiplier=3.0;
input int SupertrendCalculationBars=300;
input bool EnableStochastic=true;
input double StochasticWeight=1.0;
input int StochasticK=5;
input int StochasticD=3;
input int StochasticSlowing=3;
input double StochasticBullFloor=50.0;
input double StochasticBearCeiling=50.0;
input bool EnableBollinger=true;
input double BollingerWeight=1.0;
input int BollingerPeriod=20;
input double BollingerDeviation=2.0;
input bool EnableAO=true;
input double AOWeight=1.0;
input bool EnableSAR=true;
input double SARWeight=1.0;
input double SARStep=0.02;
input double SARMaximum=0.20;
input bool EnableCCI=true;
input double CCIWeight=1.0;
input int CCIPeriod=14;
input double CCIBullLevel=100.0;
input double CCIBearLevel=-100.0;
input bool EnableADX=true;
input double ADXWeight=1.0;
input int ADXPeriod=14;
input double ADXMinimumStrength=20.0;

//========== CANDLE CONFIRMATION ==========
input string CandleSection="========== CANDLE CONFIRMATION ==========";
input bool   UseCandleConfirmation=true;
input int    MinimumCandleScore=3;
input double MinBodyATR=0.50;
input double MinBodyPercent=60.0;
input double MinCloseLocation=75.0;
input double MinRangeATR=0.80;

//========== VOLUME ==========
input string VolumeSection="========== VOLUME ==========";
input bool   UseVolumeConfirmation=false;
input int    VolumeLookback=20;
input double VolumeMultiplier=1.20;

//========== ATR ==========
input string ATRSection="========== ATR ==========";
input bool   UseATRStopLoss=true;
input int    ATRPeriod=14;
input double ATRMultiplier=1.5;
input int    FixedStopLossPoints=1200;

//========== RISK MANAGEMENT ==========
input string RiskSection="========== RISK MANAGEMENT ==========";
input bool   UseRiskPercent=false;
input double RiskPercent=1.0;
input double FixedLot=0.01;
input bool   UseMaximumMoneyRisk=true;
input double MaximumRiskPerTradeMoney=2.00;

//========== SPREAD ==========
input string SpreadSection="========== SPREAD ==========";
input bool   UseSpreadFilter=true;
input double MaximumSpreadPoints=100.0;

//========== TAKE PROFIT ==========
input string TPSection="========== TAKE PROFIT ==========";
input ENUM_PRO_TP_MODE TakeProfitMode=TP_FixedPoints;
input int    FixedTPPoints=2000;
input double TP_ATR_Multiplier=2.0;
input bool   UseRiskRewardTP=false;
input double RiskRewardRatio=2.0;

//========== BREAK EVEN ==========
input string BreakEvenSection="========== BREAK EVEN ==========";
input bool   UseBreakEven=true;
input int    BreakEvenStartPoints=400;
input int    BreakEvenOffsetPoints=50;

//========== TRAILING ==========
input string TrailingSection="========== TRAILING ==========";
input bool   UseTrailingStop=true;
input int    TrailingStartPoints=700;
input int    TrailingDistancePoints=700;
input int    TrailingStepPoints=100;
input bool   TrailingMustLockProfit=true;

//========== SESSION ==========
input string SessionSection="========== SESSION ==========";
input bool   UseTradingSession=false;
input int    SessionStartHour=0;
input int    SessionStartMinute=0;
input int    SessionEndHour=23;
input int    SessionEndMinute=59;
input bool   UseNewsFilter=false; // No native reliable MT4 calendar: enabling safely blocks entries.

//========== PROTECTION ==========
input string ProtectionSection="========== PROTECTION ==========";
input bool   StopTradingAfterDailyLoss=true;
input double MaximumDailyLossMoney=10.0;
input double MaximumDailyLossPercent=10.0;
input bool   CloseTradesOnDailyLoss=false;
input bool   StopTradingAfterConsecutiveLosses=true;
input int    MaximumConsecutiveLosses=3;

//========== VISUAL ==========
input string VisualSection="========== VISUAL ==========";
input bool   KeepTradeHistory=true;
input int    MaxHistoricalTradesToDraw=200;
input bool   DrawSignalMarkers=true;
input bool   DrawSignalDetails=true;
input int    SignalHistoryBars=300;
input bool   KeepVisualsAfterVisualTest=true;
input color  BuyColor=C'0,230,118';
input color  SellColor=C'255,82,82';
input color  AccentColor=C'0,229,255';
input color  WarningColor=C'255,193,7';
input color  PanelBackground=C'11,16,32';
input color  CardBackground=C'23,32,51';
input color  PrimaryText=C'245,247,250';
input color  SecondaryText=C'148,163,184';

//========== PANEL ==========
input string PanelSection="========== PANEL ==========";
input bool   ShowPanel=true;
input ENUM_PRO_PANEL_CORNER PanelCorner=Panel_TopLeft;
input int    PanelX=15;
input int    PanelY=20;
input int    PanelWidth=520;
input int    PanelHeight=330;

#define SFP_TF PERIOD_M5
string PFX="SFP_";
datetime gLastSignalBar=0;
int gLastHistoryTotal=-1;
double gBuyScore=0,gSellScore=0,gATR=0,gCandleScore=0;
int gCandidate=0;
string gSignalState="NO SIGNAL";
double gPlannedLot=0,gPlannedRisk=0;
bool gVolumePassed=true;

struct ProStats
{
   int total,wins,losses,currentConsecutive,maxConsecutive;
   double net,grossWin,grossLoss,averageWin,averageLoss,profitFactor,winRate,dailyPL;
};
ProStats gStats;

int PriceDigits(){return (int)MarketInfo(Symbol(),MODE_DIGITS);}
double PricePoint(){double p=MarketInfo(Symbol(),MODE_POINT);return p>0?p:Point;}
double NormalizePrice(double p){return NormalizeDouble(p,PriceDigits());}
double BrokerTickSizePrice()
{
   double point=PricePoint(),ts=MarketInfo(Symbol(),MODE_TICKSIZE);
   if(ts<=0)return point;
   if(ts>=1.0)ts*=point;
   return ts;
}
int LotDigits()
{
   double step=MarketInfo(Symbol(),MODE_LOTSTEP);
   if(step>=1.0)return 0;if(step>=0.1)return 1;if(step>=0.01)return 2;if(step>=0.001)return 3;return 4;
}
double NormalizeLotDown(double lots)
{
   double minLot=MarketInfo(Symbol(),MODE_MINLOT),maxLot=MarketInfo(Symbol(),MODE_MAXLOT),step=MarketInfo(Symbol(),MODE_LOTSTEP);
   if(step<=0)step=0.01;
   lots=MathFloor((lots+1e-10)/step)*step;
   lots=MathMin(maxLot,lots);
   if(lots<minLot-1e-10)return 0;
   return NormalizeDouble(lots,LotDigits());
}
double StopFreezeDistancePrice()
{
   double levels=MathMax(MarketInfo(Symbol(),MODE_STOPLEVEL),MarketInfo(Symbol(),MODE_FREEZELEVEL));
   return levels*PricePoint();
}
string TFName(){return "M5";}
string TicketKey(int ticket,string suffix){return "SFP."+IntegerToString(AccountNumber())+"."+IntegerToString(MagicNumber)+"."+IntegerToString(ticket)+"."+suffix;}

bool IsOurMarketOrder()
{
   return OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber && (OrderType()==OP_BUY||OrderType()==OP_SELL);
}

int FindActiveTrade()
{
   for(int i=OrdersTotal()-1;i>=0;i--)
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && IsOurMarketOrder())return OrderTicket();
   return -1;
}

bool SelectActiveTicket(int ticket)
{
   return ticket>0 && OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES) && IsOurMarketOrder();
}

bool SupertrendAtShift(int shift,double &line,int &direction)
{
   int bars=iBars(Symbol(),SFP_TF);
   if(bars<=shift+SupertrendATRPeriod+5)return false;
   int oldest=(int)MathMin(bars-2,shift+(int)MathMax(60,SupertrendCalculationBars));
   double prevUpper=0,prevLower=0,prevST=0;
   for(int i=oldest;i>=shift;i--)
   {
      double atr=iATR(Symbol(),SFP_TF,SupertrendATRPeriod,i);
      if(atr<=0)return false;
      double mid=(iHigh(Symbol(),SFP_TF,i)+iLow(Symbol(),SFP_TF,i))*0.5;
      double basicUpper=mid+SupertrendMultiplier*atr,basicLower=mid-SupertrendMultiplier*atr;
      if(i==oldest)
      {
         prevUpper=basicUpper;prevLower=basicLower;prevST=basicUpper;
         if(i==shift){line=prevST;direction=iClose(Symbol(),SFP_TF,i)>line?1:-1;return true;}
         continue;
      }
      double priorClose=iClose(Symbol(),SFP_TF,i+1);
      double upper=(basicUpper<prevUpper || priorClose>prevUpper)?basicUpper:prevUpper;
      double lower=(basicLower>prevLower || priorClose<prevLower)?basicLower:prevLower;
      double st;
      if(MathAbs(prevST-prevUpper)<=PricePoint()*0.5)st=(iClose(Symbol(),SFP_TF,i)>upper)?lower:upper;
      else st=(iClose(Symbol(),SFP_TF,i)<lower)?upper:lower;
      prevUpper=upper;prevLower=lower;prevST=st;
      if(i==shift){line=st;direction=iClose(Symbol(),SFP_TF,i)>st?1:-1;return true;}
   }
   return false;
}

void AddVote(bool bullish,bool bearish,double weight,double &buyScore,double &sellScore)
{
   if(weight<=0)return;
   if(bullish)buyScore+=weight;
   if(bearish)sellScore+=weight;
}

double MaximumEnabledScore()
{
   double total=0;
   if(EnableSMA)total+=MathMax(0,SMAWeight);if(EnableEMA)total+=MathMax(0,EMAWeight);if(EnableRSI)total+=MathMax(0,RSIWeight);
   if(EnableMACD)total+=MathMax(0,MACDWeight);if(EnableSupertrend)total+=MathMax(0,SupertrendWeight);if(EnableStochastic)total+=MathMax(0,StochasticWeight);
   if(EnableBollinger)total+=MathMax(0,BollingerWeight);if(EnableAO)total+=MathMax(0,AOWeight);if(EnableSAR)total+=MathMax(0,SARWeight);
   if(EnableCCI)total+=MathMax(0,CCIWeight);if(EnableADX)total+=MathMax(0,ADXWeight);
   return MathMax(1,total);
}

void CalculateSignalScores(int shift,double &buyScore,double &sellScore)
{
   buyScore=0;sellScore=0;
   double close=iClose(Symbol(),SFP_TF,shift);
   if(EnableSMA)
   {
      double fast=iMA(Symbol(),SFP_TF,SMAFastPeriod,0,MODE_SMA,PRICE_CLOSE,shift),slow=iMA(Symbol(),SFP_TF,SMASlowPeriod,0,MODE_SMA,PRICE_CLOSE,shift);
      AddVote(fast>slow,fast<slow,SMAWeight,buyScore,sellScore);
   }
   if(EnableEMA)
   {
      double fast=iMA(Symbol(),SFP_TF,EMAFastPeriod,0,MODE_EMA,PRICE_CLOSE,shift),slow=iMA(Symbol(),SFP_TF,EMASlowPeriod,0,MODE_EMA,PRICE_CLOSE,shift);
      AddVote(fast>slow,fast<slow,EMAWeight,buyScore,sellScore);
   }
   if(EnableRSI)
   {
      double rsi=iRSI(Symbol(),SFP_TF,RSIPeriod,PRICE_CLOSE,shift);
      AddVote(rsi>=RSIBullLevel,rsi<=RSIBearLevel,RSIWeight,buyScore,sellScore);
   }
   if(EnableMACD)
   {
      double main=iMACD(Symbol(),SFP_TF,MACDFastEMA,MACDSlowEMA,MACDSignalPeriod,PRICE_CLOSE,MODE_MAIN,shift);
      double signal=iMACD(Symbol(),SFP_TF,MACDFastEMA,MACDSlowEMA,MACDSignalPeriod,PRICE_CLOSE,MODE_SIGNAL,shift);
      AddVote(main>signal,main<signal,MACDWeight,buyScore,sellScore);
   }
   if(EnableSupertrend)
   {
      double st=0;int dir=0;if(SupertrendAtShift(shift,st,dir))AddVote(dir>0,dir<0,SupertrendWeight,buyScore,sellScore);
   }
   if(EnableStochastic)
   {
      double k=iStochastic(Symbol(),SFP_TF,StochasticK,StochasticD,StochasticSlowing,MODE_SMA,0,MODE_MAIN,shift);
      double d=iStochastic(Symbol(),SFP_TF,StochasticK,StochasticD,StochasticSlowing,MODE_SMA,0,MODE_SIGNAL,shift);
      AddVote(k>d&&k>=StochasticBullFloor,k<d&&k<=StochasticBearCeiling,StochasticWeight,buyScore,sellScore);
   }
   if(EnableBollinger)
   {
      double mid=iBands(Symbol(),SFP_TF,BollingerPeriod,BollingerDeviation,0,PRICE_CLOSE,MODE_MAIN,shift);
      AddVote(close>mid,close<mid,BollingerWeight,buyScore,sellScore);
   }
   if(EnableAO)
   {
      double ao=iAO(Symbol(),SFP_TF,shift);AddVote(ao>0,ao<0,AOWeight,buyScore,sellScore);
   }
   if(EnableSAR)
   {
      double sar=iSAR(Symbol(),SFP_TF,SARStep,SARMaximum,shift);AddVote(close>sar,close<sar,SARWeight,buyScore,sellScore);
   }
   if(EnableCCI)
   {
      double cci=iCCI(Symbol(),SFP_TF,CCIPeriod,PRICE_TYPICAL,shift);AddVote(cci>=CCIBullLevel,cci<=CCIBearLevel,CCIWeight,buyScore,sellScore);
   }
   if(EnableADX)
   {
      double adx=iADX(Symbol(),SFP_TF,ADXPeriod,PRICE_CLOSE,MODE_MAIN,shift);
      double plus=iADX(Symbol(),SFP_TF,ADXPeriod,PRICE_CLOSE,MODE_PLUSDI,shift),minus=iADX(Symbol(),SFP_TF,ADXPeriod,PRICE_CLOSE,MODE_MINUSDI,shift);
      AddVote(adx>=ADXMinimumStrength&&plus>minus,adx>=ADXMinimumStrength&&minus>plus,ADXWeight,buyScore,sellScore);
   }
}

int SelectSignalDirection(double buyScore,double sellScore)
{
   if(!UseSignalScore)return 0;
   if(buyScore>=MinimumSignalScore && buyScore>sellScore)return 1;
   if(sellScore>=MinimumSignalScore && sellScore>buyScore)return -1;
   return 0;
}

bool CheckVolumeConfirmation(int shift,double &ratio)
{
   ratio=0;
   if(!UseVolumeConfirmation)return true;
   int lookback=(int)MathMax(1,VolumeLookback);double sum=0;
   for(int i=shift+1;i<=shift+lookback;i++)sum+=(double)iVolume(Symbol(),SFP_TF,i);
   double average=sum/lookback,current=(double)iVolume(Symbol(),SFP_TF,shift);
   if(average<=0)return false;
   ratio=current/average;
   return current>=average*VolumeMultiplier;
}

int CalculateCandleScore(int shift,int direction,double atr,bool &volumePassed)
{
   double open=iOpen(Symbol(),SFP_TF,shift),close=iClose(Symbol(),SFP_TF,shift),high=iHigh(Symbol(),SFP_TF,shift),low=iLow(Symbol(),SFP_TF,shift);
   double range=high-low,body=MathAbs(close-open);volumePassed=true;
   if(range<=0 || atr<=0)return 0;
   if((direction>0&&close<=open)||(direction<0&&close>=open))return 0;
   int score=0;
   if(body/atr>=MinBodyATR)score++;
   if(body/range*100.0>=MinBodyPercent)score++;
   double location=direction>0?(close-low)/range*100.0:(high-close)/range*100.0;
   if(location>=MinCloseLocation)score++;
   if(range/atr>=MinRangeATR)score++;
   double volumeRatio=0;volumePassed=CheckVolumeConfirmation(shift,volumeRatio);
   if(UseVolumeConfirmation && volumePassed)score++;
   return score;
}

bool CheckSpread(double &spreadPoints)
{
   RefreshRates();spreadPoints=(Ask-Bid)/PricePoint();
   return !UseSpreadFilter || spreadPoints<=MaximumSpreadPoints;
}

bool CheckTradingSession(datetime when)
{
   if(!UseTradingSession)return true;
   int nowMinutes=TimeHour(when)*60+TimeMinute(when);
   int start=(int)MathMax(0,MathMin(1439,SessionStartHour*60+SessionStartMinute));
   int finish=(int)MathMax(0,MathMin(1439,SessionEndHour*60+SessionEndMinute));
   if(start<=finish)return nowMinutes>=start&&nowMinutes<=finish;
   return nowMinutes>=start||nowMinutes<=finish;
}

datetime BrokerDayStart(datetime when){return StrToTime(TimeToString(when,TIME_DATE));}

void UpdateStatistics()
{
   ZeroMemory(gStats);datetime dayStart=BrokerDayStart(TimeCurrent());
   int runningLosses=0;bool currentSequence=true;
   for(int i=OrdersHistoryTotal()-1;i>=0;i--)
   {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)||!IsOurMarketOrder())continue;
      double result=OrderProfit()+OrderSwap()+OrderCommission();
      gStats.total++;gStats.net+=result;
      if(OrderCloseTime()>=dayStart)gStats.dailyPL+=result;
      if(result>0){gStats.wins++;gStats.grossWin+=result;if(currentSequence)currentSequence=false;}
      else if(result<0)
      {
         gStats.losses++;gStats.grossLoss+=-result;
         if(currentSequence)gStats.currentConsecutive++;
      }
   }
   runningLosses=0;
   for(int j=0;j<OrdersHistoryTotal();j++)
   {
      if(!OrderSelect(j,SELECT_BY_POS,MODE_HISTORY)||!IsOurMarketOrder())continue;
      double value=OrderProfit()+OrderSwap()+OrderCommission();
      if(value<0){runningLosses++;gStats.maxConsecutive=(int)MathMax(gStats.maxConsecutive,runningLosses);}else if(value>0)runningLosses=0;
   }
   if(gStats.total>0)gStats.winRate=100.0*gStats.wins/gStats.total;
   if(gStats.wins>0)gStats.averageWin=gStats.grossWin/gStats.wins;
   if(gStats.losses>0)gStats.averageLoss=gStats.grossLoss/gStats.losses;
   gStats.profitFactor=gStats.grossLoss>0?gStats.grossWin/gStats.grossLoss:(gStats.grossWin>0?999.0:0.0);
}

bool DailyLossReached()
{
   if(!StopTradingAfterDailyLoss)return false;
   double loss=MathMax(0,-gStats.dailyPL);
   bool money=MaximumDailyLossMoney>0&&loss>=MaximumDailyLossMoney;
   double dayStartBalance=AccountBalance()-gStats.dailyPL;
   bool percent=MaximumDailyLossPercent>0&&dayStartBalance>0&&loss/dayStartBalance*100.0>=MaximumDailyLossPercent;
   return money||percent;
}
bool ConsecutiveLossReached(){return StopTradingAfterConsecutiveLosses&&MaximumConsecutiveLosses>0&&gStats.currentConsecutive>=MaximumConsecutiveLosses;}
bool CheckDailyLoss(){return !DailyLossReached();}
bool CheckConsecutiveLosses(){return !ConsecutiveLossReached();}

bool CalculateATRStopLoss(int direction,double entry,double atr,double &sl)
{
   double distance=UseATRStopLoss?atr*ATRMultiplier:FixedStopLossPoints*PricePoint();
   distance=MathMax(distance,StopFreezeDistancePrice()+PricePoint());
   if(distance<=0)return false;
   sl=NormalizePrice(direction>0?entry-distance:entry+distance);
   return true;
}

double CalculateMoneyRisk(double lots,double entry,double sl)
{
   double tickSize=BrokerTickSizePrice(),tickValue=MarketInfo(Symbol(),MODE_TICKVALUE);
   if(lots<=0||tickSize<=0||tickValue<=0)return -1;
   return MathAbs(entry-sl)/tickSize*tickValue*lots;
}

double CalculateRiskBasedLot(double entry,double sl,double &moneyRisk)
{
   double minLot=MarketInfo(Symbol(),MODE_MINLOT);
   double perLot=CalculateMoneyRisk(1.0,entry,sl);
   if(perLot<=0){moneyRisk=-1;return 0;}
   double desired=FixedLot;
   if(UseRiskPercent)desired=AccountBalance()*MathMax(0,RiskPercent)/100.0/perLot;
   if(UseMaximumMoneyRisk&&MaximumRiskPerTradeMoney>0)desired=MathMin(desired,MaximumRiskPerTradeMoney/perLot);
   double lots=NormalizeLotDown(desired);
   if(lots<=0 || lots<minLot-1e-10){moneyRisk=perLot*minLot;return 0;}
   moneyRisk=perLot*lots;
   if(UseMaximumMoneyRisk&&MaximumRiskPerTradeMoney>0&&moneyRisk>MaximumRiskPerTradeMoney+0.01)return 0;
   return lots;
}

void ConformInitialStops(int direction,double &sl,double &tp)
{
   double minimum=StopFreezeDistancePrice()+PricePoint();
   RefreshRates();
   if(direction>0)
   {
      sl=MathMin(sl,Bid-minimum);
      if(tp>0)tp=MathMax(tp,Bid+minimum);
   }
   else
   {
      sl=MathMax(sl,Ask+minimum);
      if(tp>0)tp=MathMin(tp,Ask-minimum);
   }
   sl=NormalizePrice(sl);if(tp>0)tp=NormalizePrice(tp);
}

void CalculateTakeProfit(int direction,double entry,double sl,double atr,double &tp)
{
   if(UseRiskRewardTP)
   {
      double risk=MathAbs(entry-sl);tp=direction>0?entry+risk*RiskRewardRatio:entry-risk*RiskRewardRatio;
   }
   else
   {
      double distance=TakeProfitMode==TP_ATR?atr*TP_ATR_Multiplier:FixedTPPoints*PricePoint();
      tp=direction>0?entry+distance:entry-distance;
   }
   double minimum=StopFreezeDistancePrice()+PricePoint();
   if(direction>0)tp=MathMax(tp,entry+minimum);else tp=MathMin(tp,entry-minimum);
   tp=NormalizePrice(tp);
}

bool ValidateBrokerData()
{
   double values[7];
   values[0]=MarketInfo(Symbol(),MODE_MINLOT);values[1]=MarketInfo(Symbol(),MODE_MAXLOT);values[2]=MarketInfo(Symbol(),MODE_LOTSTEP);
   values[3]=MarketInfo(Symbol(),MODE_TICKVALUE);values[4]=BrokerTickSizePrice();values[5]=PricePoint();values[6]=MarketInfo(Symbol(),MODE_STOPLEVEL);
   for(int i=0;i<6;i++)if(values[i]<=0){Print("Invalid broker specification index=",i," value=",DoubleToString(values[i],8));return false;}
   return true;
}

string TradeBase(int ticket){return PFX+IntegerToString(MagicNumber)+"_T"+IntegerToString(ticket)+"_";}
void SetTrend(string name,datetime t1,double p1,datetime t2,double p2,color c,int style,int width)
{
   if(ObjectFind(0,name)<0)ObjectCreate(0,name,OBJ_TREND,0,t1,p1,t2,p2);
   else {ObjectMove(0,name,0,t1,p1);ObjectMove(0,name,1,t2,p2);}
   ObjectSetInteger(0,name,OBJPROP_RAY,false);ObjectSetInteger(0,name,OBJPROP_COLOR,c);ObjectSetInteger(0,name,OBJPROP_STYLE,style);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,width);ObjectSetInteger(0,name,OBJPROP_BACK,true);ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
}
void SetChartText(string name,datetime time,double price,string text,color c,int size,int anchor)
{
   if(ObjectFind(0,name)<0)ObjectCreate(0,name,OBJ_TEXT,0,time,price);else ObjectMove(0,name,0,time,price);
   ObjectSetString(0,name,OBJPROP_TEXT,text);ObjectSetString(0,name,OBJPROP_FONT,"Arial");ObjectSetInteger(0,name,OBJPROP_FONTSIZE,size);
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);ObjectSetInteger(0,name,OBJPROP_ANCHOR,anchor);ObjectSetInteger(0,name,OBJPROP_BACK,true);ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
}

void DrawSignal(int shift,int direction,double buyScore,double sellScore,int candleScore,double atr)
{
   if(!DrawSignalMarkers)return;
   datetime t=iTime(Symbol(),SFP_TF,shift);double gap=MathMax(atr*0.18,20*PricePoint());
   double price=direction>0?iLow(Symbol(),SFP_TF,shift)-gap:iHigh(Symbol(),SFP_TF,shift)+gap;
   string base=PFX+"SIG_"+IntegerToString((int)t);
   if(ObjectFind(0,base)<0)ObjectCreate(0,base,OBJ_ARROW,0,t,price);
   ObjectSetInteger(0,base,OBJPROP_ARROWCODE,direction>0?233:234);ObjectSetInteger(0,base,OBJPROP_COLOR,direction>0?BuyColor:SellColor);
   ObjectSetInteger(0,base,OBJPROP_WIDTH,2);ObjectSetInteger(0,base,OBJPROP_BACK,true);ObjectSetInteger(0,base,OBJPROP_SELECTABLE,false);
   if(DrawSignalDetails)
   {
      string info=(direction>0?"BUY ":"SELL ")+"B"+DoubleToString(buyScore,1)+" S"+DoubleToString(sellScore,1)+" C"+IntegerToString(candleScore)+" ATR "+DoubleToString(atr,PriceDigits());
      SetChartText(base+"_INFO",t,direction>0?price-gap:price+gap,info,direction>0?BuyColor:SellColor,8,direction>0?ANCHOR_UPPER:ANCHOR_LOWER);
   }
}

void DrawEntryLevels(int ticket)
{
   if(!OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)||!IsOurMarketOrder())return;
   string base=TradeBase(ticket);datetime start=OrderOpenTime(),finish=iTime(Symbol(),SFP_TF,0)+PeriodSeconds(SFP_TF)*8;
   SetTrend(base+"ENTRY",start,OrderOpenPrice(),finish,OrderOpenPrice(),AccentColor,STYLE_SOLID,1);
   if(OrderStopLoss()>0)SetTrend(base+"SL",start,OrderStopLoss(),finish,OrderStopLoss(),SellColor,STYLE_DASH,1);
   if(OrderTakeProfit()>0)SetTrend(base+"TP",start,OrderTakeProfit(),finish,OrderTakeProfit(),BuyColor,STYLE_DASH,1);
}

void DrawHistoricalTradeSelected()
{
   if(!IsOurMarketOrder()||OrderCloseTime()<=0)return;
   int ticket=OrderTicket();string base=TradeBase(ticket);datetime openTime=OrderOpenTime(),closeTime=OrderCloseTime();
   double initialSL=GlobalVariableCheck(TicketKey(ticket,"ISL"))?GlobalVariableGet(TicketKey(ticket,"ISL")):OrderStopLoss();
   double initialTP=GlobalVariableCheck(TicketKey(ticket,"ITP"))?GlobalVariableGet(TicketKey(ticket,"ITP")):OrderTakeProfit();
   double initialRisk=GlobalVariableCheck(TicketKey(ticket,"RISK"))?GlobalVariableGet(TicketKey(ticket,"RISK")):MathAbs(OrderOpenPrice()-initialSL);
   color directionColor=OrderType()==OP_BUY?BuyColor:SellColor;
   SetTrend(base+"ENTRY",openTime,OrderOpenPrice(),closeTime,OrderOpenPrice(),AccentColor,STYLE_SOLID,1);
   if(initialSL>0)SetTrend(base+"SL",openTime,initialSL,closeTime,initialSL,SellColor,STYLE_DOT,1);
   if(initialTP>0)SetTrend(base+"TP",openTime,initialTP,closeTime,initialTP,BuyColor,STYLE_DOT,1);
   SetTrend(base+"EXIT",closeTime-PeriodSeconds(SFP_TF),OrderClosePrice(),closeTime+PeriodSeconds(SFP_TF),OrderClosePrice(),directionColor,STYLE_SOLID,2);
   double result=OrderProfit()+OrderSwap()+OrderCommission();
   double r=initialRisk>0?(OrderType()==OP_BUY?(OrderClosePrice()-OrderOpenPrice()):(OrderOpenPrice()-OrderClosePrice()))/initialRisk:0;
   string text=(OrderType()==OP_BUY?"BUY":"SELL")+"  Entry "+DoubleToString(OrderOpenPrice(),PriceDigits())+"  SL "+DoubleToString(initialSL,PriceDigits())+"  TP "+DoubleToString(initialTP,PriceDigits())+"  Result "+(result>=0?"+$":"-$")+DoubleToString(MathAbs(result),2)+"  R "+(r>=0?"+":"")+DoubleToString(r,2);
   double offset=MathMax(iATR(Symbol(),SFP_TF,ATRPeriod,(int)MathMax(1,iBarShift(Symbol(),SFP_TF,closeTime,false)))*0.25,30*PricePoint());
   SetChartText(base+"RESULT",closeTime,OrderType()==OP_BUY?OrderClosePrice()+offset:OrderClosePrice()-offset,text,result>=0?BuyColor:SellColor,8,OrderType()==OP_BUY?ANCHOR_LOWER:ANCHOR_UPPER);
}

void DeleteTradeDrawingObjects(){ObjectsDeleteAll(0,PFX+IntegerToString(MagicNumber)+"_T");}

void RedrawActiveTradeLevels()
{
   for(int i=OrdersTotal()-1;i>=0;i--)
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)&&IsOurMarketOrder())DrawEntryLevels(OrderTicket());
}

void DrawHistoricalTrades()
{
   if(!KeepTradeHistory)return;
   int drawn=0,maximum=(int)MathMax(1,MathMin(500,MaxHistoricalTradesToDraw));
   for(int i=OrdersHistoryTotal()-1;i>=0&&drawn<maximum;i--)
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)&&IsOurMarketOrder()){DrawHistoricalTradeSelected();drawn++;}
}

void DrawHistoricalSignals()
{
   if(!DrawSignalMarkers)return;
   int maximum=(int)MathMin(MathMax(0,SignalHistoryBars),iBars(Symbol(),SFP_TF)-100);
   for(int shift=maximum;shift>=1;shift--)
   {
      double buy=0,sell=0;CalculateSignalScores(shift,buy,sell);int direction=SelectSignalDirection(buy,sell);if(direction==0)continue;
      double atr=iATR(Symbol(),SFP_TF,ATRPeriod,shift);bool volumeOK=true;int candle=CalculateCandleScore(shift,direction,atr,volumeOK);
      if(UseCandleConfirmation&&candle<MinimumCandleScore)continue;
      DrawSignal(shift,direction,buy,sell,candle,atr);
   }
}

bool ModifySelectedOrder(double newSL,double newTP,string source)
{
   ResetLastError();bool ok=OrderModify(OrderTicket(),OrderOpenPrice(),NormalizePrice(newSL),newTP>0?NormalizePrice(newTP):0,0,clrNONE);
   if(!ok)Print(source," OrderModify failed. Error=",GetLastError()," Ticket=",OrderTicket()," Price=",DoubleToString(OrderOpenPrice(),PriceDigits())," SL=",DoubleToString(newSL,PriceDigits())," TP=",DoubleToString(newTP,PriceDigits()));
   return ok;
}

void ManageBreakEvenSelected()
{
   if(!UseBreakEven)return;
   double point=PricePoint(),minimum=StopFreezeDistancePrice()+point;
   if(OrderType()==OP_BUY)
   {
      double profit=(Bid-OrderOpenPrice())/point;if(profit<BreakEvenStartPoints)return;
      double candidate=NormalizePrice(OrderOpenPrice()+BreakEvenOffsetPoints*point);
      candidate=MathMin(candidate,NormalizePrice(Bid-minimum));
      if(candidate>OrderOpenPrice() && (OrderStopLoss()==0||candidate>OrderStopLoss()+point*0.5))ModifySelectedOrder(candidate,OrderTakeProfit(),"Break-even BUY");
   }
   else
   {
      double profit=(OrderOpenPrice()-Ask)/point;if(profit<BreakEvenStartPoints)return;
      double candidate=NormalizePrice(OrderOpenPrice()-BreakEvenOffsetPoints*point);
      candidate=MathMax(candidate,NormalizePrice(Ask+minimum));
      if(candidate<OrderOpenPrice() && (OrderStopLoss()==0||candidate<OrderStopLoss()-point*0.5))ModifySelectedOrder(candidate,OrderTakeProfit(),"Break-even SELL");
   }
}

void ManageTrailingSelected()
{
   if(!UseTrailingStop)return;
   double point=PricePoint(),minimum=StopFreezeDistancePrice()+point,step=MathMax(1,TrailingStepPoints)*point;
   if(OrderType()==OP_BUY)
   {
      if((Bid-OrderOpenPrice())/point<TrailingStartPoints)return;
      double candidate=NormalizePrice(Bid-MathMax(TrailingDistancePoints*point,minimum));
      if(TrailingMustLockProfit&&candidate<=OrderOpenPrice())return;
      if((OrderStopLoss()==0||candidate>OrderStopLoss()+step-0.1*point)&&candidate<Bid-minimum+0.1*point)ModifySelectedOrder(candidate,OrderTakeProfit(),"Trailing BUY");
   }
   else
   {
      if((OrderOpenPrice()-Ask)/point<TrailingStartPoints)return;
      double candidate=NormalizePrice(Ask+MathMax(TrailingDistancePoints*point,minimum));
      if(TrailingMustLockProfit&&candidate>=OrderOpenPrice())return;
      if((OrderStopLoss()==0||candidate<OrderStopLoss()-step+0.1*point)&&candidate>Ask+minimum-0.1*point)ModifySelectedOrder(candidate,OrderTakeProfit(),"Trailing SELL");
   }
}

void CloseSelectedForProtection()
{
   RefreshRates();double price=OrderType()==OP_BUY?Bid:Ask;ResetLastError();
   if(!OrderClose(OrderTicket(),OrderLots(),price,SlippagePoints,WarningColor))
      Print("OrderClose daily protection failed. Error=",GetLastError()," Ticket=",OrderTicket()," Lots=",DoubleToString(OrderLots(),LotDigits())," Price=",DoubleToString(price,PriceDigits()));
}

void ManageTrade()
{
   bool closeForDay=CloseTradesOnDailyLoss&&DailyLossReached();
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)||!IsOurMarketOrder())continue;
      if(closeForDay){CloseSelectedForProtection();continue;}
      ManageBreakEvenSelected();
      if(OrderSelect(OrderTicket(),SELECT_BY_TICKET,MODE_TRADES))ManageTrailingSelected();
      if(OrderSelect(OrderTicket(),SELECT_BY_TICKET,MODE_TRADES))DrawEntryLevels(OrderTicket());
   }
}

bool OpenTrade(int direction,double atr,datetime signalTime)
{
   if(direction>0&&!AllowBuyTrades)return false;if(direction<0&&!AllowSellTrades)return false;
   if(!IsTradeAllowed()){Print("Entry blocked: IsTradeAllowed() is false.");return false;}
   if(OneTradeAtATime&&FindActiveTrade()>0)return false;
   double spread=0;if(!CheckSpread(spread)){Print("Entry blocked by spread. SpreadPoints=",DoubleToString(spread,1)," Maximum=",DoubleToString(MaximumSpreadPoints,1));return false;}
   RefreshRates();double entry=direction>0?Ask:Bid,sl=0,tp=0;
   if(!CalculateATRStopLoss(direction,entry,atr,sl))return false;
   ConformInitialStops(direction,sl,tp);CalculateTakeProfit(direction,entry,sl,atr,tp);ConformInitialStops(direction,sl,tp);
   double moneyRisk=0,lots=CalculateRiskBasedLot(entry,sl,moneyRisk);gPlannedLot=lots;gPlannedRisk=moneyRisk;
   if(lots<=0){Print("Entry rejected: broker minimum lot exceeds risk limit or broker tick data is invalid. CalculatedRisk=",DoubleToString(moneyRisk,2));return false;}
   if(AccountFreeMarginCheck(Symbol(),direction>0?OP_BUY:OP_SELL,lots)<=0){Print("Entry rejected: insufficient free margin. Error=",GetLastError()," Lots=",DoubleToString(lots,LotDigits()));return false;}
   // Mandatory immediate pre-send spread recheck.
   if(!CheckSpread(spread)){Print("OrderSend cancelled by final spread check. SpreadPoints=",DoubleToString(spread,1));return false;}
   RefreshRates();entry=direction>0?Ask:Bid;tp=0;
   if(!CalculateATRStopLoss(direction,entry,atr,sl))return false;
   ConformInitialStops(direction,sl,tp);CalculateTakeProfit(direction,entry,sl,atr,tp);ConformInitialStops(direction,sl,tp);
   moneyRisk=CalculateMoneyRisk(lots,entry,sl);
   if(UseMaximumMoneyRisk&&MaximumRiskPerTradeMoney>0&&moneyRisk>MaximumRiskPerTradeMoney+0.01){Print("OrderSend cancelled: refreshed risk exceeds cap. Risk=",DoubleToString(moneyRisk,2));return false;}
   ResetLastError();int ticket=OrderSend(Symbol(),direction>0?OP_BUY:OP_SELL,lots,NormalizePrice(entry),SlippagePoints,sl,tp,TradeComment,MagicNumber,0,direction>0?BuyColor:SellColor);
   if(ticket<0)
   {
      Print("OrderSend failed. Error=",GetLastError()," Symbol=",Symbol()," Lots=",DoubleToString(lots,LotDigits())," Price=",DoubleToString(entry,PriceDigits())," SL=",DoubleToString(sl,PriceDigits())," TP=",DoubleToString(tp,PriceDigits())," Spread=",DoubleToString(spread,1));return false;
   }
   GlobalVariableSet(TicketKey(ticket,"ISL"),sl);GlobalVariableSet(TicketKey(ticket,"ITP"),tp);GlobalVariableSet(TicketKey(ticket,"RISK"),MathAbs(entry-sl));GlobalVariableSet(TicketKey(ticket,"SIGNAL"),(double)signalTime);
   DrawEntryLevels(ticket);Print("Order opened. Ticket=",ticket," Direction=",direction>0?"BUY":"SELL"," Lots=",DoubleToString(lots,LotDigits())," Risk=",DoubleToString(moneyRisk,2));return true;
}

bool OpenBuy(double atr,datetime signalTime){return OpenTrade(1,atr,signalTime);}
bool OpenSell(double atr,datetime signalTime){return OpenTrade(-1,atr,signalTime);}

bool EntryProtectionsPass()
{
   if(UseNewsFilter){Print("News filter enabled, but MT4 has no reliable native calendar interface. Entry safely blocked.");return false;}
   if(!CheckTradingSession(TimeCurrent()))return false;
   if(!CheckDailyLoss())return false;
   if(!CheckConsecutiveLosses())return false;
   return true;
}

void ProcessNewBar()
{
   datetime signalTime=iTime(Symbol(),SFP_TF,(int)MathMax(1,SignalShift));if(signalTime<=0||signalTime==gLastSignalBar)return;
   gLastSignalBar=signalTime;
   int shift=(int)MathMax(1,SignalShift);CalculateSignalScores(shift,gBuyScore,gSellScore);gCandidate=SelectSignalDirection(gBuyScore,gSellScore);
   gATR=iATR(Symbol(),SFP_TF,ATRPeriod,shift);gCandleScore=0;gVolumePassed=true;
   if(gCandidate!=0)gCandleScore=CalculateCandleScore(shift,gCandidate,gATR,gVolumePassed);
   if(gCandidate>0)gSignalState="BUY SETUP";else if(gCandidate<0)gSignalState="SELL SETUP";else gSignalState="NO SIGNAL";
   if(gCandidate==0)return;
   DrawSignal(shift,gCandidate,gBuyScore,gSellScore,(int)gCandleScore,gATR);
   if(UseCandleConfirmation&&gCandleScore<MinimumCandleScore){gSignalState="CANDLE REJECTED";return;}
   if(gATR<=0){gSignalState="ATR INVALID";return;}
   UpdateStatistics();if(!EntryProtectionsPass()){gSignalState="PROTECTION ACTIVE";return;}
   if(OneTradeAtATime&&FindActiveTrade()>0){gSignalState="TRADE ALREADY ACTIVE";return;}
   bool opened=gCandidate>0?OpenBuy(gATR,signalTime):OpenSell(gATR,signalTime);
   if(opened)gSignalState=gCandidate>0?"BUY ACTIVE":"SELL ACTIVE";
}

void NewBar(){ProcessNewBar();}

int CornerCode(){return (int)PanelCorner;}
void PanelRect(string id,int x,int y,int w,int h,color bg,color border)
{
   string name=PFX+"PANEL_"+id;if(ObjectFind(0,name)<0)ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CornerCode());ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w);ObjectSetInteger(0,name,OBJPROP_YSIZE,h);ObjectSetInteger(0,name,OBJPROP_BGCOLOR,bg);ObjectSetInteger(0,name,OBJPROP_COLOR,border);
   ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);ObjectSetInteger(0,name,OBJPROP_BACK,false);ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
}
void PanelLabel(string id,int x,int y,string text,color c,int size,string font="Arial")
{
   string name=PFX+"PANEL_"+id;if(ObjectFind(0,name)<0)ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CornerCode());ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetString(0,name,OBJPROP_TEXT,text);ObjectSetString(0,name,OBJPROP_FONT,font);ObjectSetInteger(0,name,OBJPROP_FONTSIZE,size);ObjectSetInteger(0,name,OBJPROP_COLOR,c);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
}
void PanelValue(string id,int x,int y,string label,string value,color c)
{
   PanelLabel(id+"L",x,y,label,SecondaryText,7);PanelLabel(id+"V",x,y+12,value,c,9,"Arial Bold");
}
void ProgressBar(string id,int x,int y,int w,double value,double maximum,color fill)
{
   PanelRect(id+"BG",x,y,w,7,C'34,45,67',C'34,45,67');double ratio=maximum>0?MathMax(0,MathMin(1,value/maximum)):0;
   PanelRect(id+"FG",x,y,(int)MathMax(1,(int)(w*ratio)),7,fill,fill);
}

void DeletePanelObjects(){ObjectsDeleteAll(0,PFX+"PANEL_");}

void UpdatePanel()
{
   if(!ShowPanel){DeletePanelObjects();return;}
   int x=PanelX,y=PanelY,w=(int)MathMax(460,PanelWidth),h=(int)MathMax(330,PanelHeight),gap=6;
   int inner=w-16,col=(inner-gap*2)/3,row1=92,row2=92;
   PanelRect("ROOT",x,y,w,h,PanelBackground,C'50,70,100');
   PanelRect("HEADER",x+5,y+5,w-10,36,C'17,24,42',AccentColor);
   PanelLabel("TITLE",x+15,y+10,"SIGNAL FORGE PRO",AccentColor,13,"Arial Bold");
   PanelLabel("SUB",x+15,y+27,Symbol()+"  •  "+TFName(),SecondaryText,8);
   PanelLabel("RUN",x+w-137,y+15,"EA STATUS: RUNNING",BuyColor,8,"Arial Bold");
   int r1=y+47;
   PanelRect("ACCOUNT",x+8,r1,col,row1,CardBackground,C'38,53,78');
   PanelRect("SIGNAL",x+8+col+gap,r1,col,row1,CardBackground,C'38,53,78');
   PanelRect("MARKET",x+8+(col+gap)*2,r1,col,row1,CardBackground,C'38,53,78');
   PanelLabel("AH",x+16,r1+7,"ACCOUNT",AccentColor,8,"Arial Bold");
   PanelValue("BAL",x+16,r1+23,"BALANCE",DoubleToString(AccountBalance(),2),PrimaryText);
   PanelValue("EQU",x+16+col/2,r1+23,"EQUITY",DoubleToString(AccountEquity(),2),PrimaryText);
   PanelValue("FREE",x+16,r1+55,"FREE MARGIN",DoubleToString(AccountFreeMargin(),2),PrimaryText);
   PanelLabel("SH",x+16+col+gap,r1+7,"SIGNAL",AccentColor,8,"Arial Bold");
   PanelLabel("BS",x+16+col+gap,r1+23,"BUY  "+DoubleToString(gBuyScore,1),BuyColor,8,"Arial Bold");
   ProgressBar("BUYBAR",x+16+col+gap,r1+36,col-16,gBuyScore,MaximumEnabledScore(),BuyColor);
   PanelLabel("SS",x+16+col+gap,r1+49,"SELL "+DoubleToString(gSellScore,1),SellColor,8,"Arial Bold");
   ProgressBar("SELLBAR",x+16+col+gap,r1+62,col-16,gSellScore,MaximumEnabledScore(),SellColor);
   PanelLabel("SIGSTATE",x+16+col+gap,r1+74,gSignalState,gCandidate>0?BuyColor:(gCandidate<0?SellColor:SecondaryText),8,"Arial Bold");
   double spread=(Ask-Bid)/PricePoint();
   PanelLabel("MH",x+16+(col+gap)*2,r1+7,"MARKET",AccentColor,8,"Arial Bold");
   PanelValue("BID",x+16+(col+gap)*2,r1+23,"BID",DoubleToString(Bid,PriceDigits()),PrimaryText);
   PanelValue("ASK",x+16+(col+gap)*2+col/2,r1+23,"ASK",DoubleToString(Ask,PriceDigits()),PrimaryText);
   PanelValue("SPR",x+16+(col+gap)*2,r1+55,"SPREAD",DoubleToString(spread,1)+" pts",spread<=MaximumSpreadPoints?BuyColor:WarningColor);
   PanelValue("ATR",x+16+(col+gap)*2+col/2,r1+55,"ATR",DoubleToString(gATR,PriceDigits()),PrimaryText);
   int r2=r1+row1+gap,half=(inner-gap)/2;
   PanelRect("TRADE",x+8,r2,half,row2,CardBackground,C'38,53,78');PanelRect("RISK",x+8+half+gap,r2,half,row2,CardBackground,C'38,53,78');
   int ticket=FindActiveTrade();string dir="FLAT",entry="-",sl="-",tp="-",floating="0.00",trail="OFF",be="OFF",rr="-";color dc=SecondaryText;
   if(SelectActiveTicket(ticket))
   {
      dir=OrderType()==OP_BUY?"BUY":"SELL";dc=OrderType()==OP_BUY?BuyColor:SellColor;entry=DoubleToString(OrderOpenPrice(),PriceDigits());sl=DoubleToString(OrderStopLoss(),PriceDigits());tp=DoubleToString(OrderTakeProfit(),PriceDigits());floating=DoubleToString(OrderProfit()+OrderSwap()+OrderCommission(),2);trail=UseTrailingStop?"ARMED":"OFF";be=UseBreakEven?"ARMED":"OFF";
      gPlannedLot=OrderLots();double initialSL=GlobalVariableCheck(TicketKey(OrderTicket(),"ISL"))?GlobalVariableGet(TicketKey(OrderTicket(),"ISL")):OrderStopLoss();gPlannedRisk=CalculateMoneyRisk(OrderLots(),OrderOpenPrice(),initialSL);
      if(initialSL>0&&OrderTakeProfit()>0)rr=DoubleToString(MathAbs(OrderTakeProfit()-OrderOpenPrice())/MathAbs(OrderOpenPrice()-initialSL),2);
   }
   PanelLabel("TH",x+16,r2+7,"TRADE",AccentColor,8,"Arial Bold");PanelValue("DIR",x+16,r2+22,"DIRECTION",dir,dc);PanelValue("ENT",x+83,r2+22,"ENTRY",entry,PrimaryText);PanelValue("CSL",x+150,r2+22,"SL",sl,SellColor);PanelValue("CTP",x+207,r2+22,"TP",tp,BuyColor);
   PanelValue("FPL",x+16,r2+55,"FLOATING P/L",floating,StringToDouble(floating)>=0?BuyColor:SellColor);PanelValue("BE",x+112,r2+55,"BREAK-EVEN",be,WarningColor);PanelValue("TR",x+200,r2+55,"TRAILING",trail,WarningColor);
   int rx=x+16+half+gap;PanelLabel("RH",rx,r2+7,"RISK & PERFORMANCE",AccentColor,8,"Arial Bold");
   double actualRiskPercent=AccountBalance()>0&&gPlannedRisk>0?gPlannedRisk/AccountBalance()*100.0:0;
   PanelValue("LOT",rx,r2+22,"LOT",DoubleToString(gPlannedLot,LotDigits()),PrimaryText);PanelValue("RISKD",rx+47,r2+22,"RISK $",DoubleToString(gPlannedRisk,2),WarningColor);PanelValue("RISKP",rx+95,r2+22,"RISK %",DoubleToString(actualRiskPercent,2),PrimaryText);PanelValue("RR",rx+143,r2+22,"R:R",rr,PrimaryText);PanelValue("DPL",rx+188,r2+22,"DAILY P/L",DoubleToString(gStats.dailyPL,2),gStats.dailyPL>=0?BuyColor:SellColor);
   PanelValue("TRADES",rx,r2+55,"TRADES",IntegerToString(gStats.total),PrimaryText);PanelValue("WR",rx+62,r2+55,"WIN RATE",DoubleToString(gStats.winRate,1)+"%",BuyColor);PanelValue("PF",rx+127,r2+55,"PF",DoubleToString(gStats.profitFactor,2),PrimaryText);PanelValue("CL",rx+193,r2+55,"CONSEC LOSS",IntegerToString(gStats.currentConsecutive),gStats.currentConsecutive>0?WarningColor:PrimaryText);
   double dailyLoss=MathMax(0,-gStats.dailyPL),dailyLimit=MaximumDailyLossMoney;
   if(dailyLimit<=0&&MaximumDailyLossPercent>0)dailyLimit=(AccountBalance()-gStats.dailyPL)*MaximumDailyLossPercent/100.0;
   ProgressBar("DAYRISK",rx,r2+82,half-16,dailyLoss,MathMax(0.01,dailyLimit),dailyLoss>=dailyLimit&&dailyLimit>0?SellColor:WarningColor);
   int r3=r2+row2+gap;PanelRect("ENGINE",x+8,r3,inner,46,CardBackground,C'38,53,78');PanelLabel("EH",x+16,r3+6,"ENGINE",AccentColor,8,"Arial Bold");
   PanelLabel("ENG1",x+80,r3+7,"Trend  "+(EnableSupertrend?"ON":"OFF"),SecondaryText,8);PanelLabel("ENG2",x+166,r3+7,"Momentum  "+((EnableRSI||EnableMACD)?"ON":"OFF"),SecondaryText,8);PanelLabel("ENG3",x+277,r3+7,"Volatility  "+(EnableBollinger?"ON":"OFF"),SecondaryText,8);
   PanelLabel("CANDLE",x+16,r3+25,"CANDLE SCORE  "+DoubleToString(gCandleScore,0)+" / "+IntegerToString(MinimumCandleScore),PrimaryText,8,"Arial Bold");ProgressBar("CBAR",x+145,r3+28,105,gCandleScore,5,WarningColor);
   PanelLabel("VOL",x+270,r3+25,"VOLUME  "+(!UseVolumeConfirmation?"OPTIONAL OFF":(gVolumePassed?"PASS":"FAIL")),gVolumePassed?BuyColor:SellColor,8,"Arial Bold");
   int statusY=y+h-27;PanelRect("STATUS",x+8,statusY,inner,20,gCandidate>0?C'0,72,58':(gCandidate<0?C'92,35,45':C'28,39,59'),gCandidate>0?BuyColor:(gCandidate<0?SellColor:C'50,70,100'));
   string finalState=dir!="FLAT"?dir+" ACTIVE":gSignalState;PanelLabel("BOTTOM",x+20,statusY+4,"TRADE STATUS:  "+finalState,dir=="BUY"?BuyColor:(dir=="SELL"?SellColor:PrimaryText),9,"Arial Bold");
}

void CheckHistoryChange()
{
   int total=OrdersHistoryTotal();if(total==gLastHistoryTotal)return;
   gLastHistoryTotal=total;UpdateStatistics();DeleteTradeDrawingObjects();RedrawActiveTradeLevels();DrawHistoricalTrades();
}

int OnInit()
{
   PFX="SFP_"+IntegerToString(MagicNumber)+"_";
   if(!ValidateBrokerData())return INIT_FAILED;
   if(SignalShift<1){Print("SignalShift must be at least 1 for non-repainting signals.");return INIT_PARAMETERS_INCORRECT;}
   if(UseNewsFilter)Print("WARNING: UseNewsFilter is enabled. No reliable native MT4 calendar is available, so new entries will be blocked.");
   UpdateStatistics();gLastHistoryTotal=OrdersHistoryTotal();gATR=iATR(Symbol(),SFP_TF,ATRPeriod,1);
   DeleteTradeDrawingObjects();RedrawActiveTradeLevels();DrawHistoricalTrades();
   ObjectsDeleteAll(0,PFX+"SIG_");DrawHistoricalSignals();UpdatePanel();ChartRedraw(0);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(IsTesting()&&IsVisualMode()&&KeepVisualsAfterVisualTest){UpdateStatistics();DrawHistoricalTrades();UpdatePanel();ChartRedraw(0);return;}
   DeletePanelObjects();
}

void OnTick()
{
   RefreshRates();ManageTrade();CheckHistoryChange();
   datetime currentBar=iTime(Symbol(),SFP_TF,0);static datetime observedBar=0;
   if(currentBar>0&&currentBar!=observedBar){observedBar=currentBar;NewBar();}
   UpdateStatistics();UpdatePanel();
}
