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
- gauge_ring.bmp: reusable circular sapphire gauge
- orb_buy.bmp: green circular BUY/up state
- orb_sell.bmp: red circular SELL/down state
- orb_neutral.bmp: cyan neutral/waiting state

UseOption13SapphireBitmapSkin=true enables the assets. Set it false to use the native-object fallback UI.