.386
.model flat, stdcall
option casemap:none

;--------------Include---------------------
include Declaration.inc
;------------------------------------------

.const
;--------------Static String---------------
szClassName		db	'MyClass',0
szCaptionMain	db	'My first Window !',0
szText			db	'Win32 Assembly, Simple and powerful !',0

;--------------Local Path------------------
szOpen			db	'open',0
szPathExplorer	db	'explorer.exe',0
szPathNotepad	db	'notepad.exe',0
szPathText		db	'C:\\',0
;------------------------------------------

.data?
;--------------should be local vars?-------
hInstance		dd		?
hWinMain		dd		?
isLButtonDown	BYTE	0
isRButtonDown	BYTE	0
		
.code
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; 窗口过程
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_ProcWinMain	proc	uses ebx edi esi hWnd,uMsg,wParam,lParam
		local	@stPs:PAINTSTRUCT
		local	@stRect:RECT
		local	@hDc

		mov	eax,uMsg

;********************************************************************
		.if	eax ==	WM_PAINT
			invoke	BeginPaint,hWnd,addr @stPs
			mov	@hDc,eax

			invoke	GetClientRect,hWnd,addr @stRect
			invoke	DrawText,@hDc,addr szText,-1,\
				addr @stRect,\
				DT_SINGLELINE or DT_CENTER or DT_VCENTER

			invoke DrawLine, @hDc

			invoke	EndPaint,hWnd,addr @stPs
;********************************************************************
		.elseif	eax ==	WM_CLOSE
			invoke	DestroyWindow,hWinMain
			invoke	PostQuitMessage,NULL
;********************************************************************
		.elseif eax == WM_LBUTTONDOWN
			mov al, 1
			mov isLButtonDown, al

		.elseif eax == WM_LBUTTONUP
			mov edi, OFFSET trackPoint
			mov al, 0
			mov isLButtonDown, al

			invoke RecognizeTrack			; recognize the gesture
			invoke InitializeTrack			; clean the length

		.elseif eax == WM_MOUSEMOVE
			.if isLButtonDown == 1
				mov edi, OFFSET trackPoint
				mov ecx, trackLength
				imul ecx, SIZEOF POINT
				add edi, ecx
				movzx esi, WORD PTR lParam
				mov (POINT PTR [edi]).x, esi
				;mov @edPointx, esi
				movzx esi, WORD PTR [lParam + 2]
				mov (POINT PTR [edi]).y, esi
				;mov @edPointy, esi
				inc trackLength
				;.if trackLength > 1
				;	invoke BeginPaint, hWnd, addr @stPs
				;	mov @hDc, eax
				;	invoke CreatePen, PS_SOLID, 3, 0
				;	invoke SelectObject, @hDc, eax
				;	invoke DeleteObject, eax
				;	mov edi, OFFSET trackPoint
				;	mov ecx, trackLength
				;	sub ecx, 2
				;	imul ecx, SIZEOF POINT
				;	add edi, ecx
				;	mov esi, (POINT PTR [edi]).x
				;	mov @stPointx, esi
				;	mov esi, (POINT PTR [edi]).y
				;	mov @stPointy, esi
				;	invoke MoveToEx, @hDc, @stPointx, @stPointy, NULL
				;	invoke LineTo, @hDc, @edPointx, @edPointy
				;	invoke EndPaint, hWnd, addr @stPs
				;.endif
				.if trackLength == 1024
					mov al, 0
					mov isLButtonDown, al
				.endif 

			.endif
			invoke	InvalidateRect,hWnd,NULL,TRUE
		.else
			invoke	DefWindowProc,hWnd,uMsg,wParam,lParam
			ret
		.endif
;********************************************************************
		xor	eax,eax
		ret

_ProcWinMain	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_WinMain	proc
		local	@stWndClass:WNDCLASSEX
		local	@stMsg:MSG

		invoke	GetModuleHandle,NULL
		mov	hInstance,eax
		invoke	RtlZeroMemory,addr @stWndClass,sizeof @stWndClass
;********************************************************************
; 注册窗口类
;********************************************************************
		invoke	LoadCursor,0,IDC_ARROW
		mov	@stWndClass.hCursor,eax
		push	hInstance
		pop	@stWndClass.hInstance
		mov	@stWndClass.cbSize,sizeof WNDCLASSEX
		mov	@stWndClass.style,CS_HREDRAW or CS_VREDRAW
		mov	@stWndClass.lpfnWndProc,offset _ProcWinMain
		mov	@stWndClass.hbrBackground,COLOR_WINDOW + 1
		mov	@stWndClass.lpszClassName,offset szClassName
		invoke	RegisterClassEx,addr @stWndClass
;********************************************************************
; 建立并显示窗口
;********************************************************************
		invoke	CreateWindowEx,WS_EX_CLIENTEDGE,offset szClassName,offset szCaptionMain,\
			WS_OVERLAPPEDWINDOW,\
			100,100,600,400,\
			NULL,NULL,hInstance,NULL
		mov	hWinMain,eax
		invoke	ShowWindow,hWinMain,SW_SHOWNORMAL
		invoke	UpdateWindow,hWinMain
;********************************************************************
; 消息循环
;********************************************************************
		.while	TRUE
			invoke	GetMessage,addr @stMsg,NULL,0,0
			.break	.if eax	== 0
			invoke	TranslateMessage,addr @stMsg
			invoke	DispatchMessage,addr @stMsg
		.endw
		ret

_WinMain	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
start:
		call	_WinMain
		invoke	ExitProcess,NULL
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		end	start
