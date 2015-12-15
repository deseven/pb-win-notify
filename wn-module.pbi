; pb-win-notify module

DeclareModule WN
  IncludeFile "wn.pbi"
  Macro Notify : WN::wnNotify : EndMacro
  Macro Init : WN::wnInit : EndMacro
  Macro NotifyStruct : WN::wnNotifyStruct : EndMacro
  Macro Cleanup : WN::wnCleanup : EndMacro
  Macro Destroy : WN::wnDestroy : EndMacro
  Macro DestroyAll : WN::wnDestroyAll : EndMacro
EndDeclareModule

Module WN
  IncludeFile "wn-proc.pbi"
EndModule