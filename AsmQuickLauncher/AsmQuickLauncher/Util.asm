.386
.model flat,stdcall
option casemap:none

include Declaration.inc

.data
;----------- edit ------------------
arrowSeq BYTE 1024 DUP(0)
upArrow 			db    '¡ü', 0
downArrow 			db 	  '¡ý', 0
rightArrow 			db 	  '¡ú', 0 
leftArrow 			db 	  '¡û', 0

.code
GetArrowSeq PROC uses eax ecx esi edi,
	p: PTR DWORD,
	len: DWORD

	mov ecx, len 
	mov esi, p

	mov edi, offset arrowSeq
	mov BYTE PTR [edi], 0

	.while ecx > 0
		mov eax, [esi]
		push ecx
		push esi 

		.if eax == 0
			invoke lstrcat, addr arrowSeq, addr upArrow  
		.elseif eax == 1
			invoke lstrcat, addr arrowSeq, addr rightArrow  
		.elseif eax == 2
			invoke lstrcat, addr arrowSeq, addr downArrow  
		.else 
			invoke lstrcat, addr arrowSeq, addr leftArrow  
		.endif 

		pop esi
		pop ecx 
		add esi, TYPE DWORD
		dec ecx
	.endw 

	mov eax, offset arrowSeq
	ret 
GetArrowSeq EndP

END