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
SetStartupLaunch PROTO
SetNotStartupLaunch PROTO

.const
szMenuEditEnabled	db	'启用功能', 0
szMenuEditDisabled	db	'禁用功能', 0

.data
hMenu				dd		? ; handler of main menu
;------------functional flags--------------
functionEnabled		db		TRUE
capturingNew		db		FALSE

filePath BYTE 1024 DUP(?)
registerPath BYTE "Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Run", 0
registerName BYTE "WildCat", 0
registerDeleteName BYTE "Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Run\\WildCat", 0
registerQuery BYTE 1024 DUP(?)

registerOpenLimitedTitle	BYTE	"提示", 0
registerOpenLimitedText		BYTE	"请以管理员身份运行此程序", 0
registerWriteLimitedTitle	BYTE	"提示", 0
registerWriteLimitedText	BYTE	"请以管理员身份运行此程序", 0
registerDeleteLimitedTitle	BYTE	"提示", 0
registerDeleteLimitedText	BYTE	"请以管理员身份运行此程序", 0

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
	.elseif	evt ==	ID_MenuWindowFront
		invoke	GetMenuState, hMenu, ID_MenuWindowFront, MF_BYCOMMAND
		.if		eax & MF_CHECKED
			invoke	SetWindowNotFront
		.else
			invoke	SetWindowFront
		.endif
	.elseif	evt ==	ID_MenuNewGesture
		invoke	GetMenuState, hMenu, ID_MenuNewGesture, MF_BYCOMMAND
		.if		eax & MF_CHECKED
			invoke	SetNotCapturingNew
		.else
			invoke	SetCapturingNew
		.endif
	.elseif evt == ID_MenuAutoRun
		invoke	GetMenuState, hMenu, ID_MenuAutoRun, MF_BYCOMMAND
		.if		eax & MF_CHECKED
			invoke	SetNotStartupLaunch
		.else
			invoke	SetStartupLaunch
		.endif

	.elseif evt == ID_EXIT
		invoke Shell_NotifyIcon, NIM_DELETE, ADDR nid
		invoke	DestroyWindow,hWinMain
		invoke	PostQuitMessage,NULL
	.elseif evt == ID_SHOW
		invoke ShowWindow, hWinMain, SW_RESTORE
		invoke Shell_NotifyIcon, NIM_DELETE, ADDR nid
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

SetNotStartupLaunch PROC
		local	@hRegKey:HKEY

	invoke	RegOpenKeyEx, HKEY_LOCAL_MACHINE, ADDR registerPath, 0, KEY_WRITE, ADDR @hRegKey
	mov esi, eax
	.if	esi != 0
		invoke MessageBox, hWinMain, ADDR registerOpenLimitedText, ADDR registerOpenLimitedTitle, 0
		ret
	.endif
	invoke	RegDeleteValue, @hRegKey, ADDR registerName
	mov esi, eax
	.if	esi != 0
		invoke MessageBox, hWinMain, ADDR registerDeleteLimitedText, ADDR registerDeleteLimitedTitle, 0
		ret
	.endif
	invoke RegCloseKey, @hRegKey
	invoke	CheckMenuItem, hMenu, ID_MenuAutoRun, MF_UNCHECKED
	ret
SetNotStartupLaunch ENDP

SetStartupLaunch PROC
		local	@hRegKey:HKEY
	invoke	GetModuleFileName, 0, ADDR filePath, 1024
	invoke	RegOpenKeyEx, HKEY_LOCAL_MACHINE, ADDR registerPath, 0, KEY_ALL_ACCESS , ADDR @hRegKey
	mov esi, eax
	.if	esi != 0
		invoke MessageBox, hWinMain, ADDR registerOpenLimitedText, ADDR registerOpenLimitedTitle, 0
		ret
	.endif
	invoke	lstrlen, ADDR filePath
	mov esi, eax
	invoke	RegSetValueEx, @hRegKey, ADDR registerName, 0, REG_SZ, ADDR filePath, esi
	mov esi, eax
	.if	esi != 0
		invoke MessageBox, hWinMain, ADDR registerWriteLimitedText, ADDR registerWriteLimitedTitle, 0
		ret
	.endif
	invoke RegCloseKey, @hRegKey
	invoke	CheckMenuItem, hMenu, ID_MenuAutoRun, MF_CHECKED
	ret
SetStartupLaunch ENDP

initializeMenu PROC
		local	@hRegKey:HKEY, @hRegSize:DWORD
	invoke	RegOpenKeyEx, HKEY_LOCAL_MACHINE, ADDR registerPath, 0, KEY_ALL_ACCESS , ADDR @hRegKey
	mov @hRegSize, 4
	invoke	RegQueryValueEx, @hRegKey, ADDR registerName, 0, 0, ADDR registerQuery, ADDR @hRegSize
	mov esi, eax
	.if esi != 2
		invoke	CheckMenuItem, hMenu, ID_MenuAutoRun, MF_CHECKED
	.endif
	ret
initializeMenu ENDP

END