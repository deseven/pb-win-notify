; pb-win-notify struct example

; in this example you will see how to create notification with structure
; instead of huge string with params

IncludeFile "../wnotify.pbi"

OpenWindow(0,#PB_Ignore,#PB_Ignore,200,50,"pb-win-notify",#PB_Window_SystemMenu|#PB_Window_ScreenCentered)
ButtonGadget(#PB_Any,10,10,180,30,"show notification")

WinNotify::Init()

Repeat
  ev = WaitWindowEvent()
  If ev = WinNotify::#Cleanup : WinNotify::Cleanup() : EndIf
  If ev = #PB_Event_Gadget
    *notification.WinNotify::Notification = AllocateMemory(SizeOf(WinNotify::Notification))
    With *notification
      ; title, msg, timeout and colors are mandatory
      \title = "Hello there!"
      \msg = "This is a basic notification created with pb-win-notify!"
      \params\timeout = WinNotify::#DefTimeout
      \params\bgColor = WinNotify::#DefBgColor
      \params\frColor = WinNotify::#DefFrColor
      ; browse the structure to see all of the available params
      \params\castFrom = WinNotify::#CT
    EndWith
    ; don't worry about memory, the structure will be freed automatically
    WinNotify::NotifyStruct(*notification)
  EndIf
Until ev = #PB_Event_CloseWindow
; IDE Options = PureBasic 5.40 LTS (Windows - x64)
; CursorPosition = 11
; EnableUnicode
; EnableThread
; EnableXP
; Executable = wn.exe
; CompileSourceDirectory
; EnableBuildCount = 2