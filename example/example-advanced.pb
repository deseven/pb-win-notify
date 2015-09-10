; pb-win-notify advanced example

; in this example you'll see how to use the advanced functionality

IncludeFile "../wnotify.pbi"
UsePNGImageDecoder()

timeout = 3000
onClick = #wnClickNone

OpenWindow(0,#PB_Ignore,#PB_Ignore,200,160,"pb-win-notify advanced",#PB_Window_SystemMenu|#PB_Window_ScreenCentered)
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
iconLT = ImageID(LoadImage(#PB_Any,"res\iLT.png"))
iconLB = ImageID(LoadImage(#PB_Any,"res\iLB.png"))
iconCT = ImageID(LoadImage(#PB_Any,"res\iCT.png"))
iconCB = ImageID(LoadImage(#PB_Any,"res\iCB.png"))
iconRT = ImageID(LoadImage(#PB_Any,"res\iRT.png"))
iconRB = ImageID(LoadImage(#PB_Any,"res\iRB.png"))

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
  If ev = #wnCleanup : wnCleanup(EventWindow()) : EndIf
  If ev = #PB_Event_Gadget
    Select EventGadget()
      Case buttonLT
        wnNotify("Hello there!",createLorem(),#wnLT,timeout,$646503,$eeeeee,titleFont,msgFont,iconLT,onClick)
      Case buttonLB
        wnNotify("Hello there!",createLorem(),#wnLB,timeout,$435bd9,$eeeeee,titleFont,msgFont,iconLB,onClick)
      Case buttonCT
        wnNotify("Hello there!",createLorem(),#wnCT,timeout,$c88200,$eeeeee,titleFont,msgFont,iconCT,onClick)
      Case buttonCB
        wnNotify("Hello there!",createLorem(),#wnCB,timeout,$4229c0,$eeeeee,titleFont,msgFont,iconCB,onClick)
      Case buttonRT
        wnNotify("Hello there!",createLorem(),#wnRT,timeout,$493603,$eeeeee,titleFont,msgFont,iconRT,onClick)
      Case buttonRB
        wnNotify("Hello there!",createLorem(),#wnRB,timeout,$7a7753,$eeeeee,titleFont,msgFont,iconRB,onClick)
      Case cbNoTimeout
        If GetGadgetState(cbNoTimeout) = #PB_Checkbox_Checked
          timeout = #wnForever
        Else
          timeout = 3000
        EndIf
      Case cbCloseOnClick
        If GetGadgetState(cbCloseOnClick) = #PB_Checkbox_Checked
          onClick = #wnClickClose
        Else
          onClick = #wnClickNone
        EndIf
      Case buttonDestroyAll
        ; should be called in a thread
        CreateThread(@wnDestroyAll(),#wnAll)
    EndSelect
  EndIf
Until ev = #PB_Event_CloseWindow
; IDE Options = PureBasic 5.31 (Windows - x86)
; EnableUnicode
; EnableThread
; EnableXP
; Executable = wn.exe
; CompileSourceDirectory
; EnableBuildCount = 2