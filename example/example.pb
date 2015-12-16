; pb-win-notify example

; in order to use pb-win-notify you have to perform 4 simple steps:
; 1. include the wn.pbi file
; 2. call wnInit() once
; 3. periodically check for the #wnCleanup event and call wnCleanup()
; 4. create notifications by calling wnNotify() from anywhere you need

IncludeFile "../wn.pbi" ; 1

OpenWindow(0,#PB_Ignore,#PB_Ignore,200,50,"pb-win-notify",#PB_Window_SystemMenu|#PB_Window_ScreenCentered)
ButtonGadget(#PB_Any,10,10,180,30,"show notification")

wnInit() ; 2

Repeat
  ev = WaitWindowEvent()
  If ev = #wnCleanup : wnCleanup() : EndIf ; 3
  If ev = #PB_Event_Gadget
    wnNotify("Hello there!","This is a basic notification created with pb-win-notify!") ; 4
  EndIf
Until ev = #PB_Event_CloseWindow
; IDE Options = PureBasic 5.40 LTS (Windows - x86)
; EnableUnicode
; EnableThread
; EnableXP