; pb-win-notify example file

; in order to use pb-win-notify you have to perform 4 simple steps:
; 1. include the wnotify.pbi file
; 2. create thread with wnProcess() procedure
; 3. periodically check for the #wnCleanup event and call wnCleanup()
; 4. create notifications by calling wnNotification() from anywhere you need

IncludeFile "../wnotify.pbi" ; 1

OpenWindow(0,#PB_Ignore,#PB_Ignore,120,60,"pb-win-notify",#PB_Window_SystemMenu|#PB_Window_ScreenCentered)
button = ButtonGadget(#PB_Any,10,10,100,40,"show notification")

CreateThread(@wnProcess(),10) ; 2

Repeat
  ev = WaitWindowEvent()
  If ev = #wnCleanup : wnCleanup(EventData()) : EndIf ; 3
  If ev = #PB_Event_Gadget
    wnNotify("Hello there!","This is a basic notification created with pb-win-notify!") ; 4
  EndIf
Until ev = #PB_Event_CloseWindow
; IDE Options = PureBasic 5.31 (Windows - x86)
; EnableUnicode
; EnableXP
; Executable = wn.exe
; CompileSourceDirectory
; EnableBuildCount = 2