.386
.model flat, stdcall
option casemap:none

include Declaration.inc

.const
szMenuEditEnabled	db	'���ù���', 0
szMenuEditDisabled	db	'���ù���', 0

.data
hMenu		dd		? ; handler of main menu

.code
ProcessMenuEvents PROC,
	evt

	.if evt == ID_MenuEdit
		invoke	DialogBoxParam, hInstance, IDD_EditDialog, hWinMain, offset _ProcDlgMain, NULL
		; if editing succeed, return IDOK
		.if eax == IDOK
			;invoke MessageBox, hWinMain, offset szMenuEditEnabled, offset szMenuEditEnabled, MB_YESNO
			; return IDYES or IDNO
			; save the settings here
		.endif
	.elseif evt == ID_MenuExit
		invoke	DestroyWindow, hWinMain
		invoke	PostQuitMessage, NULL
	.elseif evt == ID_MenuEnable
		invoke	GetMenuState, hMenu, ID_MenuEnable, MF_BYCOMMAND
		.if		eax & MF_CHECKED
			;invoke	CheckMenuItem, hMenu, ID_MenuEnable, MF_UNCHECKED
			invoke	ModifyMenu,	hMenu, ID_MenuEnable, MF_UNCHECKED or MF_STRING, ID_MenuEnable, addr szMenuEditEnabled
		.else
			;invoke	CheckMenuItem, hMenu, ID_MenuEnable, MF_CHECKED
			invoke	ModifyMenu,	hMenu, ID_MenuEnable, MF_CHECKED or MF_STRING, ID_MenuEnable, addr szMenuEditDisabled
		.endif
	.endif

	ret
ProcessMenuEvents ENDP

END