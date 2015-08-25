; pb-win-notify rev.3
; written by deseven
; http://deseven.info

; set that to true to check what's going on
#wnDebug = #False

EnableExplicit

; +1000 to make sure that we won't interfere in some custom events
Enumeration #PB_Event_FirstCustomValue + 1000
  #wnCleanup
EndEnumeration

Enumeration castFrom
  #wnLT
  #wnLB
  #wnCT
  #wnCB
  #wnRT
  #wnRB
EndEnumeration

Structure notificationParams
  window.i
  windowID.i
  x.w
  y.w
  h.w
  timeout.l
  castFrom.b
  bgColor.l
  frColor.l
  titleFontID.i
  msgFontID.i
  iconID.i
EndStructure

Structure notification
  active.i
  shown.b
  params.notificationParams
  title.s
  msg.s
EndStructure

Define wnMutex.i = CreateMutex()
NewList notifications.notification()

Declare hideFromTaskBar(hWnd.l,flag.l)
Declare wnNotify(title.s,msg.s,castFrom.b = 0,timeout.l = 3000,bgColor.l = $ffffff,frColor.l = $000000,titleFontID = 0,msgFontID = 0,iconID = 0)
Declare wnAdd(*notification.notification)
Declare wnProcess(wait.i)
Declare wnCleanup(window.i)

; that's what you should call to display your notification
Procedure wnNotify(title.s,msg.s,castFrom.b = 0,timeout.l = 3000,bgColor.l = $ffffff,frColor.l = $000000,titleFontID = 0,msgFontID = 0,iconID = 0)
  Protected rc.RECT
  Protected titleGadget.i,msgGadget.i,iconGadget.i,hdc.i,font.i
  Protected *notification.notification = AllocateMemory(SizeOf(notification))
  *notification\title = title
  *notification\msg = msg
  *notification\params\castFrom = castFrom
  *notification\params\timeout = timeout
  *notification\params\bgColor = bgColor
  *notification\params\frColor = frColor
  *notification\params\titleFontID = titleFontID
  *notification\params\msgFontID = msgFontID
  *notification\params\iconID = iconID
  *notification\params\window = OpenWindow(#PB_Any,#PB_Ignore,#PB_Ignore,320,100,"",#WS_POPUPWINDOW|#WS_DISABLED|#PB_Window_Invisible)
  *notification\params\windowID = WindowID(*notification\params\window)
  SetWindowLongPtr_(*notification\params\windowID,#GWL_EXSTYLE,GetWindowLongPtr_(*notification\params\windowID,#GWL_EXSTYLE)|#WS_EX_LAYERED)
  hideFromTaskBar(*notification\params\windowID,#True)
  If *notification\params\iconID
    iconGadget = ImageGadget(#PB_Any,10,10,24,24,*notification\params\iconID)
  EndIf
  titleGadget = TextGadget(#PB_Any,42,12,270,20,*notification\title)
  msgGadget = TextGadget(#PB_Any,10,36,300,50,*notification\msg)
  SetGadgetColor(titleGadget,#PB_Gadget_BackColor,*notification\params\bgColor)
  SetGadgetColor(titleGadget,#PB_Gadget_FrontColor,*notification\params\frColor)
  SetGadgetColor(msgGadget,#PB_Gadget_BackColor,*notification\params\bgColor)
  SetGadgetColor(msgGadget,#PB_Gadget_FrontColor,*notification\params\frColor)
  If *notification\params\titleFontID
    SetGadgetFont(titleGadget,*notification\params\titleFontID)
  EndIf
  If *notification\params\msgFontID
    SetGadgetFont(msgGadget,*notification\params\msgFontID)
  EndIf
  hdc = GetDC_(GadgetID(msgGadget))
  SetTextAlign_(hdc,#TA_LEFT|#TA_TOP|#TA_NOUPDATECP)
  font = SelectObject_(hdc,SendMessage_(GadgetID(msgGadget),#WM_GETFONT,0,0))
  rc\top = 1
  rc\left = 1
  rc\right = 300
  rc\bottom = 10
  DrawText_(hdc,GetGadgetText(msgGadget),Len(GetGadgetText(msgGadget)),rc,#DT_WORDBREAK|#DT_CALCRECT)
  ReleaseDC_(GadgetID(msgGadget),hdc)
  ResizeGadget(msgGadget,#PB_Ignore,#PB_Ignore,rc\right+2*GetSystemMetrics_(#SM_CXEDGE),rc\bottom+2*GetSystemMetrics_(#SM_CYEDGE))
  *notification\params\h = rc\bottom+2*GetSystemMetrics_(#SM_CYEDGE) + 44
  SetWindowColor(*notification\params\window,*notification\params\bgColor)
  CreateThread(@wnAdd(),*notification)
  CompilerIf #wnDebug : Debug Str(ElapsedMilliseconds()) + ": adding notification" : CompilerEndIf
EndProcedure

; helper function to actually add the notification without bothering the main thread
Procedure wnAdd(*notification.notification)
  Shared wnMutex.i,notifications()
  Protected rc.RECT
  LockMutex(wnMutex)
  SystemParametersInfo_(#SPI_GETWORKAREA,0,rc,0)
  If *notification\params\castFrom = #wnLT Or *notification\params\castFrom = #wnRT Or *notification\params\castFrom = #wnCT
    *notification\params\y = rc\top + 10
  Else
    *notification\params\y = rc\bottom - *notification\params\h - 10
  EndIf
  ForEach notifications()
    If notifications()\params\castFrom = *notification\params\castFrom
      If *notification\params\castFrom = #wnLT Or *notification\params\castFrom = #wnRT Or *notification\params\castFrom = #wnCT
        *notification\params\y = notifications()\params\y + notifications()\params\h + 10
      Else
        *notification\params\y = notifications()\params\y - *notification\params\h - 10
      EndIf
    EndIf
  Next
  Select *notification\params\castFrom
    Case #wnLT,#wnLB
      *notification\params\x = rc\left + 10
    Case #wnCT,#wnCB
      *notification\params\x = rc\right/2 - 320/2
    Case #wnRT,#wnRB
      *notification\params\x = rc\right - 320 - 10
  EndSelect
  AddElement(notifications())
  notifications()\msg = *notification\msg
  notifications()\title = *notification\title
  notifications()\params = *notification\params
  ClearStructure(*notification,notification)
  FreeMemory(*notification)
  UnlockMutex(wnMutex)
EndProcedure

; animation and control, should be run in a thread
Procedure wnProcess(wait.i)
  Shared wnMutex.i,notifications()
  Protected tempx.w,tempy.w
  Repeat
    LockMutex(wnMutex)
    ForEach notifications()
      If Not notifications()\active
        CompilerIf #wnDebug : Debug Str(ElapsedMilliseconds()) +  ": displaying notification in [" + Str(notifications()\params\x) + "," + Str(notifications()\params\y) + "]" : CompilerEndIf
        notifications()\active = ElapsedMilliseconds()
        ShowWindow_(notifications()\params\windowID,#SW_SHOWNOACTIVATE)
      EndIf
      Define timePassed.i = ElapsedMilliseconds() - notifications()\active
      If timePassed <= 510
        CompilerIf #wnDebug : Debug Str(ElapsedMilliseconds()) + ": anim display " + Str(timePassed) : CompilerEndIf
        Define delta.f = 330/510
        Select notifications()\params\castFrom
          Case #wnLT,#wnLB
            delta = (320 + notifications()\params\x)/510
            tempx = -320 + delta*timePassed
            tempy = notifications()\params\y
          Case #wnCT,#wnCB
            tempx = notifications()\params\x
            tempy = notifications()\params\y
          Case #wnRT,#wnRB
            tempx = notifications()\params\x + 330 - delta*timePassed
            tempy = notifications()\params\y
        EndSelect
        SetWindowPos_(notifications()\params\windowID,#HWND_TOPMOST,tempx,tempy,320,notifications()\params\h,#SWP_NOACTIVATE)
        SetLayeredWindowAttributes_(notifications()\params\windowID,0,timePassed/2,2)
      ElseIf Not notifications()\shown
        notifications()\shown = #True
        SetWindowPos_(notifications()\params\windowID,#HWND_TOPMOST,notifications()\params\x,notifications()\params\y,320,notifications()\params\h,#SWP_NOACTIVATE)
        SetLayeredWindowAttributes_(notifications()\params\windowID,0,255,2)
      EndIf
      If timePassed >= notifications()\params\timeout
        If timePassed >= notifications()\params\timeout + 510
          CompilerIf #wnDebug : Debug Str(ElapsedMilliseconds()) + ": destroyed notification " + Str(ListIndex(notifications())) : CompilerEndIf
          PostEvent(#wnCleanup,0,0,0,notifications()\params\window)
          DeleteElement(notifications())
        Else
          CompilerIf #wnDebug : Debug Str(ElapsedMilliseconds()) + ": anim destroy " + Str(timePassed) : CompilerEndIf
          SetLayeredWindowAttributes_(notifications()\params\windowID,0,255-Abs(notifications()\params\timeout - timePassed)/2,2)
        EndIf
      EndIf
    Next
    UnlockMutex(wnMutex)
    Delay(wait)
  ForEver
EndProcedure

; destroying window from main thread (because... reasons)
Procedure wnCleanup(window.i)
  CloseWindow(window)
  CompilerIf #wnDebug : Debug Str(ElapsedMilliseconds()) + ": destroyed window " + Str(window) : CompilerEndIf
EndProcedure

; taken from pb forums, don't remember the exact topic
Procedure hideFromTaskBar(hWnd.l,flag.l)
  Protected TBL.ITaskbarList
  CoInitialize_(0)
  If CoCreateInstance_(?CLSID_TaskBarList,0,1,?IID_ITaskBarList,@TBL) = #S_OK
    TBL\HrInit()
    If flag
      TBL\DeleteTab(hWnd)
    Else
      TBL\AddTab(hWnd)
    EndIf
    TBL\Release()
  EndIf
  CoUninitialize_()
  DataSection
    CLSID_TaskBarList:
    Data.l $56FDF344
    Data.w $FD6D,$11D0
    Data.b $95,$8A,$00,$60,$97,$C9,$A0,$90
    IID_ITaskBarList:
    Data.l $56FDF342
    Data.w $FD6D,$11D0
    Data.b $95,$8A,$00,$60,$97,$C9,$A0,$90
  EndDataSection
EndProcedure

DisableExplicit
; IDE Options = PureBasic 5.31 (Windows - x86)
; EnableUnicode
; EnableXP
; EnableBuildCount = 0