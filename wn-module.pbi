; pb-win-notify module

DeclareModule WN
  IncludeFile "wn.pbi"
  
  ; constants map
  #Debug = #wnDebug
  #FadeIn = #wnFadeIn
  #SlideIn = #wnSlideIn
  #FadeOut = #wnFadeOut
  #InAnimTime = #wnInAnimTime
  #OutAnimTime = #wnOutAnimTime
  #DefTimeout = #wnDefTimeout
  #DefBgColor = #wnDefBgColor
  #DefFrColor = #wnDefFrColor
  #Cleanup = #wnCleanup
  #Click = #wnClick
  #Close = #wnClose
  #ClickNone = #wnClickNone
  #ClickClose = #wnClickClose
  #ClickEvent = #wnClickClose
  #CloseNone = #wnCloseNone
  #CloseEvent = #wnCloseEvent
  #All = #wnAll
  #LT = #wnLT
  #LB = #wnLB
  #CT = #wnCT
  #CB = #wnCB
  #RT = #wnRT
  #RB = #wnRB
  #Custom = #wnCustom
  #Forever = #wnForever
  #Ignore_ = #wnIgnore
  
  Declare Init(wait.i = 10)
  Declare Notify(title.s,msg.s,castFrom.b = #LT,timeout.l = #DefTimeout,bgColor.l = #DefBgColor,frColor.l = #DefFrColor,titleFontID.i = 0,msgFontID.i = 0,iconID.i = 0,onClick.b = #ClickNone,onClickData.i = #Null,onClose.i = #CloseNone,onCloseData.i = #Null)
  Declare NotifyStruct(*notification.wnNotification)
  Declare Cleanup(wnd.i = 0)
  Declare Destroy(wnd.i)
  Declare DestroyAll(castFrom.i = #All)
EndDeclareModule

Module WN
  IncludeFile "wn-proc.pbi"
  
  ; procedures map
  Procedure Init(wait.i = 10)
    ProcedureReturn wnInit(wait)
  EndProcedure
  Procedure Notify(title.s,msg.s,castFrom.b = #LT,timeout.l = #DefTimeout,bgColor.l = #DefBgColor,frColor.l = #DefFrColor,titleFontID.i = 0,msgFontID.i = 0,iconID.i = 0,onClick.b = #ClickNone,onClickData.i = #Null,onClose.i = #CloseNone,onCloseData.i = #Null)
    ProcedureReturn wnNotify(title,msg,castFrom,timeout,bgColor,frColor,titleFontID,msgFontID,iconID,onClick,onClickData,onClose,onCloseData)
  EndProcedure
  Procedure NotifyStruct(*notification.wnNotification)
    ProcedureReturn wnNotifyStruct(*notification)
  EndProcedure
  Procedure Cleanup(wnd.i = 0)
    ProcedureReturn wnCleanup(wnd)
  EndProcedure
  Procedure Destroy(wnd.i)
    ProcedureReturn wnDestroy(wnd)
  EndProcedure
  Procedure DestroyAll(castFrom.i = #All)
    ProcedureReturn wnDestroyAll(castFrom)
  EndProcedure
EndModule
; IDE Options = PureBasic 5.40 LTS (Windows - x86)
; Folding = --
; EnableUnicode
; EnableXP