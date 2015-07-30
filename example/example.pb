; pb-win-notify example file

; in order to use pb-win-notify you have to perform 4 simple steps:
; 1. include the wnotify.pbi file
; 2. create thread with wnProcess() procedure
; 3. periodically check for the #wnCleanup event and call wnCleanup()
; 4. create notifications by calling wnNotification() from anywhere you need

IncludeFile "../wnotify.pbi" ; 1

UsePNGImageDecoder()

OpenWindow(0,#PB_Ignore,#PB_Ignore,200,100,"pb-win-notify",#PB_Window_SystemMenu|#PB_Window_ScreenCentered)
buttonLT = ButtonGadget(#PB_Any,10,10,60,40,"LT")
buttonLB = ButtonGadget(#PB_Any,10,50,60,40,"LB")
buttonCT = ButtonGadget(#PB_Any,70,10,60,40,"CT")
buttonCB = ButtonGadget(#PB_Any,70,50,60,40,"CB")
buttonRT = ButtonGadget(#PB_Any,130,10,60,40,"RT")
buttonRB = ButtonGadget(#PB_Any,130,50,60,40,"RB")

; you can use any icons/fonts or don't use anything at all, as you like
titleFont = FontID(LoadFont(#PB_Any,"Arial",14,#PB_Font_Bold|#PB_Font_HighQuality))
msgFont = FontID(LoadFont(#PB_Any,"Arial",12,#PB_Font_HighQuality))
iconLT = ImageID(LoadImage(#PB_Any,"iLT.png"))
iconLB = ImageID(LoadImage(#PB_Any,"iLB.png"))
iconCT = ImageID(LoadImage(#PB_Any,"iCT.png"))
iconCB = ImageID(LoadImage(#PB_Any,"iCB.png"))
iconRT = ImageID(LoadImage(#PB_Any,"iRT.png"))
iconRB = ImageID(LoadImage(#PB_Any,"iRB.png"))

; basic procedure to create random amount of text
Procedure.s createLorum()
  For i = 1 To Random(5,1)
    lorum.s + "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. "
  Next
  ProcedureReturn lorum
EndProcedure

CreateThread(@wnProcess(),10) ; 2

Repeat
  ev = WaitWindowEvent()
  If ev = #wnCleanup : wnCleanup(EventData()) : EndIf ; 3
  If ev = #PB_Event_Gadget
    Select EventGadget() ; 4
      Case buttonLT
        wnNotify("Hello there!",createLorum(),#wnLT,3000,$000099,0,titleFont,msgFont,iconLT)
      Case buttonLB
        wnNotify("Hello there!",createLorum(),#wnLB,3000,$009900,0,titleFont,msgFont,iconLB)
      Case buttonCT
        wnNotify("Hello there!",createLorum(),#wnCT,3000,$cc0000,0,titleFont,msgFont,iconCT)
      Case buttonCB
        wnNotify("Hello there!",createLorum(),#wnCB,3000,$999900,0,titleFont,msgFont,iconCB)
      Case buttonRT
        wnNotify("Hello there!",createLorum(),#wnRT,3000,$009999,0,titleFont,msgFont,iconRT)
      Case buttonRB
        wnNotify("Hello there!",createLorum(),#wnRB,3000,$990099,0,titleFont,msgFont,iconRB)
    EndSelect
  EndIf
Until ev = #PB_Event_CloseWindow
; IDE Options = PureBasic 5.31 (Windows - x86)
; EnableUnicode
; EnableXP
; Executable = wn.exe
; DisableDebugger
; CompileSourceDirectory
; EnableBuildCount = 1