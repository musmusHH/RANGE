Signal Forge Pro — Option 13 Sapphire Bitmap Skin

INSTALLATION
1. Copy this entire SignalForgePro13 folder into:
   MT4 Data Folder\MQL4\Images\SignalForgePro13\
2. Copy Signal Forge Pro XAUUSD M5 EA.mq4 into:
   MT4 Data Folder\MQL4\Experts\
3. Open the EA in MetaEditor and compile it.

The EA uses #resource directives, so these BMP assets are embedded into the compiled EX4. They are used through native OBJ_BITMAP_LABEL chart objects; no DLL, WebRequest, API, or external application is used at runtime.

FILES
- logo.bmp: sapphire SF header emblem
- corner.bmp: raised sapphire panel corner ornament
- orb_buy.bmp: green circular BUY/up state
- orb_sell.bmp: red circular SELL/down state
- orb_neutral.bmp: cyan neutral/waiting state
- panel_signal.bmp: complete 440x388 Signal Module skin
- panel_account.bmp: complete 345x241 Account Cockpit skin
- panel_active.bmp: complete 345x320 Active Position skin

UseOption13SapphireBitmapSkin=true enables the complete Option 13 layout. Dynamic labels and values are overlaid with native OBJ_LABEL objects. The Signal Module includes a live vertical 0-100 score meter and three runtime-generated neon circular percentage gauges for RSI, MACD and Signal Quality. Their illuminated arcs are rebuilt as the percentages change; they are not fixed painted effects. The Active Position module uses solid raised native MQL4 cards and separators (no painted grid) and also shows live 0-100 normalized closed-bar readings for all eleven signal indicators: SMA, RSI, MACD, Supertrend, Stochastic, Bollinger, EMA, AO, SAR, CCI and ADX. Set the option false to use the responsive native-object fallback UI.

The enabled EMA 200 regime filter requires the entire closed signal candle above EMA 200 for BUY or below EMA 200 for SELL. EMA 200 is drawn on the chart with a vivid solid raised EMA200 endpoint card and large bold text that follows the live line as price, scale, or chart position changes.