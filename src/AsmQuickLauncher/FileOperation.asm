TITLE File Operations             (FileOperation.asm)

.386
.model flat,stdcall
option casemap:none

; All file operations for Quick Launcher
; IMPORT ACTIONs from a specific ascii file 'settings.ini'
; when the program starts 
; and EXPORT the actions to the same file 
; when the program exits 
; file format:
; type:DWORD len:DWORD actionSeq:DWORD * len path: BYTE tip:BYTE
; Last update: Apr/10/2014

include Declaration.inc

.data
;-----------------------------------------------------
szFileName	BYTE SETTINGS_FILE
szErrOpenFile BYTE '配置文件不存在，已自动创建新的配置文件', 0
szErrCreateFile BYTE '更新配置文件失败！', 0
szMessageBoxCaption BYTE '配置文件操作失败', 0

; save the absolute path of settings.ini
szProcFileName	BYTE	MAX_PATH DUP(?)

fpHandle DWORD ?

szFileName1 BYTE 'settings.ini',0

szSpace BYTE ' ', 0
szCrlf BYTE 13,10, 0
szSplit BYTE 124, 0

.code 
;-----------------------------------------------------
OutputDword2File PROC,  
	num: DWORD
	LOCAL @dwBytesWrite, buf[MAX_BUF_SIZE]: byte
;
; Output a DWORD to a specific file 
; Receives: DWORD
;-----------------------------------------------------
	pushad
	invoke dw2a, num, addr buf 	; convert DWORD to BYTE 
	invoke lstrlen, addr buf 	; count the length 
	mov edx, eax
	invoke WriteFile, fpHandle, addr buf, edx, addr @dwBytesWrite, 0
	popad 

	ret 
OutputDword2File ENDP

;-----------------------------------------------------
OutputByte2File PROC,
	buf: PTR BYTE
	LOCAL @dwBytesWrite
;
; Output a string to a specific file 
; Receives: address of BYTE 
;-----------------------------------------------------
	pushad
	invoke lstrlen, buf ; count the length 
	mov edx, eax
	invoke WriteFile, fpHandle, buf, edx, addr @dwBytesWrite, 0	 
	popad 
	ret 
OutputByte2File ENDP

;-----------------------------------------------------
OutputSpace2File PROC
	LOCAL @dwBytesWrite
;
; Output a BLANK SPACE to a specific file 
;-----------------------------------------------------
	pushad
	invoke lstrlen, addr szSpace ; count the length 
	mov edx, eax
	invoke WriteFile, fpHandle, addr szSpace, edx, addr @dwBytesWrite, 0
	popad 
	ret 
OutputSpace2File ENDP

;-----------------------------------------------------
OutputCrlf2File PROC
	LOCAL @dwBytesWrite
;
; Output a CRLF to a specific file 
;-----------------------------------------------------
	pushad
	invoke lstrlen, addr szCrlf ; count the length 
	mov edx, eax
	invoke WriteFile, fpHandle, addr szCrlf, edx, addr @dwBytesWrite, 0
	popad 
	ret 
OutputCrlf2File ENDP

OutputSplit2File PROC,
	p:PTR BYTE 
	LOCAL @dwBytesWrite

	pushad
	invoke lstrlen, p 	; count the length 
	mov edx, eax
	invoke WriteFile, fpHandle, p, edx, addr @dwBytesWrite, 0
	popad 
	ret 
	
OutputSplit2File ENDP

;-----------------------------------------------------
ImportAcitons PROC
	LOCAL @hFile, @dwBytesRead
	LOCAL @szReadBuffer: byte
	LOCAL curStep: DWORD, first: DWORD
	LOCAL pathType: DWORD
	LOCAL seqLen: DWORD, seq[MAX_SEQ_LEN]:DWORD,seqIndex: DWORD
	LOCAL path[1024]:DWORD, pathIndex: DWORD
	LOCAL tip[1024]:DWORD, tipIndex: DWORD
;
; READ the specific file
; and store the ACTIONs into actionMap
; Called when the program starts 
;-----------------------------------------------------

	; get the absolute path of settings.ini, or file saving may fail
	invoke GetModuleFileName, 0, offset szProcFileName, MAX_PATH
	invoke	lstrlen, offset szProcFileName
	mov		ecx, eax
	.while	szProcFileName[ecx] != '\'
		dec	ecx
	.endw
	inc		ecx
	mov		szProcFileName[ecx], 0
	invoke	lstrcat, offset szProcFileName, offset szFileName1

	pushad 

	;---------------- open settings.ini ------------------------------
	INVOKE	CreateFile,addr szProcFileName,GENERIC_READ,FILE_SHARE_READ,0,\
			OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0

	.if	eax ==	INVALID_HANDLE_VALUE
		invoke	MessageBox,hWinMain,addr szErrOpenFile,addr szMessageBoxCaption,MB_OK or MB_ICONEXCLAMATION
		ret
	.endif

	mov	@hFile,eax									; store the fileHandle 
	;------------------------------------------------------------------

	;------------------------------------------------------------------
	; load data to actionMap
	; read a single char each time 
	xor	eax,eax
	mov	@dwBytesRead,eax

	mov seqLen, 0
	mov curStep, 0
	mov seqIndex, 0
	mov pathIndex, 0
	mov tipIndex, 0
	mov first, 0
	;------------------------------------------------------------------
	; read data from file 
	.while	TRUE
		lea	esi, @szReadBuffer
		invoke	ReadFile, @hFile, esi, 1, addr @dwBytesRead, 0
		.break	.if ! @dwBytesRead
		
		;------touch a crlf --> input a complete ACTION--------- 	
		.if @szReadBuffer == 10	|| @szReadBuffer == 13	

			;----------------------------------------------------
			.if seqLen != 0
			;--------add aciton to map ---------
				lea ebx, path
				mov edx, pathIndex
				lea edi, [ebx + edx * TYPE BYTE]
				mov BYTE PTR [edi], 0 				; path should ends up with 0

				lea ebx, tip
				mov edx, tipIndex
				lea edi, [ebx + edx * TYPE BYTE]
				mov BYTE PTR [edi], 0				; tip should ends up with 0

				INVOKE AddNewAction, addr seq, seqLen, addr path, addr tip, pathType	; add new action 
			;-------------------------------------

			;--------clear all for next action-----		
				mov curStep, 0
				mov pathType, 0
				mov seqLen, 0
				mov seqIndex, 0
				mov pathIndex, 0
				mov tipIndex, 0
				mov first, 0
			;----------------------------------------
			.endif 
			;-------------------------------------------------------

		;----------------- touch a space ---------------
		.elseif @szReadBuffer == 32 && curStep < 3   	; touch a space 						
				inc curStep 							; curStep +1
		;----------------- touch a '|' ---------------	
		.elseif @szReadBuffer == 124 && first == 0  	; use '|' to seperate path and tip
			inc curStep
			inc first
		;----------- touch char -------------------------
		.else
			.if curStep == 0 						; get type 
				movzx eax, @szReadBuffer
				sub eax, '0'
				mov pathType, eax 

			;------get len---------
			.elseif curStep == 1 			 		; get length 					
				
				movzx eax, @szReadBuffer
				mov edx, seqLen
				imul edx, edx, 10
				sub eax, '0'
				add edx, eax
				mov seqLen, edx 
			;------------------------

			;------get seq-----------
			.elseif curStep == 2					; get sequence
				movzx eax, @szReadBuffer
				sub eax, '0'
				lea ebx, seq
				mov esi, seqIndex 
				mov [ebx + esi * TYPE DWORD], eax 
				mov eax, seqIndex
				inc eax 
				mov seqIndex, eax
			;--------------------------

			;------get path------------ 
			.elseif curStep == 3 					; get path 
				lea esi, @szReadBuffer				; esi points to src

				lea ebx, path
				mov edx, pathIndex
				lea edi, [ebx + edx * TYPE BYTE]	; edi poitnts to dest

				movsb 								; load char from src to dest

				inc pathIndex 						; pathIndex ++ 
			;--------------------------
			;------get tip------------ 
			.else 
				lea esi, @szReadBuffer				; esi points to src

				lea ebx, tip
				mov edx, tipIndex
				lea edi, [ebx + edx * TYPE BYTE]	; edi poitnts to dest

				movsb 								; load char from src to dest

				inc tipIndex
			.endif
			;--------------------------
		.endif

	.endw
	;------------------------------------------------------------------

	;------------------------------------------------------------------
	; in case that there is no a crlf in the end 
	.if seqLen != 0

		lea ebx, path
		mov edx, pathIndex
		lea edi, [ebx + edx * TYPE BYTE]
		mov BYTE PTR [edi], 0 				; path should ends up with 0
	
		lea ebx, tip
		mov edx, tipIndex
		lea edi, [ebx + edx * TYPE BYTE]
		mov BYTE PTR [edi], 0				; tip should ends up with 0

		INVOKE AddNewAction, addr seq, seqLen, addr path, addr tip, pathType 	; add new action 
		 
	.endif 
	;------------------------------------------------------------------

	INVOKE	CloseHandle, @hFile				; close file 

	popad 
	
	ret 
ImportAcitons ENDP

;-----------------------------------------------------
ExportActions PROC
	local index: dword
;
; WRITE data to the specific file
; Called when the program ends 
;-----------------------------------------------------

	; get the absolute path of settings.ini, or file saving may fail
	invoke GetModuleFileName, 0, offset szProcFileName, MAX_PATH
	invoke	lstrlen, offset szProcFileName
	mov		ecx, eax
	.while	szProcFileName[ecx] != '\'
		dec	ecx
	.endw
	inc		ecx
	mov		szProcFileName[ecx], 0
	invoke	lstrcat, offset szProcFileName, offset szFileName1

	pushad

	;---------------- open settings.ini ------------------------------
	invoke	CreateFile,addr szProcFileName,GENERIC_WRITE,FILE_SHARE_READ,\
			0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
	.if	eax ==	INVALID_HANDLE_VALUE
			invoke	MessageBox,hWinMain,addr szErrCreateFile,addr szMessageBoxCaption,MB_OK or MB_ICONEXCLAMATION
			ret
	.endif

	mov fpHandle, eax			; store the fileHandle as global variable
	;------------------------------------------------------------------


	mov ecx, actionLen			; use the length of actionMap as the loop counter

	mov edi, OFFSET actionMap 	; point to the first element of actionMap

	;------------------------------------------------------------------
	.while ecx > 0
		
		invoke OutputDword2File, (ACTION PTR [edi]).pathType	; output type 
		invoke OutputSpace2File
		invoke OutputDword2File, (ACTION PTR [edi]).len 		; output len 
		invoke OutputSpace2File

		;---------------------------------------------------------------
		mov ebx, (ACTION PTR [edi]).len
		lea esi, (ACTION PTR [edi]).seq

		.while ebx > 0 											; output seq 
			
			invoke OutputDword2File, [esi]

			add esi, TYPE DWORD
			dec ebx 
		.endw 
		;---------------------------------------------------------------

		invoke OutputSpace2File
		invoke OutputByte2File, ADDR (ACTION PTR [edi]).path 	; output action path 
		invoke OutputSplit2File, addr szSplit
		invoke OutputByte2File, ADDR (ACTION PTR [edi]).tip 	; output action tip 
		invoke OutputCrlf2File
		
		add edi, TYPE ACTION 
		dec ecx
	.endw 
	;------------------------------------------------------------------

	INVOKE	CloseHandle, fpHandle
	
	popad

	ret

ExportActions ENDP

END