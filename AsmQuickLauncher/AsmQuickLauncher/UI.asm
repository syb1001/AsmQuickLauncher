.386
.model flat, stdcall
option casemap:none

include Declaration.inc

EnableMainFunction PROTO
DisableMainFunction PROTO
SetWindowFront PROTO
SetWindowNotFront PROTO
SetCapturingNew PROTO
SetNotCapturingNew PROTO

.const
szMenuEditEnabled	db	'启用功能', 0
szMenuEditDisabled	db	'禁用功能', 0

.data
hMenu				dd		? ; handler of main menu
;------------functional flags--------------
functionEnabled		db		TRUE
capturingNew		db		FALSE

.code
ProcessMenuEvents PROC,
	evt

	.if evt == ID_MenuEdit
		invoke	DialogBoxParam, hInstance, IDD_EditDialog, hWinMain, offset _ProcEditDlgMain, NULL
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
	.elseif	eax ==	ID_MenuWindowFront
		invoke	GetMenuState, hMenu, ID_MenuWindowFront, MF_BYCOMMAND
		.if		eax & MF_CHECKED
			invoke	SetWindowNotFront
		.else
			invoke	SetWindowFront
		.endif
	.elseif	eax ==	ID_MenuNewGesture
		invoke	GetMenuState, hMenu, ID_MenuNewGesture, MF_BYCOMMAND
		.if		eax & MF_CHECKED
			invoke	SetNotCapturingNew
		.else
			invoke	SetCapturingNew
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

SetWindowFront PROC
	invoke	CheckMenuItem, hMenu, ID_MenuWindowFront, MF_CHECKED
	invoke	SetWindowPos,hWinMain,HWND_TOPMOST,0,0,0,0,SWP_NOMOVE or SWP_NOSIZE
	ret
SetWindowFront ENDP

SetWindowNotFront PROC
	invoke	CheckMenuItem, hMenu, ID_MenuWindowFront, MF_UNCHECKED
	invoke	SetWindowPos,hWinMain,HWND_NOTOPMOST,0,0,0,0,SWP_NOMOVE or SWP_NOSIZE
	ret
SetWindowNotFront ENDP

SetCapturingNew PROC
	invoke	CheckMenuItem, hMenu, ID_MenuNewGesture, MF_CHECKED
	mov		capturingNew, TRUE
	ret
SetCapturingNew ENDP

SetNotCapturingNew PROC
	invoke	CheckMenuItem, hMenu, ID_MenuNewGesture, MF_UNCHECKED
	mov		capturingNew, FALSE
	ret
SetNotCapturingNew ENDP

END