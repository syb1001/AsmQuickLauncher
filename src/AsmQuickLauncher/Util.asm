.386
.model flat,stdcall
option casemap:none

include Declaration.inc

.data
;----------- edit ------------------
upArrow 			db    '¡ü', 0
downArrow 			db 	  '¡ý', 0
rightArrow 			db 	  '¡ú', 0 
leftArrow 			db 	  '¡û', 0

.const
szOpen			db		'open', 0

.code
GetArrowSeq PROC uses eax ecx esi edi,
	p: PTR DWORD,
	len: DWORD,
	dest: PTR BYTE

	mov ecx, len 
	mov esi, p

	mov edi, dest
	mov BYTE PTR [edi], 0

	.while ecx > 0
		mov eax, [esi]
		push ecx
		push esi 

		.if eax == 0
			invoke lstrcat, dest, offset upArrow  
		.elseif eax == 1
			invoke lstrcat, dest, offset rightArrow  
		.elseif eax == 2
			invoke lstrcat, dest, offset downArrow  
		.else 
			invoke lstrcat, dest, offset leftArrow  
		.endif 

		pop esi
		pop ecx 
		add esi, TYPE DWORD
		dec ecx
	.endw 

	ret 
GetArrowSeq EndP

ExecuteMatch PROC uses eax ecx esi edi,
	index: DWORD

	.if		index == -1
			ret
	.endif

	mov		eax, index
	lea		ebx, actionMap
	mov		edx, TYPE ACTION
	mul		edx
	add		ebx, eax

	mov		eax, (ACTION PTR [ebx]).pathType
	.if		eax <= 2
			lea		esi, (ACTION PTR [ebx]).path
			invoke	ShellExecute, NULL, addr szOpen, esi, NULL, NULL, SW_SHOW
	.else
			; convert the saved path to a vitual path struct here
			; then use ShellExecuteEx to open that
	.endif

	ret
ExecuteMatch ENDP

CopyAction PROC uses eax ecx esi edi,
	dest: PTR ACTION,
	src: PTR ACTION

	mov		esi, src
	mov		edi, dest

	mov		eax, (ACTION PTR [esi]).len
	mov		(ACTION PTR [edi]).len, eax
	mov		eax, (ACTION PTR [esi]).pathType
	mov		(ACTION PTR [edi]).pathType, eax

	invoke	lstrcpy, addr (ACTION PTR [edi]).path, addr (ACTION PTR [esi]).path
	invoke	lstrcpy, addr (ACTION PTR [edi]).tip, addr (ACTION PTR [esi]).tip

	mov		ecx, 0
	lea		ebx, (ACTION PTR [esi]).seq
	lea		edx, (ACTION PTR [edi]).seq
	mov		edi, (ACTION PTR [esi]).len
	.while	ecx < edi
		mov		eax, [ebx]
		mov		[edx], eax
		add		ebx, TYPE DWORD
		add		edx, TYPE DWORD
		inc		ecx
	.endw

	ret
CopyAction ENDP

DeleteAction PROC uses eax ecx esi edi,
	index: DWORD,
	address: PTR ACTION

	.if		actionLen == 0
		ret
	.endif
	dec		actionLen

	mov		ecx, index
	mov		edi, address
	mov		esi, address
	add		esi, TYPE ACTION
	.while	ecx < actionLen
		invoke	CopyAction, edi, esi
		add		esi, TYPE ACTION
		add		edi, TYPE ACTION
		inc		ecx
	.endw

	ret
DeleteAction ENDP

END