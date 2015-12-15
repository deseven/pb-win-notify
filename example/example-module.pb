; pb-win-notify module example

IncludeFile "../wn-module.pbi"

OpenWindow(0,#PB_Ignore,#PB_Ignore,200,50,"pb-win-notify",#PB_Window_SystemMenu|#PB_Window_ScreenCentered)
ButtonGadget(#PB_Any,10,10,180,30,"show notification")

WN::wnInit()

Repeat
  ev = WaitWindowEvent()
  If ev = WN::#wnCleanup : WN::wnCleanup() : EndIf
  If ev = #PB_Event_Gadget
    WN::Notify("Hello there!","This is a basic notification created with pb-win-notify!")
  EndIf
Until ev = #PB_Event_CloseWindow
