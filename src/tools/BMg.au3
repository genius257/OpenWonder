#include <WinAPIFiles.au3>
#include <WinAPIHObj.au3>

Func _BMg_Open($sFile)
    Return _WinAPI_CreateFile($sFile, 2, 2, 2)
EndFunc

Func _BMg_Close($hFile)
    Return _WinAPI_CloseHandle($hFile)
EndFunc
