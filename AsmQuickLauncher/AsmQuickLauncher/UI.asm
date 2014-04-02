.386
.model flat, stdcall
option casemap:none

include Declaration.inc

.const
szPathNotepad	db	'notepad.exe',0

.data
hMenu		dd		? ; handler of main menu

.code
ProcessMenuEvents PROC,
	evt

	.if evt == ID_MenuEdit
		invoke	MessageBox, hWinMain, addr szPathNotepad, addr szPathNotepad,MB_OK
	.elseif evt == ID_MenuExit
		invoke	DestroyWindow, hWinMain
		invoke	PostQuitMessage, NULL
	.elseif evt == ID_MenuEnable
		invoke	MessageBox, hWinMain, addr szPathNotepad, addr szPathNotepad, MB_OK
	.endif

	ret
ProcessMenuEvents ENDP

END