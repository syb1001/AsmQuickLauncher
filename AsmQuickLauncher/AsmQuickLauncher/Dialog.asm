.386
.model flat, stdcall
option casemap:none

include Declaration.inc

.const
szOpen			db		'open', 0
szFileFilter	db		'All Files(*.*)', 0 , '*.*', 0, 0
szTextTest		db		'≤‚ ‘“ªœ¬', 0

.data
szCurrentPath		db		MAX_PATH DUP (?)
szCurrentTip		db		1024 DUP (?)
szCurrentType		db		?

actionAddress		dd		?

.code
_ProcDlgMain PROC uses ebx edi esi hWnd, wMsg, wParam, lParam
	LOCAL	@ofn:		OPENFILENAME,
			@bi:		BROWSEINFO,
			@lpidlist:	DWORD,
			@sei:		SHELLEXECUTEINFO

	mov		eax, wMsg
	.if		eax == WM_INITDIALOG
			; init the dialog controls here
			mov		eax, 0
			.while	eax < actionLen
				push	eax
					
				lea		ebx, actionMap
				mov		edx, TYPE ACTION
				mul		edx
				add		ebx, eax
				invoke	SendDlgItemMessage, hWnd, IDC_GestureList, CB_ADDSTRING, 0, addr (ACTION PTR [ebx]).tip

				pop		eax
				inc		eax
			.endw

			invoke	SendDlgItemMessage, hWnd, IDC_GestureList, CB_SETCURSEL, 0, 0
			invoke	SetDlgItemText, hWnd, IDC_GestureHint, addr (ACTION PTR actionMap).tip
			invoke	SetDlgItemText, hWnd, IDC_GesturePath, addr (ACTION PTR actionMap).path
			invoke	SetDlgItemText, hWnd, IDC_GestureSequence, addr (ACTION PTR actionMap).seq
			lea		eax, actionMap
			mov		actionAddress, eax
			;invoke	lstrcpy, szCurrentTip, addr (ACTION PTR actionMap).tip
			;invoke	MessageBox, hWnd, addr szCurrentTip, offset szOpen, MB_OK
	.elseif	eax == WM_CLOSE
			invoke	EndDialog, hWnd, 0
	.elseif	eax == WM_COMMAND
			mov		eax, wParam
			.if		ax == IDOK
					; press ok button
					; update this item in the actionMap
					invoke	SendDlgItemMessage, hWnd, IDC_GestureList, CB_GETCURSEL, 0, 0
					mov		esi, eax
					mov		edx, TYPE ACTION
					mul		edx
					lea		ebx, actionMap
					add		ebx, eax
					; update actionMap
					invoke	GetDlgItemText, hWnd, IDC_GestureHint, addr (ACTION PTR [ebx]).tip, 1024
					invoke	GetDlgItemText, hWnd, IDC_GesturePath, addr (ACTION PTR [ebx]).path, 1024

					invoke	EndDialog, hWnd, 1
			.elseif	ax == IDCANCEL
					invoke	EndDialog, hWnd, 0
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
						;invoke ShellExecute, NULL, addr szOpen, addr szCurrentPath, NULL, NULL, SW_SHOW
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
							; save the virtual path somewhere
							;invoke	ShellExecuteEx, addr @sei
						.else
							; browse a normal file, change the path text and open it
							invoke SetDlgItemText, hWnd, IDC_GesturePath, addr szCurrentPath
							;invoke ShellExecute, NULL, addr szOpen, addr szCurrentPath, NULL, NULL, SW_SHOW
						.endif
					.endif
			; input the path directly
			.elseif	ax == IDC_EnterPath
				; another modal dialog
				invoke	DialogBoxParam, hInstance, IDD_InputBox, hWnd, offset _ProcInputBoxMain, NULL
				.if	eax == 1
					mov		ebx, actionAddress
					invoke SetDlgItemText, hWnd, IDC_GesturePath, addr (ACTION PTR [ebx]).path
				.endif
			.elseif	ax == IDC_GestureList
				; process message of combo box here
				shr		eax, 16
				.if	ax == CBN_SELENDOK
					invoke	SendDlgItemMessage, hWnd, IDC_GestureList, CB_GETCURSEL, 0, 0
					mov		edx, TYPE ACTION
					mul		edx
					lea		ebx, actionMap
					add		ebx, eax
					mov		actionAddress, ebx
					invoke	SetDlgItemText, hWnd, IDC_GestureHint, addr (ACTION PTR [ebx]).tip
					invoke	SetDlgItemText, hWnd, IDC_GesturePath, addr (ACTION PTR [ebx]).path
					;invoke	lstrcpy
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
