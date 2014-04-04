.386
.model flat, stdcall
option casemap:none

include Declaration.inc

.const
szTextTest		db		'≤‚ ‘“ªœ¬', 0

.code
_ProcDlgMain PROC uses ebx edi esi hWnd, wMsg, wParam, lParam

	mov		eax, wMsg
	.if		eax == WM_CLOSE
			invoke	EndDialog, hWnd, NULL
	.elseif	eax == WM_COMMAND
			mov		eax, wParam
			.if		ax == IDOK
					invoke	EndDialog, hWnd, NULL
			.elseif	ax == IDCANCEL
					invoke	EndDialog, hWnd, NULL
			.elseif ax == IDC_ChooseFile
					invoke	MessageBox, hWinMain, addr szTextTest, addr szTextTest, MB_OK
			.endif
	.else
			mov		eax, FALSE
			ret
	.endif

	mov		eax, TRUE
	ret

_ProcDlgMain ENDP
END
