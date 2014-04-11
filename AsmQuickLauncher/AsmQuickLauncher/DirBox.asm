.386
.model flat, stdcall
option casemap:none

include Declaration.inc

EnablePreviousButton PROTO,
	hWnd: DWORD

.data
dirSeq					dd		32 DUP(0)
dirLen					dd		0
actionAddressDirBox		dd		?
arrowStringDirBox		db		128 DUP(?)

.const
szError		db		'����', 0
szWarning	db		'�������г��Ȳ���Ϊ0��', 0

.code
_ProcDirBoxMain PROC uses ebx edi esi hWnd, wMsg, wParam, lParam

	mov		eax, wMsg
;================================================================================================================
	.if		eax == WM_INITDIALOG
			mov		ebx, actionAddressDirBox
			; convert 0123 sequence to dir sequence
			invoke	GetArrowSeq, addr (ACTION PTR [ebx]).seq, (ACTION PTR [ebx]).len, offset arrowStringDirBox
			; copy arrow string and diaplay
			invoke	SetDlgItemText, hWnd, IDC_DirBox, offset arrowStringDirBox
			; copy length
			mov		ebx, actionAddressDirBox
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
			; set button status
			.if		dirLen != 0
				mov		eax, dirLen
				dec		eax
				mov		edx, dirSeq[eax * TYPE DWORD]
				.if		edx == 0
					invoke	GetDlgItem, hWnd, IDC_Up
					invoke	EnableWindow, eax, FALSE
				.elseif	edx == 1
					invoke	GetDlgItem, hWnd, IDC_Right
					invoke	EnableWindow, eax, FALSE
				.elseif	edx == 2
					invoke	GetDlgItem, hWnd, IDC_Down
					invoke	EnableWindow, eax, FALSE
				.else
					invoke	GetDlgItem, hWnd, IDC_Left
					invoke	EnableWindow, eax, FALSE
				.endif
			.endif
;================================================================================================================
	.elseif	eax == WM_CLOSE
			invoke	EndDialog, hWnd, 0
;================================================================================================================
	.elseif	eax == WM_COMMAND
			mov		eax, wParam
;----------------------------------------------------------------------------------------------------------------
			.if		ax == IDOK
					; judge the length is 0 or not, which is illegal
					.if	dirLen == 0
						invoke	MessageBox, 0, offset szWarning, offset szError, 0
						mov		eax, FALSE
						ret
					.endif
					; copy length
					mov		edx, dirLen
					mov		ebx, actionAddressDirBox
					mov		(ACTION PTR [ebx]).len, edx
					; copy 0123 sequence
					mov		ecx, 0
					lea		esi, dirSeq
					;mov		ebx, actionAddress
					lea		edi, (ACTION PTR [ebx]).seq
					.while	ecx < edx
						mov		eax, [esi]
						mov		[edi], eax
						add		esi, TYPE DWORD
						add		edi, TYPE DWORD
						inc		ecx
					.endw

					invoke	EndDialog, hWnd, 1
;----------------------------------------------------------------------------------------------------------------
			.elseif	ax == IDCANCEL
					invoke	EndDialog, hWnd, 0
;----------------------------------------------------------------------------------------------------------------
			.elseif ax == IDC_Up
					invoke	lstrcat, offset arrowStringDirBox, offset upArrow
					invoke	SetDlgItemText, hWnd, IDC_DirBox, offset arrowStringDirBox
					; add int to tail of array
					mov		eax, dirLen
					mov		dirSeq[eax * TYPE DWORD], 0
					; change button status
					invoke	EnablePreviousButton, hWnd
					invoke	GetDlgItem, hWnd, IDC_Up
					invoke	EnableWindow, eax, FALSE
					; len++
					inc		dirLen
			.elseif ax == IDC_Right
					invoke	lstrcat, offset arrowStringDirBox, offset rightArrow
					invoke	SetDlgItemText, hWnd, IDC_DirBox, offset arrowStringDirBox
					; add int to tail of array
					mov		eax, dirLen
					mov		dirSeq[eax * TYPE DWORD], 1
					; change button status
					invoke	EnablePreviousButton, hWnd
					invoke	GetDlgItem, hWnd, IDC_Right
					invoke	EnableWindow, eax, FALSE
					; len++
					inc		dirLen
			.elseif ax == IDC_Down
					invoke	lstrcat, offset arrowStringDirBox, offset downArrow
					invoke	SetDlgItemText, hWnd, IDC_DirBox, offset arrowStringDirBox
					; add int to tail of array
					mov		eax, dirLen
					mov		dirSeq[eax * TYPE DWORD], 2
					; change button status
					invoke	EnablePreviousButton, hWnd
					invoke	GetDlgItem, hWnd, IDC_Down
					invoke	EnableWindow, eax, FALSE
					; len++
					inc		dirLen
			.elseif ax == IDC_Left
					invoke	lstrcat, offset arrowStringDirBox, offset leftArrow
					invoke	SetDlgItemText, hWnd, IDC_DirBox, offset arrowStringDirBox
					; add int to tail of array
					mov		eax, dirLen
					mov		dirSeq[eax * TYPE DWORD], 3
					; change button status
					invoke	EnablePreviousButton, hWnd
					invoke	GetDlgItem, hWnd, IDC_Left
					invoke	EnableWindow, eax, FALSE
					; len++
					inc		dirLen
;----------------------------------------------------------------------------------------------------------------
			.elseif ax == IDC_Clear
					invoke	EnablePreviousButton, hWnd
					; set string to NULL
					mov		arrowStringDirBox, 0
					invoke	SetDlgItemText, hWnd, IDC_DirBox, offset arrowStringDirBox
					; set array length to 0
					mov		dirLen, 0
			.endif
;================================================================================================================
	.else
			mov		eax, FALSE
			ret
	.endif

	mov		eax, TRUE
	ret

_ProcDirBoxMain ENDP

EnablePreviousButton PROC,
	hWnd: DWORD

	.if		dirLen != 0
		mov		eax, dirLen
		dec		eax
		mov		edx, dirSeq[eax * TYPE DWORD]
		.if		edx == 0
			invoke	GetDlgItem, hWnd, IDC_Up
			invoke	EnableWindow, eax, TRUE
		.elseif	edx == 1
			invoke	GetDlgItem, hWnd, IDC_Right
			invoke	EnableWindow, eax, TRUE
		.elseif	edx == 2
			invoke	GetDlgItem, hWnd, IDC_Down
			invoke	EnableWindow, eax, TRUE
		.else
			invoke	GetDlgItem, hWnd, IDC_Left
			invoke	EnableWindow, eax, TRUE
		.endif
	.endif
	ret
EnablePreviousButton ENDP

END

