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
		local	@drawBottomLeft:DWORD, @drawBottomUp:DWORD, @notDrawBottom:DWORD, @drawBottomNum:DWORD, @seqOffset:DWORD

		invoke	CreateCompatibleDC, _hDc
		mov	@hDcBmp,eax
		invoke	CreateCompatibleDC, _hDc
		mov	@hDcDirection, eax
		invoke CreateCompatibleBitmap, _hDc, WINDOW_WIDTH, WINDOW_HEIGHT
		mov	@hBmpBack,eax
		invoke SelectObject, @hDcBmp, @hBmpBack
		invoke	ReleaseDC, hWinMain, @hDc
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
			invoke BitBlt, @hDcBmp, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcDirection, 0, 0, SRCCOPY
		.elseif	lastDirection == 3
			invoke	LoadBitmap, hInstance, IDB_LEFT
			mov @hBmpDirection, eax
			invoke SelectObject, @hDcDirection, @hBmpDirection
			invoke BitBlt, @hDcBmp, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcDirection, 0, 0, SRCCOPY
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
		.if seqLength > 2
			mov esi, 0
		.endif

		;显示所有手势
		.while ecx < seqLength
			.if seqLength > 10
				mov esi, 0
			.endif
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
						invoke	LoadBitmap, hInstance, IDB_BOTTOMUP
						mov @hBmpDirection, eax
						invoke SelectObject, @hDcDirection, @hBmpDirection
						invoke BitBlt, @hDcBmp, @drawBottomLeft, @drawBottomUp, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcDirection, 0, 0, SRCCOPY
					.elseif esi == 1
						invoke	LoadBitmap, hInstance, IDB_BOTTOMRIGHT
						mov @hBmpDirection, eax
						invoke SelectObject, @hDcDirection, @hBmpDirection
						invoke BitBlt, @hDcBmp, @drawBottomLeft, @drawBottomUp, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcDirection, 0, 0, SRCCOPY
					.elseif esi == 2
						invoke	LoadBitmap, hInstance, IDB_BOTTOMDOWN
						mov @hBmpDirection, eax
						invoke SelectObject, @hDcDirection, @hBmpDirection
						invoke BitBlt, @hDcBmp, @drawBottomLeft, @drawBottomUp, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcDirection, 0, 0, SRCCOPY
					.elseif	esi == 3
						invoke	LoadBitmap, hInstance, IDB_BOTTOMLEFT
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
						invoke	LoadBitmap, hInstance, IDB_BOTTOMUP
						mov @hBmpDirection, eax
						invoke SelectObject, @hDcDirection, @hBmpDirection
						invoke BitBlt, @hDcBmp, @drawBottomLeft, @drawBottomUp, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcDirection, 0, 0, SRCCOPY
					.elseif esi == 1
						invoke	LoadBitmap, hInstance, IDB_BOTTOMRIGHT
						mov @hBmpDirection, eax
						invoke SelectObject, @hDcDirection, @hBmpDirection
						invoke BitBlt, @hDcBmp, @drawBottomLeft, @drawBottomUp, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcDirection, 0, 0, SRCCOPY
					.elseif esi == 2
						invoke	LoadBitmap, hInstance, IDB_BOTTOMDOWN
						mov @hBmpDirection, eax
						invoke SelectObject, @hDcDirection, @hBmpDirection
						invoke BitBlt, @hDcBmp, @drawBottomLeft, @drawBottomUp, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcDirection, 0, 0, SRCCOPY
					.elseif	esi == 3
						invoke	LoadBitmap, hInstance, IDB_BOTTOMLEFT
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
				sub @drawBottomUp, esi

				
			.endif
		.endw

		popad




		invoke BitBlt, _hDc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, @hDcBmp, 0, 0, SRCCOPY

			
		
		invoke DeleteDC, @hDcBmp
		invoke DeleteDC, @hDcDirection
		invoke DeleteObject, @hBmpBack

		ret

CreateBitMap endp


END