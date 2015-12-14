; pb-win-notify module
; Original by deseven
; https://github.com/deseven/pb-win-notify
; http://deseven.info
;
; Fork by poshu
; https://github.com/poshu/pb-win-notify

; ### this is what you should call once before adding any notifications
; Init(
;  wait.i        - animation step in msec
; )

; ### that's what you should call to display your notification
; Notify(
;  title.s       - title of the notification
;  msg.s         - text of the notification
;  castFrom.b    - location of the notification, can be one of the following: #LT,#LB,#CT,#CB,#RT,#RB
;  timeout.l     - timeout in msec when the notification will be destroyed
;  bgColor.l     - background color
;  frColor.l     - front (text) color
;  titleFontID.i - FontID() of the desired title font
;  msgFontID.i   - FontID() of the desired message font
;  iconID.i      - ImageID() of the desired icon right before the title
;  onClick.b     - action to perform when you click on the notification, can be one of the following: #ClickNone,#ClickClose,#ClickEvent
;  onClickData.i - data which will be sent as EventData() (only if onClick = #ClickEvent)
;  onClose.b     - action to perform when notification is closing (by timeout or user action), can be #CloseNone or #CloseEvent
;  onCloseData.i - data which will be sent as EventData() (only if onClose = #CloseEvent)
; )

; ### the same but you can pass a structure instead of the long line of params
; NotifyStruct(
;  *notification - Notification structure with params
; )

; ### destroy old notifications, you should call it every time you got #Cleanup event
; Cleanup(
;  wnd.i         - notification window
; )

; ### destroy notification
; Destroy(
;  wnd.i         - notification window
; )

; ### destroy all notifications
; DestroyAll(
;  castFrom.i    - notifications casted from specified location
; )

; set that to true to check what's going on

DeclareModule WinNotify
	#Debug = #False
	
	; animations
	#FadeIn = #True
	#SlideIn = #True
	#FadeOut = #False
	
	; and animations' time
	#InAnimTime = 600
	#OutAnimTime = 800
	
	; defaults
	#DefTimeout = 3000
	#DefBgColor = $ffffff
	#DefFrColor = $000000
	
	EnableExplicit
	
	; +1000 to make sure that we won't interfere in some custom events
	Enumeration #PB_Event_FirstCustomValue + 1000
		#Cleanup
		#Click
		#Close
	EndEnumeration
	
	Enumeration wnClickActions
		#ClickNone
		#ClickClose
		#ClickEvent
	EndEnumeration
	
	Enumeration wnCloseActions
		#CloseNone
		#CloseEvent
	EndEnumeration
	
	Enumeration wnCastFrom
		#All
		#LT
		#LB
		#CT
		#CB
		#RT
		#RB
	EndEnumeration
	
	Structure NotificationParams
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
		castFrom.l
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
	
	Structure Notification
		active.i
		shown.b
		params.NotificationParams
		title.s
		msg.s
	EndStructure
	
	#Forever = -1
	
	Define wnMutex.i = CreateMutex()
	Define wnThread.i = 0
	NewList Notifications.Notification()
	
	Declare Init(wait.i = 10)
	Declare Notify(title.s,msg.s,castFrom.l = #LT,timeout.l = #DefTimeout,bgColor.l = #DefBgColor,frColor.l = #DefFrColor,titleFontID.i = 0,msgFontID.i = 0,iconID.i = 0,onClick.b = #ClickNone,onClickData.i = #Null,onClose.i = #CloseNone,onCloseData.i = #Null)
	Declare NotifyStruct(*notification)
	Declare Cleanup(wnd.i = 0)
	Declare Destroy(wnd.i)
	Declare DestroyAll(castFrom.i = #All)
	
EndDeclareModule

Module WinNotify
	
	; LoWord & HiWord used by custom placed notification
	Macro LoWord(value)
  	(value & $FFFF)
  EndMacro
  
  Macro HiWord(value)
  	(value >> 16 & $FFFF)
  EndMacro
	
	; (thread, internal) notifications processing
	Declare wnProcess(wait.i)
	
	; (thread, internal) helper function to actually add the notification without bothering the main thread
	Declare wnAdd(*notification.Notification)
	
	; (internal) destroy notification
	Declare DestroyReal(wnd.i)
	
	; (internal) destroy current notification
	Declare DestroyThis()
	
	; (internal) destroy all notifications
	Declare DestroyAllReal(castFrom.i = #All)
	
	; (internal) callback for our notifications
	Declare wnCallback(hWnd.i,msg.i,wParam.i,lParam.i)
	
	; (internal) processing actions for notification event
	Declare wnOnclick(hWnd.i)
	
	; (internal) recalc the remaining notifications positions
	Declare wnRecalc(noLock.i = #True)
	
	; (internal) creates notification image
	Declare createNotificationImage(width.l,title.s,msg.s,frColor.l,bgColor.l,iconID.i,titleFontID.i,msgFontID.i)
	
	; (internal) updates position, size and opacity of the notification
	Declare updateNotification(window.i,windowID.i,image.i,x.l = #PB_Ignore,y.l = #PB_Ignore,w.l = #PB_Ignore,h.l = #PB_Ignore,alpha.w = #PB_Ignore,showWindow = #False)
	
	; (internal) taken from pb forums, don't remember the exact topic
	Declare wnHideFromTaskBar(hWnd.i,flag.b)
	
	; (internal) wrap long text with lines
	Declare wrapText(text.s,width.l,List lines.s())
	
	; (internal) gets the font size in pixels
	Declare getFontSize(fontID.i)
	
	; (internal) check if the notification should be visible
	Declare isVisible(*notification.Notification)
	
	Procedure Notify(title.s,msg.s,castFrom.l = #LT,timeout.l = #DefTimeout,bgColor.l = #DefBgColor,frColor.l = #DefFrColor,titleFontID.i = 0,msgFontID.i = 0,iconID.i = 0,onClick.b = #ClickNone,onClickData.i = #Null,onClose.i = #CloseNone,onCloseData.i = #Null)
		Protected *notification.Notification = AllocateMemory(SizeOf(Notification))
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
		ProcedureReturn NotifyStruct(*notification)
	EndProcedure
	
	Procedure NotifyStruct(*notification.Notification)
		Protected rc.RECT,wnd.i
		*notification\params\window = OpenWindow(#PB_Any,#PB_Ignore,#PB_Ignore,320,100,"",#PB_Window_ScreenCentered|#PB_Window_BorderLess|#PB_Window_Invisible)
		If IsWindow(*notification\params\window)
			*notification\params\windowID = WindowID(*notification\params\window)
			SetWindowLongPtr_(*notification\params\windowID,#GWL_EXSTYLE,GetWindowLongPtr_(*notification\params\windowID,#GWL_EXSTYLE)|#WS_EX_LAYERED)
			wnHideFromTaskBar(*notification\params\windowID,#True)
			SetWindowCallback(@wnCallback(),*notification\params\window)
			StickyWindow(*notification\params\window,#True)
			wnd = *notification\params\window
			*notification\params\image = createNotificationImage(320,*notification\title,*notification\msg,*notification\params\frColor,*notification\params\bgColor,*notification\params\iconID,*notification\params\titleFontID,*notification\params\msgFontID)
			*notification\params\imageID = ImageID(*notification\params\image)
			*notification\params\h = ImageHeight(*notification\params\image)
			CreateThread(@wnAdd(),*notification)
			CompilerIf #Debug : Debug Str(ElapsedMilliseconds()) + ": adding notification" : CompilerEndIf
			ProcedureReturn wnd
		Else
			CompilerIf #Debug : Debug Str(ElapsedMilliseconds()) + ": failed to open new window!" : CompilerEndIf
		EndIf
	EndProcedure
	
	Procedure wnAdd(*notification.Notification)
		Shared wnMutex.i,Notifications()
		Protected rc.RECT
		SystemParametersInfo_(#SPI_GETWORKAREA,0,rc,0)
		Select *notification\params\castFrom
			Case #LT,#LB
				*notification\params\x = rc\left + 10
			Case #CT,#CB
				*notification\params\x = rc\right/2 - 320/2
			Case #RT,#RB
				*notification\params\x = rc\right - 320 - 10
			Default ; Casted from a custom position
				*notification\params\x = LoWord(*notification\params\castFrom)
		EndSelect
		LockMutex(wnMutex)
		AddElement(Notifications())
		Notifications()\msg = *notification\msg
		Notifications()\title = *notification\title
		Notifications()\params = *notification\params
		wnRecalc(#True)
		UnlockMutex(wnMutex)
		ClearStructure(*notification,Notification)
		FreeMemory(*notification)
	EndProcedure
	
	Procedure Init(wait.i = 10)
		Shared wnThread.i
		If Not IsThread(wnThread)
			ProcedureReturn CreateThread(@wnProcess(),wait)
		EndIf
	EndProcedure
	
	Procedure wnProcess(wait.i)
		Shared wnMutex.i,Notifications()
		Protected animX.w,animY.w,castFrom.b,height.w,timePassed.i,deltaMove.f,deltaAlpha.f
		Repeat
			LockMutex(wnMutex)
			ForEach Notifications()
				timePassed = ElapsedMilliseconds() - Notifications()\active
				If Not Notifications()\active
					If isVisible(@Notifications())
						updateNotification(Notifications()\params\window,Notifications()\params\windowID,Notifications()\params\image,-10000,-10000,320,Notifications()\params\h,255,#True)
						CompilerIf #Debug : Debug Str(ElapsedMilliseconds()) +  ": displaying notification in [" + Str(Notifications()\params\x) + "," + Str(Notifications()\params\y) + "]" : CompilerEndIf
						Notifications()\active = ElapsedMilliseconds()
					EndIf
				Else
					If timePassed <= #InAnimTime
						CompilerIf #Debug : Debug Str(ElapsedMilliseconds()) + ": anim display " + Str(timePassed) : CompilerEndIf
						If #SlideIn
							deltaMove = 330/#InAnimTime
							Select Notifications()\params\castFrom
								Case #LT,#LB
									deltaMove = (320 + Notifications()\params\x)/#InAnimTime
									animX = -320 + deltaMove*timePassed
									animY = Notifications()\params\y
								Case #CT,#CB
									animX = Notifications()\params\x
									animY = Notifications()\params\y
								Case #RT,#RB
									animX = Notifications()\params\x + 330 - deltaMove*timePassed
									animY = Notifications()\params\y
								Default ;Casted from a custom position
									animX = LoWord(Notifications()\params\castFrom)
									animY = hiWord(Notifications()\params\castFrom)
							EndSelect
						Else
							animX = Notifications()\params\x
							animY = Notifications()\params\y
						EndIf
						If #FadeIn : deltaAlpha = timePassed/#InAnimTime : Else : deltaAlpha = 1 : EndIf
						updateNotification(Notifications()\params\window,Notifications()\params\windowID,Notifications()\params\image,animX,animY,320,Notifications()\params\h,255 * deltaAlpha)
					ElseIf Not Notifications()\shown
						Notifications()\shown = #True
						updateNotification(Notifications()\params\window,Notifications()\params\windowID,Notifications()\params\image,Notifications()\params\x,Notifications()\params\y,320,Notifications()\params\h,255)
					ElseIf Notifications()\params\timeout <> #Forever
						If timePassed >= Notifications()\params\timeout + #OutAnimTime Or (timePassed >= Notifications()\params\timeout And Not #FadeOut)
							DestroyThis()
						ElseIf timePassed >= Notifications()\params\timeout
							deltaAlpha = Abs(Notifications()\params\timeout - timePassed)/#OutAnimTime*255
							updateNotification(Notifications()\params\window,Notifications()\params\windowID,Notifications()\params\image,#PB_Ignore,#PB_Ignore,320,Notifications()\params\h,255-deltaAlpha)
						EndIf
					EndIf
				EndIf
			Next
			UnlockMutex(wnMutex)
			Delay(wait)
		ForEver
	EndProcedure
	
	Procedure Cleanup(wnd.i = 0)
		If wnd = 0 : wnd = EventWindow() : EndIf
		If IsWindow(wnd) And wnd <> 0 : CloseWindow(wnd) : EndIf
		;CreateThread(@wnRecalc(),#False)
		CompilerIf #Debug : Debug Str(ElapsedMilliseconds()) + ": destroyed window " + Str(wnd) : CompilerEndIf
	EndProcedure
	
	Procedure wnCallback(hWnd.i,msg.i,wParam.i,lParam.i)
		If msg = #WM_LBUTTONUP
			CreateThread(@wnOnclick(),hWnd)
		EndIf
		ProcedureReturn #PB_ProcessPureBasicEvents
	EndProcedure
	
	Procedure wnOnclick(hWnd.i)
		Shared wnMutex.i,Notifications()
		Protected height.w,castFrom.b
		LockMutex(wnMutex)
		ForEach Notifications()
			If Notifications()\params\windowID = hWnd
				Select Notifications()\params\onClick
					Case #ClickClose
						DestroyThis()
					Case #ClickEvent
						PostEvent(#Click,Notifications()\params\window,#Null,#Null,Notifications()\params\onClickData)
				EndSelect
				Break
			EndIf
		Next
		UnlockMutex(wnMutex)
	EndProcedure
	
	Procedure wnRecalc(noLock.i = #True)
		Shared Notifications(),wnMutex.i
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
		ForEach Notifications()
			redraw = #False
			If Not Notifications()\params\expired
				Select Notifications()\params\castFrom
					Case #LT
						newY = osLT + 10
						If Notifications()\params\y <> newY
							Notifications()\params\y = newY
							redraw = #True
						EndIf
						osLT = newY + Notifications()\params\h
					Case #RT
						newY = osRT + 10
						If Notifications()\params\y <> newY
							Notifications()\params\y = newY
							redraw = #True
						EndIf
						osRT = newY + Notifications()\params\h
					Case #CT
						newY = osCT + 10
						If Notifications()\params\y <> newY
							Notifications()\params\y = newY
							redraw = #True
						EndIf
						osCT = newY + Notifications()\params\h
					Case #LB
						newY = osLB - Notifications()\params\h - 10
						If Notifications()\params\y <> newY
							Notifications()\params\y = newY
							redraw = #True
						EndIf
						osLB = newY
					Case #RB
						newY = osRB - Notifications()\params\h - 10
						If Notifications()\params\y <> newY
							Notifications()\params\y = newY
							redraw = #True
						EndIf
						osRB = newY
					Case #CB
						newY = osCB - Notifications()\params\h - 10
						If Notifications()\params\y <> newY
							Notifications()\params\y = newY
							redraw = #True
						EndIf
						osCB = newY
					Default
						newY = HiWord(Notifications()\params\castFrom)
						If Notifications()\params\y <> newY
							Notifications()\params\y = newY
							redraw = #True
						EndIf
						osCB = newY
				EndSelect
			EndIf
			If redraw
				If Notifications()\active
					updateNotification(Notifications()\params\window,Notifications()\params\windowID,Notifications()\params\image,Notifications()\params\x,Notifications()\params\y,320,Notifications()\params\h,255)
				Else
					updateNotification(Notifications()\params\window,Notifications()\params\windowID,Notifications()\params\image,Notifications()\params\x,Notifications()\params\y,-10000,-10000,255)
				EndIf  
				CompilerIf #Debug : Debug Str(ElapsedMilliseconds()) + ": recalc for notification " + Str(Notifications()\params\window) : CompilerEndIf
			EndIf
		Next
		If Not noLock : UnlockMutex(wnMutex) : EndIf
	EndProcedure
	
	Procedure Destroy(wnd.i)
		ProcedureReturn CreateThread(@DestroyReal(),wnd)
	EndProcedure
	
	Procedure DestroyReal(wnd.i)
		Shared wnMutex,Notifications()
		LockMutex(wnMutex)
		ForEach Notifications()
			If Notifications()\params\window = wnd
				DestroyThis()
			EndIf
		Next
		UnlockMutex(wnMutex)
	EndProcedure
	
	Procedure DestroyThis()
		Shared Notifications()
		Protected height.w,castFrom.b,cur.i,wnd.i
		cur = ListIndex(Notifications())
		height = Notifications()\params\h
		castFrom = Notifications()\params\castFrom
		If Notifications()\params\onClose = #CloseEvent
			PostEvent(#Close,Notifications()\params\window,0,0,Notifications()\params\onCloseData)
		EndIf
		wnd = Notifications()\params\window
		Notifications()\params\expired = #True
		wnRecalc()
		SelectElement(Notifications(),cur)
		FreeImage(Notifications()\params\image)
		DeleteElement(Notifications())
		CompilerIf #Debug : Debug Str(ElapsedMilliseconds()) + ": destroyed notification " + Str(wnd) : CompilerEndIf
		PostEvent(#Cleanup,wnd,0)
		If ListSize(Notifications())
			If cur < ListSize(Notifications())
				If cur > 0
					SelectElement(Notifications(),cur-1)
				ElseIf cur = 0
					SelectElement(Notifications(),0)
				EndIf
			EndIf
		EndIf
	EndProcedure
	
	Procedure DestroyAll(castFrom.i = #All)
		ProcedureReturn CreateThread(@DestroyAllReal(),castFrom)
	EndProcedure
	
	Procedure DestroyAllReal(castFrom.i = #All)
		Shared wnMutex,Notifications()
		LockMutex(wnMutex)
		ForEach Notifications()
			If castFrom = #All Or Notifications()\params\castFrom = castFrom
				DestroyThis()
			EndIf
		Next
		; very bad workaround to delete the last remaining element in the list
		If ListSize(Notifications())
			FirstElement(Notifications())
			If castFrom = #All Or Notifications()\params\castFrom = castFrom
				DestroyThis()
			EndIf
		EndIf
		UnlockMutex(wnMutex)
	EndProcedure
	
	Procedure createNotificationImage(width.l,title.s,msg.s,frColor.l,bgColor.l,iconID.i,titleFontID.i,msgFontID.i)
		Protected image.i,height.l,textOffset.l,msgFontSize.l
		Protected NewList lines.s()
		If Not Len(msg)
			height = 44
		Else
			msgFontSize = getFontSize(msgFontSize)
			image = CreateImage(#PB_Any,1,1)
			StartDrawing(ImageOutput(image))
			If msgFontID : DrawingFont(msgFontID) : EndIf
			wrapText(msg,width-20,lines())
			StopDrawing()
			FreeImage(image)
			height = 50 + ListSize(lines()) * msgFontSize
		EndIf
		image = CreateImage(#PB_Any,width,height,32,bgColor)
		StartDrawing(ImageOutput(image))
		BackColor(bgColor)
		FrontColor(frColor)
		If titleFontID : DrawingFont(titleFontID) : EndIf
		If iconID
			DrawingMode(#PB_2DDrawing_AlphaBlend)
			DrawImage(iconID,10,10)
			DrawingMode(#PB_2DDrawing_Default)
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
		ProcedureReturn image
	EndProcedure
	
	Procedure updateNotification(window.i,windowID.i,image.i,x.l = #PB_Ignore,y.l = #PB_Ignore,w.l = #PB_Ignore,h.l = #PB_Ignore,alpha.w = #PB_Ignore,showWindow = #False)
		Protected size.SIZE,cn.POINT,pos.POINT,blend.BLENDFUNCTION
		Protected sSize.i,sPos.i,hDC.i
		If windowID <> WindowID(window) : ProcedureReturn : EndIf
		hDC = StartDrawing(ImageOutput(image))
		If x <> #PB_Ignore And y <> #PB_Ignore
			pos\x = x
			pos\y = y
			sPos = @pos
			CompilerIf #Debug : Debug Str(ElapsedMilliseconds()) + " setting pos of notification " + Str(window) + " to " + Str(pos\x) + "," + Str(pos\y) : CompilerEndIf
		Else
			sPos = 0
		EndIf
		If w <> #PB_Ignore And h <> #PB_Ignore
			size\cx = w
			size\cy = h
			sSize = @size
		Else
			sSize = 0
		EndIf
		If alpha <> #PB_Ignore
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
	
	Procedure isVisible(*notification.Notification)
		Protected rc.RECT
		SystemParametersInfo_(#SPI_GETWORKAREA,0,rc,0)
		If *notification\params\x >= rc\left And *notification\params\x + 320 <= rc\right
			If *notification\params\y >= rc\top And *notification\params\y + *notification\params\h <= rc\bottom
				ProcedureReturn #True
			EndIf
		EndIf
		; we will return true for notification which exceeds the work area
		; otherwise it will never be shown
		If rc\right - rc\left < 320 Or rc\bottom - rc\top < *notification\params\h
			ProcedureReturn #True
		EndIf
		ProcedureReturn #False
	EndProcedure
	
	DisableExplicit
EndModule
; IDE Options = PureBasic 5.40 LTS (Windows - x64)
; CursorPosition = 459
; FirstLine = 387
; Folding = f4lZI9
; EnableUnicode
; EnableThread
; EnableXP
; EnableBuildCount = 0