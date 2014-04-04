.386
.model flat, stdcall
option casemap:none

include Declaration.inc

.const
szFileFilter	db		'All Files(*.*)', 0 , '*.*', 0, 0
szTextTest		db		'≤‚ ‘“ªœ¬', 0

.data
szCurrentPath	db		MAX_PATH DUP (?)

.code
_ProcDlgMain PROC uses ebx edi esi hWnd, wMsg, wParam, lParam
	LOCAL	@ofn:	OPENFILENAME,
			@bi:	BROWSEINFO

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
					invoke	RtlZeroMemory, addr @ofn, sizeof @ofn
					mov		@ofn.lStructSize, sizeof @ofn
					push	hWnd
					pop		@ofn.hwndOwner
					mov		@ofn.lpstrFilter, offset szFileFilter
					mov		@ofn.lpstrFile, offset szCurrentPath
					mov		@ofn.nMaxFile, MAX_PATH 
					mov		@ofn.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST
					invoke	GetOpenFileName, addr @ofn
					.if	eax
						invoke SetDlgItemText, hWnd, IDC_GesturePath, addr szCurrentPath
					.endif
			.elseif ax == IDC_ChooseDirectory
					invoke	RtlZeroMemory, addr @bi, sizeof @bi
					push	hWnd
					pop		@bi.hwndOwner
					invoke	SHBrowseForFolder, addr @bi
					.if	eax
						invoke SHGetPathFromIDList, eax, offset szCurrentPath
						invoke SetDlgItemText, hWnd, IDC_GesturePath, addr szCurrentPath
					.endif
			.endif
	.else
			mov		eax, FALSE
			ret
	.endif

	mov		eax, TRUE
	ret

_ProcDlgMain ENDP
END
