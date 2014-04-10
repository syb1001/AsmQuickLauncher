.386
.model flat, stdcall
option casemap:none

include Declaration.inc

EnableMainFunction PROTO
DisableMainFunction PROTO


.const
szMenuEditEnabled	db	'启用功能', 0
szMenuEditDisabled	db	'禁用功能', 0

.data
hMenu				dd		? ; handler of main menu
functionEnabled		db		TRUE

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
			invoke	DisableMainFunction
		.else
			invoke	EnableMainFunction
		.endif
	.endif

	ret
ProcessMenuEvents ENDP

EnableMainFunction PROC
	invoke	CheckMenuItem, hMenu, ID_MenuEnable, MF_CHECKED
	mov		functionEnabled, TRUE
	;invoke	ModifyMenu,	hMenu, ID_MenuEnable, MF_CHECKED or MF_STRING, ID_MenuEnable, addr szMenuEditDisabled
	ret
EnableMainFunction ENDP

DisableMainFunction PROC
	invoke	CheckMenuItem, hMenu, ID_MenuEnable, MF_UNCHECKED
	mov		functionEnabled, FALSE
	;invoke	ModifyMenu,	hMenu, ID_MenuEnable, MF_UNCHECKED or MF_STRING, ID_MenuEnable, addr szMenuEditEnabled
	;invoke	ModifyMenu,	hMenu, ID_MenuEnable, MF_UNCHECKED, ID_MenuEnable, 0
	ret
DisableMainFunction ENDP

END