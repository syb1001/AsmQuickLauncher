.386
.model flat, stdcall
option casemap:none

include Declaration.inc

.code
_ProcInputBoxMain PROC uses ebx edi esi hWnd, wMsg, wParam, lParam

	mov		eax, wMsg
	.if		eax == WM_INITDIALOG
			invoke SetDlgItemText, hWnd, IDC_InputPath, addr (ACTION PTR actionAddress).path
	.elseif	eax == WM_CLOSE
			invoke	EndDialog, hWnd, 0
	.elseif	eax == WM_COMMAND
			mov		eax, wParam
			.if		ax == IDOK
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

