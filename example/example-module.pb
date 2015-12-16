; pb-win-notify module example

; in order to use pb-win-notify you have to perform 4 simple steps:
; 1. include the wn-module.pbi file
; 2. call Init() once
; 3. periodically check for the #Cleanup event and call Cleanup()
; 4. create notifications by calling Notify() from anywhere you need

IncludeFile "../wn-module.pbi" ; 1

OpenWindow(0,#PB_Ignore,#PB_Ignore,200,50,"pb-win-notify",#PB_Window_SystemMenu|#PB_Window_ScreenCentered)
ButtonGadget(#PB_Any,10,10,180,30,"show notification")

WN::Init() ; 2

Repeat
  ev = WaitWindowEvent()
  If ev = WN::#Cleanup : WN::Cleanup() : EndIf ; 3
  If ev = #PB_Event_Gadget
    WN::Notify("Hello there!","This is a basic notification created with pb-win-notify!") ; 4
  EndIf
Until ev = #PB_Event_CloseWindow

; IDE Options = PureBasic 5.40 LTS (Windows - x86)
; EnableUnicode
; EnableThread
; EnableXP