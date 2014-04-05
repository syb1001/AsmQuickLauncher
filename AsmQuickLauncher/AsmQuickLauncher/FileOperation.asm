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
BufSize DWORD MAX_BUF_SIZE
szFileName	BYTE SETTINGS_FILE
szErrOpenFile BYTE 'Can not open settings.ini', 0
szErrCreateFile BYTE 'Can not update settings.ini', 0
fpHandle WORD ?

.code 

OutputDword2File PROC uses eax @hFile,
	num: DWORD
LOCAL @dwBytesWrite: dword,  buf[1024]: byte
LOCAL space:byte

	mov BYTE PTR space, 32
	
	pushad
	;invoke ConvertDword2Str, num, ADDR buf 
	invoke dw2a, num, addr buf
	invoke WriteFile, @hFile, addr buf, 255, @dwBytesWrite, 0	; output len 
	invoke WriteFile, @hFile, addr space, 1, @dwBytesWrite, 0	; output a space 
	popad

	ret 
OutputDword2File ENDP

OutputByte2File PROC uses eax @hFile,
	buf: PTR BYTE
LOCAL @dwBytesWrite
LOCAL cr:byte, lf:byte 

	mov BYTE PTR cr, 13
	mov BYTE PTR lf, 10

	pushad
	invoke WriteFile, @hFile, addr buf, 255, @dwBytesWrite, 0	; output len 
	
	invoke WriteFile, @hFile, addr cr, 1, @dwBytesWrite, 0	
	invoke WriteFile, @hFile, addr lf, 1, @dwBytesWrite, 0	
	
	popad

	ret 
OutputByte2File ENDP

ImportAcitons PROC
	LOCAL @hFile, @dwBytesRead
	LOCAL @szReadBuffer: byte
	LOCAL curStep: DWORD, seqLen: DWORD, seq[MAX_SEQ_LEN]:DWORD,seqIndex: DWORD
	LOCAL path[1024]:DWORD, pathIndex: DWORD
	pushad 

	; open settings.ini
	INVOKE	CreateFile,addr szFileName,GENERIC_READ,FILE_SHARE_READ,0,\
			OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	.if	eax ==	INVALID_HANDLE_VALUE
		invoke	MessageBox,hWinMain,addr szErrOpenFile,NULL,MB_OK or MB_ICONEXCLAMATION
		ret
	.endif
	mov	@hFile,eax

	; load data to actionMap
	; read a single char each time 
	xor	eax,eax
	mov	@dwBytesRead,eax

	mov seqLen, 0
	mov curStep, 0
	mov seqIndex, 0
	mov pathIndex, 0

	.while	TRUE
		lea	esi, @szReadBuffer
		invoke	ReadFile, @hFile, esi, 1, addr @dwBytesRead, 0
		.break	.if ! @dwBytesRead
			
		.if @szReadBuffer == 10	|| @szReadBuffer == 13	; crlf 

			.if seqLen != 0

				lea ebx, path
				mov edx, pathIndex
				lea edi, [ebx + edx * TYPE BYTE]
				mov BYTE PTR [edi], 0 				; path should ends up with 0
				;INVOKE MessageBox, 0, addr @szReadBuffer, addr path, 0

				INVOKE AddNewAction, addr seq, seqLen, addr path

				mov seqLen, 0 		; clear all for next action
				mov curStep, 0
				mov seqIndex, 0
				mov pathIndex, 0
			.endif 
			
		.elseif @szReadBuffer == 32    ; space = 32
			
			mov eax, curStep
			inc eax
			mov curStep, eax 

		.else
			.if curStep == 0					; get len
				
				movzx eax, @szReadBuffer
				mov edx, seqLen
				imul edx, edx, 10
				sub eax, '0'
				add edx, eax
				mov seqLen, edx 
			.elseif curStep == 1				; get sequence
				
				movzx eax, @szReadBuffer
				sub eax, '0'
				lea ebx, seq
				mov esi, seqIndex 
				mov [ebx + esi * TYPE DWORD], eax 
				mov eax, seqIndex
				inc eax 
				mov seqIndex, eax
			.else 								; get path 
				lea esi, @szReadBuffer			; esi points to src

				lea ebx, path
				mov edx, pathIndex
				lea edi, [ebx + edx * TYPE BYTE]	; edi poitnts to dest

				movsb 							; load char from src to dest

				mov eax, pathIndex			; pathIndex ++ 
				inc eax
				mov pathIndex, eax
								
			.endif

		.endif

	.endw

	INVOKE	CloseHandle, @hFile

	popad 
	
	ret 
ImportAcitons ENDP


ExportActions PROC
	LOCAL @hFile
	local buf[20]:byte, @dwBytesWrite:dword

	invoke	CreateFile,addr szFileName,GENERIC_WRITE,FILE_SHARE_READ,\
			0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
	.if	eax ==	INVALID_HANDLE_VALUE
			invoke	MessageBox,hWinMain,addr szErrCreateFile,NULL,MB_OK or MB_ICONEXCLAMATION
			ret
	.endif
	mov	@hFile,eax	

   invoke WriteFile, @hFile, addr buf, 255, @dwBytesWrite, 0

	mov ecx, actionLen	; loop counter
	xor edx, edx 		; index of actionMap

	mov edi, OFFSET actionMap 	; point to the first element of actionMap
	
Output2FileLoop: 	; bug: if actionLen = 0
	
	invoke OutputDword2File, @hFile, (ACTION PTR [edi]).len

	push ecx
	mov ecx, (ACTION PTR [edi]).len

	lea esi, (ACTION PTR [edi]).seq
@@:
	
	invoke OutputDword2File, @hFile, [esi]

	add esi, TYPE DWORD
	loop @B

	pop ecx 

	invoke OutputByte2File, @hFile, ADDR (ACTION PTR [edi]).path

	add edi, TYPE ACTION 
	loop Output2FileLoop

	INVOKE	CloseHandle, @hFile
	
	ret

ExportActions ENDP

ConvertDword2Str PROC,
	num: DWORD,
	s: PTR BYTE 

	mov eax, num 
	mov esi, s
	invoke dw2a, eax, esi 

	ret 
ConvertDword2Str ENDP

END