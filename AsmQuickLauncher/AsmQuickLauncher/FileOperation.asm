.386
.model flat,stdcall
option casemap:none

; IMPORT acitons from a specific ascii file 'settings.ini'
; when the program starts 
; and EXPORT the actions to the same file 
; when the program exits 
; file format:
; len:DWORD actionSeq:DWORD * len path: BYTE 


include Declaration.inc

.data

szFileName	BYTE SETTINGS_FILE
szErrOpenFile BYTE 'Can not open settings.ini', 0
szErrCreateFile BYTE 'Can not update settings.ini', 0

fpHandle DWORD ?

szFileName1 BYTE 'settings.ini',0

szSpace BYTE ' ', 0
szCrlf BYTE 13,10, 0

.code 

OutputDword2File PROC,  
	num: DWORD
	LOCAL @dwBytesWrite, buf[MAX_BUF_SIZE]: byte

	pushad
	invoke dw2a, num, addr buf 	; convert DWORD to BYTE 
	invoke lstrlen, addr buf 	; count the length 
	mov edx, eax
	invoke WriteFile, fpHandle, addr buf, edx, addr @dwBytesWrite, 0
	popad 

	ret 
OutputDword2File ENDP

OutputByte2File PROC,
	buf: PTR BYTE
	LOCAL @dwBytesWrite

	pushad
	invoke lstrlen, buf ; count the length 
	mov edx, eax
	invoke WriteFile, fpHandle, buf, edx, addr @dwBytesWrite, 0	 
	popad 
	ret 
OutputByte2File ENDP

OutputSpace2File PROC
	LOCAL @dwBytesWrite
	pushad
	invoke lstrlen, addr szSpace ; count the length 
	mov edx, eax
	invoke WriteFile, fpHandle, addr szSpace, edx, addr @dwBytesWrite, 0
	popad 
	ret 
OutputSpace2File ENDP

OutputCrlf2File PROC
	LOCAL @dwBytesWrite
	pushad
	invoke lstrlen, addr szCrlf ; count the length 
	mov edx, eax
	invoke WriteFile, fpHandle, addr szCrlf, edx, addr @dwBytesWrite, 0
	popad 
	ret 
OutputCrlf2File ENDP

ImportAcitons PROC
	LOCAL @hFile, @dwBytesRead
	LOCAL @szReadBuffer: byte
	LOCAL curStep: DWORD, seqLen: DWORD, seq[MAX_SEQ_LEN]:DWORD,seqIndex: DWORD
	LOCAL path[1024]:DWORD, pathIndex: DWORD
	LOCAL tip[1024]:DWORD, tipIndex: DWORD

	pushad 
	;---------------- open settings.ini ------------------------------
	INVOKE	CreateFile,addr szFileName,GENERIC_READ,FILE_SHARE_READ,0,\
			OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	.if	eax ==	INVALID_HANDLE_VALUE
		invoke	MessageBox,hWinMain,addr szErrOpenFile,NULL,MB_OK or MB_ICONEXCLAMATION
		ret
	.endif
	mov	@hFile,eax	; store the fileHandle 
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

	.while	TRUE
		lea	esi, @szReadBuffer
		invoke	ReadFile, @hFile, esi, 1, addr @dwBytesRead, 0
		.break	.if ! @dwBytesRead
		
		;------touch a crlf --> input a complete ACTION--------- 	
		.if @szReadBuffer == 10	|| @szReadBuffer == 13	

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

				INVOKE AddNewAction, addr seq, seqLen, addr path, addr tip 	; add new action 
			;-------------------------------------	
			;--------clear all for next action-------		
				mov seqLen, 0 		
				mov curStep, 0
				mov seqIndex, 0
				mov pathIndex, 0
				mov tipIndex, 0
			;----------------------------------------
			.endif 

		;----------------- touch a space ---------------
		.elseif @szReadBuffer == 32    ; touch a space 
			
			mov eax, curStep
			inc eax
			mov curStep, eax 

		;----------- touch char -------------------------
		.else
			;------get len---------
			.if curStep == 0					
				
				movzx eax, @szReadBuffer
				mov edx, seqLen
				imul edx, edx, 10
				sub eax, '0'
				add edx, eax
				mov seqLen, edx 
			;------------------------
			;------get seq-----------
			.elseif curStep == 1				; get sequence
				
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
			.elseif curStep == 2 								; get path 
				lea esi, @szReadBuffer			; esi points to src

				lea ebx, path
				mov edx, pathIndex
				lea edi, [ebx + edx * TYPE BYTE]	; edi poitnts to dest

				movsb 							; load char from src to dest

				inc pathIndex 				; pathIndex ++ 
			;--------------------------
			;------get tip------------ 
			.else 
				lea esi, @szReadBuffer			; esi points to src

				lea ebx, tip
				mov edx, tipIndex
				lea edi, [ebx + edx * TYPE BYTE]	; edi poitnts to dest

				movsb 							; load char from src to dest

				inc tipIndex
			.endif
			;--------------------------
		.endif

	.endw

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

		INVOKE AddNewAction, addr seq, seqLen, addr path, addr tip 	; add new action 

	.endif 

	INVOKE	CloseHandle, @hFile

	popad 
	
	ret 
ImportAcitons ENDP


ExportActions PROC
	local index: dword
	
	pushad
	;---------------- open settings.ini ------------------------------
	invoke	CreateFile,addr szFileName1,GENERIC_WRITE,FILE_SHARE_READ,\
			0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
	.if	eax ==	INVALID_HANDLE_VALUE
			invoke	MessageBox,hWinMain,addr szErrCreateFile,NULL,MB_OK or MB_ICONEXCLAMATION
			ret
	.endif
	mov fpHandle, eax	; store the fileHandle 
	;------------------------------------------------------------------


	mov ecx, actionLen	; loop counter

	mov edi, OFFSET actionMap 	; point to the first element of actionMap

	.while ecx > 0
		
		invoke OutputDword2File, (ACTION PTR [edi]).len ; output len 
		invoke OutputSpace2File

		mov ebx, (ACTION PTR [edi]).len
		lea esi, (ACTION PTR [edi]).seq

		.while ebx > 0 		; output seq 
			
			invoke OutputDword2File, [esi]

			add esi, TYPE DWORD
			dec ebx 
		.endw 
		
		invoke OutputSpace2File
		invoke OutputByte2File, ADDR (ACTION PTR [edi]).path 	; output action path 
		invoke OutputSpace2File
		invoke OutputByte2File, ADDR (ACTION PTR [edi]).tip 	; output action tip 
		invoke OutputCrlf2File
		
		add edi, TYPE ACTION 
		dec ecx
	.endw 

	INVOKE	CloseHandle, fpHandle
	
	popad

	ret

ExportActions ENDP

END