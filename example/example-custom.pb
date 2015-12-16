; pb-win-notify custom example

; in this example you'll learn how to create your own custom notification
; we will use a simple image, but it's up to you how you'll to create it
; you can check the createNotificationImage() from wn-proc.pbi to get an idea

IncludeFile "../wn.pbi"

UsePNGImageDecoder()

; this is a procedure created by netmaestro
; it helps to use PNG images in winapi
; for more info, see http://www.forums.purebasic.com/english/viewtopic.php?f=12&t=52884
Procedure PreMultiply(image)
  StartDrawing(ImageOutput(image))
    DrawingMode(#PB_2DDrawing_AllChannels)
    For j=0 To ImageHeight(image)-1
      For i=0 To ImageWidth(image)-1
        color = Point(i,j)
        Plot(i,j, RGBA(Red(color)   & $FF * Alpha(color) & $FF / $FF,
                       Green(color) & $FF * Alpha(color) & $FF / $FF,
                       Blue(color)  & $FF * Alpha(color) & $FF / $FF,
                       Alpha(color)))
      Next
    Next
  StopDrawing()
EndProcedure

; loading the image and premultiplying it
img = LoadImage(#PB_Any,"res\custom.png")
PreMultiply(img)

OpenWindow(0,#PB_Ignore,#PB_Ignore,200,50,"pb-win-notify",#PB_Window_SystemMenu|#PB_Window_ScreenCentered)
ButtonGadget(#PB_Any,10,10,180,30,"show notification")

wnInit()

Repeat
  ev = WaitWindowEvent()
  If ev = #wnCleanup : wnCleanup() : EndIf
  If ev = #PB_Event_Gadget
    ; the image will be freed with the notification itself, so for the sake of this example
    ; we will copy it every time
    wnImg = CopyImage(img,#PB_Any)
    *notification.wnNotification = AllocateMemory(SizeOf(wnNotification))
    With *notification
      ; we don't need message and title, since we are loading a custom image
      \params\image = wnImg
      \params\imageID = ImageID(wnImg)
      ; but we still need some basic params
      \params\timeout = #wnDefTimeout
      \params\castFrom = #wnLT
    EndWith
    wnNotifyStruct(*notification)
  EndIf
Until ev = #PB_Event_CloseWindow
; IDE Options = PureBasic 5.40 LTS (Windows - x86)
; Folding = -
; EnableUnicode
; EnableThread
; EnableXP