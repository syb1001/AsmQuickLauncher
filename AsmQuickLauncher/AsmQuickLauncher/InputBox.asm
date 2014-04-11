.386
.model flat, stdcall
option casemap:none

include Declaration.inc

.data
actionAddressInputBox		dd		?

.code
_ProcInputBoxMain PROC uses ebx edi esi hWnd, wMsg, wParam, lParam

	mov		eax, wMsg
	.if		eax == WM_INITDIALOG
			mov		ebx, actionAddressInputBox
			invoke	SetDlgItemText, hWnd, IDC_InputPath, addr (ACTION PTR [ebx]).path
	.elseif	eax == WM_CLOSE
			invoke	EndDialog, hWnd, 0
	.elseif	eax == WM_COMMAND
			mov		eax, wParam
			.if		ax == IDOK
					mov		ebx, actionAddressInputBox
					invoke	GetDlgItemText, hWnd, IDC_InputPath, addr (ACTION PTR [ebx]).path, 1024
					invoke	EndDialog, hWnd, 1
			.elseif	ax == IDCANCEL
					invoke	EndDialog, hWnd, 0
			.endif
	.else
			mov		eax, FALSE
			ret
	.endif

	mov		eax, TRUE
	ret

_ProcInputBoxMain ENDP
END

