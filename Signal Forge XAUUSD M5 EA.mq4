//+------------------------------------------------------------------+
//| Signal Forge XAUUSD M5 EA                                        |
//| Based on Signal Forge [LuxAlgo]                                  |
//| Original work (c) LuxAlgo, CC BY-NC-SA 4.0                      |
//| https://creativecommons.org/licenses/by-nc-sa/4.0/               |
//|                                                                  |
//| Non-commercial ShareAlike MT4 EA port. Test on demo first.       |
//+------------------------------------------------------------------+
#property strict

//--- Trading
input int    MagicNumber       = 260914;
input double FixedLots         = 0.01;
input int    SlippagePoints    = 50;
input int    MaximumSpreadPoints = 150;
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
input double TrailingDistancePoints = 100.0;
input double TrailingStepPoints = 100.0;

//--- Signal aggregation
input bool RequireAllEnabledIndicatorsToAlign = true;

//--- XAUUSD M5 conservative filter preset
input bool EnableSMA = false;
input int  SMAFastLength = 9;
input int  SMASlowLength = 30;
input bool EnableRSI = true;
input int  RSILength = 14;
input double RSILongAbove = 52.0;
input double RSIShortBelow = 48.0;
input bool EnableMACD = false;
input int  MACDFastLength = 8;
input int  MACDSlowLength = 21;
input int  MACDSignalLength = 5;
input bool EnableSupertrend = true;
input double SupertrendFactor = 2.5;
input int  SupertrendLength = 10;
input bool EnableStochastic = false;
input int  StochasticKLength = 14;
input int  StochasticDLength = 3;
input int  StochasticSmooth = 3;
input bool EnableBollinger = false;
input int  BollingerLength = 20;
input bool EnableEMA = true;
input int  EMAFastLength = 9;
input int  EMASlowLength = 21;
input bool EnableAO = false;
input bool EnableSAR = false;
input double SARStep = 0.02;
input double SARMaximum = 0.2;
input bool EnableCCI = false;
input int  CCILength = 20;
input double CCILongAbove = 50.0;
input double CCIShortBelow = -50.0;
input bool EnableADX = true;
input int  ADXPeriod = 14;
input double ADXThreshold = 22.0;

//--- Display
enum EA_CORNER { EA_Top_Right=0, EA_Bottom_Right=1, EA_Bottom_Left=2 };
input bool ApplyProfessionalChartTheme = true;
input bool ShowDashboard = true;
input EA_CORNER SignalPanelPosition = EA_Top_Right;
input EA_CORNER PerformancePanelPosition = EA_Bottom_Right;
input int DashboardFontSize = 9;
input bool DrawEntrySLTPLines = true;
input bool DrawClosedTradeResults = true;
input int  MaximumResultBoxes = 50;
input int  ResultBoxPaddingPixels = 8;

string PREFIX="SF_EA_";
datetime gLastBar=0;
bool gBull[11],gBear[11];
bool gLongSignal=false,gShortSignal=false;
string gLastAction="EA INITIALIZED";

//+------------------------------------------------------------------+
int CornerValue(EA_CORNER p)
{
   if(p==EA_Top_Right) return CORNER_RIGHT_UPPER;
   if(p==EA_Bottom_Right) return CORNER_RIGHT_LOWER;
   return CORNER_LEFT_LOWER;
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
   ObjectSetInteger(0,l,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,l,OBJPROP_HIDDEN,true);
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
int SupertrendDirection(int shift)
{
   int oldest=MathMin(Bars-2,shift+600);
   if(oldest<=shift) return 0;
   bool ready=false;
   double prevUpper=0,prevLower=0,prevST=0,prevClose=0;
   int result=0;
   for(int i=oldest;i>=shift;i--)
   {
      double atr=iATR(NULL,0,MathMax(1,SupertrendLength),i);
      double upper=(High[i]+Low[i])*0.5+SupertrendFactor*atr;
      double lower=(High[i]+Low[i])*0.5-SupertrendFactor*atr;
      double finalUpper=upper,finalLower=lower,st=upper;
      int direction=1;
      if(!ready || atr<=0)
      {
         if(atr>0) ready=true;
      }
      else
      {
         finalUpper=(upper<prevUpper || prevClose>prevUpper)?upper:prevUpper;
         finalLower=(lower>prevLower || prevClose<prevLower)?lower:prevLower;
         if(prevST==prevUpper) st=(Close[i]>finalUpper)?finalLower:finalUpper;
         else st=(Close[i]<finalLower)?finalUpper:finalLower;
         direction=(st==finalLower)?-1:1;
      }
      prevUpper=finalUpper; prevLower=finalLower; prevST=st; prevClose=Close[i];
      if(i==shift) result=ready?direction:0;
   }
   return result;
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
   bool enabled[11];
   enabled[0]=EnableSMA;enabled[1]=EnableRSI;enabled[2]=EnableMACD;enabled[3]=EnableSupertrend;
   enabled[4]=EnableStochastic;enabled[5]=EnableBollinger;enabled[6]=EnableEMA;enabled[7]=EnableAO;
   enabled[8]=EnableSAR;enabled[9]=EnableCCI;enabled[10]=EnableADX;
   lng=RequireAllEnabledIndicatorsToAlign;
   sht=RequireAllEnabledIndicatorsToAlign;
   bool any=false;
   for(int i=0;i<11;i++) if(enabled[i])
   {
      if(RequireAllEnabledIndicatorsToAlign) { lng=(lng&&bull[i]); sht=(sht&&bear[i]); }
      else { lng=(lng||bull[i]); sht=(sht||bear[i]); }
      any=true;
   }
   if(!any) { lng=false; sht=false; }
}

//+------------------------------------------------------------------+
double NormalizeLots(double lots)
{
   double minLot=MarketInfo(Symbol(),MODE_MINLOT);
   double maxLot=MarketInfo(Symbol(),MODE_MAXLOT);
   double step=MarketInfo(Symbol(),MODE_LOTSTEP);
   if(step<=0) step=0.01;
   lots=MathMax(minLot,MathMin(maxLot,lots));
   return NormalizeDouble(MathFloor(lots/step+0.0000001)*step,2);
}

double RiskStopDistance(double lots)
{
   double balance=(RiskReferenceBalance>0)?RiskReferenceBalance:AccountBalance();
   double money=balance*MathMax(0.0,RiskPercent)/100.0;
   double tickSize=MarketInfo(Symbol(),MODE_TICKSIZE);
   double tickValue=MarketInfo(Symbol(),MODE_TICKVALUE);
   if(tickSize<=0) tickSize=Point;
   if(money<=0 || tickValue<=0 || lots<=0) return 0;
   return MathMax(Point,money*tickSize/(lots*tickValue));
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
   RefreshRates();
   double spread=(Ask-Bid)/Point;
   if(MaximumSpreadPoints>0 && spread>MaximumSpreadPoints)
   { gLastAction="BLOCKED: SPREAD "+DoubleToString(spread,0)+" PTS"; return false; }

   double lots=NormalizeLots(FixedLots);
   double entry=(type==OP_BUY)?Ask:Bid;
   double atr=iATR(NULL,0,MathMax(1,ATRLength),1);
   double slDistance=(StopLossMode==SL_By_Risk_Percent)?RiskStopDistance(lots):atr*MathMax(0.1,StopLossATR);
   double tpDistance=(TakeProfitMode==TP_By_Points)?MathMax(Point,TakeProfitPoints*Point):atr*MathMax(0.1,TakeProfitATR);
   double minimum=(MarketInfo(Symbol(),MODE_STOPLEVEL)+2)*Point;
   slDistance=MathMax(slDistance,minimum);
   tpDistance=MathMax(tpDistance,minimum);
   double sl=(type==OP_BUY)?entry-slDistance:entry+slDistance;
   double tp=(type==OP_BUY)?entry+tpDistance:entry-tpDistance;
   sl=NormalizeDouble(sl,Digits); tp=NormalizeDouble(tp,Digits);

   string comment=(type==OP_BUY)?"Signal Forge BUY":"Signal Forge SELL";
   color arrow=(type==OP_BUY)?C'0,255,170':C'255,64,96';
   int ticket=OrderSend(Symbol(),type,lots,entry,SlippagePoints,sl,tp,comment,MagicNumber,0,arrow);
   if(ticket<0 && GetLastError()==130)
   {
      RefreshRates(); entry=(type==OP_BUY)?Ask:Bid;
      ticket=OrderSend(Symbol(),type,lots,entry,SlippagePoints,0,0,comment,MagicNumber,0,arrow);
      if(ticket>0 && OrderSelect(ticket,SELECT_BY_TICKET))
      {
         sl=(type==OP_BUY)?entry-slDistance:entry+slDistance;
         tp=(type==OP_BUY)?entry+tpDistance:entry-tpDistance;
         if(!OrderModify(ticket,OrderOpenPrice(),NormalizeDouble(sl,Digits),NormalizeDouble(tp,Digits),0,arrow))
            Print("Signal Forge ECN SL/TP modify failed: ",GetLastError());
      }
   }
   if(ticket<0) { int err=GetLastError(); gLastAction="ORDER ERROR "+IntegerToString(err); Print(gLastAction); return false; }
   gLastAction=(type==OP_BUY)?"BUY OPENED":"SELL OPENED";
   return true;
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
   ObjectSetInteger(0,rect,OBJPROP_BACK,false);
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
   ObjectSetInteger(0,label,OBJPROP_BACK,false);
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
      ObjectsDeleteAll(0,base);
      return;
   }

   double net=OrderProfit()+OrderSwap()+OrderCommission();
   bool won=(net>0);
   double points=(OrderType()==OP_BUY)?(OrderClosePrice()-OrderOpenPrice())/Point:(OrderOpenPrice()-OrderClosePrice())/Point;
   string side=(OrderType()==OP_BUY)?"BUY ":"SELL ";
   string headline=(won?"WIN  ":"LOSS  ")+SignedValue(net,2);
   string detail=side+DoubleToString(OrderLots(),2)+"  "+SignedValue(MathRound(points),0)+" pts";

   int mainFont=MathMax(8,DashboardFontSize);
   int subFont=MathMax(7,DashboardFontSize-1);
   int padding=MathMax(5,ResultBoxPaddingPixels);
   // Consolas is monospaced. This sizing keeps both strings inside the card
   // and avoids the oversized chart-time rectangles used previously.
   int charPixels=MathMax(6,(mainFont*7)/10);
   int longest=MathMax(StringLen(headline),StringLen(detail));
   int width=longest*charPixels+padding*2+4;
   int mainHeight=mainFont+14;
   int subHeight=subFont+12;
   int height=mainHeight+subHeight;

   long chartWidth=0,chartHeight=0;
   ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0,chartWidth);
   ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0,chartHeight);
   int left=anchorX+10;
   if(left+width>(int)chartWidth-8) left=anchorX-width-10;
   left=MathMax(8,MathMin(left,(int)chartWidth-width-8));
   int top=MathMax(8,MathMin(anchorY-height/2,(int)chartHeight-height-8));

   // Collision avoidance: move a card below an existing card, or above it
   // near the lower edge. Text and both raised rows always move together.
   for(int pass=0;pass<100;pass++)
   {
      bool moved=false;
      for(int i=0;i<usedCount;i++)
      {
         if(!PixelBoxesOverlap(left,top,width,height,usedX[i],usedY[i],usedW[i],usedH[i])) continue;
         int below=usedY[i]+usedH[i]+5;
         if(below+height<=(int)chartHeight-8) top=below;
         else top=MathMax(8,usedY[i]-height-5);
         moved=true;
         break;
      }
      if(!moved) break;
   }

   color mainBg=won?C'0,82,185':C'145,20,48';
   color subBg=won?C'0,124,230':C'210,32,68';
   color border=won?C'90,205,255':C'255,115,135';
   ResultCardRow(base+"MAIN",base+"TITLE",left,top,width,mainHeight,headline,mainBg,border,mainFont,padding);
   ResultCardRow(base+"SUB",base+"DETAIL",left,top+mainHeight,width,subHeight,detail,subBg,border,subFont,padding);

   string marker=base+"MARK";
   EnsureResultCardObject(marker,OBJ_ARROW);
   if(ObjectFind(0,marker)<0) ObjectCreate(0,marker,OBJ_ARROW,0,closeTime,OrderClosePrice());
   ObjectMove(0,marker,0,closeTime,OrderClosePrice());
   ObjectSetInteger(0,marker,OBJPROP_ARROWCODE,159);
   ObjectSetInteger(0,marker,OBJPROP_COLOR,won?C'255,225,60':C'255,64,96');
   ObjectSetInteger(0,marker,OBJPROP_WIDTH,2);
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

//+------------------------------------------------------------------+
void HistoryStats(int &trades,int &wins,int &losses,double &net)
{
   trades=0;wins=0;losses=0;net=0;
   for(int i=OrdersHistoryTotal()-1;i>=0;i--) if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
   {
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=MagicNumber) continue;
      if(OrderType()!=OP_BUY && OrderType()!=OP_SELL) continue;
      double result=OrderProfit()+OrderSwap()+OrderCommission();
      trades++; net+=result; if(result>0) wins++; else losses++;
   }
}

void UpdateDashboard()
{
   if(!ShowDashboard) { ObjectsDeleteAll(0,PREFIX+"SIG_"); ObjectsDeleteAll(0,PREFIX+"PERF_"); return; }
   int fs=MathMax(7,DashboardFontSize);
   string names[11]={"SMA CROSS","RSI","MACD","SUPERTREND","STOCHASTIC","BOLLINGER","EMA CROSS","AO","SAR","CCI","ADX FILTER"};
   bool enabled[11];
   enabled[0]=EnableSMA;enabled[1]=EnableRSI;enabled[2]=EnableMACD;enabled[3]=EnableSupertrend;enabled[4]=EnableStochastic;
   enabled[5]=EnableBollinger;enabled[6]=EnableEMA;enabled[7]=EnableAO;enabled[8]=EnableSAR;enabled[9]=EnableCCI;enabled[10]=EnableADX;
   int x=10,y=10,w=390,h=338;
   DrawPanel("SIG",SignalPanelPosition,x,y,w,h);
   DrawCell("SIG","TITLE",SignalPanelPosition,x,y,w,h,6,6,378,28,"SIGNAL FORGE EA | "+Symbol()+" M"+IntegerToString(Period()),C'255,255,255',C'82,55,210',fs+1);
   DrawCell("SIG","H0",SignalPanelPosition,x,y,w,h,6,36,150,22,"INDICATOR",C'120,210,255',C'28,48,88',fs);
   DrawCell("SIG","H1",SignalPanelPosition,x,y,w,h,156,36,130,22,"STATUS",C'120,210,255',C'28,48,88',fs);
   DrawCell("SIG","H2",SignalPanelPosition,x,y,w,h,286,36,98,22,"FILTER",C'120,210,255',C'28,48,88',fs);
   for(int i=0;i<11;i++)
   {
      int top=60+i*22; string id=IntegerToString(i);
      color sc=StatusColor(gBull[i],gBear[i]);
      color sb=gBull[i]?C'0,72,58':(gBear[i]?C'92,18,36':C'65,55,20');
      DrawCell("SIG","N"+id,SignalPanelPosition,x,y,w,h,6,top,150,21,names[i],C'235,240,255',C'22,30,48',fs);
      DrawCell("SIG","S"+id,SignalPanelPosition,x,y,w,h,156,top,130,21,StatusText(gBull[i],gBear[i]),sc,sb,fs);
      DrawCell("SIG","E"+id,SignalPanelPosition,x,y,w,h,286,top,98,21,enabled[i]?"ON":"OFF",enabled[i]?C'0,255,170':C'255,64,96',enabled[i]?C'0,72,58':C'92,18,36',fs);
   }
   string signal=gLongSignal?"LONG":(gShortSignal?"SHORT":"NEUTRAL");
   color sigc=gLongSignal?C'0,255,170':(gShortSignal?C'255,64,96':C'255,214,64');
   color sigb=gLongSignal?C'0,72,58':(gShortSignal?C'92,18,36':C'72,58,18');
   DrawCell("SIG","SIGNAL",SignalPanelPosition,x,y,w,h,6,304,378,28,"CURRENT SIGNAL: "+signal,sigc,sigb,fs+1);

   int trades,wins,losses;double net;HistoryStats(trades,wins,losses,net);
   double wr=trades>0?100.0*wins/trades:0;
   int type;int ticket=ActiveTicket(type);
   string position=ticket<0?"FLAT":(type==OP_BUY?"BUY #":"SELL #")+IntegerToString(ticket);
   int qx=10,qy=10,qw=460,qh=126;
   DrawPanel("PERF",PerformancePanelPosition,qx,qy,qw,qh);
   DrawCell("PERF","TITLE",PerformancePanelPosition,qx,qy,qw,qh,6,6,448,28,"EA PERFORMANCE | CLOSED ORDERS",C'255,255,255',C'0,105,160',fs+1);
   string heads[5]={"TRADES","WINS","LOSSES","WIN RATE","NET"};
   string vals[5]; vals[0]=IntegerToString(trades);vals[1]=IntegerToString(wins);vals[2]=IntegerToString(losses);vals[3]=DoubleToString(wr,1)+"%";vals[4]=DoubleToString(net,2);
   int widths[5]={80,70,70,100,128};
   color cols[5];cols[0]=C'120,210,255';cols[1]=C'0,255,170';cols[2]=C'255,64,96';cols[3]=(wr>=50)?C'0,255,170':C'255,64,96';cols[4]=(net>0)?C'0,255,170':(net<0?C'255,64,96':C'220,225,235');
   int left=6;
   for(int p=0;p<5;p++)
   {
      string id=IntegerToString(p);
      DrawCell("PERF","H"+id,PerformancePanelPosition,qx,qy,qw,qh,left,36,widths[p],22,heads[p],C'120,210,255',C'28,48,88',fs);
      color bg=(p==1 || (p==3&&wr>=50) || (p==4&&net>0))?C'0,72,58':((p==2 || (p==3&&trades>0&&wr<50) || (p==4&&net<0))?C'92,18,36':C'42,49,65');
      DrawCell("PERF","V"+id,PerformancePanelPosition,qx,qy,qw,qh,left,59,widths[p],31,vals[p],cols[p],bg,fs+1);
      left+=widths[p];
   }
   DrawCell("PERF","POS",PerformancePanelPosition,qx,qy,qw,qh,6,92,220,28,"POSITION: "+position,ticket<0?C'255,214,64':C'0,255,170',ticket<0?C'72,58,18':C'0,72,58',fs);
   DrawCell("PERF","ACT",PerformancePanelPosition,qx,qy,qw,qh,226,92,228,28,gLastAction,C'235,240,255',C'32,42,64',fs);
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
int OnInit()
{
   ArrayInitialize(gBull,false); ArrayInitialize(gBear,false);
   ApplyChartTheme();
   EventSetTimer(1);
   gLastBar=0;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectsDeleteAll(0,PREFIX);
}

void OnTimer()
{
   DrawTradeLines();
   UpdateClosedTradeResults();
   UpdateDashboard();
}

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   if(id==CHARTEVENT_CHART_CHANGE) UpdateClosedTradeResults();
}

void OnTick()
{
   ManageTrailing();
   DrawTradeLines();
   UpdateClosedTradeResults();
   if(Bars<100) return;
   if(Time[0]==gLastBar) return;
   gLastBar=Time[0];

   int shift=TradeOnClosedBar?1:0;
   bool previousBull[11]={false,false,false,false,false,false,false,false,false,false,false};
   bool previousBear[11]={false,false,false,false,false,false,false,false,false,false,false};
   GetConditions(shift,gBull,gBear);
   GetConditions(shift+1,previousBull,previousBear);
   CombinedSignal(gBull,gBear,gLongSignal,gShortSignal);
   bool previousLong=false,previousShort=false;
   CombinedSignal(previousBull,previousBear,previousLong,previousShort);
   bool enterLong=gLongSignal && !previousLong;
   bool enterShort=gShortSignal && !previousShort;

   int currentType;int ticket=ActiveTicket(currentType);
   if(CloseOnOppositeSignal && ticket>=0)
   {
      if((currentType==OP_BUY && gShortSignal) || (currentType==OP_SELL && gLongSignal))
      {
         if(CloseActivePosition()) { gLastAction="CLOSED ON OPPOSITE"; ticket=-1; }
      }
   }
   if((!OnePositionOnly || ticket<0) && !(enterLong&&enterShort))
   {
      if(enterLong) OpenPosition(OP_BUY);
      else if(enterShort) OpenPosition(OP_SELL);
   }
   UpdateDashboard();
}
//+------------------------------------------------------------------+
