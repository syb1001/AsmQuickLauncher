.386
.model flat,stdcall
option casemap:none

include Declaration.inc

.data
;--------------Mouse Track------------------------------------------------
trackPoint POINT 1024 DUP(<>) 	; Mouse track Point
trackLength DWORD 0 				; number of mouse track points
trackSeq DWORD 1024 DUP(0)		; store track direction 
seqLength DWORD 0					; number of directions
;--------------------------------------------------------------------------

;--------------Action-------------------------------------------------------
actionMap ACTION 32 DUP(<>)
;--------------------------------------------------------------------------

.code

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

		INVOKE CalTan, edx, esi	; tan = tan(delY/delX)
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

RecognizeTrack PROC uses ecx edx esi edi ebx ; Judge the length before invoke
				LOCAL lastDirection : SDWORD
				LOCAL curSeq: DWORD 		 ; store current trasck sequence as DWORD format
; Get the array of directions 
	
	mov lastDirection, -1

	mov ecx, trackLength 		; get the number of points N
	dec ecx								; ecx = N - 1

	mov esi, OFFSET trackPoint			; point to the first array of trackPoint
	
	mov edi, OFFSET trackSeq				; point the the first array of trackSeq 

	mov edx, 0	  						; counter of trackSeq array 

	mov ebx, 0 							; counter of curSeq's digit bit, must be less than MAX_DIRECTIONS_PER_DWORD

	mov curSeq, 0
;---------------------------------------------------------------------------------------------------
L1:	
	
	INVOKE GetDirection, (POINT PTR [esi]).x, (POINT PTR [esi + SIZEOF POINT]).x, (POINT PTR [esi]).y,
	(POINT PTR [esi + SIZEOF POINT]).y

	add esi, SIZEOF POINT 							 ; point to the next trackPoint
	
	; record only if a new direction occurs 
	.IF lastDirection == -1 || eax != lastDirection
		
		mov lastDirection, eax

		push edx 
		mov eax, curSeq 			; curSeq = curSeq * 10 + current direction
		mov edx, curSeq
		shl eax, 3
		shl edx, 1
		add eax, edx 
		add eax, lastDirection
		mov curSeq, eax 
		pop edx 

		inc ebx   				

		.IF ebx == MAX_DIRECTIONS_PER_DWORD
			mov eax, curSeq
			mov [edi], eax 		; store curSeq in trackSeq
			add edi, SIZEOF DWORD
			inc edx 
			mov curSeq, 0 		; clear the sequence
			mov ebx, 0 			; clear the counter 

		.ENDIF	
	.ENDIF

	loop L1

	; add the last sequence 
	mov eax, curSeq
	mov [edi], eax 		; store curSeq in trackSeq
	inc edx 

;---------------------------------------------------------------------------------------------------

	mov seqLength, edx

	; Match a suitable gesture
	mov edi, OFFSET trackSeq				; point the the first array of trackSeq 

	.IF edx == 1 
		mov edx, [edi]

		.IF edx == 0			; go up
			;invoke ShellExecute, NULL, addr szOpen, addr szPathNotepad, NULL, NULL, SW_SHOW
			mov eax, 0
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

END