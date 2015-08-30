; pb-win-notify rev.5
; written by deseven
; https://github.com/deseven/pb-win-notify
; http://deseven.info

; wnNotify(
;   title.s       - title of the notification
;   msg.s         - text of the notification
;   castFrom.b    - location of the notification, can be one of the following: #wnLT,#wnLB,#wnCT,#wnCB,#wnRT,#wnRB
;   timeout.l     - timeout in msec when the notification will be destroyed
;   bgColor.l     - background color
;   frColor.l     - front (text) color
;   titleFontID.i - FontID() of the desired title font
;   msgFontID.i   - FontID() of the desired message font
;   iconID.i      - ImageID() of the desired icon right before the title
;   onClick.b     - action to perform when you click on the notification, can be one of the following: #wnNothing,#wnClose,#wnSendEvent
;   onClickData.i - data which will be sent as EventData() (only if onClick = #wnSendEvent)
; )

; set that to true to check what's going on
#wnDebug = #False

; animations
#wnFadeIn = #True
#wnSlideIn = #True
#wnFadeOut = #False

; and animations' time
#wnInAnimTime = 500
#wnOutAnimTime = 800

EnableExplicit

; +1000 to make sure that we won't interfere in some custom events
Enumeration #PB_Event_FirstCustomValue + 1000
  #wnCleanup
  #wnClick
EndEnumeration

Enumeration wnClickActions
  #wnNothing
  #wnClose
  #wnSendEvent
EndEnumeration

Enumeration wnCastFrom
  #wnLT
  #wnLB
  #wnCT
  #wnCB
  #wnRT
  #wnRB
  #wnAll
EndEnumeration

Structure wnNotificationParams
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
  onClick.b
  onClickData.i
EndStructure

Structure wnNotification
  active.i
  shown.b
  params.wnNotificationParams
  title.s
  msg.s
EndStructure

#wnForever = -1

Define wnMutex.i = CreateMutex()
NewList wnNotifications.wnNotification()

; that's what you should call to display your notification
Declare wnNotify(title.s,msg.s,castFrom.b = 0,timeout.l = 3000,bgColor.l = $ffffff,frColor.l = $000000,titleFontID.i = 0,msgFontID.i = 0,iconID.i = 0,onClick.b = #wnNothing,onClickData.i = #Null)

; (thread) animation and control
Declare wnProcess(wait.i)

; destroy old notifications
Declare wnCleanup(wnd.i)

; (thread) destroy notification
Declare wnDestroy(wnd.i)

; (thread) destroy all notifications
Declare wnDestroyAll(castFrom.i = #wnAll)

; (thread, internal) helper function to actually add the notification without bothering the main thread
Declare wnAdd(*notification.wnNotification)

; (internal) callback for our notifications
Declare wnCallback(hWnd.i,msg.i,wParam.i,lParam.i)

; (internal) processing actions for notification event
Declare wnOnclick(hWnd.i)

; (internal) recalc the remaining notifications positions
Declare wnRecalc(height.w,castFrom.b)

; (internal) taken from pb forums, don't remember the exact topic
Declare wnHideFromTaskBar(hWnd.i,flag.b)

Procedure wnNotify(title.s,msg.s,castFrom.b = 0,timeout.l = 3000,bgColor.l = $ffffff,frColor.l = $000000,titleFontID.i = 0,msgFontID.i = 0,iconID.i = 0,onClick.b = #wnNothing,onClickData.i = #Null)
  Protected rc.RECT
  Protected titleGadget.i,msgGadget.i,iconGadget.i,hdc.i,font.i
  Protected *notification.wnNotification = AllocateMemory(SizeOf(wnNotification))
  *notification\title = title
  *notification\msg = msg
  *notification\params\castFrom = castFrom
  *notification\params\timeout = timeout
  *notification\params\bgColor = bgColor
  *notification\params\frColor = frColor
  *notification\params\titleFontID = titleFontID
  *notification\params\msgFontID = msgFontID
  *notification\params\iconID = iconID
  *notification\params\window = OpenWindow(#PB_Any,#PB_Ignore,#PB_Ignore,320,100,"",#WS_POPUPWINDOW|#PB_Window_Invisible)
  *notification\params\windowID = WindowID(*notification\params\window)
  *notification\params\onClick = onClick
  *notification\params\onClickData = onClickData
  SetWindowLongPtr_(*notification\params\windowID,#GWL_EXSTYLE,GetWindowLongPtr_(*notification\params\windowID,#GWL_EXSTYLE)|#WS_EX_LAYERED)
  wnHideFromTaskBar(*notification\params\windowID,#True)
  SetWindowCallback(@wnCallback(),*notification\params\window)
  If *notification\params\iconID
    iconGadget = ImageGadget(#PB_Any,10,10,24,24,*notification\params\iconID)
    titleGadget = TextGadget(#PB_Any,42,12,270,20,*notification\title)
  Else
    titleGadget = TextGadget(#PB_Any,10,12,300,20,*notification\title)
  EndIf
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
  ProcedureReturn *notification\params\window  
EndProcedure

Procedure wnAdd(*notification.wnNotification)
  Shared wnMutex.i,wnNotifications()
  Protected rc.RECT
  LockMutex(wnMutex)
  SystemParametersInfo_(#SPI_GETWORKAREA,0,rc,0)
  If *notification\params\castFrom = #wnLT Or *notification\params\castFrom = #wnRT Or *notification\params\castFrom = #wnCT
    *notification\params\y = rc\top + 10
  Else
    *notification\params\y = rc\bottom - *notification\params\h - 10
  EndIf
  ForEach wnNotifications()
    If wnNotifications()\params\castFrom = *notification\params\castFrom
      If *notification\params\castFrom = #wnLT Or *notification\params\castFrom = #wnRT Or *notification\params\castFrom = #wnCT
        *notification\params\y = wnNotifications()\params\y + wnNotifications()\params\h + 10
      Else
        *notification\params\y = wnNotifications()\params\y - *notification\params\h - 10
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
  AddElement(wnNotifications())
  wnNotifications()\msg = *notification\msg
  wnNotifications()\title = *notification\title
  wnNotifications()\params = *notification\params
  ClearStructure(*notification,wnNotification)
  FreeMemory(*notification)
  UnlockMutex(wnMutex)
EndProcedure

Procedure wnProcess(wait.i)
  Shared wnMutex.i,wnNotifications()
  Protected animX.w,animY.w,castFrom.b,height.w,timePassed.i,deltaMove.f,deltaAlpha.f
  Repeat
    LockMutex(wnMutex)
    ForEach wnNotifications()
      If Not wnNotifications()\active
        CompilerIf #wnDebug : Debug Str(ElapsedMilliseconds()) +  ": displaying notification in [" + Str(wnNotifications()\params\x) + "," + Str(wnNotifications()\params\y) + "]" : CompilerEndIf
        wnNotifications()\active = ElapsedMilliseconds()
        ShowWindow_(wnNotifications()\params\windowID,#SW_SHOWNOACTIVATE)
      EndIf
      timePassed = ElapsedMilliseconds() - wnNotifications()\active
      If timePassed <= #wnInAnimTime
        CompilerIf #wnDebug : Debug Str(ElapsedMilliseconds()) + ": anim display " + Str(timePassed) : CompilerEndIf
        If #wnSlideIn
          deltaMove = 330/#wnInAnimTime
          Select wnNotifications()\params\castFrom
            Case #wnLT,#wnLB
              deltaMove = (320 + wnNotifications()\params\x)/#wnInAnimTime
              animX = -320 + deltaMove*timePassed
              animY = wnNotifications()\params\y
            Case #wnCT,#wnCB
              animX = wnNotifications()\params\x
              animY = wnNotifications()\params\y
            Case #wnRT,#wnRB
              animX = wnNotifications()\params\x + 330 - deltaMove*timePassed
              animY = wnNotifications()\params\y
          EndSelect
        Else
          animX = wnNotifications()\params\x
          animY = wnNotifications()\params\y
        EndIf
        If #wnFadeIn : deltaAlpha = timePassed/#wnInAnimTime : Else : deltaAlpha = 1 : EndIf
        SetWindowPos_(wnNotifications()\params\windowID,#HWND_TOPMOST,animX,animY,320,wnNotifications()\params\h,#SWP_NOACTIVATE)
        SetLayeredWindowAttributes_(wnNotifications()\params\windowID,0,deltaAlpha*255,2)
      ElseIf Not wnNotifications()\shown
        wnNotifications()\shown = #True
        SetWindowPos_(wnNotifications()\params\windowID,#HWND_TOPMOST,wnNotifications()\params\x,wnNotifications()\params\y,320,wnNotifications()\params\h,#SWP_NOACTIVATE)
        SetLayeredWindowAttributes_(wnNotifications()\params\windowID,0,255,2)
        RedrawWindow_(wnNotifications()\params\windowID,0,0,#RDW_INVALIDATE)
      EndIf
      If wnNotifications()\params\timeout <> #wnForever
        If timePassed >= wnNotifications()\params\timeout + #wnOutAnimTime Or (timePassed >= wnNotifications()\params\timeout And Not #wnFadeOut)
          CompilerIf #wnDebug : Debug Str(ElapsedMilliseconds()) + ": destroyed notification " + Str(ListIndex(wnNotifications())) : CompilerEndIf
          PostEvent(#wnCleanup,0,0,0,wnNotifications()\params\window)
          height = wnNotifications()\params\h
          castFrom = wnNotifications()\params\castFrom
          DeleteElement(wnNotifications(),#True)
          wnRecalc(height,castFrom)
        ElseIf timePassed >= wnNotifications()\params\timeout
          deltaAlpha = Abs(wnNotifications()\params\timeout - timePassed)/#wnOutAnimTime*255
          CompilerIf #wnDebug : Debug Str(ElapsedMilliseconds()) + ": anim destroy " + Str(timePassed) : CompilerEndIf
          SetLayeredWindowAttributes_(wnNotifications()\params\windowID,0,255-deltaAlpha,2)
        EndIf
      EndIf
    Next
    UnlockMutex(wnMutex)
    Delay(wait)
  ForEver
EndProcedure

Procedure wnCleanup(wnd.i)
  If IsWindow(wnd) : CloseWindow(wnd) : EndIf
  CompilerIf #wnDebug : Debug Str(ElapsedMilliseconds()) + ": destroyed window " + Str(window) : CompilerEndIf
EndProcedure

Procedure wnCallback(hWnd.i,msg.i,wParam.i,lParam.i)
  If msg = #WM_LBUTTONUP
    CreateThread(@wnOnclick(),hWnd)
  EndIf
  ProcedureReturn #PB_ProcessPureBasicEvents
EndProcedure

Procedure wnOnclick(hWnd.i)
  Shared wnMutex.i,wnNotifications()
  Protected height.w,castFrom.b
  LockMutex(wnMutex)
  ForEach wnNotifications()
    If wnNotifications()\params\windowID = hWnd
      Select wnNotifications()\params\onClick
        Case #wnClose
          PostEvent(#wnCleanup,0,0,0,wnNotifications()\params\window)
          height = wnNotifications()\params\h
          castFrom = wnNotifications()\params\castFrom
          DeleteElement(wnNotifications(),#True)
          wnRecalc(height,castFrom)
        Case #wnSendEvent
          PostEvent(#wnClick,wnNotifications()\params\window,#Null,#Null,wnNotifications()\params\onClickData)
      EndSelect
      Break
    EndIf
  Next
  UnlockMutex(wnMutex)
EndProcedure

Procedure wnRecalc(height.w,castFrom.b)
  Shared wnNotifications()
  Protected rc.RECT,cur.i,offsetTop.w,offsetBottom.w
  SystemParametersInfo_(#SPI_GETWORKAREA,0,rc,0)
  offsetTop = rc\top
  offsetBottom = rc\bottom
  cur = ListIndex(wnNotifications())
  ForEach wnNotifications()
    If wnNotifications()\params\castFrom = castFrom
      If castFrom = #wnLT Or castFrom = #wnRT Or castFrom = #wnCT
        wnNotifications()\params\y = offsetTop + 10 
        offsetTop = wnNotifications()\params\y + wnNotifications()\params\h
      Else
        wnNotifications()\params\y = offsetBottom - wnNotifications()\params\h - 10 
        offsetBottom = wnNotifications()\params\y
      EndIf
      SetWindowPos_(wnNotifications()\params\windowID,#HWND_TOPMOST,wnNotifications()\params\x,wnNotifications()\params\y,320,wnNotifications()\params\h,#SWP_NOACTIVATE)
      SetLayeredWindowAttributes_(wnNotifications()\params\windowID,0,255,2)
      RedrawWindow_(wnNotifications()\params\windowID,0,0,#RDW_INVALIDATE)
    EndIf
  Next
  If cur >= 0 : SelectElement(wnNotifications(),cur) : EndIf
EndProcedure

Procedure wnDestroy(wnd.i)
  Shared wnMutex,wnNotifications()
  Protected height.w,castFrom.b
  LockMutex(wnMutex)
  ForEach wnNotifications()
    If wnNotifications()\params\window = wnd
      height = wnNotifications()\params\h
      castFrom = wnNotifications()\params\castFrom
      PostEvent(#wnCleanup,0,0,0,wnNotifications()\params\window)
      DeleteElement(wnNotifications(),#True)
      wnRecalc(height,castFrom)
    EndIf
  Next
  UnlockMutex(wnMutex)
EndProcedure

Procedure wnDestroyAll(castFrom.i = #wnAll)
  Shared wnMutex,wnNotifications()
  LockMutex(wnMutex)
  ForEach wnNotifications()
    If castFrom = #wnAll Or wnNotifications()\params\castFrom = castFrom
      PostEvent(#wnCleanup,0,0,0,wnNotifications()\params\window)
      DeleteElement(wnNotifications())
    EndIf
  Next
  UnlockMutex(wnMutex)
EndProcedure

Procedure wnHideFromTaskBar(hWnd.i,flag.b)
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