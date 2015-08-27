; pb-win-notify advanced example file

; in this example you'll see how to use the full functionality

IncludeFile "../wnotify.pbi"
UsePNGImageDecoder()

timeout = 3000
onClick = #wnSendEvent

OpenWindow(0,#PB_Ignore,#PB_Ignore,200,160,"pb-win-notify",#PB_Window_SystemMenu|#PB_Window_ScreenCentered)
buttonLT = ButtonGadget(#PB_Any,10,10,60,40,"LT")
buttonLB = ButtonGadget(#PB_Any,10,50,60,40,"LB")
buttonCT = ButtonGadget(#PB_Any,70,10,60,40,"CT")
buttonCB = ButtonGadget(#PB_Any,70,50,60,40,"CB")
buttonRT = ButtonGadget(#PB_Any,130,10,60,40,"RT")
buttonRB = ButtonGadget(#PB_Any,130,50,60,40,"RB")
cbNoTimeout = CheckBoxGadget(#PB_Any,10,90,90,20,"no timeout")
cbCloseOnClick = CheckBoxGadget(#PB_Any,100,90,90,20,"close on click")
buttonDestroyAll = ButtonGadget(#PB_Any,10,110,180,40,"destroy all")

; icons/fonts
titleFont = FontID(LoadFont(#PB_Any,"Calibri",13,#PB_Font_Bold))
msgFont = FontID(LoadFont(#PB_Any,"Calibri",11))
iconLT = ImageID(LoadImage(#PB_Any,"iLT.png"))
iconLB = ImageID(LoadImage(#PB_Any,"iLB.png"))
iconCT = ImageID(LoadImage(#PB_Any,"iCT.png"))
iconCB = ImageID(LoadImage(#PB_Any,"iCB.png"))
iconRT = ImageID(LoadImage(#PB_Any,"iRT.png"))
iconRB = ImageID(LoadImage(#PB_Any,"iRB.png"))

; basic procedure to create random amount of text
Procedure.s createLorem()
  For i = 1 To Random(5,1)
    lorem.s + "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. "
  Next
  ProcedureReturn lorem
EndProcedure

; you can tune the thread parameter, which defines the animation step in msec
; however i recommend to keep it between 10 and 30
CreateThread(@wnProcess(),10)

Repeat
  ev = WaitWindowEvent()
  If ev = #wnCleanup : wnCleanup(EventData()) : EndIf
  If ev = #PB_Event_Gadget
    Select EventGadget()
      Case buttonLT
        wnNotify("Hello there!",createLorem(),#wnLT,timeout,$646503,$eeeeee,titleFont,msgFont,iconLT,onClick,0)
      Case buttonLB
        wnNotify("Hello there!",createLorem(),#wnLB,timeout,$435bd9,$eeeeee,titleFont,msgFont,iconLB,onClick,0)
      Case buttonCT
        wnNotify("Hello there!",createLorem(),#wnCT,timeout,$c88200,$eeeeee,titleFont,msgFont,iconCT,onClick,0)
      Case buttonCB
        wnNotify("Hello there!",createLorem(),#wnCB,timeout,$4229c0,$eeeeee,titleFont,msgFont,iconCB,onClick,0)
      Case buttonRT
        wnNotify("Hello there!",createLorem(),#wnRT,timeout,$493603,$eeeeee,titleFont,msgFont,iconRT,onClick,0)
      Case buttonRB
        wnNotify("Hello there!",createLorem(),#wnRB,timeout,$7a7753,$eeeeee,titleFont,msgFont,iconRB,onClick,0)
      Case cbNoTimeout
        If GetGadgetState(cbNoTimeout) = #PB_Checkbox_Checked
          timeout = #wnForever
        Else
          timeout = 3000
        EndIf
      Case cbCloseOnClick
        If GetGadgetState(cbCloseOnClick) = #PB_Checkbox_Checked
          onClick = #wnClose
        Else
          onClick = #wnSendEvent
        EndIf
      Case buttonDestroyAll
        ; should be called in a thread
        CreateThread(@wnDestroyAll(),0)
    EndSelect
  EndIf
  ; this is the event which will be sent if you call wnNotify() with onClick = #wnSendEvent
  ; and click on the created notification
  If ev = #wnClick
    Debug "you clicked on notification " + EventWindow()
    ; here you can also call EventData() to get the onClickData param you passed while calling wnNotify()
    ; it unlocks many possibilities, for example you can open the desired url, run some program, etc
  EndIf
Until ev = #PB_Event_CloseWindow
; IDE Options = PureBasic 5.31 (Windows - x86)
; EnableUnicode
; EnableXP
; Executable = wn.exe
; CompileSourceDirectory
; EnableBuildCount = 2