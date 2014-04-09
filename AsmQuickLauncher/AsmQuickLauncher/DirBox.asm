.386
.model flat, stdcall
option casemap:none

include Declaration.inc

.data
dirSeq		dd		32 DUP(0)
dirLen		dd		0
arrowString	db		128 DUP(0)

.const
szError		db		'错误', 0
szWarning	db		'手势序列长度不能为0！', 0

.code
_ProcDirBoxMain PROC uses ebx edi esi hWnd, wMsg, wParam, lParam

	mov		eax, wMsg
	.if		eax == WM_INITDIALOG
			mov		ebx, actionAddress
			; convert 0123 sequence to dir sequence
			invoke	GetArrowSeq, addr (ACTION PTR [ebx]).seq, (ACTION PTR [ebx]).len
			; copy arrow string and diaplay
			invoke	lstrcpy, offset arrowString, offset arrowSeq
			invoke	SetDlgItemText, hWnd, IDC_DirBox, offset arrowString
			; copy length
			mov		edx, (ACTION PTR [ebx]).len
			mov		dirLen, edx
			; copy 0123 sequence
			mov		ecx, 0
			lea		esi, (ACTION PTR [ebx]).seq
			lea		edi, dirSeq
			.while	ecx < edx
				mov		eax, [esi]
				mov		[edi], eax
				add		esi, TYPE DWORD
				add		edi, TYPE DWORD
				inc		ecx
			.endw
	.elseif	eax == WM_CLOSE
			invoke	EndDialog, hWnd, 0
	.elseif	eax == WM_COMMAND
			mov		eax, wParam
			.if		ax == IDOK
					; judge the length is 0 or not, which is illegal
					.if	dirLen == 0
						invoke	MessageBox, 0, offset szWarning, offset szError, 0
						mov		eax, FALSE
						ret
					.endif
					; copy length
					mov		edx, dirLen
					mov		ebx, actionAddress
					mov		(ACTION PTR [ebx]).len, edx
					; copy 0123 sequence
					mov		ecx, 0
					lea		esi, dirSeq
					mov		ebx, actionAddress
					lea		edi, (ACTION PTR [ebx]).seq
					.while	ecx < edx
						mov		eax, [esi]
						mov		[edi], eax
						add		esi, TYPE DWORD
						add		edi, TYPE DWORD
						inc		ecx
					.endw

					invoke	EndDialog, hWnd, 1
			.elseif	ax == IDCANCEL
					invoke	EndDialog, hWnd, 0
			.elseif ax == IDC_Up
					invoke	lstrcat, offset arrowString, offset upArrow
					invoke	SetDlgItemText, hWnd, IDC_DirBox, offset arrowString
					; add int to tail of array
					mov		eax, dirLen
					mov		dirSeq[eax * TYPE DWORD], 0
					; len++
					mov		eax, dirLen
					inc		eax
					mov		dirLen, eax
			.elseif ax == IDC_Down
					invoke	lstrcat, offset arrowString, offset downArrow
					invoke	SetDlgItemText, hWnd, IDC_DirBox, offset arrowString
					; add int to tail of array
					mov		eax, dirLen
					mov		dirSeq[eax * TYPE DWORD], 2
					; len++
					mov		eax, dirLen
					inc		eax
					mov		dirLen, eax
			.elseif ax == IDC_Left
					invoke	lstrcat, offset arrowString, offset leftArrow
					invoke	SetDlgItemText, hWnd, IDC_DirBox, offset arrowString
					; add int to tail of array
					mov		eax, dirLen
					mov		dirSeq[eax * TYPE DWORD], 3
					; len++
					mov		eax, dirLen
					inc		eax
					mov		dirLen, eax
			.elseif ax == IDC_Right
					invoke	lstrcat, offset arrowString, offset rightArrow
					invoke	SetDlgItemText, hWnd, IDC_DirBox, offset arrowString
					; add int to tail of array
					mov		eax, dirLen
					mov		dirSeq[eax * TYPE DWORD], 1
					; len++
					mov		eax, dirLen
					inc		eax
					mov		dirLen, eax
			.elseif ax == IDC_Clear
					; set string to NULL
					mov		arrowString, 0
					invoke	SetDlgItemText, hWnd, IDC_DirBox, offset arrowString
					; set array length to 0
					mov		dirLen, 0
			.endif
	.else
			mov		eax, FALSE
			ret
	.endif

	mov		eax, TRUE
	ret

_ProcDirBoxMain ENDP
END

