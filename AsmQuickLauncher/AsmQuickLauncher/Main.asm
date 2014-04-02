;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; FirstWindow.asm
; 窗口程序的模板代码
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; 使用 nmake 或下列命令进行编译和链接:
; ml /c /coff FirstWindow.asm
; Link /subsystem:windows FirstWindow.obj
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		.386
		.model flat,stdcall
		option casemap:none
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Include 文件定义
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

include		windows.inc
include		gdi32.inc
include		user32.inc
include		kernel32.inc

includelib	gdi32.lib
includelib	user32.lib
includelib	kernel32.lib

include shell32.inc			; ShellExecute
includelib shell32.lib

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;宏常量定义
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
IDR_Menu		equ		101
IDD_EditDialog	equ		103
ID_Edit			equ		40008
ID_Exit			equ		40007
ID_Enabled		equ		40009


;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; 数据段
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		.const
MAX_MOUSE_TRACK_LENGTH DWORD 1024

szClassName	db	'MyClass',0
szCaptionMain	db	'My first Window !',0
szText		db	'Win32 Assembly, Simple and powerful !',0

;--------------Local Path------------------
szOpen		db	'open',0
szPathExplorer	db	'explorer.exe',0
szPathNotepad	db	'notepad.exe',0
szPathText	db	'C:\\',0

		.data?
hInstance	dd		?
hWinMain	dd		?
hMenu		dd		?
isLButtonDown BYTE 0
isRButtonDown BYTE 0


;--------------Mouse Track-----------------
trackPoint POINT 1024 DUP(<>) 	; Mouse track Point
trackLength DWORD 0 								; number of mouse track points
trackSeq DWORD 1024 DUP(0)		; store track direction 
seqLength DWORD 0									; number of directions
;------------------------------------------



		
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; 代码段
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		.code
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; 窗口过程
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

CalTan PROC uses ebx edi,
	X : SDWORD,
	Y : SDWORD

	mov ebx, X
	.IF X < 0
		neg ebx
	.ENDIF

	mov edi, Y
	.IF Y < 0
		neg edi
	.ENDIF

	.IF edi > ebx
		mov eax, 1
	.ELSE
		mov eax, 0
	.ENDIF

	ret 

CalTan ENDP

GetDirection PROC uses edx esi edi,
	x0: SDWORD,
	x1: SDWORD,
	y0: SDWORD,
	y1: SDWORD
LOCAL delX : SDWORD, delY : SDWORD
 
	mov edx, x1
	sub edx, x0
	mov delX, edx

	mov esi, y0
	sub esi, y1
	mov delY, esi

	; return eax = 0(up), 1(right), 2(down), 3(left)	 
	.IF delX == 0       			; along Y-axis
		.IF delY >= 0
			mov eax, 0
		.ELSE 
			mov eax, 2
		.ENDIF
	
	.ELSEIF delX > 0				; in the right part
		
		INVOKE CalTan, edx, esi	; tan = tan(delY/delX)
		mov edi, eax				

		.IF delY == 0				; along Y-axis
			mov eax, 1
		.ELSEIF delY > 0			; quadrant I
			.IF edi > 0
				mov eax, 0
			.ELSE
				mov eax, 1
			.ENDIF
		.ELSEIF 					; quadrant IV
			.IF edi > 0
				mov eax, 2
			.ELSE
				mov eax, 1
			.ENDIF
		.ENDIF

	.ELSEIF 						; in the left part

		INVOKE CalTan, edx, esi	; tan = tan(delY/ddelX)
		mov edi, eax				

		.IF delY == 0				; along Y-axis
			mov eax, 3
		.ELSEIF delY > 0			; quadrant II
			.IF edi > 0
				mov eax, 0
			.ELSE
				mov eax, 3
			.ENDIF
		.ELSEIF 					; quadrant III
			.IF delY > 0
				mov eax, 2
			.ELSE
				mov eax, 3
			.ENDIF
		.ENDIF

	.ENDIF

	ret 

GetDirection ENDP


RecognizeTrack PROC uses ecx edx esi edi  ; Judge the length before invoke
				LOCAL lastDirection : SDWORD
; Get the array of directions 
	
	mov lastDirection, -1

	mov ecx, trackLength 		; get the number of points N
	dec ecx								; ecx = N - 1

	mov esi, OFFSET trackPoint			; point to the first array of trackPoint
	
	mov edi, OFFSET trackSeq				; point the the first array of trackSeq 

	mov edx, 0	  						; counter of trackSeq array 

L1:	
	
	INVOKE GetDirection, (POINT PTR [esi]).x, (POINT PTR [esi + SIZEOF POINT]).x, (POINT PTR [esi]).y,
	(POINT PTR [esi + SIZEOF POINT]).y

	add esi, SIZEOF POINT 							 ; point to the next trackPoint
	
	; record only if a new direction occurs 
	.IF lastDirection == -1 || eax != lastDirection
		mov [edi], eax 
		add edi, SIZEOF DWORD
		inc edx
		mov lastDirection, eax
	.ENDIF
	loop L1

	mov seqLength, edx

	; Match a suitable gesture
	mov edi, OFFSET trackSeq				; point the the first array of trackSeq 

	.IF edx == 1 
		mov edx, [edi]

		.IF edx == 0			; go up
			invoke ShellExecute, NULL, addr szOpen, addr szPathNotepad, NULL, NULL, SW_SHOW
		.ELSEIF edx == 1		; go down
			mov eax, 1
		.ELSEIF edx == 2		; go right 
 			mov eax, 2
		.ELSE 					; go left
			mov eax, 3
		.ENDIF

	.ENDIF

	ret

RecognizeTrack ENDP

InitializeTrack PROC

	mov trackLength, 0
	mov seqLength, 0

	ret
	
InitializeTrack EndP

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_ProcDlgMain	proc	uses ebx edi esi hWnd, wMsg, wParam, lParam
		

		mov		eax, wMsg
		.if eax == WM_CLOSE
			invoke	EndDialog, hWnd, NULL
		.endif
		ret
_ProcDlgMain	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


_ProcWinMain	proc	uses ebx edi esi hWnd,uMsg,wParam,lParam
		local	@stPs:PAINTSTRUCT
		local	@stRect:RECT
		local	@hDc

		mov	eax,uMsg

		.if	eax ==	WM_PAINT
			invoke	BeginPaint,hWnd,addr @stPs
			mov	@hDc,eax

			invoke	GetClientRect,hWnd,addr @stRect
			invoke	DrawText,@hDc,addr szText,-1,\
				addr @stRect,\
				DT_SINGLELINE or DT_CENTER or DT_VCENTER

			invoke	EndPaint,hWnd,addr @stPs
;********************************************************************
		.elseif	eax ==	WM_CLOSE
			invoke	DestroyWindow,hWinMain
			invoke	PostQuitMessage,NULL
;********************************************************************
		; 处理菜单事件
		.elseif eax == WM_COMMAND
			mov	eax, wParam
			movzx	eax, ax
			.if eax == ID_Edit
				invoke	DialogBoxParam, hInstance, IDD_EditDialog, hWnd, offset _ProcDlgMain, NULL
			.elseif eax == ID_Exit
				invoke	DestroyWindow,hWinMain
				invoke	PostQuitMessage,NULL
			.elseif eax == ID_Enabled
				invoke	MessageBox,hWinMain,addr szPathNotepad,addr szPathNotepad,MB_OK
			.endif
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
				movzx esi, WORD PTR [lParam + 2]
				mov (POINT PTR [edi]).y, esi
				inc trackLength

				;.if trackLength > MAX_MOUSE_TRACK_LENGTH
					; warning !
				;.endif 

			.endif
		.else
			invoke	DefWindowProc,hWnd,uMsg,wParam,lParam
			ret
		.endif
;********************************************************************
		xor	eax,eax
		ret

_ProcWinMain	endp
_WinMain	proc
		local	@stWndClass:WNDCLASSEX
		local	@stMsg:MSG

		invoke	GetModuleHandle,NULL
		mov	hInstance,eax
		; 读取菜单
		invoke	LoadMenu, hInstance, IDR_Menu
		mov		hMenu, eax

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
			NULL,hMenu,hInstance,NULL
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
