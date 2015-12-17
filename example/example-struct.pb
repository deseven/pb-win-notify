; pb-win-notify struct example

; in this example you will see how to create notification with structure
; instead of huge string with params

IncludeFile "../wn.pbi"

OpenWindow(0,#PB_Ignore,#PB_Ignore,200,50,"pb-win-notify",#PB_Window_SystemMenu|#PB_Window_ScreenCentered)
ButtonGadget(#PB_Any,10,10,180,30,"show notification")

wnInit()

Repeat
  ev = WaitWindowEvent()
  If ev = #wnCleanup : wnCleanup() : EndIf
  If ev = #PB_Event_Gadget
    *notification.wnNotification = AllocateMemory(SizeOf(wnNotification))
    With *notification
      ; title, msg, timeout and colors are mandatory
      \title = "Hello there!"
      \msg = "This is a basic notification created with pb-win-notify by wnNotifyStruct procedure!"
      \params\timeout = #wnDefTimeout
      \params\bgColor = #wnDefBgColor
      \params\frColor = #wnDefFrColor
      ; browse the structure to see all of the available params
      \params\castFrom = #wnCT
      ; this method also allows to tune some more params, such as notification width
      \params\w = 600
    EndWith
    ; don't worry about memory, the structure will be freed automatically
    wnNotifyStruct(*notification)
  EndIf
Until ev = #PB_Event_CloseWindow
; IDE Options = PureBasic 5.40 LTS (Windows - x86)
; EnableUnicode
; EnableThread
; EnableXP