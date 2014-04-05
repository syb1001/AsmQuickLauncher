.386
.model flat, stdcall
option casemap:none

include Declaration.inc

.const
szOpen			db		'open', 0
szFileFilter	db		'All Files(*.*)', 0 , '*.*', 0, 0
szTextTest		db		'≤‚ ‘“ªœ¬', 0

.data
szCurrentPath	db		MAX_PATH DUP (?)

.code
_ProcDlgMain PROC uses ebx edi esi hWnd, wMsg, wParam, lParam
	LOCAL	@ofn:		OPENFILENAME,
			@bi:		BROWSEINFO,
			@lpidlist:	DWORD,
			@sei:		SHELLEXECUTEINFO

	mov		eax, wMsg
	.if		eax == WM_CLOSE
			invoke	EndDialog, hWnd, NULL
	.elseif	eax == WM_COMMAND
			mov		eax, wParam
			.if		ax == IDOK
					invoke	EndDialog, hWnd, NULL
			.elseif	ax == IDCANCEL
					invoke	EndDialog, hWnd, NULL
			; browse a file
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
						invoke ShellExecute, NULL, addr szOpen, addr szCurrentPath, NULL, NULL, SW_SHOW
					.endif
			; browse a directory
			.elseif ax == IDC_ChooseDirectory
					invoke	RtlZeroMemory, addr @bi, sizeof @bi
					push	hWnd
					pop		@bi.hwndOwner
					mov		@bi.pszDisplayName, offset szCurrentPath
					or		@bi.ulFlags, BIF_USENEWUI
					; invoke the common dialog
					invoke	SHBrowseForFolder, addr @bi
					; if success (usually success)
					.if	eax
						; the returned eax contains a ItemIdList
						mov		@lpidlist, eax
						; if not chose a file path, the function will fail
						invoke SHGetPathFromIDList, @lpidlist, offset szCurrentPath
						.if !eax
							; unsuccessful getting the path, indicates that we choose a vitual path
							; so will use ShellExecuteEx to open the vitual path

							;invoke	SHGetSpecialFolderLocation, NULL, CSIDL_DRIVES, addr @lpidlist
							;invoke	SHGetSpecialFolderPath, NULL, offset szCurrentPath, CSIDL_DRIVES, FALSE
							invoke	RtlZeroMemory, addr @sei, sizeof @sei
							mov		@sei.cbSize, sizeof @sei
							mov		@sei.fMask, SEE_MASK_IDLIST
							push	@lpidlist
							pop		@sei.lpIDList
							mov		@sei.lpVerb, offset szOpen
							mov		@sei.nShow, SW_SHOWNORMAL
							invoke	ShellExecuteEx, addr @sei
						.else
							; browse a normal file, change the path text and open it
							invoke SetDlgItemText, hWnd, IDC_GesturePath, addr szCurrentPath
							invoke ShellExecute, NULL, addr szOpen, addr szCurrentPath, NULL, NULL, SW_SHOW
						.endif
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
