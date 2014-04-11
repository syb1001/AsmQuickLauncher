.386
.model flat, stdcall
option casemap:none

;================Include===================
include Declaration.inc

.const
;=============Static String================
szClassName		db	'MyClass',0
szCaptionMain	db	'Asm Quick Launcher',0
szText			db	'Drag Your Mouse Here',0
szCaptionNew	db	'��������ƣ�', 0
szTextNew		db	'��ǰ���Ʋ�ƥ�䣬�Ƿ����Ϊ�µ����ƣ�', 0

.data
;================Variables=================
hInstance		dd		?
hWinMain		dd		?
isLButtonDown	BYTE	0
isRButtonDown	BYTE	0
WINDOW_WIDTH	DWORD	0
WINDOW_HEIGHT	DWORD	0
		
.code
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; ���ڹ���
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_ProcWinMain	proc	uses ebx edi esi hWnd,uMsg,wParam,lParam
		local	@stPs:PAINTSTRUCT
		local	@stRect:RECT
		local	@hDc
		local	@coord_x:DWORD, @coord_y:DWORD, @lastpoint_x:DWORD, @lastpoint_y:DWORD

		mov	eax,uMsg

;********************************************************************
		.if	eax ==	WM_PAINT
			invoke	BeginPaint,hWnd,addr @stPs
			;���´��ڸ߶ȺͿ�Ȳ���
			mov	@hDc,eax
			mov	ecx,@stPs.rcPaint.right
			sub	ecx,@stPs.rcPaint.left
			mov WINDOW_WIDTH, ecx
			mov	ecx,@stPs.rcPaint.bottom
			sub	ecx,@stPs.rcPaint.top
			mov WINDOW_HEIGHT, ecx
			invoke CreateBitMap, @hDc
			invoke	EndPaint,hWnd,addr @stPs
;********************************************************************
		.elseif	eax ==	WM_CREATE
			mov	eax,hWnd
			mov	hWinMain,eax
;********************************************************************
		.elseif	eax ==	WM_CLOSE
			invoke	DestroyWindow,hWinMain
			invoke	PostQuitMessage,NULL
			;invoke	
;********************************************************************
		.elseif eax == WM_COMMAND
			mov	eax, wParam
			movzx	eax, ax
			invoke	ProcessMenuEvents, eax
;********************************************************************
		.elseif eax == WM_LBUTTONDOWN
			.if	functionEnabled == FALSE
				ret
			.endif

			invoke LeftButtonDownProc, lParam
			
		.elseif eax == WM_LBUTTONUP
			.if	functionEnabled == FALSE
				ret
			.endif
			mov edi, OFFSET drawPoint
			mov al, 0
			mov isLButtonDown, al

			; call ShellExecute
			.if	bestMatch == -1
				.if	capturingNew == TRUE
					; open dialog to get new gesture info
					invoke	DialogBoxParam, hInstance, IDD_NewDialog, hWinMain, offset _ProcNewDlgMain, NULL
				.else
					; inquire whether to add new action
					invoke	MessageBox, hWnd, offset szTextNew, offset szCaptionNew, MB_YESNO
					.if	eax == IDYES
						; open dialog to get new gesture info
						invoke	DialogBoxParam, hInstance, IDD_NewDialog, hWinMain, offset _ProcNewDlgMain, NULL
					.endif
				.endif
			.else
				; execute the action
				invoke	ExecuteMatch, bestMatch
			.endif

			invoke InitializeTrack			;  clear all for new track 
			
			invoke	InvalidateRect,hWnd,NULL,1

		.elseif eax == WM_MOUSEMOVE
			.if	functionEnabled == FALSE
				ret
			.endif
			.if isLButtonDown == 1
				mov edi, OFFSET drawPoint
				mov ecx, drawLength
				imul ecx, SIZEOF POINT
				add edi, ecx
				movzx esi, WORD PTR lParam
				mov (POINT PTR [edi]).x, esi
				movzx esi, WORD PTR [lParam + 2]
				mov (POINT PTR [edi]).y, esi
				inc drawLength

				;�жϵ�ǰ�ĵ��ܷ���뵽�ж�����ĵ�����
				movzx esi, WORD PTR lParam
				mov @coord_x, esi
				movzx esi, WORD PTR [lParam + 2]
				mov @coord_y, esi
				mov edi, OFFSET lastPoint
				mov esi, (POINT PTR [edi]).x
				mov ebx, 0

				.if @coord_x > esi
					add ebx, @coord_x
					sub ebx, esi
				.else
					add ebx, esi
					sub ebx, @coord_x
				.endif

				mov esi, (POINT PTR [edi]).y
				.if @coord_y > esi
					add ebx, @coord_y
					sub ebx, esi
				.else
					add ebx, esi
					sub ebx, @coord_y
				.endif

				.if ebx > RECOGNIZE_DISTANCE
					;�����������Ч��
					mov esi, @coord_x
					mov (POINT PTR [edi]).x, esi
					mov esi, @coord_y
					mov (POINT PTR [edi]).y, esi

					;�����жϷ���ĵ���
					mov edi, OFFSET trackPoint
					mov ecx, trackLength
					imul ecx, SIZEOF POINT
					add edi, ecx
					movzx esi, WORD PTR lParam
					mov (POINT PTR [edi]).x, esi
					movzx esi, WORD PTR [lParam + 2]
					mov (POINT PTR [edi]).y, esi
					inc trackLength
					invoke RecognizeTrack
				.endif

				;invoke RecognizeTrack			; recognize the gesture

				.if drawLength == 1024
					mov al, 0
					mov isLButtonDown, al
				.endif 

				.if drawLength >20
					mov edi, OFFSET drawPoint
				.endif
				
				;mov esi, OFFSET trackSeq
				;.if seqLength>10
				;	mov esi, 0
				;.endif

			.endif
			invoke	InvalidateRect,hWnd,NULL,0
		.elseif eax == WM_SYSCOMMAND && wParam == SC_MINIMIZE
			invoke ToTray
		.elseif eax == WM_USER
			.if lParam == WM_LBUTTONDOWN
				invoke ShowWindow, hWinMain, SW_RESTORE
				invoke Shell_NotifyIcon, NIM_DELETE, ADDR nid
			.endif

			.if lParam == WM_RBUTTONDOWN

				invoke IconRightButtonDown

			.endif

			
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
		local	@windowLeft:DWORD, @windowTop:DWORD

		invoke ImportAcitons

		invoke	GetModuleHandle,NULL
		mov	hInstance,eax

		; load the main menu
		invoke	LoadMenu, hInstance, IDR_MainMenu
		mov		hMenu, eax
		invoke	initializeMenu
		invoke	LoadMenu, hInstance, IDR_IconMenu
		mov		hIconMenu, eax

		invoke	RtlZeroMemory,addr @stWndClass,sizeof @stWndClass
;********************************************************************
; ע�ᴰ����
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
; ��������ʾ����
;********************************************************************
		mov WINDOW_WIDTH, 400
		mov WINDOW_HEIGHT, 400
		invoke GetSystemMetrics, SM_CXSCREEN
		sub eax, WINDOW_WIDTH
		mov edx, 0
		mov esi, 2
		div esi
		mov @windowLeft, eax

		invoke GetSystemMetrics, SM_CYSCREEN
		sub eax, WINDOW_HEIGHT
		mov edx, 0
		mov esi, 2
		div esi
		mov @windowTop, eax

		invoke	CreateWindowEx,WS_EX_CLIENTEDGE,offset szClassName,offset szCaptionMain,\
			WS_OVERLAPPEDWINDOW,\
			@windowLeft,@windowTop,WINDOW_WIDTH,WINDOW_HEIGHT,\
			NULL,hMenu,hInstance,NULL
		mov	hWinMain,eax
		invoke	ShowWindow,hWinMain,SW_SHOWNORMAL
		invoke	UpdateWindow,hWinMain
;********************************************************************
; ��Ϣѭ��
;********************************************************************
		.while	TRUE
			invoke	GetMessage,addr @stMsg,NULL,0,0
			.break	.if eax	== 0
			invoke	TranslateMessage,addr @stMsg
			invoke	DispatchMessage,addr @stMsg
		.endw

		invoke ExportActions

		ret

_WinMain	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
start:
		call	_WinMain
		invoke	ExitProcess,NULL
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		end	start
