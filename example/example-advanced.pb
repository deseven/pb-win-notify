; pb-win-notify advanced example

; in this example you'll see how to use the advanced functionality

IncludeFile "../wnotify.pbi"
UsePNGImageDecoder()

timeout = 3000
onClick = WinNotify::#ClickNone

;	A macro to makelong (used by custom placed notification)
Macro MakeLong(loWord, hiWord)
  (hiWord << 16 | loWord)
EndMacro

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

; you can tune the wnInit() parameter, which defines the animation step in msec
; however i recommend to keep it between 10 and 30
WinNotify::Init(10)

; Display a custom placed notification :
WinNotify::Notify("This is a custom placed notification!","Look at the code to know how it's done!",MakeLong(WindowX(0),(WindowY(0)+10+WindowHeight(0,#PB_Window_FrameCoordinate))),2000,$646503,$eeeeee,titleFont,msgFont,iconCT,onClick)

Repeat
  ev = WaitWindowEvent()
  If ev = WinNotify::#Cleanup : WinNotify::Cleanup() : EndIf
  If ev = #PB_Event_Gadget
    Select EventGadget()
      Case buttonLT
        WinNotify::Notify("Hello there!",createLorem(),WinNotify::#LT,timeout,$646503,$eeeeee,titleFont,msgFont,iconLT,onClick)
      Case buttonLB
        WinNotify::Notify("Hello there!",createLorem(),WinNotify::#LB,timeout,$435bd9,$eeeeee,titleFont,msgFont,iconLB,onClick)
      Case buttonCT
        WinNotify::Notify("Hello there!",createLorem(),WinNotify::#CT,timeout,$c88200,$eeeeee,titleFont,msgFont,iconCT,onClick)
      Case buttonCB
        WinNotify::Notify("Hello there!",createLorem(),WinNotify::#CB,timeout,$4229c0,$eeeeee,titleFont,msgFont,iconCB,onClick)
      Case buttonRT
        WinNotify::Notify("Hello there!",createLorem(),WinNotify::#RT,timeout,$493603,$eeeeee,titleFont,msgFont,iconRT,onClick)
      Case buttonRB
        WinNotify::Notify("Hello there!",createLorem(),WinNotify::#RB,timeout,$7a7753,$eeeeee,titleFont,msgFont,iconRB,onClick)
      Case cbNoTimeout
        If GetGadgetState(cbNoTimeout) = #PB_Checkbox_Checked
          timeout = WinNotify::#Forever
        Else
          timeout = 3000
        EndIf
      Case cbCloseOnClick
        If GetGadgetState(cbCloseOnClick) = #PB_Checkbox_Checked
          onClick = WinNotify::#ClickClose
        Else
          onClick = WinNotify::#ClickNone
        EndIf
      Case buttonDestroyAll
        WinNotify::DestroyAll()
    EndSelect
  EndIf
Until ev = #PB_Event_CloseWindow
; IDE Options = PureBasic 5.40 LTS (Windows - x64)
; CursorPosition = 49
; FirstLine = 12
; Folding = -
; EnableUnicode
; EnableThread
; EnableXP
; Executable = wn.exe
; CompileSourceDirectory
; EnableBuildCount = 4