.386
.model flat, stdcall
option casemap:none

; Dialog for user to input path
; created when clicking '����·��'

include Declaration.inc

.const
szWarningCap	db		'·�����Ϸ�', 0
szPathWarning	db		'����д·����', 0

.data
; the return address of this dialog
; when OK clicked, the path will be assigned to the path
; field of the temp ACTION struct of callee of this dialog
actionAddressInputBox		dd		?
; temp string for path
tempPathInputBox			db		MAX_PATH DUP(?)

.code
_ProcInputBoxMain PROC uses ebx edi esi hWnd, wMsg, wParam, lParam

	mov		eax, wMsg
;================================================================================================================
	.if		eax == WM_INITDIALOG
			mov		ebx, actionAddressInputBox
			invoke	SetDlgItemText, hWnd, IDC_InputPath, addr (ACTION PTR [ebx]).path
;================================================================================================================
	.elseif	eax == WM_CLOSE
			invoke	EndDialog, hWnd, 0
;================================================================================================================
	.elseif	eax == WM_COMMAND
			mov		eax, wParam
;----------------------------------------------------------------------------------------------------------------
			.if		ax == IDOK
					invoke	GetDlgItemText, hWnd, IDC_InputPath, offset tempPathInputBox, 1024
					invoke	lstrlen, offset tempPathInputBox
					.if		eax == 0
						invoke	MessageBox, hWnd, offset szPathWarning, offset szWarningCap, MB_OK
						mov		ebx, actionAddressInputBox
						invoke	SetDlgItemText, hWnd, IDC_InputPath, addr (ACTION PTR [ebx]).path
						ret
					.endif
					mov		ebx, actionAddressInputBox
					invoke	GetDlgItemText, hWnd, IDC_InputPath, addr (ACTION PTR [ebx]).path, 1024
					invoke	EndDialog, hWnd, 1
;----------------------------------------------------------------------------------------------------------------
			.elseif	ax == IDCANCEL
					invoke	EndDialog, hWnd, 0
			.endif
;================================================================================================================
	.else
			mov		eax, FALSE
			ret
	.endif

	mov		eax, TRUE
	ret

_ProcInputBoxMain ENDP
END

