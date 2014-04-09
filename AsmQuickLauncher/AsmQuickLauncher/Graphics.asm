.386
.model flat,stdcall
option casemap:none

include Declaration.inc
.data
lastPoint POINT <>

.code
DrawLine PROC uses ecx edi esi, _hDc
		local	@stPointx, @stPointy, @edPointx, @edPointy

		.if drawLength > 1
			invoke CreatePen, PS_SOLID, 3, 0
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

		invoke	CreateCompatibleDC, _hDc
		mov	@hDcBmp,eax
		invoke	CreateCompatibleDC, _hDc
		mov	@hDcDirection, eax
		invoke CreateCompatibleBitmap, _hDc, WINDOW_WIDTH, WINDOW_HEIGHT
		mov	@hBmpBack,eax
		invoke SelectObject, @hDcBmp, @hBmpBack
		;invoke	ReleaseDC, hWinMain, @hDc
		invoke BitBlt, @hDcBmp, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, _hDc, 0, 0, WHITENESS
		invoke DrawLine, @hDcBmp
		.if lastDirection == 0
			invoke	LoadBitmap, hInstance, IDB_UP
			mov @hBmpDirection, eax
			invoke SelectObject, @hDcDirection, @hBmpDirection
			invoke BitBlt, @hDcBmp, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcDirection, 0, 0, SRCCOPY
		.elseif lastDirection == 1
			invoke	LoadBitmap, hInstance, IDB_RIGHT
			mov @hBmpDirection, eax
			invoke SelectObject, @hDcDirection, @hBmpDirection
			invoke BitBlt, @hDcBmp, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcDirection, 0, 0, SRCCOPY
		.elseif lastDirection == 2
			invoke	LoadBitmap, hInstance, IDB_DOWN
			mov @hBmpDirection, eax
			invoke SelectObject, @hDcDirection, @hBmpDirection
			invoke BitBlt, @hDcBmp, 0, 0, WINDOW_WIDTH/4, WINDOW_HEIGHT/4, @hDcDirection, 0, 0, SRCCOPY
		.elseif	lastDirection == 3
			invoke	LoadBitmap, hInstance, IDB_LEFT
			mov @hBmpDirection, eax
			invoke SelectObject, @hDcDirection, @hBmpDirection
			invoke BitBlt, @hDcBmp, 0, 0, WINDOW_WIDTH/4, WINDOW_HEIGHT/4, @hDcDirection, 0, 0, SRCCOPY
		.endif
		invoke BitBlt, _hDc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcBmp, 0, 0, SRCCOPY

			
		
		invoke DeleteDC, @hDcBmp
		invoke DeleteDC, @hDcDirection
		invoke DeleteObject, @hDcBmp
		invoke DeleteObject, @hBmpBack

		ret

CreateBitMap endp


END