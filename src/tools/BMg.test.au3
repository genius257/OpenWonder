#include <GDIPlus.au3>
#include <WinAPICom.au3>
#include <GUIConstantsEx.au3>
#include <ListBoxConstants.au3>
#include <SendMessage.au3>
#include <Memory.au3>
#include <StaticConstants.au3>
#include <GuiListBox.au3>
#include "BMg.au3"

Opt("GuiOnEventMode" , 1)

Global $hFile = Null
Global $aEntries[0][3]

$hWnd = GUICreate("GMg inspector", 700, 320)
$iList = GUICtrlCreateList("", 0, 0, 100, 300)
GUICtrlSetOnEvent($iList, "ListChange")
$iGraphic = GUICtrlCreateGraphic(100, 0, 600, 300, $SS_BITMAP)
;$iGraphic = GUICtrlCreatePic(100, 0, 600, 300)
;$iGraphic = GUICtrlCreateLabel(100, 0, 600, 300)
;GUICtrlSetData($iList, "test|")
;GUICtrlSetData($iList, "test|")
$iMenu = GUICtrlCreateMenu("File")
GUICtrlCreateMenuItem("Open", $iMenu)
GUICtrlSetOnEvent(-1, "FileOpenDialogBGm")
GUISetOnEvent($GUI_EVENT_CLOSE, "MyExit", $hWnd)
GUISetState(@SW_SHOW, $hWnd)

_GDIPlus_Startup()
;$hGraphics = _GDIPlus_GraphicsCreateFromHWND(GUICtrlGetHandle($iGraphic))
;_GDIPlus_GraphicsClear($hGraphics)
;_GDIPlus_GraphicsDispose($hGraphics)

OnAutoItExitRegister("CleanUp")

While 1
    Sleep(10)
WEnd

Func MyExit()
    Exit
EndFunc

Func ListChange()
    ;GUICtrlRecvMsg()
    ;ConsoleWrite(GUICtrlSendMsg(GUICtrlGetHandle($iList), $LB_GETCOUNT, 0, 0)&@CRLF)
    $iIndex = _SendMessage(GUICtrlGetHandle($iList), $LB_GETCURSEL)
    _WinAPI_SetFilePointerEx($hFile, $aEntries[$iIndex][1], $FILE_BEGIN)
    Local $t = DllStructCreate(StringFormat("BYTE[%i]", $aEntries[$iIndex][2]))
    Local $iRead
    ;; _WinAPI_ReadFile($hFile, DllStructGetPtr($t), $aEntries[$iIndex][2], $iRead)
    ;ConsoleWrite(GUICtrlRead($iList, 1)&@CRLF)
    $hMemory = _MemGlobalAlloc($aEntries[$iIndex][2], $GMEM_MOVEABLE)
    $pMemory = _MemGlobalLock($hMemory)
    _WinAPI_ReadFile($hFile, $pMemory, $aEntries[$iIndex][2], $iRead)
    _MemGlobalUnlock($pMemory)
    $pIStream = _WinAPI_CreateStreamOnHGlobal($hMemory)
    $hBitmap = _GDIPlus_BitmapCreateFromStream($pIStream)
    _WinAPI_ReleaseStream($pIStream)
    ; _GDIPlus_ImageSaveToFile($hBitmap, @ScriptDir&"\"&$aEntries[$iIndex][0]);for debug
    ;ConsoleWrite(_GDIPlus_ImageGetWidth($hBitmap)&@CRLF)
    ;ConsoleWrite(_GDIPlus_ImageGetHeight($hBitmap)&@CRLF)
    ;$hHBITMAP = _GDIPlus_BitmapCreateDIBFromBitmap($hBitmap)
    $hHBITMAP = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hBitmap)
    _GDIPlus_BitmapDispose($hBitmap)
    Local Const $IMAGE_BITMAP = 0x0000
    ;GUICtrlSendMsg($iGraphic, $STM_SETIMAGE, $IMAGE_BITMAP, $hHBITMAP)
    _SendMessage(GUICtrlGetHandle($iGraphic), $STM_SETIMAGE, $IMAGE_BITMAP, $hHBITMAP)
    _WinAPI_DeleteObject($hHBITMAP)
    GUICtrlSetState($iGraphic, $GUI_SHOW)
EndFunc

Func FileOpenDialogBGm()
    Local $sFile = FileOpenDialog("Open File", "", "Bitmap archive (*.BMg)|JEPG archive (*.JMg)")
    If @error <> 0 Then Return MsgBox(0, @error, "")
    If Not ($hFile = Null) Then _BMg_Close($hFile)
    GUICtrlSetData($iList, "")
    _GUICtrlListBox_BeginUpdate(GUICtrlGetHandle($iList))
    $hFile = _BMg_Open($sFile)
    Local $t = DllStructCreate("USHORT")
    Local $iRead
    _WinAPI_ReadFile($hFile, DllStructGetPtr($t), 2, $iRead)
    Local $iFiles = DllStructGetData($t, 1)
    Redim $aEntries[$iFiles][UBound($aEntries, 2)]
    Local $iIndex = 0
    Local $pInfo = 0
    While $iFiles > 0
        $pInfo = _WinAPI_GetFilePointerEx($hFile) + 24
        $t = DllStructCreate("BYTE")
        _WinAPI_ReadFile($hFile, DllStructGetPtr($t), 1, $iRead)
        $iRead = DllStructGetData($t, 1)
        $t = DllStructCreate(StringFormat("CHAR[%i]", $iRead))
        _WinAPI_ReadFile($hFile, DllStructGetPtr($t), $iRead, $iRead)
        $aEntries[$iIndex][0] = DllStructGetData($t, 1)
        ; ConsoleWrite(DllStructGetData($t, 1)&@CRLF)
        _WinAPI_SetFilePointerEx($hFile, $pInfo, $FILE_BEGIN)
        $t = DllStructCreate("UINT")
        _WinAPI_ReadFile($hFile, DllStructGetPtr($t), 4, $iRead)
        $aEntries[$iIndex][1] = DllStructGetData($t, 1)
        _WinAPI_ReadFile($hFile, DllStructGetPtr($t), 4, $iRead)
        $aEntries[$iIndex][2] = DllStructGetData($t, 1)
        ; ConsoleWrite(Hex(DllStructGetData($t, 1), 8)&@CRLF)
        GUICtrlSetData($iList, $aEntries[$iIndex][0]&"|")
        $iIndex += 1
        $iFiles -= 1
    WEnd
    _GUICtrlListBox_EndUpdate(GUICtrlGetHandle($iList))
EndFunc

Func CleanUp()
    If Not ($hFile = Null) Then _BMg_Close($hFile)
    _GDIPlus_Shutdown()
EndFunc
