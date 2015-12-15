; pb-win-notify rev.12
; written by deseven
; thanks to poshu for contributions!
;
; https://github.com/deseven/pb-win-notify

; ### Notes:
; Threadsafe is REQUIRED if you plan to have more than one active notification.

; ### this is what you should call once before adding any notifications
; wnInit(
;  wait.i        - animation step in msec
; )

; ### that's what you should call to display your notification
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

; ### the same but you can pass a structure instead of the long line of params
; wnNotifyStruct(
;  *notification - wnNotification structure with params
; )

; ### destroy old notifications, you should call it every time you got #wnCleanup event
; wnCleanup(
;  wnd.i         - notification window
; )

; ### destroy notification
; wnDestroy(
;  wnd.i         - notification window
; )

; ### destroy all notifications
; wnDestroyAll(
;  castFrom.i    - notifications casted from specified location
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
  #wnAll
  #wnLT
  #wnLB
  #wnCT
  #wnCB
  #wnRT
  #wnRB
  #wnCustom
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
  expired.b
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
Define wnThread.i = 0
NewList wnNotifications.wnNotification()

Declare wnInit(wait.i = 10)
Declare wnNotify(title.s,msg.s,castFrom.b = #wnLT,timeout.l = #wnDefTimeout,bgColor.l = #wnDefBgColor,frColor.l = #wnDefFrColor,titleFontID.i = 0,msgFontID.i = 0,iconID.i = 0,onClick.b = #wnClickNone,onClickData.i = #Null,onClose.i = #wnCloseNone,onCloseData.i = #Null)
Declare wnNotifyStruct(*notification)
Declare wnCleanup(wnd.i = 0)
Declare wnDestroy(wnd.i)
Declare wnDestroyAll(castFrom.i = #wnAll)

; !BEWARE!
; the following procedures are INTERNAL
; you usually shouldn't use 'em

; (thread, internal) notifications processing
Declare wnProcess(wait.i)

; (thread, internal) helper function to actually add the notification without bothering the main thread
Declare wnAdd(*notification.wnNotification)

; (internal) destroy notification
Declare wnDestroyReal(wnd.i)

; (internal) destroy current notification
Declare wnDestroyThis()

; (internal) destroy all notifications
Declare wnDestroyAllReal(castFrom.i = #wnAll)

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

; (internal) check if the notification should be visible
Declare isVisible(*notification.wnNotification)

CompilerIf #PB_Compiler_Module = ""
  EnableExplicit
  IncludeFile "wn-proc.pbi"
  DisableExplicit
CompilerEndIf
; IDE Options = PureBasic 5.40 LTS (Windows - x86)
; Folding = -
; EnableUnicode
; EnableXP