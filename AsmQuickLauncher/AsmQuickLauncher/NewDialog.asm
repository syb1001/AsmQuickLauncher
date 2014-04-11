.386
.model flat, stdcall
option casemap:none

include Declaration.inc

.const
szOpen			db		'open', 0
szFileFilter	db		'All Files(*.*)', 0 , '*.*', 0, 0
szWarningCap	db		'添加失败', 0
szTipWarning	db		'请填写手势提示文字！', 0
szPathWarning	db		'请选择启动项！', 0
szSeqWarning	db		'请编辑手势序列！', 0

.data
tempActionNew		ACTION	<>
arrowStringNew		db		128 DUP(?)
tempPathNew		db		MAX_PATH DUP(?)

.code
_ProcNewDlgMain PROC uses ebx edi esi hWnd, wMsg, wParam, lParam
	LOCAL	@ofn:		OPENFILENAME,
			@bi:		BROWSEINFO,
			@lpidlist:	DWORD,
			@sei:		SHELLEXECUTEINFO

	mov		eax, wMsg
;================================================================================================================
	.if		eax == WM_INITDIALOG
			; init the dialog controls here

			; initialize temp action
			invoke	RtlZeroMemory, offset tempActionNew, TYPE ACTION

			mov		ecx, 0
			lea		esi, trackSeq
			lea		edi, tempActionNew.seq
			mov		edx, seqLength
			.while	ecx < edx
				mov		eax, [esi]
				mov		[edi], eax
				add		esi, TYPE DWORD
				add		edi, TYPE DWORD
				inc		ecx
			.endw

			mov		tempActionNew.len, edx

			invoke	SetDlgItemText, hWnd, IDC_GesturePath, 0
			invoke	GetArrowSeq, addr trackSeq, seqLength, offset arrowStringNew
			invoke	SetDlgItemText, hWnd, IDC_GestureSequence, offset arrowStringNew
;================================================================================================================
	.elseif	eax == WM_CLOSE
			invoke	EndDialog, hWnd, 0
;================================================================================================================
	.elseif	eax == WM_COMMAND
			mov		eax, wParam
;----------------------------------------------------------------------------------------------------------------
			.if		ax == IDOK
					; press ok button
					; update this item in the actionMap

					;------------------------------validation check------------------------------
					invoke	GetDlgItemText, hWnd, IDC_GestureHint, offset tempActionNew.tip, 1024
					invoke	lstrlen, offset tempActionNew.tip
					.if		eax == 0
						invoke	MessageBox, hWnd, offset szTipWarning, offset szWarningCap, MB_OK
						invoke	SetDlgItemText, hWnd, IDC_GestureHint, offset tempActionNew.tip
						ret
					.endif
					invoke	lstrlen, offset tempActionNew.path
					.if		eax == 0
						invoke	MessageBox, hWnd, offset szPathWarning, offset szWarningCap, MB_OK
						ret
					.endif
					.if		tempActionNew.len == 0
						invoke	MessageBox, hWnd, offset szSeqWarning, offset szWarningCap, MB_OK
						ret
					.endif
					;----------------------------------------------------------------------------

					invoke	AddNewAction, offset tempActionNew.seq, tempActionNew.len, \
						offset tempActionNew.path, offset tempActionNew.tip, tempActionNew.pathType

					invoke	EndDialog, hWnd, 1
;----------------------------------------------------------------------------------------------------------------
			.elseif	ax == IDCANCEL
					invoke	EndDialog, hWnd, 0
;----------------------------------------------------------------------------------------------------------------
			; browse a file
			.elseif ax == IDC_ChooseFile
					invoke	RtlZeroMemory, addr @ofn, sizeof @ofn
					mov		@ofn.lStructSize, sizeof @ofn
					push	hWnd
					pop		@ofn.hwndOwner
					mov		@ofn.lpstrFilter, offset szFileFilter
					mov		@ofn.lpstrFile, offset tempPathNew
					mov		@ofn.nMaxFile, MAX_PATH 
					mov		@ofn.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST
					invoke	GetOpenFileName, addr @ofn
					.if	eax
						mov		tempActionNew.pathType, 0
						invoke	lstrcpy, offset tempActionNew.path, offset tempPathNew
						invoke	SetDlgItemText, hWnd, IDC_GesturePath, addr tempActionNew.path
					.endif
;----------------------------------------------------------------------------------------------------------------
			; browse a directory
			.elseif ax == IDC_ChooseDirectory
					invoke	RtlZeroMemory, addr @bi, sizeof @bi
					push	hWnd
					pop		@bi.hwndOwner
					mov		@bi.pszDisplayName, offset tempPathNew
					or		@bi.ulFlags, BIF_USENEWUI
					; disable the function to browse virtual path
					; waiting for better solution
					or		@bi.ulFlags, BIF_RETURNONLYFSDIRS
					; invoke the common dialog
					invoke	SHBrowseForFolder, addr @bi
					; if success (usually success)
					.if	eax
						; the returned eax contains a ItemIdList
						mov		@lpidlist, eax
						; if not chose a file path, the function will fail
						invoke SHGetPathFromIDList, @lpidlist, offset tempActionNew.path
						.if !eax
							; this if branch is currently disabled
							mov		tempActionNew.pathType, 3
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
							mov		tempActionNew.pathType, 1
							; browse a normal file, change the path text and open it
							invoke SetDlgItemText, hWnd, IDC_GesturePath, addr tempActionNew.path
						.endif
					.endif
;----------------------------------------------------------------------------------------------------------------
			; input the path directly
			.elseif	ax == IDC_EnterPath
				; another modal dialog
				lea		eax, tempActionNew
				mov		actionAddressInputBox, eax
				invoke	DialogBoxParam, hInstance, IDD_InputBox, hWnd, offset _ProcInputBoxMain, NULL
				.if	eax == 1
					mov		tempActionNew.pathType, 2
					invoke	SetDlgItemText, hWnd, IDC_GesturePath, addr (ACTION PTR tempActionNew).path
				.endif
;----------------------------------------------------------------------------------------------------------------
			; edit the gesture sequence
			.elseif ax == IDC_EditGesture
				; third modal dialog
				lea		eax, tempActionNew
				mov		actionAddressDirBox, eax
				invoke	DialogBoxParam, hInstance, IDD_DirBox, hWnd, offset _ProcDirBoxMain, NULL
				.if	eax == 1
					invoke	GetArrowSeq, addr (ACTION PTR tempActionNew).seq, (ACTION PTR tempActionNew).len, offset arrowStringNew
					invoke	SetDlgItemText, hWnd, IDC_GestureSequence, offset arrowStringNew
				.endif
			.endif
;----------------------------------------------------------------------------------------------------------------
;================================================================================================================
	.else
			mov		eax, FALSE
			ret
	.endif

	mov		eax, TRUE
	ret

_ProcNewDlgMain ENDP
END
