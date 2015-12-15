; pb-win-notify events example

; in this example you'll see how to use events

myLink.s = "http://google.com"

IncludeFile "../wn.pbi"
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

wnInit()

Repeat
  ev = WaitWindowEvent()
  If ev = #wnCleanup : wnCleanup() : EndIf
  If ev = #PB_Event_Gadget
    Select EventGadget()
      Case buttonClose
        ; you can use #wnClickClose as the onClick param to close the notification,
        ; so there is no need to send the custom event
        ; but in this example we will use it anyway
        closeNotification = wnNotify("Hello there!","Click me to close!",#wnRB,#wnForever,$646503,$eeeeee,titleFont,msgFont,iconClose,#wnClickEvent)
        DisableGadget(buttonClose,#True)
      Case buttonNotepad
        ; we will also use the onClose event in this one
        notepadNotification = wnNotify("Hello there!","Click me to launch notepad!",#wnRB,#wnForever,$435bd9,$eeeeee,titleFont,msgFont,iconNotepad,#wnClickClose,0,#wnCloseEvent)
        DisableGadget(buttonNotepad,#True)
      Case buttonLink
        ; to pass some additional params we can use the onClickData
        ; but it's not possible to pass a string
        ; however you still can call it with a pointer
        linkNotification = wnNotify("Hello there!","Click me and to open link!",#wnRB,#wnForever,$c88200,$eeeeee,titleFont,msgFont,iconLink,#wnClickEvent,@myLink)
        DisableGadget(buttonLink,#True)
    EndSelect
  EndIf
  ; to get the click event you should check for #wnClick
  If ev = #wnClick
    ; to detect which notification sent you this event 
    ; check the EventWindow() against the value you got from wnNotify()
    ; don't forget to use wnDestroy() if you don't need that notification anymore
    Select EventWindow()
      Case closeNotification
        wnDestroy(EventWindow())
        closeNotification = 0 : DisableGadget(buttonClose,#False)
      Case linkNotification
        ; here we grab our url from memory
        ; you actually don't need to do that as you have only one url
        ; but if you have many you can assign them to the notifications
        ; and get it back like that
        RunProgram(PeekS(EventData()))
        wnDestroy(EventWindow())
        linkNotification = 0 : DisableGadget(buttonLink,#False)
    EndSelect
  EndIf
  ; to get the close event you should check for #wnClose
  If ev = #wnClose
    Select EventWindow()
      Case notepadNotification
        RunProgram("notepad")
        wnDestroy(EventWindow())
        notepadNotification = 0 : DisableGadget(buttonNotepad,#False)
    EndSelect
  EndIf
Until ev = #PB_Event_CloseWindow