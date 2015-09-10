; pb-win-notify rev.6
; written by deseven
; https://github.com/deseven/pb-win-notify
; http://deseven.info

; wnNotify(
;  title.s       - title of the notification
;  msg.s         - text of the notification
;  castFrom.b    - location of the notification, can be one of the following: #wnLT,#wnLB,#wnCT,#wnCB,#wnRT,#wnRB
;  timeout.l     - timeout in msec when the notification will be destroyed
;  bgColor.l     - background color
;  frColor.l     - front (text) color
;  titleFontID.i - FontID() of the desired title font
;  msgFontID.i   - FontID() of the desired message font
;  iconID.i      - ImageID() of the desired icon right before the title
;  onClick.b     - action to perform when you click on the notification, can be one of the following: #wnClickNone,#wnClickClose,#wnClickEvent
;  onClickData.i - data which will be sent as EventData() (only if onClick = #wnClickEvent)
;  onClose.b     - action to perform when notification is closing (by timeout or user action), can be #wnCloseNone or #wnCloseEvent
;  onCloseData.i - data which will be sent as EventData() (only if onClose = #wnCloseEvent)
; )

; wnNotifyStruct(
;  *notification.wnNotification - structure with params
; )

; set that to true to check what's going on
#wnDebug = #False

; animations
#wnFadeIn = #True
#wnSlideIn = #True
#wnFadeOut = #False

; and animations' time
#wnInAnimTime = 600
#wnOutAnimTime = 800

; defaults
#wnDefTimeout = 3000
#wnDefBgColor = $ffffff
#wnDefFrColor = $000000

EnableExplicit

; +1000 to make sure that we won't interfere in some custom events
Enumeration #PB_Event_FirstCustomValue + 1000
  #wnCleanup
  #wnClick
  #wnClose
EndEnumeration

Enumeration wnClickActions
  #wnClickNone
  #wnClickClose
  #wnClickEvent
EndEnumeration

Enumeration wnCloseActions
  #wnCloseNone
  #wnCloseEvent
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
  image.i
  imageID.i
  iconHandle.i
  titleHandle.i
  msgHandle.i
  x.i
  y.i
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
  onClose.b
  onCloseData.i
EndStructure

Structure wnNotification
  active.i
  shown.b
  params.wnNotificationParams
  title.s
  msg.s
EndStructure

#wnForever = -1
#wnIgnore = -32768

Define wnMutex.i = CreateMutex()
NewList wnNotifications.wnNotification()

; that's what you should call to display your notification
Declare wnNotify(title.s,msg.s,castFrom.b = #wnLT,timeout.l = #wnDefTimeout,bgColor.l = #wnDefBgColor,frColor.l = #wnDefFrColor,titleFontID.i = 0,msgFontID.i = 0,iconID.i = 0,onClick.b = #wnClickNone,onClickData.i = #Null,onClose.i = #wnCloseNone,onCloseData.i = #Null)

; the same but you can pass a structure instead of the long line of params
Declare wnNotifyStruct(*notification)

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

; (internal) destroy current notification
Declare wnDestroyThis()

; (internal) callback for our notifications
Declare wnCallback(hWnd.i,msg.i,wParam.i,lParam.i)

; (internal) processing actions for notification event
Declare wnOnclick(hWnd.i)

; (internal) recalc the remaining notifications positions
Declare wnRecalc(noLock.i = #True)

; (internal) creates notification image
Declare createNotificationImage(width.l,title.s,msg.s,frColor.l,bgColor.l,iconID.i,titleFontID.i,msgFontID.i)

; (internal) updates position, size and opacity of the notification
Declare updateNotification(window.i,windowID.i,image.i,x.l = #wnIgnore,y.l = #wnIgnore,w.l = #wnIgnore,h.l = #wnIgnore,alpha.w = #wnIgnore,showWindow = #False)

; (internal) taken from pb forums, don't remember the exact topic
Declare wnHideFromTaskBar(hWnd.i,flag.b)

; (internal) wrap long text with lines
Declare wrapText(text.s,width.l,List lines.s())

; (internal) gets the font size in pixels
Declare getFontSize(fontID.i)

Procedure wnNotify(title.s,msg.s,castFrom.b = #wnLT,timeout.l = #wnDefTimeout,bgColor.l = #wnDefBgColor,frColor.l = #wnDefFrColor,titleFontID.i = 0,msgFontID.i = 0,iconID.i = 0,onClick.b = #wnClickNone,onClickData.i = #Null,onClose.i = #wnCloseNone,onCloseData.i = #Null)
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
  *notification\params\onClick = onClick
  *notification\params\onClickData = onClickData
  *notification\params\onClose = onClose
  *notification\params\onCloseData = onCloseData
  ProcedureReturn wnNotifyStruct(*notification)
EndProcedure

Procedure wnNotifyStruct(*notification.wnNotification)
  Protected rc.RECT,wnd.i
  *notification\params\window = OpenWindow(#PB_Any,#PB_Ignore,#PB_Ignore,320,100,"",#PB_Window_ScreenCentered|#PB_Window_BorderLess|#PB_Window_Invisible)
  *notification\params\windowID = WindowID(*notification\params\window)
  SetWindowLongPtr_(*notification\params\windowID,#GWL_EXSTYLE,GetWindowLongPtr_(*notification\params\windowID,#GWL_EXSTYLE)|#WS_EX_LAYERED)
  wnHideFromTaskBar(*notification\params\windowID,#True)
  SetWindowCallback(@wnCallback(),*notification\params\window)
  StickyWindow(*notification\params\window,#True)
  wnd = *notification\params\window
  *notification\params\image = createNotificationImage(320,*notification\title,*notification\msg,*notification\params\frColor,*notification\params\bgColor,*notification\params\iconID,*notification\params\titleFontID,*notification\params\msgFontID)
  *notification\params\imageID = ImageID(*notification\params\image)
  *notification\params\h = ImageHeight(*notification\params\image)
  updateNotification(*notification\params\window,*notification\params\windowID,*notification\params\image,-10000,-10000,320,*notification\params\h,255,#True)
  CreateThread(@wnAdd(),*notification)
  CompilerIf #wnDebug : Debug Str(ElapsedMilliseconds()) + ": adding notification" : CompilerEndIf
  ProcedureReturn wnd
EndProcedure

Procedure wnAdd(*notification.wnNotification)
  Shared wnMutex.i,wnNotifications()
  Protected rc.RECT
  SystemParametersInfo_(#SPI_GETWORKAREA,0,rc,0)
  Select *notification\params\castFrom
    Case #wnLT,#wnLB
      *notification\params\x = rc\left + 10
    Case #wnCT,#wnCB
      *notification\params\x = rc\right/2 - 320/2
    Case #wnRT,#wnRB
      *notification\params\x = rc\right - 320 - 10
  EndSelect
  LockMutex(wnMutex)
  AddElement(wnNotifications())
  wnNotifications()\msg = *notification\msg
  wnNotifications()\title = *notification\title
  wnNotifications()\params = *notification\params
  wnRecalc(#True)
  UnlockMutex(wnMutex)
  ClearStructure(*notification,wnNotification)
  FreeMemory(*notification)
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
        updateNotification(wnNotifications()\params\window,wnNotifications()\params\windowID,wnNotifications()\params\image,animX,animY,320,wnNotifications()\params\h,255 * deltaAlpha)
      ElseIf Not wnNotifications()\shown
        wnNotifications()\shown = #True
        updateNotification(wnNotifications()\params\window,wnNotifications()\params\windowID,wnNotifications()\params\image,wnNotifications()\params\x,wnNotifications()\params\y,320,wnNotifications()\params\h,255)
      EndIf
      If wnNotifications()\params\timeout <> #wnForever
        If timePassed >= wnNotifications()\params\timeout + #wnOutAnimTime Or (timePassed >= wnNotifications()\params\timeout And Not #wnFadeOut)
          wnDestroyThis()
        ElseIf timePassed >= wnNotifications()\params\timeout
          deltaAlpha = Abs(wnNotifications()\params\timeout - timePassed)/#wnOutAnimTime*255
          updateNotification(wnNotifications()\params\window,wnNotifications()\params\windowID,wnNotifications()\params\image,#wnIgnore,#wnIgnore,320,wnNotifications()\params\h,255-deltaAlpha)
        EndIf
      EndIf
    Next
    UnlockMutex(wnMutex)
    Delay(wait)
  ForEver
EndProcedure

Procedure wnCleanup(wnd.i)
  If IsWindow(wnd) : CloseWindow(wnd) : EndIf
  CreateThread(@wnRecalc(),0)
  CompilerIf #wnDebug : Debug Str(ElapsedMilliseconds()) + ": destroyed window " + Str(wnd) : CompilerEndIf
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
        Case #wnClickClose
          wnDestroyThis()
        Case #wnClickEvent
          PostEvent(#wnClick,wnNotifications()\params\window,#Null,#Null,wnNotifications()\params\onClickData)
      EndSelect
      Break
    EndIf
  Next
  UnlockMutex(wnMutex)
EndProcedure

Procedure wnRecalc(noLock.i = #True)
  Shared wnNotifications(),wnMutex.i
  Protected osLT.i,osRT.i,osLB.i,osRB.i,osCT.i,osCB.i
  Protected rc.RECT,redraw.b,newY.i
  If Not noLock : LockMutex(wnMutex) : EndIf
  SystemParametersInfo_(#SPI_GETWORKAREA,0,rc,0)
  osLT = rc\top
  osRT = rc\top
  osCT = rc\top
  osLB = rc\bottom
  osRB = rc\bottom
  osCB = rc\bottom
  ForEach wnNotifications()
    redraw = #False
    Select wnNotifications()\params\castFrom
      Case #wnLT
        newY = osLT + 10
        If wnNotifications()\params\y <> newY
          wnNotifications()\params\y = newY
          redraw = #True
        EndIf
        osLT = newY + wnNotifications()\params\h
      Case #wnRT
        newY = osRT + 10
        If wnNotifications()\params\y <> newY
          wnNotifications()\params\y = newY
          redraw = #True
        EndIf
        osRT = newY + wnNotifications()\params\h
      Case #wnCT
        newY = osCT + 10
        If wnNotifications()\params\y <> newY
          wnNotifications()\params\y = newY
          redraw = #True
        EndIf
        osCT = newY + wnNotifications()\params\h
      Case #wnLB
        newY = osLB - wnNotifications()\params\h - 10
        If wnNotifications()\params\y <> newY
          wnNotifications()\params\y = newY
          redraw = #True
        EndIf
        osLB = newY
      Case #wnRB
        newY = osRB - wnNotifications()\params\h - 10
        If wnNotifications()\params\y <> newY
          wnNotifications()\params\y = newY
          redraw = #True
        EndIf
        osRB = newY
      Case #wnCB
        newY = osCB - wnNotifications()\params\h - 10
        If wnNotifications()\params\y <> newY
          wnNotifications()\params\y = newY
          redraw = #True
        EndIf
        osCB = newY
    EndSelect
    If redraw
      If wnNotifications()\active
        updateNotification(wnNotifications()\params\window,wnNotifications()\params\windowID,wnNotifications()\params\image,wnNotifications()\params\x,wnNotifications()\params\y,320,wnNotifications()\params\h,255)
      Else
        updateNotification(wnNotifications()\params\window,wnNotifications()\params\windowID,wnNotifications()\params\image,wnNotifications()\params\x,wnNotifications()\params\y,-10000,-10000,255)
      EndIf  
      CompilerIf #wnDebug : Debug Str(ElapsedMilliseconds()) + ": recalc for notification " + Str(wnNotifications()\params\window) : CompilerEndIf
    EndIf
  Next
  If Not noLock : UnlockMutex(wnMutex) : EndIf
EndProcedure

Procedure wnDestroy(wnd.i)
  Shared wnMutex,wnNotifications()
  Protected height.w,castFrom.b,cur.i
  LockMutex(wnMutex)
  ForEach wnNotifications()
    If wnNotifications()\params\window = wnd
      If wnNotifications()\params\onClose = #wnCloseEvent
        PostEvent(#wnClose,wnNotifications()\params\window,0,0,wnNotifications()\params\onCloseData)
      EndIf
      DeleteElement(wnNotifications())
      CompilerIf #wnDebug : Debug Str(ElapsedMilliseconds()) + ": destroyed notification " + Str(wnd) : CompilerEndIf
      PostEvent(#wnCleanup,wnd,0)
    EndIf
  Next
  UnlockMutex(wnMutex)
EndProcedure

Procedure wnDestroyThis()
  Shared wnNotifications()
  Protected height.w,castFrom.b,cur.i,wnd.i
  cur = ListIndex(wnNotifications())
  height = wnNotifications()\params\h
  castFrom = wnNotifications()\params\castFrom
  If wnNotifications()\params\onClose = #wnCloseEvent
    PostEvent(#wnClose,wnNotifications()\params\window,0,0,wnNotifications()\params\onCloseData)
  EndIf
  wnd = wnNotifications()\params\window
  DeleteElement(wnNotifications())
  CompilerIf #wnDebug : Debug Str(ElapsedMilliseconds()) + ": destroyed notification " + Str(wnd) : CompilerEndIf
  PostEvent(#wnCleanup,wnd,0)
  If ListSize(wnNotifications())
    If cur < ListSize(wnNotifications())
      If cur > 0
        SelectElement(wnNotifications(),cur-1)
      ElseIf cur = 0
        SelectElement(wnNotifications(),0)
      EndIf
    EndIf
  EndIf
EndProcedure

Procedure wnDestroyAll(castFrom.i = #wnAll)
  Shared wnMutex,wnNotifications()
  LockMutex(wnMutex)
  ForEach wnNotifications()
    If castFrom = #wnAll Or wnNotifications()\params\castFrom = castFrom
      wnDestroyThis()
    EndIf
  Next
  ; very bad workaround to delete the last remaining element in the list
  If ListSize(wnNotifications())
    FirstElement(wnNotifications())
    If castFrom = #wnAll Or wnNotifications()\params\castFrom = castFrom
      wnDestroyThis()
    EndIf
  EndIf
  UnlockMutex(wnMutex)
EndProcedure

Procedure createNotificationImage(width.l,title.s,msg.s,frColor.l,bgColor.l,iconID.i,titleFontID.i,msgFontID.i)
  Protected image.i,height.l,textOffset.l,msgFontSize.l
  Protected NewList lines.s()
  msgFontSize = getFontSize(msgFontSize)
  image = CreateImage(#PB_Any,1,1)
  StartDrawing(ImageOutput(image))
  If msgFontID : DrawingFont(msgFontID) : EndIf
  wrapText(msg,width-20,lines())
  StopDrawing()
  FreeImage(image)
  height = 50 + ListSize(lines()) * msgFontSize
  image = CreateImage(#PB_Any,width,height,32,bgColor)
  StartDrawing(ImageOutput(image))
  BackColor(bgColor)
  FrontColor(frColor)
  If titleFontID : DrawingFont(titleFontID) : EndIf
  If iconID
    DrawAlphaImage(iconID,10,10)
    DrawText(42,12,title)
  Else
    DrawText(10,12,title)
  EndIf
  If msgFontID : DrawingFont(msgFontID) : EndIf
  ForEach lines()
    textOffset = 36 + ListIndex(lines()) * msgFontSize
    DrawText(10,textOffset,lines())
  Next
  StopDrawing()
  FreeList(lines())
  SaveImage(image,"test.bmp")
  ProcedureReturn image
EndProcedure

Procedure updateNotification(window.i,windowID.i,image.i,x.l = #wnIgnore,y.l = #wnIgnore,w.l = #wnIgnore,h.l = #wnIgnore,alpha.w = #wnIgnore,showWindow = #False)
  Protected size.SIZE,cn.POINT,pos.POINT,blend.BLENDFUNCTION
  Protected sSize.i,sPos.i,hDC.i
  If windowID <> WindowID(window) : ProcedureReturn : EndIf
  hDC = StartDrawing(ImageOutput(image))
  If x <> #wnIgnore And y <> #wnIgnore
    pos\x = x
    pos\y = y
    sPos = @pos
    CompilerIf #wnDebug : Debug Str(ElapsedMilliseconds()) + " setting pos of notification " + Str(window) + " to " + Str(pos\x) + "," + Str(pos\y) : CompilerEndIf
  Else
    sPos = 0
  EndIf
  If w <> #wnIgnore And h <> #wnIgnore
    size\cx = w
    size\cy = h
    sSize = @size
  Else
    sSize = 0
  EndIf
  If alpha <> #wnIgnore
    blend\SourceConstantAlpha = alpha
  Else
    blend\SourceConstantAlpha = 255
  EndIf
  blend\AlphaFormat = 1
  UpdateLayeredWindow_(windowID,0,sPos,sSize,hDC,@cn,0,@blend,2)
  StopDrawing()
  If showWindow
    HideWindow(window,#False,#PB_Window_NoActivate)
  EndIf
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

Procedure wrapText(text.s,width.l,List lines.s())
  Protected cut.l,limit.l
  Repeat
    If TextWidth(text) <= width
      AddElement(lines())
      lines() = text
      ProcedureReturn
    Else
      limit=0
      Repeat
        limit + 1
      Until TextWidth(Left(text,limit)) > width
      cut = limit
      Repeat
        cut - 1
      Until Mid(text,cut,1) = " " Or Mid(text,cut,1) = "-" Or cut = 0
      If cut = 0
        cut = limit-1
      EndIf
      AddElement(lines())
      lines() = Left(text,cut)
      text = Right(text,Len(text)-cut)
    EndIf
  ForEver
EndProcedure

Procedure getFontSize(fontID.i)
  Protected img.i = CreateImage(#PB_Any,1,1)
  Protected fontSize.l
  StartDrawing(ImageOutput(img))
  If fontID : DrawingFont(fontID) : EndIf
  fontSize = TextHeight("#A")
  StopDrawing()
  FreeImage(img)
  ProcedureReturn fontSize
EndProcedure

DisableExplicit
; IDE Options = PureBasic 5.31 (Windows - x86)
; EnableUnicode
; EnableThread
; EnableXP
; EnableBuildCount = 0