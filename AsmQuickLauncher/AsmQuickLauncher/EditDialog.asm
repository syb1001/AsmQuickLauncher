.386
.model flat, stdcall
option casemap:none

; Dialog for editing gestures
; when no gesture exists, this dialog can
; also be used for add new gesture

include Declaration.inc

.const
szOpen			db		'open', 0
szFileFilter	db		'All Files(*.*)', 0 , '*.*', 0, 0
szWarningCap	db		'修改失败', 0
szTipWarning	db		'请填写手势提示文字！', 0
szPathWarning	db		'请选择启动项！', 0
szSeqWarning	db		'请编辑手势序列！', 0
szButtonAdd		db		'添加', 0
szButtonClose	db		'关闭', 0

.data
; the temp ACTION struct for recording user's modification
; when OK button clicked, it's assigned to actionMap
tempActionEdit		ACTION	<>
; temp arrow string
arrowStringEdit		db		128 DUP(?)
; temp string for path
tempPathEdit		db		MAX_PATH DUP(?)
; temp string for tip
tempTipEdit			db		1024 DUP(?)

.code
_ProcEditDlgMain PROC uses ebx edi esi hWnd, wMsg, wParam, lParam
	LOCAL	@ofn:		OPENFILENAME,
			@bi:		BROWSEINFO,
			@lpidlist:	DWORD,
			@sei:		SHELLEXECUTEINFO,
			@handler:	DWORD

	mov		eax, wMsg
;================================================================================================================
	.if		eax == WM_INITDIALOG
			
			invoke	GetDlgItem, hWnd, IDC_GestureSequence
			invoke	EnableWindow, eax, FALSE

			; initialize temp action
			invoke	RtlZeroMemory, offset tempActionEdit, TYPE ACTION

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

			.if actionLen == 0
				invoke	GetDlgItem, hWnd, IDC_DeleteGesture
				invoke	EnableWindow, eax, FALSE
				invoke	SetDlgItemText, hWnd, IDOK, offset szButtonAdd
				invoke	SetDlgItemText, hWnd, IDCANCEL, offset szButtonClose
			.else
				invoke	CopyAction, offset tempActionEdit, offset actionMap
			.endif

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
;
; Processss OK button message
; update an item in the actionMap
;----------------------------------------------------------------------------------------------------------------
			.if		ax == IDOK

					;------------------------------validation check------------------------------
					invoke	GetDlgItemText, hWnd, IDC_GestureHint, offset tempTipEdit, 1024
					invoke	lstrlen, offset tempTipEdit
					.if		eax == 0
						invoke	MessageBox, hWnd, offset szTipWarning, offset szWarningCap, MB_OK
						invoke	SetDlgItemText, hWnd, IDC_GestureHint, offset tempActionEdit.tip
						ret
					.endif
					invoke	lstrlen, offset tempActionEdit.path
					.if		eax == 0
						invoke	MessageBox, hWnd, offset szPathWarning, offset szWarningCap, MB_OK
						ret
					.endif
					.if		tempActionEdit.len == 0
						invoke	MessageBox, hWnd, offset szSeqWarning, offset szWarningCap, MB_OK
						ret
					.endif
					;----------------------------------------------------------------------------

					invoke	GetDlgItemText, hWnd, IDC_GestureHint, offset tempActionEdit.tip, 1024
					.if		actionLen == 0
						; actionLen=0, add a new action
						invoke	AddNewAction, offset tempActionEdit.seq, tempActionEdit.len, \
							offset tempActionEdit.path, offset tempActionEdit.tip, tempActionEdit.pathType
					.else
						invoke	SendDlgItemMessage, hWnd, IDC_GestureList, CB_GETCURSEL, 0, 0
						mov		esi, eax
						mov		edx, TYPE ACTION
						mul		edx
						lea		ebx, actionMap
						add		ebx, eax

						; update actionMap
						invoke	CopyAction, ebx, offset tempActionEdit
					.endif

					invoke	EndDialog, hWnd, 1
;
; Cancel button clicked
;----------------------------------------------------------------------------------------------------------------
			.elseif	ax == IDCANCEL
					invoke	EndDialog, hWnd, 0
;
; Browse a file
;----------------------------------------------------------------------------------------------------------------
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
;
; Browse a directory
; Virtual path is not implemented
;----------------------------------------------------------------------------------------------------------------
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
;
; Input the path directly
;----------------------------------------------------------------------------------------------------------------
			.elseif	ax == IDC_EnterPath
				lea		eax, tempActionEdit
				mov		actionAddressInputBox, eax
				invoke	DialogBoxParam, hInstance, IDD_InputBox, hWnd, offset _ProcInputBoxMain, NULL
				.if	eax == 1
					mov		tempActionEdit.pathType, 2
					invoke SetDlgItemText, hWnd, IDC_GesturePath, addr (ACTION PTR tempActionEdit).path
				.endif
;
; Edit the gesture sequence
;----------------------------------------------------------------------------------------------------------------
			.elseif ax == IDC_EditGesture
				lea		eax, tempActionEdit
				mov		actionAddressDirBox, eax
				invoke	DialogBoxParam, hInstance, IDD_DirBox, hWnd, offset _ProcDirBoxMain, NULL
				.if	eax == 1
					invoke	GetArrowSeq, addr (ACTION PTR tempActionEdit).seq, (ACTION PTR tempActionEdit).len, offset arrowStringEdit
					invoke	SetDlgItemText, hWnd, IDC_GestureSequence, offset arrowStringEdit
				.endif
;
; Delete an action
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
					invoke	GetDlgItem, hWnd, IDC_DeleteGesture
					invoke	EnableWindow, eax, FALSE
					invoke	SetDlgItemText, hWnd, IDOK, offset szButtonAdd
					invoke	SetDlgItemText, hWnd, IDCANCEL, offset szButtonClose
				.else
					invoke	CopyAction,	offset tempActionEdit, ebx
				.endif

				invoke	SendDlgItemMessage, hWnd, IDC_GestureList, CB_SETCURSEL, esi, 0
				invoke	SetDlgItemText, hWnd, IDC_GestureHint, addr (ACTION PTR tempActionEdit).tip
				invoke	SetDlgItemText, hWnd, IDC_GesturePath, addr (ACTION PTR tempActionEdit).path
				invoke	GetArrowSeq, addr (ACTION PTR tempActionEdit).seq, (ACTION PTR tempActionEdit).len, offset arrowStringEdit
				invoke	SetDlgItemText, hWnd, IDC_GestureSequence, offset arrowStringEdit
;
; Process message of combo box
;----------------------------------------------------------------------------------------------------------------
			.elseif	ax == IDC_GestureList
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
