.386
.model flat, stdcall
option casemap:none

include Declaration.inc

.const
szOpen			db		'open', 0
szFileFilter	db		'All Files(*.*)', 0 , '*.*', 0, 0

.data
tempActionEdit		ACTION	<>
arrowStringEdit		db		128 DUP(?)
tempPathEdit		db		MAX_PATH DUP(?)

.code
_ProcEditDlgMain PROC uses ebx edi esi hWnd, wMsg, wParam, lParam
	LOCAL	@ofn:		OPENFILENAME,
			@bi:		BROWSEINFO,
			@lpidlist:	DWORD,
			@sei:		SHELLEXECUTEINFO

	mov		eax, wMsg
;================================================================================================================
	.if		eax == WM_INITDIALOG
			.if actionLen == 0
				ret
			.endif
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

			invoke	CopyAction, offset tempActionEdit, offset actionMap

			invoke	SendDlgItemMessage, hWnd, IDC_GestureList, CB_SETCURSEL, 0, 0
			invoke	SetDlgItemText, hWnd, IDC_GestureHint, addr (ACTION PTR tempActionEdit).tip
			invoke	SetDlgItemText, hWnd, IDC_GesturePath, addr (ACTION PTR tempActionEdit).path
			invoke	GetArrowSeq, addr (ACTION PTR tempActionEdit).seq, (ACTION PTR tempActionEdit).len, offset arrowStringEdit
			invoke	SetDlgItemText, hWnd, IDC_GestureSequence, offset arrowStringEdit
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

					; actionlen=0, add a new action

					.if		actionLen == 0
						invoke	GetDlgItemText, hWnd, IDC_GestureHint, offset tempActionEdit.tip, 1024

						invoke	AddNewAction, offset tempActionEdit.seq, tempActionEdit.len, \
							offset tempActionEdit.path, offset tempActionEdit.tip, tempActionEdit.pathType
					.else
						invoke	SendDlgItemMessage, hWnd, IDC_GestureList, CB_GETCURSEL, 0, 0
						mov		esi, eax
						mov		edx, TYPE ACTION
						mul		edx
						lea		ebx, actionMap
						add		ebx, eax

						invoke	GetDlgItemText, hWnd, IDC_GestureHint, offset tempActionEdit.tip, 1024
						; update actionMap
						invoke	CopyAction, ebx, offset tempActionEdit
					.endif

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
					mov		@ofn.lpstrFile, offset tempPathEdit
					mov		@ofn.nMaxFile, MAX_PATH 
					mov		@ofn.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST
					invoke	GetOpenFileName, addr @ofn
					.if	eax
						mov		tempActionEdit.pathType, 0
						invoke	lstrcpy, offset tempActionEdit.path, offset tempPathEdit
						invoke	SetDlgItemText, hWnd, IDC_GesturePath, addr tempActionEdit.path
					.endif
;----------------------------------------------------------------------------------------------------------------
			; browse a directory
			.elseif ax == IDC_ChooseDirectory
					invoke	RtlZeroMemory, addr @bi, sizeof @bi
					push	hWnd
					pop		@bi.hwndOwner
					mov		@bi.pszDisplayName, offset tempPathEdit
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
						invoke SHGetPathFromIDList, @lpidlist, offset tempActionEdit.path
						.if !eax
							; this if branch is currently disabled
							mov		tempActionEdit.pathType, 3
							; unsuccessful getting the path, indicates that we choose a vitual path
							; so will use ShellExecuteEx to open the vitual path

							;invoke	SHGetSpecialFolderLocation, NULL, CSIDL_DRIVES, addr @lpidlist
							;invoke	SHGetSpecialFolderPath, NULL, offset tempActionEdit.path, CSIDL_DRIVES, FALSE
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
							mov		tempActionEdit.pathType, 1
							; browse a normal file, change the path text and open it
							invoke SetDlgItemText, hWnd, IDC_GesturePath, addr tempActionEdit.path
						.endif
					.endif
;----------------------------------------------------------------------------------------------------------------
			; input the path directly
			.elseif	ax == IDC_EnterPath
				; another modal dialog
				lea		eax, tempActionEdit
				mov		actionAddressInputBox, eax
				invoke	DialogBoxParam, hInstance, IDD_InputBox, hWnd, offset _ProcInputBoxMain, NULL
				.if	eax == 1
					mov		tempActionEdit.pathType, 2
					invoke SetDlgItemText, hWnd, IDC_GesturePath, addr (ACTION PTR tempActionEdit).path
				.endif
			; edit the gesture sequence
			.elseif ax == IDC_EditGesture
				; third modal dialog
				lea		eax, tempActionEdit
				mov		actionAddressDirBox, eax
				invoke	DialogBoxParam, hInstance, IDD_DirBox, hWnd, offset _ProcDirBoxMain, NULL
				.if	eax == 1
					invoke	GetArrowSeq, addr (ACTION PTR tempActionEdit).seq, (ACTION PTR tempActionEdit).len, offset arrowStringEdit
					invoke	SetDlgItemText, hWnd, IDC_GestureSequence, offset arrowStringEdit
				.endif
;----------------------------------------------------------------------------------------------------------------
			.elseif	ax == IDC_DeleteGesture
				.if		actionLen == 0
					ret
				.endif
				; to delete an action, get its index and memory address
				invoke	SendDlgItemMessage, hWnd, IDC_GestureList, CB_GETCURSEL, 0, 0
				mov		esi, eax
				mov		edx, TYPE ACTION
				mul		edx
				lea		ebx, actionMap
				add		ebx, eax

				pushad
				invoke	DeleteAction, esi, ebx
				popad

				push	ebx
				invoke	SendDlgItemMessage, hWnd, IDC_GestureList, CB_DELETESTRING, esi, 0
				pop		ebx

				; consider the last item deleted
				.if		esi >= actionLen
					dec		esi
					sub		ebx, TYPE ACTION
				.endif
				
				.if		actionLen == 0
					invoke	RtlZeroMemory, offset tempActionEdit, TYPE ACTION
				.else
					invoke	CopyAction,	offset tempActionEdit, ebx
				.endif

				invoke	SendDlgItemMessage, hWnd, IDC_GestureList, CB_SETCURSEL, esi, 0
				invoke	SetDlgItemText, hWnd, IDC_GestureHint, addr (ACTION PTR tempActionEdit).tip
				invoke	SetDlgItemText, hWnd, IDC_GesturePath, addr (ACTION PTR tempActionEdit).path
				invoke	GetArrowSeq, addr (ACTION PTR tempActionEdit).seq, (ACTION PTR tempActionEdit).len, offset arrowStringEdit
				invoke	SetDlgItemText, hWnd, IDC_GestureSequence, offset arrowStringEdit
;----------------------------------------------------------------------------------------------------------------
			.elseif	ax == IDC_GestureList
				; process message of combo box here
				shr		eax, 16
				.if	ax == CBN_SELENDOK
					invoke	SendDlgItemMessage, hWnd, IDC_GestureList, CB_GETCURSEL, 0, 0
					mov		edx, TYPE ACTION
					mul		edx
					lea		ebx, actionMap
					add		ebx, eax

					invoke	CopyAction, offset tempActionEdit, ebx

					invoke	SetDlgItemText, hWnd, IDC_GestureHint, addr (ACTION PTR tempActionEdit).tip
					invoke	SetDlgItemText, hWnd, IDC_GesturePath, addr (ACTION PTR tempActionEdit).path
					invoke	GetArrowSeq, addr (ACTION PTR tempActionEdit).seq, (ACTION PTR tempActionEdit).len, offset arrowStringEdit
					invoke	SetDlgItemText, hWnd, IDC_GestureSequence, offset arrowStringEdit
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

_ProcEditDlgMain ENDP
END
