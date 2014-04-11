TITLE Recognition and Matching        (Recognize.asm)

.386
.model flat,stdcall
option casemap:none

; Receive mouse track from front-end
; CONVERT the mouse track into direction sequence
; Then MATCH with the ACTIONs in the actionMap
; Returen bestMatch to front-end 
; Last update: Apr/10/2014

include Declaration.inc

.data
;--------------Mouse Track------------------------------------------------
trackPoint POINT 1024 DUP(<>) 		; chosen mouse track points
trackLength DWORD 0 				; number of chosen mouse track points

drawPoint POINT 1024 DUP(<>)		; original mouse track points
drawLength DWORD 0					; number of original mouse track points

trackSeq DWORD 1024 DUP(0)			; store track direction 
seqLength DWORD 0					; number of directions
;--------------------------------------------------------------------------

train DWORD 0

;--------------Action------------------------------------------------------
actionMap ACTION MAX_MAP_SIZE DUP(<>) 	; ACTION array 
actionLen DWORD 0 						; length of ACTION array 
;--------------------------------------------------------------------------

;--------------train-------------------------------------------------------
trainSeq DWORD 1024 DUP(0)
trainLength DWORD 0
;--------------------------------------------------------------------------

;--------------match-------------------------------------------------------
prefixMatchArray DWORD MAX_MAP_SIZE DUP(0) ; prefixMatchArray[k] = 0, if actionMap[k] still matches 
										   ; as far as compared 
										   ; prefixMatchArray[k] = 1, if actionMap[k] mismatches
bestMatch SDWORD -1 					   ; bestMatch = the no. of best-match ACTION 
lastDirection SDWORD -1 				   ; last direction of track 
;--------------------------------------------------------------------------

;----------DEBUG-------
tmpStr BYTE 1024 DUP(0)
tmpStr2 BYTE 1024 DUP(0)
;---------------------------------------------------------------------------

.code

;-----------------------------------------------------
CalTan PROC uses ebx edi,
	X : DWORD,
	Y : DWORD
;
; Calculate tangant value 
; Receives: X = |x1 - x0|, Y = |y0 - y1|
; Returns:  1, if tan > 1
;           0, if tan < 1
;-----------------------------------------------------

	mov ebx, X
	
	mov edi, Y

	.IF edi > ebx
		mov eax, 1
	.ELSE
		mov eax, 0
	.ENDIF

	ret 

CalTan ENDP

;-----------------------------------------------------
GetDirection PROC uses edx esi edi,
	x0: DWORD,
	x1: DWORD,
	y0: DWORD,
	y1: DWORD
	LOCAL delX: DWORD, delY: DWORD
	LOCAL signX: DWORD, signY: DWORD 
;
; Get the moving direction from P0 and P1
; Receives: x0: P0.x 
;			x1: P1.x
;			y0: P0.y
;			y1: P1.y
; Returns:  0 = up â†?
;           1 = right â†?
;			2 = down â†?
;			3 = left â†?
; Local:	delX = |x1 - x0|
;			delY = |y0 - y1|
;			signX = (x1 < x0)
;			signY = (y0 < y1) 
;-----------------------------------------------------

;-----------------------------------------------------
	mov edx, x1
	.if edx < x0  			
		mov signX, 1 		; signX = 1: dexX < 0
		mov edx, x0
		sub edx, x1 
	.else
		mov signX, 0		; signX = 0: delX >= 0
		sub edx, x0	
	.endif 
	mov delX, edx			; delX = |X1 - X0|


	mov esi, y0
	.if esi < y1
		mov signY, 1 		; signY = 1: dexY < 0
		mov esi, y1
		sub esi, y0
	.else 
		mov signY, 0		; signY = 0: delY >= 0
		sub esi, y1
	.endif 
	mov delY, esi 			; dexY = |Y0 - Y1|

	;-----------------------------------------------------
	;-----------------------------------------------------
	.IF delX == 0       			; along Y-axis
		.IF signY == 0				; delY >= 0
			mov eax, 0
		.ELSE 
			mov eax, 2
		.ENDIF

	;-----------------------------------------------------
	.ELSEIF signX == 0				; delX > 0, in the right part
		
		INVOKE CalTan, edx, esi		; tan = tan(delY/delX)

		mov edi, eax				

		;-------------------------------------------------
		.IF delY == 0				; along Y-axis
			mov eax, 1
		;-------------------------------------------------
		.ELSEIF signY == 0 			; delY > 0, quadrant I

			.IF edi > 0
				mov eax, 0
			.ELSE
				mov eax, 1
			.ENDIF
		;-------------------------------------------------	
		.ELSE 						; delY > 0, quadrant IV
			.IF edi > 0
				mov eax, 2
			.ELSE
				mov eax, 1
			.ENDIF
		.ENDIF

	;-----------------------------------------------------	
	.ELSE 						; delX < 0, in the left part

		INVOKE CalTan, edx, esi	; tan = tan(delY/delX)

		mov edi, eax				
		
		;-------------------------------------------------
		.IF delY == 0				; along Y-axis
			mov eax, 3
		;-------------------------------------------------
		.ELSEIF signY == 0 			; delY > 0, quadrant II

			.IF edi > 0
				mov eax, 0
			.ELSE
				mov eax, 3
			.ENDIF
		;-------------------------------------------------
		.ELSE 						; delY > 0, quadrant III
			.IF edi > 0
				mov eax, 2
			.ELSE
				mov eax, 3
			.ENDIF
		.ENDIF
	;-----------------------------------------------------		
	.ENDIF

	ret 

GetDirection ENDP

;-----------------------------------------------------
RecognizeTrack PROC uses ecx edx esi edi ebx 
				LOCAL curSeq: DWORD 		 
;
; Recognize the track of the points sequence
; Requires: trackPoint:		PTR POINT, array of the track sequence of mouse 
;			trackLength:	DWORD, length of trackPoint
;			trackSeq:		DWORD, array of the direction of mouse track 
;			seqLength:		DWORD, length of trackSeq
; 			lastDirection:	SDWORD, last direction of the mouse track
;-----------------------------------------------------
	
	;-------------------------------------------------
	.if trackLength <= 1 				
		ret 
	.endif 
	;-------------------------------------------------

	mov ebx, OFFSET trackPoint			; points to the first element of trackPoint
	mov eax, trackLength
	sub eax, 2
	lea esi, [ebx + eax * TYPE POINT]	; points to the (trackLength-1)-th element

	mov ebx, OFFSET trackSeq			; points the the first element of trackSeq 
	mov eax, seqLength
	lea edi, [ebx + eax * TYPE DWORD]	; points to the seqLength-th element to store the new direction

	;-------------------------------------------------
	; get the moving direction
	INVOKE GetDirection, (POINT PTR [esi]).x, (POINT PTR [esi + TYPE POINT]).x, (POINT PTR [esi]).y,
	(POINT PTR [esi + TYPE POINT]).y 	; 
	
	; wait till a new direction occurs 
	.IF lastDirection == -1 || eax != lastDirection
		
		mov lastDirection, eax			; record the new direction 

		mov [edi], eax 					; store current direction in trackSeq
		
		inc seqLength					; seqLength ++

		; match the action 
		invoke Match, lastDirection 
		 
	.ENDIF
	;-------------------------------------------------

	ret

RecognizeTrack ENDP

;-----------------------------------------------------
Match PROC uses ebx edx ecx edi esi, 
	dir: DWORD
	LOCAL counter: DWORD, closestLen: DWORD
;
; Match the current direction sequence with ACTIONs in the actionMap 
; if prefixMatchArray[k] = 0 
; then compare the len-th bit of actionMap[k].seq 
; or ignore 
; bestMatch stores the one whose length is closest to the len
; Receives: dir = current direction
; Requires: bestMatch = the no. of best-match ACTION 
;			prefixMatchArray[k] = 0, if actionMap[k] still matches 
;			as far as compared 
;			prefixMatchArray[k] = 1, if actionMap[k] mismatches
; Returns: 	counter = the counter of loop 
;			closestLen = closest length 
;-----------------------------------------------------

	mov SDWORD PTR eax, -1
	mov bestMatch, eax 				; Initialize bestMatch with -1 means no match 
	mov closestLen, 999999		; Initialize smallestLenDif with oo

	mov ecx, actionLen 				; use length of actionMap as the loop counter 

	mov esi, OFFSET actionMap		; points the the first array of actionMap 
	mov edi, OFFSET prefixMatchArray ; points the the first array of prefixMatchArray

	mov counter, 0					; counter 

	;-----------------------------------------------------
	.while ecx > 0					
		
		mov eax, [edi]			 	; eax = prefixMatchArray[k]

		;-----------------------------------------------------
		.if eax == 0				; actionMap[k] still matches

			mov eax, seqLength		; eax = length of trackSeq 
			mov ebx, (ACTION PTR [esi]).len ; ebx = length of actionMap[k]

			;-----------------------------------------------------
			.if eax <= ebx			; if seqLength < actionMap[counter].len 

				dec eax 
				lea ebx, (ACTION PTR [esi]).seq 	; points to the first array of seq of each ACTION
			 	lea edx, [ebx + eax * TYPE DWORD] 	; points to its len-th bit 

			 	mov eax, dir 		; eax = current direction

			 	;-----------------------------------------------------
			 	.if [edx] == eax 	; compare current direction and actionMap[k][seqLength]
			 		
			 		mov eax, (ACTION PTR [esi]).len ; eax = length of actionMap[k]

			 		;--------------------------------------------------
			 		comment *
			 		.if eax < closestLen 			; minimum match 
			 			mov ebx, counter
			 			mov bestMatch, ebx
			 			mov closestLen, eax 
			 		.endif 
			 		*

			 		.if eax == seqLength
			 			mov ebx, counter
			 			mov bestMatch, ebx
			 		.endif 
			 		;---------------------------------------------------

			 	.else 
			 		mov eax, 1
			 		mov [edi], eax 		; not match: set prefixMatchArray[k] = 1
			 	.endif 
				;-----------------------------------------------------

			;-----------------------------------------------------	
			.else
				mov eax, 1
			 	mov [edi], eax 		; not match: set prefixMatchArray[counter] = 1
			.endif
			;-----------------------------------------------------

		.endif 
		;-----------------------------------------------------

		add esi, TYPE ACTION 	; point to the next ACTION of actionMap
		add edi, TYPE DWORD  	; point to the next element of prefixMatchArray
		dec ecx 
		inc counter 			; counter +1 

	.endw 	
	;-----------------------------------------------------

	ret

Match ENDP

;-----------------------------------------------------
AddNewAction PROC uses ebx esi edi edx,
	seq: PTR DWORD,
	len: DWORD,
	path: PTR BYTE,
	tip: PTR BYTE, 
	pathType: DWORD
	LOCAL curActionPos:DWORD, seqStartPos:DWORD, pathStartPos:DWORD, tipStartPos:DWORD
;
; Add a new ACTION into actionMap 
; Receives: seq = address of direction sequence
; 			len = length of direction sequence
;			path = address of path of shellExecute 
;			tip = address of tip that user input 
; Requires: actionMap = ACTION array 
;-----------------------------------------------------

	;-----------------------set sequence-------------------
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
	;-----------------------------------------------------

	;--------set corresponding aciton path----------------
	mov edi, curActionPos
	lea esi, (ACTION PTR [edi]).path
	mov pathStartPos, esi 

	INVOKE lstrcpy, pathStartPos, path
	;-----------------------------------------------------
	
	;-------------------set tip ------------------------
	mov edi, curActionPos
	lea esi, (ACTION PTR [edi]).tip
	mov tipStartPos, esi 

	INVOKE lstrcpy, tipStartPos, tip
	;---------------------------------------------------

	;-------------------set type------------------------
	mov edi, curActionPos
	mov eax, pathType 
	mov (ACTION PTR [edi]).pathType, eax 
	;---------------------------------------------------

	inc actionLen	; length of actionMap + 1
	
	;-------------debug---------------------------------
	;INVOKE MessageBoxDwordArr, seqStartPos, len, tipStartPos
	;invoke GetArrowSeq, seq, len
	;INVOKE MessageBox, 0, addr upArrow, addr downArrow, 0
	
	ret 	

AddNewAction ENDP

;-----------------------------------------------------
MessageBoxDwordArr PROC uses eax ebx ecx edx esi edi,
	pArr: PTR DWORD,
	len: DWORD,
	path: PTR BYTE
;
; Show MessageBox, output a DWORD array and a string 
; Receives: pArr = points to DWORD array 
; 			len = length of DWORD array 
;			path = points to string  
;-----------------------------------------------------

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

;-----------------------------------------------------
InitializeTrack PROC
;
; Preparations for a new mouse track 
;-----------------------------------------------------

	mov trackLength, 0
	mov drawLength, 0
	mov seqLength, 0

	;--------------------------------
	; clear prefixMatchArray
	mov ecx, MAX_MAP_SIZE
	mov esi, offset prefixMatchArray
	.while ecx > 0
		xor eax, eax 
		mov [esi], eax
		dec ecx
		add esi, type DWORD
	.endw 
	;---------------------------------


	mov SDWORD PTR eax, -1
	mov bestMatch, eax
	mov lastDirection, eax 

	ret
	
InitializeTrack EndP

;-----------------------------------------------------
TestProc PROC uses eax ebx 
;
; Test program 
;-----------------------------------------------------
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

GetTipOfBestMatch PROC

	.if bestMatch >= 0
		mov ebx, OFFSET actionMap 	; point to the first element of actionMap
		mov esi, bestMatch			
		mov eax, TYPE ACTION
		mul esi  
		lea edi, [ebx + eax]		; point to the bestMatch-th element of actionMap to insert a new ACTION
		lea eax, (ACTION PTR [edi]).tip
	.else
		mov eax, 0
	.endif 

	ret 
GetTipOfBestMatch ENDP

END