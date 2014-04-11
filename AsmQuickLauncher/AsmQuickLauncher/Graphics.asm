.386
.model flat,stdcall
option casemap:none

include Declaration.inc
.data
lastPoint POINT <>
nid NOTIFYICONDATA <>
iconText BYTE "哈哈", 0
iconMenuClose BYTE "退出", 0
iconMenuOpen BYTE "显示", 0
topTextFont BYTE "微软雅黑", 0

testCounter	DWORD 0
hIconMenu DWORD 0

upBitmap DWORD ?
downBitmap DWORD ?
leftBitmap DWORD ?
rightBitmap DWORD ?

bottomUpBitmap DWORD ?
bottomDownBitmap DWORD ?
bottomLeftBitmap DWORD ?
bottomRightBitmap DWORD ?


trackTooLong DWORD 0

.code

LoadIconBitmap PROC
	
	invoke	LoadBitmap, hInstance, IDB_BOTTOMUP
	MOV bottomUpBitmap, eax 

	invoke	LoadBitmap, hInstance, IDB_BOTTOMDOWN
	MOV bottomDownBitmap, eax 

	invoke	LoadBitmap, hInstance, IDB_BOTTOMRIGHT
	MOV bottomRightBitmap, eax 

	invoke	LoadBitmap, hInstance, IDB_BOTTOMLEFT
	MOV bottomLeftBitmap, eax 

	invoke	LoadBitmap, hInstance, IDB_UP
	mov upBitmap, eax

	invoke	LoadBitmap, hInstance, IDB_DOWN
	mov downBitmap, eax 

	invoke	LoadBitmap, hInstance, IDB_LEFT
	mov leftBitmap, eax

	invoke	LoadBitmap, hInstance, IDB_RIGHT
	mov rightBitmap, eax 

	ret 
LoadIconBitmap ENDP 

DrawLine PROC uses ecx edi esi, _hDc
		local	@stPointx, @stPointy, @edPointx, @edPointy

	.if drawLength > 1
		invoke CreatePen, PS_SOLID, 2, 0e16941h
		invoke SelectObject, _hDc, eax
		invoke DeleteObject, eax
		mov ecx, drawLength
		sub ecx, 1
	ShortLine:
		push ecx
		.if ecx >= 1
			mov edi, OFFSET drawPoint
			mov esi, ecx
			imul esi, SIZEOF POINT
			add edi, esi
			mov esi, (POINT PTR [edi]).x
			mov @stPointx, esi
			mov esi, (POINT PTR [edi]).y
			mov @stPointy, esi
			sub edi, SIZEOF POINT
			mov esi, (POINT PTR [edi]).x
			mov @edPointx, esi
			mov esi, (POINT PTR [edi]).y
			mov @edPointy, esi
			invoke MoveToEx, _hDc, @stPointx, @stPointy, NULL
			invoke LineTo, _hDc, @edPointx, @edPointy
		.endif
		pop ecx
		loop ShortLine
	.endif
	ret

DrawLine EndP

CreateBitMap PROC, _hDc
		local	@hDc
		local	@hBmpBack:DWORD, @hDcBmp:DWORD, @hDcDirection:DWORD, @hBmpDirection:DWORD
		local	@drawBottomLeft:DWORD, @drawBottomUp:DWORD, @notDrawBottom:DWORD, @drawBottomNum:DWORD, @seqOffset:DWORD
		local	@middleArrowLeft:DWORD, @middleArrowTop:DWORD
		local	@textMiddlePos:DWORD
		local	@topTextAddr:DWORD, @topTextLen:DWORD

	invoke	CreateCompatibleDC, _hDc
	mov	@hDcBmp,eax
	invoke	CreateCompatibleDC, _hDc
	mov	@hDcDirection, eax
	invoke CreateCompatibleBitmap, _hDc, WINDOW_WIDTH, WINDOW_HEIGHT
	mov	@hBmpBack, eax
	invoke SelectObject, @hDcBmp, @hBmpBack
	invoke DeleteObject, @hBmpBack
	invoke BitBlt, @hDcBmp, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, _hDc, 0, 0, WHITENESS


	;在屏幕中心画出当前方向
	mov eax, WINDOW_WIDTH
	sub eax, BMP_CENTER_SIZE
	mov edx, 0
	mov esi, 2
	div esi
	mov @middleArrowLeft, eax

	mov eax, WINDOW_HEIGHT
	sub eax, BMP_CENTER_SIZE
	mov edx, 0
	mov esi, 2
	div esi
	mov @middleArrowTop, eax

	.if lastDirection == 0
		mov eax, upBitmap
		mov @hBmpDirection, eax
		invoke SelectObject, @hDcDirection, @hBmpDirection
		invoke BitBlt, @hDcBmp, @middleArrowLeft, @middleArrowTop, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcDirection, 0, 0, SRCCOPY
	.elseif lastDirection == 1
		mov eax, rightBitmap
		mov @hBmpDirection, eax
		invoke SelectObject, @hDcDirection, @hBmpDirection
		invoke BitBlt, @hDcBmp, @middleArrowLeft, @middleArrowTop, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcDirection, 0, 0, SRCCOPY
	.elseif lastDirection == 2
		mov eax, downBitmap
		mov @hBmpDirection, eax
		invoke SelectObject, @hDcDirection, @hBmpDirection
		invoke BitBlt, @hDcBmp, @middleArrowLeft, @middleArrowTop, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcDirection, 0, 0, SRCCOPY
	.elseif	lastDirection == 3
		mov eax, leftBitmap
		mov @hBmpDirection, eax
		invoke SelectObject, @hDcDirection, @hBmpDirection
		invoke BitBlt, @hDcBmp, @middleArrowLeft, @middleArrowTop, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcDirection, 0, 0, SRCCOPY
	.endif

	pushad

	mov ecx, 0
	mov edx, 0
	mov eax, WINDOW_WIDTH
	mov esi, BMP_BOTTOM_SIZE 
	div esi

	mov @drawBottomNum, eax 
		
	;mov eax, edx
	;mov edx, 0
	;mov esi, 2
	;div esi
	;mov @drawBottomLeft, eax
	mov esi, WINDOW_HEIGHT
	mov @drawBottomUp, esi
	sub @drawBottomUp, BMP_BOTTOM_SIZE
	;mov edi, OFFSET trackSeq
	;mov @seqOffset, edi
	mov ebx, OFFSET trackSeq

	;显示所有手势
	.while ecx < seqLength
		mov edi, seqLength
		sub edi, ecx

		;每次显示一排
		.if edi < @drawBottomNum
			mov esi, BMP_BOTTOM_SIZE
			imul esi, edi
			mov eax, WINDOW_WIDTH
			sub eax, esi
			mov edx, 0
			mov esi, 2
			div esi
			mov @drawBottomLeft, eax
			.while ecx < seqLength

				mov esi, [ebx]
				push ecx
				.if esi == 0
					mov eax, bottomUpBitmap
					mov @hBmpDirection, eax
					invoke SelectObject, @hDcDirection, @hBmpDirection
					invoke BitBlt, @hDcBmp, @drawBottomLeft, @drawBottomUp, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcDirection, 0, 0, SRCCOPY
				.elseif esi == 1
					mov eax, bottomRightBitmap
					mov @hBmpDirection, eax
					invoke SelectObject, @hDcDirection, @hBmpDirection
					invoke BitBlt, @hDcBmp, @drawBottomLeft, @drawBottomUp, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcDirection, 0, 0, SRCCOPY
				.elseif esi == 2
					mov eax, bottomDownBitmap
					mov @hBmpDirection, eax
					invoke SelectObject, @hDcDirection, @hBmpDirection
					invoke BitBlt, @hDcBmp, @drawBottomLeft, @drawBottomUp, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcDirection, 0, 0, SRCCOPY
				.elseif	esi == 3
					mov eax, bottomLeftBitmap
					mov @hBmpDirection, eax
					invoke SelectObject, @hDcDirection, @hBmpDirection
					invoke BitBlt, @hDcBmp, @drawBottomLeft, @drawBottomUp, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcDirection, 0, 0, SRCCOPY
				.endif
				pop ecx

				add ebx, SIZEOF DWORD
				inc ecx
				mov esi, @drawBottomLeft
				add esi, BMP_BOTTOM_SIZE
				mov @drawBottomLeft, esi
			.endw
		.else
			mov edx, 0
			mov eax, WINDOW_WIDTH
			mov esi, BMP_BOTTOM_SIZE 
			div esi
			mov @drawBottomNum, eax 
			mov eax, edx
			mov edx, 0
			mov esi, 2
			div esi
			mov @drawBottomLeft, eax

			push ecx
			mov ecx, 0
			.while ecx < @drawBottomNum
				mov esi, [ebx]
				push ecx
				.if esi == 0
					mov eax, bottomUpBitmap
					mov @hBmpDirection, eax
					invoke SelectObject, @hDcDirection, @hBmpDirection
					invoke BitBlt, @hDcBmp, @drawBottomLeft, @drawBottomUp, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcDirection, 0, 0, SRCCOPY
				.elseif esi == 1
					mov eax, bottomRightBitmap
					mov @hBmpDirection, eax
					invoke SelectObject, @hDcDirection, @hBmpDirection
					invoke BitBlt, @hDcBmp, @drawBottomLeft, @drawBottomUp, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcDirection, 0, 0, SRCCOPY
				.elseif esi == 2
					mov eax, bottomDownBitmap
					mov @hBmpDirection, eax
					invoke SelectObject, @hDcDirection, @hBmpDirection
					invoke BitBlt, @hDcBmp, @drawBottomLeft, @drawBottomUp, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcDirection, 0, 0, SRCCOPY
				.elseif	esi == 3
					mov eax, bottomLeftBitmap
					mov @hBmpDirection, eax
					invoke SelectObject, @hDcDirection, @hBmpDirection
					invoke BitBlt, @hDcBmp, @drawBottomLeft, @drawBottomUp, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcDirection, 0, 0, SRCCOPY
				.endif
				pop ecx

				add ebx, SIZEOF DWORD
				inc ecx
				mov esi, @drawBottomLeft
				add esi, BMP_BOTTOM_SIZE
				mov @drawBottomLeft, esi
			.endw
			pop ecx
			add ecx, @drawBottomNum
				
			mov esi, BMP_BOTTOM_SIZE
			.if @drawBottomUp <= esi
					mov eax, 1
					mov trackTooLong, eax 
					ret 
			.endif 
			sub @drawBottomUp, esi

				
		.endif
	.endw

	popad

	;在上方显示提示文字
	invoke GetTipOfBestMatch
	mov @topTextAddr, eax
	mov ebx, eax
	invoke lstrlen, ebx
	mov @topTextLen, eax
	.if @topTextLen > 0
		invoke SetTextAlign, @hDcBmp, TA_CENTER
		mov eax, WINDOW_WIDTH
		mov edx, 0
		mov edi, 2
		div edi
		mov @textMiddlePos, eax
		invoke CreateFont, 24, 0, 0, 0, FW_BOLD, 0, 0, 0, DEFAULT_CHARSET, 0, 0, 0, 0, ADDR topTextFont
		invoke SelectObject, @hDcBmp, eax
		invoke DeleteObject, eax
		invoke TextOut, @hDcBmp, @textMiddlePos, 0, @topTextAddr, @topTextLen
	.endif 
	invoke DrawLine, @hDcBmp

	invoke BitBlt, _hDc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcBmp, 0, 0, SRCCOPY

	invoke DeleteDC, @hDcBmp
	invoke DeleteDC, @hDcDirection
	ret

CreateBitMap endp

ToTray proc
		invoke RtlZeroMemory, ADDR nid, SIZEOF nid

	mov nid.cbSize, SIZEOF NOTIFYICONDATA
	mov esi, hWinMain
	mov nid.hwnd, esi
	;mov nid.uID, ICON_NOT
	mov nid.uFlags, NIF_ICON or NIF_MESSAGE or NIF_TIP
	invoke LoadIcon, hInstance, IDI_TRAY
	mov nid.hIcon, eax
	mov nid.uCallbackMessage, WM_USER
	invoke lstrcpy, ADDR nid.szTip, ADDR iconText
	invoke ShowWindow, hWinMain, SW_HIDE
	invoke Shell_NotifyIcon, NIM_ADD, ADDR nid
	
	ret
ToTray endp

IconRightButtonDown proc
		local	@hPopupMenu:DWORD
		local	@stPos:POINT

	invoke	GetSubMenu,hIconMenu, 0
	mov	@hPopupMenu, eax
	invoke GetCursorPos, ADDR @stPos
	invoke	TrackPopupMenu, @hPopupMenu, TPM_LEFTALIGN,@stPos.x,@stPos.y,0 ,hWinMain,NULL

	ret

IconRightButtonDown endp

LeftButtonDownProc proc, lParam

	;给判断方向的点列赋初始值
	mov edi, OFFSET trackPoint
	movzx esi, WORD PTR lParam
	mov (POINT PTR [edi]).x, esi
	movzx esi, WORD PTR [lParam + 2]
	mov (POINT PTR [edi]).y, esi
	mov trackLength, 1
	mov isLButtonDown, 1

	;给当前的点赋初始值
	mov edi, OFFSET lastPoint
	movzx esi, WORD PTR lParam
	mov (POINT PTR [edi]).x, esi
	movzx esi, WORD PTR [lParam + 2]
	mov (POINT PTR [edi]).y, esi

	;给画线轨迹的点列赋初始值
	mov edi, OFFSET drawPoint
	movzx esi, WORD PTR lParam
	mov (POINT PTR [edi]).x, esi
	movzx esi, WORD PTR [lParam + 2]
	mov (POINT PTR [edi]).y, esi
	mov drawLength, 1

	ret

LeftButtonDownProc endp

END