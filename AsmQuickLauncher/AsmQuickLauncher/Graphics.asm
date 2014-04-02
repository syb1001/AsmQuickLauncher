.386
.model flat,stdcall
option casemap:none

include Declaration.inc

.code
DrawLine PROC uses ecx edi esi, _hDc
		local	@stPointx, @stPointy, @edPointx, @edPointy

		.if trackLength > 1
			invoke CreatePen, PS_SOLID, 3, 0
			invoke SelectObject, _hDc, eax
			invoke DeleteObject, eax
			mov ecx, trackLength
			sub ecx, 1
		ShortLine:
			push ecx
			.if ecx >= 1
				mov edi, OFFSET trackPoint
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


END