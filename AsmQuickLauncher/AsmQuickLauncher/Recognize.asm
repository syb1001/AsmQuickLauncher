
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
train DWORD 0
;--------------Action-------------------------------------------------------
actionMap ACTION 32 DUP(<>)
actionLen DWORD 0
;--------------------------------------------------------------------------

;--------------train----------------
trainSeq DWORD 1024 DUP(0)
trainLength DWORD 0

;----------DEBUG-------
tmpStr BYTE 1024 DUP(0)
tmpStr2 BYTE 1024 DUP(0)

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
	
	INVOKE GetDirection, (POINT PTR [esi]).x, (POINT PTR [esi + TYPE POINT]).x, (POINT PTR [esi]).y,
	(POINT PTR [esi + TYPE POINT]).y

	add esi, TYPE POINT 							 ; point to the next trackPoint
	
	; Wait til a new direction occurs 
	.IF lastDirection == -1 || eax != lastDirection
		
		mov lastDirection, eax		; record the new direction 

		comment *
		push edx 
		mov eax, curSeq 			
		mov edx, curSeq
		shl eax, 3
		shl edx, 1
		add eax, edx 
		add eax, lastDirection
		mov curSeq, eax 
		pop edx 

		mov eax, curSeq 			; curSeq = curSeq << 2 + current direction
		shl eax, 2
		or eax, lastDirection
		mov curSeq, eax 

		inc ebx   				

		.IF ebx == MAX_DIRECTIONS_PER_DWORD
			mov eax, curSeq
			mov [edi], eax 		; store curSeq in trackSeq
			add edi, TYPE DWORD
			inc edx 
			mov curSeq, 0 		; clear the sequence
			mov ebx, 0 			; clear the counter 

		.ENDIF	
		*

		mov [edi], eax 		; store curSeq in trackSeq
		add edi, TYPE DWORD
		inc edx 

		; to insert a trigger here 

	.ENDIF

	loop L1

	comment *
	; add the last sequence 
	mov eax, curSeq
	mov [edi], eax 		; store curSeq in trackSeq
	inc edx 
	*

	mov seqLength, edx 	; update the length of trackSeq

	; to Match

	ret

RecognizeTrack ENDP

Match PROC uses ebx edx ecx edi esi  
; Match a suitable gesture
	
	mov ecx, actionLen 			; use length of actionMap as the loop counter 
	mov esi, OFFSET actionMap	; point the the first array of actionMap 
	mov eax, 0					; counter 

EnumLoop:

	push ecx  			; save the counter of outer loop 

	mov ecx, (ACTION PTR [esi]).len 	; use the length of each ACTION as the loop counter 
	lea edi, (ACTION PTR [esi]).seq 	; point to the first array of seq of each ACTION

	mov ebx, OFFSET trackSeq	; point the the first array of trackSeq

	CompareLoop:
		mov edx, [edi]
		cmp edx, [ebx]
		jne MisMatching

		add edi, TYPE DWORD 	; point to the next element of ACTION.seq 
		add ebx, TYPE DWORD 	; point to the next element of trackSeq

	loop CompareLoop

	jmp Hit

MisMatching:
	
	pop ecx 			; recover the counter of outer loop 

	add esi, TYPE ACTION ; point to the next ACTION of actionMap
	inc eax 				; counter +1 

	loop EnumLoop 

NotHhit:
	mov eax, -1
	jmp rtn_Match

Hit:
	
rtn_Match:	
	ret 
Match ENDP


AddNewAction PROC uses ebx esi edi edx,
	seq: PTR DWORD,
	len: DWORD
LOCAL tmpAdd:DWORD

	mov ebx, OFFSET actionMap 	; point to the first element of actionMap
	mov esi, actionLen			
	mov eax, TYPE ACTION
	mul esi  
	lea edi, [ebx + eax]		; point to the len-th element of actionMap to insert a new ACTION
	
	mov ecx, len 
	mov (ACTION PTR [edi]).len, ecx

	lea esi, (ACTION PTR [edi]).seq 
	mov tmpAdd, esi

	mov edi, seq 				; point to the first element of seq 
@@:
	mov eax, [edi]
	mov [esi], eax

	add esi, TYPE DWORD
	add edi, TYPE DWORD
	loop @B

	INVOKE MessageBoxDwordArr, tmpAdd, len

	ret 	
AddNewAction ENDP

MessageBoxDwordArr PROC uses eax ebx ecx edx esi edi,
	pArr: PTR DWORD,
	len: DWORD

	mov ecx, len 
	mov ebx, pArr
	mov esi, OFFSET tmpStr
@@:
	mov eax, [ebx]
	pushad
	INVOKE dw2a, eax, esi 
	popad
	add esi, TYPE BYTE
	add ebx, TYPE DWORD	
	loop @B

	mov eax, len
	INVOKE dw2a, eax, OFFSET tmpStr2
 	INVOKE MessageBox, 0, OFFSET tmpStr, OFFSET tmpStr2, 0
	ret 
MessageBoxDwordArr ENDP

InitializeTrack PROC

	mov trackLength, 0
	mov seqLength, 0

	ret
	
InitializeTrack EndP

TestProc PROC uses eax ebx 


	mov ecx, 10
	mov trainLength, ecx 

	mov ebx, OFFSET trainSeq

	mov eax, 1
@@:
	mov [ebx], eax 
	inc eax
	add ebx, TYPE DWORD
	loop @B

	invoke MessageBoxDwordArr, ADDR trainSeq, 10
	ret 

TestProc ENDP

END