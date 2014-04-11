.386
.model flat,stdcall
option casemap:none

include Declaration.inc

.data
;--------------Mouse Track------------------------------------------------
trackPoint POINT 2048 DUP(<>) 	; Mouse track Point
trackLength DWORD 0 				; number of mouse track points
drawPoint POINT 2048 DUP(<>)
drawLength DWORD 0
trackSeq DWORD 2048 DUP(0)		; store track direction 
seqLength DWORD 0					; number of directions
;--------------------------------------------------------------------------
train DWORD 0
;--------------Action-------------------------------------------------------
actionMap ACTION MAX_MAP_SIZE DUP(<>)
actionLen DWORD 0
;--------------------------------------------------------------------------

;--------------train----------------
trainSeq DWORD 1024 DUP(0)
trainLength DWORD 0
;--------------------------------------------------------------------------

;------------- match ---------------
prefixMatchArray DWORD MAX_MAP_SIZE DUP(0)
bestMatch SDWORD -1
lastDirection SDWORD -1
;--------------------------------------------------------------------------

;----------DEBUG-------
tmpStr BYTE 1024 DUP(0)
tmpStr2 BYTE 1024 DUP(0)


.code

CalTan PROC uses ebx edi,
	X : DWORD,
	Y : DWORD

	mov ebx, X
	
	mov edi, Y

	.IF edi > ebx
		mov eax, 1
	.ELSE
		mov eax, 0
	.ENDIF

	ret 

CalTan ENDP

GetDirection PROC uses edx esi edi,
	x0: DWORD,
	x1: DWORD,
	y0: DWORD,
	y1: DWORD
LOCAL delX : DWORD, delY : DWORD, signX: DWORD, signY: DWORD 
 	
	mov edx, x1
	.if edx < x0  			
		mov signX, 1 		; signX = 1: dexX < 0
		mov edx, x0
		sub edx, x1 
	.else
		mov signX, 0		; signX = 0: delX >= 0
		sub edx, x0	
	.endif 
	mov delX, edx	; dexX = |X1 - X0|


	mov esi, y0
	.if esi < y1
		mov signY, 1 	; signY = 1: dexY < 0
		mov esi, y1
		sub esi, y0
	.else 
		mov signY, 0	; signY = 0: delY >= 0
		sub esi, y1
	.endif 
	mov delY, esi 		; dexY = |Y0 - Y1|

	; return eax = 0(up), 1(right), 2(down), 3(left)	 
	.IF delX == 0       			; along Y-axis
		.IF signY == 0				; delY >= 0
			mov eax, 0
		.ELSE 
			mov eax, 2
		.ENDIF
	
	.ELSEIF signX == 0				; delX > 0, in the right part
		
		INVOKE CalTan, edx, esi	; tan = tan(delY/delX)

		mov edi, eax				

		.IF delY == 0				; along Y-axis
			mov eax, 1
		
		.ELSEIF signY == 0 			; delY > 0, quadrant I

			.IF edi > 0
				mov eax, 0
			.ELSE
				mov eax, 1
			.ENDIF

		.ELSE 						; delY > 0, quadrant IV
			.IF edi > 0
				mov eax, 2
			.ELSE
				mov eax, 1
			.ENDIF
		.ENDIF

	.ELSE 						; delX < 0, in the left part

		INVOKE CalTan, edx, esi	; tan = tan(delY/delX)
		mov edi, eax				

		.IF delY == 0				; along Y-axis
			mov eax, 3
		
		.ELSEIF signY == 0 			; delY > 0, quadrant II
			.IF edi > 0
				mov eax, 0
			.ELSE
				mov eax, 3
			.ENDIF
		
		.ELSE 						; delY > 0, quadrant III
			.IF edi > 0
				mov eax, 2
			.ELSE
				mov eax, 3
			.ENDIF
		.ENDIF

	.ENDIF

	ret 

GetDirection ENDP

RecognizeTrack PROC uses ecx edx esi edi ebx ; Judge the length before invoke
				LOCAL curSeq: DWORD 		 ; store current trasck sequence as DWORD format
; Get the array of directions 
	
	.if trackLength <= 1
		ret 
	.endif 
		
	mov ebx, OFFSET trackPoint			; point to the first array of trackPoint
	mov eax, trackLength
	sub eax, 2
	lea esi, [ebx + eax * TYPE POINT]

	mov ebx, OFFSET trackSeq				; point the the first array of trackSeq 
	mov eax, seqLength
	lea edi, [ebx + eax * TYPE DWORD]

;---------------------------------------------------------------------------------------------------
	
		INVOKE GetDirection, (POINT PTR [esi]).x, (POINT PTR [esi + TYPE POINT]).x, (POINT PTR [esi]).y,
		(POINT PTR [esi + TYPE POINT]).y
		
		; Wait til a new direction occurs 
		.IF lastDirection == -1 || eax != lastDirection
			
			mov lastDirection, eax		; record the new direction 

			mov [edi], eax 		; store curSeq in trackSeq
			
			inc seqLength		; seqLength ++

			; to insert a trigger here 
			invoke Match, eax 
			 
		.ENDIF

	ret

RecognizeTrack ENDP


Match PROC uses ebx edx ecx edi esi, 
	dir: DWORD
	local counter: DWORD, smallestLenDif: DWORD

; if prefixMatchArray[k] = 0 
; then compare the len-th bit of actionMap[k].seq 
; or ignore 
; bestMatch stores the one whose length is closest to the len
	
	comment *
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
	*

	mov SDWORD PTR eax, -1
	mov bestMatch, eax 				; Initialize bestMatch with -1 means no match 
	mov smallestLenDif, 1024		; Initialize smallestLenDif with oo

	mov ecx, actionLen 			; use length of actionMap as the loop counter 

	mov esi, OFFSET actionMap	; point the the first array of actionMap 
	mov edi, OFFSET prefixMatchArray ; point the the first array of prefixMatchArray

	mov counter, 0					; counter 


	.while ecx > 0
		
		mov eax, [edi]

		.if eax == 0			 ; still match 

			mov eax, seqLength	; use the length of each ACTION as the loop counter 
			mov ebx, (ACTION PTR [esi]).len 
			.if eax <= ebx			; if seqLength < actionMap[counter].len 

				dec eax 
				lea ebx, (ACTION PTR [esi]).seq 	; point to the first array of seq of each ACTION
			 	lea edx, [ebx + eax * TYPE DWORD] 	; point to its len-th bit 

			 	mov eax, dir
			 	.if [edx] == eax 	; compare dir and seq[len]
			 		
			 		mov eax, (ACTION PTR [esi]).len
			 		mov ebx, seqLength
			 		sub eax, ebx 			; length difference between trackLength and actionMap[counter]

			 		.if eax < smallestLenDif
			 			mov ebx, counter
			 			mov bestMatch, ebx
			 			mov smallestLenDif, eax 

			 		.endif 

			 	.else 
			 		mov eax, 1
			 		mov [edi], eax 		; not match: set prefixMatchArray[counter] = 1
			 	.endif 
			
			.else
				mov eax, 1
			 	mov [edi], eax 		; not match: set prefixMatchArray[counter] = 1
			.endif

		.endif 


		add esi, TYPE ACTION 	; point to the next ACTION of actionMap
		add edi, TYPE DWORD  	; point to the next element of prefixMatchArray
		dec ecx 
		inc counter 				; counter +1 
	.endw 	

	ret

Match ENDP


AddNewAction PROC uses ebx esi edi edx,
	seq: PTR DWORD,
	len: DWORD,
	path: PTR BYTE,
	tip: PTR BYTE, 
	pathType: DWORD

LOCAL curActionPos:DWORD, seqStartPos:DWORD, pathStartPos:DWORD, tipStartPos:DWORD

;--------set sequence-----------------------------------
	mov ebx, OFFSET actionMap 	; point to the first element of actionMap
	mov esi, actionLen			
	mov eax, TYPE ACTION
	mul esi  
	lea edi, [ebx + eax]		; point to the len-th element of actionMap to insert a new ACTION
	
	mov curActionPos, edi 		; store pointer to current action 

	mov ecx, len 
	mov (ACTION PTR [edi]).len, ecx

	lea esi, (ACTION PTR [edi]).seq 
	mov seqStartPos, esi

	mov edi, seq 				; point to the first element of seq 
@@:
	mov eax, [edi]
	mov [esi], eax

	add esi, TYPE DWORD
	add edi, TYPE DWORD
	loop @B

;--------set responsive aciton path----------------
	
	mov edi, curActionPos
	lea esi, (ACTION PTR [edi]).path
	mov pathStartPos, esi 

	INVOKE lstrcpy, pathStartPos, path
;-------------end-----------------------------------
	
;-------- set tip ----------------
	
	mov edi, curActionPos
	lea esi, (ACTION PTR [edi]).tip
	mov tipStartPos, esi 

	INVOKE lstrcpy, tipStartPos, tip
;-------------end-----------------------------------

;-------- set type ----------------
	mov edi, curActionPos
	mov eax, pathType 
	mov (ACTION PTR [edi]).pathType, eax 
;-------------end-----------------------------------

	inc actionLen
	
;-------------debug---------------------------------
	

	;INVOKE MessageBoxDwordArr, seqStartPos, len, tipStartPos
	;invoke GetArrowSeq, seq, len
	;INVOKE MessageBox, 0, addr upArrow, addr downArrow, 0
	

	ret 	
AddNewAction ENDP

MessageBoxDwordArr PROC uses eax ebx ecx edx esi edi,
	pArr: PTR DWORD,
	len: DWORD,
	path: PTR BYTE

	mov ecx, len 
	.if ecx < 1
		ret 
	.endif 
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

 	INVOKE MessageBox, 0, OFFSET tmpStr, path, 0
	ret 
MessageBoxDwordArr ENDP

InitializeTrack PROC
	
	;invoke MessageBoxDwordArr, addr trackSeq, seqLength, addr tmpStr

	mov trackLength, 0
	mov drawLength, 0
	mov seqLength, 0

	mov ecx, MAX_MAP_SIZE
	mov esi, offset prefixMatchArray
	.while ecx > 1
		xor eax, eax 
		mov [esi], eax
		dec ecx
		add esi, type DWORD
	.endw 

	mov SDWORD PTR eax, -1
	mov bestMatch, eax
	mov lastDirection, eax 

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

	;invoke MessageBoxDwordArr, ADDR trainSeq, 10
	ret 

TestProc ENDP


END