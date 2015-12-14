; pb-win-notify events example

; in this example you'll see how to use events

myLink.s = "http://google.com"

IncludeFile "../wnotify.pbi"
UsePNGImageDecoder()

OpenWindow(0,#PB_Ignore,#PB_Ignore,200,100,"pb-win-notify events",#PB_Window_SystemMenu|#PB_Window_ScreenCentered)
TextGadget(#PB_Any,10,10,180,20,"after clicking on the notification:",#PB_Text_Center)
buttonClose = ButtonGadget(#PB_Any,10,30,180,20,"close")
buttonNotepad = ButtonGadget(#PB_Any,10,50,180,20,"open notepad")
buttonLink = ButtonGadget(#PB_Any,10,70,180,20,"open link")
titleFont = FontID(LoadFont(#PB_Any,"Calibri",13,#PB_Font_Bold))
msgFont = FontID(LoadFont(#PB_Any,"Calibri",11))
iconClose = ImageID(LoadImage(#PB_Any,"res\iClose.png"))
iconNotepad = ImageID(LoadImage(#PB_Any,"res\iNotepad.png"))
iconLink = ImageID(LoadImage(#PB_Any,"res\iLink.png"))

WinNotify::Init()

Repeat
  ev = WaitWindowEvent()
  If ev = WinNotify::#Cleanup : WinNotify::Cleanup() : EndIf
  If ev = #PB_Event_Gadget
    Select EventGadget()
      Case buttonClose
        ; you can use WinNotify::#ClickClose as the onClick param to close the notification,
        ; so there is no need to send the custom event
        ; but in this example we will use it anyway
        closeNotification = WinNotify::Notify("Hello there!","Click me to close!",WinNotify::#RB,WinNotify::#Forever,$646503,$eeeeee,titleFont,msgFont,iconClose,WinNotify::#ClickEvent)
        DisableGadget(buttonClose,#True)
      Case buttonNotepad
        ; we will also use the onClose event in this one
        notepadNotification = WinNotify::Notify("Hello there!","Click me to launch notepad!",WinNotify::#RB,WinNotify::#Forever,$435bd9,$eeeeee,titleFont,msgFont,iconNotepad,WinNotify::#ClickClose,0,WinNotify::#CloseEvent)
        DisableGadget(buttonNotepad,#True)
      Case buttonLink
        ; to pass some additional params we can use the onClickData
        ; but it's not possible to pass a string
        ; however you still can call it with a pointer
        linkNotification = WinNotify::Notify("Hello there!","Click me and to open link!",WinNotify::#RB,WinNotify::#Forever,$c88200,$eeeeee,titleFont,msgFont,iconLink,WinNotify::#ClickEvent,@myLink)
        DisableGadget(buttonLink,#True)
    EndSelect
  EndIf
  ; to get the click event you should check for WinNotify::#Click
  If ev = WinNotify::#Click
    ; to detect which notification sent you this event 
    ; check the EventWindow() against the value you got from WinNotify::Notify()
    ; don't forget to use WinNotify::Destroy() if you don't need that notification anymore
    Select EventWindow()
      Case closeNotification
        WinNotify::Destroy(EventWindow())
        closeNotification = 0 : DisableGadget(buttonClose,#False)
      Case linkNotification
        ; here we grab our url from memory
        ; you actually don't need to do that as you have only one url
        ; but if you have many you can assign them to the notifications
        ; and get it back like that
        RunProgram(PeekS(EventData()))
        WinNotify::Destroy(EventWindow())
        linkNotification = 0 : DisableGadget(buttonLink,#False)
    EndSelect
  EndIf
  ; to get the close event you should check for WinNotify::#Close
  If ev = WinNotify::#Close
    Select EventWindow()
      Case notepadNotification
        RunProgram("notepad")
        WinNotify::Destroy(EventWindow())
        notepadNotification = 0 : DisableGadget(buttonNotepad,#False)
    EndSelect
  EndIf
Until ev = #PB_Event_CloseWindow
; IDE Options = PureBasic 5.40 LTS (Windows - x64)
; CursorPosition = 7
; FirstLine = 2
; EnableUnicode
; EnableThread
; EnableXP
; Executable = wn.exe
; CompileSourceDirectory
; EnableBuildCount = 2