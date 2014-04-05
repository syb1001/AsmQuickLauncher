.386
.model flat, stdcall
option casemap:none

include Declaration.inc

.const
szMenuEditEnabled	db	'启用功能', 0
szMenuEditDisabled	db	'禁用功能', 0

.data
hMenu		dd		? ; handler of main menu

.code
ProcessMenuEvents PROC,
	evt

	.if evt == ID_MenuEdit
		invoke	DialogBoxParam, hInstance, IDD_EditDialog, hWinMain, offset _ProcDlgMain, NULL
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