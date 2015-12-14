; pb-win-notify example

; in order to use pb-win-notify you have to perform 4 simple steps:
; 1. include the wnotify.pbi file
; 2. call wnInit() once
; 3. periodically check for the #wnCleanup event and call wnCleanup()
; 4. create notifications by calling wnNotification() from anywhere you need

IncludeFile "../wnotify.pbi" ; 1

OpenWindow(0,#PB_Ignore,#PB_Ignore,200,50,"pb-win-notify",#PB_Window_SystemMenu|#PB_Window_ScreenCentered)
ButtonGadget(#PB_Any,10,10,180,30,"show notification")

WinNotify::Init() ; 2

Repeat
  ev = WaitWindowEvent()
  If ev = WinNotify::#Cleanup : WinNotify::Cleanup() : EndIf ; 3
  If ev = #PB_Event_Gadget
    WinNotify::Notify("Hello there!","This is a basic notification created with pb-win-notify!") ; 4
  EndIf
Until ev = #PB_Event_CloseWindow
; IDE Options = PureBasic 5.40 LTS (Windows - x64)
; CursorPosition = 21
; EnableUnicode
; EnableThread
; EnableXP
; Executable = wn.exe
; CompileSourceDirectory
; EnableBuildCount = 2